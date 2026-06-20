import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/entities/physical_activity_type.dart';
import 'package:fitness_tracker/features/activity_monitor/domain/services/activity_debouncer.dart';

void main() {
  test('debouncer emits only after stability duration', () async {
    final debouncer = ActivityDebouncer(
      stabilityDuration: const Duration(milliseconds: 200),
    );

    PhysicalActivityType? confirmed;
    var isFirst = false;

    debouncer.listen((type, first) {
      confirmed = type;
      isFirst = first;
    });

    debouncer.onCandidate(PhysicalActivityType.walking);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(confirmed, isNull);

    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(confirmed, PhysicalActivityType.walking);
    expect(isFirst, isTrue);
  });

  test('debouncer ignores repeated same announced state', () async {
    final debouncer = ActivityDebouncer(
      stabilityDuration: const Duration(milliseconds: 100),
    );

    var callCount = 0;
    debouncer.listen((_, __) => callCount++);

    debouncer.onCandidate(PhysicalActivityType.running);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(callCount, 1);

    debouncer.onCandidate(PhysicalActivityType.running);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(callCount, 1);
  });

  test('debouncer announces again when state changes', () async {
    final debouncer = ActivityDebouncer(
      stabilityDuration: const Duration(milliseconds: 100),
      paceChangeDuration: const Duration(milliseconds: 100),
    );

    var callCount = 0;
    debouncer.listen((_, __) => callCount++);

    debouncer.onCandidate(PhysicalActivityType.walking);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    debouncer.onCandidate(PhysicalActivityType.running);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(callCount, 2);
  });

  test('cancelPending prevents pending announcement', () async {
    final debouncer = ActivityDebouncer(
      stabilityDuration: const Duration(milliseconds: 200),
    );

    var callCount = 0;
    debouncer.listen((_, __) => callCount++);

    debouncer.onCandidate(PhysicalActivityType.walking);
    debouncer.cancelPending();

    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(callCount, 0);
  });
}
