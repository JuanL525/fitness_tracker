import '../../../auth/domain/entities/step_data.dart';
import '../entities/physical_activity_type.dart';

/// Cadencia de pasos: fuente principal para caminar vs correr.
class StepCadenceClassifier {
  static const double enterWalking = 55;
  static const double exitWalking = 45;
  static const double enterRunning = 110;
  static const double exitRunning = 100;
  static const double enterStationary = 25;
  static const double movementHoldSpm = 40;

  PhysicalActivityType _state = PhysicalActivityType.stationary;
  double _smoothedSpm = 0.0;

  void reset() {
    _state = PhysicalActivityType.stationary;
    _smoothedSpm = 0.0;
  }

  PhysicalActivityType get current => _state;

  PhysicalActivityType classify({
    required double stepsPerMinute,
    required bool stepsStillComing,
  }) {
    if (_smoothedSpm == 0.0) {
      _smoothedSpm = stepsPerMinute;
    } else {
      _smoothedSpm = (_smoothedSpm * 0.80) + (stepsPerMinute * 0.20);
    }
    final effectiveSpm = _smoothedSpm;

    final movementLikely =
        stepsStillComing || effectiveSpm >= movementHoldSpm;

    if (movementLikely && effectiveSpm < enterStationary) {
      if (_state != PhysicalActivityType.stationary) {
        return _state;
      }
    }

    switch (_state) {
      case PhysicalActivityType.running:
        if (effectiveSpm >= exitRunning) {
          return _state = PhysicalActivityType.running;
        }
        if (effectiveSpm >= enterWalking) {
          return _state = PhysicalActivityType.walking;
        }
        if (!movementLikely && effectiveSpm <= enterStationary) {
          return _state = PhysicalActivityType.stationary;
        }
        return _state;

      case PhysicalActivityType.walking:
        if (effectiveSpm >= enterRunning) {
          return _state = PhysicalActivityType.running;
        }
        if (effectiveSpm >= exitWalking) {
          return _state = PhysicalActivityType.walking;
        }
        if (!movementLikely && effectiveSpm <= enterStationary) {
          return _state = PhysicalActivityType.stationary;
        }
        return _state;

      case PhysicalActivityType.stationary:
        if (effectiveSpm >= enterRunning) {
          return _state = PhysicalActivityType.running;
        }
        if (effectiveSpm >= enterWalking) {
          return _state = PhysicalActivityType.walking;
        }
        return _state;
    }
  }
}

extension StepDataActivityX on StepData {
  PhysicalActivityType toPhysicalActivity(StepCadenceClassifier classifier) {
    return classifier.classify(
      stepsPerMinute: stepsPerMinute,
      stepsStillComing: false,
    );
  }
}
