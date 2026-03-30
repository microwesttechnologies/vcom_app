import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vcom_app/core/chat/chat_api.service.dart';
import 'package:vcom_app/core/chat/chat_socket.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/chat/chat_contact.model.dart';
import 'package:vcom_app/core/models/chat/chat_conversation.model.dart';
import 'package:vcom_app/core/models/chat/chat_message.model.dart';

class ChatComponent extends ChangeNotifier {
  final ChatApiService _api = ChatApiService();
  final ChatSocketService _socket = ChatSocketService();
  final TokenService _tokenService = TokenService();

  bool _isLoading = false;
  String? _error;

  String _currentUserId = '';
  String _currentUserName = '';
  String _currentRole = '';

  List<ChatContactModel> _contacts = const [];
  List<ChatConversationModel> _conversations = const [];
  List<ChatMessageModel> _messages = const [];

  ChatConversationModel? _selectedConversation;
  ChatContactModel? _selectedContact;
  bool _isOtherTyping = false;

  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  Map<String, String> _presenceNameById = const {};
  Timer? _typingInactivityTimer;
  bool _typingEmitted = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentUserId => _currentUserId;
  String get currentUserName => _currentUserName;
  String get currentRole => _currentRole;
  List<ChatContactModel> get contacts => _contacts;
  List<ChatConversationModel> get conversations => _conversations;
  List<ChatMessageModel> get messages => _messages;
  ChatConversationModel? get selectedConversation => _selectedConversation;
  ChatContactModel? get selectedContact => _selectedContact;
  bool get isOtherTyping => _isOtherTyping;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final me = await _api.fetchMe();
      _currentUserId = (me['id_user'] ?? '').toString().trim();
      _currentUserName = (me['name_user'] ?? '').toString().trim();
      _currentRole = (me['role_user'] ?? '').toString().trim();

      if (_currentUserId.isEmpty) {
        _currentUserId = (_tokenService.getUserId() ?? '').trim();
      }
      if (_currentUserName.isEmpty) {
        _currentUserName = (_tokenService.getUserName() ?? '').trim();
      }
      if (_currentRole.isEmpty) {
        _currentRole = (_tokenService.getRole() ?? '').trim();
      }

      _contacts = await _api.fetchContacts(
        currentRole: _currentRole,
        currentUserId: _currentUserId,
      );
      _conversations = await _api.fetchConversations();

