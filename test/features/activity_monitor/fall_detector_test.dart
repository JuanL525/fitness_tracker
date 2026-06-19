import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/entities/accelerometer_sample.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/services/fall_detector.dart';

AccelerometerSample sampleAt(
  DateTime time, {
  double x = 0,
  double y = 0,
  double z = 9.8,
}) {
  return AccelerometerSample(x: x, y: y, z: z, timestamp: time);
}

void main() {
  late FallDetector detector;
  late DateTime baseTime;

  setUp(() {
    detector = FallDetector();
    baseTime = DateTime(2026, 1, 1, 12);
  });

  test('test mode triggers on strong shake after warmup', () {
    detector.setTestSensitivity(true);
    var t = baseTime;

    for (var i = 0; i < 20; i++) {
      detector.process(sampleAt(t));
      t = t.add(const Duration(milliseconds: 20));
    }

    final event = detector.process(
      sampleAt(t, x: 22, y: 15, z: 4),
    );

    expect(event, isNotNull);
  });

  test('does not alert while steps are recent', () {
    detector.onStepUpdate(5);
    var t = baseTime;

    for (var i = 0; i < 20; i++) {
      final event = detector.process(
        sampleAt(t, x: 22, y: 15, z: 4),
      );
      expect(event, isNull);
      t = t.add(const Duration(milliseconds: 20));
    }
  });
}
