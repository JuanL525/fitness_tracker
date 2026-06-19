import 'dart:async';

import '../../../auth/domain/entities/step_data.dart';
import '../entities/accelerometer_sample.dart';
import '../entities/activity_monitor_event.dart';
import '../entities/movement_speed.dart';
import '../entities/physical_activity_type.dart';
import '../repositories/activity_monitor_repositories.dart';
import '../services/activity_debouncer.dart';
import '../services/fall_detector.dart';
import '../services/hybrid_activity_classifier.dart';
import '../services/step_cadence_classifier.dart';
import '../../data/datasources/platform_step_datasource.dart';

class MonitorActivityUseCase {
  MonitorActivityUseCase({
    required ActivitySensorRepository sensorRepository,
    required VoiceFeedbackRepository voiceRepository,
    required SensorPermissionsRepository permissionsRepository,
    required PlatformStepDataSource stepDataSource,
    LocationSpeedRepository? locationRepository,
    ActivityDebouncer? debouncer,
    FallDetector? fallDetector,
    HybridActivityClassifier? activityClassifier,
  })  : _sensorRepository = sensorRepository,
        _voiceRepository = voiceRepository,
        _permissionsRepository = permissionsRepository,
        _stepDataSource = stepDataSource,
        _locationRepository = locationRepository,
        _debouncer = debouncer ?? ActivityDebouncer(),
        _fallDetector = fallDetector ?? FallDetector(),
        _activityClassifier = activityClassifier ?? HybridActivityClassifier();

  final ActivitySensorRepository _sensorRepository;
  final VoiceFeedbackRepository _voiceRepository;
  final SensorPermissionsRepository _permissionsRepository;
  final PlatformStepDataSource _stepDataSource;
  final LocationSpeedRepository? _locationRepository;
  final ActivityDebouncer _debouncer;
  final FallDetector _fallDetector;
  final HybridActivityClassifier _activityClassifier;

  final _controller = StreamController<ActivityMonitorEvent>.broadcast();
  StreamSubscription<AccelerometerSample>? _accelSubscription;
  StreamSubscription<StepData>? _stepSubscription;
  StreamSubscription<MovementSpeed>? _locationSubscription;
  Timer? _activityTimer;
  DateTime? _warmupUntil;
  DateTime? _lastStepIncreaseAt;
  int? _previousStepCount;
  double _lastStepsPerMinute = 0;
  MovementSpeed? _lastGps;

  static const _stepActivityGrace = Duration(seconds: 4);

  Stream<ActivityMonitorEvent> get events => _controller.stream;

