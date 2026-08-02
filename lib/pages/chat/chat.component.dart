import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vcom_app/core/chat/chat_api.service.dart';
import 'package:vcom_app/core/chat/chat_module_cache.dart';
import 'package:vcom_app/core/chat/chat_socket.service.dart';
import 'package:vcom_app/core/chat/chat_unread_badge.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/user_role.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'package:vcom_app/core/models/chat/chat_contact.model.dart';
import 'package:vcom_app/core/models/chat/chat_conversation.model.dart';
import 'package:vcom_app/core/models/chat/chat_message.model.dart';
import 'package:vcom_app/core/pwa/pwa_platform.dart';

class ChatComponent extends ChangeNotifier {
  final ChatApiService _api = ChatApiService();
  final ChatSocketService _socket = ChatSocketService();
  final TokenService _tokenService = TokenService();
  final UserStatusService _userStatusService = UserStatusService();
  final ChatUnreadBadgeService _unreadBadge = ChatUnreadBadgeService();

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
  Map<String, bool> _presenceOnlineById = const {};
  Map<String, bool> _presenceOnlineByRoleAndName = const {};
  Timer? _typingInactivityTimer;
  Timer? _socketWatchdogTimer;
  Timer? _httpPollingTimer;
  bool _typingEmitted = false;

  /// Polling HTTP solo en Safari iOS real o PWA instalada (WS inestable para recibir).
  bool get _useHttpPolling =>
      kIsWeb && isIosDevice && (isIosSafari || isStandalonePwa);

  /// Envío HTTP preferido en Safari iOS/PWA; el resto usa WebSocket.
  bool get _preferHttpSend => _useHttpPolling;

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
    _error = null;
    await _tokenService.initialize();
    _applyTokenIdentity();
    final uid = (_tokenService.getUserId() ?? '').trim();

    if (uid.isNotEmpty) {
      final cached = await ChatModuleCache.instance.load(uid);
      if (cached != null) {
        _applyInboxCache(cached);
        try {
          await _connectSocketAndListen();
        } catch (e) {
          if (!_isModelRole) {
            _error = e.toString();
          } else {
            debugPrint('Chat MODELO: socket no disponible: $e');
          }
        }
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final me = await _fetchRemoteIdentity();

      _hydratePresenceCache();

      await _loadInbox();

      final token = _tokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesion invalida para chat');
      }

      try {
        await _connectSocketAndListen();
      } catch (error) {
        if (!_isModelRole) rethrow;
        debugPrint('Chat MODELO: socket no disponible: $error');
      }
      unawaited(_persistInboxCache(me));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyTokenIdentity() {
    _currentUserId = (_tokenService.getUserId() ?? '').trim();
    _currentUserName = (_tokenService.getUserName() ?? '').trim();
    _currentRole = (_tokenService.getRole() ?? '').trim();
  }

  bool get _isModelRole => _normalizeRole(_currentRole) == 'MODELO';

  Future<Map<String, dynamic>> _fetchRemoteIdentity() async {
    try {
      final me = await _api.fetchMe();
      _currentUserId =
          (me['id_user'] ?? _currentUserId).toString().trim();
      _currentUserName =
          (me['name_user'] ?? _currentUserName).toString().trim();
      _currentRole =
          (me['role_user'] ?? _currentRole).toString().trim();
      return me;
    } catch (error) {
      if (!_isModelRole || _currentUserId.isEmpty) rethrow;
      debugPrint(
        'Chat MODELO: /me no disponible; se usa identidad del JWT: $error',
      );
      return {
        'id_user': _currentUserId,
        'name_user': _currentUserName,
        'role_user': _currentRole,
      };
    }
  }

  Future<void> _loadInbox() async {
    try {
      final fetchedContacts = await _api.fetchContacts(
        currentRole: _currentRole,
        currentUserId: _currentUserId,
      );
      _contacts = _mergePresenceIntoContacts(fetchedContacts);
      _conversations = await _api.fetchConversations();
      _syncUnreadBadge();
    } catch (error) {
      if (!_isModelRole) rethrow;
      debugPrint(
        'Chat MODELO: bandeja remota no disponible; se conserva caché: $error',
      );
    }
  }

  void _applyInboxCache(ChatListCacheData cached) {
    final me = cached.me;
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
    _hydratePresenceCache();
    _contacts = _mergePresenceIntoContacts(cached.contacts);
    _conversations = cached.conversations;
    _syncUnreadBadge();
  }

  Future<void> _connectSocketAndListen() async {
    final token = _tokenService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesion invalida para chat');
    }

    if (_useHttpPolling) {
      _startHttpPolling();
    }

    try {
      await _socket.connect(token);
      _socket.emit('chat.screen.open', {});
      _wsSubscription?.cancel();
      _wsSubscription = _socket.events.listen(_handleSocketEvent);
      _startSocketWatchdog();
    } catch (e) {
      if (!_useHttpPolling) rethrow;
    }
  }

