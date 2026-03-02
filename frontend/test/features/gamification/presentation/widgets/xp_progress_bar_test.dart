import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_math_kids/features/gamification/presentation/widgets/xp_progress_bar.dart';

Widget buildTestWidget(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('XpProgressBar', () {
    testWidgets('renders level badge and XP text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpProgressBar(
            currentLevel: 5,
            xpInCurrentLevel: 200,
            xpForNextLevel: 500,
            totalXp: 1500,
            animate: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Lv.5'), findsOneWidget);
      expect(find.text('⭐ 1500 XP'), findsOneWidget);
      expect(find.text('200 / 500 XP'), findsOneWidget);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpProgressBar(
            currentLevel: 3,
            xpInCurrentLevel: 100,
            xpForNextLevel: 300,
            totalXp: 400,
            showLabel: false,
            animate: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Lv.3'), findsOneWidget);
      expect(find.text('100 / 300 XP'), findsNothing);
    });

    testWidgets('renders with zero progress', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpProgressBar(
            currentLevel: 1,
            xpInCurrentLevel: 0,
            xpForNextLevel: 100,
            totalXp: 0,
            animate: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Lv.1'), findsOneWidget);
      expect(find.text('⭐ 0 XP'), findsOneWidget);
    });

    testWidgets('renders with full progress', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpProgressBar(
            currentLevel: 10,
            xpInCurrentLevel: 500,
            xpForNextLevel: 500,
            totalXp: 5000,
            animate: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Lv.10'), findsOneWidget);
      expect(find.text('500 / 500 XP'), findsOneWidget);
    });

    testWidgets('handles custom height', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpProgressBar(
            currentLevel: 2,
            xpInCurrentLevel: 50,
            xpForNextLevel: 200,
            totalXp: 250,
            height: 30,
            animate: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(XpProgressBar), findsOneWidget);
    });
  });
}
