import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/parent_remote_datasource.dart';
import '../../data/models/child_progress_model.dart';
import '../../data/models/child_summary_model.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../domain/repositories/parent_repository.dart';

/// Provides the [ParentRemoteDatasource] instance.
final parentRemoteDatasourceProvider = Provider<ParentRemoteDatasource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ParentRemoteDatasource(apiClient: apiClient);
});

/// Provides the [ParentRepository] implementation.
final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepositoryImpl(
    remoteDatasource: ref.read(parentRemoteDatasourceProvider),
  );
});

/// Fetches the list of children for the current parent.
final childrenListProvider = FutureProvider<List<ChildSummaryModel>>((
  ref,
) async {
  final datasource = ref.read(parentRemoteDatasourceProvider);
  return datasource.getChildren();
});

/// Notifier for the currently selected child ID.
class SelectedChildNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectChild(String? childId) {
    state = childId;
  }
}

/// Provider for the currently selected child ID.
final selectedChildProvider = NotifierProvider<SelectedChildNotifier, String?>(
  SelectedChildNotifier.new,
);

/// Fetches detailed progress for the selected child.
final childProgressProvider = FutureProvider<ChildProgressModel?>((ref) async {
  final selectedChildId = ref.watch(selectedChildProvider);
  if (selectedChildId == null) return null;

  final datasource = ref.read(parentRemoteDatasourceProvider);
  return datasource.getChildProgress(selectedChildId);
});
