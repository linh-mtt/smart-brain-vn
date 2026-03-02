import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/api_constants.dart';

/// Connection state for the WebSocket.
enum WsConnectionState {
  /// Not connected to the server.
  disconnected,

  /// Attempting to connect.
  connecting,

  /// Successfully connected.
  connected,

  /// Attempting to reconnect after a lost connection.
  reconnecting,
}

/// Low-level WebSocket service for competition feature.
///
/// Handles connection lifecycle, message encoding/decoding,
/// and exponential backoff reconnection.
class CompetitionWebSocketService {
  CompetitionWebSocketService();

  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController =
      StreamController<WsConnectionState>.broadcast();

  WsConnectionState _currentState = WsConnectionState.disconnected;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  String? _token;
  bool _intentionalDisconnect = false;

  /// Stream of decoded JSON messages from the server.
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Stream of connection state changes.
  Stream<WsConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// Current connection state.
  WsConnectionState get currentState => _currentState;

  /// Whether the WebSocket is currently connected.
  bool get isConnected => _currentState == WsConnectionState.connected;

  /// Connects to the WebSocket server with the given auth [token].
  Future<void> connect(String token) async {
    _token = token;
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    await _establishConnection();
  }

  /// Disconnects from the WebSocket server.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _channel?.sink.close();
    _channel = null;
    _updateState(WsConnectionState.disconnected);
  }

  /// Sends a JSON message through the WebSocket.
  void send(Map<String, dynamic> message) {
    if (_channel == null || _currentState != WsConnectionState.connected) {
      return;
    }
    _channel!.sink.add(jsonEncode(message));
  }

  /// Disposes all resources. Call when the service is no longer needed.
  Future<void> dispose() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _channel?.sink.close();
    _channel = null;
    await _messageController.close();
    await _connectionStateController.close();
  }

  Future<void> _establishConnection() async {
    _updateState(WsConnectionState.connecting);

    try {
      final wsUrl = '${ApiConstants.wsBaseUrl}?token=$_token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      await _channel!.ready;
      _reconnectAttempts = 0;
      _updateState(WsConnectionState.connected);

      _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);
    } catch (e) {
      _updateState(WsConnectionState.disconnected);
      if (!_intentionalDisconnect) {
        _scheduleReconnect();
      }
    }
  }

  void _onMessage(dynamic data) {
    if (_messageController.isClosed) return;

    try {
      final decoded = jsonDecode(data as String) as Map<String, dynamic>;
      _messageController.add(decoded);
    } catch (_) {
      // Ignore malformed messages.
    }
  }

  void _onError(Object error) {
    if (!_intentionalDisconnect) {
      _updateState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _onDone() {
    if (!_intentionalDisconnect) {
      _updateState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect) return;
    if (_reconnectAttempts >= ApiConstants.wsMaxReconnectAttempts) return;

    _updateState(WsConnectionState.reconnecting);

    final delay = min(
      ApiConstants.wsReconnectDelay * pow(2, _reconnectAttempts).toInt(),
      ApiConstants.wsMaxReconnectDelay,
    );
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (!_intentionalDisconnect) {
        _establishConnection();
      }
    });
  }

  void _updateState(WsConnectionState state) {
    _currentState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }
}
