class ChatUiStateService {
  static final ChatUiStateService _instance = ChatUiStateService._internal();
  factory ChatUiStateService() => _instance;
  ChatUiStateService._internal();

  bool _isInChatModule = false;
  int? _openConversationId;

  bool get isInChatModule => _isInChatModule;

  void setInChatModule(bool value) {
    _isInChatModule = value;
  }

  void setOpenConversationId(int? id) {
    _openConversationId = id;
  }

  /// No mostrar bandeja del sistema si el usuario está viendo exactamente esa conversación.
  bool shouldSuppressTrayForConversation(int conversationId) {
    if (!_isInChatModule) return false;
    return _openConversationId != null && _openConversationId == conversationId;
  }
}
