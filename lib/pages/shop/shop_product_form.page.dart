import 'dart:io';
import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/pages/shop/shop.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class ShopProductFormPage extends StatefulWidget {
  final ShopComponent component;
  final ProductModel? initialProduct;

  const ShopProductFormPage({
    super.key,
    required this.component,
    this.initialProduct,
  });

  @override
  State<ShopProductFormPage> createState() => _ShopProductFormPageState();
}

class _ShopProductFormPageState extends State<ShopProductFormPage> {
  static const int _maxImages = 5;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  int? _selectedCategoryId;
  bool _saving = false;
  List<File> _newImages = [];

  bool get _isEdit => widget.initialProduct != null;
  int get _existingImagesCount => widget.initialProduct?.images.length ?? 0;
  int get _remainingSlots => _maxImages - _existingImagesCount - _newImages.length;

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    if (product != null) {
      _nameCtrl.text = product.nameProduct;
      _descCtrl.text = product.descriptionProduct ?? '';
      _priceCtrl.text = product.priceCop.toStringAsFixed(0);
      _selectedCategoryId = product.category?.idCategory ?? product.brand?.idCategory;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    if (_remainingSlots <= 0) {
      _showError('Solo se permiten hasta $_maxImages imagenes en total');
      return;
    }

    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2200,
      maxHeight: 2200,
    );

    if (file == null) return;

    setState(() {
      _newImages = [..._newImages, File(file.path)];
    });
  }

  Future<void> _showImageSourcePicker() async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1628),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: VcomColors.oroLujoso),
                title: const Text(
                  'Galeria',
                  style: TextStyle(color: VcomColors.blancoCrema),
                ),
                onTap: () => Navigator.of(context).pop(false),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: VcomColors.oroLujoso),
                title: const Text(
                  'Camara',
                  style: TextStyle(color: VcomColors.blancoCrema),
                ),
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );

    if (fromCamera == null) return;
    await _pickImage(fromCamera: fromCamera);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showError('Selecciona una categoria');
      return;
    }

    setState(() => _saving = true);

    try {
      final price = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0;

      if (_isEdit) {
        await widget.component.updateProductFromCategory(
          idProduct: widget.initialProduct!.idProduct!,
          idCategory: _selectedCategoryId!,
          nameProduct: _nameCtrl.text,
          descriptionProduct: _descCtrl.text,
          priceCop: price,
          newImages: _newImages,
        );
      } else {
        await widget.component.createProductFromCategory(
          idCategory: _selectedCategoryId!,
          nameProduct: _nameCtrl.text,
          descriptionProduct: _descCtrl.text,
          priceCop: price,
          images: _newImages,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.component.categories;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: ModeloNavbar(
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pop(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.8),
            radius: 1.3,
            colors: [
              Color(0xFF273C67),
              Color(0xFF1a2847),
              Color(0xFF0d1525),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    children: [
                      Text(
                        _isEdit ? 'Editar articulo' : 'Nuevo articulo',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: VcomColors.blancoCrema,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildField(
                        controller: _nameCtrl,
                        label: 'Nombre del articulo',
                        hint: 'Escribe aqui el titulo',
                        icon: Icons.inventory_2_outlined,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingresa el nombre del articulo' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildCategorySelector(categories),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _priceCtrl,
                        label: 'Valor',
                        hint: 'Valor',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = double.tryParse((v ?? '').replaceAll(',', ''));
                          if (n == null || n <= 0) return 'Precio invalido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _descCtrl,
                        label: 'Descripcion',
                        hint: 'Describe el articulo',
                        icon: Icons.edit_note_outlined,
                        minLines: 4,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 10),
                      _buildImagePicker(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VcomColors.oroLujoso,
                        foregroundColor: VcomColors.azulMedianocheTexto,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _saving ? 'Guardando...' : 'Publicar articulo',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(List categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.grid_view_outlined,
              size: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              'ID_CATEGORY',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 8,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _glassCard(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedCategoryId,
              dropdownColor: const Color(0xFF0E1628),
              isExpanded: true,
              hint: Text(
                'Selecciona categoria',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
              style: const TextStyle(
                color: VcomColors.blancoCrema,
                fontSize: 12,
              ),
              iconEnabledColor: VcomColors.oroLujoso,
              items: categories
                  .map<DropdownMenuItem<int>>(
                    (c) => DropdownMenuItem<int>(
                      value: c.idCategory as int,
                      child: Text('${c.idCategory} - ${c.nameCategory}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategoryId = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IMAGENES',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 8,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showImageSourcePicker,
          borderRadius: BorderRadius.circular(7),
          child: DottedBorder(
            color: Colors.grey,
            strokeWidth: 1.5,
            dashPattern: const [6, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(7),
            padding: EdgeInsets.zero,
            child: _glassCard(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      color: Color.fromARGB(120, 255, 254, 250),
                      size: 15,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AGREGAR IMAGEN (${_newImages.length}/$_maxImages)',
                      style: const TextStyle(
                        color: Color.fromARGB(120, 255, 254, 250),
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_existingImagesCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Imagenes actuales: $_existingImagesCount',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
          ),
        ],
        if (_newImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _newImages.length; i++)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _newImages[i],
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: () => setState(() => _newImages.removeAt(i)),
                        child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.black87,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String? value)? validator,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 8,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: VcomColors.blancoCrema,
            fontSize: 12,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 2, left: 0, right: 0, bottom: 0),
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: VcomColors.oroLujoso,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0xFF23314A).withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
