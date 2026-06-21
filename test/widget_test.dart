import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/core/di/injection.dart';
import 'package:fitness_tracker/main.dart';

void main() {
  testWidgets('Fitness app loads login screen', (WidgetTester tester) async {
    await setupDependencyInjection();
    await tester.pumpWidget(const FitnessApp());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Fitness Tracker'), findsOneWidget);
    expect(find.text('Toca para autenticar con huella'), findsOneWidget);
  });
}
