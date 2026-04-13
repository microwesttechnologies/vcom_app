import 'package:flutter/material.dart';
import 'package:vcom_app/components/commons/button.dart';
import 'package:vcom_app/core/models/brand.model.dart';
import 'package:vcom_app/core/models/category.model.dart';
import 'package:vcom_app/pages/brands/managerBrand.component.dart';
import 'package:vcom_app/pages/brands/widgets/brand_card_item.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class BrandListContent extends StatelessWidget {
  final ManagerBrandComponent component;
  final ValueChanged<BrandModel> onEdit;
  final ValueChanged<BrandModel> onDelete;
  final VoidCallback onRetry;

  const BrandListContent({
    super.key,
    required this.component,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (component.isLoading && component.brands.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }

    if (component.error != null && component.brands.isEmpty) {
      return _ErrorState(message: component.error!, onRetry: onRetry);
    }

    if (component.brands.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(totalBrands: component.brands.length),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: component.brands.length,
            itemBuilder: (context, index) {
              final brand = component.brands[index];
              final categoryName = _resolveCategoryName(
                categories: component.categories,
                categoryId: brand.idCategory,
              );

              return BrandCardItem(
                brand: brand,
                categoryName: categoryName,
                canEdit: component.canUpdateBrands,
                canDelete: component.canDeleteBrands,
                onEdit: () => onEdit(brand),
                onDelete: () => onDelete(brand),
              );
            },
          ),
        ),
      ],
    );
  }

  String _resolveCategoryName({
    required List<CategoryModel> categories,
    required int categoryId,
  }) {
    final category = categories.cast<CategoryModel?>().firstWhere(
      (item) => item?.idCategory == categoryId,
      orElse: () => null,
    );
    return category?.nameCategory ?? 'N/A';
  }
}

class _Header extends StatelessWidget {
  final int totalBrands;

  const _Header({required this.totalBrands});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Gestión de Marcas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: VcomColors.blancoCrema,
          ),
        ),
        Text(
          '$totalBrands marcas',
          style: TextStyle(
            fontSize: 14,
            color: VcomColors.blancoCrema.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: VcomColors.error),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar marcas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: VcomColors.blancoCrema,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: VcomColors.blancoCrema.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ButtonComponent(
            label: 'Reintentar',
            size: ButtonSize.medium,
            color: VcomColors.oroLujoso,
            textColor: VcomColors.azulMedianocheTexto,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.branding_watermark_outlined,
            size: 64,
            color: VcomColors.oroLujoso,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay marcas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: VcomColors.blancoCrema,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera marca',
            style: TextStyle(
              fontSize: 14,
              color: VcomColors.blancoCrema.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
