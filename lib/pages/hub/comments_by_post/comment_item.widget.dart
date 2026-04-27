import 'package:flutter/material.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'package:vcom_app/pages/hub/hub.component.dart';
import 'package:vcom_app/pages/hub/hub_constants.dart';
import 'package:vcom_app/pages/hub/hub_helpers.dart';
import 'package:vcom_app/pages/hub/widgets/comment_reaction_selector.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Widget estilo Facebook para un comentario individual.
class CommentItemWidget extends StatelessWidget {
  const CommentItemWidget({
    required this.postId,
    required this.comment,
    required this.component,
    super.key,
  });

  final int postId;
  final dynamic comment;
  final HubComponent component;

  @override
  Widget build(BuildContext context) {
    final commentId = _resolveId(comment);
    final canReact = commentId != null;
    final myReaction = canReact
        ? component.myCommentReaction(postId, commentId)
        : null;
    final isReacting = canReact
        ? component.isCommentReactionInFlight(postId, commentId)
        : false;
    final authorName = resolveCommentAuthorName(
      comment,
      TokenService(),
      UserStatusService(),
    );
    final content = (comment.content ?? '').toString();
    final timeAgo = relativeTime((comment.createdAt ?? '').toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(authorName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bubble(authorName, content),
                const SizedBox(height: 4),
                _metaRow(timeAgo, canReact, commentId, myReaction, isReacting),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name) {
    final initials = _initials(name);
    return CircleAvatar(
      radius: 18,
      backgroundColor: VcomColors.oroLujoso,
      child: Text(
        initials,
        style: const TextStyle(
          color: VcomColors.azulMedianocheTexto,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _bubble(String author, String content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VcomColors.azulOverlayTransparente70,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            author,
            style: const TextStyle(
              color: VcomColors.oroLujoso,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(
    String timeAgo,
    bool canReact,
    dynamic commentId,
    String? myReaction,
    bool isReacting,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Text(
            timeAgo,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          CommentReactionSelector(
            key: ValueKey('cr-$postId-$commentId'),
            reactionsCount: comment.reactionsCount,
            selectedReactionType: myReaction,
            isSubmitting: !canReact || isReacting,
            reactionOptions: HubConstants.reactionOptions,
            onReactionSelected: (type) async {
              if (!canReact) return false;
              return component.reactToComment(postId, commentId, type);
            },
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static dynamic _resolveId(dynamic comment) {
    final direct = comment.id;
    if (direct is int && direct > 0) return direct;
    if (direct != null) {
      final raw = direct.toString().trim();
      if (raw.isNotEmpty) return int.tryParse(raw) ?? raw;
    }
    final apiKey = comment.apiKey;
    if (apiKey != null) {
      final raw = apiKey.toString().trim();
      if (raw.isNotEmpty) return int.tryParse(raw) ?? raw;
    }
    return null;
  }
}