  Future<bool> start() async {
    final granted = await _permissionsRepository.requestSensorPermissions();
    if (!granted) {
      _controller.add(PermissionsDenied());
      return false;
    }

    await _voiceRepository.initialize();
    await _sensorRepository.start();

    _debouncer.listen(_onActivityConfirmed);
    _activityClassifier.reset();
    _beginWarmup();
    _previousStepCount = null;
    _lastStepIncreaseAt = null;
    _lastStepsPerMinute = 0;
    _lastGps = null;

    await _startLocationIfAvailable();

    _stepSubscription = _stepDataSource.stepStream.listen(
      _onStepData,
      onError: (Object error) => _controller.addError(error),
    );

    _accelSubscription = _sensorRepository.samples.listen(
      _onAccelSample,
      onError: (Object error) => _controller.addError(error),
    );

    _activityTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _evaluateActivity();
    });

    return true;
  }

  Future<void> _startLocationIfAvailable() async {
    final repo = _locationRepository;
    if (repo == null) {
      return;
    }

    final locationGranted = await repo.requestPermissions();
    if (!locationGranted) {
      return;
    }

    await repo.start();
    _locationSubscription = repo.speedSamples.listen(
      (speed) {
        _lastGps = speed;
        if (!_isInWarmup) {
          _evaluateActivity();
        }
      },
      onError: (_) {},
    );
  }

  Future<void> stop() async {
    _activityTimer?.cancel();
    _activityTimer = null;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await _locationRepository?.stop();
    await _stepSubscription?.cancel();
    await _accelSubscription?.cancel();
    _stepSubscription = null;
    _accelSubscription = null;
    await _stepDataSource.stop();
    await _sensorRepository.stop();
    _debouncer.dispose();
    _activityClassifier.reset();
  }

  void resetFallDetector() {
    _fallDetector.resetAfterUserResponse();
  }

  void setFallTestSensitivity(bool enabled) {
    _fallDetector.setTestSensitivity(enabled);
  }

  bool get fallTestSensitivity => _fallDetector.testSensitivity;

  void _beginWarmup() {
    _warmupUntil = DateTime.now().add(const Duration(seconds: 4));
    _debouncer.reset();
  }

  bool get _isInWarmup {
    final until = _warmupUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  Duration? get _sinceLastStepIncrease {
    final lastIncrease = _lastStepIncreaseAt;
    if (lastIncrease == null) {
      return null;
    }
    return DateTime.now().difference(lastIncrease);
  }

  bool _stepsStillComingFromState() {
    final lastIncrease = _lastStepIncreaseAt;
    if (lastIncrease != null &&
        DateTime.now().difference(lastIncrease) < _stepActivityGrace) {
      return true;
    }
    return _lastStepsPerMinute >= StepCadenceClassifier.movementHoldSpm;
  }

  void _onStepData(StepData data) {
    if (data.stepCount == 0 && (_previousStepCount ?? 0) > 0) {
      _beginWarmup();
    }

    if (data.stepCount > (_previousStepCount ?? -1)) {
      _lastStepIncreaseAt = DateTime.now();
    }
    _previousStepCount = data.stepCount;
    _lastStepsPerMinute = data.stepsPerMinute;

    _fallDetector.onStepUpdate(data.stepCount);
    _controller.add(StepCountUpdated(data));

    if (_isInWarmup) {
      return;
    }

    _evaluateActivity();
  }

  void _evaluateActivity() {
    if (_isInWarmup) {
      return;
    }

    final sinceSteps = _sinceLastStepIncrease;
    if (sinceSteps != null &&
        _activityClassifier.shouldForceStationary(
          sinceLastStepIncrease: sinceSteps,
          stepsPerMinute: _lastStepsPerMinute,
          gps: _lastGps,
        )) {
      _submitCandidate(PhysicalActivityType.stationary);
      return;
    }

    final type = _activityClassifier.classifyMovement(
      stepsPerMinute: _lastStepsPerMinute,
      stepsStillComing: _stepsStillComingFromState(),
      gps: _lastGps,
    );

    _submitCandidate(type);
  }

  void _submitCandidate(PhysicalActivityType type) {
    if (type == PhysicalActivityType.stationary &&
        _debouncer.lastAnnounced == PhysicalActivityType.stationary) {
      return;
    }
    _debouncer.onCandidate(type);
  }

  void _onAccelSample(AccelerometerSample sample) {
    final fall = _fallDetector.process(sample);
    if (fall != null) {
      _controller.add(
        FallDetected(
          timestamp: fall.timestamp,
          impactMagnitude: fall.impactMagnitude,
        ),
      );
    }
  }

  Future<void> _onActivityConfirmed(
    PhysicalActivityType type,
    bool isFirst,
  ) async {
    _controller.add(
      ActivityConfirmed(type: type, isFirstAnnouncement: isFirst),
    );

    final message =
        isFirst ? type.firstAnnouncement : type.changeAnnouncement;
    await _voiceRepository.speak(message);
  }

  Future<void> announceFallPrompt() async {
    await _voiceRepository.speak(
      '¿Estás bien? Parece que te has caído',
    );
  }

  void dispose() {
    _activityTimer?.cancel();
    _locationSubscription?.cancel();
    _stepSubscription?.cancel();
    _accelSubscription?.cancel();
    _debouncer.dispose();
    _controller.close();
  }
}
