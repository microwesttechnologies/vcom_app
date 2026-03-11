import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/menubar.component.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/pages/chat/chat.page.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/pages/training/training.page.dart';
import 'package:vcom_app/pages/wallet/wallet.page.dart';

/// Menú inferior estándar para el rol MODELO con navegación lista.
///
/// Pasa [activeIndex] para resaltar el ítem de la página actual:
///   0 = STORE, 1 = TRAINING, 2 = CALENDAR,
///   3 = MY WALLET, 4 = HUB, 5 = CHAT
///   -1 (default) = ninguno activo (ej. Dashboard)
///
/// ```dart
/// bottomNavigationBar: const ModeloMenuBar(activeIndex: 3), // MY WALLET activo
/// ```
class ModeloMenuBar extends StatelessWidget {
  final int activeIndex;
  const ModeloMenuBar({super.key, this.activeIndex = -1});

  @override
  Widget build(BuildContext context) {
    final role = TokenService().getRole();
    if (role?.toUpperCase() != 'MODELO') return const SizedBox.shrink();

    return MenuBarComponent(
      activeIndex: activeIndex,
      items: [
        MenuBarItem(
          icon: Icons.shopping_bag,
          label: 'STORE',
          onTap: () => _pushIfNotCurrent<ShopPage>(
            context,
            () => const ShopPage(),
          ),
        ),
        MenuBarItem(
          icon: Icons.diamond_outlined,
          label: 'TRAINING',
          onTap: () => _pushIfNotCurrent<TrainingPage>(
            context,
            () => const TrainingPage(),
          ),
        ),
        MenuBarItem(
          icon: Icons.event,
          label: 'CALENDAR',
          onTap: () {},
        ),
        MenuBarItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'MY WALLET',
          onTap: () => _pushIfNotCurrent<WalletPage>(
            context,
            () => const WalletPage(),
          ),
        ),
        MenuBarItem(
          icon: Icons.grid_view,
          label: 'HUB',
          onTap: () {},
        ),
        MenuBarItem(
          icon: Icons.forum_outlined,
          label: 'CHAT',
          onTap: () => _pushIfNotCurrent<ChatPage>(
            context,
            () => const ChatPage(),
          ),
        ),
      ],
    );
  }

  void _pushIfNotCurrent<T extends Widget>(
    BuildContext context,
    Widget Function() builder,
  ) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        settings: RouteSettings(name: T.toString()),
        pageBuilder: (_, __, ___) => builder(),
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => route.isFirst,
    );
  }
}
