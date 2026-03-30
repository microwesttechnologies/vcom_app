import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/chat/chat_contact.model.dart';
import 'package:vcom_app/core/models/chat/chat_conversation.model.dart';
import 'package:vcom_app/core/models/chat/chat_message.model.dart';

class ChatApiService {
  final TokenService _tokenService = TokenService();

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    return Uri.parse('${EnvironmentDev.resolvedChatApiBaseUrl}${EnvironmentDev.chatApiPath}$path').replace(
      queryParameters: queryParameters,
    );
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      ..._tokenService.getAuthHeaders(),
    };
  }

  Future<Map<String, dynamic>> fetchMe() async {
    final response = await http.get(_uri('/me'), headers: _headers());
    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode >= 400) {
      throw Exception('No fue posible cargar usuario de chat (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['user'] as Map<String, dynamic>? ?? const {});
  }

  Future<List<ChatContactModel>> fetchContacts({
    required String currentRole,
    required String currentUserId,
  }) async {
    // currentRole/currentUserId se mantienen para compatibilidad del contrato.
    // La fuente canónica de contactos ahora es Node /contacts.
    final _ = (currentRole, currentUserId);
    final contacts = await _fetchLegacyContacts();
    return contacts
        .map(
          (c) => ChatContactModel(
            idUser: c.idUser,
            nameUser: c.nameUser,
            roleUser: c.roleUser,
            isOnline: false,
          ),
        )
        .toList(growable: false);
  }

  Future<List<ChatContactModel>> _fetchLegacyContacts() async {
    final response = await http.get(_uri('/contacts'), headers: _headers());
    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode >= 400) {
      throw Exception('No fue posible cargar contactos (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatContactModel.fromJson)
        .toList(growable: false);
  }

  // El estado online/offline se inicializa en false y se sincroniza solo por WS

  Future<ChatConversationModel> createOrGetConversation(String otherUserId) async {
    final response = await http.post(
      _uri('/conversations'),
      headers: _headers(),
      body: jsonEncode({'other_user_id': otherUserId}),
    );

    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode >= 400) {
      throw Exception('No fue posible abrir conversacion (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = body['conversation'] as Map<String, dynamic>?;
    if (raw == null) {
      throw Exception('Respuesta invalida al crear conversacion');
    }

    return ChatConversationModel.fromJson({
      'id_conversation': raw['id_conversation'],
      'other_user_id': otherUserId,
      'created_at': raw['created_at'],
      'updated_at': raw['updated_at'],
      'last_message_at': raw['last_message_at'],
      'unread_count': 0,
      'last_message': null,
    });
  }

  Future<List<ChatConversationModel>> fetchConversations() async {
    final response = await http.get(_uri('/conversations'), headers: _headers());
    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode >= 400) {
      throw Exception('No fue posible cargar conversaciones (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatConversationModel.fromJson)
        .toList(growable: false);
  }

  Future<List<ChatMessageModel>> fetchMessages(
    int conversationId, {
    int limit = 60,
  }) async {
    final response = await http.get(
      _uri('/conversations/$conversationId/messages', queryParameters: {
        'limit': '$limit',
      }),
      headers: _headers(),
    );

    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode >= 400) {
      throw Exception('No fue posible cargar mensajes (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageModel.fromJson)
        .toList(growable: false);
  }

  Future<void> markConversationRead(int conversationId) async {
    final response = await http.post(
      _uri('/conversations/$conversationId/read'),
      headers: _headers(),
    );

    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode >= 400) {
      throw Exception('No fue posible marcar vistos (${response.statusCode})');
    }
  }
}
