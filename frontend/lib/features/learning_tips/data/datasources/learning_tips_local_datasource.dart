import 'dart:convert';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/hive_service.dart';
import '../../domain/entities/learning_tip_entity.dart';
import '../../domain/entities/quiz_question_entity.dart';
import '../../domain/entities/tip_progress_entity.dart';
import '../../domain/entities/tip_step_entity.dart';

/// Key prefix for tip progress entries in Hive cache box.
const String _progressKeyPrefix = 'learning_tip_progress_';

/// Local datasource for Learning Tips.
///
/// Tip content is hardcoded (no network). Only progress tracking
/// uses [HiveService] for persistence.
class LearningTipsLocalDatasource {
  LearningTipsLocalDatasource({required HiveService hiveService})
    : _hiveService = hiveService;

  final HiveService _hiveService;

  // ─── Tip Content ─────────────────────────────────────────────────────

  /// Returns all hardcoded learning tips.
  List<LearningTipEntity> getAllTipContent() => _allTips;

  /// Returns a single tip by [tipId], or throws [CacheException] if not found.
  LearningTipEntity getTipContentById(String tipId) {
    final tip = _allTips.where((t) => t.id == tipId).firstOrNull;
    if (tip == null) {
      throw CacheException(message: 'Tip not found: $tipId');
    }
    return tip;
  }

  // ─── Progress Persistence ────────────────────────────────────────────

