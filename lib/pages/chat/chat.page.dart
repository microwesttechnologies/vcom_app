import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:vcom_app/components/shared/video_thumbnail.widget.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/media_upload.service.dart';
import 'package:vcom_app/core/chat/chat_ui_state.service.dart';
import 'package:vcom_app/core/models/chat/chat_contact.model.dart';
import 'package:vcom_app/core/models/chat/chat_conversation.model.dart';
import 'package:vcom_app/core/models/chat/chat_message.model.dart';
import 'package:vcom_app/pages/chat/chat.component.dart';
import 'package:vcom_app/pages/shop/store_fullscreen_images.view.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class ChatPage extends StatefulWidget {
  final String? initialOtherUserId;
  final String? initialOtherUserName;
  final String? initialOtherUserRole;

  const ChatPage({
    super.key,
    this.initialOtherUserId,
    this.initialOtherUserName,
    this.initialOtherUserRole,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatComponent _component = ChatComponent();
  final ChatUiStateService _chatUiStateService = ChatUiStateService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isMediaUploading = false;
  double? _uploadProgress;
  String _uploadStatusLabel = '';

  @override
  void initState() {
    super.initState();
    _chatUiStateService.setInChatModule(true);
    _component.addListener(_onChanged);
    _component.initialize().then((_) => _openInitialConversationIfNeeded());
  }

  @override
  void dispose() {
    _chatUiStateService.setInChatModule(false);
    _component.removeListener(_onChanged);
    _component.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    _chatUiStateService.setOpenConversationId(
      _component.selectedConversation?.idConversation,
    );
    setState(() {});

    if (_component.selectedConversation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _openInitialConversationIfNeeded() async {
    final userId = widget.initialOtherUserId?.trim() ?? '';
    if (userId.isEmpty || !mounted) return;

    await _component.openConversationByUserId(
      userId: userId,
      userName: widget.initialOtherUserName,
      userRole: widget.initialOtherUserRole,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inConversation = _component.selectedConversation != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(inConversation),
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'chat'),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.85),
            radius: 1.25,
            colors: [
              Color(0xFF23385F),
              Color(0xFF111C33),
              Color(0xFF050A13),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.34, 0.72, 1.0],
          ),
        ),
        child: SafeArea(
          child: _component.isLoading && !inConversation
              ? const Center(
                  child: CircularProgressIndicator(color: VcomColors.oroLujoso),
                )
              : inConversation
                  ? _buildConversationView()
                  : _buildInboxView(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool inConversation) {
    final title = inConversation
        ? (_component.selectedContact?.nameUser ?? 'Chat')
        : 'Mensajes';

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: inConversation
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => _component.backToList(),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        if (_component.selectedContact != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildOnlineDot(_component.selectedContact!.isOnline),
          ),
      ],
    );
  }

  Widget _buildInboxView() {
    if (_component.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _component.error!,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _component.refresh,
      color: VcomColors.oroLujoso,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
        children: [
          const Text(
            'Contactos disponibles',
            style: TextStyle(
              color: Color(0xFFD7DCE6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_component.contacts.isEmpty)
            _emptyCard('No hay usuarios compatibles para chatear.'),
          for (final contact in _component.contacts) _buildContactTile(contact),
          const SizedBox(height: 14),
          const Text(
            'Conversaciones',
            style: TextStyle(
              color: Color(0xFFD7DCE6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_component.conversations.isEmpty)
            _emptyCard('Aun no tienes conversaciones.'),
          for (final conversation in _component.conversations)
            _buildConversationTile(conversation),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ChatConversationModel conversation) {
    final userId = conversation.otherUserId;
    ChatContactModel? contact;
    for (final item in _component.contacts) {
      if (item.idUser == userId) {
        contact = item;
        break;
      }
    }

    if (contact == null) return const SizedBox.shrink();
    return _buildContactTile(contact, unreadCount: conversation.unreadCount);
  }

  Widget _buildContactTile(ChatContactModel contact, {int unreadCount = 0}) {
    final initial = contact.nameUser.isNotEmpty ? contact.nameUser[0].toUpperCase() : '?';
    final hasUnread = unreadCount > 0;
    final unreadLabel = unreadCount > 99 ? '99+' : unreadCount.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0x5A0C1322),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _component.openConversation(contact),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF243654),
                  child: Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.nameUser,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact.roleUser,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasUnread) _buildUnreadBadge(unreadLabel),
                    if (hasUnread) const SizedBox(width: 8),
                    _buildOnlineDot(contact.isOnline),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineDot(bool isOnline) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF4ADE80) : const Color(0xFF71717A),
        shape: BoxShape.circle,
        boxShadow: [
          if (isOnline)
            BoxShadow(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.65),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
    );
  }

  Widget _buildUnreadBadge(String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildConversationView() {
    final messages = _component.messages;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            itemCount: messages.length + (_component.isOtherTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (_component.isOtherTyping && index == messages.length) {
                return _typingBubble();
              }

              final message = messages[index];
              final isMe = message.senderId == _component.currentUserId;
              return _messageBubble(message, isMe);
            },
          ),
        ),
        _composer(),
      ],
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          'escribiendo...',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _messageBubble(ChatMessageModel message, bool isMe) {
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMe ? const Color(0xFFD8AC28) : const Color(0xFF0E1727);
    final textColor = isMe ? Colors.black : Colors.white;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) _avatarLeft(),
              if (!isMe) const SizedBox(width: 6),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: radius,
                    border: Border.all(
                      color: isMe
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isMe
                            ? const Color(0xFFD8AC28).withValues(alpha: 0.34)
                            : Colors.black.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Text(
                          '${_component.selectedContact?.nameUser ?? 'Usuario'} - ${_formatHour(message.createdAt)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (!isMe) const SizedBox(height: 8),
                      _messageContent(message, textColor),
                      if (isMe)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Tu - ${_formatHour(message.createdAt)} - ${_statusLabel(message.status)}',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 6),
              if (isMe) _avatarRight(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageContent(ChatMessageModel message, Color textColor) {
    final imageUrl = _resolveImageUrl(message);
    final videoUrl = _resolveVideoUrl(message);
    final videoThumbnailUrl = _resolveVideoThumbnailUrl(message);
    final normalizedType = message.messageType.trim().toLowerCase();
    final normalizedContentType = (message.mediaContentType ?? '').trim().toLowerCase();
    final hasMediaUrl = (message.mediaUrl ?? '').trim().isNotEmpty;
    final isVideo = normalizedType == 'video' ||
        normalizedContentType.startsWith('video/') ||
        videoUrl != null;
    final isImage = !isVideo &&
        (normalizedType == 'image' ||
            normalizedContentType.startsWith('image/') ||
            hasMediaUrl ||
            imageUrl != null);

    if (isVideo) {
      return _videoMessage(
        videoUrl ?? message.content,
        thumbnailUrl: videoThumbnailUrl,
      );
    }

    if (isImage) {
      final displayUrl = _fixLocalhostForAndroid(imageUrl ?? message.content);
      return GestureDetector(
        onTap: displayUrl.trim().isEmpty
            ? null
            : () => StoreFullscreenImages.open(context, urls: [displayUrl]),
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            displayUrl,
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 100,
              width: double.infinity,
              color: Colors.black26,
              alignment: Alignment.center,
              child: Text(
                'No se pudo cargar la imagen',
                style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 12),
              ),
            ),
          ),
        ),
      );
    }

    return Text(
      message.content,
      style: TextStyle(
        color: textColor,
        height: 1.35,
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _videoMessage(String videoUrl, {String? thumbnailUrl}) {
    final resolvedUrl = _fixLocalhostForAndroid(videoUrl);
    final resolvedThumbnailUrl = thumbnailUrl == null
        ? null
        : _fixLocalhostForAndroid(thumbnailUrl);

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => _ChatVideoPlayerPage(videoUrl: resolvedUrl),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: resolvedThumbnailUrl != null
                ? Image.network(
                    resolvedThumbnailUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => VideoThumbnail(
                      videoUrl: resolvedUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                : VideoThumbnail(
                    videoUrl: resolvedUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
          ),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.62),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveImageUrl(ChatMessageModel message) {
    final raw = _resolveMediaUrl(message.mediaUrl ?? message.content);
    if (raw.isEmpty) return null;
    final normalizedType = message.messageType.trim().toLowerCase();
    final normalizedContentType = (message.mediaContentType ?? '').trim().toLowerCase();
    final hasMediaUrl = (message.mediaUrl ?? '').trim().isNotEmpty;
    final shouldTreatAsImage = normalizedType == 'image' ||
        normalizedContentType.startsWith('image/') ||
        hasMediaUrl ||
        _looksLikeImagePath(raw);
    if (!shouldTreatAsImage) return null;

    return _fixLocalhostForAndroid(raw);
  }

  String? _resolveVideoUrl(ChatMessageModel message) {
    final payload = _parseLegacyMediaPayload(message.content);
    final raw = _resolveMediaUrl(
      message.mediaUrl ?? payload?['url']?.toString() ?? message.content,
    );
    if (raw.isEmpty) return null;
    final normalizedType = message.messageType.trim().toLowerCase();
    final normalizedContentType = (message.mediaContentType ?? '').trim().toLowerCase();
    final shouldTreatAsVideo = normalizedType == 'video' ||
        normalizedContentType.startsWith('video/') ||
        _looksLikeVideoPath(raw);
    if (!shouldTreatAsVideo) return null;

    return _fixLocalhostForAndroid(raw);
  }

  String? _resolveVideoThumbnailUrl(ChatMessageModel message) {
    final payload = _parseLegacyMediaPayload(message.content);
    final thumbnailRaw = _resolveMediaUrl(
      message.mediaThumbnailUrl ?? payload?['thumbnail_url']?.toString() ?? '',
    );
    if (thumbnailRaw.isEmpty) return null;
    if (!_looksLikeImagePath(thumbnailRaw)) return null;

    return _fixLocalhostForAndroid(thumbnailRaw);
  }

  String _resolveMediaUrl(String rawContent) {
    final raw = rawContent.trim();
    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    if (raw.startsWith('/')) {
      final base = EnvironmentDev.resolvedChatApiBaseUrl;
      return '$base$raw';
    }

    final base = EnvironmentDev.resolvedChatApiBaseUrl;
    return '$base/$raw';
  }

  Map<String, dynamic>? _parseLegacyMediaPayload(String rawContent) {
    final raw = rawContent.trim();
    if (raw.isEmpty || !raw.startsWith('{')) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  bool _looksLikeImagePath(String value) {
    final lower = value.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('.gif') ||
        lower.contains('/image') ||
        lower.contains('/images/');
  }

  bool _looksLikeVideoPath(String value) {
    final lower = value.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.webm') ||
        lower.contains('.mkv') ||
        lower.contains('/video') ||
        lower.contains('/videos/');
  }

  String _fixLocalhostForAndroid(String url) {
    if (kIsWeb) return url;
    if (defaultTargetPlatform != TargetPlatform.android) return url;

    return url
        .replaceFirst('://localhost', '://10.0.2.2')
        .replaceFirst('://127.0.0.1', '://10.0.2.2');
  }

  Widget _composer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isMediaUploading) _uploadProgressBar(),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _isMediaUploading ? null : _showAttachmentOptions,
                icon: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: _isMediaUploading
                      ? Colors.white.withValues(alpha: 0.28)
                      : VcomColors.oroLujoso,
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1627),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isMediaUploading,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!_isMediaUploading) _sendMessage();
                    },
                    onChanged: (value) {
                      if (_isMediaUploading) return;
                      if (value.trim().isEmpty) {
                        _component.emitTypingStop();
                      } else {
                        _component.emitTypingStart();
                      }
                    },
                    style: TextStyle(
                      color: _isMediaUploading
                          ? Colors.white.withValues(alpha: 0.45)
                          : Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          _isMediaUploading ? 'Subiendo archivo...' : 'Escribe un mensaje',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _isMediaUploading ? null : _sendMessage,
                icon: _isMediaUploading
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.black, size: 21),
                style: IconButton.styleFrom(
                  backgroundColor: _isMediaUploading
                      ? VcomColors.oroLujoso.withValues(alpha: 0.55)
                      : VcomColors.oroLujoso,
                  disabledBackgroundColor: VcomColors.oroLujoso.withValues(alpha: 0.55),
                  fixedSize: const Size(44, 44),
                  shape: const CircleBorder(),
                  shadowColor: VcomColors.oroLujoso.withValues(alpha: 0.35),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _uploadProgressBar() {
    final progress = _uploadProgress;
    final percentLabel = progress == null
        ? ''
        : ' ${(progress.clamp(0.0, 1.0) * 100).round()}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1424),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VcomColors.oroLujoso,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$_uploadStatusLabel$percentLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: progress == null
                ? const LinearProgressIndicator(
                    minHeight: 5,
                    backgroundColor: Color(0xFF1A2740),
                    color: VcomColors.oroLujoso,
                  )
                : LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: const Color(0xFF1A2740),
                    color: VcomColors.oroLujoso,
                  ),
          ),
        ],
      ),
    );
  }

  void _setUploadState({
    required bool active,
    double? progress,
    String label = '',
  }) {
    if (!mounted) return;
    setState(() {
      _isMediaUploading = active;
      _uploadProgress = active ? progress : null;
      if (label.isNotEmpty) {
        _uploadStatusLabel = label;
      } else if (!active) {
        _uploadStatusLabel = '';
      }
    });
  }

  void _onUploadProgress(String label, double progress) {
    _setUploadState(active: true, progress: progress, label: label);
  }

  Future<void> _uploadImage({bool fromCamera = false}) async {
    if (_isMediaUploading) return;

    try {
      final conversationId = _component.selectedConversation?.idConversation;
      if (conversationId == null || conversationId <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abre una conversación antes de enviar')),
        );
        return;
      }

      _setUploadState(
        active: true,
        progress: null,
        label: 'Preparando imagen...',
      );

      final uploader = MediaUploadService();
      final url = await uploader.selectAndUploadImage(
        fromCamera: fromCamera,
        conversationId: conversationId,
        onProgress: (progress) => _onUploadProgress('Subiendo imagen...', progress),
      );
      if (url == null || url.trim().isEmpty) return;

      _setUploadState(active: true, progress: 1, label: 'Enviando imagen...');

      final sent = await _component.sendImageUrl(url);
      if (!sent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _component.error ?? 'No se pudo enviar la imagen',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir imagen: $e')),
      );
    } finally {
      _setUploadState(active: false);
    }
  }

  Future<void> _uploadVideo({bool fromCamera = false}) async {
    if (_isMediaUploading) return;

    try {
      final conversationId = _component.selectedConversation?.idConversation;
      if (conversationId == null || conversationId <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abre una conversación antes de enviar')),
        );
        return;
      }

      _setUploadState(
        active: true,
        progress: null,
        label: 'Preparando video...',
      );

      final uploader = MediaUploadService();
      final upload = await uploader.selectAndUploadVideo(
        fromCamera: fromCamera,
        conversationId: conversationId,
        onProgress: (progress) => _onUploadProgress('Subiendo video...', progress),
      );
      if (upload == null) return;

      _setUploadState(active: true, progress: 1, label: 'Enviando video...');

      final sent = await _component.sendVideo(
        videoUrl: upload.url,
        thumbnailUrl: upload.thumbnailUrl,
        contentType: upload.contentType,
        metadata: {
          if ((upload.thumbnailUrl ?? '').trim().isNotEmpty)
            'thumbnail_url': upload.thumbnailUrl,
        },
      );
      if (!sent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _component.error ?? 'No se pudo enviar el video',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir video: $e')),
      );
    } finally {
      _setUploadState(active: false);
    }
  }

  Future<void> _showAttachmentOptions() async {
    if (_isMediaUploading) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E1727),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                _attachmentTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Imagen desde galeria',
                  onTap: () {
                    Navigator.of(context).pop();
                    _uploadImage();
                  },
                ),
                if (!kIsWeb)
                  _attachmentTile(
                    icon: Icons.photo_camera_outlined,
                    title: 'Imagen desde camara',
                    onTap: () {
                      Navigator.of(context).pop();
                      _uploadImage(fromCamera: true);
                    },
                  ),
                _attachmentTile(
                  icon: Icons.video_library_outlined,
                  title: 'Video desde galeria',
                  onTap: () {
                    Navigator.of(context).pop();
                    _uploadVideo();
                  },
                ),
                if (!kIsWeb)
                  _attachmentTile(
                    icon: Icons.videocam_outlined,
                    title: 'Video desde camara',
                    onTap: () {
                      Navigator.of(context).pop();
                      _uploadVideo(fromCamera: true);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachmentTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: Colors.white.withValues(alpha: 0.04),
        leading: Icon(icon, color: VcomColors.oroLujoso),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_isMediaUploading) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _component.emitTypingStop();
    _component.sendText(text);
    _messageController.clear();
  }

  String _formatHour(DateTime value) => DateFormat('h:mm a').format(value);

  String _statusLabel(String status) {
    switch (status) {
      case 'seen':
        return 'visto';
      case 'received':
        return 'recibido';
      case 'unseen':
      default:
        return 'no visto';
    }
  }

  Widget _avatarLeft() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: const Color(0xFF20324D),
        child: Text(
          (_component.selectedContact?.nameUser.isNotEmpty ?? false)
              ? _component.selectedContact!.nameUser[0].toUpperCase()
              : 'U',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _avatarRight() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: const Color(0xFF7B5F12),
        child: Text(
          (_component.currentUserName.isNotEmpty)
              ? _component.currentUserName[0].toUpperCase()
              : 'T',
          style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x3A111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
      ),
    );
  }
}

