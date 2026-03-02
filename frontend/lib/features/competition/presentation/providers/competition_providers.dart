import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/competition_websocket_datasource.dart';
import '../../data/repositories/competition_repository_impl.dart';
import '../../data/services/competition_websocket_service.dart';
import '../../domain/repositories/competition_repository.dart';
import '../notifiers/match_notifier.dart';
import '../notifiers/websocket_notifier.dart';

/// Provides the [CompetitionWebSocketService] instance.
final competitionWebSocketServiceProvider =
    Provider<CompetitionWebSocketService>((ref) {
      final service = CompetitionWebSocketService();
      ref.onDispose(() => service.dispose());
      return service;
    });

/// Provides the [CompetitionWebSocketDatasource] instance.
final competitionWebSocketDatasourceProvider =
    Provider<CompetitionWebSocketDatasource>((ref) {
      final service = ref.read(competitionWebSocketServiceProvider);
      return CompetitionWebSocketDatasource(webSocketService: service);
    });

/// Provides the [CompetitionRepository] instance.
final competitionRepositoryProvider = Provider<CompetitionRepository>((ref) {
  return CompetitionRepositoryImpl(
    datasource: ref.read(competitionWebSocketDatasourceProvider),
  );
});

/// Provides the match state and notifier.
final matchNotifierProvider =
    NotifierProvider.autoDispose<MatchNotifier, MatchState>(
      () => MatchNotifier(),
    );

/// Provides the WebSocket connection state and notifier.
final webSocketNotifierProvider =
    NotifierProvider.autoDispose<WebSocketNotifier, WebSocketState>(
      () => WebSocketNotifier(),
    );
