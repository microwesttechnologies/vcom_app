class ChatUiStateService {
  static final ChatUiStateService _instance = ChatUiStateService._internal();
  factory ChatUiStateService() => _instance;
  ChatUiStateService._internal();

  bool _isInChatModule = false;

  bool get isInChatModule => _isInChatModule;

  void setInChatModule(bool value) {
    _isInChatModule = value;
  }
}
