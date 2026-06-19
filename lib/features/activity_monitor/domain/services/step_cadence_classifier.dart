import '../../../auth/domain/entities/step_data.dart';
import '../entities/physical_activity_type.dart';

/// Cadencia de pasos: fuente principal para caminar vs correr.
class StepCadenceClassifier {
  static const double enterWalking = 70;
  static const double exitWalking = 55;
  static const double enterRunning = 145;
  static const double exitRunning = 120;
  static const double enterStationary = 25;
  static const double movementHoldSpm = 40;

  PhysicalActivityType _state = PhysicalActivityType.stationary;

  void reset() {
    _state = PhysicalActivityType.stationary;
  }

  PhysicalActivityType get current => _state;

  PhysicalActivityType classify({
    required double stepsPerMinute,
    required bool stepsStillComing,
  }) {
    final movementLikely =
        stepsStillComing || stepsPerMinute >= movementHoldSpm;

    if (movementLikely && stepsPerMinute < enterStationary) {
      if (_state != PhysicalActivityType.stationary) {
        return _state;
      }
    }

    switch (_state) {
      case PhysicalActivityType.running:
        if (stepsPerMinute >= exitRunning) {
          return _state = PhysicalActivityType.running;
        }
        if (stepsPerMinute >= enterWalking) {
          return _state = PhysicalActivityType.walking;
        }
        if (!movementLikely && stepsPerMinute <= enterStationary) {
          return _state = PhysicalActivityType.stationary;
        }
        return _state;

      case PhysicalActivityType.walking:
        if (stepsPerMinute >= enterRunning) {
          return _state = PhysicalActivityType.running;
        }
        if (stepsPerMinute >= exitWalking) {
          return _state = PhysicalActivityType.walking;
        }
        if (!movementLikely && stepsPerMinute <= enterStationary) {
          return _state = PhysicalActivityType.stationary;
        }
        return _state;

      case PhysicalActivityType.stationary:
        if (stepsPerMinute >= enterRunning) {
          return _state = PhysicalActivityType.running;
        }
        if (stepsPerMinute >= enterWalking) {
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
