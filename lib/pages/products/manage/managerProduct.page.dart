import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/components/shared/sidebar.component.dart';
import 'package:vcom_app/components/commons/button.dart';
import 'package:vcom_app/components/commons/add_button.component.dart';
import 'package:vcom_app/pages/products/manage/managerProduct.component.dart';
import 'package:vcom_app/pages/products/create/createProduct.page.dart';
import 'package:vcom_app/pages/products/edit/editProduct.page.dart';
import 'package:vcom_app/pages/products/delete/deleteProduct.page.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';
import 'package:vcom_app/pages/categories/managerCategory.page.dart';
import 'package:vcom_app/pages/brands/managerBrand.page.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página de gestión de productos
/// Solo lista productos y navega a las páginas de create, edit y delete
class ManagerProductPage extends StatefulWidget {
  const ManagerProductPage({super.key});

  @override
  State<ManagerProductPage> createState() => _ManagerProductPageState();
}

class _ManagerProductPageState extends State<ManagerProductPage> {
  int _selectedIndex = 3;
  late ManagerProductComponent _managerProductComponent;

  @override
  void initState() {
    super.initState();
    _managerProductComponent = ManagerProductComponent();
    _managerProductComponent.addListener(_onComponentChanged);
    _managerProductComponent.initialize();
  }

  @override
  void dispose() {
    _managerProductComponent.removeListener(_onComponentChanged);
    super.dispose();
  }

  void _onComponentChanged() {
    setState(() {});
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateProductPage(),
      ),
    );
    
    if (result == true && mounted) {
      _managerProductComponent.fetchProducts();
    }
  }

  Future<void> _navigateToEdit(ProductModel product) async {
    if (product.idProduct == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(productId: product.idProduct!),
      ),
    );
    
    if (result == true && mounted) {
      _managerProductComponent.fetchProducts();
    }
  }

  Future<void> _navigateToDelete(ProductModel product) async {
    if (product.idProduct == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeleteProductPage(
          productId: product.idProduct!,
          productName: product.nameProduct ?? 'Producto',
        ),
      ),
    );
    
    if (result == true && mounted) {
      _managerProductComponent.fetchProducts();
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManagerBrandPage(),
                  ),
                );
              },
            ),
            SidebarItem(
              label: 'Productos',
              icon: Icons.inventory,
              isSelected: _selectedIndex == 3,
              onTap: () {
                Navigator.pop(context);
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
        onPressed: _navigateToCreate,
      ),
    );
  }

  Widget _buildContent() {
    if (_managerProductComponent.isLoading && _managerProductComponent.products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: VcomColors.oroLujoso,
        ),
      );
    }

    if (_managerProductComponent.error != null && _managerProductComponent.products.isEmpty) {
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
              'Error al cargar productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _managerProductComponent.error!,
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
              onPressed: () => _managerProductComponent.fetchProducts(),
            ),
          ],
        ),
      );
    }

    if (_managerProductComponent.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: VcomColors.oroLujoso,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer producto',
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
        // Header
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Gestión de Productos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
            Text(
              '${_managerProductComponent.products.length} productos',
              style: TextStyle(
                fontSize: 14,
                color: VcomColors.blancoCrema.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Lista de productos
        Expanded(
          child: ListView.builder(
            itemCount: _managerProductComponent.products.length,
            itemBuilder: (context, index) {
              final product = _managerProductComponent.products[index];
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
                      // Header con título y botones
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.nameProduct ?? 'Sin nombre',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                            onPressed: () => _navigateToEdit(product),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _navigateToDelete(product),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Descripción
                      if (product.descriptionProduct != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            product.descriptionProduct!,
                            style: TextStyle(
                              color: VcomColors.blancoCrema.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      // Chips de marca y categoría
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (product.brand != null)
                            Chip(
                              label: Text(
                                product.brand!.nameBrand ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: VcomColors.oroLujoso.withOpacity(0.2),
                              labelStyle: TextStyle(color: VcomColors.oroBrillante),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          if (product.category != null)
                            Chip(
                              label: Text(
                                product.category!.nameCategory ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: VcomColors.azulOverlayTransparente60,
                              labelStyle: TextStyle(color: VcomColors.blancoCrema),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Precio, stock y estado
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              '\$${product.priceCop?.toStringAsFixed(0) ?? '0'} COP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: VcomColors.oroBrillante,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Stock: ${product.stock ?? 0}',
                            style: TextStyle(
                              fontSize: 14,
                              color: VcomColors.blancoCrema.withOpacity(0.7),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (product.stateProduct ?? false)
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (product.stateProduct ?? false) ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                fontSize: 12,
                                color: (product.stateProduct ?? false) ? Colors.green : Colors.red,
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


