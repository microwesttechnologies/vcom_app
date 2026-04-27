import 'package:flutter/material.dart';
import 'package:vcom_app/core/hub/hub_tags.service.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Fila horizontal de chips para filtrar por tag.
class TagsChipsRow extends StatelessWidget {
  const TagsChipsRow({
    required this.tags,
    required this.selectedTag,
    required this.onSelected,
    super.key,
  });

  final List<HubTag> tags;
  final HubTag? selectedTag;
  final ValueChanged<HubTag?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(
                  label: 'Todos los Artículos',
                  isSelected: selectedTag == null,
                  onTap: () => onSelected(null),
                ),
                for (final t in tags)
                  _chip(
                    label: t.name,
                    isSelected: selectedTag?.id == t.id,
                    onTap: () => onSelected(t),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (_) => onTap(),
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected
              ? VcomColors.azulMedianocheTexto
              : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        selectedColor: VcomColors.oroLujoso,
        backgroundColor: const Color(0xFF1A2740),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
