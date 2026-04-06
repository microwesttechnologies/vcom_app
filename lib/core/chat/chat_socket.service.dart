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

    final uri = Uri.parse(EnvironmentDev.chatWebSocketUrl).replace(
      queryParameters: {'token': token},
    );

    _connectedToken = token;
    _channel = IOWebSocketChannel.connect(uri.toString());
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
      },
      onError: (_) {
        _isConnected = false;
      },
      cancelOnError: false,
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
