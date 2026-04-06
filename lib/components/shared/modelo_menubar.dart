import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/menubar.component.dart';
import 'package:vcom_app/pages/chat/chat.page.dart';
import 'package:vcom_app/pages/events/events.page.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/pages/training/training.page.dart';
import 'package:vcom_app/pages/wallet/wallet.page.dart';

class ModeloMenuBar extends StatelessWidget {
  final int activeIndex;
  final String? activeRoute;

  const ModeloMenuBar({super.key, this.activeIndex = -1, this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final entries = <_ModeloMenuEntry>[
      _ModeloMenuEntry(
        label: 'STORE',
        icon: Icons.shopping_bag,
        hints: const ['shop', 'tienda', 'store'],
        onTap: (context) =>
            _pushIfNotCurrent<ShopPage>(context, () => const ShopPage()),
      ),
      _ModeloMenuEntry(
        label: 'TRAINING',
        icon: Icons.diamond_outlined,
        hints: const ['training', 'entrenamiento'],
        onTap: (context) => _pushIfNotCurrent<TrainingPage>(
          context,
          () => const TrainingPage(),
        ),
      ),
      _ModeloMenuEntry(
        label: 'CALENDAR',
        icon: Icons.event,
        hints: const ['event', 'evento', 'calendar', 'calendario'],
        onTap: (context) =>
            _pushIfNotCurrent<EventsPage>(context, () => const EventsPage()),
      ),
      _ModeloMenuEntry(
        label: 'MY WALLET',
        icon: Icons.account_balance_wallet_outlined,
        hints: const ['wallet', 'cartera', 'billetera'],
        onTap: (context) =>
            _pushIfNotCurrent<WalletPage>(context, () => const WalletPage()),
      ),
      _ModeloMenuEntry(
        label: 'CHAT',
        icon: Icons.forum_outlined,
        hints: const ['chat', 'mensaje', 'mensajes'],
        onTap: (context) =>
            _pushIfNotCurrent<ChatPage>(context, () => const ChatPage()),
      ),
    ];

    return MenuBarComponent(
      activeIndex: _resolveActiveIndex(entries),
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
      return activeIndex >= 0 && activeIndex < entries.length
          ? activeIndex
          : -1;
    }

    final normalizedActiveRoute = activeRoute!.trim().toLowerCase();
    return entries.indexWhere(
      (entry) => entry.hints.any(
        (hint) =>
            normalizedActiveRoute.contains(hint) ||
            hint.contains(normalizedActiveRoute),
      ),
    );
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

class _ModeloMenuEntry {
  final String label;
  final IconData icon;
  final List<String> hints;
  final void Function(BuildContext context) onTap;

  const _ModeloMenuEntry({
    required this.label,
    required this.icon,
    required this.hints,
    required this.onTap,
  });
}
