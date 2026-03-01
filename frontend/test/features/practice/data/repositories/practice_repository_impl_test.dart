import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/exceptions.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/practice/data/datasources/practice_remote_datasource.dart';
import 'package:smart_math_kids/features/practice/data/models/practice_question_model.dart';
import 'package:smart_math_kids/features/practice/data/models/session_feedback_model.dart';
import 'package:smart_math_kids/features/practice/data/models/session_result_model.dart';
import 'package:smart_math_kids/features/practice/data/models/start_session_model.dart';
import 'package:smart_math_kids/features/practice/data/repositories/practice_repository_impl.dart';

class MockPracticeRemoteDatasource extends Mock
    implements PracticeRemoteDatasource {}

void main() {
  late MockPracticeRemoteDatasource mockDatasource;
  late PracticeRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockPracticeRemoteDatasource();
    repository = PracticeRepositoryImpl(remoteDatasource: mockDatasource);
  });

  final tQuestion = PracticeQuestionModel(
    id: 'q1',
    questionText: '2 + 3',
    correctAnswer: 5.0,
    options: ['3', '4', '5', '6'],
    explanation: 'Two plus three equals five',
    topic: 'addition',
    difficultyLevel: 1,
  );

  final tStartSessionModel = StartSessionModel(
    sessionId: 'sess-1',
    topic: 'addition',
    difficultyStart: 1,
    questions: [tQuestion],
  );

  final tSessionProgress = SessionProgressModel(
    totalQuestions: 5,
    correctCount: 1,
    totalPoints: 10,
    totalTimeMs: 3000,
    accuracy: 100.0,
  );

  final tFeedbackModel = SessionFeedbackModel(
    isCorrect: true,
    correctAnswer: 5.0,
    pointsEarned: 10,
    comboCount: 1,
    comboMultiplier: 1.0,
    maxCombo: 1,
    newDifficulty: 1,
    eloRating: 1000.0,
    streak: 1,
    weakTopics: [],
    sessionProgress: tSessionProgress,
  );

  final tResultDetail = ResultDetailModel(
    id: 'r1',
    questionText: '2 + 3',
    correctAnswer: 5.0,
    userAnswer: 5.0,
    isCorrect: true,
    pointsEarned: 10,
    comboCount: 1,
    comboMultiplier: 1.0,
    timeTakenMs: 3000,
    createdAt: DateTime(2025, 1, 1),
  );

  final tSessionResult = SessionResultModel(
    sessionId: 'sess-1',
    userId: 'user-1',
    topic: 'addition',
    status: 'completed',
    totalQuestions: 5,
    correctCount: 4,
    accuracy: 80.0,
    totalPoints: 80,
    totalTimeMs: 15000,
    maxCombo: 3,
    difficultyStart: 1,
    difficultyEnd: 2,
    startedAt: DateTime(2025, 1, 1),
    completedAt: DateTime(2025, 1, 1, 0, 5),
    results: [tResultDetail],
  );

  group('startSession', () {
    test(
      'returns Result.success with correct entity mapping on success',
      () async {
        when(
          () => mockDatasource.startSession(
            topic: any(named: 'topic'),
            questionCount: any(named: 'questionCount'),
          ),
        ).thenAnswer((_) async => tStartSessionModel);

        final result = await repository.startSession(topic: 'addition');

        expect(result.isSuccess, isTrue);
        final data = result.dataOrNull!;
        expect(data.sessionId, 'sess-1');
        expect(data.topic, 'addition');
        expect(data.difficultyStart, 1);
        expect(data.questions.length, 1);
        expect(data.questions.first.questionText, '2 + 3');
        expect(data.questions.first.correctAnswer, 5.0);
      },
    );

    test('returns ServerFailure on ServerException', () async {
      when(
        () => mockDatasource.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenThrow(ServerException(message: 'Server error'));

      final result = await repository.startSession(topic: 'addition');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('returns UnknownFailure on generic exception', () async {
      when(
        () => mockDatasource.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenThrow(Exception('unexpected'));

      final result = await repository.startSession(topic: 'addition');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });

  group('submitAnswer', () {
    test('returns Result.success with correct SessionFeedbackEntity', () async {
      when(
        () => mockDatasource.submitAnswer(
          sessionId: any(named: 'sessionId'),
          questionId: any(named: 'questionId'),
          topic: any(named: 'topic'),
          difficultyLevel: any(named: 'difficultyLevel'),
          questionText: any(named: 'questionText'),
          correctAnswer: any(named: 'correctAnswer'),
          answer: any(named: 'answer'),
          timeTakenMs: any(named: 'timeTakenMs'),
        ),
      ).thenAnswer((_) async => tFeedbackModel);

      final result = await repository.submitAnswer(
        sessionId: 'sess-1',
        questionId: 'q1',
        topic: 'addition',
        difficultyLevel: 1,
        questionText: '2 + 3',
        correctAnswer: 5.0,
        answer: 5.0,
        timeTakenMs: 3000,
      );

      expect(result.isSuccess, isTrue);
      final entity = result.dataOrNull!;
      expect(entity.isCorrect, isTrue);
      expect(entity.pointsEarned, 10);
      expect(entity.comboCount, 1);
      expect(entity.sessionProgress.totalPoints, 10);
      expect(entity.sessionProgress.accuracy, 100.0);
    });

    test('returns failure on ServerException', () async {
      when(
        () => mockDatasource.submitAnswer(
          sessionId: any(named: 'sessionId'),
          questionId: any(named: 'questionId'),
          topic: any(named: 'topic'),
          difficultyLevel: any(named: 'difficultyLevel'),
          questionText: any(named: 'questionText'),
          correctAnswer: any(named: 'correctAnswer'),
          answer: any(named: 'answer'),
          timeTakenMs: any(named: 'timeTakenMs'),
        ),
      ).thenThrow(ServerException(message: 'fail'));

      final result = await repository.submitAnswer(
        sessionId: 'sess-1',
        questionId: 'q1',
        topic: 'addition',
        difficultyLevel: 1,
        questionText: '2 + 3',
        correctAnswer: 5.0,
        answer: 5.0,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('getResult', () {
    test('returns Result.success with correct PracticeResultEntity', () async {
      when(
        () => mockDatasource.getResult(sessionId: any(named: 'sessionId')),
      ).thenAnswer((_) async => tSessionResult);

      final result = await repository.getResult(sessionId: 'sess-1');

      expect(result.isSuccess, isTrue);
      final entity = result.dataOrNull!;
      expect(entity.sessionId, 'sess-1');
      expect(entity.topic, 'addition');
      expect(entity.totalQuestions, 5);
      expect(entity.correctCount, 4);
      expect(entity.accuracy, 80.0);
      expect(entity.maxCombo, 3);
      expect(entity.results.length, 1);
      expect(entity.results.first.questionText, '2 + 3');
    });

    test('returns failure on exception', () async {
      when(
        () => mockDatasource.getResult(sessionId: any(named: 'sessionId')),
      ).thenThrow(ServerException(message: 'fail'));

      final result = await repository.getResult(sessionId: 'sess-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });
}
