import 'package:flutter/material.dart';
import 'package:vcom_app/pages/hub/hub_constants.dart';
import 'package:vcom_app/pages/hub/widgets/comment_reaction_selector.dart';

/// Widget envoltorio para reaccionar a un comentario individual.
class CommentReactionWidget extends StatelessWidget {
  const CommentReactionWidget({
    required this.reactionsCount,
    required this.selectedReactionType,
    required this.isSubmitting,
    required this.onReactionSelected,
    super.key,
  });

  final int reactionsCount;
  final String? selectedReactionType;
  final bool isSubmitting;
  final Future<bool> Function(String type) onReactionSelected;

  @override
  Widget build(BuildContext context) {
    return CommentReactionSelector(
      reactionsCount: reactionsCount,
      selectedReactionType: selectedReactionType,
      isSubmitting: isSubmitting,
      reactionOptions: HubConstants.reactionOptions,
      onReactionSelected: onReactionSelected,
    );
  }
}