  /// Gets progress for a single tip, or null if none saved.
  Future<TipProgressEntity?> getProgress(String tipId) async {
    try {
      final json = await _hiveService.getValue<String>(
        HiveService.cacheBox,
        '$_progressKeyPrefix$tipId',
      );
      if (json == null) return null;
      return _progressFromJson(tipId, jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      throw CacheException(message: 'Failed to read progress: ${e.toString()}');
    }
  }

  /// Gets progress for all tips that have been saved.
  Future<List<TipProgressEntity>> getAllProgress() async {
    try {
      final progressList = <TipProgressEntity>[];
      for (final tip in _allTips) {
        final json = await _hiveService.getValue<String>(
          HiveService.cacheBox,
          '$_progressKeyPrefix${tip.id}',
        );
        if (json != null) {
          progressList.add(
            _progressFromJson(tip.id, jsonDecode(json) as Map<String, dynamic>),
          );
        }
      }
      return progressList;
    } catch (e) {
      throw CacheException(
        message: 'Failed to read all progress: ${e.toString()}',
      );
    }
  }

  /// Saves progress for a tip.
  Future<void> saveProgress(
    String tipId,
    Map<String, dynamic> progressData,
  ) async {
    try {
      await _hiveService.putValue<String>(
        HiveService.cacheBox,
        '$_progressKeyPrefix$tipId',
        jsonEncode(progressData),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save progress: ${e.toString()}');
    }
  }

  /// Clears all tip progress from cache.
  Future<void> clearAllProgress() async {
    try {
      for (final tip in _allTips) {
        await _hiveService.deleteValue(
          HiveService.cacheBox,
          '$_progressKeyPrefix${tip.id}',
        );
      }
    } catch (e) {
      throw CacheException(
        message: 'Failed to clear progress: ${e.toString()}',
      );
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  TipProgressEntity _progressFromJson(String tipId, Map<String, dynamic> json) {
    return TipProgressEntity(
      tipId: tipId,
      isCompleted: json['isCompleted'] as bool? ?? false,
      quizScore: json['quizScore'] as int?,
      quizTotal: json['quizTotal'] as int?,
      lastViewedAt: json['lastViewedAt'] != null
          ? DateTime.parse(json['lastViewedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Hardcoded Tip Content
// ═══════════════════════════════════════════════════════════════════════════

final List<LearningTipEntity> _allTips = [
  // ─── Addition Tips ───────────────────────────────────────────────────
  LearningTipEntity(
    id: 'tip_add_9',
    title: 'Adding 9 Trick',
    description: 'Add 10 then subtract 1 — the fastest way to add 9!',
    category: 'addition',
    icon: '➕',
    difficulty: 1,
    animationAsset: 'assets/animations/tip_addition.json',
    color: '#FF6B6B',
    steps: const [
      TipStepEntity(
        title: 'The Idea',
        content:
            'Adding 9 is almost like adding 10. So add 10 first, then take away 1!',
        example: '27 + 9 → think 27 + 10 - 1',
        visualHint: '🔟 ➡️ ➖1️⃣',
      ),
      TipStepEntity(
        title: 'Try It',
        content:
            'Step 1: Add 10 to the number.\nStep 2: Subtract 1 from the result.',
        example: '27 + 10 = 37, then 37 - 1 = 36 ✓',
      ),
      TipStepEntity(
        title: 'More Examples',
        content: 'This works with any number! Practice a few more:',
        example: '45 + 9 = 45 + 10 - 1 = 54\n68 + 9 = 68 + 10 - 1 = 77',
      ),
    ],
    quizQuestions: const [
      QuizQuestionEntity(
        id: 'tip_add_9_q1',
        question: 'What is 34 + 9 using the Adding 9 trick?',
        options: ['42', '43', '44', '45'],
        correctIndex: 1,
        explanation: '34 + 10 = 44, then 44 - 1 = 43',
      ),
      QuizQuestionEntity(
        id: 'tip_add_9_q2',
        question: 'What is the first step in the Adding 9 trick?',
        options: ['Subtract 1', 'Add 9 directly', 'Add 10', 'Multiply by 9'],
        correctIndex: 2,
        explanation: 'First add 10 (which is easy), then subtract 1.',
      ),
      QuizQuestionEntity(
        id: 'tip_add_9_q3',
        question: 'What is 56 + 9?',
        options: ['64', '65', '66', '63'],
        correctIndex: 1,
        explanation: '56 + 10 = 66, then 66 - 1 = 65',
      ),
    ],
  ),

  LearningTipEntity(
    id: 'tip_doubles',
    title: 'Double Numbers',
    description: 'Use doubles you already know to add nearby numbers fast!',
    category: 'addition',
    icon: '➕',
    difficulty: 1,
    animationAsset: 'assets/animations/tip_addition.json',
    color: '#FF8E8E',
    steps: const [
      TipStepEntity(
        title: 'Doubles Are Easy',
        content:
            'You probably already know doubles: 6+6=12, 7+7=14, 8+8=16. '
            'Use them to solve nearby additions!',
        example: '7 + 8 → think 7 + 7 + 1',
        visualHint: '👯 ➕ 1️⃣',
      ),
      TipStepEntity(
        title: 'Doubles Plus One',
        content:
            'When two numbers are 1 apart, double the smaller one and add 1.',
        example: '7 + 8 = 7 + 7 + 1 = 14 + 1 = 15',
      ),
      TipStepEntity(
        title: 'Doubles Minus One',
        content: 'You can also double the bigger number and subtract 1.',
        example: '7 + 8 = 8 + 8 - 1 = 16 - 1 = 15',
      ),
    ],
    quizQuestions: const [
      QuizQuestionEntity(
        id: 'tip_doubles_q1',
        question: 'Using the doubles strategy, what is 8 + 9?',
        options: ['16', '17', '18', '15'],
        correctIndex: 1,
        explanation: '8 + 9 = 8 + 8 + 1 = 16 + 1 = 17',
      ),
      QuizQuestionEntity(
        id: 'tip_doubles_q2',
        question: 'What double helps you solve 6 + 7?',
        options: ['5 + 5', '6 + 6', '7 + 7', '8 + 8'],
        correctIndex: 1,
        explanation:
            '6 + 6 = 12, then add 1 to get 13. Or 7 + 7 = 14, minus 1 = 13.',
      ),
      QuizQuestionEntity(
        id: 'tip_doubles_q3',
        question: 'What is 15 + 16 using the doubles strategy?',
        options: ['29', '30', '31', '32'],
        correctIndex: 2,
        explanation: '15 + 15 = 30, then 30 + 1 = 31',
      ),
    ],
  ),

  // ─── Multiplication Tips ─────────────────────────────────────────────
  LearningTipEntity(
    id: 'tip_mult_9_finger',
    title: 'Multiply by 9 Finger Trick',
    description: 'Use your fingers to multiply any number by 9 instantly!',
    category: 'multiplication',
    icon: '✖️',
    difficulty: 2,
    animationAsset: 'assets/animations/tip_multiplication.json',
    color: '#4ECDC4',
    steps: const [
      TipStepEntity(
        title: 'Hold Up Your Hands',
        content: 'Hold up all 10 fingers. Number them 1-10 from left to right.',
        example: 'To solve 9 × 4, fold down finger #4',
        visualHint: '🖐️🖐️ → fold finger 4',
      ),
      TipStepEntity(
        title: 'Fold and Count',
        content:
            'Fold down the finger matching the number you multiply by 9.\n'
            'Fingers LEFT of the fold = tens digit.\n'
            'Fingers RIGHT of the fold = ones digit.',
        example: '9 × 4: fold finger 4 → 3 left | 6 right → 36',
      ),
      TipStepEntity(
        title: 'Practice More',
        content: 'Try it with different numbers from 1 to 10!',
        example:
            '9 × 3: fold finger 3 → 2 left | 7 right → 27\n'
            '9 × 7: fold finger 7 → 6 left | 3 right → 63',
      ),
    ],
    quizQuestions: const [
      QuizQuestionEntity(
        id: 'tip_mult_9_q1',
        question: 'Using the finger trick, what is 9 × 6?',
        options: ['45', '54', '56', '63'],
        correctIndex: 1,
        explanation:
            'Fold finger 6: 5 fingers left (tens), 4 fingers right (ones) → 54',
      ),
      QuizQuestionEntity(
        id: 'tip_mult_9_q2',
        question: 'When you fold finger #8, how many fingers are to the LEFT?',
        options: ['6', '7', '8', '9'],
        correctIndex: 1,
        explanation: 'Fingers 1-7 are to the left of finger 8, so 7 fingers.',
      ),
      QuizQuestionEntity(
        id: 'tip_mult_9_q3',
        question: 'What is 9 × 5 using the finger trick?',
        options: ['36', '40', '45', '54'],
        correctIndex: 2,
        explanation: 'Fold finger 5: 4 fingers left, 5 fingers right → 45',
      ),
    ],
  ),

  LearningTipEntity(
    id: 'tip_mult_5',
    title: 'Multiply by 5',
    description: 'Multiply by 10 then halve — super quick for ×5!',
    category: 'multiplication',
    icon: '✖️',
    difficulty: 2,
    animationAsset: 'assets/animations/tip_multiplication.json',
    color: '#45B7D1',
    steps: const [
      TipStepEntity(
        title: 'The Shortcut',
        content:
            'Multiplying by 5 is the same as multiplying by 10 and dividing by 2. '
            'Multiplying by 10 is easy — just add a zero!',
        example: '7 × 5 → think 7 × 10 ÷ 2',
        visualHint: '× 🔟 then ➗ 2️⃣',
      ),
      TipStepEntity(
        title: 'Step by Step',
        content:
            'Step 1: Multiply the number by 10.\n'
            'Step 2: Divide the result by 2.',
        example: '7 × 10 = 70, then 70 ÷ 2 = 35 ✓',
      ),
      TipStepEntity(
        title: 'Bigger Numbers',
        content: 'This trick works great for bigger numbers too!',
        example:
            '14 × 5 = 14 × 10 ÷ 2 = 140 ÷ 2 = 70\n'
            '18 × 5 = 18 × 10 ÷ 2 = 180 ÷ 2 = 90',
      ),
    ],
    quizQuestions: const [
      QuizQuestionEntity(
        id: 'tip_mult_5_q1',
        question: 'What is 12 × 5 using the multiply-by-5 trick?',
        options: ['50', '55', '60', '65'],
        correctIndex: 2,
        explanation: '12 × 10 = 120, then 120 ÷ 2 = 60',
      ),
      QuizQuestionEntity(
        id: 'tip_mult_5_q2',
        question: 'What do you do FIRST in the multiply-by-5 trick?',
        options: [
          'Divide by 2',
          'Multiply by 5 directly',
          'Multiply by 10',
          'Add 5',
        ],
        correctIndex: 2,
        explanation: 'First multiply by 10 (add a zero), then divide by 2.',
      ),
      QuizQuestionEntity(
        id: 'tip_mult_5_q3',
        question: 'What is 16 × 5?',
        options: ['70', '75', '80', '85'],
        correctIndex: 2,
        explanation: '16 × 10 = 160, then 160 ÷ 2 = 80',
      ),
    ],
  ),

  // ─── Mental Math Tips ────────────────────────────────────────────────
  LearningTipEntity(
    id: 'tip_round_adjust',
    title: 'Round and Adjust',
    description: 'Round numbers to the nearest 10, then adjust for easy math!',
    category: 'mental_math',
    icon: '🧠',
    difficulty: 2,
    animationAsset: 'assets/animations/tip_mental_math.json',
    color: '#A78BFA',
    steps: const [
      TipStepEntity(
        title: 'Round to 10',
        content:
            'When adding numbers close to a multiple of 10, round up first, '
            'then subtract what you added.',
        example: '48 + 37 → round 48 to 50',
        visualHint: '🔄 round up → ➖ extra',
      ),
      TipStepEntity(
        title: 'Add Then Adjust',
        content:
            'Step 1: Round 48 up to 50 (added 2).\n'
            'Step 2: Add: 50 + 37 = 87.\n'
            'Step 3: Subtract the extra 2: 87 - 2 = 85.',
        example: '48 + 37 = 50 + 37 - 2 = 87 - 2 = 85',
      ),
      TipStepEntity(
        title: 'Works Both Ways',
        content:
            'You can round either number! Round whichever is closer to a tens.',
        example:
            '33 + 29 → round 29 to 30:\n'
            '33 + 30 - 1 = 63 - 1 = 62',
      ),
    ],
    quizQuestions: const [
      QuizQuestionEntity(
        id: 'tip_round_q1',
        question: 'What is 47 + 28 using round and adjust?',
        options: ['73', '74', '75', '76'],
        correctIndex: 2,
        explanation:
            'Round 47 to 50: 50 + 28 = 78, then 78 - 3 = 75. '
            'Or round 28 to 30: 47 + 30 = 77, then 77 - 2 = 75.',
      ),
      QuizQuestionEntity(
        id: 'tip_round_q2',
        question: 'If you round 38 up to 40, how much do you subtract later?',
        options: ['1', '2', '3', '4'],
        correctIndex: 1,
        explanation: '40 - 38 = 2, so you subtract 2 to adjust.',
      ),
      QuizQuestionEntity(
        id: 'tip_round_q3',
        question: 'What is 59 + 24 using round and adjust?',
        options: ['81', '82', '83', '84'],
        correctIndex: 2,
        explanation: 'Round 59 to 60: 60 + 24 = 84, then 84 - 1 = 83',
      ),
    ],
  ),

  LearningTipEntity(
    id: 'tip_break_apart',
    title: 'Break Apart Strategy',
    description: 'Split hard multiplications into easy pieces!',
    category: 'mental_math',
    icon: '🧠',
    difficulty: 3,
    animationAsset: 'assets/animations/tip_mental_math.json',
    color: '#C084FC',
    steps: const [
      TipStepEntity(
        title: 'Split the Number',
        content:
            'Break one number into tens and ones. '
            'Multiply each part separately, then add the results.',
        example: '14 × 3 → split 14 into 10 + 4',
        visualHint: '🔨 break → ✖️ each → ➕ together',
      ),
      TipStepEntity(
        title: 'Multiply Each Part',
        content:
            'Step 1: 10 × 3 = 30\n'
            'Step 2: 4 × 3 = 12\n'
            'Step 3: Add: 30 + 12 = 42',
        example: '14 × 3 = (10 × 3) + (4 × 3) = 30 + 12 = 42',
      ),
      TipStepEntity(
        title: 'Bigger Numbers',
        content: 'This works for any multiplication that feels too hard!',
        example:
            '23 × 4 = (20 × 4) + (3 × 4) = 80 + 12 = 92\n'
            '15 × 6 = (10 × 6) + (5 × 6) = 60 + 30 = 90',
      ),
    ],
    quizQuestions: const [
      QuizQuestionEntity(
        id: 'tip_break_q1',
        question: 'What is 13 × 5 using the break apart strategy?',
        options: ['55', '60', '65', '70'],
        correctIndex: 2,
        explanation: '13 × 5 = (10 × 5) + (3 × 5) = 50 + 15 = 65',
      ),
      QuizQuestionEntity(
        id: 'tip_break_q2',
        question: 'How would you break apart 17 × 4?',
        options: [
          '(10 × 4) + (7 × 4)',
          '(17 × 2) + (17 × 2)',
          '(15 × 4) + (2 × 4)',
          'All of the above',
        ],
        correctIndex: 3,
        explanation: 'All are valid ways to break apart! Each gives 68.',
      ),
      QuizQuestionEntity(
        id: 'tip_break_q3',
        question: 'What is 22 × 3 using break apart?',
        options: ['63', '64', '66', '68'],
        correctIndex: 2,
        explanation: '22 × 3 = (20 × 3) + (2 × 3) = 60 + 6 = 66',
      ),
    ],
  ),
];
