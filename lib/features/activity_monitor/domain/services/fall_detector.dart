import 'dart:math' as math;

import '../entities/accelerometer_sample.dart';

/// Caída = sacudida MUY fuerte solo cuando no hay pasos recientes.
class FallDetector {
  FallDetector({this.testSensitivity = false});

  bool testSensitivity;

  static const double gravityAlpha = 0.85;
  static const int warmupSamples = 12;

  double get shakeThreshold => testSensitivity ? 14.0 : 19.0;
  double get jerkThreshold => testSensitivity ? 11.0 : 15.0;
  Duration get cooldown =>
      testSensitivity
          ? const Duration(seconds: 20)
          : const Duration(seconds: 45);
  Duration get stepQuietPeriod => const Duration(seconds: 4);

  double _gx = 0;
  double _gy = 0;
  double _gz = 0;
  double _prevLinearMag = 0;
  int _sampleCount = 0;
  DateTime? _lastFallDetectedAt;
  DateTime? _lastStepAt;
  int _lastStepCount = 0;

  void setTestSensitivity(bool enabled) {
    testSensitivity = enabled;
    _resetFilter();
  }

  void onStepUpdate(int stepCount) {
    if (stepCount > _lastStepCount) {
      _lastStepAt = DateTime.now();
    }
    _lastStepCount = stepCount;
  }

  bool get _recentlyStepping {
    if (_lastStepAt == null) {
      return false;
    }
    return DateTime.now().difference(_lastStepAt!) < stepQuietPeriod;
  }

  FallEvent? process(AccelerometerSample sample) {
    if (_isInCooldown(sample.timestamp)) {
      return null;
    }

    if (!testSensitivity && _recentlyStepping) {
      return null;
    }

    final linearMag = _linearAcceleration(sample);
    final jerk = (linearMag - _prevLinearMag).abs();
    _prevLinearMag = linearMag;
    _sampleCount++;

    if (_sampleCount < warmupSamples) {
      return null;
    }

    if (linearMag >= shakeThreshold || jerk >= jerkThreshold) {
      _lastFallDetectedAt = sample.timestamp;
      return FallEvent(
        timestamp: sample.timestamp,
        impactMagnitude: math.max(linearMag, jerk),
      );
    }

    return null;
  }

  void resetAfterUserResponse() {
    _lastFallDetectedAt = DateTime.now();
    _lastStepAt = null;
  }

  double _linearAcceleration(AccelerometerSample sample) {
    _gx = gravityAlpha * _gx + (1 - gravityAlpha) * sample.x;
    _gy = gravityAlpha * _gy + (1 - gravityAlpha) * sample.y;
    _gz = gravityAlpha * _gz + (1 - gravityAlpha) * sample.z;

    final lx = sample.x - _gx;
    final ly = sample.y - _gy;
    final lz = sample.z - _gz;
    return math.sqrt(lx * lx + ly * ly + lz * lz);
  }

  bool _isInCooldown(DateTime timestamp) {
    if (_lastFallDetectedAt == null) {
      return false;
    }
    return timestamp.difference(_lastFallDetectedAt!) < cooldown;
  }

  void _resetFilter() {
    _gx = 0;
    _gy = 0;
    _gz = 0;
    _prevLinearMag = 0;
    _sampleCount = 0;
  }
}
