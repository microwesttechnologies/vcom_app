import 'package:flutter/material.dart';
import 'package:vcom_app/components/commons/check.component.dart';
import 'package:vcom_app/components/commons/label.component.dart';
import 'package:vcom_app/core/models/category.model.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class BrandFormFields extends StatelessWidget {
  final bool saving;
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategoryChanged;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController logoController;
  final TextEditingController websiteController;
  final bool stateBrand;
  final ValueChanged<bool> onStateChanged;
  final bool Function(String url) isValidUrl;

  const BrandFormFields({
    super.key,
    required this.saving,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.nameController,
    required this.descriptionController,
    required this.logoController,
    required this.websiteController,
    required this.stateBrand,
    required this.onStateChanged,
    required this.isValidUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCategoryField(),
        const SizedBox(height: 20),
        _buildNameField(),
        const SizedBox(height: 20),
        _buildDescriptionField(),
        const SizedBox(height: 20),
        _buildLogoField(),
        const SizedBox(height: 20),
        _buildWebsiteField(),
        const SizedBox(height: 20),
        _buildStateField(),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: VcomColors.blancoCrema.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: VcomColors.azulOverlayTransparente60,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: VcomColors.oroLujoso.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: VcomColors.oroLujoso.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: VcomColors.oroBrillante, width: 2),
      ),
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LabelComponent(
          label: 'Categoría *',
          size: LabelSize.medium,
          fontWeight: FontWeight.w600,
          color: VcomColors.oroBrillante,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: selectedCategoryId,
          decoration: _inputDecoration(hintText: 'Seleccione una categoría'),
          dropdownColor: VcomColors.azulZafiroProfundo,
          style: const TextStyle(color: VcomColors.blancoCrema),
          items: categories
              .map(
                (category) => DropdownMenuItem<int>(
                  value: category.idCategory,
                  child: Text(category.nameCategory),
                ),
              )
              .toList(),
          onChanged: saving ? null : onCategoryChanged,
          validator: (value) =>
              value == null ? 'Seleccione una categoría' : null,
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return _buildTextField(
      label: 'Nombre de la Marca *',
      hintText: 'Ingrese el nombre de la marca',
      controller: nameController,
      validator: (value) =>
          value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
    );
  }

  Widget _buildDescriptionField() {
    return _buildTextField(
      label: 'Descripción',
      hintText: 'Ingrese la descripción de la marca',
      controller: descriptionController,
      maxLines: 3,
    );
  }

  Widget _buildLogoField() {
    return _buildTextField(
      label: 'Logo (URL)',
      hintText: 'https://example.com/logo.png',
      controller: logoController,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        if (isValidUrl(value)) return null;
        return 'Ingrese una URL válida (http:// o https://)';
      },
    );
  }

  Widget _buildWebsiteField() {
    return _buildTextField(
      label: 'Sitio Web (URL)',
      hintText: 'https://example.com',
      controller: websiteController,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        if (isValidUrl(value)) return null;
        return 'Ingrese una URL válida (http:// o https://)';
      },
    );
  }

  Widget _buildStateField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: VcomColors.azulOverlayTransparente60,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CheckComponent(
        label: 'Marca activa',
        color: VcomColors.oroLujoso,
        textColor: VcomColors.blancoCrema,
        isChecked: stateBrand,
        isDisabled: saving,
        onChanged: onStateChanged,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabelComponent(
          label: label,
          size: LabelSize.medium,
          fontWeight: FontWeight.w600,
          color: VcomColors.oroBrillante,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !saving,
          maxLines: maxLines,
          style: const TextStyle(color: VcomColors.blancoCrema),
          decoration: _inputDecoration(hintText: hintText),
          validator: validator,
        ),
      ],
    );
  }
}
