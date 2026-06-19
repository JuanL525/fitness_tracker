import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/entities/accelerometer_sample.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/entities/physical_activity_type.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/services/activity_classifier.dart';

void main() {
  late ActivityClassifier classifier;

  setUp(() {
    classifier = ActivityClassifier();
  });

  test('classifies stationary with minimal linear acceleration', () {
    PhysicalActivityState? result;

    for (var i = 0; i < 35; i++) {
      result = classifier.classify(
        AccelerometerSample(x: 0, y: 0, z: 9.8),
      );
    }

    expect(result, isNotNull);
    expect(result!.type, PhysicalActivityType.stationary);
  });

  test('classifies walking with moderate oscillation', () {
    PhysicalActivityState? result;

    for (var i = 0; i < 45; i++) {
      final swing = (i.isEven ? 1.4 : -1.4);
      result = classifier.classify(
        AccelerometerSample(x: swing, y: swing * 0.5, z: 9.8),
      );
    }

    expect(result, isNotNull);
    expect(result!.type, PhysicalActivityType.walking);
  });

  test('classifies running with strong oscillation', () {
    PhysicalActivityState? result;

    for (var i = 0; i < 45; i++) {
      final swing = (i.isEven ? 3.5 : -3.5);
      result = classifier.classify(
        AccelerometerSample(x: swing, y: swing, z: 9.5),
      );
    }

    expect(result, isNotNull);
    expect(result!.type, PhysicalActivityType.running);
  });
}
