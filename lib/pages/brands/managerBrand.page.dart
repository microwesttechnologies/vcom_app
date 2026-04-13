import 'package:flutter/material.dart';
import 'package:vcom_app/components/commons/add_button.component.dart';
import 'package:vcom_app/components/shared/dynamic_sidebar_drawer.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/core/models/brand.model.dart';
import 'package:vcom_app/pages/brands/managerBrand.component.dart';
import 'package:vcom_app/pages/brands/widgets/brand_form_sheet.dart';
import 'package:vcom_app/pages/brands/widgets/brand_list_content.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página de gestión de marcas.
///
/// La página orquesta permisos, navegación y acciones.
/// El render detallado del formulario/listado vive en widgets locales del módulo.
class ManagerBrandPage extends StatefulWidget {
  const ManagerBrandPage({super.key});

  @override
  State<ManagerBrandPage> createState() => _ManagerBrandPageState();
}

class _ManagerBrandPageState extends State<ManagerBrandPage> {
  late final ManagerBrandComponent _managerBrandComponent;

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
    super.dispose();
  }

  void _onComponentChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _showPermissionDenied(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No tienes permiso para $action marcas'),
        backgroundColor: VcomColors.error,
      ),
    );
  }

  Future<void> _saveBrand(BrandModel brand, bool isEditing) async {
    if (isEditing) {
      await _managerBrandComponent.updateBrand(brand);
      return;
    }

    await _managerBrandComponent.createBrand(brand);
  }

  Future<void> _openBrandForm({BrandModel? brand}) async {
    if (brand != null && !_managerBrandComponent.canUpdateBrands) {
      _showPermissionDenied('editar');
      return;
    }

    if (brand == null && !_managerBrandComponent.canCreateBrands) {
      _showPermissionDenied('crear');
      return;
    }

    final result = await showModalBottomSheet<BrandFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BrandFormSheet(
        initialBrand: brand,
        categories: _managerBrandComponent.categories,
        onSave: _saveBrand,
      ),
    );

    if (!mounted || result == null) return;

    final successMessage = switch (result) {
      BrandFormResult.updated => 'Marca actualizada exitosamente',
      BrandFormResult.created => 'Marca creada exitosamente',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: VcomColors.success,
      ),
    );
  }

  Future<void> _handleDelete(BrandModel brand) async {
    if (!_managerBrandComponent.canDeleteBrands) {
      _showPermissionDenied('eliminar');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VcomColors.azulZafiroProfundo,
        title: const Text(
          'Confirmar eliminación',
          style: TextStyle(color: VcomColors.blancoCrema),
        ),
        content: const Text(
          '¿Está seguro de que desea eliminar esta marca?',
          style: TextStyle(color: VcomColors.blancoCrema),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: VcomColors.oroLujoso),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: VcomColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _managerBrandComponent.deleteBrand(brand.idBrand);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marca eliminada exitosamente'),
          backgroundColor: VcomColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: VcomColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModeloNavbar(),
      drawer: const Drawer(
        child: DynamicSidebarDrawer(selectedRouteHints: ['brand', 'marca']),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: VcomColors.gradienteNocturno),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: BrandListContent(
              component: _managerBrandComponent,
              onRetry: () =>
                  _managerBrandComponent.fetchBrands(forceRefresh: true),
              onEdit: (brand) => _openBrandForm(brand: brand),
              onDelete: _handleDelete,
            ),
          ),
        ),
      ),
      floatingActionButton: _managerBrandComponent.canCreateBrands
          ? AddButtonComponent(onPressed: _openBrandForm)
          : null,
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'brand'),
    );
  }
}
