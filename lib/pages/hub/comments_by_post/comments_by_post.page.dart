import 'package:flutter/material.dart';
import 'package:vcom_app/pages/hub/comments_by_post/comment_item.widget.dart';
import 'package:vcom_app/pages/hub/comments_by_post/add_comment_row.widget.dart';
import 'package:vcom_app/pages/hub/hub.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Bottom sheet de comentarios estilo Facebook.
class CommentsSheet extends StatelessWidget {
  const CommentsSheet({
    required this.postId,
    required this.component,
    super.key,
  });

  final int postId;
  final HubComponent component;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return AnimatedBuilder(
          animation: component,
          builder: (_, _) {
            final comments = component.commentsByPost[postId] ?? const [];
            return Container(
              decoration: const BoxDecoration(
                color: VcomColors.azulZafiroProfundo,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    _header(comments.length),
                    const Divider(height: 1, color: Color(0xFF1A2740)),
                    Expanded(
                      child: comments.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              itemCount: comments.length,
                              itemBuilder: (_, i) {
                                return CommentItemWidget(
                                  postId: postId,
                                  comment: comments[i],
                                  component: component,
                                );
                              },
                            ),
                    ),
                    const Divider(height: 1, color: Color(0xFF1A2740)),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: AddCommentRow(
                          postId: postId,
                          component: component,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _header(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Comentarios${count > 0 ? ' ($count)' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'Sé el primero en comentar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
