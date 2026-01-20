/// Modelo de mensaje del chat
class MessageModel {
  final int idMessage;
  final int idConversation;
  final String idSender; // ID del usuario que envía - UUID String
  final String senderName; // Nombre del remitente
  final String? senderAvatar; // URL del avatar del remitente
  final String content; // Contenido del mensaje (texto o URL de imagen)
  final String messageType; // 'text' o 'image'
  final DateTime createdAt;
  final bool isRead;
  final bool isFromCurrentUser; // Calculado en el frontend

  MessageModel({
    required this.idMessage,
    required this.idConversation,
    required this.idSender,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.messageType = 'text',
    required this.createdAt,
    this.isRead = false,
    this.isFromCurrentUser = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Función helper para convertir a int de forma segura
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed;
      }
      return null;
    }

    final senderId = json['id_sender']?.toString() ?? 
                     json['sender_id']?.toString() ?? '';
    final isFromCurrentUser = currentUserId != null && 
                              currentUserId.toString() == senderId;

    // Extraer información del sender de forma segura
    final senderData = json['sender'];
    final senderName = json['sender_name'] as String? ?? 
                      (senderData != null && senderData is Map 
                        ? senderData['name'] as String? 
                        : null) ?? 'Usuario';
    final senderAvatar = json['sender_avatar'] as String? ?? 
                        (senderData != null && senderData is Map 
                          ? senderData['avatar'] as String? 
                          : null);

    return MessageModel(
      idMessage: _parseInt(json['id_message']) ?? 
                 _parseInt(json['id']) ?? 0,
      idConversation: _parseInt(json['id_conversation']) ?? 
                      _parseInt(json['conversation_id']) ?? 0,
      idSender: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: json['content'] as String? ?? json['message'] as String? ?? '',
      messageType: json['message_type'] as String? ?? json['type'] as String? ?? 'text',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? json['read'] as bool? ?? false,
      isFromCurrentUser: isFromCurrentUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_message': idMessage,
      'id_conversation': idConversation,
      'id_sender': idSender,
      'content': content,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}
