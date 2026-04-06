class ChatMessageModel {
  final int idMessage;
  final int idConversation;
  final String senderId;
  final String recipientId;
  final String content;
  final String messageType;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final String? mediaContentType;
  final Map<String, dynamic>? mediaMetadata;
  final String status;
  final DateTime createdAt;
  final DateTime? receivedAt;
  final DateTime? seenAt;

  ChatMessageModel({
    required this.idMessage,
    required this.idConversation,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.messageType,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaContentType,
    this.mediaMetadata,
    required this.status,
    required this.createdAt,
    this.receivedAt,
    this.seenAt,
  });

  bool get isSeen => status == 'seen';
  bool get isReceived => status == 'received';
  bool get isUnseen => status == 'unseen';

  ChatMessageModel copyWith({
    String? status,
    DateTime? receivedAt,
    DateTime? seenAt,
  }) {
    return ChatMessageModel(
      idMessage: idMessage,
      idConversation: idConversation,
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      messageType: messageType,
      mediaUrl: mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl,
      mediaContentType: mediaContentType,
      mediaMetadata: mediaMetadata,
      status: status ?? this.status,
      createdAt: createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
      seenAt: seenAt ?? this.seenAt,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      idMessage: _toInt(json['id_message']),
      idConversation: _toInt(json['id_conversation']),
      senderId: (json['sender_id'] ?? '').toString(),
      recipientId: (json['recipient_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      messageType: (json['message_type'] ?? 'text').toString(),
      mediaUrl: _toNullableString(json['media_url']),
      mediaThumbnailUrl: _toNullableString(json['media_thumbnail_url']),
      mediaContentType: _toNullableString(json['media_content_type']),
      mediaMetadata: _toMap(json['media_metadata']),
      status: (json['status'] ?? 'unseen').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      receivedAt: DateTime.tryParse((json['received_at'] ?? '').toString()),
      seenAt: DateTime.tryParse((json['seen_at'] ?? '').toString()),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static String? _toNullableString(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return null;
  }
}
