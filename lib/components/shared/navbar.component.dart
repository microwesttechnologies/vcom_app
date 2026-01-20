import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';
import 'package:vcom_app/core/common/token.service.dart';

/// Modelo para los items del navbar
class NavbarItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSelected;
  final String? badge;

  const NavbarItem({
    required this.label,
    this.icon,
    this.onTap,
    this.isSelected = false,
    this.badge,
  });
}

/// Modelo para acciones del topbar (iconos con badges opcionales)
class TopBarAction {
  final IconData icon;
  final VoidCallback? onTap;
  final String? badge;
  final Color? iconColor;
  final Color? badgeColor;

  const TopBarAction({
    required this.icon,
    this.onTap,
    this.badge,
    this.iconColor,
    this.badgeColor,
  });
}

/// Componente de navbar reutilizable estilo Top App Bar moderno
/// Con esquinas redondeadas superiores, título grande, subtítulo y acciones con badges
class NavbarComponent extends StatelessWidget implements PreferredSizeWidget {
  /// Título principal del navbar (texto grande)
  final String? title;

  /// Subtítulo del navbar (texto más pequeño debajo del título)
  final String? subtitle;

  /// Lista de items del navbar (acciones)
  final List<NavbarItem>? items;

  /// Lista de acciones del topbar (iconos simples con badges opcionales)
  final List<TopBarAction>? topBarActions;

  /// Color de fondo del navbar
  final Color? backgroundColor;

  /// Color del texto del título
  final Color? textColor;

  /// Color del texto del subtítulo
  final Color? subtitleColor;

  /// Color de los iconos
  final Color? iconColor;

  /// Altura del navbar
  final double? height;

  /// Widget personalizado para el título
  final Widget? titleWidget;

  /// Widget personalizado para las acciones (items)
  final List<Widget>? actions;

  /// Si muestra el botón de retroceso
  final bool showBackButton;

  /// Callback cuando se presiona el botón de retroceso
  final VoidCallback? onBackPressed;

  /// Callback cuando se presiona el botón de menú hamburguesa
  final VoidCallback? onMenuPressed;

  /// Si muestra el botón de menú hamburguesa
  final bool showMenuButton;

  /// Radio de las esquinas superiores
  final double? topBorderRadius;

  /// Elevación del navbar
  final double? elevation;

  /// Constructor del componente
  const NavbarComponent({
    super.key,
    this.title,
    this.subtitle,
    this.items,
    this.topBarActions,
    this.backgroundColor,
    this.textColor,
    this.subtitleColor,
    this.iconColor,
    this.height,
    this.titleWidget,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.onMenuPressed,
    this.showMenuButton = true,
    this.topBorderRadius,
    this.elevation,
  });

  @override
  Size get preferredSize {
    // Calcular altura dinámica basada en si hay subtítulo
    double defaultHeight = kToolbarHeight;
    if (subtitle != null || titleWidget != null) {
      defaultHeight = kToolbarHeight + 32; // Extra espacio para subtítulo
    }
    return Size.fromHeight(height ?? defaultHeight);
  }

  /// Construye un widget de acción con badge opcional
  Widget _buildActionWithBadge(TopBarAction action, Color defaultIconColor) {
    Widget iconWidget = Icon(
      action.icon,
      color: action.iconColor ?? defaultIconColor,
      size: 24,
    );

    // Agregar badge si existe
    if (action.badge != null && action.badge!.isNotEmpty) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: action.badgeColor ?? Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  action.badge!,
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

    return iconWidget;
  }

  /// Obtiene el nombre del usuario desde el servicio global
  String _getUserName() {
    final tokenService = TokenService();
    return tokenService.getUserName() ?? 'Usuario';
  }

  /// Obtiene el rol del usuario desde el servicio global
  String _getRole() {
    final tokenService = TokenService();
    return tokenService.getRole() ?? 'Sin rol asignado';
  }

