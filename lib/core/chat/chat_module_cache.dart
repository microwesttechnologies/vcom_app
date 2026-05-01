import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcom_app/core/models/chat/chat_contact.model.dart';
import 'package:vcom_app/core/models/chat/chat_conversation.model.dart';

/// Listas del inbox de chat (contactos + conversaciones) para no repetir GET al reabrir el módulo.
class ChatListCacheData {
  final Map<String, dynamic> me;
  final List<ChatContactModel> contacts;
  final List<ChatConversationModel> conversations;

  ChatListCacheData({
    required this.me,
    required this.contacts,
    required this.conversations,
  });
}

class ChatModuleCache {
  ChatModuleCache._();
  static final ChatModuleCache instance = ChatModuleCache._();

  static const _prefsKey = 'chat_module_inbox_cache_v1';

  ChatListCacheData? _memory;
  String? _memoryUserId;

  Future<ChatListCacheData?> load(String userId) async {
    final u = userId.trim();
    if (u.isEmpty) return null;

    if (_memoryUserId == u && _memory != null) {
      return _memory;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return null;

      final root = jsonDecode(raw) as Map<String, dynamic>;
      if ((root['user_id'] ?? '').toString().trim() != u) return null;

      final me = root['me'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(root['me'] as Map)
          : <String, dynamic>{};

      final contacts = (root['contacts'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ChatContactModel.fromJson)
          .toList(growable: false);

      final conversations = (root['conversations'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ChatConversationModel.fromJson)
          .toList(growable: false);

      final data = ChatListCacheData(
        me: me,
        contacts: contacts,
        conversations: conversations,
      );
      _memory = data;
      _memoryUserId = u;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required String userId,
    required Map<String, dynamic> me,
    required List<ChatContactModel> contacts,
    required List<ChatConversationModel> conversations,
  }) async {
    final u = userId.trim();
    if (u.isEmpty) return;

    final data = ChatListCacheData(
      me: Map<String, dynamic>.from(me),
      contacts: List<ChatContactModel>.from(contacts),
      conversations: List<ChatConversationModel>.from(conversations),
    );
    _memory = data;
    _memoryUserId = u;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'user_id': u,
          'me': me,
          'contacts': contacts.map((c) => c.toJson()).toList(growable: false),
          'conversations':
              conversations.map((c) => c.toJson()).toList(growable: false),
        }),
      );
    } catch (_) {}
  }

  Future<void> clear() async {
    _memory = null;
    _memoryUserId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}
