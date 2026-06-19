import 'dart:math' as math;

import '../entities/accelerometer_sample.dart';
import '../entities/physical_activity_type.dart';

/// Clasifica actividad usando aceleración **lineal** (sin gravedad).
/// Detecta caminar/correr aunque el celular esté casi quieto en la mano.
class ActivityClassifier {
  static const int historySize = 12;
  static const double gravityAlpha = 0.85;
  static const int confidenceRequired = 4;

  /// Umbrales sobre magnitud lineal promedio (m/s²).
  static const double stationaryThreshold = 0.85;
  static const double walkingThreshold = 2.4;

  double _gx = 0;
  double _gy = 0;
  double _gz = 0;
  int _warmupSamples = 0;
  final List<double> _linearHistory = [];
  PhysicalActivityType _lastCandidate = PhysicalActivityType.stationary;
  int _confidence = 0;

  PhysicalActivityState? classify(AccelerometerSample sample) {
    if (_warmupSamples < 15) {
      if (_warmupSamples == 0) {
        _gx = sample.x;
        _gy = sample.y;
        _gz = sample.z;
      } else {
        _linearMagnitude(sample);
      }
      _warmupSamples++;
      return null;
    }

    final linearMag = _linearMagnitude(sample);

    _linearHistory.add(linearMag);
    if (_linearHistory.length > historySize) {
      _linearHistory.removeAt(0);
    }

    if (_linearHistory.length < historySize) {
      return null;
    }

    final avgLinear =
        _linearHistory.reduce((a, b) => a + b) / _linearHistory.length;

    final newCandidate = _classifyFromLinear(avgLinear);

    if (newCandidate == _lastCandidate) {
      _confidence++;
    } else {
      _confidence = 0;
      _lastCandidate = newCandidate;
    }

    if (_confidence < confidenceRequired) {
      return null;
    }

    return PhysicalActivityState(
      type: newCandidate,
      smoothedMagnitude: avgLinear,
      timestamp: sample.timestamp,
    );
  }

  PhysicalActivityType _classifyFromLinear(double avgLinear) {
    if (avgLinear < stationaryThreshold) {
      return PhysicalActivityType.stationary;
    }
    if (avgLinear < walkingThreshold) {
      return PhysicalActivityType.walking;
    }
    return PhysicalActivityType.running;
  }

  double _linearMagnitude(AccelerometerSample sample) {
    _gx = gravityAlpha * _gx + (1 - gravityAlpha) * sample.x;
    _gy = gravityAlpha * _gy + (1 - gravityAlpha) * sample.y;
    _gz = gravityAlpha * _gz + (1 - gravityAlpha) * sample.z;

    final lx = sample.x - _gx;
    final ly = sample.y - _gy;
    final lz = sample.z - _gz;
    return math.sqrt(lx * lx + ly * ly + lz * lz);
  }

  void reset() {
    _linearHistory.clear();
    _lastCandidate = PhysicalActivityType.stationary;
    _confidence = 0;
    _gx = 0;
    _gy = 0;
    _gz = 0;
    _warmupSamples = 0;
  }
}