  Future<void> _persistInboxCache(Map<String, dynamic> me) async {
    final uid = _currentUserId.trim().isNotEmpty
        ? _currentUserId.trim()
        : (_tokenService.getUserId() ?? '').trim();
    if (uid.isEmpty) return;
    await ChatModuleCache.instance.save(
      userId: uid,
      me: me,
      contacts: _contacts,
      conversations: _conversations,
    );
  }

  Future<void> _persistInboxFromState() async {
    await _persistInboxCache({
      'id_user': _currentUserId,
      'name_user': _currentUserName,
      'role_user': _currentRole,
    });
  }

  void _hydratePresenceCache() {
    _presenceNameById = _userStatusService.presenceNameById;
    _presenceOnlineById = _userStatusService.presenceOnlineById;
    _presenceOnlineByRoleAndName = _userStatusService.presenceOnlineByRoleAndName;
  }

  Future<void> refresh() async {
    try {
      final fetchedContacts = await _api.fetchContacts(
        currentRole: _currentRole,
        currentUserId: _currentUserId,
      );
      _contacts = _mergePresenceIntoContacts(fetchedContacts);
      _conversations = await _api.fetchConversations();
      _syncUnreadBadge();
      unawaited(_persistInboxFromState());
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

      await _ensureSocketConnected();
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
      _syncUnreadBadge();
      _socket.emit('message.seen', {
        'conversation_id': conversation.idConversation,
      });
      _isOtherTyping = false;
      unawaited(_persistInboxFromState());
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openConversationByUserId({
    required String userId,
    String? userName,
    String? userRole,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    ChatContactModel? contact;
    for (final item in _contacts) {
      if (item.idUser.trim() == normalizedUserId) {
        contact = item;
        break;
      }
    }

    contact ??= ChatContactModel(
      idUser: normalizedUserId,
      nameUser: (userName ?? '').trim().isNotEmpty ? userName!.trim() : 'Chat',
      roleUser: (userRole ?? '').trim(),
      isOnline: _resolveCachedOnline(
        userId: normalizedUserId,
        userName: userName,
        userRole: userRole,
      ),
    );

    await openConversation(contact);
  }

  Future<void> openConversationByConversationId(int conversationId) async {
    if (conversationId <= 0) return;

    ChatConversationModel? conversation;
    for (final item in _conversations) {
      if (item.idConversation == conversationId) {
        conversation = item;
        break;
      }
    }

    if (conversation == null) {
      try {
        _conversations = await _api.fetchConversations();
        _syncUnreadBadge();
        for (final item in _conversations) {
          if (item.idConversation == conversationId) {
            conversation = item;
            break;
          }
        }
      } catch (_) {}
    }

    if (conversation == null) return;

    await openConversationByUserId(userId: conversation.otherUserId);
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
    if (id == null || id <= 0 || text.trim().isEmpty) return;
    emitTypingStop();

    unawaited(
      _dispatchMessageSend(
        conversationId: id,
        socketPayload: {
          'conversation_id': id,
          'content': text.trim(),
          'message_type': 'text',
        },
        httpSend: () => _api.sendMessage(
          conversationId: id,
          content: text.trim(),
          messageType: 'text',
        ),
      ),
    );
  }

  Future<bool> sendImageUrl(String imageUrl) async {
    final id = _selectedConversation?.idConversation;
    if (id == null || id <= 0 || imageUrl.trim().isEmpty) return false;
    emitTypingStop();

    return _dispatchMessageSend(
      conversationId: id,
      socketPayload: {
        'conversation_id': id,
        'content': imageUrl.trim(),
        'message_type': 'image',
        'media_url': imageUrl.trim(),
      },
      httpSend: () => _api.sendMessage(
        conversationId: id,
        content: imageUrl.trim(),
        messageType: 'image',
        mediaUrl: imageUrl.trim(),
      ),
    );
  }

  Future<bool> sendVideo({
    required String videoUrl,
    String? thumbnailUrl,
    String? contentType,
    Map<String, dynamic>? metadata,
  }) async {
    final id = _selectedConversation?.idConversation;
    if (id == null || id <= 0 || videoUrl.trim().isEmpty) return false;
    emitTypingStop();

    return _dispatchMessageSend(
      conversationId: id,
      socketPayload: {
        'conversation_id': id,
        'content': videoUrl.trim(),
        'message_type': 'video',
        'media_url': videoUrl.trim(),
        if ((thumbnailUrl ?? '').trim().isNotEmpty)
          'media_thumbnail_url': thumbnailUrl!.trim(),
        if ((contentType ?? '').trim().isNotEmpty)
          'media_content_type': contentType!.trim(),
        if (metadata != null) 'media_metadata': metadata,
      },
      httpSend: () => _api.sendMessage(
        conversationId: id,
        content: videoUrl.trim(),
        messageType: 'video',
        mediaUrl: videoUrl.trim(),
        mediaThumbnailUrl: thumbnailUrl,
        mediaContentType: contentType,
        mediaMetadata: metadata,
      ),
    );
  }

  Future<bool> _dispatchMessageSend({
    required int conversationId,
    required Map<String, dynamic> socketPayload,
    required Future<ChatMessageModel> Function() httpSend,
  }) async {
    if (!_preferHttpSend) {
      await _ensureSocketConnected();
      if (_socket.isConnected) {
        _socket.emit('message.send', socketPayload);
        return true;
      }
    }

    try {
      final msg = await httpSend();
      _appendMessageIfNew(msg);
      unawaited(refresh());
      return true;
    } catch (e) {
      if (!_preferHttpSend) {
        await _ensureSocketConnected();
        if (_socket.isConnected) {
          _socket.emit('message.send', socketPayload);
          return true;
        }
      } else {
        await _ensureSocketConnected();
        if (_socket.isConnected) {
          _socket.emit('message.send', socketPayload);
          return true;
        }
      }
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _appendMessageIfNew(ChatMessageModel msg) {
    if (_messages.any((m) => m.idMessage == msg.idMessage)) return;
    _messages = [..._messages, msg];
    notifyListeners();
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
    final onlineById = <String, bool>{};
    final onlineByRoleAndName = <String, bool>{};

    for (final raw in rawContacts.whereType<Map<String, dynamic>>()) {
      final id = (raw['user_id'] ?? '').toString().trim();
      final name = (raw['name_user'] ?? raw['name'] ?? '').toString().trim();
      final role = (raw['role_user'] ?? raw['role'] ?? '').toString().trim();
      final key = _roleAndNameKey(role, name);
      final isOnline = raw['is_online'] == true;

      if (id.isNotEmpty) {
        byId[id] = raw;
        nameById[id] = _normalizeName(name);
        onlineById[id] = isOnline;
      }
      if (key.isNotEmpty) {
        byRoleAndName[key] = raw;
        onlineByRoleAndName[key] = isOnline;
      }
    }

    _presenceNameById = nameById;
    _presenceOnlineById = onlineById;
    _presenceOnlineByRoleAndName = onlineByRoleAndName;

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
    final nextOnlineById = Map<String, bool>.from(_presenceOnlineById);
    nextOnlineById[userId] = isOnline;
    _presenceOnlineById = nextOnlineById;

    if (normalizedFromPresence.isNotEmpty) {
      final matchingKeys = _contacts
          .where((c) => _normalizeName(c.nameUser) == normalizedFromPresence)
          .map((c) => _roleAndNameKey(c.roleUser, c.nameUser))
          .where((key) => key.isNotEmpty);
      final nextOnlineByRoleAndName = Map<String, bool>.from(_presenceOnlineByRoleAndName);
      for (final key in matchingKeys) {
        nextOnlineByRoleAndName[key] = isOnline;
      }
      _presenceOnlineByRoleAndName = nextOnlineByRoleAndName;
    }

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

  List<ChatContactModel> _mergePresenceIntoContacts(List<ChatContactModel> contacts) {
    if (contacts.isEmpty) return contacts;

    return contacts
        .map((c) {
          final byId = _presenceOnlineById[c.idUser.trim()];
          final byRoleAndName = _presenceOnlineByRoleAndName[_roleAndNameKey(
            c.roleUser,
            c.nameUser,
          )];
          final isOnline = byId ?? byRoleAndName ?? c.isOnline;

          if (isOnline == c.isOnline) return c;
          return ChatContactModel(
            idUser: c.idUser,
            nameUser: c.nameUser,
            roleUser: c.roleUser,
            isOnline: isOnline,
          );
        })
        .toList(growable: false);
  }

  bool _resolveCachedOnline({
    required String userId,
    String? userName,
    String? userRole,
  }) {
    final byId = _presenceOnlineById[userId.trim()];
    if (byId != null) return byId;

    final roleAndName = _roleAndNameKey(userRole ?? '', userName ?? '');
    if (roleAndName.isEmpty) return false;
    return _presenceOnlineByRoleAndName[roleAndName] ?? false;
  }

  static String _normalizeName(String value) {
    return value.trim().toLowerCase();
  }

  static String _normalizeRole(String value) => UserRole.normalize(value);

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
    _socket.emit('chat.screen.close', {});
    _socketWatchdogTimer?.cancel();
    _socketWatchdogTimer = null;
    _httpPollingTimer?.cancel();
    _httpPollingTimer = null;
    _typingInactivityTimer?.cancel();
    _typingInactivityTimer = null;
    _wsSubscription?.cancel();
    _wsSubscription = null;
    // Cierra el WebSocket: el backend suele no mandar FCM si la sesión WS sigue viva;
    // luego [ChatSocketService.notifyChatUiClosed] reconecta en modo escucha para
    // `message.new` y notificación local fuera del chat.
    unawaited(
      _socket.disconnect().then((_) => ChatSocketService.notifyChatUiClosed()),
    );
    super.dispose();
  }

  void _startSocketWatchdog() {
    _socketWatchdogTimer?.cancel();
    _socketWatchdogTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_ensureSocketConnected());
    });
  }

  Future<void> _ensureSocketConnected() async {
    final token = _tokenService.getToken();
    if (token == null || token.isEmpty) return;
    if (_socket.isConnected) return;

    try {
      await _socket.connect(token);
      _socket.emit('chat.screen.open', {});

      final activeConversationId = _selectedConversation?.idConversation;
      if (activeConversationId != null) {
        _socket.emit('conversation.join', {
          'conversation_id': activeConversationId,
        });
      }
    } catch (_) {
      // noop: reintento en siguiente ciclo del watchdog
    }
  }

  void _startHttpPolling() {
    if (!_useHttpPolling) return;

    listenPageVisibility((visible) {
      if (visible) {
        unawaited(_pollHttpChat());
        _scheduleHttpPollingTimer();
      } else {
        _httpPollingTimer?.cancel();
        _httpPollingTimer = null;
      }
    });

    if (isPageVisible) {
      unawaited(_pollHttpChat());
      _scheduleHttpPollingTimer();
    }
  }

  void _scheduleHttpPollingTimer() {
    _httpPollingTimer?.cancel();
    _httpPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_pollHttpChat());
    });
  }

  Future<void> _pollHttpChat() async {
    if (!isPageVisible) return;

    if (_selectedConversation != null) {
      await _pollActiveConversationMessages();
      return;
    }

    await refresh();
  }

  Future<void> _pollActiveConversationMessages() async {
    final conversation = _selectedConversation;
    if (conversation == null) return;

    final conversationId = conversation.idConversation;
    try {
      final fresh = await _api.fetchMessages(conversationId);
      if (_sameMessageList(_messages, fresh)) return;

      final previousIds = _messages.map((m) => m.idMessage).toSet();
      final hasIncoming = fresh.any(
        (m) => !previousIds.contains(m.idMessage) && m.senderId != _currentUserId,
      );

      _messages = fresh;
      if (hasIncoming) {
        await _api.markConversationRead(conversationId);
        _conversations = _conversations
            .map(
              (item) => item.idConversation == conversationId
                  ? item.copyWith(unreadCount: 0)
                  : item,
            )
            .toList(growable: false);
        _syncUnreadBadge();
      }
      notifyListeners();
    } catch (_) {}
  }

  void _syncUnreadBadge() {
    _unreadBadge.syncFromConversations(_conversations);
  }

  bool _sameMessageList(List<ChatMessageModel> a, List<ChatMessageModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].idMessage != b[i].idMessage || a[i].status != b[i].status) {
        return false;
      }
    }
    return true;
  }
}
