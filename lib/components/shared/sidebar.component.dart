import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/style/vcom_colors.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/pages/auth/login.page.dart';
import 'package:vcom_app/core/common/user_status.service.dart';

/// Modelo para los items del sidebar
class SidebarItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isSelected;
  final String? badge;

  const SidebarItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.isSelected = false,
    this.badge,
  });
}

/// Componente de sidebar reutilizable
class SidebarComponent extends StatelessWidget {
  /// Lista de items del sidebar
  final List<SidebarItem> items;

  /// Color de fondo del sidebar
  final Color? backgroundColor;

  /// Color del item seleccionado
  final Color? selectedColor;

  /// Color del texto del item seleccionado
  final Color? selectedTextColor;

  /// Color del texto de los items no seleccionados
  final Color? textColor;

  /// Ancho del sidebar
  final double? width;

  /// Callback cuando se selecciona un item
  final ValueChanged<int>? onItemSelected;

  /// Índice del item seleccionado
  final int selectedIndex;

  /// Constructor del componente
  const SidebarComponent({
    super.key,
    required this.items,
    this.backgroundColor,
    this.selectedColor,
    this.selectedTextColor,
    this.textColor,
    this.width,
    this.onItemSelected,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ?? VcomColors.azulZafiroProfundo;
    final effectiveSelectedColor =
        selectedColor ?? VcomColors.oroLujoso;
    final effectiveSelectedTextColor =
        selectedTextColor ?? VcomColors.azulMedianocheTexto;
    final effectiveTextColor =
        textColor ?? VcomColors.blancoCrema;

    return Container(
      width: width ?? 280,
      color: effectiveBackgroundColor,
      child: Column(
        children: [
          // Header del sidebar (opcional, puede personalizarse)
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.menu,
                  color: effectiveTextColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Menú',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: effectiveTextColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista de items
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index || item.isSelected;

                return InkWell(
                  onTap: () {
                    item.onTap?.call();
                    onItemSelected?.call(index);
                  },
                  child: Container(
                    color: isSelected
                        ? effectiveSelectedColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected
                            ? effectiveSelectedColor
                            : effectiveTextColor,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? effectiveSelectedColor
                              : effectiveTextColor,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: item.badge != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: effectiveSelectedColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.badge!,
                                style: TextStyle(
                                  color: effectiveSelectedTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                      selected: isSelected,
                      selectedTileColor: effectiveSelectedColor.withValues(alpha: 0.1),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Botón de cerrar sesión
          Container(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () async {
                final tokenService = TokenService();
                final userStatusService = UserStatusService();
                
                // 1. Llamar al endpoint de logout del backend
                try {
                  final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.authLogout}');
                  await http.post(
                    url,
                    headers: {
                      'Content-Type': 'application/json',
                      'Accept': 'application/json',
                      'Authorization': 'Bearer ${tokenService.getToken()}',
                    },
                  ).timeout(const Duration(seconds: 3));
                } catch (e) {
                  // Si falla, continuar con el logout de todas formas
                  debugPrint('Error en logout del backend: $e');
                }
                
                // 2. Limpiar el token y datos del usuario
                await userStatusService.setOffline();
                tokenService.clear();
                
                // 3. Cerrar el drawer
                if (context.mounted) {
                  Navigator.pop(context);
                  
                  // 4. Navegar al login y limpiar la pila de navegación
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                    (route) => false, // Elimina todas las rutas anteriores
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.red.shade300,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
