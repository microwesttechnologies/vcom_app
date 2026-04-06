import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  IOWebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isConnected = false;
  String? _connectedToken;

  Stream<Map<String, dynamic>> get events => _eventsController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    if (_channel != null && _connectedToken == token) {
      return;
    }

    await disconnect();

    final uri = _buildSocketUri(token);

    _connectedToken = token;
    try {
      _channel = IOWebSocketChannel.connect(uri.toString());
    } catch (e) {
      _connectedToken = null;
      _isConnected = false;
      _eventsController.add({
        'event': 'error',
        'data': {
          'code': 'WS_CONNECT_ERROR',
          'message': e.toString(),
        },
      });
      return;
    }

    _subscription = _channel!.stream.listen(
      (dynamic raw) {
        try {
          final decoded = jsonDecode(raw.toString());
          if (decoded is Map<String, dynamic>) {
            _eventsController.add(decoded);
            if (decoded['event'] == 'connection.ready') {
              _isConnected = true;
            }
          }
        } catch (_) {}
      },
      onDone: () {
        _isConnected = false;
        _connectedToken = null;
      },
      onError: (_) {
        _isConnected = false;
        _connectedToken = null;
      },
      cancelOnError: false,
    );
  }

  Uri _buildSocketUri(String token) {
    final rawBase = EnvironmentDev.chatWebSocketUrl.trim().replaceAll('#', '');
    final parsed = Uri.parse(rawBase);
    final scheme = parsed.scheme == 'wss'
        ? 'wss'
        : parsed.scheme == 'ws'
            ? 'ws'
            : parsed.scheme == 'https'
                ? 'wss'
                : 'ws';
    final path = parsed.path.isEmpty ? '/ws' : parsed.path;

    if (parsed.hasPort) {
      return Uri(
        scheme: scheme,
        host: parsed.host,
        port: parsed.port,
        path: path,
        queryParameters: {'token': token},
      );
    }

    return Uri(
      scheme: scheme,
      host: parsed.host,
      path: path,
      queryParameters: {'token': token},
    );
  }

  void emit(String event, Map<String, dynamic> data) {
    final channel = _channel;
    if (channel == null) return;

    channel.sink.add(jsonEncode({'event': event, 'data': data}));
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _connectedToken = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
  }
}
