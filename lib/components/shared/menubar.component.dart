import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Modelo para los items del menubar
class MenubarItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final VoidCallback? onTap;

  const MenubarItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.onTap,
  });
}

/// Componente de menubar (barra de menú inferior) reutilizable
class MenubarComponent extends StatelessWidget {
  /// Lista de items del menubar
  final List<MenubarItem> items;

  /// Índice del item seleccionado (tab actual)
  final int selectedIndex;

  /// Color de fondo del menubar
  final Color? backgroundColor;

  /// Color del item seleccionado
  final Color? selectedColor;

  /// Color del texto del item seleccionado
  final Color? selectedTextColor;

  /// Color de los items no seleccionados
  final Color? unselectedColor;

  /// Color del texto de los items no seleccionados
  final Color? unselectedTextColor;

  /// Altura del menubar
  final double? height;

  /// Callback cuando se selecciona un item (cambia el tab)
  final ValueChanged<int>? onItemSelected;

  /// Tipo de menubar (fixed o shifting)
  final BottomNavigationBarType type;

  /// Constructor del componente
  const MenubarComponent({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.backgroundColor,
    this.selectedColor,
    this.selectedTextColor,
    this.unselectedColor,
    this.unselectedTextColor,
    this.height,
    this.onItemSelected,
    this.type = BottomNavigationBarType.fixed,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ?? VcomColors.azulZafiroProfundo;
    final effectiveSelectedColor =
        selectedColor ?? VcomColors.oroLujoso;
    final effectiveSelectedTextColor =
        selectedTextColor ?? VcomColors.azulMedianocheTexto;
    final effectiveUnselectedColor =
        unselectedColor ?? VcomColors.blancoCrema.withOpacity(0.6);
    final effectiveUnselectedTextColor =
        unselectedTextColor ?? VcomColors.blancoCrema.withOpacity(0.6);

    return Container(
      height: height ?? 60,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
          (index) {
            final item = items[index];
            final isSelected = selectedIndex == index;

            return Expanded(
              child: InkWell(
                onTap: () {
                  item.onTap?.call();
                  onItemSelected?.call(index);
                },
                child: Container(
                  height: height ?? 60,
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected
                            ? (item.selectedIcon ?? item.icon)
                            : item.icon,
                        color: isSelected
                            ? effectiveSelectedColor
                            : effectiveUnselectedColor,
                        size: isSelected ? 28 : 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: isSelected ? 12 : 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? effectiveSelectedTextColor
                              : effectiveUnselectedTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

