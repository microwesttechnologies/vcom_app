import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/components/shared/sidebar.component.dart';
import 'package:vcom_app/components/commons/card.component.dart';
import 'package:vcom_app/core/common/icon.helper.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.component.dart';
import 'package:vcom_app/pages/dahsboard/dashboard_modelo.component.dart';
import 'package:vcom_app/pages/dahsboard/dashboard_modelo.view.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/pages/categories/managerCategory.page.dart';
import 'package:vcom_app/pages/brands/managerBrand.page.dart';
import 'package:vcom_app/pages/products/manage/managerProduct.page.dart';
import 'package:vcom_app/pages/chat/chat.page.dart';
import 'package:vcom_app/pages/events/events.page.dart';
import 'package:vcom_app/pages/training/training.page.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página del dashboard
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late DashboardComponent _dashboardComponent;
  late DashboardModeloComponent _dashboardModeloComponent;
  final TokenService _tokenService = TokenService();

  bool get _usesModeloDashboard {
    final role = _tokenService.getRole()?.toUpperCase() ?? '';
    return role == 'MODELO' || role == 'MODAL' || role == 'MONITOR';
  }

  @override
  void initState() {
    super.initState();
    _dashboardComponent = DashboardComponent();
    _dashboardComponent.addListener(_onComponentChanged);
    _dashboardModeloComponent = DashboardModeloComponent();
    _dashboardModeloComponent.addListener(_onComponentChanged);

    if (_usesModeloDashboard) {
      _dashboardModeloComponent.initialize();
    } else {
      _dashboardComponent.fetchModules();
    }
  }

  @override
  void dispose() {
    _dashboardComponent.removeListener(_onComponentChanged);
    _dashboardModeloComponent.removeListener(_onComponentChanged);
    super.dispose();
  }

  void _onComponentChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _usesModeloDashboard ? const Color(0xFF000000) : null,
      extendBodyBehindAppBar: _usesModeloDashboard,
      extendBody: _usesModeloDashboard,
      appBar: const ModeloNavbar(),
      drawer: Drawer(
        child: SidebarComponent(
          items: [
            SidebarItem(
              label: 'Dashboard',
              icon: Icons.dashboard,
              isSelected: _selectedIndex == 0,
              onTap: () {
                // Si ya estás en el dashboard, solo cierra el drawer
                Navigator.of(context).pop();
              },
            ),
            SidebarItem(
              label: 'Perfil',
              icon: Icons.person,
              isSelected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            SidebarItem(
              label: 'Configuración',
              icon: Icons.settings,
              isSelected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            SidebarItem(
              label: 'Notificaciones',
              icon: Icons.notifications,
              badge: '3',
              isSelected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            // SidebarItem(
            //   label: 'Tienda',
            //   icon: Icons.store,
            //   isSelected: _selectedIndex == 4,
            //   onTap: () {
            //     Navigator.pop(context);
            //     _navigateToModule('/shop');
            //   },
            // ),
            SidebarItem(
              label: 'Ayuda',
              icon: Icons.help,
              isSelected: _selectedIndex == 5,
              onTap: () {
                setState(() => _selectedIndex = 5);
                Navigator.pop(context);
              },
            ),
          ],
          selectedIndex: _selectedIndex,
          onItemSelected: (index) {
            // No actualizar el estado si ya estás en esa página
            if (_selectedIndex != index) {
              setState(() => _selectedIndex = index);
            }
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _usesModeloDashboard
            ? const BoxDecoration(
                color: Color(0xFF000000),
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
              )
            : const BoxDecoration(gradient: VcomColors.gradienteNocturno),
        child: SafeArea(
          bottom: false,
          child: _usesModeloDashboard
              ? _buildContent()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildContent(),
                ),
        ),
      ),
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'dashboard'),
    );
  }

  /// Navega a la ruta del módulo
  void _navigateToModule(String route) {
    final routeLower = route.toLowerCase();
    Widget? targetPage;

    // Mapear rutas a páginas
    if (routeLower.contains('dashboard') || routeLower.contains('inicio')) {
      // Ya estamos en el dashboard
      return;
    } else if (routeLower.contains('categories') ||
        routeLower.contains('categoria')) {
      targetPage = const ManagerCategoryPage();
    } else if (routeLower.contains('brand') || routeLower.contains('marca')) {
      targetPage = const ManagerBrandPage();
    } else if (routeLower.contains('product') ||
        routeLower.contains('producto')) {
      targetPage = const ManagerProductPage();
    } else if (routeLower.contains('shop') ||
        routeLower.contains('tienda') ||
        routeLower.contains('store')) {
      targetPage = const ShopPage();
    } else if (routeLower.contains('chat') || routeLower.contains('mensaje')) {
      targetPage = const ChatPage();
    } else if (routeLower.contains('event') ||
        routeLower.contains('evento') ||
        routeLower.contains('calendar') ||
        routeLower.contains('calendario')) {
      targetPage = const EventsPage();
    } else if (routeLower.contains('training') ||
        routeLower.contains('entrenamiento')) {
      targetPage = const TrainingPage();
    }

    if (targetPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetPage!),
      );
    } else {
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
                    'Módulo en desarrollo',
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

  Widget _buildContent() {
    if (_usesModeloDashboard) {
      return _buildModeloContent();
    }
    return _buildDefaultContent();
  }

  Widget _buildModeloContent() {
    if (_dashboardModeloComponent.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }
    return DashboardModeloView(component: _dashboardModeloComponent);
  }

  Widget _buildDefaultContent() {
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _dashboardComponent.error!,
              style: TextStyle(
                fontSize: 14,
                color: VcomColors.blancoCrema.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _dashboardComponent.fetchModules(),
              style: ElevatedButton.styleFrom(
                backgroundColor: VcomColors.oroLujoso,
                foregroundColor: VcomColors.azulMedianocheTexto,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_dashboardComponent.modules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 64, color: VcomColors.oroLujoso),
            const SizedBox(height: 16),
            Text(
              'No hay módulos disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _dashboardComponent.modules.length,
      itemBuilder: (context, index) {
        final module = _dashboardComponent.modules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: CardComponent(
            label: module.nameModule,
            description: module.descriptionModule,
            icon: IconHelper.getIconFromString(module.icon),
            size: CardSize.medium,
            width: double.infinity,
            onTap: () {
              _navigateToModule(module.route);
            },
          ),
        );
      },
    );
  }
}
