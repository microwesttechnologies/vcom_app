import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/menubar.component.dart';
import 'package:vcom_app/core/common/permission.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/module.model.dart';
import 'package:vcom_app/pages/chat/chat.page.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';
import 'package:vcom_app/pages/events/events.page.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/pages/training/training.page.dart';
import 'package:vcom_app/pages/wallet/wallet.page.dart';

class ModeloMenuBar extends StatelessWidget {
  final int activeIndex;
  final String? activeRoute;

  const ModeloMenuBar({
    super.key,
    this.activeIndex = -1,
    this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    final role = TokenService().getRole()?.toUpperCase() ?? '';
    final usesModeloMenu =
        role == 'MODELO' || role == 'MODAL' || role == 'MONITOR';
    if (!usesModeloMenu) return const SizedBox.shrink();

    final permissionService = PermissionService();
    final entries = _resolveEntries(permissionService);
    if (entries.isEmpty) return const SizedBox.shrink();

    final resolvedActiveIndex = _resolveActiveIndex(entries);

    return MenuBarComponent(
      activeIndex: resolvedActiveIndex,
      items: entries
          .map(
            (entry) => MenuBarItem(
              icon: entry.icon,
              label: entry.label,
              onTap: () => entry.onTap(context),
            ),
          )
          .toList(growable: false),
    );
  }

  int _resolveActiveIndex(List<_ModeloMenuEntry> entries) {
    if (activeRoute == null || activeRoute!.trim().isEmpty) {
      return activeIndex >= 0 && activeIndex < entries.length ? activeIndex : -1;
    }

    final normalizedActiveRoute = activeRoute!.trim().toLowerCase();
    return entries.indexWhere(
      (entry) => entry.hints.any(
        (hint) => normalizedActiveRoute.contains(hint) || hint.contains(normalizedActiveRoute),
      ),
    );
  }

  List<_ModeloMenuEntry> _resolveEntries(PermissionService permissionService) {
    final candidates = <_ModeloMenuCandidate>[
      _ModeloMenuCandidate(
        label: 'STORE',
        icon: Icons.shopping_bag,
        routeHints: const ['shop', 'tienda', 'store'],
        onTap: (context) => _pushIfNotCurrent<ShopPage>(
              context,
              () => const ShopPage(),
            ),
      ),
      _ModeloMenuCandidate(
        label: 'TRAINING',
        icon: Icons.diamond_outlined,
        routeHints: const ['training', 'entrenamiento'],
        onTap: (context) => _pushIfNotCurrent<TrainingPage>(
              context,
              () => const TrainingPage(),
            ),
      ),
      _ModeloMenuCandidate(
        label: 'CALENDAR',
        icon: Icons.event,
        routeHints: const ['event', 'evento', 'calendar', 'calendario'],
        onTap: (context) => _pushIfNotCurrent<EventsPage>(
              context,
              () => const EventsPage(),
            ),
      ),
      _ModeloMenuCandidate(
        label: 'MY WALLET',
        icon: Icons.account_balance_wallet_outlined,
        routeHints: const ['wallet', 'cartera'],
        onTap: (context) => _pushIfNotCurrent<WalletPage>(
              context,
              () => const WalletPage(),
            ),
      ),
      _ModeloMenuCandidate(
        label: 'HUB',
        icon: Icons.grid_view,
        routeHints: const ['hub', 'dashboard', 'inicio'],
        onTap: (context) => _pushIfNotCurrent<DashboardPage>(
              context,
              () => const DashboardPage(),
            ),
      ),
      _ModeloMenuCandidate(
        label: 'CHAT',
        icon: Icons.forum_outlined,
        routeHints: const ['chat', 'mensaje'],
        onTap: (context) => _pushIfNotCurrent<ChatPage>(
              context,
              () => const ChatPage(),
            ),
      ),
    ];

    final entries = <_ModeloMenuEntry>[];
    for (final candidate in candidates) {
      final module = permissionService.findModule(routeHints: candidate.routeHints);
      if (module == null || !module.state || !module.permissions.read) {
        continue;
      }

      entries.add(
        _ModeloMenuEntry(
          label: candidate.label,
          icon: candidate.icon,
          hints: candidate.routeHints,
          module: module,
          onTap: candidate.onTap,
        ),
      );
    }

    return entries;
  }

  void _pushIfNotCurrent<T extends Widget>(
    BuildContext context,
    Widget Function() builder,
  ) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        settings: RouteSettings(name: T.toString()),
        pageBuilder: (_, animation, secondaryAnimation) => builder(),
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => route.isFirst,
    );
  }
}

class _ModeloMenuCandidate {
  final String label;
  final IconData icon;
  final List<String> routeHints;
  final void Function(BuildContext context) onTap;

  const _ModeloMenuCandidate({
    required this.label,
    required this.icon,
    required this.routeHints,
    required this.onTap,
  });
}

class _ModeloMenuEntry {
  final String label;
  final IconData icon;
  final List<String> hints;
  final ModuleModel module;
  final void Function(BuildContext context) onTap;

  const _ModeloMenuEntry({
    required this.label,
    required this.icon,
    required this.hints,
    required this.module,
    required this.onTap,
  });
}
