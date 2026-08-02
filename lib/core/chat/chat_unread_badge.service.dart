import 'package:flutter/foundation.dart';
import 'package:vcom_app/core/chat/chat_api.service.dart';
import 'package:vcom_app/core/models/chat/chat_conversation.model.dart';

/// Contador global de mensajes de chat sin leer (badge del menú).
class ChatUnreadBadgeService extends ChangeNotifier {
  static final ChatUnreadBadgeService _instance =
      ChatUnreadBadgeService._internal();
  factory ChatUnreadBadgeService() => _instance;
  ChatUnreadBadgeService._internal();

  final ChatApiService _api = ChatApiService();
  int _totalUnread = 0;
  bool _refreshing = false;

  int get totalUnread => _totalUnread;

  String? get badgeLabel {
    if (_totalUnread <= 0) return null;
    if (_totalUnread > 99) return '99+';
    return _totalUnread.toString();
  }

  void syncFromConversations(List<ChatConversationModel> conversations) {
    final next = conversations.fold<int>(
      0,
      (sum, item) => sum + (item.unreadCount > 0 ? item.unreadCount : 0),
    );
    _setTotal(next);
  }

  void clearAll() => _setTotal(0);

  Future<void> refreshFromApi() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final conversations = await _api.fetchConversations();
      syncFromConversations(conversations);
    } catch (e) {
      debugPrint('ChatUnreadBadge: no se pudo refrescar: $e');
    } finally {
      _refreshing = false;
    }
  }

  void _setTotal(int value) {
    final next = value < 0 ? 0 : value;
    if (next == _totalUnread) return;
    _totalUnread = next;
    notifyListeners();
  }
}
