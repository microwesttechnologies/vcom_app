import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class CommentReactionSelector extends StatefulWidget {
  const CommentReactionSelector({
    required this.reactionsCount,
    required this.reactionOptions,
    required this.onReactionSelected,
    this.selectedReactionType,
    this.isSubmitting = false,
    super.key,
  });

  final int reactionsCount;
  final List<List<String>> reactionOptions;
  final Future<bool> Function(String type) onReactionSelected;
  final String? selectedReactionType;
  final bool isSubmitting;

  @override
  State<CommentReactionSelector> createState() => _CommentReactionSelectorState();
}

class _CommentReactionSelectorState extends State<CommentReactionSelector> {
  bool _isPickerOpen = false;

  @override
  Widget build(BuildContext context) {
    final selectedEmoji = widget.reactionOptions
        .where((pair) => pair.length >= 2 && pair[1] == widget.selectedReactionType)
        .map((pair) => pair[0])
        .cast<String?>()
        .firstWhere((value) => value != null, orElse: () => null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.isSubmitting
              ? null
              : () {
                  setState(() {
                    _isPickerOpen = !_isPickerOpen;
                  });
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedEmoji == null)
                  Icon(
                    Icons.favorite_border,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.72),
                  )
                else
                  Text(selectedEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${widget.reactionsCount}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isPickerOpen) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final pair in widget.reactionOptions)
                if (pair.length >= 2)
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: widget.isSubmitting
                        ? null
                        : () async {
                            setState(() {
                              _isPickerOpen = false;
                            });
                            await widget.onReactionSelected(pair[1]);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: widget.selectedReactionType == pair[1]
                            ? VcomColors.oroLujoso.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.selectedReactionType == pair[1]
                              ? VcomColors.oroLujoso
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(pair[0], style: const TextStyle(fontSize: 14)),
                    ),
                  ),
            ],
          ),
        ],
      ],
    );
  }
}
