import 'package:flutter/material.dart';
import 'package:vcom_app/core/models/brand.model.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class BrandCardItem extends StatelessWidget {
  final BrandModel brand;
  final String categoryName;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BrandCardItem({
    super.key,
    required this.brand,
    required this.categoryName,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: VcomColors.azulZafiroProfundo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: VcomColors.oroLujoso.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(),
            if (brand.descriptionBrand != null) ...[
              const SizedBox(height: 8),
              Text(
                brand.descriptionBrand!,
                style: TextStyle(
                  color: VcomColors.blancoCrema.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _buildMetadata(),
            const SizedBox(height: 8),
            _buildStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            brand.nameBrand,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: VcomColors.blancoCrema,
            ),
          ),
        ),
        if (canEdit)
          IconButton(
            icon: const Icon(Icons.edit, color: VcomColors.oroLujoso, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onEdit,
          ),
        if (canEdit && canDelete) const SizedBox(width: 8),
        if (canDelete)
          IconButton(
            icon: const Icon(Icons.delete, color: VcomColors.error, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDelete,
          ),
      ],
    );
  }

  Widget _buildMetadata() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          label: Text(categoryName, style: const TextStyle(fontSize: 12)),
          backgroundColor: VcomColors.azulOverlayTransparente60,
          labelStyle: const TextStyle(color: VcomColors.blancoCrema),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        if (brand.website != null)
          Chip(
            label: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, size: 14),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Website',
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: VcomColors.oroLujoso.withValues(alpha: 0.2),
            labelStyle: const TextStyle(color: VcomColors.oroBrillante),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
      ],
    );
  }

  Widget _buildStatus() {
    final stateColor = brand.stateBrand ? VcomColors.success : VcomColors.error;
    final stateLabel = brand.stateBrand ? 'Activo' : 'Inactivo';

    return Row(
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: stateColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            stateLabel,
            style: TextStyle(fontSize: 12, color: stateColor),
          ),
        ),
      ],
    );
  }
}
