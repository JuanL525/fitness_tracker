import '../entities/movement_speed.dart';
import '../entities/physical_activity_type.dart';
import 'speed_activity_classifier.dart';
import 'speed_smoother.dart';
import 'step_cadence_classifier.dart';

/// Caminar/correr por cadencia de pasos; GPS confirma quietud y corrige walk/run.
class HybridActivityClassifier {
  HybridActivityClassifier({
    SpeedActivityClassifier? speedClassifier,
    StepCadenceClassifier? cadenceClassifier,
    SpeedSmoother? speedSmoother,
  })  : _speedClassifier = speedClassifier ?? SpeedActivityClassifier(),
        _cadenceClassifier = cadenceClassifier ?? StepCadenceClassifier(),
        _speedSmoother = speedSmoother ?? SpeedSmoother();

  final SpeedActivityClassifier _speedClassifier;
  final StepCadenceClassifier _cadenceClassifier;
  final SpeedSmoother _speedSmoother;

  void reset() {
    _speedClassifier.reset();
    _cadenceClassifier.reset();
    _speedSmoother.reset();
  }

  PhysicalActivityType get current => _cadenceClassifier.current;

  bool shouldForceStationary({
    required Duration sinceLastStepIncrease,
    required double stepsPerMinute,
    MovementSpeed? gps,
  }) {
    if (sinceLastStepIncrease < const Duration(seconds: 3)) {
      return false;
    }

    if (gps?.isReliable == true) {
      final smoothed = _speedSmoother.smooth(gps!.metersPerSecond);
      return _speedClassifier.isLikelyStationary(smoothed);
    }

    return stepsPerMinute <= 5;
  }

  static const double _walkingToRunningSpeedMps = 2.2;

  PhysicalActivityType classifyMovement({
    required double stepsPerMinute,
    required bool stepsStillComing,
    MovementSpeed? gps,
  }) {
    double? smoothedSpeed;
    if (gps?.isReliable == true) {
      smoothedSpeed = _speedSmoother.smooth(gps!.metersPerSecond);
    }

    final cadenceType = _cadenceClassifier.classify(
      stepsPerMinute: stepsPerMinute,
      stepsStillComing: stepsStillComing,
    );

    if (cadenceType == PhysicalActivityType.stationary &&
        smoothedSpeed != null) {
      if (!_speedClassifier.isLikelyStationary(smoothedSpeed)) {
        return PhysicalActivityType.walking;
      }
    }

    if (cadenceType == PhysicalActivityType.walking &&
        smoothedSpeed != null &&
        smoothedSpeed > _walkingToRunningSpeedMps) {
      return PhysicalActivityType.running;
    }

    return cadenceType;
  }
}
