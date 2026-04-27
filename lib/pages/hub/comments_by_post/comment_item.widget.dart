import 'package:flutter/material.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'package:vcom_app/pages/hub/hub.component.dart';
import 'package:vcom_app/pages/hub/hub_constants.dart';
import 'package:vcom_app/pages/hub/hub_helpers.dart';
import 'package:vcom_app/pages/hub/widgets/comment_reaction_selector.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Widget para un solo comentario con su selector de reacción.
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

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _authorRow(authorName),
              const SizedBox(height: 6),
              _contentText(content),
              const SizedBox(height: 8),
              _reactionRow(context, canReact, commentId,
                  myReaction, isReacting),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authorRow(String name) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: VcomColors.oroLujoso,
          child: const Icon(
            Icons.person,
            size: 14,
            color: VcomColors.azulMedianocheTexto,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Autor: $name',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _contentText(String content) {
    return Text(
      content,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.92),
        fontSize: 15,
        height: 1.3,
      ),
    );
  }

  Widget _reactionRow(
    BuildContext context,
    bool canReact,
    dynamic commentId,
    String? myReaction,
    bool isReacting,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CommentReactionSelector(
          key: ValueKey('comment-reaction-$postId-$commentId'),
          reactionsCount: comment.reactionsCount,
          selectedReactionType: myReaction,
          isSubmitting: !canReact || isReacting,
          reactionOptions: HubConstants.reactionOptions,
          onReactionSelected: (type) async {
            if (!canReact) return false;
            return component.reactToComment(postId, commentId, type);
          },
        ),
        if (!canReact)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              'Sin id de comentario',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }

  static dynamic _resolveId(dynamic comment) {
    final direct = comment.id;
    if (direct is int && direct > 0) return direct;
    if (direct != null) {
      final raw = direct.toString().trim();
      if (raw.isNotEmpty) {
        return int.tryParse(raw) ?? raw;
      }
    }
    final apiKey = comment.apiKey;
    if (apiKey != null) {
      final raw = apiKey.toString().trim();
      if (raw.isNotEmpty) {
        return int.tryParse(raw) ?? raw;
      }
    }
    return null;
  }
}
