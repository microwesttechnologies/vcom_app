import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vcom_app/components/commons/button.dart';
import 'package:vcom_app/components/commons/label.component.dart';
import 'package:vcom_app/pages/products/edit/editProduct.component.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página para editar productos
class EditProductPage extends StatefulWidget {
  final int productId;
  
  const EditProductPage({
    super.key,
    required this.productId,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late EditProductComponent _editProductComponent;
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
  final List<String> _existingImageUrls = [];
  final ImagePicker _imagePicker = ImagePicker();

  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _editProductComponent = EditProductComponent();
    _editProductComponent.addListener(_onComponentChanged);
    _loadProductDataAsync();
  }

  @override
  void dispose() {
    _editProductComponent.removeListener(_onComponentChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDataAsync() async {
    try {
      await _editProductComponent.initialize(widget.productId);
      // Esperar a que el producto y las marcas estén completamente cargados
      while (_editProductComponent.isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      // Esperar un frame adicional para asegurar que todo esté listo
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted && _editProductComponent.product != null && !_dataLoaded) {
        _loadProductData(_editProductComponent.product!);
        _dataLoaded = true;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      // Error manejado por el componente
    }
  }

  void _onComponentChanged() {
    // Cargar datos cuando el producto esté disponible y las marcas estén cargadas
    if (_editProductComponent.product != null && 
        !_dataLoaded && 
        !_editProductComponent.isLoading) {
      // Verificar que las marcas estén cargadas si hay categoría
      if (_editProductComponent.product!.category?.idCategory != null) {
        if (_editProductComponent.brands.isNotEmpty || 
            _editProductComponent.selectedCategoryId == null) {
          _loadProductData(_editProductComponent.product!);
          _dataLoaded = true;
        }
      } else {
        _loadProductData(_editProductComponent.product!);
        _dataLoaded = true;
      }
    }
    setState(() {});
  }

  void _loadProductData(ProductModel product) {
    if (!mounted) return;
    
    _nameController.text = product.nameProduct;
    _descriptionController.text = product.descriptionProduct ?? '';
    _skuController.text = product.sku ?? '';
    _priceController.text = product.priceCop.toString();
    _stockController.text = product.stock.toString();
    _selectedCategoryId = product.category?.idCategory;
    _selectedBrandId = product.idBrand;
    _stateProduct = product.stateProduct;
    
    // Cargar imágenes existentes
    _existingImageUrls.clear();
    _selectedImages.clear();
    if (product.images.isNotEmpty) {
      _existingImageUrls.addAll(
        product.images.map((img) => img.imageUrl).where((url) => url.isNotEmpty),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
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

    if (_editProductComponent.product?.idProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Producto no válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Solo incluir imágenes existentes con URLs válidas
      // Las nuevas imágenes locales no se pueden enviar hasta que se suban al servidor
      final List<ProductImageModel> productImages = [];
      
      // Agregar solo imágenes existentes que no se eliminaron y tienen URLs válidas
      if (_editProductComponent.product?.images.isNotEmpty ?? false) {
        int order = 1; // El API requiere que image_order sea al menos 1
        for (var existingImg in _editProductComponent.product!.images) {
          // Solo incluir si la URL es válida (empieza con http:// o https://)
          if (_existingImageUrls.contains(existingImg.imageUrl) &&
              (existingImg.imageUrl.startsWith('http://') || 
               existingImg.imageUrl.startsWith('https://'))) {
            productImages.add(ProductImageModel(
              idImage: existingImg.idImage,
              imageUrl: existingImg.imageUrl,
              imageOrder: order,
              isPrimary: order == 1,
            ));
            order++;
          }
        }
      }
      
      // Nota: Las nuevas imágenes seleccionadas (_selectedImages) no se pueden enviar
      // porque son archivos locales. Necesitarían subirse primero al servidor
      // para obtener URLs válidas antes de incluirlas en el producto

      final product = ProductModel(
        idProduct: _editProductComponent.product!.idProduct,
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

      await _editProductComponent.updateProduct(product, newImages: _selectedImages);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Asegurar que los datos se carguen cuando el producto esté disponible
    if (_editProductComponent.product != null && !_dataLoaded && !_editProductComponent.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dataLoaded) {
          _loadProductData(_editProductComponent.product!);
          _dataLoaded = true;
          setState(() {});
        }
      });
    }

    if (_editProductComponent.isLoading && _editProductComponent.product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar Producto'),
          backgroundColor: VcomColors.azulZafiroProfundo,
          foregroundColor: VcomColors.blancoCrema,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: VcomColors.gradienteNocturno,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: VcomColors.oroLujoso,
            ),
          ),
        ),
      );
    }

    if (_editProductComponent.error != null && _editProductComponent.product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar Producto'),
          backgroundColor: VcomColors.azulZafiroProfundo,
          foregroundColor: VcomColors.blancoCrema,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: VcomColors.gradienteNocturno,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: VcomColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar producto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: VcomColors.blancoCrema,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _editProductComponent.error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: VcomColors.blancoCrema.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ButtonComponent(
                  label: 'Volver',
                  size: ButtonSize.medium,
                  color: VcomColors.oroLujoso,
                  textColor: VcomColors.azulMedianocheTexto,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
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
                    items: _editProductComponent.categories
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
                          await _editProductComponent.fetchBrandsByCategory(value);
                        } catch (e) {
                          // Error manejado por el componente
                        }
                      } else {
                        _editProductComponent.clearCategorySelection();
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
                    items: _editProductComponent.brands
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
                        // Grid de imágenes existentes
                        if (_existingImageUrls.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: _existingImageUrls.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _existingImageUrls[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[800],
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey[400],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _existingImageUrls.removeAt(index);
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
                        // Grid de imágenes nuevas
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
                        if (_existingImageUrls.isEmpty && _selectedImages.isEmpty)
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
                          label: 'Actualizar',
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