      final token = _tokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesion invalida para chat');
      }

      await _socket.connect(token);
      _wsSubscription?.cancel();
      _wsSubscription = _socket.events.listen(_handleSocketEvent);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      _contacts = await _api.fetchContacts(
        currentRole: _currentRole,
        currentUserId: _currentUserId,
      );
      _conversations = await _api.fetchConversations();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> openConversation(ChatContactModel contact) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      ChatConversationModel? conversation = _conversations.firstWhere(
        (item) => item.otherUserId == contact.idUser,
        orElse: () => ChatConversationModel(
          idConversation: 0,
          otherUserId: contact.idUser,
          createdAt: DateTime.now(),
          unreadCount: 0,
        ),
      );

      if (conversation.idConversation == 0) {
        conversation = await _api.createOrGetConversation(contact.idUser);
        _conversations = [conversation, ..._conversations];
      }

      _selectedContact = contact;
      _selectedConversation = conversation;

      _socket.emit('conversation.join', {
        'conversation_id': conversation.idConversation,
      });

      _messages = await _api.fetchMessages(conversation.idConversation);
      await _api.markConversationRead(conversation.idConversation);
      _conversations = _conversations
          .map((item) => item.idConversation == conversation!.idConversation
              ? item.copyWith(unreadCount: 0)
              : item)
          .toList(growable: false);
      _socket.emit('message.seen', {
        'conversation_id': conversation.idConversation,
      });
      _isOtherTyping = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> backToList() async {
    emitTypingStop();
    final conversationId = _selectedConversation?.idConversation;
    if (conversationId != null) {
      _socket.emit('conversation.leave', {'conversation_id': conversationId});
    }
    _selectedConversation = null;
    _selectedContact = null;
    _messages = const [];
    _isOtherTyping = false;
    notifyListeners();
  }

  void emitTypingStart() {
    final id = _selectedConversation?.idConversation;
    if (id == null) return;

    if (!_typingEmitted) {
      _socket.emit('typing.start', {'conversation_id': id});
      _typingEmitted = true;
    }

    _typingInactivityTimer?.cancel();
    _typingInactivityTimer = Timer(const Duration(seconds: 2), () {
      emitTypingStop();
    });
  }

  void emitTypingStop() {
    final id = _selectedConversation?.idConversation;
    if (id == null) return;
    _typingInactivityTimer?.cancel();
    _typingInactivityTimer = null;

    if (!_typingEmitted) return;
    _socket.emit('typing.stop', {'conversation_id': id});
    _typingEmitted = false;
  }

  void sendText(String text) {
    final id = _selectedConversation?.idConversation;
    if (id == null || text.trim().isEmpty) return;
    emitTypingStop();

    _socket.emit('message.send', {
      'conversation_id': id,
      'content': text.trim(),
      'message_type': 'text',
    });
  }

  void sendImageUrl(String imageUrl) {
    final id = _selectedConversation?.idConversation;
    if (id == null || imageUrl.trim().isEmpty) return;
    emitTypingStop();

    _socket.emit('message.send', {
      'conversation_id': id,
      'content': imageUrl.trim(),
      'message_type': 'image',
    });
  }

  void _handleSocketEvent(Map<String, dynamic> payload) {
    final event = (payload['event'] ?? '').toString();
    final data = payload['data'];

    if (event == 'presence.snapshot' && data is Map<String, dynamic>) {
      _applyPresenceSnapshot(data);
      return;
    }

    if (event == 'presence.update' && data is Map<String, dynamic>) {
      final userId = (data['user_id'] ?? '').toString().trim();
      final isOnline = data['is_online'] == true;
      _applyPresenceUpdate(userId, isOnline);
      return;
    }

    if (event == 'typing.update' && data is Map<String, dynamic>) {
      final conversationId = _toInt(data['conversation_id']);
      final userId = (data['user_id'] ?? '').toString();
      final isTyping = data['is_typing'] == true;
      if (_selectedConversation?.idConversation == conversationId && userId != _currentUserId) {
        _isOtherTyping = isTyping;
        notifyListeners();
      }
      return;
    }

    if (event == 'message.new' && data is Map<String, dynamic>) {
      final msg = ChatMessageModel.fromJson(data);

      if (_selectedConversation?.idConversation == msg.idConversation) {
        final exists = _messages.any((m) => m.idMessage == msg.idMessage);
        if (!exists) {
          _messages = [..._messages, msg];
          _isOtherTyping = false;
          if (msg.recipientId == _currentUserId) {
            _socket.emit('message.seen', {'conversation_id': msg.idConversation});
          }
          notifyListeners();
        }
      }

      unawaited(refresh());
      return;
    }

    if (event == 'message.status' && data is Map<String, dynamic>) {
      final messageId = _toInt(data['id_message']);
      final status = (data['status'] ?? 'unseen').toString();
      final receivedAt = DateTime.tryParse((data['received_at'] ?? '').toString());
      final seenAt = DateTime.tryParse((data['seen_at'] ?? '').toString());

      _messages = _messages
          .map(
            (m) => m.idMessage == messageId
                ? m.copyWith(status: status, receivedAt: receivedAt, seenAt: seenAt)
                : m,
          )
          .toList(growable: false);
      notifyListeners();
      return;
    }

    if (event == 'error' && data is Map<String, dynamic>) {
      _error = (data['message'] ?? 'Error de websocket').toString();
      notifyListeners();
    }
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  void _applyPresenceSnapshot(Map<String, dynamic> data) {
    if (_contacts.isEmpty) return;

    final rawContacts = data['contacts'];
    if (rawContacts is! List) return;

    final byId = <String, Map<String, dynamic>>{};
    final byRoleAndName = <String, Map<String, dynamic>>{};
    final nameById = <String, String>{};

    for (final raw in rawContacts.whereType<Map<String, dynamic>>()) {
      final id = (raw['user_id'] ?? '').toString().trim();
      final name = (raw['name_user'] ?? raw['name'] ?? '').toString().trim();
      final role = (raw['role_user'] ?? raw['role'] ?? '').toString().trim();
      final key = _roleAndNameKey(role, name);

      if (id.isNotEmpty) {
        byId[id] = raw;
        nameById[id] = _normalizeName(name);
      }
      if (key.isNotEmpty) {
        byRoleAndName[key] = raw;
      }
    }

    _presenceNameById = nameById;

    _contacts = _contacts
        .map((c) {
          Map<String, dynamic>? match = byId[c.idUser.trim()];
          match ??= byRoleAndName[_roleAndNameKey(c.roleUser, c.nameUser)];
          if (match == null) return c;

          final mergedId = (match['user_id'] ?? '').toString().trim();
          final isOnline = match['is_online'] == true;
          final nextId = mergedId.isNotEmpty ? mergedId : c.idUser;

          if (nextId == c.idUser && isOnline == c.isOnline) return c;

          return ChatContactModel(
            idUser: nextId,
            nameUser: c.nameUser,
            roleUser: c.roleUser,
            isOnline: isOnline,
          );
        })
        .toList(growable: false);

    if (_selectedContact != null) {
      for (final contact in _contacts) {
        if (_sameContact(contact, _selectedContact!)) {
          _selectedContact = contact;
          break;
        }
      }
    }

    notifyListeners();
  }

  void _applyPresenceUpdate(String userId, bool isOnline) {
    if (userId.isEmpty || _contacts.isEmpty) return;

    final normalizedFromPresence = _presenceNameById[userId] ?? '';

    var changed = false;
    _contacts = _contacts
        .map((c) {
          final matchesById = c.idUser.trim() == userId;
          final matchesByName = normalizedFromPresence.isNotEmpty &&
              _normalizeName(c.nameUser) == normalizedFromPresence;

          if (!matchesById && !matchesByName) return c;
          if (c.isOnline == isOnline) return c;

          changed = true;
          return ChatContactModel(
            idUser: c.idUser,
            nameUser: c.nameUser,
            roleUser: c.roleUser,
            isOnline: isOnline,
          );
        })
        .toList(growable: false);

    if (changed) {
      if (_selectedContact != null) {
        final selectedId = _selectedContact!.idUser.trim();
        final selectedName = _normalizeName(_selectedContact!.nameUser);
        final selectedById = selectedId == userId;
        final selectedByName = normalizedFromPresence.isNotEmpty &&
            selectedName == normalizedFromPresence;
        if (selectedById || selectedByName) {
          _selectedContact = ChatContactModel(
            idUser: _selectedContact!.idUser,
            nameUser: _selectedContact!.nameUser,
            roleUser: _selectedContact!.roleUser,
            isOnline: isOnline,
          );
        }
      }
      notifyListeners();
    }
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

  bool _sameContact(ChatContactModel a, ChatContactModel b) {
    if (a.idUser.trim() == b.idUser.trim()) return true;
    return _roleAndNameKey(a.roleUser, a.nameUser) ==
        _roleAndNameKey(b.roleUser, b.nameUser);
  }

  @override
  void dispose() {
    emitTypingStop();
    _typingInactivityTimer?.cancel();
    _typingInactivityTimer = null;
    _wsSubscription?.cancel();
    _socket.dispose();
    super.dispose();
  }
}
