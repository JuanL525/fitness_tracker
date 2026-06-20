import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/entities/step_data.dart';

/// Motor de conteo de pasos basado en acelerómetro (`sensors_plus`).
class SensorsStepEngine {
  StreamController<StepData>? _controller;
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  Timer? _tickTimer;

  int _stepCount = 0;
  double _lastMagnitude = 0;
  double _magnitudeBaseline = 0;
  bool _aboveThreshold = false;
  DateTime? _lastStepTime;
  final List<DateTime> _recentSteps = [];

  static const double _stepThreshold = 1.2;
  static const double _maxStepMagnitude = 4.0;
  static const double _impactMagnitude = 6.0;
  static const Duration _impactCooldown = Duration(seconds: 3);
  static const Duration _minStepInterval = Duration(milliseconds: 280);
  static const Duration _spmWindow = Duration(seconds: 3);

  DateTime? _impactCooldownUntil;

  Stream<StepData> get stream {
    _controller ??= StreamController<StepData>.broadcast(
      onListen: _ensureStarted,
    );
    return _controller!.stream;
  }

  Future<void> start() async {
    if (_subscription != null) {
      return;
    }

    _controller ??= StreamController<StepData>.broadcast();
    _resetSession();

    _subscription = userAccelerometerEventStream().listen(_onEvent);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _emit());
    _emit();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _tickTimer?.cancel();
    _subscription = null;
    _tickTimer = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller?.close();
    _controller = null;
  }

  void _ensureStarted() {
    if (_subscription == null) {
      unawaited(start());
    }
  }

  void _resetSession() {
    _stepCount = 0;
    _lastMagnitude = 0;
    _magnitudeBaseline = 0;
    _aboveThreshold = false;
    _lastStepTime = null;
    _recentSteps.clear();
    _impactCooldownUntil = null;
  }

  void _onEvent(UserAccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    final now = DateTime.now();
    if (_impactCooldownUntil != null &&
        now.isBefore(_impactCooldownUntil!)) {
      _lastMagnitude = magnitude;
      return;
    }

    if (magnitude >= _impactMagnitude) {
      _impactCooldownUntil = now.add(_impactCooldown);
      _aboveThreshold = false;
      _lastMagnitude = magnitude;
      return;
    }

    if (magnitude > _maxStepMagnitude) {
      _lastMagnitude = magnitude;
      return;
    }

    if (_magnitudeBaseline == 0) {
      _magnitudeBaseline = magnitude;
    } else {
      _magnitudeBaseline = (_magnitudeBaseline * 0.95) + (magnitude * 0.05);
    }
    _lastMagnitude = magnitude;

    if (magnitude > _magnitudeBaseline + _stepThreshold) {
      if (!_aboveThreshold) {
        _aboveThreshold = true;
        final now = DateTime.now();
        if (_lastStepTime == null ||
            now.difference(_lastStepTime!) >= _minStepInterval) {
          _stepCount++;
          _lastStepTime = now;
          _recentSteps.add(now);
          _pruneRecentSteps();
          _emit();
        }
      }
    } else if (magnitude < _magnitudeBaseline + (_stepThreshold * 0.5)) {
      _aboveThreshold = false;
    }
  }

  void _pruneRecentSteps() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 10));
    _recentSteps.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }

  double _computeSpm() {
    _pruneRecentSteps();
    if (_recentSteps.isEmpty) {
      return 0;
    }

    final windowStart = DateTime.now().subtract(_spmWindow);
    final stepsInWindow =
        _recentSteps.where((timestamp) => timestamp.isAfter(windowStart)).length;
    return stepsInWindow * (60.0 / _spmWindow.inSeconds);
  }

  void _emit() {
    final controller = _controller;
    if (controller == null || controller.isClosed) {
      return;
    }

    controller.add(
      StepData(
        stepCount: _stepCount,
        activityType: ActivityType.stationary,
        magnitude: _lastMagnitude,
        stepsPerMinute: _computeSpm(),
      ),
    );
  }
}
