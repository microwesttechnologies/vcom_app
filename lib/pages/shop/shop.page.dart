import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
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
import 'package:vcom_app/pages/events/events.page.dart';
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
  ProductModel? _currentProduct;
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
    final shopModuleIndex = _dashboardComponent.modules.indexWhere((module) {
      final route = module.route.toLowerCase();
      return route.contains('shop') ||
          route.contains('tienda') ||
          route.contains('store');
    });
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
              style: TextStyle(fontSize: 16, color: VcomColors.blancoCrema),
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
          final index =
              _dashboardComponent.modules.indexOf(module) +
              1; // +1 porque Dashboard será el índice 0
          return SidebarItem(
            label: module.nameModule,
            icon: IconHelper.getIconFromString(module.icon),
            isSelected: _selectedIndex == index,
            onTap: () {
              Navigator.pop(context);
              _navigateToModule(module);
            },
          );
        })
        .toList();

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
              style: TextStyle(fontSize: 16, color: VcomColors.blancoCrema),
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
    final isShopRoute =
        route.contains('shop') ||
        route.contains('tienda') ||
        route.contains('store');
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
    } else if (route.contains('shop') ||
        route.contains('tienda') ||
        route.contains('store')) {
      targetPage = const ShopPage();
    } else if (route.contains('chat') || route.contains('mensaje')) {
      targetPage = const ChatPage();
    } else if (route.contains('event') ||
        route.contains('evento') ||
        route.contains('calendar') ||
        route.contains('calendario')) {
      targetPage = const EventsPage();
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

  void _openProduct(ProductModel product) {
    setState(() => _currentProduct = product);
  }

  void _closeProduct() {
    setState(() => _currentProduct = null);
  }

  @override
  Widget build(BuildContext context) {
    final inDetail = _currentProduct != null;

    return PopScope(
      canPop: !inDetail,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && inDetail) _closeProduct();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: ModeloNavbar(
          showBackButton: inDetail,
          onBackTap: inDetail ? _closeProduct : null,
        ),
        extendBodyBehindAppBar: true,
        extendBody: true,
        drawer: inDetail ? null : Drawer(child: _buildSidebar()),
        bottomNavigationBar: const ModeloMenuBar(activeRoute: 'shop'),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: inDetail
              ? ProductDetailBody(
                  key: ValueKey(_currentProduct!.idProduct),
                  product: _currentProduct!,
                )
              : Container(
                  key: const ValueKey('shop-list'),
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.8),
                      radius: 1.2,
                      colors: [
                        Color(0xFF273C67),
                        Color(0xFF1a2847),
                        Color(0xFF0d1525),
                        Color(0xFF000000),
                      ],
                      stops: [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                  child: SafeArea(child: _buildContent()),
                ),
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
              onPressed: () => _shopComponent.refresh(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _shopComponent.refresh(),
      color: VcomColors.oroLujoso,
      backgroundColor: const Color(0xFF1a2847),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
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

          // Grid de productos
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _buildProductsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Buscar artículos...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.38),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.5),
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _shopComponent.searchProducts('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (value) => _shopComponent.searchProducts(value),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip(null, 'Todos los Artículos'),
          ..._shopComponent.categories.map(
            (c) => _buildCategoryChip(c.idCategory, c.nameCategory),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(int? categoryId, String label) {
    final isSelected = _shopComponent.selectedCategoryId == categoryId;
    return GestureDetector(
      onTap: () => _shopComponent.filterByCategory(categoryId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? VcomColors.oroLujoso : const Color(0xFFD4D4D8),
            width: 0.6,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? VcomColors.oroLujoso : const Color(0xFFD4D4D8),
          ),
        ),
      ),
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
              Icon(
                Icons.search_off,
                size: 64,
                color: VcomColors.oroLujoso.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron productos',
                style: TextStyle(
                  fontSize: 16,
                  color: VcomColors.blancoCrema.withValues(alpha: 0.7),
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
        childAspectRatio: 0.58,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        return _buildProductCard(_shopComponent.products[index]);
      }, childCount: _shopComponent.products.length),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final primaryImage = product.images.isNotEmpty
        ? product.images.firstWhere(
            (img) => img.isPrimary,
            orElse: () => product.images.first,
          )
        : null;

    final categoryName =
        product.category?.nameCategory ?? product.brand?.nameBrand ?? '';

    return GestureDetector(
      onTap: () => _openProduct(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: VcomColors.oroLujoso.withValues(alpha: 0.35),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen con botón de carrito superpuesto ──────────────────────
            Expanded(
              flex: 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: primaryImage != null
                        ? Image.network(
                            primaryImage.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                  // Degradado inferior suave
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(4),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Botón carrito
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openProduct(product),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: VcomColors.oroLujoso.withValues(
                                alpha: 0.4,
                              ),
                              width: 0.8,
                            ),
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info del producto ─────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Categoría
                    if (categoryName.isNotEmpty)
                      Text(
                        categoryName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          color: VcomColors.oroLujoso,
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Nombre
                    Text(
                      product.nameProduct,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: VcomColors.blancoCrema,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Precio
                    Text(
                      _formatPrice(product.priceCop),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55),
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

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFF1a2847),
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}
