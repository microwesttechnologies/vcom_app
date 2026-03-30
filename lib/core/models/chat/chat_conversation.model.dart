class ChatConversationModel {
  final int idConversation;
  final String otherUserId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;
  final String? lastMessageContent;
  final String? lastMessageType;
  final String? lastMessageSenderId;
  final int unreadCount;

  ChatConversationModel({
    required this.idConversation,
    required this.otherUserId,
    required this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
    this.lastMessageContent,
    this.lastMessageType,
    this.lastMessageSenderId,
    required this.unreadCount,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final lastMessage = json['last_message'] as Map<String, dynamic>?;

    return ChatConversationModel(
      idConversation: _toInt(json['id_conversation']),
      otherUserId: (json['other_user_id'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
      lastMessageAt: DateTime.tryParse((json['last_message_at'] ?? '').toString()),
      lastMessageContent: lastMessage?['content']?.toString(),
      lastMessageType: lastMessage?['message_type']?.toString(),
      lastMessageSenderId: lastMessage?['sender_id']?.toString(),
      unreadCount: _toInt(json['unread_count']),
    );
  }

  ChatConversationModel copyWith({
    int? idConversation,
    String? otherUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? lastMessageContent,
    String? lastMessageType,
    String? lastMessageSenderId,
    int? unreadCount,
  }) {
    return ChatConversationModel(
      idConversation: idConversation ?? this.idConversation,
      otherUserId: otherUserId ?? this.otherUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }
}