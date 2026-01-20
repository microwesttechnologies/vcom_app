import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/components/shared/sidebar.component.dart';
import 'package:vcom_app/components/commons/button.dart';
import 'package:vcom_app/pages/shop/shop.component.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.component.dart';
import 'package:vcom_app/pages/categories/managerCategory.page.dart';
import 'package:vcom_app/pages/brands/managerBrand.page.dart';
import 'package:vcom_app/pages/products/manage/managerProduct.page.dart';
import 'package:vcom_app/pages/chat/chat.page.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/core/models/module.model.dart';
import 'package:vcom_app/core/common/icon.helper.dart';
import 'package:vcom_app/style/vcom_colors.dart';
import 'package:intl/intl.dart';

/// Página de detalle del producto
class ProductDetailPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ShopComponent _shopComponent;
  late DashboardComponent _dashboardComponent;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _shopComponent = ShopComponent();
    _shopComponent.addListener(_onComponentChanged);
    
    _dashboardComponent = DashboardComponent();
    _dashboardComponent.addListener(_onComponentChanged);
    _dashboardComponent.fetchModules();
  }

  @override
  void dispose() {
    _shopComponent.removeListener(_onComponentChanged);
    _dashboardComponent.removeListener(_onComponentChanged);
    _pageController.dispose();
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

  Future<void> _contactWhatsApp() async {
    try {
      await _shopComponent.contactWhatsApp(widget.product);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir WhatsApp: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ProductImageModel> images = widget.product.images.isNotEmpty 
        ? widget.product.images 
        : <ProductImageModel>[]; // Lista vacía si no hay imágenes

    return Scaffold(
      appBar: NavbarComponent(
        title: widget.product.nameProduct,
        showBackButton: true,
        showMenuButton: false,
        backgroundColor: VcomColors.azulZafiroProfundo,
        topBarActions: [],
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Galería de imágenes
                _buildImageGallery(images),
                
                // Información del producto
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del producto
                      Text(
                        widget.product.nameProduct,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: VcomColors.blancoCrema,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Marca
                      if (widget.product.brand != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: VcomColors.oroLujoso.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: VcomColors.oroLujoso.withOpacity(0.5)),
                          ),
                          child: Text(
                            widget.product.brand!.nameBrand,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: VcomColors.oroBrillante,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Precio
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: VcomColors.azulZafiroProfundo,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VcomColors.oroLujoso.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: VcomColors.oroLujoso,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Precio',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: VcomColors.blancoCrema.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  _formatPrice(widget.product.priceCop),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: VcomColors.oroLujoso,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Stock
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.product.stock > 5 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.product.stock > 5 
                                ? Colors.green.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.product.stock > 5 ? Icons.check_circle : Icons.warning,
                              color: widget.product.stock > 5 ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.product.stock > 5 
                                  ? 'Disponible (${widget.product.stock} unidades)'
                                  : 'Pocas unidades (${widget.product.stock} disponibles)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: widget.product.stock > 5 ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // SKU
                      if (widget.product.sku != null && widget.product.sku!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: VcomColors.azulOverlayTransparente60,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.qr_code, color: VcomColors.blancoCrema.withOpacity(0.7)),
                              const SizedBox(width: 12),
                              Text(
                                'SKU: ${widget.product.sku}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: VcomColors.blancoCrema.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 32),
                      
                      // Descripción
                      if (widget.product.descriptionProduct != null && 
                          widget.product.descriptionProduct!.isNotEmpty) ...[
                        Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: VcomColors.blancoCrema,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: VcomColors.azulZafiroProfundo,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: VcomColors.oroLujoso.withOpacity(0.3)),
                          ),
                          child: Text(
                            widget.product.descriptionProduct!,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: VcomColors.blancoCrema,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      // Botón de WhatsApp
                      SizedBox(
                        width: double.infinity,
                        child: ButtonComponent(
                          label: 'Consultar por WhatsApp',
                          size: ButtonSize.large,
                          color: const Color(0xFF25D366), // Color de WhatsApp
                          textColor: Colors.white,
                          icon: Icons.chat,
                          onPressed: _contactWhatsApp,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Información adicional
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: VcomColors.azulOverlayTransparente60,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: VcomColors.oroLujoso, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Al consultar por WhatsApp recibirás:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: VcomColors.blancoCrema,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoItem('• Información detallada del producto'),
                            _buildInfoItem('• Disponibilidad actualizada'),
                            _buildInfoItem('• Opciones de pago y envío'),
                            _buildInfoItem('• Atención personalizada'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<ProductImageModel> images) {
    if (images.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        color: Colors.grey[200],
        child: Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.grey[400],
        ),
      );
    }

    return Column(
      children: [
        // Imagen principal
        Container(
          height: 400,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: Image.network(
                  images[index].imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        
        // Indicadores de imagen
        if (images.length > 1) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? VcomColors.oroLujoso
                        : VcomColors.blancoCrema.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
        
        // Miniaturas
        if (images.length > 1) ...[
          const SizedBox(height: 16),
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final isSelected = _currentImageIndex == index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? VcomColors.oroLujoso : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        images[index].imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image,
                              size: 24,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: VcomColors.blancoCrema.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
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
}
