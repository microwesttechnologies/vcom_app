import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vcom_app/components/commons/button.dart';
import 'package:vcom_app/components/commons/label.component.dart';
import 'package:vcom_app/pages/products/create/createProduct.component.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página para crear productos
class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  late CreateProductComponent _createProductComponent;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  int? _selectedCategoryId;
  int? _selectedBrandId;
  bool _stateProduct = true;
  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _createProductComponent = CreateProductComponent();
    _createProductComponent.addListener(_onComponentChanged);
    _createProductComponent.initialize();
  }

  @override
  void dispose() {
    _createProductComponent.removeListener(_onComponentChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _onComponentChanged() {
    setState(() {});
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBrandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione una marca'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final List<ProductImageModel> productImages = [];

      final product = ProductModel(
        idBrand: _selectedBrandId!,
        nameProduct: _nameController.text.trim(),
        descriptionProduct: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        sku: _skuController.text.trim().isEmpty 
            ? null 
            : _skuController.text.trim(),
        priceCop: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        stateProduct: _stateProduct,
        images: productImages,
      );

      await _createProductComponent.createProduct(product, images: _selectedImages);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Mostrar modal de error en lugar de SnackBar para errores de imágenes
        _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: VcomColors.azulZafiroProfundo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: VcomColors.oroLujoso.withValues(alpha: 0.3)),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Error al crear producto',
                style: TextStyle(
                  color: VcomColors.blancoCrema,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
            child: SingleChildScrollView(
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: VcomColors.blancoCrema.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: VcomColors.oroLujoso,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Producto'),
        backgroundColor: VcomColors.azulZafiroProfundo,
        foregroundColor: VcomColors.blancoCrema,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: VcomColors.gradienteNocturno,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Categoría
                  LabelComponent(
                    label: 'Categoría *',
                    size: LabelSize.medium,
                    fontWeight: FontWeight.w600,
                    color: VcomColors.oroBrillante,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    decoration: InputDecoration(
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
                        borderSide: BorderSide(
                          color: VcomColors.oroBrillante,
                          width: 2,
                        ),
                      ),
                    ),
                    dropdownColor: VcomColors.azulZafiroProfundo,
                    style: TextStyle(color: VcomColors.blancoCrema),
                    items: _createProductComponent.categories
                        .map((category) => DropdownMenuItem<int>(
                              value: category.idCategory,
                              child: Text(category.nameCategory),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedCategoryId = value;
                        _selectedBrandId = null;
                      });
                      
                      if (value != null) {
                        try {
                          await _createProductComponent.fetchBrandsByCategory(value);
                        } catch (e) {
                          // Error manejado por el componente
                        }
                      } else {
                        _createProductComponent.clearCategorySelection();
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Seleccione una categoría' : null,
                  ),
                  const SizedBox(height: 20),
                  // Marca
                  LabelComponent(
                    label: 'Marca *',
                    size: LabelSize.medium,
                    fontWeight: FontWeight.w600,
                    color: VcomColors.oroBrillante,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedBrandId,
                    decoration: InputDecoration(
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
                        borderSide: BorderSide(
                          color: VcomColors.oroBrillante,
                          width: 2,
                        ),
                      ),
                    ),
                    dropdownColor: VcomColors.azulZafiroProfundo,
                    style: TextStyle(color: VcomColors.blancoCrema),
                    items: _createProductComponent.brands
                        .map((brand) => DropdownMenuItem<int>(
                              value: brand.idBrand,
                              child: Text(brand.nameBrand),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedBrandId = value),
                    validator: (value) =>
                        value == null ? 'Seleccione una marca' : null,
                  ),
                  const SizedBox(height: 20),
                  // Nombre
                  LabelComponent(
                    label: 'Nombre del Producto *',
                    size: LabelSize.medium,
                    fontWeight: FontWeight.w600,
                    color: VcomColors.oroBrillante,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: VcomColors.blancoCrema),
                    decoration: InputDecoration(
                      hintText: 'Ingrese el nombre del producto',
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
                        borderSide: BorderSide(
                          color: VcomColors.oroBrillante,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 20),
                  // Descripción
                  LabelComponent(
                    label: 'Descripción',
                    size: LabelSize.medium,
                    fontWeight: FontWeight.w600,
                    color: VcomColors.oroBrillante,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: TextStyle(color: VcomColors.blancoCrema),
                    decoration: InputDecoration(
                      hintText: 'Ingrese la descripción del producto',
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
                        borderSide: BorderSide(
                          color: VcomColors.oroBrillante,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Referencia
                  LabelComponent(
                    label: 'Referencia',
                    size: LabelSize.medium,
                    fontWeight: FontWeight.w600,
                    color: VcomColors.oroBrillante,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _skuController,
                    style: TextStyle(color: VcomColors.blancoCrema),
                    decoration: InputDecoration(
                      hintText: 'Ingrese la referencia del producto',
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
                        borderSide: BorderSide(
                          color: VcomColors.oroBrillante,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Precio y Stock en fila
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LabelComponent(
                              label: 'Precio (COP) *',
                              size: LabelSize.medium,
                              fontWeight: FontWeight.w600,
                              color: VcomColors.oroBrillante,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              style: TextStyle(color: VcomColors.blancoCrema),
                              decoration: InputDecoration(
                                hintText: '0.00',
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
                                  borderSide: BorderSide(
                                    color: VcomColors.oroBrillante,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Campo requerido';
                                }
                                if (double.tryParse(value!) == null) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LabelComponent(
                              label: 'Stock *',
                              size: LabelSize.medium,
                              fontWeight: FontWeight.w600,
                              color: VcomColors.oroBrillante,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: TextStyle(color: VcomColors.blancoCrema),
                              decoration: InputDecoration(
                                hintText: '0',
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
                                  borderSide: BorderSide(
                                    color: VcomColors.oroBrillante,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Campo requerido';
                                }
                                if (int.tryParse(value!) == null) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Imágenes del producto
                  LabelComponent(
                    label: 'Imágenes del Producto',
                    size: LabelSize.medium,
                    fontWeight: FontWeight.w600,
                    color: VcomColors.oroBrillante,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: VcomColors.azulOverlayTransparente60,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: VcomColors.oroLujoso.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Grid de imágenes
                        if (_selectedImages.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_selectedImages[index].path),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (index == 0)
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: VcomColors.oroLujoso,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Principal',
                                          style: TextStyle(
                                            color: VcomColors.azulMedianocheTexto,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                        // Botón para agregar imágenes
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickImageFromGallery,
                                icon: Icon(Icons.photo_library, color: VcomColors.oroBrillante),
                                label: Text(
                                  'Galería',
                                  style: TextStyle(color: VcomColors.blancoCrema),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: VcomColors.oroLujoso.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickImageFromCamera,
                                icon: Icon(Icons.camera_alt, color: VcomColors.oroBrillante),
                                label: Text(
                                  'Cámara',
                                  style: TextStyle(color: VcomColors.blancoCrema),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: VcomColors.oroLujoso.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedImages.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'No hay imágenes seleccionadas',
                              style: TextStyle(
                                color: VcomColors.blancoCrema.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Estado
                  CheckboxListTile(
                    title: Text(
                      'Producto activo',
                      style: TextStyle(color: VcomColors.blancoCrema),
                    ),
                    value: _stateProduct,
                    activeColor: VcomColors.oroLujoso,
                    checkColor: VcomColors.azulMedianocheTexto,
                    onChanged: (value) =>
                        setState(() => _stateProduct = value ?? true),
                    tileColor: VcomColors.azulOverlayTransparente60,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: ButtonComponent(
                          label: 'Cancelar',
                          size: ButtonSize.large,
                          color: Colors.grey[800],
                          textColor: VcomColors.blancoCrema,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ButtonComponent(
                          label: 'Crear',
                          size: ButtonSize.large,
                          color: VcomColors.oroLujoso,
                          textColor: VcomColors.azulMedianocheTexto,
                          onPressed: _handleSave,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