  @override
  Widget build(BuildContext context) {
    // Obtener datos del usuario desde el servicio global si no se proporcionaron
    final effectiveTitle = title ?? 'Hola, ${_getUserName()}';
    final effectiveSubtitle = subtitle ?? _getRole();
    
    final effectiveBackgroundColor =
        backgroundColor ?? VcomColors.azulZafiroProfundo;
    final effectiveTextColor =
        textColor ?? VcomColors.blancoCrema;
    final effectiveSubtitleColor =
        subtitleColor ?? VcomColors.blancoCrema.withOpacity(0.7);
    final effectiveIconColor =
        iconColor ?? VcomColors.blancoCrema.withOpacity(0.9);
    final effectiveElevation = elevation ?? 4.0;
    final effectiveTopBorderRadius = topBorderRadius ?? 16.0;

    // Configurar acciones por defecto si no se proporcionan
    final effectiveTopBarActions = topBarActions ?? [
      TopBarAction(
        icon: Icons.notifications_outlined,
        badge: '1',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notificaciones')),
          );
        },
      ),
      TopBarAction(
        icon: Icons.settings_outlined,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuración')),
          );
        },
      ),
    ];

    List<Widget> actionWidgets = [];

    // Construir acciones del topbar (iconos con badges)
    if (effectiveTopBarActions.isNotEmpty) {
      for (final action in effectiveTopBarActions) {
        actionWidgets.add(
          IconButton(
            icon: _buildActionWithBadge(action, effectiveIconColor),
            onPressed: action.onTap,
            color: effectiveIconColor,
          ),
        );
      }
    }

    // Agregar items del navbar si existen (compatibilidad con versión anterior)
    if (items != null && items!.isNotEmpty) {
      for (int i = 0; i < items!.length; i++) {
        final item = items![i];
        actionWidgets.add(
          InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      color: item.isSelected
                          ? effectiveTextColor
                          : effectiveIconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    item.label,
                    style: TextStyle(
                      color: item.isSelected
                          ? effectiveTextColor
                          : effectiveIconColor,
                      fontWeight: item.isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (item.badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: effectiveTextColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.badge!,
                        style: TextStyle(
                          color: effectiveBackgroundColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
        if (i < items!.length - 1) {
          actionWidgets.add(const SizedBox(width: 8));
        }
      }
    }

    // Agregar acciones personalizadas si existen
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    // Construir el widget del título
    Widget? titleWidget = this.titleWidget;
    if (titleWidget == null && (effectiveTitle.isNotEmpty || effectiveSubtitle.isNotEmpty)) {
      titleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (effectiveTitle.isNotEmpty)
            Text(
              effectiveTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: effectiveTextColor,
                letterSpacing: 0.15,
              ),
            ),
          if (effectiveSubtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              effectiveSubtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: effectiveSubtitleColor,
                letterSpacing: 0.25,
              ),
            ),
          ],
        ],
      );
    }

    // Determinar qué mostrar en el leading
    // Prioridad: Menú hamburguesa > Botón de retroceso
    Widget? leadingWidget;
    bool automaticallyImplyLeading = true;

    if (showMenuButton) {
      // Mostrar botón de hamburguesa
      automaticallyImplyLeading = false;
      leadingWidget = Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu, 
            color: effectiveIconColor,
            size: 28,
          ),
          tooltip: 'Menú',
          onPressed: onMenuPressed ?? () {
            // Intentar abrir el drawer si existe, si no mostrar mensaje
            try {
              Scaffold.of(context).openDrawer();
            } catch (e) {
              // Si no hay drawer, mostrar snackbar o simplemente no hacer nada
              // El usuario puede personalizar con onMenuPressed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menú'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        ),
      );
    } else {
      // Si no hay menú, verificar si se debe mostrar botón de retroceso
      final bool shouldShowBackButton = showBackButton 
          ? true 
          : Navigator.canPop(context);
      
      if (shouldShowBackButton) {
        automaticallyImplyLeading = false;
        leadingWidget = IconButton(
          icon: Icon(Icons.arrow_back, color: effectiveIconColor),
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        );
      }
    }

    Widget appBar = AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: effectiveTextColor,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leadingWidget,
      title: titleWidget,
      actions: actionWidgets.isNotEmpty ? actionWidgets : null,
      toolbarHeight: height ?? preferredSize.height,
    );

    // Aplicar fondo con esquinas redondeadas superiores
    Widget appBarContainer = Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveTopBorderRadius > 0
            ? BorderRadius.only(
                topLeft: Radius.circular(effectiveTopBorderRadius),
                topRight: Radius.circular(effectiveTopBorderRadius),
              )
            : null,
        boxShadow: effectiveElevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: effectiveElevation * 2,
                  offset: Offset(0, effectiveElevation),
                ),
              ]
            : null,
      ),
      child: appBar,
    );

    // Clippear las esquinas superiores si hay border radius
    if (effectiveTopBorderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(effectiveTopBorderRadius),
          topRight: Radius.circular(effectiveTopBorderRadius),
        ),
        child: appBarContainer,
      );
    }

    return appBarContainer;
  }
}

