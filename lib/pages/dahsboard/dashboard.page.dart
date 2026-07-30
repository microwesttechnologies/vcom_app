import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/dynamic_sidebar_drawer.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/core/chat/chat_push.service.dart';
import 'package:vcom_app/pages/dahsboard/dashboard_modelo.component.dart';
import 'package:vcom_app/pages/dahsboard/dashboard_modelo.view.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Inicio unico para modelos y monitores (misma experiencia visual).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardModeloComponent _dashboardModeloComponent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatPushService().markAppShellReady();
    });
    _dashboardModeloComponent = DashboardModeloComponent();
    _dashboardModeloComponent.addListener(_onComponentChanged);
    _dashboardModeloComponent.initialize();
  }

  @override
  void dispose() {
    _dashboardModeloComponent.removeListener(_onComponentChanged);
    super.dispose();
  }

  void _onComponentChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const ModeloNavbar(),
      drawer: const Drawer(
        child: DynamicSidebarDrawer(selectedRouteHints: ['dashboard', 'inicio']),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
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
        ),
        child: SafeArea(
          bottom: false,
          child: _buildContent(),
        ),
      ),
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'dashboard'),
    );
  }

  Widget _buildContent() {
    if (_dashboardModeloComponent.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }
    return DashboardModeloView(component: _dashboardModeloComponent);
  }
}
