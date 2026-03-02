import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/competition_websocket_datasource.dart';
import '../../data/services/competition_websocket_service.dart';
import '../providers/competition_providers.dart';

/// State for WebSocket connection management.
class WebSocketState {
  const WebSocketState({
    this.connectionState = WsConnectionState.disconnected,
    this.isConnecting = false,
    this.error,
  });

  final WsConnectionState connectionState;
  final bool isConnecting;
  final String? error;

  /// Whether the WebSocket is currently connected.
  bool get isConnected => connectionState == WsConnectionState.connected;

  /// Creates a copy with modified fields.
  /// [error] resets to null when not explicitly passed.
  WebSocketState copyWith({
    WsConnectionState? connectionState,
    bool? isConnecting,
    String? error,
  }) {
    return WebSocketState(
      connectionState: connectionState ?? this.connectionState,
      isConnecting: isConnecting ?? this.isConnecting,
      error: error,
    );
  }
}

/// Manages WebSocket connection state.
///
/// Handles connecting, disconnecting, and monitoring connection health.
class WebSocketNotifier extends Notifier<WebSocketState> {
  late CompetitionWebSocketDatasource _datasource;
  StreamSubscription<WsConnectionState>? _connectionSubscription;

  @override
  WebSocketState build() {
    _datasource = ref.read(competitionWebSocketDatasourceProvider);

    ref.onDispose(() {
      _connectionSubscription?.cancel();
    });

    return const WebSocketState();
  }

  /// Connects to the WebSocket server with the given auth [token].
  Future<void> connect(String token) async {
    state = state.copyWith(isConnecting: true);

    try {
      await _datasource.connect(token);

      _connectionSubscription?.cancel();
      _connectionSubscription = _datasource.connectionState.listen((wsState) {
        state = state.copyWith(
          connectionState: wsState,
          isConnecting: wsState == WsConnectionState.connecting,
        );
      });

      state = state.copyWith(
        connectionState: WsConnectionState.connected,
        isConnecting: false,
      );
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        error: 'Failed to connect: ${e.toString()}',
      );
    }
  }

  /// Disconnects from the WebSocket server.
  Future<void> disconnect() async {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _datasource.disconnect();
    state = const WebSocketState();
  }
}
