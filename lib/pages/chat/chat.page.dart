import 'package:flutter/material.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/media_upload.service.dart';
import 'package:vcom_app/pages/chat/chat.component.dart';
import 'package:vcom_app/pages/chat/widgets/message_content.widget.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página de chat usando Pusher directo
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ChatComponent _chatComponent;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _role;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _chatComponent = ChatComponent();
    _chatComponent.addListener(_onChatChanged);
    _initChat();
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
    }
  }

  @override
  void dispose() {
    _chatComponent.removeListener(_onChatChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _chatComponent.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: VcomColors.azulZafiroProfundo,
        foregroundColor: VcomColors.oroLujoso,
        elevation: 0,
      ),
      backgroundColor: VcomColors.azulNocheSombra,
      body: _buildBody(),
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

    return RefreshIndicator(
      color: VcomColors.oroLujoso,
      backgroundColor: VcomColors.azulZafiroProfundo,
      onRefresh: () => chat.refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: chat.conversations.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: VcomColors.oroLujoso.withOpacity(0.1),
        ),
        itemBuilder: (context, index) {
          final conversation = chat.conversations[index];
          final isOnline = conversation.userStatus == 'online';
          
          return Container(
            decoration: BoxDecoration(
              color: VcomColors.azulZafiroProfundo,
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
              subtitle: Text(
                conversation.lastMessage ?? 'Sin mensajes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: VcomColors.blancoCrema.withOpacity(0.6),
                ),
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
                _scrollToBottom();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatView(ChatComponent chat) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && chat.messages.isNotEmpty) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VcomColors.azulZafiroProfundo,
                VcomColors.azulNocheSombra,
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: VcomColors.oroLujoso.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: VcomColors.oroLujoso),
                onPressed: () {
                  // Solo limpiar la selección, NO desconectar completamente
                  chat.clearSelectedConversation();
                },
              ),
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: VcomColors.oroLujoso,
                    child: Text(
                      chat.selectedConversation!.otherUserName[0].toUpperCase(),
                      style: const TextStyle(
                        color: VcomColors.azulMedianocheTexto,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (chat.selectedConversation!.userStatus == 'online')
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
                            color: VcomColors.azulNocheSombra,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.selectedConversation!.otherUserName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: VcomColors.blancoCrema,
                      ),
                    ),
                    Text(
                      chat.selectedConversation!.userStatus == 'online'
                          ? 'En línea'
                          : 'Desconectado',
                      style: TextStyle(
                        fontSize: 12,
                        color: chat.selectedConversation!.userStatus == 'online'
                            ? VcomColors.success
                            : VcomColors.blancoCrema.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VcomColors.azulZafiroProfundo,
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
                // Botón para adjuntar imagen
                IconButton(
                  icon: Icon(
                    Icons.image,
                    color: VcomColors.oroLujoso,
                  ),
                  onPressed: () => _sendMedia(chat, isVideo: false),
                ),
                // Botón para adjuntar video
                IconButton(
                  icon: Icon(
                    Icons.videocam,
                    color: VcomColors.oroLujoso,
                  ),
                  onPressed: () => _sendMedia(chat, isVideo: true),
                ),
                Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: VcomColors.blancoCrema),
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
                        color: VcomColors.blancoCrema.withOpacity(0.4),
                      ),
                      filled: true,
                      fillColor: VcomColors.azulNocheSombra,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: VcomColors.oroLujoso.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: VcomColors.oroLujoso.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: VcomColors.oroLujoso,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        VcomColors.oroBrillante,
                        VcomColors.oroLujoso,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 20),
                    color: VcomColors.azulMedianocheTexto,
                    onPressed: () => _sendMessage(chat),
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

    try {
      if (_isTyping) {
        _isTyping = false;
        chat.emitTypingStop();
      }
      
      await chat.sendMessage(text);
      _messageController.clear();
      _scrollToBottom();
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

  /// Envía un archivo multimedia (imagen o video)
  Future<void> _sendMedia(ChatComponent chat, {required bool isVideo}) async {
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
        fileUrl = await mediaService.selectAndUploadVideo();
      } else {
        fileUrl = await mediaService.selectAndUploadImage();
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
