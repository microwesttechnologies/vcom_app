import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/media_upload.service.dart';
import 'package:vcom_app/core/models/chat/conversation.model.dart';
import 'package:vcom_app/core/realtime/presence.service.dart';
import 'package:vcom_app/pages/chat/chat.component.dart';
import 'package:vcom_app/pages/chat/widgets/message_content.widget.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página de chat usando Pusher directo
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late ChatComponent _chatComponent;
  final PresenceService _presence = PresenceService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _role;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatComponent = ChatComponent();
    _chatComponent.addListener(_onChatChanged);
    _initChat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Manejar cambios en el ciclo de vida de la app
    switch (state) {
      case AppLifecycleState.resumed:
        // La app volvió al primer plano
        print('📱 App resumed - Activando presencia');
        _presence.activate().catchError((e) {
          print('⚠️ Error activando presencia en resume: $e');
        });
        break;
      case AppLifecycleState.paused:
        // La app pasó a segundo plano
        print('📱 App paused - Desactivando presencia');
        _presence.deactivate().catchError((e) {
          print('⚠️ Error desactivando presencia en pause: $e');
        });
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Estados donde la app no está activa
        break;
    }
  }

  Future<void> _initChat() async {
    final tokenService = TokenService();
    _role = tokenService.getRole();
    
    if (_role != null) {
      await _chatComponent.initialize(_role!);
    }
  }

  void _onChatChanged() {
    if (mounted) {
      setState(() {});
      // Hacer scroll automático cuando llegan nuevos mensajes
      if (_chatComponent.messages.isNotEmpty) {
        _scrollToBottom(animated: false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatComponent.removeListener(_onChatChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _chatComponent.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Esperar un frame adicional para asegurar que todo esté renderizado
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            if (animated) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            } else {
              // Scroll instantáneo para carga inicial
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inChat = _chatComponent.selectedConversation != null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: inChat
          ? _ChatNavbar(
              conversation: _chatComponent.selectedConversation!,
              presence: _presence,
              onBack: () => _chatComponent.clearSelectedConversation(),
            )
          : const ModeloNavbar(),
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'chat'),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.8),
            radius: 1.2,
            colors: [
              Color(0xFF273C67),
              Color(0xFF1a2847),
              Color(0xFF0d1525),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_chatComponent.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: VcomColors.oroLujoso,
        ),
      );
    }

    if (_chatComponent.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: VcomColors.error),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: VcomColors.blancoCrema,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _chatComponent.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: VcomColors.blancoCrema.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () => _initChat(),
              style: ElevatedButton.styleFrom(
                backgroundColor: VcomColors.oroLujoso,
                foregroundColor: VcomColors.azulMedianocheTexto,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_chatComponent.selectedConversation == null) {
      return _buildConversationsList(_chatComponent);
    }

    return _buildChatView(_chatComponent);
  }

  Widget _buildConversationsList(ChatComponent chat) {
    if (chat.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: VcomColors.oroLujoso.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No hay conversaciones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: VcomColors.blancoCrema.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => chat.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: VcomColors.oroLujoso,
                foregroundColor: VcomColors.azulMedianocheTexto,
              ),
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'Conversaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: VcomColors.oroLujoso,
            backgroundColor: VcomColors.azulZafiroProfundo,
            onRefresh: () => chat.refresh(),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(8, 4, 8, 8 + 70),
        itemCount: chat.conversations.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: VcomColors.oroLujoso.withOpacity(0.1),
        ),
        itemBuilder: (context, index) {
          final conversation = chat.conversations[index];
          final isOnline = _presence.isUserOnline(conversation.idOtherUser);
          final statusText = _presence.getUserStatusText(conversation.idOtherUser);
          
          return Container(
            decoration: BoxDecoration(
              color: VcomColors.azulNocheSombra,
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: VcomColors.oroLujoso,
                    child: Text(
                      conversation.otherUserName[0].toUpperCase(),
                      style: const TextStyle(
                        color: VcomColors.azulMedianocheTexto,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: VcomColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: VcomColors.azulZafiroProfundo,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                conversation.otherUserName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: VcomColors.blancoCrema,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLastMessagePreview(conversation),
                  if (!isOnline)
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        color: VcomColors.blancoCrema.withOpacity(0.4),
                      ),
                    ),
                ],
              ),
              trailing: conversation.unreadCount > 0
                  ? CircleAvatar(
                      backgroundColor: VcomColors.error,
                      radius: 12,
                      child: Text(
                        '${conversation.unreadCount}',
                        style: const TextStyle(
                          color: VcomColors.blanco,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () async {
                await chat.selectConversation(conversation);
                
                // Marcar mensajes como leídos
                if (conversation.unreadCount > 0 && conversation.idConversation != null) {
                  await chat.markMessagesAsRead(conversation.idConversation!);
                }
                
                // Hacer scroll con delay para asegurar que los mensajes se cargaron
                Future.delayed(const Duration(milliseconds: 300), () {
                  _scrollToBottom(animated: false);
                });
              },
            ),
          );
        },
      ),
    ),
  ),
      ],
    );
  }

  Widget _buildChatView(ChatComponent chat) {
    return Column(
      children: [
        // Messages
        Expanded(
          child: chat.isLoadingMessages
              ? Center(
                  child: CircularProgressIndicator(
                    color: VcomColors.oroLujoso,
                  ),
                )
              : chat.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_outlined,
                            size: 64,
                            color: VcomColors.oroLujoso.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay mensajes\n¡Envía el primero!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: VcomColors.blancoCrema.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            reverse: false,
                            itemCount: chat.messages.length,
                            itemBuilder: (context, index) {
                        final message = chat.messages[index];
                        final isMe = message.isFromCurrentUser;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: isMe
                                  ? const LinearGradient(
                                      colors: [
                                        VcomColors.oroLujoso,
                                        VcomColors.bronceDorado,
                                      ],
                                    )
                                  : null,
                              color: isMe ? null : VcomColors.azulZafiroProfundo,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMe ? 18 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: VcomColors.azulNocheSombra.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      message.senderName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: VcomColors.oroLujoso,
                                      ),
                                    ),
                                  ),
                                MessageContentWidget(
                                  content: message.content,
                                  messageType: message.messageType,
                                  isMe: isMe,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(message.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? VcomColors.azulMedianocheTexto.withOpacity(0.7)
                                        : VcomColors.blancoCrema.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                            },
                          ),
                        ),
                        if (chat.isOtherUserTyping)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: VcomColors.azulZafiroProfundo,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Escribiendo',
                                        style: TextStyle(
                                          color: VcomColors.oroLujoso,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            VcomColors.oroLujoso,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 1, 7, 21),
            border: Border(
              top: BorderSide(
                color: VcomColors.oroLujoso.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Botones imagen y cámara pegados a la izquierda
                IconButton(
                  icon: Icon(Icons.image, color: VcomColors.oroLujoso, size: 20),
                  onPressed: () => _showImageSourceDialog(chat),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: Icon(Icons.videocam, color: VcomColors.oroLujoso, size: 20),
                  onPressed: () => _showVideoSourceDialog(chat),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF8BA3C7),
                    ),
                    onChanged: (text) {
                      if (text.isNotEmpty && !_isTyping) {
                        _isTyping = true;
                        _chatComponent.emitTypingStart();
                      } else if (text.isEmpty && _isTyping) {
                        _isTyping = false;
                        _chatComponent.emitTypingStop();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF6B7B9A),
                      ),
                      filled: true,
                      fillColor: VcomColors.azulNocheSombra,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: VcomColors.oroLujoso.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: VcomColors.oroLujoso.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: VcomColors.oroLujoso,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: VcomColors.oroLujoso,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => _sendMessage(chat),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.send,
                        size: 18,
                        color: VcomColors.azulMedianocheTexto,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage(ChatComponent chat) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_isTyping) {
      _isTyping = false;
      chat.emitTypingStop();
    }

    // Limpiar y hacer scroll de inmediato para respuesta fluida
    _messageController.clear();
    _scrollToBottom();

    try {
      await chat.sendMessage(text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar mensaje: $e'),
          backgroundColor: VcomColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Muestra diálogo para elegir entre galería o cámara (IMAGEN)
  Future<void> _showImageSourceDialog(ChatComponent chat) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VcomColors.azulZafiroProfundo,
        title: Text(
          'Seleccionar imagen',
          style: TextStyle(color: VcomColors.blancoCrema),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Opción Galería
            ListTile(
              leading: Icon(Icons.photo_library, color: VcomColors.oroLujoso),
              title: Text(
                'Galería',
                style: TextStyle(color: VcomColors.blancoCrema),
              ),
              onTap: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 8),
            // Opción Cámara
            ListTile(
              leading: Icon(Icons.camera_alt, color: VcomColors.oroLujoso),
              title: Text(
                'Cámara',
                style: TextStyle(color: VcomColors.blancoCrema),
              ),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _sendMedia(chat, isVideo: false, fromCamera: result);
    }
  }

  /// Muestra diálogo para elegir entre galería o cámara (VIDEO)
  Future<void> _showVideoSourceDialog(ChatComponent chat) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VcomColors.azulZafiroProfundo,
        title: Text(
          'Seleccionar video',
          style: TextStyle(color: VcomColors.blancoCrema),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Opción Galería
            ListTile(
              leading: Icon(Icons.video_library, color: VcomColors.oroLujoso),
              title: Text(
                'Galería',
                style: TextStyle(color: VcomColors.blancoCrema),
              ),
              onTap: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 8),
            // Opción Grabar
            ListTile(
              leading: Icon(Icons.videocam, color: VcomColors.oroLujoso),
              title: Text(
                'Grabar video',
                style: TextStyle(color: VcomColors.blancoCrema),
              ),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _sendMedia(chat, isVideo: true, fromCamera: result);
    }
  }

  /// Envía un archivo multimedia (imagen o video)
  Future<void> _sendMedia(
    ChatComponent chat, {
    required bool isVideo,
    bool fromCamera = false,
  }) async {
    final mediaService = MediaUploadService();

    try {
      // Mostrar diálogo de carga
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: VcomColors.azulZafiroProfundo,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(VcomColors.oroLujoso),
                ),
                const SizedBox(height: 16),
                Text(
                  isVideo ? 'Subiendo video...' : 'Subiendo imagen...',
                  style: TextStyle(color: VcomColors.blancoCrema),
                ),
              ],
            ),
          ),
        );
      }

      // Seleccionar y subir el archivo
      String? fileUrl;
      if (isVideo) {
        fileUrl = await mediaService.selectAndUploadVideo(fromCamera: fromCamera);
      } else {
        fileUrl = await mediaService.selectAndUploadImage(fromCamera: fromCamera);
      }

      // Cerrar diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (fileUrl == null) {
        // Usuario canceló la selección
        return;
      }

      // Enviar mensaje con el archivo
      await chat.sendMessage(
        fileUrl,
        messageType: isVideo ? 'video' : 'image',
      );

      _scrollToBottom();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isVideo ? 'Video enviado' : 'Imagen enviada'),
            backgroundColor: VcomColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: VcomColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Construye el preview del último mensaje con iconos para multimedia
  Widget _buildLastMessagePreview(dynamic conversation) {
    if (conversation.lastMessage == null || conversation.lastMessage.isEmpty) {
      return Text(
        'Sin mensajes',
        style: TextStyle(
          color: VcomColors.blancoCrema.withOpacity(0.5),
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      );
    }

    // Detectar si es una URL de imagen o video
    final message = conversation.lastMessage as String;
    final isImage = message.contains('/images/') || 
                    message.endsWith('.jpg') || 
                    message.endsWith('.jpeg') || 
                    message.endsWith('.png') ||
                    message.endsWith('.gif') ||
                    message.endsWith('.webp');
    
    final isVideo = message.contains('/videos/') || 
                    message.endsWith('.mp4') || 
                    message.endsWith('.mov') ||
                    message.endsWith('.avi');

    if (isImage) {
      return Row(
        children: [
          Icon(
            Icons.image,
            size: 16,
            color: VcomColors.oroLujoso.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            'Imagen',
            style: TextStyle(
              color: VcomColors.blancoCrema.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    if (isVideo) {
      return Row(
        children: [
          Icon(
            Icons.videocam,
            size: 16,
            color: VcomColors.oroLujoso.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            'Video',
            style: TextStyle(
              color: VcomColors.blancoCrema.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    // Mensaje de texto normal
    return Text(
      message,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: conversation.unreadCount > 0
            ? VcomColors.blancoCrema.withOpacity(0.9)  // Más visible si no leído
            : VcomColors.blancoCrema.withOpacity(0.6),
        fontSize: 13,
        fontWeight: conversation.unreadCount > 0 
            ? FontWeight.w500  // Más peso si no leído
            : FontWeight.normal,
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Hoy - mostrar hora
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Navbar del chat con el mismo estilo glass que el navbar compartido
class _ChatNavbar extends StatelessWidget implements PreferredSizeWidget {
  final ConversationModel conversation;
  final PresenceService presence;
  final VoidCallback onBack;

  const _ChatNavbar({
    required this.conversation,
    required this.presence,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isOnline = presence.isUserOnline(conversation.idOtherUser);
    final statusText = presence.getUserStatusText(conversation.idOtherUser);
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: onBack,
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [VcomColors.primaryPurple, VcomColors.oroLujoso],
              ),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: VcomColors.azulNocheSombra,
              backgroundImage: conversation.otherUserAvatar != null
                  ? NetworkImage(conversation.otherUserAvatar!)
                  : null,
              child: conversation.otherUserAvatar == null
                  ? Text(
                      conversation.otherUserName.isNotEmpty
                          ? conversation.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: VcomColors.oroLujoso,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: isOnline
                        ? VcomColors.success
                        : VcomColors.blancoCrema.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  conversation.otherUserName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: VcomColors.blancoCrema,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
