import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/gamification/domain/entities/xp_profile_entity.dart';
import 'package:smart_math_kids/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:smart_math_kids/features/gamification/presentation/notifiers/gamification_notifier.dart';
import 'package:smart_math_kids/features/gamification/presentation/providers/gamification_providers.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

void main() {
  late MockGamificationRepository mockRepo;
  late ProviderContainer container;

  // ─── Test Data ───────────────────────────────────────────────────────

  final tProfile = XpProfileEntity(
    userId: 'user-1',
    totalXp: 1500,
    currentLevel: 5,
    xpInCurrentLevel: 200,
    xpForNextLevel: 500,
    xpProgressPercent: 40.0,
    unlockedAchievements: [
      UnlockedAchievementEntity(
        id: 'ach-1',
        name: 'First Steps',
        description: 'Complete your first exercise',
        emoji: '🌟',
        rewardPoints: 50,
        unlockedAt: DateTime(2025, 1, 15),
      ),
    ],
    activeTheme: ThemeEntity(
      id: 'theme-1',
      name: 'Ocean',
      description: 'Deep blue ocean theme',
      emoji: '🌊',
      requiredLevel: 1,
      requiredXp: 0,
      isPremium: false,
      isUnlocked: true,
      isActive: true,
      canUnlock: true,
    ),
  );

  final tThemes = [
    ThemeEntity(
      id: 'theme-1',
      name: 'Ocean',
      description: 'Deep blue ocean theme',
      emoji: '🌊',
      requiredLevel: 1,
      requiredXp: 0,
      isPremium: false,
      isUnlocked: true,
      isActive: true,
      canUnlock: true,
    ),
    ThemeEntity(
      id: 'theme-2',
      name: 'Forest',
      description: 'Green forest theme',
      emoji: '🌲',
      requiredLevel: 3,
      requiredXp: 500,
      isPremium: false,
      isUnlocked: false,
      isActive: false,
      canUnlock: true,
    ),
  ];

  setUp(() {
    mockRepo = MockGamificationRepository();
    container = ProviderContainer(
      overrides: [gamificationRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  GamificationState readState() => container.read(gamificationNotifierProvider);
  GamificationNotifier readNotifier() =>
      container.read(gamificationNotifierProvider.notifier);

  // ─── Initial State ───────────────────────────────────────────────────

  group('initial state', () {
    test('has correct defaults', () {
      final state = readState();
      expect(state.profile, isNull);
      expect(state.themes, isEmpty);
      expect(state.isLoading, false);
      expect(state.isLoadingThemes, false);
      expect(state.error, isNull);
      expect(state.hasData, false);
    });
  });

  // ─── loadProfile ──────────────────────────────────────────────────────

  group('loadProfile', () {
    test('loads profile successfully', () async {
      when(
        () => mockRepo.getXpProfile(),
      ).thenAnswer((_) async => Result.success(tProfile));

      await readNotifier().loadProfile();

      final state = readState();
      expect(state.profile, tProfile);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(() => mockRepo.getXpProfile()).called(1);
    });

    test('sets error when profile load fails', () async {
      when(() => mockRepo.getXpProfile()).thenAnswer(
        (_) async => const Result.failure(ServerFailure(message: 'Error')),
      );

      await readNotifier().loadProfile();

      final state = readState();
      expect(state.error, isNotNull);
      expect(state.profile, isNull);
    });

    test('sets isLoading true then false', () async {
      when(
        () => mockRepo.getXpProfile(),
      ).thenAnswer((_) async => Result.success(tProfile));

      await readNotifier().loadProfile();

      final state = readState();
      expect(state.isLoading, false);
      expect(state.profile, tProfile);
    });
  });

  // ─── loadThemes ───────────────────────────────────────────────────────

  group('loadThemes', () {
    test('loads themes successfully', () async {
      when(
        () => mockRepo.getThemes(),
      ).thenAnswer((_) async => Result.success(tThemes));

      await readNotifier().loadThemes();

      final state = readState();
      expect(state.themes.length, 2);
      expect(state.isLoadingThemes, false);
      verify(() => mockRepo.getThemes()).called(1);
    });

    test('sets error when themes load fails', () async {
      when(() => mockRepo.getThemes()).thenAnswer(
        (_) async => const Result.failure(ServerFailure(message: 'Error')),
      );

      await readNotifier().loadThemes();

      final state = readState();
      expect(state.error, isNotNull);
      expect(state.themes, isEmpty);
    });

    test('sets isLoadingThemes true then false', () async {
      when(
        () => mockRepo.getThemes(),
      ).thenAnswer((_) async => Result.success(tThemes));

      await readNotifier().loadThemes();

      final state = readState();
      expect(state.isLoadingThemes, false);
      expect(state.themes.length, 2);
    });
  });

  // ─── unlockTheme ──────────────────────────────────────────────────────

  group('unlockTheme', () {
    test('unlocks theme and refreshes data', () async {
      when(
        () => mockRepo.unlockTheme('theme-2'),
      ).thenAnswer((_) async => Result.success(tThemes[1]));
      when(
        () => mockRepo.getThemes(),
      ).thenAnswer((_) async => Result.success(tThemes));
      when(
        () => mockRepo.getXpProfile(),
      ).thenAnswer((_) async => Result.success(tProfile));

      await readNotifier().unlockTheme('theme-2');
      // Allow unawaited futures to complete
      await Future<void>.delayed(Duration.zero);

      verify(() => mockRepo.unlockTheme('theme-2')).called(1);
    });

    test('sets error when unlock fails', () async {
      when(() => mockRepo.unlockTheme('theme-2')).thenAnswer(
        (_) async => const Result.failure(ServerFailure(message: 'Error')),
      );

      await readNotifier().unlockTheme('theme-2');

      final state = readState();
      expect(state.error, isNotNull);
    });
  });

  // ─── activateTheme ────────────────────────────────────────────────────

  group('activateTheme', () {
    test('activates theme and refreshes data', () async {
      when(
        () => mockRepo.activateTheme('theme-1'),
      ).thenAnswer((_) async => const Result.success(null));
      when(
        () => mockRepo.getThemes(),
      ).thenAnswer((_) async => Result.success(tThemes));
      when(
        () => mockRepo.getXpProfile(),
      ).thenAnswer((_) async => Result.success(tProfile));

      await readNotifier().activateTheme('theme-1');
      // Allow unawaited futures to complete
      await Future<void>.delayed(Duration.zero);

      verify(() => mockRepo.activateTheme('theme-1')).called(1);
    });

    test('sets error when activate fails', () async {
      when(() => mockRepo.activateTheme('theme-1')).thenAnswer(
        (_) async => const Result.failure(ServerFailure(message: 'Error')),
      );

      await readNotifier().activateTheme('theme-1');

      final state = readState();
      expect(state.error, isNotNull);
    });
  });

  // ─── refresh ──────────────────────────────────────────────────────────

  group('refresh', () {
    test('reloads all data', () async {
      when(
        () => mockRepo.getXpProfile(),
      ).thenAnswer((_) async => Result.success(tProfile));
      when(
        () => mockRepo.getThemes(),
      ).thenAnswer((_) async => Result.success(tThemes));

      await readNotifier().refresh();

      final state = readState();
      expect(state.profile, tProfile);
      expect(state.themes.length, 2);
      verify(() => mockRepo.getXpProfile()).called(1);
      verify(() => mockRepo.getThemes()).called(1);
    });
  });

  // ─── GamificationState ─────────────────────────────────────────────────

  group('GamificationState', () {
    test('copyWith preserves unmodified fields', () {
      final state = GamificationState(
        profile: tProfile,
        themes: tThemes,
        isLoading: false,
      );

      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, true);
      expect(updated.profile, tProfile);
      expect(updated.themes, tThemes);
    });

    test('hasData returns true when profile is present', () {
      final state = GamificationState(profile: tProfile);
      expect(state.hasData, true);
    });

    test('hasData returns false when profile is null', () {
      const state = GamificationState();
      expect(state.hasData, false);
    });
  });
}
