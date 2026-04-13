import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/sidebar.component.dart';
import 'package:vcom_app/core/common/icon.helper.dart';
import 'package:vcom_app/core/common/permission.service.dart';
import 'package:vcom_app/core/models/module.model.dart';
import 'package:vcom_app/pages/brands/managerBrand.page.dart';
import 'package:vcom_app/pages/categories/managerCategory.page.dart';
import 'package:vcom_app/pages/chat/chat.page.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';
import 'package:vcom_app/pages/events/events.page.dart';
import 'package:vcom_app/pages/hub/hub.page.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/pages/training/training.page.dart';
import 'package:vcom_app/pages/wallet/wallet.page.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class DynamicSidebarDrawer extends StatefulWidget {
  final List<String> selectedRouteHints;

  const DynamicSidebarDrawer({super.key, required this.selectedRouteHints});

  @override
  State<DynamicSidebarDrawer> createState() => _DynamicSidebarDrawerState();
}

class _DynamicSidebarDrawerState extends State<DynamicSidebarDrawer> {
  final PermissionService _permissionService = PermissionService();
  List<ModuleModel> _modules = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final modules = await _permissionService.loadPermissions(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      setState(() {
        _modules = modules;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _modules = const [];
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: VcomColors.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar módulos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VcomColors.blancoCrema,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 14,
                  color: VcomColors.blancoCrema.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _loadModules(forceRefresh: true),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final items = <SidebarItem>[
      SidebarItem(
        label: 'Dashboard',
        icon: Icons.dashboard,
        isSelected: _isDashboardSelected,
        onTap: () => _navigateToDashboard(context),
      ),
      ..._modules
          .where((module) => module.state && module.permissions.read)
          .where(
            (module) =>
                !_normalize(module.route).contains('product') &&
                !_normalize(module.route).contains('producto'),
          )
          .map(
            (module) => SidebarItem(
              label: module.nameModule,
              icon: IconHelper.getIconFromString(module.icon),
              isSelected: _matchesCurrentModule(module),
              onTap: () => _navigateToModule(context, module),
            ),
          ),
    ];

    return SidebarComponent(
      items: items,
      selectedIndex: _resolveSelectedIndex(items),
      onItemSelected: (_) {},
    );
  }

  bool get _isDashboardSelected => widget.selectedRouteHints.any((hint) {
    final normalized = _normalize(hint);
    return normalized.contains('dashboard') || normalized.contains('inicio');
  });

  int _resolveSelectedIndex(List<SidebarItem> items) {
    final selectedIndex = items.indexWhere((item) => item.isSelected);
    return selectedIndex >= 0 ? selectedIndex : 0;
  }

  bool _matchesCurrentModule(ModuleModel module) {
    final route = _normalize(module.route);
    final name = _normalize(module.nameModule);

    for (final hint in widget.selectedRouteHints) {
      final normalizedHint = _normalize(hint);
      if (normalizedHint.isEmpty) continue;
      if (route.contains(normalizedHint) || name.contains(normalizedHint)) {
        return true;
      }
    }

    return false;
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.of(context).pop();
    if (_isDashboardSelected) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardPage()));
  }

  void _navigateToModule(BuildContext context, ModuleModel module) {
    Navigator.of(context).pop();
    if (_matchesCurrentModule(module)) return;

    final page = _resolvePage(module.route);
    if (page == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${module.nameModule} está en desarrollo'),
          backgroundColor: VcomColors.oroLujoso,
        ),
      );
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  Widget? _resolvePage(String route) {
    final normalizedRoute = _normalize(route);

    if (normalizedRoute.contains('dashboard') ||
        normalizedRoute.contains('inicio')) {
      return const DashboardPage();
    }
    if (normalizedRoute.contains('category') ||
        normalizedRoute.contains('categoria')) {
      return const ManagerCategoryPage();
    }
    if (normalizedRoute.contains('brand') ||
        normalizedRoute.contains('marca')) {
      return const ManagerBrandPage();
    }
    if (normalizedRoute.contains('shop') ||
        normalizedRoute.contains('tienda') ||
        normalizedRoute.contains('store')) {
      return const ShopPage();
    }
    if (normalizedRoute.contains('chat') ||
        normalizedRoute.contains('mensaje')) {
      return const ChatPage();
    }
    if (normalizedRoute.contains('event') ||
        normalizedRoute.contains('evento') ||
        normalizedRoute.contains('calendar') ||
        normalizedRoute.contains('calendario')) {
      return const EventsPage();
    }
    if (normalizedRoute.contains('training') ||
        normalizedRoute.contains('entrenamiento')) {
      return const TrainingPage();
    }
    if (normalizedRoute.contains('wallet') ||
        normalizedRoute.contains('cartera')) {
      return const WalletPage();
    }
    if (normalizedRoute.contains('hub') ||
        normalizedRoute.contains('feed') ||
        normalizedRoute.contains('chisme')) {
      return const HubPage();
    }

    return null;
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
