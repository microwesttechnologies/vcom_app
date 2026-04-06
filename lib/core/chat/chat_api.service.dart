import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/chat/chat_contact.model.dart';
import 'package:vcom_app/core/models/chat/chat_conversation.model.dart';
import 'package:vcom_app/core/models/chat/chat_message.model.dart';

class ChatApiService {
  final TokenService _tokenService = TokenService();

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    return Uri.parse(
      '${EnvironmentDev.resolvedChatApiBaseUrl}${EnvironmentDev.chatApiPath}$path',
    ).replace(queryParameters: queryParameters);
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      ..._tokenService.getAuthHeaders(),
    };
  }

  Future<Map<String, dynamic>> fetchMe() async {
    final response = await http.get(_uri('/me'), headers: _headers());

    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible cargar usuario de chat (${response.statusCode})',
      );
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
    return _fetchLegacyContacts();
  }

  Future<List<ChatContactModel>> _fetchLegacyContacts() async {
    final response = await http.get(_uri('/contacts'), headers: _headers());

    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible cargar contactos (${response.statusCode})',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatContactModel.fromJson)
        .toList(growable: false);
  }

  // El estado online/offline se inicializa en false y se sincroniza solo por WS

  Future<ChatConversationModel> createOrGetConversation(
    String otherUserId,
  ) async {
    final response = await http.post(
      _uri('/conversations'),
      headers: _headers(),
      body: jsonEncode({'other_user_id': otherUserId}),
    );

    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible abrir conversacion (${response.statusCode})',
      );
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
    final response = await http.get(
      _uri('/conversations'),
      headers: _headers(),
    );

    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible cargar conversaciones (${response.statusCode})',
      );
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
      _uri(
        '/conversations/$conversationId/messages',
        queryParameters: {'limit': '$limit'},
      ),
      headers: _headers(),
    );

    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible cargar mensajes (${response.statusCode})',
      );
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

    if (response.statusCode >= 400) {
      throw Exception('No fue posible marcar vistos (${response.statusCode})');
    }
  }

  Future<void> registerPushToken(String pushToken) async {
    final payloads = [
      {'push_token': pushToken, 'platform': _platformName()},
      {'token': pushToken, 'platform': _platformName()},
      {'fcm_token': pushToken, 'platform': _platformName()},
      {
        'push_token': pushToken,
        'fcm_token': pushToken,
        'token': pushToken,
        'platform': _platformName(),
      },
    ];
    final paths = [
      EnvironmentDev.chatPushTokensPath,
      '/push-tokens',
      '/device/push-token',
    ];

    http.Response? lastResponse;
    for (final path in paths) {
      for (final payload in payloads) {
        final response = await http.post(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(payload),
        );

        if (response.statusCode < 400) {
          return;
        }

        lastResponse = response;
        if (response.statusCode == 401) {
          throw Exception(
            'No fue posible registrar push token (${response.statusCode})',
          );
        }
      }
    }

    throw Exception(
      'No fue posible registrar push token (${lastResponse?.statusCode ?? 0})',
    );
  }

  Future<void> unregisterPushToken(String pushToken) async {
    final payloads = [
      {'push_token': pushToken, 'platform': _platformName()},
      {'token': pushToken, 'platform': _platformName()},
      {'fcm_token': pushToken, 'platform': _platformName()},
    ];
    final paths = [
      EnvironmentDev.chatPushTokensPath,
      '/push-tokens',
      '/device/push-token',
    ];

    http.Response? lastResponse;
    for (final path in paths) {
      for (final payload in payloads) {
        final response = await http.delete(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(payload),
        );

        if (response.statusCode < 400 || response.statusCode == 404) {
          return;
        }

        lastResponse = response;
        if (response.statusCode == 401) {
          throw Exception(
            'No fue posible eliminar push token (${response.statusCode})',
          );
        }
      }
    }

    throw Exception(
      'No fue posible eliminar push token (${lastResponse?.statusCode ?? 0})',
    );
  }

  String _platformName() {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
