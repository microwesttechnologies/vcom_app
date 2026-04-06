import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/components/shared/sidebar.component.dart';
import 'package:vcom_app/components/commons/button.dart';
import 'package:vcom_app/components/commons/label.component.dart';
import 'package:vcom_app/components/commons/add_button.component.dart';
import 'package:vcom_app/pages/categories/managerCategory.component.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';
import 'package:vcom_app/pages/brands/managerBrand.page.dart';
import 'package:vcom_app/core/models/category.model.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página de gestión de categorías
class ManagerCategoryPage extends StatefulWidget {
  const ManagerCategoryPage({super.key});

  @override
  State<ManagerCategoryPage> createState() => _ManagerCategoryPageState();
}

class _ManagerCategoryPageState extends State<ManagerCategoryPage> {
  int _selectedIndex = 1;
  late ManagerCategoryComponent _managerCategoryComponent;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController();
  bool _stateCategory = true;

  @override
  void initState() {
    super.initState();
    _managerCategoryComponent = ManagerCategoryComponent();
    _managerCategoryComponent.addListener(_onComponentChanged);
    _managerCategoryComponent.initialize();
  }

  @override
  void dispose() {
    _managerCategoryComponent.removeListener(_onComponentChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _onComponentChanged() {
    setState(() {});
  }

  void _showPermissionDenied(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No tienes permiso para $action categorías'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _loadCategoryData(CategoryModel category) {
    _nameController.text = category.nameCategory;
    _descriptionController.text = category.descriptionCategory ?? '';
    _iconController.text = category.icon ?? '';
    _stateCategory = category.stateCategory;
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _iconController.clear();
    _stateCategory = true;
    _managerCategoryComponent.clearSelectedCategory();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEditing = _managerCategoryComponent.selectedCategory != null;
    if (isEditing && !_managerCategoryComponent.canUpdateCategories) {
      _showPermissionDenied('actualizar');
      return;
    }
    if (!isEditing && !_managerCategoryComponent.canCreateCategories) {
      _showPermissionDenied('crear');
      return;
    }

    try {
      final category = CategoryModel(
        idCategory: _managerCategoryComponent.selectedCategory?.idCategory ?? 0,
        nameCategory: _nameController.text.trim(),
        descriptionCategory: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        icon: _iconController.text.trim().isEmpty
            ? null
            : _iconController.text.trim(),
        stateCategory: _stateCategory,
      );

      if (_managerCategoryComponent.selectedCategory != null) {
        await _managerCategoryComponent.updateCategory(category);
      } else {
        await _managerCategoryComponent.createCategory(category);
      }

      if (mounted) {
        Navigator.pop(context);
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _managerCategoryComponent.selectedCategory != null
                  ? 'Categoría actualizada exitosamente'
                  : 'Categoría creada exitosamente',
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

  Future<void> _handleDelete(int categoryId) async {
    if (!_managerCategoryComponent.canDeleteCategories) {
      _showPermissionDenied('eliminar');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VcomColors.azulZafiroProfundo,
        title: Text(
          'Confirmar eliminación',
          style: TextStyle(color: VcomColors.blancoCrema),
        ),
        content: Text(
          '¿Está seguro de que desea eliminar esta categoría?',
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
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _managerCategoryComponent.deleteCategory(categoryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoría eliminada exitosamente'),
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

  void _showCategoryForm({CategoryModel? category}) {
    if (category != null && !_managerCategoryComponent.canUpdateCategories) {
      _showPermissionDenied('editar');
      return;
    }
    if (category == null && !_managerCategoryComponent.canCreateCategories) {
      _showPermissionDenied('crear');
      return;
    }

    if (category != null) {
      _managerCategoryComponent.setSelectedCategory(category);
      _loadCategoryData(category);
    } else {
      _clearForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                      color: VcomColors.oroLujoso.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category != null ? 'Editar Categoría' : 'Nueva Categoría',
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
                        label: 'Nombre de la Categoría *',
                        size: LabelSize.medium,
                        fontWeight: FontWeight.w600,
                        color: VcomColors.oroBrillante,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: VcomColors.blancoCrema),
                        decoration: InputDecoration(
                          hintText: 'Ingrese el nombre de la categoría',
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
                          hintText: 'Ingrese la descripción de la categoría',
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
                      LabelComponent(
                        label: 'Icono',
                        size: LabelSize.medium,
                        fontWeight: FontWeight.w600,
                        color: VcomColors.oroBrillante,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _iconController,
                        style: TextStyle(color: VcomColors.blancoCrema),
                        decoration: InputDecoration(
                          hintText: 'Ingrese el nombre del icono',
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
                      CheckboxListTile(
                        title: Text(
                          'Categoría activa',
                          style: TextStyle(color: VcomColors.blancoCrema),
                        ),
                        value: _stateCategory,
                        activeColor: VcomColors.oroLujoso,
                        checkColor: VcomColors.azulMedianocheTexto,
                        onChanged: (value) =>
                            setState(() => _stateCategory = value ?? true),
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
                              label: category != null ? 'Actualizar' : 'Crear',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModeloNavbar(),
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
              },
            ),
            SidebarItem(
              label: 'Marcas',
              icon: Icons.branding_watermark,
              isSelected: _selectedIndex == 2,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManagerBrandPage(),
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
        decoration: const BoxDecoration(gradient: VcomColors.gradienteNocturno),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildContent(),
          ),
        ),
      ),
      floatingActionButton: _managerCategoryComponent.canCreateCategories
          ? AddButtonComponent(onPressed: () => _showCategoryForm())
          : null,
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'category'),
    );
  }

  Widget _buildContent() {
    if (_managerCategoryComponent.isLoading &&
        _managerCategoryComponent.categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }

    if (_managerCategoryComponent.error != null &&
        _managerCategoryComponent.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: VcomColors.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar categorías',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _managerCategoryComponent.error!,
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
              onPressed: () =>
                  _managerCategoryComponent.fetchCategories(forceRefresh: true),
            ),
          ],
        ),
      );
    }

    if (_managerCategoryComponent.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: VcomColors.oroLujoso,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay categorías',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera categoría',
              style: TextStyle(
                fontSize: 14,
                color: VcomColors.blancoCrema.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Gestión de Categorías',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
            Text(
              '${_managerCategoryComponent.categories.length} categorías',
              style: TextStyle(
                fontSize: 14,
                color: VcomColors.blancoCrema.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: _managerCategoryComponent.categories.length,
            itemBuilder: (context, index) {
              final category = _managerCategoryComponent.categories[index];
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.nameCategory,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: VcomColors.blancoCrema,
                              ),
                            ),
                          ),
                          if (_managerCategoryComponent.canUpdateCategories)
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: VcomColors.oroLujoso,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  _showCategoryForm(category: category),
                            ),
                          if (_managerCategoryComponent.canUpdateCategories &&
                              _managerCategoryComponent.canDeleteCategories)
                            const SizedBox(width: 8),
                          if (_managerCategoryComponent.canDeleteCategories)
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  _handleDelete(category.idCategory),
                            ),
                        ],
                      ),
                      if (category.descriptionCategory != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          category.descriptionCategory!,
                          style: TextStyle(
                            color: VcomColors.blancoCrema.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (category.icon != null)
                            Chip(
                              label: Text(
                                category.icon!,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor:
                                  VcomColors.azulOverlayTransparente60,
                              labelStyle: TextStyle(
                                color: VcomColors.blancoCrema,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: category.stateCategory
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category.stateCategory ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                fontSize: 12,
                                color: category.stateCategory
                                    ? Colors.green
                                    : Colors.red,
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
