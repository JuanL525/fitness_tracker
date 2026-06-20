import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/entities/movement_speed.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/entities/physical_activity_type.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/services/hybrid_activity_classifier.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/services/step_cadence_classifier.dart';

void main() {
  group('HybridActivityClassifier', () {
    test('overrides walking to running when GPS speed exceeds threshold', () {
      final classifier = HybridActivityClassifier();
      final gps = MovementSpeed(
        metersPerSecond: 3.5,
        accuracyMeters: 12,
        timestamp: DateTime.now(),
      );

      expect(
        classifier.classifyMovement(
          stepsPerMinute: 90,
          stepsStillComing: true,
          gps: gps,
        ),
        PhysicalActivityType.running,
      );
    });

    test('requires high cadence to switch to running', () {
      final classifier = HybridActivityClassifier();

      classifier.classifyMovement(
        stepsPerMinute: 100,
        stepsStillComing: true,
        gps: null,
      );
      expect(
        classifier.classifyMovement(
          stepsPerMinute: 130,
          stepsStillComing: true,
          gps: null,
        ),
        PhysicalActivityType.running,
      );
      expect(
        classifier.classifyMovement(
          stepsPerMinute: 150,
          stepsStillComing: true,
          gps: null,
        ),
        PhysicalActivityType.running,
      );
    });

    test('forces stationary when GPS confirms stop', () {
      final classifier = HybridActivityClassifier();
      final gps = MovementSpeed(
        metersPerSecond: 0.1,
        accuracyMeters: 10,
        timestamp: DateTime.now(),
      );

      expect(
        classifier.shouldForceStationary(
          sinceLastStepIncrease: const Duration(seconds: 4),
          stepsPerMinute: 40,
          gps: gps,
        ),
        isTrue,
      );
    });

    test('does not force stationary while steps are still arriving', () {
      final classifier = HybridActivityClassifier();

      expect(
        classifier.shouldForceStationary(
          sinceLastStepIncrease: const Duration(seconds: 1),
          stepsPerMinute: 90,
          gps: null,
        ),
        isFalse,
      );
    });
  });

  group('StepCadenceClassifier hysteresis', () {
    test('holds running until cadence drops below exit threshold', () {
      final classifier = StepCadenceClassifier();
      classifier.classify(stepsPerMinute: 150, stepsStillComing: true);
      expect(
        classifier.classify(stepsPerMinute: 125, stepsStillComing: true),
        PhysicalActivityType.running,
      );
    });
  });
}
