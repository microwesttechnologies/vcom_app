import 'package:flutter/material.dart';
import 'package:vcom_app/components/commons/button.dart';
import 'package:vcom_app/core/models/brand.model.dart';
import 'package:vcom_app/core/models/category.model.dart';
import 'package:vcom_app/pages/brands/widgets/brand_form_fields.dart';
import 'package:vcom_app/style/vcom_colors.dart';

enum BrandFormResult { created, updated }

class BrandFormSheet extends StatefulWidget {
  final BrandModel? initialBrand;
  final List<CategoryModel> categories;
  final Future<void> Function(BrandModel brand, bool isEditing) onSave;

  const BrandFormSheet({
    super.key,
    required this.initialBrand,
    required this.categories,
    required this.onSave,
  });

  @override
  State<BrandFormSheet> createState() => _BrandFormSheetState();
}

class _BrandFormSheetState extends State<BrandFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoController = TextEditingController();
  final _websiteController = TextEditingController();

  int? _selectedCategoryId;
  bool _stateBrand = true;
  bool _saving = false;

  bool get _isEditing => widget.initialBrand != null;

  @override
  void initState() {
    super.initState();
    final brand = widget.initialBrand;
    if (brand == null) return;

    _nameController.text = brand.nameBrand;
    _descriptionController.text = brand.descriptionBrand ?? '';
    _logoController.text = brand.logo ?? '';
    _websiteController.text = brand.website ?? '';
    _selectedCategoryId = brand.idCategory;
    _stateBrand = brand.stateBrand;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _logoController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final categoryId = _selectedCategoryId;
    if (categoryId == null) {
      _showError('Por favor seleccione una categoría');
      return;
    }

    setState(() => _saving = true);

    final brand = BrandModel(
      idBrand: widget.initialBrand?.idBrand ?? 0,
      idCategory: categoryId,
      nameBrand: _nameController.text.trim(),
      descriptionBrand: _optionalTrimmed(_descriptionController.text),
      logo: _optionalTrimmed(_logoController.text),
      website: _optionalTrimmed(_websiteController.text),
      stateBrand: _stateBrand,
    );

    try {
      await widget.onSave(brand, _isEditing);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(_isEditing ? BrandFormResult.updated : BrandFormResult.created);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _optionalTrimmed(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: VcomColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: VcomColors.azulZafiroProfundo,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BrandFormFields(
                      saving: _saving,
                      categories: widget.categories,
                      selectedCategoryId: _selectedCategoryId,
                      onCategoryChanged: (value) =>
                          setState(() => _selectedCategoryId = value),
                      nameController: _nameController,
                      descriptionController: _descriptionController,
                      logoController: _logoController,
                      websiteController: _websiteController,
                      stateBrand: _stateBrand,
                      onStateChanged: (value) =>
                          setState(() => _stateBrand = value),
                      isValidUrl: _isValidUrl,
                    ),
                    const SizedBox(height: 32),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: VcomColors.oroLujoso.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isEditing ? 'Editar Marca' : 'Nueva Marca',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: VcomColors.blancoCrema,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: VcomColors.blancoCrema),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ButtonComponent(
            label: 'Cancelar',
            size: ButtonSize.large,
            color: VcomColors.azulOverlayTransparente70,
            textColor: VcomColors.blancoCrema,
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ButtonComponent(
            label: _saving
                ? (_isEditing ? 'Actualizando...' : 'Creando...')
                : (_isEditing ? 'Actualizar' : 'Crear'),
            size: ButtonSize.large,
            color: VcomColors.oroLujoso,
            textColor: VcomColors.azulMedianocheTexto,
            onPressed: _saving ? null : _submit,
          ),
        ),
      ],
    );
  }
}
