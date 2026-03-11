import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Ítem individual del menú inferior.
class MenuBarItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const MenuBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Menú inferior glass reutilizable en toda la app.
///
/// Uso básico:
/// ```dart
/// bottomNavigationBar: MenuBarComponent(
///   items: [...],
///   activeIndex: 2, // ítem activo (dorado)
/// )
/// ```
class MenuBarComponent extends StatelessWidget {
  final List<MenuBarItem> items;
  final int activeIndex;

  const MenuBarComponent({
    super.key,
    required this.items,
    this.activeIndex = -1,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(2, 2, 2, 2 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              // border: Border.all(color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: List.generate(
                  items.length,
                  (i) => _MenuBarItemWidget(
                    item: items[i],
                    isActive: i == activeIndex,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuBarItemWidget extends StatelessWidget {
  final MenuBarItem item;
  final bool isActive;

  const _MenuBarItemWidget({required this.item, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? VcomColors.oroLujoso : Colors.white.withValues(alpha: 1);

    return Expanded(
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: color,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
