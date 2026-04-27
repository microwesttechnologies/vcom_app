import 'package:flutter/material.dart';
import 'package:vcom_app/pages/hub/hub_constants.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Fila expandible de emojis para reaccionar a un post.
class PostReactionRow extends StatelessWidget {
  const PostReactionRow({
    required this.postId,
    required this.currentReaction,
    required this.isInFlight,
    required this.onReact,
    super.key,
  });

  final int postId;
  final String? currentReaction;
  final bool isInFlight;
  final Future<bool> Function(String type) onReact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final r in HubConstants.reactionOptions)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isInFlight
                  ? null
                  : () async {
                      final ok = await onReact(r[1]);
                      if (!context.mounted || ok) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo reaccionar'),
                        ),
                      );
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: currentReaction == r[1]
                      ? VcomColors.oroLujoso.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: currentReaction == r[1]
                        ? VcomColors.oroLujoso.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(r[0], style: const TextStyle(fontSize: 14)),
              ),
            ),
          ),
      ],
    );
  }
}
