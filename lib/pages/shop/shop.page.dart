import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/components/shared/sidebar.component.dart';
import 'package:vcom_app/components/commons/button.dart';
import 'package:vcom_app/pages/shop/shop.component.dart';
import 'package:vcom_app/pages/shop/product_detail.page.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.component.dart';
import 'package:vcom_app/pages/categories/managerCategory.page.dart';
import 'package:vcom_app/pages/brands/managerBrand.page.dart';
import 'package:vcom_app/pages/products/manage/managerProduct.page.dart';
import 'package:vcom_app/pages/chat/chat.page.dart';
import 'package:vcom_app/pages/training/training.page.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/core/models/module.model.dart';
import 'package:vcom_app/core/common/icon.helper.dart';
import 'package:vcom_app/style/vcom_colors.dart';
import 'package:intl/intl.dart';

/// Página principal de la tienda
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int _selectedIndex = 0;
  late ShopComponent _shopComponent;
  late DashboardComponent _dashboardComponent;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _shopComponent = ShopComponent();
    _shopComponent.addListener(_onComponentChanged);
    _shopComponent.initialize();
    
    _dashboardComponent = DashboardComponent();
    _dashboardComponent.addListener(_onComponentChanged);
    _dashboardComponent.fetchModules().then((_) {
      // Establecer el índice seleccionado para la tienda después de cargar los módulos
      if (mounted) {
        _updateSelectedIndexForShop();
      }
    });
  }

  /// Actualiza el índice seleccionado para la tienda
  void _updateSelectedIndexForShop() {
    final shopModuleIndex = _dashboardComponent.modules.indexWhere(
      (module) {
        final route = module.route.toLowerCase();
        return route.contains('shop') || route.contains('tienda') || route.contains('store');
      },
    );
    if (shopModuleIndex != -1) {
      setState(() {
        _selectedIndex = shopModuleIndex;
      });
    }
  }

  @override
  void dispose() {
    _shopComponent.removeListener(_onComponentChanged);
    _dashboardComponent.removeListener(_onComponentChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onComponentChanged() {
    setState(() {});
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  /// Construye el sidebar dinámicamente basado en los módulos del usuario
  Widget _buildSidebar() {
    if (_dashboardComponent.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }

    if (_dashboardComponent.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: VcomColors.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar módulos',
              style: TextStyle(
                fontSize: 16,
                color: VcomColors.blancoCrema,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _dashboardComponent.fetchModules(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Convertir todos los módulos a SidebarItem
    final moduleItems = _dashboardComponent.modules
        .where((module) => module.state) // Solo módulos activos
        .map((module) {
      final index = _dashboardComponent.modules.indexOf(module) + 1; // +1 porque Dashboard será el índice 0
      return SidebarItem(
        label: module.nameModule,
        icon: IconHelper.getIconFromString(module.icon),
        isSelected: _selectedIndex == index,
        onTap: () {
          Navigator.pop(context);
          _navigateToModule(module);
        },
      );
    }).toList();

    // Agregar botón de Dashboard al principio
    final sidebarItems = [
      SidebarItem(
        label: 'Dashboard',
        icon: Icons.dashboard,
        isSelected: _selectedIndex == 0,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        },
      ),
      ...moduleItems,
    ];

    // Si no hay módulos, mostrar mensaje
    if (sidebarItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 64, color: VcomColors.oroLujoso),
            const SizedBox(height: 16),
            Text(
              'No hay módulos disponibles',
              style: TextStyle(
                fontSize: 16,
                color: VcomColors.blancoCrema,
              ),
            ),
          ],
        ),
      );
    }

    return SidebarComponent(
      items: sidebarItems,
      selectedIndex: _selectedIndex,
      onItemSelected: (index) {
        setState(() => _selectedIndex = index);
      },
    );
  }

  /// Navega a la página correspondiente según la ruta del módulo
  void _navigateToModule(ModuleModel module) {
    final route = module.route.toLowerCase();
    
    // Determinar si estamos en la tienda para mantener el índice seleccionado
    final isShopRoute = route.contains('shop') || route.contains('tienda') || route.contains('store');
    if (isShopRoute) {
      // Ya estamos en la tienda, solo actualizar el índice
      final moduleIndex = _dashboardComponent.modules.indexOf(module);
      if (moduleIndex != -1) {
        setState(() {
          _selectedIndex = moduleIndex;
        });
      }
      return;
    }

    Widget? targetPage;

    // Mapear rutas a páginas
    if (route.contains('dashboard') || route.contains('inicio')) {
      targetPage = const DashboardPage();
    } else if (route.contains('category') || route.contains('categoria')) {
      targetPage = const ManagerCategoryPage();
    } else if (route.contains('brand') || route.contains('marca')) {
      targetPage = const ManagerBrandPage();
    } else if (route.contains('product') || route.contains('producto')) {
      targetPage = const ManagerProductPage();
    } else if (route.contains('shop') || route.contains('tienda') || route.contains('store')) {
      targetPage = const ShopPage();
    } else if (route.contains('chat') || route.contains('mensaje')) {
      targetPage = const ChatPage();
    } else if (route.contains('training') || route.contains('entrenamiento')) {
      targetPage = const TrainingPage();
    }

    if (targetPage != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => targetPage!),
      );
    } else {
      // Si no se encuentra la ruta, mostrar mensaje de módulo en desarrollo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.construction,
                  color: VcomColors.blancoCrema,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${module.nameModule} está en desarrollo',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: VcomColors.oroLujoso,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: VcomColors.azulMedianocheTexto,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavbarComponent(
        title: 'VCOM Store',
        subtitle: 'Tu tienda de confianza',
        backgroundColor: VcomColors.azulZafiroProfundo,
      ),
      drawer: Drawer(
        child: _buildSidebar(),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: VcomColors.gradienteNocturno,
        ),
        child: SafeArea(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_shopComponent.isLoading && _shopComponent.allProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: VcomColors.oroLujoso,
              strokeWidth: 4,
            ),
            const SizedBox(height: 24),
            Text(
              'Cargando productos...',
              style: TextStyle(
                fontSize: 16,
                color: VcomColors.blancoCrema,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_shopComponent.error != null && _shopComponent.allProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: VcomColors.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar la tienda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _shopComponent.error!,
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
              onPressed: () => _shopComponent.refresh(),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Barra de búsqueda
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: _buildSearchBar(),
          ),
        ),
        
        // Filtros de categorías
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCategoryFilters(),
          ),
        ),
        
        // Productos más vistos
        if (_shopComponent.selectedCategoryId == null && _shopComponent.searchQuery.isEmpty)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _buildMostViewedSection(),
            ),
          ),
        
        // Lista de productos
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildProductsSection(),
          ),
        ),
        
        // Grid de productos
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: _buildProductsGrid(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: VcomColors.blancoCrema,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: VcomColors.azulMedianocheTexto),
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          hintStyle: TextStyle(color: VcomColors.azulMedianocheTexto.withOpacity(0.6)),
          prefixIcon: Icon(Icons.search, color: VcomColors.azulMedianocheTexto.withOpacity(0.6)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: VcomColors.azulMedianocheTexto.withOpacity(0.6)),
                  onPressed: () {
                    _searchController.clear();
                    _shopComponent.searchProducts('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (value) => _shopComponent.searchProducts(value),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorías',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: VcomColors.blancoCrema,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryChip(null, 'Todos'),
              ..._shopComponent.categories.map((category) => 
                _buildCategoryChip(category.idCategory, category.nameCategory)
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(int? categoryId, String label) {
    final isSelected = _shopComponent.selectedCategoryId == categoryId;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _shopComponent.filterByCategory(categoryId),
        backgroundColor: VcomColors.azulOverlayTransparente60,
        selectedColor: VcomColors.oroLujoso,
        labelStyle: TextStyle(
          color: isSelected ? VcomColors.azulMedianocheTexto : VcomColors.blancoCrema,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? VcomColors.oroLujoso : VcomColors.oroLujoso.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildMostViewedSection() {
    final mostViewed = _shopComponent.getMostViewedProducts();
    if (mostViewed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: VcomColors.oroLujoso, size: 24),
            const SizedBox(width: 8),
            Text(
              'Productos más vistos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mostViewed.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                child: _buildProductCard(mostViewed[index], isHorizontal: true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    final productCount = _shopComponent.products.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _shopComponent.selectedCategoryId != null || _shopComponent.searchQuery.isNotEmpty
              ? 'Resultados ($productCount)'
              : 'Todos los productos ($productCount)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: VcomColors.blancoCrema,
          ),
        ),
        if (_shopComponent.selectedCategoryId != null || _shopComponent.searchQuery.isNotEmpty)
          TextButton(
            onPressed: () => _shopComponent.clearFilters(),
            child: Text(
              'Limpiar filtros',
              style: TextStyle(color: VcomColors.oroLujoso),
            ),
          ),
      ],
    );
  }

  Widget _buildProductsGrid() {
    // Mostrar loader mientras carga
    if (_shopComponent.isLoading && _shopComponent.allProducts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: VcomColors.oroLujoso,
                strokeWidth: 4,
              ),
              const SizedBox(height: 24),
              Text(
                'Cargando productos...',
                style: TextStyle(
                  fontSize: 16,
                  color: VcomColors.blancoCrema,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_shopComponent.products.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: VcomColors.oroLujoso.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'No se encontraron productos',
                style: TextStyle(
                  fontSize: 16,
                  color: VcomColors.blancoCrema.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return _buildProductCard(_shopComponent.products[index]);
        },
        childCount: _shopComponent.products.length,
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, {bool isHorizontal = false}) {
    final primaryImage = product.images.isNotEmpty 
        ? product.images.firstWhere((img) => img.isPrimary, orElse: () => product.images.first)
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: VcomColors.azulZafiroProfundo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: VcomColors.oroLujoso.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              flex: isHorizontal ? 3 : 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: VcomColors.azulOverlayTransparente60,
                ),
                child: primaryImage != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          primaryImage.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: VcomColors.azulOverlayTransparente60,
                              child: Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: VcomColors.blancoCrema.withOpacity(0.5),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        color: VcomColors.azulOverlayTransparente60,
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: VcomColors.blancoCrema.withOpacity(0.5),
                        ),
                      ),
              ),
            ),
            
            // Información del producto
            Expanded(
              flex: isHorizontal ? 2 : 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del producto
                    Text(
                      product.nameProduct,
                      style: TextStyle(
                        fontSize: isHorizontal ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: VcomColors.blancoCrema,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Marca
                    if (product.brand != null)
                      Text(
                        product.brand!.nameBrand,
                        style: TextStyle(
                          fontSize: 12,
                          color: VcomColors.blancoCrema.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const Spacer(),
                    
                    // Precio
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatPrice(product.priceCop),
                        style: TextStyle(
                          fontSize: isHorizontal ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: VcomColors.oroLujoso,
                        ),
                      ),
                    ),
                    
                    // Stock
                    if (product.stock <= 5)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Solo ${product.stock} disponibles',
                          style: TextStyle(
                            fontSize: 10,
                            color: VcomColors.oroBrillante,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


