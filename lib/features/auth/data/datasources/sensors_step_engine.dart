import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/entities/step_data.dart';

/// Motor de pasos y actividad basado en picos del acelerómetro (con gravedad).
/// Misma lógica que el proyecto de referencia: umbrales 13 / 17 m/s² y ventana 3 s.
class SensorsStepEngine {
  StreamController<StepData>? _controller;
  StreamSubscription<AccelerometerEvent>? _subscription;

  int _stepCount = 0;
  ActivityType _currentActivity = ActivityType.stationary;
  DateTime _lastWalkTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRunTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastStepTime = DateTime.fromMillisecondsSinceEpoch(0);
  final List<DateTime> _recentSteps = [];

  double _lastMagnitude = 0;

  static const double walkPeakThreshold = 13.0;
  static const double runPeakThreshold = 17.0;
  static const double fallIgnoreThreshold = 35.0;
  static const Duration peakMemoryWindow = Duration(seconds: 3);
  static const Duration minStepInterval = Duration(milliseconds: 300);
  static const Duration spmWindow = Duration(seconds: 3);

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

    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onEvent);
    _emit();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
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
    _currentActivity = ActivityType.stationary;
    _lastWalkTime = DateTime.fromMillisecondsSinceEpoch(0);
    _lastRunTime = DateTime.fromMillisecondsSinceEpoch(0);
    _lastStepTime = DateTime.fromMillisecondsSinceEpoch(0);
    _recentSteps.clear();
    _lastMagnitude = 0;
  }

  void _onEvent(AccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (magnitude > fallIgnoreThreshold) {
      _lastMagnitude = magnitude;
      _emit();
      return;
    }

    final now = DateTime.now();

    // Conteo de pasos: cruce ascendente sobre umbral de caminata.
    if (magnitude > walkPeakThreshold && _lastMagnitude <= walkPeakThreshold) {
      if (now.difference(_lastStepTime) >= minStepInterval) {
        _stepCount++;
        _lastStepTime = now;
        _recentSteps.add(now);
        _pruneRecentSteps();
      }
    }
    _lastMagnitude = magnitude;

    // Picos de intensidad para walk / run.
    if (magnitude > runPeakThreshold) {
      _lastRunTime = now;
    } else if (magnitude > walkPeakThreshold) {
      _lastWalkTime = now;
    }

    final newActivity = _resolveActivity(now);
    _currentActivity = newActivity;
    _emit();
  }

  ActivityType _resolveActivity(DateTime now) {
    if (now.difference(_lastRunTime) < peakMemoryWindow) {
      return ActivityType.running;
    }
    if (now.difference(_lastWalkTime) < peakMemoryWindow) {
      return ActivityType.walking;
    }
    return ActivityType.stationary;
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

    final windowStart = DateTime.now().subtract(spmWindow);
    final stepsInWindow =
        _recentSteps.where((t) => t.isAfter(windowStart)).length;
    return stepsInWindow * (60.0 / spmWindow.inSeconds);
  }

  void _emit() {
    final controller = _controller;
    if (controller == null || controller.isClosed) {
      return;
    }

    controller.add(
      StepData(
        stepCount: _stepCount,
        activityType: _currentActivity,
        magnitude: _lastMagnitude,
        stepsPerMinute: _computeSpm(),
      ),
    );
  }
}
