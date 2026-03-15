import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/chat/conversation.model.dart';
import 'package:vcom_app/core/models/chat/message.model.dart';
import 'package:vcom_app/core/realtime/pusher_direct.service.dart';
import 'package:vcom_app/core/realtime/presence.service.dart';

/// ChatComponent usando Pusher directo
/// Basado en la app de prueba que funciona
class ChatComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final PusherDirectService _pusher = PusherDirectService();
  final PresenceService _presence = PresenceService();

  // Estado
  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  ConversationModel? _selectedConversation;
  
  bool _loading = false;
  bool _loadingMessages = false;
  bool _isOtherUserTyping = false;
  String? _error;
  String? _currentUserId;
  String? _userName;

  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  ConversationModel? get selectedConversation => _selectedConversation;
  bool get isLoading => _loading;
  bool get isLoadingMessages => _loadingMessages;
  bool get isOtherUserTyping => _isOtherUserTyping;
  String? get error => _error;

  // Headers para el backend
  Map<String, String> _headers() {
    final token = _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token?.isNotEmpty == true) 'Authorization': 'Bearer $token',
    };
  }

  /// Inicializa el componente
  Future<void> initialize(String role) async {
    _loading = true;
    _error = null;
    _currentUserId = _tokenService.getUserId();
    _userName = _tokenService.getUserName();
    notifyListeners();

    try {
      print('🚀 ========================================');
      print('🚀 INICIALIZANDO CHAT SIMPLIFICADO');
      print('🚀 Usuario: $_userName ($_currentUserId)');
      print('🚀 Rol: $role');
      print('🚀 ========================================');

      // 1. Inicializar Pusher con callback unificado
      await _pusher.init(onMessage: _handleUnifiedPusherMessage);

      // 2. Inicializar y activar el servicio de presencia (usa el mismo Pusher)
      await _presence.initialize();
      await _presence.activate();
      
      // 3. Escuchar cambios de estado de presencia
      _presence.addListener(_onPresenceChanged);

      // 4. Cargar conversaciones desde el backend
      await fetchConversations();

      print('✅ Chat inicializado correctamente');
    } catch (e) {
      _error = e.toString();
      print('❌ Error inicializando chat: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Callback unificado para todos los mensajes de Pusher
  /// Distribuye eventos al handler local
  void _handleUnifiedPusherMessage(Map<String, dynamic> data) {
    print('📨 ========================================');
    print('📨 [UNIFIED] MENSAJE RECIBIDO DE PUSHER');
    print('📨 Data: $data');
    print('📨 ========================================');

    _onPusherMessage(data);
  }

  /// Maneja cambios de estado de presencia
  void _onPresenceChanged() {
    print('🔄 ========================================');
    print('🔄 _onPresenceChanged() LLAMADO');
    print('🔄 Actualizando ${_conversations.length} conversaciones');
    print('🔄 ========================================');
    
    // Actualizar el estado de las conversaciones
    _conversations = _conversations.map((conv) {
      print('👤 Procesando conversación:');
      print('   📝 Nombre: ${conv.otherUserName}');
      print('   🔑 ID: ${conv.idOtherUser}');
      print('   📊 Estado anterior: ${conv.userStatus}');
      
      final isOnline = _presence.isUserOnline(conv.idOtherUser);
      final newStatus = isOnline ? 'online' : 'offline';
      
      print('   ✨ Estado nuevo: $newStatus');
      print('   ---');
      
      return conv.copyWith(
        userStatus: newStatus,
      );
    }).toList();

    // Si hay una conversación seleccionada, actualizarla también
    if (_selectedConversation != null) {
      print('💬 Actualizando conversación seleccionada:');
      print('   📝 Nombre: ${_selectedConversation!.otherUserName}');
      print('   🔑 ID: ${_selectedConversation!.idOtherUser}');
      
      final isOnline = _presence.isUserOnline(_selectedConversation!.idOtherUser);
      _selectedConversation = _selectedConversation!.copyWith(
        userStatus: isOnline ? 'online' : 'offline',
      );
      
      print('   ✨ Estado: ${isOnline ? "ONLINE" : "OFFLINE"}');
    }

    print('✅ ========================================');
    print('✅ Llamando notifyListeners()');
    print('✅ ========================================');
    notifyListeners();
  }

  /// Obtiene las conversaciones desde el backend
  Future<void> fetchConversations() async {
    try {
      print('📥 Obteniendo conversaciones desde el backend...');
      
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.chatConversations}');
      final response = await http.get(url, headers: _headers()).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al obtener conversaciones');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['data'] ?? []);

        print('📋 Lista de conversaciones raw: ${list.length} items');
        
        _conversations = [];
        for (var e in list) {
          try {
            final conv = ConversationModel.fromJson(e);
            _conversations.add(conv);
          } catch (e) {
            print('⚠️ Error parseando conversación: $e');
          }
        }

        // Actualizar estados de conversaciones con datos de presencia
        _conversations = _conversations.map((conv) {
          final isOnline = _presence.isUserOnline(conv.idOtherUser);
          return conv.copyWith(
            userStatus: isOnline ? 'online' : 'offline',
          );
        }).toList();

        print('✅ Conversaciones obtenidas: ${_conversations.length}');
        _error = null;
      } else {
        throw Exception('Error al obtener conversaciones: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _conversations = [];
      print('❌ Error: $_error');
    }

    notifyListeners();
  }

  /// Selecciona una conversación
  Future<void> selectConversation(ConversationModel conversation) async {
    print('📱 Seleccionando conversación: ${conversation.otherUserName}');
    print('📱 idConversation: ${conversation.idConversation}');
    print('📱 idOtherUser: "${conversation.idOtherUser}"');
    print('📱 ¿Está vacío?: ${conversation.idOtherUser.isEmpty}');

    // Si la conversación no tiene ID válido, crearla primero
    if (conversation.idConversation == null || conversation.idConversation == 0) {
      print('⚠️ Conversación sin ID, creando nueva conversación...');
      
      String otherUserId = conversation.idOtherUser;
      
      // Si idOtherUser está vacío, buscarlo por nombre
      if (otherUserId.isEmpty) {
        print('⚠️ idOtherUser está vacío, buscando por nombre: "${conversation.otherUserName}"');
        try {
          otherUserId = await _getUserIdByName(conversation.otherUserName);
          print('✅ ID encontrado: $otherUserId');
        } catch (e) {
          _error = 'No se pudo encontrar el usuario: ${conversation.otherUserName}';
          notifyListeners();
          return;
        }
      }
      
      await _createOrGetConversation(otherUserId);
      
      // Buscar la conversación recién creada en la lista
      await fetchConversations();
      
      // Encontrar la conversación con el usuario
      final newConversation = _conversations.firstWhere(
        (c) => c.idOtherUser == otherUserId || c.otherUserName == conversation.otherUserName,
        orElse: () => conversation,
      );
      
      _selectedConversation = newConversation;
    } else {
      _selectedConversation = conversation;
    }
    
    notifyListeners();

    // Suscribirse al canal de Pusher solo si hay ID válido
    if (_selectedConversation!.idConversation != null && 
        _selectedConversation!.idConversation! > 0) {
      final channelName = 'chat-${_selectedConversation!.idConversation}';
      await _pusher.subscribe(channelName);

      // Cargar mensajes existentes desde el backend
      await fetchMessages(_selectedConversation!.idConversation!);
    } else {
      print('⚠️ No se pudo crear o encontrar la conversación');
      _messages = [];
      notifyListeners();
    }
  }

  /// Obtiene el ID de un usuario por su nombre
  Future<String> _getUserIdByName(String userName) async {
    try {
      print('🔍 Buscando ID de usuario por nombre: "$userName"');
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.chatGetUserByName}');
      print('🔍 URL: $url');

      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'user_name': userName,
        }),
      ).timeout(const Duration(seconds: 10));

      print('🔍 Status Code: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = data['user']['id_user'] as String;
        print('✅ Usuario encontrado: $userId');
        return userId;
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ Error Response: $errorData');
        throw Exception('Usuario no encontrado: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al buscar usuario por nombre: $e');
      rethrow;
    }
  }

  /// Crea o obtiene una conversación con otro usuario
  Future<void> _createOrGetConversation(String? otherUserId) async {
    if (otherUserId == null) {
      throw Exception('ID de usuario no válido');
    }

    try {
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.chatCreateOrGetConversation}');
      
      print('🔵 Creando/obteniendo conversación');
      print('🔵 URL: $url');
      print('🔵 other_user_id: $otherUserId');
      
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'other_user_id': otherUserId,
        }),
      ).timeout(const Duration(seconds: 10));

      print('🔵 Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Conversación creada/obtenida: ${data['conversation']['id_conversation']}');
      } else {
        print('❌ Error Response: ${response.body}');
        throw Exception('Error al crear conversación: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al crear/obtener conversación: $e');
      rethrow;
    }
  }

  /// Limpia la conversación seleccionada
  void clearSelectedConversation() {
    _selectedConversation = null;
    _messages = [];
    notifyListeners();
  }

  /// Obtiene los mensajes desde el backend
  Future<void> fetchMessages(int conversationId) async {
    if (conversationId == 0) {
      _messages = [];
      notifyListeners();
      return;
    }

    _loadingMessages = true;
    notifyListeners();

    try {
      print('📥 Obteniendo mensajes de conversación: $conversationId');

      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.chatMessages(conversationId)}');
      final response = await http.get(url, headers: _headers()).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al obtener mensajes');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['data'] ?? []);

        _messages = list
            .map<MessageModel>((e) => MessageModel.fromJson(e, currentUserId: _currentUserId))
            .toList();

        print('✅ Mensajes obtenidos: ${_messages.length}');
        _error = null;
      } else {
        throw Exception('Error al obtener mensajes: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _messages = [];
      print('❌ Error: $_error');
    } finally {
      _loadingMessages = false;
      notifyListeners();
    }
  }

  /// Envía un mensaje directamente a Pusher
  /// Usa actualización optimista: muestra el mensaje de inmediato antes de la red
  Future<void> sendMessage(String content, {String messageType = 'text'}) async {
    if (_selectedConversation == null) {
      throw Exception('No hay conversación seleccionada');
    }

    final now = DateTime.now();
    final tempId = now.millisecondsSinceEpoch;

    // Crear el mensaje para actualización optimista
    final messageData = {
      'id_message': tempId,
      'id_conversation': _selectedConversation!.idConversation,
      'id_sender': _currentUserId,
      'sender_name': _userName ?? 'Usuario',
      'sender_avatar': null,
      'content': content,
      'message_type': messageType,
      'created_at': now.toIso8601String(),
      'is_read': false,
    };

    // Actualización optimista: mostrar mensaje de inmediato
    final optimisticMessage = MessageModel.fromJson(
      messageData,
      currentUserId: _currentUserId,
    );
    _messages.add(optimisticMessage);
    notifyListeners();

    try {
      // Enviar a Pusher y backend en segundo plano
      final channelName = 'chat-${_selectedConversation!.idConversation}';
      await _pusher.sendMessage(
        channelName: channelName,
        eventName: 'message.sent',
        data: messageData,
      );
      await _saveMessageToBackend(content, messageType: messageType);
    } catch (e) {
      // Revertir en caso de error
      _messages.removeWhere((m) => m.idMessage == tempId);
      notifyListeners();
      rethrow;
    }
  }

  /// Guarda el mensaje en el backend (opcional, para persistencia)
  Future<void> _saveMessageToBackend(String content, {String messageType = 'text'}) async {
    if (_selectedConversation?.idConversation == null) return;

    try {
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.chatSendMessage}');
      final body = {
        'conversation_id': _selectedConversation!.idConversation,
        'content': content,
        'message_type': messageType, // 'text', 'image', o 'video'
      };

      await http.post(
        url,
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));

      print('✅ Mensaje guardado en el backend');
    } catch (e) {
      print('⚠️ Error guardando mensaje en backend (no crítico): $e');
      // No lanzar error, no es crítico
    }
  }

  /// Procesa mensajes entrantes de Pusher
  void _onPusherMessage(Map<String, dynamic> data) {
    print('📨 ========================================');
    print('📨 MENSAJE RECIBIDO DE PUSHER');
    print('📨 Datos: $data');

    try {
      final type = data['type'] as String?;

      // Manejar eventos de typing
      if (type == 'typing.start') {
        final userId = data['user_id'] as String?;
        
        // Solo mostrar typing si NO es el usuario actual
        if (userId != null && userId != _currentUserId) {
          print('⌨️ Usuario comenzó a escribir');
          _isOtherUserTyping = true;
          notifyListeners();
        } else {
          print('⌨️ Ignorando typing propio');
        }
        return;
      }

      if (type == 'typing.stop') {
        final userId = data['user_id'] as String?;
        
        // Solo detener typing si NO es el usuario actual
        if (userId != null && userId != _currentUserId) {
          print('⌨️ Usuario dejó de escribir');
          _isOtherUserTyping = false;
          notifyListeners();
        }
        return;
      }

      // Nota: Los eventos de estado ya fueron filtrados en _handleUnifiedPusherMessage

      // Parsear el mensaje
      final message = MessageModel.fromJson(
        data,
        currentUserId: _currentUserId,
      );

      print('📨 De: ${message.senderName}');
      print('📨 Tipo: ${message.messageType}');
      print('📨 Contenido: ${message.content}');
      print('📨 URL completa: ${message.content}');
      print('📨 Conversación: ${message.idConversation}');
      print('📨 Es mío?: ${message.isFromCurrentUser}');

      // Detener indicador de typing cuando llega un mensaje
      _isOtherUserTyping = false;

      // Si el mensaje es de la conversación actual, agregarlo
      if (_selectedConversation?.idConversation == message.idConversation) {
        // Evitar duplicados
        final exists = _messages.any((m) => m.idMessage == message.idMessage);
        if (!exists) {
          _messages.add(message);
          print('✅ Mensaje agregado a la lista (${_messages.length} mensajes)');
          notifyListeners();
        } else {
          print('⚠️ Mensaje duplicado, ignorando');
        }
      } else {
        print('ℹ️ Mensaje de otra conversación, actualizando lista');
      }

      // Actualizar última conversación en la lista
      _updateConversationLastMessage(message);

      print('✅ ========================================');
    } catch (e, stackTrace) {
      print('❌ Error procesando mensaje de Pusher: $e');
      print('❌ Stack: $stackTrace');
    }
  }

  /// Actualiza el último mensaje de una conversación
  void _updateConversationLastMessage(MessageModel message) {
    _conversations = _conversations.map((c) {
      if (c.idConversation == message.idConversation) {
        return c.copyWith(
          lastMessage: message.content,
          lastMessageAt: message.createdAt,
          unreadCount: message.isFromCurrentUser ? c.unreadCount : (c.unreadCount + 1),
        );
      }
      return c;
    }).toList();

    notifyListeners();
  }

  /// Recarga las conversaciones
  Future<void> refresh() async {
    await fetchConversations();
  }

  /// Recarga los mensajes de la conversación actual
  Future<void> reloadMessages() async {
    if (_selectedConversation?.idConversation != null) {
      await fetchMessages(_selectedConversation!.idConversation!);
    }
  }

  /// Marca los mensajes de una conversación como leídos
  Future<void> markMessagesAsRead(int conversationId) async {
    try {
      print('📖 Marcando mensajes como leídos: conversación $conversationId');
      
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.chatMarkAsRead(conversationId)}');
      
      final response = await http.post(
        url,
        headers: _headers(),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('✅ Mensajes marcados como leídos');
        
        // Actualizar el contador local de no leídos
        _conversations = _conversations.map((conv) {
          if (conv.idConversation == conversationId) {
            return conv.copyWith(unreadCount: 0);
          }
          return conv;
        }).toList();
        
        // Si es la conversación seleccionada, actualizarla también
        if (_selectedConversation?.idConversation == conversationId) {
          _selectedConversation = _selectedConversation!.copyWith(unreadCount: 0);
        }
        
        notifyListeners();
      } else {
        print('⚠️ Error marcando mensajes como leídos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marcando mensajes como leídos: $e');
      // No es crítico, continuar
    }
  }

  /// Emitir evento de typing start
  void emitTypingStart() {
    if (_selectedConversation?.idConversation == null) return;
    
    final channelName = 'chat-${_selectedConversation!.idConversation}';
    _pusher.sendMessage(
      channelName: channelName,
      eventName: 'client-typing',
      data: {
        'type': 'typing.start',
        'user_id': _currentUserId,
        'user_name': _userName,
      },
    ).catchError((e) {
      print('⚠️ Error enviando typing start: $e');
    });
  }

  /// Emitir evento de typing stop
  void emitTypingStop() {
    if (_selectedConversation?.idConversation == null) return;
    
    final channelName = 'chat-${_selectedConversation!.idConversation}';
    _pusher.sendMessage(
      channelName: channelName,
      eventName: 'client-typing',
      data: {
        'type': 'typing.stop',
        'user_id': _currentUserId,
        'user_name': _userName,
      },
    ).catchError((e) {
      print('⚠️ Error enviando typing stop: $e');
    });
  }

  @override
  void dispose() {
    // Remover listener de presencia
    _presence.removeListener(_onPresenceChanged);
    
    // Desactivar presencia (marca como offline)
    _presence.deactivate().catchError((e) {
      print('⚠️ Error en dispose al desactivar presencia: $e');
    });
    
    super.dispose();
  }
  
  /// Método público para desconectar explícitamente
  Future<void> disconnect() async {
    // Desactivar presencia y desconectar
    await _presence.deactivate();
  }
}


