import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/components/shared/sidebar.component.dart';
import 'package:vcom_app/components/commons/button.dart';
import 'package:vcom_app/components/commons/label.component.dart';
import 'package:vcom_app/components/commons/add_button.component.dart';
import 'package:vcom_app/pages/brands/managerBrand.component.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';
import 'package:vcom_app/pages/categories/managerCategory.page.dart';
import 'package:vcom_app/pages/products/manage/managerProduct.page.dart';
import 'package:vcom_app/core/models/brand.model.dart';
import 'package:vcom_app/core/models/category.model.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página de gestión de marcas
class ManagerBrandPage extends StatefulWidget {
  const ManagerBrandPage({super.key});

  @override
  State<ManagerBrandPage> createState() => _ManagerBrandPageState();
}

class _ManagerBrandPageState extends State<ManagerBrandPage> {
  int _selectedIndex = 2;
  late ManagerBrandComponent _managerBrandComponent;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoController = TextEditingController();
  final _websiteController = TextEditingController();
  
  int? _selectedCategoryId;
  bool _stateBrand = true;

  @override
  void initState() {
    super.initState();
    _managerBrandComponent = ManagerBrandComponent();
    _managerBrandComponent.addListener(_onComponentChanged);
    _managerBrandComponent.initialize();
  }

