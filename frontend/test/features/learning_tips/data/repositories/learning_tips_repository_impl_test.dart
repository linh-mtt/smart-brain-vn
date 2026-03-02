import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/exceptions.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/learning_tips/data/datasources/learning_tips_local_datasource.dart';
import 'package:smart_math_kids/features/learning_tips/data/repositories/learning_tips_repository_impl.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/learning_tip_entity.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/quiz_question_entity.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/tip_progress_entity.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/tip_step_entity.dart';

class MockLearningTipsLocalDatasource extends Mock
    implements LearningTipsLocalDatasource {}

void main() {
  late MockLearningTipsLocalDatasource mockDatasource;
  late LearningTipsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockDatasource = MockLearningTipsLocalDatasource();
    repository = LearningTipsRepositoryImpl(localDatasource: mockDatasource);
  });

  final tTip = LearningTipEntity(
    id: 'tip_1',
    title: 'Test Tip',
    description: 'desc',
    category: 'addition',
    icon: '➕',
    difficulty: 1,
    steps: const [
      TipStepEntity(title: 'Step 1', content: 'content', example: 'ex'),
    ],
    quizQuestions: const [
      QuizQuestionEntity(
        id: 'q1',
        question: 'Q?',
        options: ['A', 'B', 'C', 'D'],
        correctIndex: 0,
        explanation: 'Because',
      ),
    ],
    animationAsset: 'assets/test.json',
    color: '#FF0000',
  );

  final tProgress = TipProgressEntity(
    tipId: 'tip_1',
    isCompleted: true,
    quizScore: 2,
    quizTotal: 3,
  );

  group('getAllTips', () {
    test('returns Result.success with correct data on success', () async {
      when(() => mockDatasource.getAllTipContent()).thenReturn([tTip]);

      final result = await repository.getAllTips();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals([tTip]));
      expect(result.dataOrNull?.first.id, 'tip_1');
      expect(result.dataOrNull?.first.title, 'Test Tip');
    });

    test(
      'returns Result.failure with CacheFailure on CacheException',
      () async {
        when(
          () => mockDatasource.getAllTipContent(),
        ).thenThrow(CacheException(message: 'Cache error'));

        final result = await repository.getAllTips();

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<CacheFailure>());
      },
    );

    test(
      'returns Result.failure with UnknownFailure on generic exception',
      () async {
        when(
          () => mockDatasource.getAllTipContent(),
        ).thenThrow(Exception('oops'));

        final result = await repository.getAllTips();

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });

  group('getTipById', () {
    test('returns Result.success with correct tip on success', () async {
      when(() => mockDatasource.getTipContentById('tip_1')).thenReturn(tTip);

      final result = await repository.getTipById('tip_1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(tTip));
      expect(result.dataOrNull?.id, 'tip_1');
      expect(result.dataOrNull?.title, 'Test Tip');
    });

    test(
      'returns Result.failure with CacheFailure on CacheException',
      () async {
        when(
          () => mockDatasource.getTipContentById('tip_1'),
        ).thenThrow(CacheException(message: 'Tip not found'));

        final result = await repository.getTipById('tip_1');

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<CacheFailure>());
      },
    );

    test(
      'returns Result.failure with UnknownFailure on generic exception',
      () async {
        when(
          () => mockDatasource.getTipContentById('tip_1'),
        ).thenThrow(Exception('oops'));

        final result = await repository.getTipById('tip_1');

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });

  group('getAllProgress', () {
    test('returns Result.success with correct data on success', () async {
      when(
        () => mockDatasource.getAllProgress(),
      ).thenAnswer((_) async => [tProgress]);

      final result = await repository.getAllProgress();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals([tProgress]));
      expect(result.dataOrNull?.first.tipId, 'tip_1');
      expect(result.dataOrNull?.first.isCompleted, isTrue);
      expect(result.dataOrNull?.first.quizScore, 2);
      expect(result.dataOrNull?.first.quizTotal, 3);
    });

    test(
      'returns Result.failure with CacheFailure on CacheException',
      () async {
        when(
          () => mockDatasource.getAllProgress(),
        ).thenThrow(CacheException(message: 'Failed to read progress'));

        final result = await repository.getAllProgress();

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<CacheFailure>());
      },
    );

    test(
      'returns Result.failure with UnknownFailure on generic exception',
      () async {
        when(
          () => mockDatasource.getAllProgress(),
        ).thenThrow(Exception('oops'));

        final result = await repository.getAllProgress();

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });

  group('markTipCompleted', () {
    test('returns Result.success on success', () async {
      when(
        () => mockDatasource.saveProgress(any(), any()),
      ).thenAnswer((_) async => {});

      final result = await repository.markTipCompleted(
        'tip_1',
        quizScore: 2,
        quizTotal: 3,
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockDatasource.saveProgress('tip_1', any())).called(1);
    });

    test(
      'saveProgress is called with correct tip ID and progress data',
      () async {
        when(
          () => mockDatasource.saveProgress(any(), any()),
        ).thenAnswer((_) async => {});

        await repository.markTipCompleted('tip_1', quizScore: 2, quizTotal: 3);

        verify(() => mockDatasource.saveProgress('tip_1', any())).called(1);
      },
    );

    test(
      'returns Result.failure with CacheFailure on CacheException',
      () async {
        when(
          () => mockDatasource.saveProgress(any(), any()),
        ).thenThrow(CacheException(message: 'Failed to save progress'));

        final result = await repository.markTipCompleted('tip_1');

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<CacheFailure>());
      },
    );

    test(
      'returns Result.failure with UnknownFailure on generic exception',
      () async {
        when(
          () => mockDatasource.saveProgress(any(), any()),
        ).thenThrow(Exception('oops'));

        final result = await repository.markTipCompleted('tip_1');

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });

  group('resetProgress', () {
    test('returns Result.success on success', () async {
      when(() => mockDatasource.clearAllProgress()).thenAnswer((_) async => {});

      final result = await repository.resetProgress();

      expect(result.isSuccess, isTrue);
      verify(() => mockDatasource.clearAllProgress()).called(1);
    });

    test(
      'returns Result.failure with CacheFailure on CacheException',
      () async {
        when(
          () => mockDatasource.clearAllProgress(),
        ).thenThrow(CacheException(message: 'Failed to clear progress'));

        final result = await repository.resetProgress();

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<CacheFailure>());
      },
    );

    test(
      'returns Result.failure with UnknownFailure on generic exception',
      () async {
        when(
          () => mockDatasource.clearAllProgress(),
        ).thenThrow(Exception('oops'));

        final result = await repository.resetProgress();

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });
}
