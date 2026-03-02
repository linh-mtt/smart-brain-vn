import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_math_kids/features/gamification/domain/entities/xp_profile_entity.dart';
import 'package:smart_math_kids/features/gamification/presentation/widgets/badge_popup_overlay.dart';

Widget buildTestWidget(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  final tAchievement = UnlockedAchievementEntity(
    id: 'ach-1',
    name: 'First Steps',
    description: 'Complete your first exercise',
    emoji: '🌟',
    rewardPoints: 50,
    unlockedAt: DateTime(2025, 1, 15),
  );

  group('BadgePopupOverlay', () {
    testWidgets('renders achievement details', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          BadgePopupOverlay(achievement: tAchievement, animate: false),
        ),
      );
      await tester.pump();

      expect(find.text('🌟'), findsOneWidget);
      expect(find.text('Achievement Unlocked!'), findsOneWidget);
      expect(find.text('First Steps'), findsOneWidget);
      expect(find.text('Complete your first exercise'), findsOneWidget);
      expect(find.text('+50 XP'), findsOneWidget);
    });

    testWidgets('shows tap to dismiss hint', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          BadgePopupOverlay(achievement: tAchievement, animate: false),
        ),
      );
      await tester.pump();

      expect(find.text('Tap anywhere to dismiss'), findsOneWidget);
    });

    testWidgets('calls onDismiss when tapped', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        buildTestWidget(
          BadgePopupOverlay(
            achievement: tAchievement,
            onDismiss: () => dismissed = true,
            animate: false,
          ),
        ),
      );
      await tester.pump();

      // Tap the InkWell area
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(dismissed, true);
    });

    testWidgets('renders with different achievement data', (tester) async {
      final otherAchievement = UnlockedAchievementEntity(
        id: 'ach-2',
        name: 'Speed Demon',
        description: 'Answer 10 questions in under 1 minute',
        emoji: '⚡',
        rewardPoints: 100,
        unlockedAt: DateTime(2025, 2, 1),
      );
      await tester.pumpWidget(
        buildTestWidget(
          BadgePopupOverlay(achievement: otherAchievement, animate: false),
        ),
      );
      await tester.pump();

      expect(find.text('⚡'), findsOneWidget);
      expect(find.text('Speed Demon'), findsOneWidget);
      expect(find.text('+100 XP'), findsOneWidget);
    });
  });
}
