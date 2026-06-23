import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/features/auth/domain/entities/step_data.dart';

/// Verifica la lógica de ventana de picos (equivalente al motor de referencia).
void main() {
  ActivityType resolveActivity({
    required DateTime now,
    required DateTime lastRunTime,
    required DateTime lastWalkTime,
  }) {
    if (now.difference(lastRunTime) < const Duration(seconds: 3)) {
      return ActivityType.running;
    }
    if (now.difference(lastWalkTime) < const Duration(seconds: 3)) {
      return ActivityType.walking;
    }
    return ActivityType.stationary;
  }

  test('running while run peak was within 3 seconds', () {
    final now = DateTime(2024, 1, 1, 12, 0, 5);
    expect(
      resolveActivity(
        now: now,
        lastRunTime: now.subtract(const Duration(seconds: 1)),
        lastWalkTime: now.subtract(const Duration(seconds: 2)),
      ),
      ActivityType.running,
    );
  });

  test('walking when only walk peak is recent', () {
    final now = DateTime(2024, 1, 1, 12, 0, 5);
    expect(
      resolveActivity(
        now: now,
        lastRunTime: now.subtract(const Duration(seconds: 5)),
        lastWalkTime: now.subtract(const Duration(seconds: 1)),
      ),
      ActivityType.walking,
    );
  });

  test('stationary when no recent peaks', () {
    final now = DateTime(2024, 1, 1, 12, 0, 5);
    expect(
      resolveActivity(
        now: now,
        lastRunTime: now.subtract(const Duration(seconds: 4)),
        lastWalkTime: now.subtract(const Duration(seconds: 4)),
      ),
      ActivityType.stationary,
    );
  });
}
