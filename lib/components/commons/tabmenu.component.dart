import 'package:flutter/material.dart';

/// Modelo para los items del tab menu
class TabMenuItem {
  /// Etiqueta del item del menú
  final String label;

  /// Icono del item del menú
  final IconData icon;

  /// Callback cuando se presiona el item
  final VoidCallback? onTap;

  /// Si el item está seleccionado
  final bool isSelected;

  /// Badge (notificación) para mostrar en el item
  final String? badge;

  /// Color personalizado del icono cuando está seleccionado
  final Color? selectedIconColor;

  /// Color personalizado del icono cuando no está seleccionado
  final Color? unselectedIconColor;

  /// Color personalizado del texto cuando está seleccionado
  final Color? selectedLabelColor;

  /// Color personalizado del texto cuando no está seleccionado
  final Color? unselectedLabelColor;

  const TabMenuItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.isSelected = false,
    this.badge,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.selectedLabelColor,
    this.unselectedLabelColor,
  });
}

/// Componente de tab menu inferior (bottom navigation bar) reutilizable
/// Similar al que usan las aplicaciones móviles modernas
class TabMenuComponent extends StatelessWidget {
  /// Lista de items del menú (máximo 5)
  final List<TabMenuItem> items;

  /// Color de fondo del tab menu
  final Color? backgroundColor;

  /// Altura del tab menu
  final double? height;

  /// Tipo de visualización del texto (siempre visible, solo cuando está seleccionado, etc.)
  final BottomNavigationBarType type;

  /// Radio de las esquinas superiores
  final double? topBorderRadius;

  /// Espaciado entre icono y texto
  final double? iconLabelSpacing;

  /// Tamaño del icono
  final double? iconSize;

  /// Tamaño de fuente del label
  final double? fontSize;

  /// Constructor del componente
  const TabMenuComponent({
    super.key,
    required this.items,
    this.backgroundColor,
    this.height,
    this.type = BottomNavigationBarType.fixed,
    this.topBorderRadius,
    this.iconLabelSpacing,
    this.iconSize,
    this.fontSize,
  }) : assert(items.length <= 5, 'El tab menu no puede tener más de 5 items');

  /// Construye los items del BottomNavigationBar
  List<BottomNavigationBarItem> _buildBottomNavItems(
    BuildContext context,
    List<TabMenuItem> menuItems,
    Color selectedColor,
    Color unselectedColor,
  ) {
    return menuItems.map((item) {
      Widget iconWidget = Icon(
        item.icon,
        size: iconSize ?? 24.0,
        color: item.isSelected
            ? (item.selectedIconColor ?? selectedColor)
            : (item.unselectedIconColor ?? unselectedColor),
      );

      // Agregar badge si existe
      if (item.badge != null) {
        iconWidget = Stack(
          clipBehavior: Clip.none,
          children: [
            iconWidget,
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return BottomNavigationBarItem(
        icon: iconWidget,
        label: item.label,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.surface;

    // Validar que no haya más de 5 items
    if (items.length > 5) {
      throw ArgumentError(
        'El tab menu no puede tener más de 5 items. Se proporcionaron ${items.length} items.',
      );
    }

    // Validar que haya al menos un item
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Encontrar el índice del item seleccionado
    int selectedIndex = items.indexWhere((item) => item.isSelected);
    if (selectedIndex == -1 && items.isNotEmpty) {
      selectedIndex = 0; // Por defecto seleccionar el primero
    }

    // Obtener los colores del tema
    final selectedColor = items[selectedIndex].selectedIconColor ??
        theme.colorScheme.primary;
    final unselectedColor = items[selectedIndex].unselectedIconColor ??
        theme.colorScheme.onSurface.withOpacity(0.6);

    // Construir los items del BottomNavigationBar
    final bottomNavItems =
        _buildBottomNavItems(context, items, selectedColor, unselectedColor);

    Widget tabMenu = BottomNavigationBar(
      items: bottomNavItems,
      currentIndex: selectedIndex,
      onTap: (index) {
        if (index >= 0 && index < items.length && items[index].onTap != null) {
          items[index].onTap!();
        }
      },
      type: items.length > 3
          ? BottomNavigationBarType.fixed
          : type, // Forzar fixed si hay más de 3 items
      backgroundColor: effectiveBackgroundColor,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      selectedLabelStyle: TextStyle(
        fontSize: fontSize ?? 12.0,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: fontSize ?? 12.0,
        fontWeight: FontWeight.normal,
      ),
      iconSize: iconSize ?? 24.0,
      elevation: 8.0,
      showSelectedLabels: true,
      showUnselectedLabels: items.length <= 3,
    );

    // Agregar border radius superior si se especifica
    if (topBorderRadius != null && topBorderRadius! > 0) {
      tabMenu = ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topBorderRadius!),
          topRight: Radius.circular(topBorderRadius!),
        ),
        child: tabMenu,
      );
    }

    // Agregar altura personalizada si se especifica
    if (height != null) {
      tabMenu = SizedBox(
        height: height,
        child: tabMenu,
      );
    }

    return tabMenu;
  }
}