class _ChatVideoPlayerPage extends StatefulWidget {
  final String videoUrl;

  const _ChatVideoPlayerPage({required this.videoUrl});

  @override
  State<_ChatVideoPlayerPage> createState() => _ChatVideoPlayerPageState();
}

class _ChatVideoPlayerPageState extends State<_ChatVideoPlayerPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _controller = controller;
    controller.addListener(_onVideoTick);

    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (!mounted || _controller != controller) {
        controller.removeListener(_onVideoTick);
        await controller.dispose();
        return;
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (_) {
      controller.removeListener(_onVideoTick);
      await controller.dispose();
      if (!mounted) return;
      if (_controller == controller) _controller = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo reproducir el video')),
      );
      Navigator.of(context).maybePop();
    }
  }

  void _onVideoTick() {
    if (mounted) setState(() {});
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    setState(() {});
  }

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    c?.removeListener(_onVideoTick);
    c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: !_isInitialized || controller == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: VcomColors.oroLujoso,
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final ar = controller.value.aspectRatio > 0 &&
                              controller.value.aspectRatio.isFinite
                          ? controller.value.aspectRatio
                          : 16 / 9;
                      var w = constraints.maxWidth;
                      var h = w / ar;
                      if (h > constraints.maxHeight) {
                        h = constraints.maxHeight;
                        w = h * ar;
                      }
                      return Center(
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: VideoPlayer(controller),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isInitialized && controller != null)
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _togglePlay,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: Colors.white.withValues(alpha: 0.92),
                      size: 72,
                      shadows: const [
                        Shadow(blurRadius: 18, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
