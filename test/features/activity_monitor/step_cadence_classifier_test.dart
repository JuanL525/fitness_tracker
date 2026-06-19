import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/entities/physical_activity_type.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/services/step_cadence_classifier.dart';

void main() {
  group('StepCadenceClassifier', () {
    test('holds running while steps still coming despite low instant spm', () {
      final classifier = StepCadenceClassifier();
      classifier.classify(stepsPerMinute: 150, stepsStillComing: true);
      expect(classifier.current, PhysicalActivityType.running);

      final held = classifier.classify(
        stepsPerMinute: 20,
        stepsStillComing: true,
      );
      expect(held, PhysicalActivityType.running);
    });

    test('transitions running to walking with hysteresis', () {
      final classifier = StepCadenceClassifier();
      classifier.classify(stepsPerMinute: 150, stepsStillComing: true);
      expect(
        classifier.classify(stepsPerMinute: 125, stepsStillComing: true),
        PhysicalActivityType.running,
      );
      expect(
        classifier.classify(stepsPerMinute: 90, stepsStillComing: true),
        PhysicalActivityType.walking,
      );
    });

    test('does not enter stationary while cadence indicates movement', () {
      final classifier = StepCadenceClassifier();
      classifier.classify(stepsPerMinute: 80, stepsStillComing: true);
      expect(
        classifier.classify(stepsPerMinute: 35, stepsStillComing: false),
        PhysicalActivityType.walking,
      );
    });

    test('enters stationary only after movement stops and spm is low', () {
      final classifier = StepCadenceClassifier();
      classifier.classify(stepsPerMinute: 80, stepsStillComing: true);
      expect(
        classifier.classify(stepsPerMinute: 20, stepsStillComing: false),
        PhysicalActivityType.stationary,
      );
    });
  });
}
