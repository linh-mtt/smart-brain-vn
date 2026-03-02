import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/hive_service.dart';
import '../../data/datasources/learning_tips_local_datasource.dart';
import '../../data/repositories/learning_tips_repository_impl.dart';
import '../../domain/repositories/learning_tips_repository.dart';
import '../notifiers/learning_tips_notifier.dart';

/// Provides the [LearningTipsLocalDatasource] instance.
final learningTipsLocalDatasourceProvider =
    Provider<LearningTipsLocalDatasource>((ref) {
      final hiveService = ref.read(hiveServiceProvider);
      return LearningTipsLocalDatasource(hiveService: hiveService);
    });

/// Provides the [LearningTipsRepository] instance.
final learningTipsRepositoryProvider = Provider<LearningTipsRepository>((ref) {
  return LearningTipsRepositoryImpl(
    localDatasource: ref.read(learningTipsLocalDatasourceProvider),
  );
});

/// Provides the learning tips list state and notifier.
///
/// NOT autoDispose — persists while the user is on the tips screens.
final learningTipsListProvider =
    NotifierProvider<LearningTipsListNotifier, LearningTipsListState>(
      () => LearningTipsListNotifier(),
    );

/// Provides the tip detail / quiz state and notifier.
///
/// autoDispose — resets when the user leaves the detail page.
final tipDetailProvider =
    NotifierProvider.autoDispose<TipDetailNotifier, TipDetailState>(
      () => TipDetailNotifier(),
    );

/// Available tip categories derived from loaded tips.
final tipCategoriesProvider = Provider<List<String>>((ref) {
  final tips = ref.watch(learningTipsListProvider).tips;
  final categories = tips.map((t) => t.category).toSet().toList()..sort();
  return categories;
});

/// Number of completed tips.
final completedTipsCountProvider = Provider<int>((ref) {
  return ref.watch(learningTipsListProvider).completedCount;
});
