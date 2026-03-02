import '../../../../core/errors/failures.dart';
import '../entities/learning_tip_entity.dart';
import '../entities/tip_progress_entity.dart';

/// Abstract interface for the Learning Tips repository.
///
/// All methods return [Result<T>] to handle success/failure in the domain layer.
abstract class LearningTipsRepository {
  /// Returns all available learning tips.
  Future<Result<List<LearningTipEntity>>> getAllTips();

  /// Returns a single tip by its [tipId].
  Future<Result<LearningTipEntity>> getTipById(String tipId);

  /// Returns progress records for all tips.
  Future<Result<List<TipProgressEntity>>> getAllProgress();

  /// Marks a tip as completed with optional quiz results.
  Future<Result<void>> markTipCompleted(
    String tipId, {
    int? quizScore,
    int? quizTotal,
  });

  /// Resets all tip progress.
  Future<Result<void>> resetProgress();
}
