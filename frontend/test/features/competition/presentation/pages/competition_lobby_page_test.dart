import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_math_kids/features/competition/domain/entities/match_entity.dart';
import 'package:smart_math_kids/features/competition/presentation/notifiers/match_notifier.dart';
import 'package:smart_math_kids/features/competition/presentation/notifiers/websocket_notifier.dart';
import 'package:smart_math_kids/features/competition/presentation/pages/competition_lobby_page.dart';
import 'package:smart_math_kids/features/competition/presentation/providers/competition_providers.dart';

// ============================================================================
// Test Notifiers
// ============================================================================

/// Custom MatchNotifier for testing that returns a fixed state without
/// reading providers in build().
class TestMatchNotifier extends MatchNotifier {
  TestMatchNotifier(this._initialState);
  final MatchState _initialState;

  @override
  MatchState build() => _initialState;

  @override
  Future<void> findMatch() async {}

  @override
  Future<void> submitAnswer(double answer) async {}

  @override
  Future<void> leaveMatch() async {}

  @override
  void reset() {}
}

/// Custom WebSocketNotifier for testing that returns a fixed state.
class TestWebSocketNotifier extends WebSocketNotifier {
  TestWebSocketNotifier(this._initialState);
  final WebSocketState _initialState;

  @override
  WebSocketState build() => _initialState;

  @override
  Future<void> connect(String token) async {}

  @override
  Future<void> disconnect() async {}
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Builds a test widget with the CompetitionLobbyPage and optional overrides.
Widget buildTestWidget({
  MatchState matchState = const MatchState(),
  WebSocketState wsState = const WebSocketState(),
}) {
  return ProviderScope(
    overrides: [
      matchNotifierProvider.overrideWith(() => TestMatchNotifier(matchState)),
      webSocketNotifierProvider.overrideWith(
        () => TestWebSocketNotifier(wsState),
      ),
    ],
    child: const MaterialApp(home: CompetitionLobbyPage()),
  );
}

// ============================================================================
// Main Test Suite
// ============================================================================

void main() {
  group('CompetitionLobbyPage Widget Tests', () {
    // ========================================================================
    // Test 1: Renders idle state initially (default — _isSearching = false)
    // ========================================================================
    testWidgets('renders idle state initially with Find Opponent button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should show idle state with "Find Opponent" button
      expect(find.byType(CompetitionLobbyPage), findsOneWidget);
      expect(
        find.text('Ready for a Math Battle?'),
        findsOneWidget,
        reason: 'Should display invitation heading',
      );
      expect(
        find.text('Find Opponent'),
        findsOneWidget,
        reason: 'Should show Find Opponent button',
      );
    });

    // ========================================================================
    // Test 2: Shows challenge description text
    // ========================================================================
    testWidgets('shows challenge description text in idle state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Challenge another player in a real-time math competition!'),
        findsOneWidget,
        reason: 'Should display challenge description',
      );
    });

    // ========================================================================
    // Test 3: Shows Competition title in app bar
    // ========================================================================
    testWidgets('shows Competition title in app bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Competition'),
        findsOneWidget,
        reason: 'Should display Competition title in AppBar',
      );
    });

    // ========================================================================
    // Test 4: Shows error state with error message and Try Again button
    // ========================================================================
    testWidgets('shows error message and Try Again button on error', (
      WidgetTester tester,
    ) async {
      const errorMessage = 'Connection failed. Please try again.';

      await tester.pumpWidget(
        buildTestWidget(
          matchState: const MatchState(
            status: MatchStatus.waiting,
            isLoading: false,
            error: errorMessage,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Error UI should be visible
      expect(
        find.text(errorMessage),
        findsOneWidget,
        reason: 'Should display error message',
      );
      expect(
        find.text('Try Again'),
        findsOneWidget,
        reason: 'Should show Try Again button when error occurs',
      );
      // Idle state elements should NOT be visible
      expect(
        find.text('Ready for a Math Battle?'),
        findsNothing,
        reason: 'Should not show idle heading in error state',
      );
      expect(
        find.text('Find Opponent'),
        findsNothing,
        reason: 'Should not show Find Opponent button in error state',
      );
    });

    // ========================================================================
    // Test 5: Error state shows sad emoji
    // ========================================================================
    testWidgets('error state displays sad emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          matchState: const MatchState(error: 'Network error occurred'),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('😕'),
        findsOneWidget,
        reason: 'Should show sad emoji on error',
      );
    });

    // ========================================================================
    // Test 6: No searching text in idle state
    // ========================================================================
    testWidgets('does not show searching text in idle state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Searching for opponent...'),
        findsNothing,
        reason: 'Should not show searching text in idle state',
      );
    });

    // ========================================================================
    // Test 7: Has back button in app bar
    // ========================================================================
    testWidgets('has back button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byIcon(Icons.arrow_back),
        findsOneWidget,
        reason: 'Should have back button in app bar',
      );
    });

    // ========================================================================
    // Test 8: Error state hides idle UI elements
    // ========================================================================
    testWidgets('error state hides idle UI elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          matchState: const MatchState(error: 'Something went wrong'),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Error state should show error UI, not idle UI
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(
        find.text('🎮'),
        findsNothing,
        reason: 'Game emoji should not show in error state',
      );
    });
  });
}