  @override
  void dispose() {
    _managerBrandComponent.removeListener(_onComponentChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _logoController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _onComponentChanged() {
    setState(() {});
  }

  /// Valida si una cadena es una URL válida
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void _loadBrandData(BrandModel brand) {
    _nameController.text = brand.nameBrand;
    _descriptionController.text = brand.descriptionBrand ?? '';
    _logoController.text = brand.logo ?? '';
    _websiteController.text = brand.website ?? '';
    _selectedCategoryId = brand.idCategory;
    _stateBrand = brand.stateBrand;
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _logoController.clear();
    _websiteController.clear();
    _selectedCategoryId = null;
    _stateBrand = true;
    _managerBrandComponent.clearSelectedBrand();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione una categoría'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final brand = BrandModel(
        idBrand: _managerBrandComponent.selectedBrand?.idBrand ?? 0,
        idCategory: _selectedCategoryId!,
        nameBrand: _nameController.text.trim(),
        descriptionBrand: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        logo: _logoController.text.trim().isEmpty 
            ? null 
            : _logoController.text.trim(),
        website: _websiteController.text.trim().isEmpty 
            ? null 
            : _websiteController.text.trim(),
        stateBrand: _stateBrand,
      );

      if (_managerBrandComponent.selectedBrand != null) {
        await _managerBrandComponent.updateBrand(brand);
      } else {
        await _managerBrandComponent.createBrand(brand);
      }

      if (mounted) {
        Navigator.pop(context);
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _managerBrandComponent.selectedBrand != null
                  ? 'Marca actualizada exitosamente'
                  : 'Marca creada exitosamente',
            ),
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

  Future<void> _handleDelete(int brandId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VcomColors.azulZafiroProfundo,
        title: Text(
          'Confirmar eliminación',
          style: TextStyle(color: VcomColors.blancoCrema),
        ),
        content: Text(
          '¿Está seguro de que desea eliminar esta marca?',
          style: TextStyle(color: VcomColors.blancoCrema),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: VcomColors.oroLujoso),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _managerBrandComponent.deleteBrand(brandId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Marca eliminada exitosamente'),
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
  }

  void _showBrandForm({BrandModel? brand}) {
    try {
      if (brand != null) {
        _managerBrandComponent.setSelectedBrand(brand);
        _loadBrandData(brand);
      } else {
        _clearForm();
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: VcomColors.azulZafiroProfundo,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: VcomColors.oroLujoso.withOpacity(0.3),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      brand != null ? 'Editar Marca' : 'Nueva Marca',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: VcomColors.blancoCrema,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: VcomColors.blancoCrema),
                      onPressed: () {
                        Navigator.pop(context);
                        _clearForm();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabelComponent(
                        label: 'Categoría *',
                        size: LabelSize.medium,
                        fontWeight: FontWeight.w600,
                        color: VcomColors.oroBrillante,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: VcomColors.azulOverlayTransparente60,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
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
                        items: _managerBrandComponent.categories
                            .map((category) => DropdownMenuItem<int>(
                                  value: category.idCategory,
                                  child: Text(category.nameCategory),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedCategoryId = value),
                        validator: (value) =>
                            value == null ? 'Seleccione una categoría' : null,
                      ),
                      const SizedBox(height: 20),
                      LabelComponent(
                        label: 'Nombre de la Marca *',
                        size: LabelSize.medium,
                        fontWeight: FontWeight.w600,
                        color: VcomColors.oroBrillante,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: VcomColors.blancoCrema),
                        decoration: InputDecoration(
                          hintText: 'Ingrese el nombre de la marca',
                          hintStyle: TextStyle(
                            color: VcomColors.blancoCrema.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: VcomColors.azulOverlayTransparente60,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
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
                          hintText: 'Ingrese la descripción de la marca',
                          hintStyle: TextStyle(
                            color: VcomColors.blancoCrema.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: VcomColors.azulOverlayTransparente60,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
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
                      LabelComponent(
                        label: 'Logo (URL)',
                        size: LabelSize.medium,
                        fontWeight: FontWeight.w600,
                        color: VcomColors.oroBrillante,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _logoController,
                        style: TextStyle(color: VcomColors.blancoCrema),
                        decoration: InputDecoration(
                          hintText: 'https://example.com/logo.png',
                          hintStyle: TextStyle(
                            color: VcomColors.blancoCrema.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: VcomColors.azulOverlayTransparente60,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
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
                          if (value != null && value.isNotEmpty) {
                            if (!_isValidUrl(value)) {
                              return 'Ingrese una URL válida (debe comenzar con http:// o https://)';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      LabelComponent(
                        label: 'Sitio Web (URL)',
                        size: LabelSize.medium,
                        fontWeight: FontWeight.w600,
                        color: VcomColors.oroBrillante,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _websiteController,
                        style: TextStyle(color: VcomColors.blancoCrema),
                        decoration: InputDecoration(
                          hintText: 'https://example.com',
                          hintStyle: TextStyle(
                            color: VcomColors.blancoCrema.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: VcomColors.azulOverlayTransparente60,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
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
                          if (value != null && value.isNotEmpty) {
                            if (!_isValidUrl(value)) {
                              return 'Ingrese una URL válida (debe comenzar con http:// o https://)';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CheckboxListTile(
                        title: Text(
                          'Marca activa',
                          style: TextStyle(color: VcomColors.blancoCrema),
                        ),
                        value: _stateBrand,
                        activeColor: VcomColors.oroLujoso,
                        checkColor: VcomColors.azulMedianocheTexto,
                        onChanged: (value) =>
                            setState(() => _stateBrand = value ?? true),
                        tileColor: VcomColors.azulOverlayTransparente60,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: ButtonComponent(
                              label: 'Cancelar',
                              size: ButtonSize.large,
                              color: Colors.grey[800],
                              textColor: VcomColors.blancoCrema,
                              onPressed: () {
                                Navigator.pop(context);
                                _clearForm();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ButtonComponent(
                              label: brand != null ? 'Actualizar' : 'Crear',
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
            ],
          ),
        ),
      ),
    ).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al mostrar formulario: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavbarComponent(),
      drawer: Drawer(
        child: SidebarComponent(
          items: [
            SidebarItem(
              label: 'Dashboard',
              icon: Icons.dashboard,
              isSelected: _selectedIndex == 0,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardPage(),
                  ),
                );
              },
            ),
            SidebarItem(
              label: 'Categorías',
              icon: Icons.category,
              isSelected: _selectedIndex == 1,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManagerCategoryPage(),
                  ),
                );
              },
            ),
            SidebarItem(
              label: 'Marcas',
              icon: Icons.branding_watermark,
              isSelected: _selectedIndex == 2,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            SidebarItem(
              label: 'Productos',
              icon: Icons.inventory,
              isSelected: _selectedIndex == 3,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManagerProductPage(),
                  ),
                );
              },
            ),
          ],
          selectedIndex: _selectedIndex,
          onItemSelected: (index) {
            setState(() => _selectedIndex = index);
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: VcomColors.gradienteNocturno,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildContent(),
          ),
        ),
      ),
      floatingActionButton: AddButtonComponent(
        onPressed: () => _showBrandForm(),
      ),
    );
  }

  Widget _buildContent() {
    if (_managerBrandComponent.isLoading && _managerBrandComponent.brands.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: VcomColors.oroLujoso,
        ),
      );
    }

    if (_managerBrandComponent.error != null && _managerBrandComponent.brands.isEmpty) {
      return Center(
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
              'Error al cargar marcas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _managerBrandComponent.error!,
              style: TextStyle(
                fontSize: 14,
                color: VcomColors.blancoCrema.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ButtonComponent(
              label: 'Reintentar',
              size: ButtonSize.medium,
              color: VcomColors.oroLujoso,
              textColor: VcomColors.azulMedianocheTexto,
              onPressed: () => _managerBrandComponent.fetchBrands(),
            ),
          ],
        ),
      );
    }

    if (_managerBrandComponent.brands.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.branding_watermark_outlined,
              size: 64,
              color: VcomColors.oroLujoso,
            ),
            const SizedBox(height: 16),
            Text(
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
                color: VcomColors.blancoCrema.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gestión de Marcas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
            Text(
              '${_managerBrandComponent.brands.length} marcas',
              style: TextStyle(
                fontSize: 14,
                color: VcomColors.blancoCrema.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: _managerBrandComponent.brands.length,
            itemBuilder: (context, index) {
              final brand = _managerBrandComponent.brands[index];
              final category = _managerBrandComponent.categories
                  .firstWhere((c) => c.idCategory == brand.idCategory, orElse: () => CategoryModel(idCategory: 0, nameCategory: 'N/A', stateCategory: false));
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: VcomColors.azulZafiroProfundo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: VcomColors.oroLujoso.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              brand.nameBrand,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: VcomColors.blancoCrema,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: VcomColors.oroLujoso, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showBrandForm(brand: brand),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _handleDelete(brand.idBrand),
                          ),
                        ],
                      ),
                      if (brand.descriptionBrand != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          brand.descriptionBrand!,
                          style: TextStyle(
                            color: VcomColors.blancoCrema.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              category.nameCategory,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: VcomColors.azulOverlayTransparente60,
                            labelStyle: TextStyle(color: VcomColors.blancoCrema),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          if (brand.website != null)
                            Chip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.language, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Website',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: VcomColors.oroLujoso.withOpacity(0.2),
                              labelStyle: TextStyle(color: VcomColors.oroBrillante),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: brand.stateBrand
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              brand.stateBrand ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                fontSize: 12,
                                color: brand.stateBrand ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

