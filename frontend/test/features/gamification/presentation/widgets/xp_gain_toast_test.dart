import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_math_kids/features/gamification/presentation/widgets/xp_gain_toast.dart';

Widget buildTestWidget(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('XpGainToast', () {
    testWidgets('renders XP amount', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const XpGainToast(xpAmount: 50, animate: false)),
      );
      await tester.pump();

      expect(find.text('+50 XP'), findsOneWidget);
      expect(find.text('⚡'), findsOneWidget);
    });

    testWidgets('shows combo multiplier when provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpGainToast(xpAmount: 100, comboMultiplier: 3, animate: false),
        ),
      );
      await tester.pump();

      expect(find.text('+100 XP'), findsOneWidget);
      expect(find.text('3x'), findsOneWidget);
    });

    testWidgets('hides combo multiplier when not provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const XpGainToast(xpAmount: 25, animate: false)),
      );
      await tester.pump();

      expect(find.text('+25 XP'), findsOneWidget);
      // No combo badge should be shown
      expect(find.text('1x'), findsNothing);
    });

    testWidgets('hides combo multiplier when multiplier is 1', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpGainToast(xpAmount: 30, comboMultiplier: 1, animate: false),
        ),
      );
      await tester.pump();

      expect(find.text('+30 XP'), findsOneWidget);
      expect(find.text('1x'), findsNothing);
    });

    testWidgets('renders with large XP values', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpGainToast(xpAmount: 9999, comboMultiplier: 5, animate: false),
        ),
      );
      await tester.pump();

      expect(find.text('+9999 XP'), findsOneWidget);
      expect(find.text('5x'), findsOneWidget);
    });
  });
}
