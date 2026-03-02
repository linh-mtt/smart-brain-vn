import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/exceptions.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/gamification/data/datasources/gamification_remote_datasource.dart';
import 'package:smart_math_kids/features/gamification/data/models/theme_list_model.dart';
import 'package:smart_math_kids/features/gamification/data/models/theme_model.dart';
import 'package:smart_math_kids/features/gamification/data/models/xp_profile_model.dart';
import 'package:smart_math_kids/features/gamification/data/repositories/gamification_repository_impl.dart';

class MockGamificationRemoteDatasource extends Mock
    implements GamificationRemoteDatasource {}

void main() {
  late MockGamificationRemoteDatasource mockDatasource;
  late GamificationRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockGamificationRemoteDatasource();
    repository = GamificationRepositoryImpl(remoteDatasource: mockDatasource);
  });

  // ─── Test Data ───────────────────────────────────────────────────────

  final tProfileModel = XpProfileModel(
    userId: 'user-1',
    totalXp: 1500,
    currentLevel: 5,
    xpInCurrentLevel: 200,
    xpForNextLevel: 500,
    xpProgressPercent: 40.0,
    unlockedAchievements: [
      UnlockedAchievementModel(
        id: 'ach-1',
        name: 'First Steps',
        description: 'Complete your first exercise',
        emoji: '🌟',
        rewardPoints: 50,
        unlockedAt: DateTime(2025, 1, 15),
      ),
    ],
    activeTheme: ThemeModel(
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

  final tThemeModel = ThemeModel(
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
  );

  final tThemeListModel = ThemeListModel(themes: [tThemeModel]);

  // ─── getXpProfile ────────────────────────────────────────────────────

  group('getXpProfile', () {
    test('returns success with entity when datasource succeeds', () async {
      when(
        () => mockDatasource.getXpProfile(),
      ).thenAnswer((_) async => tProfileModel);

      final result = await repository.getXpProfile();

      expect(result.isSuccess, true);
      final entity = result.dataOrNull!;
      expect(entity.userId, 'user-1');
      expect(entity.totalXp, 1500);
      expect(entity.currentLevel, 5);
      expect(entity.xpInCurrentLevel, 200);
      expect(entity.xpForNextLevel, 500);
      expect(entity.unlockedAchievements.length, 1);
      verify(() => mockDatasource.getXpProfile()).called(1);
    });

    test('returns failure when datasource throws AppException', () async {
      when(
        () => mockDatasource.getXpProfile(),
      ).thenThrow(const ServerException(message: 'Server error'));

      final result = await repository.getXpProfile();

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test(
      'returns UnknownFailure when datasource throws generic exception',
      () async {
        when(
          () => mockDatasource.getXpProfile(),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.getXpProfile();

        expect(result.isFailure, true);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });

  // ─── getThemes ────────────────────────────────────────────────────────

  group('getThemes', () {
    test(
      'returns success with list of entities when datasource succeeds',
      () async {
        when(
          () => mockDatasource.getThemes(),
        ).thenAnswer((_) async => tThemeListModel);

        final result = await repository.getThemes();

        expect(result.isSuccess, true);
        final entities = result.dataOrNull!;
        expect(entities.length, 1);
        expect(entities.first.name, 'Ocean');
        verify(() => mockDatasource.getThemes()).called(1);
      },
    );

    test('returns failure when datasource throws AppException', () async {
      when(
        () => mockDatasource.getThemes(),
      ).thenThrow(const ServerException(message: 'Server error'));

      final result = await repository.getThemes();

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test(
      'returns UnknownFailure when datasource throws generic exception',
      () async {
        when(
          () => mockDatasource.getThemes(),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.getThemes();

        expect(result.isFailure, true);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });

  // ─── unlockTheme ──────────────────────────────────────────────────────

  group('unlockTheme', () {
    test('returns success with entity when datasource succeeds', () async {
      when(
        () => mockDatasource.unlockTheme('theme-1'),
      ).thenAnswer((_) async => tThemeModel);

      final result = await repository.unlockTheme('theme-1');

      expect(result.isSuccess, true);
      final entity = result.dataOrNull!;
      expect(entity.name, 'Ocean');
      verify(() => mockDatasource.unlockTheme('theme-1')).called(1);
    });

    test('returns failure when datasource throws AppException', () async {
      when(
        () => mockDatasource.unlockTheme(any()),
      ).thenThrow(const ServerException(message: 'Server error'));

      final result = await repository.unlockTheme('theme-1');

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test(
      'returns UnknownFailure when datasource throws generic exception',
      () async {
        when(
          () => mockDatasource.unlockTheme(any()),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.unlockTheme('theme-1');

        expect(result.isFailure, true);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });

  // ─── activateTheme ────────────────────────────────────────────────────

  group('activateTheme', () {
    test('returns success when datasource succeeds', () async {
      when(
        () => mockDatasource.activateTheme('theme-1'),
      ).thenAnswer((_) async {});

      final result = await repository.activateTheme('theme-1');

      expect(result.isSuccess, true);
      verify(() => mockDatasource.activateTheme('theme-1')).called(1);
    });

    test('returns failure when datasource throws AppException', () async {
      when(
        () => mockDatasource.activateTheme(any()),
      ).thenThrow(const ServerException(message: 'Server error'));

      final result = await repository.activateTheme('theme-1');

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test(
      'returns UnknownFailure when datasource throws generic exception',
      () async {
        when(
          () => mockDatasource.activateTheme(any()),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.activateTheme('theme-1');

        expect(result.isFailure, true);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });
}
