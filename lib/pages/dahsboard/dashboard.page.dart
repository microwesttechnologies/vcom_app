import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/components/shared/sidebar.component.dart';
import 'package:vcom_app/components/commons/card.component.dart';
import 'package:vcom_app/core/common/icon.helper.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.component.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/pages/categories/managerCategory.page.dart';
import 'package:vcom_app/pages/brands/managerBrand.page.dart';
import 'package:vcom_app/pages/products/manage/managerProduct.page.dart';
import 'package:vcom_app/pages/chat/chat.page.dart';
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

  @override
  void initState() {
    super.initState();
    _dashboardComponent = DashboardComponent();
    _dashboardComponent.addListener(_onComponentChanged);
    _dashboardComponent.fetchModules();
  }

  @override
  void dispose() {
    _dashboardComponent.removeListener(_onComponentChanged);
    super.dispose();
  }

  void _onComponentChanged() {
    setState(() {});
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
            SidebarItem(
              label: 'Tienda',
              icon: Icons.store,
              isSelected: _selectedIndex == 4,
              onTap: () {
                Navigator.pop(context);
                _navigateToModule('/shop');
              },
            ),
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
        decoration: const BoxDecoration(gradient: VcomColors.gradienteNocturno),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildContent(),
          ),
        ),
      ),
      // // 🧪 BOTÓN DE PRUEBA (TEMPORAL)
      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: Colors.green,
      //   icon: const Icon(Icons.send),
      //   label: const Text('Enviar test'),
      //   onPressed: _sendTestMessage,
      // ),
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
    } else if (routeLower.contains('training') || routeLower.contains('entrenamiento')) {
      targetPage = const TrainingPage();
    }

    if (targetPage != null) {
      Navigator.push(
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
                color: VcomColors.blancoCrema.withOpacity(0.7),
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
