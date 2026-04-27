import 'package:flutter/material.dart';
import 'package:vcom_app/pages/hub/comments_by_post/comment_item.widget.dart';
import 'package:vcom_app/pages/hub/comments_by_post/add_comment_row.widget.dart';
import 'package:vcom_app/pages/hub/hub.component.dart';

/// Bottom sheet de comentarios de un post.
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
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return AnimatedBuilder(
          animation: component,
          builder: (_, _) {
            final comments = component.commentsByPost[postId] ?? const [];
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dragHandle(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AddCommentRow(postId: postId, component: component),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: comments.length,
                      itemBuilder: (_, index) {
                        return CommentItemWidget(
                          postId: postId,
                          comment: comments[index],
                          component: component,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _dragHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
