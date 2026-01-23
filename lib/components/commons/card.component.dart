import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Enum para definir los tamaños del card
enum CardSize {
  small,
  medium,
  large,
}

/// Componente de card horizontal reutilizable para ingreso a módulos
class CardComponent extends StatelessWidget {
  /// Texto del label del card
  final String label;

  /// Descripción del card (opcional)
  final String? description;

  /// Icono del card
  final IconData icon;

  /// Tamaño del card (small, medium, large)
  final CardSize size;

  /// Color de fondo del card
  final Color? backgroundColor;

  /// Color del texto del label
  final Color? textColor;

  /// Color del icono
  final Color? iconColor;

  /// Color del borde
  final Color? borderColor;

  /// Ancho del borde
  final double? borderWidth;

  /// Radio de las esquinas del card
  final double? borderRadius;

  /// Callback cuando se presiona el card
  final VoidCallback? onTap;

  /// Si el card está deshabilitado
  final bool isDisabled;

  /// Ancho del card (opcional, null = ancho automático)
  final double? width;

  /// Altura del card (opcional, null = altura automática)
  final double? height;

  /// Padding interno del card
  final EdgeInsets? padding;

  /// Elevación/sombra del card
  final double? elevation;

  /// Constructor del componente
  const CardComponent({
    super.key,
    required this.label,
    this.description,
    required this.icon,
    this.size = CardSize.medium,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.onTap,
    this.isDisabled = false,
    this.width,
    this.height,
    this.padding,
    this.elevation,
  });

  /// Obtiene el tamaño de fuente según el tamaño del card
  double _getFontSize() {
    switch (size) {
      case CardSize.small:
        return 16.0;
      case CardSize.medium:
        return 20.0;
      case CardSize.large:
        return 24.0;
    }
  }

  /// Obtiene el tamaño del icono según el tamaño del card
  double _getIconSize() {
    switch (size) {
      case CardSize.small:
        return 24.0;
      case CardSize.medium:
        return 32.0;
      case CardSize.large:
        return 40.0;
    }
  }

  /// Obtiene el padding por defecto según el tamaño del card
  EdgeInsets _getDefaultPadding() {
    switch (size) {
      case CardSize.small:
        return const EdgeInsets.all(12.0);
      case CardSize.medium:
        return const EdgeInsets.all(16.0);
      case CardSize.large:
        return const EdgeInsets.all(20.0);
    }
  }

  /// Obtiene el espaciado entre el icono y el texto
  double _getIconSpacing() {
    switch (size) {
      case CardSize.small:
        return 8.0;
      case CardSize.medium:
        return 12.0;
      case CardSize.large:
        return 16.0;
    }
  }

  /// Obtiene la altura por defecto según el tamaño del card
  double _getDefaultHeight() {
    final baseHeight = switch (size) {
      CardSize.small => 60.0,
      CardSize.medium => 80.0,
      CardSize.large => 100.0,
    };
    // Si hay descripción, aumentar la altura para evitar overflow
    if (description != null && description!.isNotEmpty) {
      return baseHeight + 40.0;
    }
    return baseHeight;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ?? VcomColors.azulZafiroProfundo;
    final effectiveTextColor =
        textColor ?? VcomColors.blancoCrema;
    final effectiveIconColor =
        iconColor ?? VcomColors.oroLujoso;
    final effectiveBorderColor =
        borderColor ?? VcomColors.oroLujoso.withOpacity(0.5);
    final effectiveBorderWidth = borderWidth ?? 1.0;
    final effectiveBorderRadius = borderRadius ?? 12.0;
    final effectiveElevation = elevation ?? 2.0;
    final effectivePadding = padding ?? _getDefaultPadding();
    final effectiveHeight = height ?? _getDefaultHeight();
    final opacity = isDisabled ? 0.5 : 1.0;
    final isEnabled = !isDisabled && onTap != null;

    Widget cardContent = Container(
      width: width,
      constraints: BoxConstraints(minHeight: effectiveHeight),
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor.withOpacity(opacity),
        border: Border.all(
          color: effectiveBorderColor.withOpacity(opacity),
          width: effectiveBorderWidth,
        ),
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        boxShadow: effectiveElevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: effectiveElevation * 2,
                  offset: Offset(0, effectiveElevation),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: _getIconSize(),
            color: effectiveIconColor.withOpacity(opacity),
          ),
          SizedBox(width: _getIconSpacing()),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: _getFontSize(),
                    fontWeight: FontWeight.w600,
                    color: effectiveTextColor.withOpacity(opacity),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: TextStyle(
                      fontSize: _getFontSize() - 2,
                      fontWeight: FontWeight.w400,
                      color: effectiveTextColor.withOpacity(opacity * 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (isEnabled) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

