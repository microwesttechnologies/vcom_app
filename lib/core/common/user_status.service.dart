import 'dart:async';

import 'package:vcom_app/core/chat/chat_socket.service.dart';
import 'package:vcom_app/core/common/token.service.dart';

/// Servicio global para gestionar el estado online/offline del usuario.
class UserStatusService {
  static final UserStatusService _instance = UserStatusService._internal();
  factory UserStatusService() => _instance;
  UserStatusService._internal();

  final ChatSocketService _socket = ChatSocketService();
  final TokenService _tokenService = TokenService();

  bool _isOnline = false;
  StreamSubscription<Map<String, dynamic>>? _presenceSubscription;
  Map<String, String> _presenceNameById = const {};
  Map<String, bool> _presenceOnlineById = const {};
  Map<String, bool> _presenceOnlineByRoleAndName = const {};

  bool get isOnline => _isOnline;
  Map<String, String> get presenceNameById => _presenceNameById;
  Map<String, bool> get presenceOnlineById => _presenceOnlineById;
  Map<String, bool> get presenceOnlineByRoleAndName => _presenceOnlineByRoleAndName;

  Future<void> initialize() async {
    if (!_tokenService.hasToken()) return;
    await setOnline();
  }

  Future<void> setOnline() async {
    final token = _tokenService.getToken();
    if (token == null || token.isEmpty) {
      _isOnline = false;
      return;
    }

    await _socket.connect(token);
    _ensurePresenceListener();
    _isOnline = true;
  }

  Future<void> setOffline() async {
    await _presenceSubscription?.cancel();
    _presenceSubscription = null;
    _presenceNameById = const {};
    _presenceOnlineById = const {};
    _presenceOnlineByRoleAndName = const {};
    await _socket.disconnect();
    _isOnline = false;
  }

  Future<void> clear() async {
    await setOffline();
  }

  void _ensurePresenceListener() {
    _presenceSubscription ??= _socket.events.listen((payload) {
      final event = (payload['event'] ?? '').toString();
      final data = payload['data'];

      if (event == 'presence.snapshot' && data is Map<String, dynamic>) {
        _cachePresenceSnapshot(data);
        return;
      }

      if (event == 'presence.update' && data is Map<String, dynamic>) {
        final userId = (data['user_id'] ?? '').toString().trim();
        final isOnline = data['is_online'] == true;
        _cachePresenceUpdate(userId, isOnline);
      }
    });
  }

  void _cachePresenceSnapshot(Map<String, dynamic> data) {
    final rawContacts = data['contacts'];
    if (rawContacts is! List) return;

    final nextNameById = <String, String>{};
    final nextOnlineById = <String, bool>{};
    final nextOnlineByRoleAndName = <String, bool>{};

    for (final raw in rawContacts.whereType<Map<String, dynamic>>()) {
      final id = (raw['user_id'] ?? '').toString().trim();
      final name = (raw['name_user'] ?? raw['name'] ?? '').toString().trim();
      final role = (raw['role_user'] ?? raw['role'] ?? '').toString().trim();
      final isOnline = raw['is_online'] == true;
      final roleAndName = _roleAndNameKey(role, name);

      if (id.isNotEmpty) {
        nextNameById[id] = _normalizeName(name);
        nextOnlineById[id] = isOnline;
      }
      if (roleAndName.isNotEmpty) {
        nextOnlineByRoleAndName[roleAndName] = isOnline;
      }
    }

    _presenceNameById = nextNameById;
    _presenceOnlineById = nextOnlineById;
    _presenceOnlineByRoleAndName = nextOnlineByRoleAndName;
  }

  void _cachePresenceUpdate(String userId, bool isOnline) {
    if (userId.isEmpty) return;

    final nextOnlineById = Map<String, bool>.from(_presenceOnlineById);
    nextOnlineById[userId] = isOnline;
    _presenceOnlineById = nextOnlineById;

    final normalizedName = _presenceNameById[userId] ?? '';
    if (normalizedName.isEmpty) return;

    final nextOnlineByRoleAndName = Map<String, bool>.from(_presenceOnlineByRoleAndName);
    for (final entry in _presenceOnlineByRoleAndName.entries) {
      if (entry.key.endsWith('|$normalizedName')) {
        nextOnlineByRoleAndName[entry.key] = isOnline;
      }
    }
    _presenceOnlineByRoleAndName = nextOnlineByRoleAndName;
  }

  static String _normalizeName(String value) {
    return value.trim().toLowerCase();
  }

  static String _normalizeRole(String value) {
    final role = value.trim().toUpperCase();
    if (role == 'MODEL' || role == 'MODELO' || role == 'MODAL') return 'MODELO';
    if (role == 'MONITOR') return 'MONITOR';
    return role;
  }

  static String _roleAndNameKey(String role, String name) {
    final normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) return '';
    return '${_normalizeRole(role)}|$normalizedName';
  }
}
