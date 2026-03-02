import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_math_kids/features/gamification/presentation/widgets/level_up_animation.dart';

Widget buildTestWidget(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('LevelUpAnimation', () {
    testWidgets('renders level up text and level number', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const LevelUpAnimation(newLevel: 5, animate: false)),
      );
      await tester.pump();

      expect(find.text('LEVEL UP!'), findsOneWidget);
      expect(find.text('Level 5'), findsOneWidget);
      expect(find.text('🌟'), findsOneWidget);
    });

    testWidgets('renders tap to continue text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const LevelUpAnimation(newLevel: 10, animate: false)),
      );
      await tester.pump();

      expect(find.text('Tap to continue'), findsOneWidget);
    });

    testWidgets('calls onComplete when tapped', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        buildTestWidget(
          LevelUpAnimation(
            newLevel: 3,
            onComplete: () => completed = true,
            animate: false,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(completed, true);
    });

    testWidgets('renders different level numbers', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const LevelUpAnimation(newLevel: 99, animate: false)),
      );
      await tester.pump();

      expect(find.text('Level 99'), findsOneWidget);
    });
  });
}
