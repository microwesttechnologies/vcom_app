import 'message.model.dart';

/// Modelo de conversación del chat
class ConversationModel {
  final int? idConversation; // Puede ser null si no hay conversación aún (para monitores)
  final String idOtherUser; // ID del otro participante (modelo o monitor) - UUID String
  final String otherUserName; // Nombre del otro participante
  final String? otherUserAvatar; // Avatar del otro participante
  final String? lastMessage; // Último mensaje
  final DateTime? lastMessageAt; // Timestamp del último mensaje
  final int unreadCount; // Número de mensajes no leídos
  final String userStatus; // 'online', 'offline', 'away'
  final bool isActive; // Si la modelo está activa (solo para Monitor)
  final MessageModel? lastMessageModel; // Objeto del último mensaje completo
  final DateTime? updatedAt; // Fecha de última actualización
  final DateTime? createdAt; // Fecha de creación
  final DateTime? lastSeen; // Última vez que el usuario estuvo en línea

  ConversationModel({
    this.idConversation, // Opcional para permitir modelos sin conversación
    required this.idOtherUser,
    required this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.userStatus = 'offline',
    this.isActive = true,
    this.lastMessageModel,
    this.updatedAt,
    this.createdAt,
    this.lastSeen,
  });

  // ===================== COPY WITH =====================
  ConversationModel copyWith({
    int? idConversation,
    String? idOtherUser,
    String? otherUserName,
    String? otherUserAvatar,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    String? userStatus,
    bool? isActive,
    MessageModel? lastMessageModel,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? lastSeen,
  }) {
    return ConversationModel(
      idConversation: idConversation ?? this.idConversation,
      idOtherUser: idOtherUser ?? this.idOtherUser,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      userStatus: userStatus ?? this.userStatus,
      isActive: isActive ?? this.isActive,
      lastMessageModel: lastMessageModel ?? this.lastMessageModel,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  // ===================== FROM JSON =====================
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    MessageModel? lastMessageModel;
    if (json['last_message'] != null && json['last_message'] is Map) {
      lastMessageModel =
          MessageModel.fromJson(json['last_message'] as Map<String, dynamic>);
    }

    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    final otherUserData = json['other_user'];
    final otherUserName =
        json['other_user_name'] as String? ??
        (otherUserData is Map ? otherUserData['name'] as String? : null) ??
        json['participant_name'] as String? ??
        'Usuario';

    final otherUserAvatar =
        json['other_user_avatar'] as String? ??
        (otherUserData is Map ? otherUserData['avatar'] as String? : null);

    final userStatus =
        json['user_status'] as String? ??
        (otherUserData is Map ? otherUserData['status'] as String? : null) ??
        'offline';

    final isActive =
        json['is_active'] as bool? ??
        (otherUserData is Map ? otherUserData['is_active'] as bool? : null) ??
        true;

    final lastMessageData = json['last_message'];
    final lastMessageText =
        json['last_message_text'] as String? ??
        (lastMessageData is Map ? lastMessageData['content'] as String? : null);

    return ConversationModel(
      idConversation:
          _parseInt(json['id_conversation']) ??
          _parseInt(json['id']),
      idOtherUser:
          json['id_other_user']?.toString() ??
          json['id_model']?.toString() ?? // Para monitores que ven modelos
          json['id_monitor']?.toString() ?? // Para modelos que ven su monitor
          (otherUserData is Map ? otherUserData['id']?.toString() : null) ??
          (otherUserData is Map ? otherUserData['id_user']?.toString() : null) ??
          json['participant_id']?.toString() ??
          '',
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
      lastMessage: lastMessageText,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : (lastMessageData is Map && lastMessageData['created_at'] != null
              ? DateTime.parse(lastMessageData['created_at'] as String)
              : null),
      unreadCount:
          _parseInt(json['unread_count']) ??
          _parseInt(json['unread_messages']) ??
          0,
      userStatus: userStatus,
      isActive: isActive,
      lastMessageModel: lastMessageModel,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : (otherUserData is Map && otherUserData['last_seen'] != null
              ? DateTime.parse(otherUserData['last_seen'] as String)
              : null),
    );
  }

  // ===================== TO JSON =====================
  Map<String, dynamic> toJson() {
    return {
      'id_conversation': idConversation,
      'id_other_user': idOtherUser,
      'other_user_name': otherUserName,
      'other_user_avatar': otherUserAvatar,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'user_status': userStatus,
      'is_active': isActive,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }
}
