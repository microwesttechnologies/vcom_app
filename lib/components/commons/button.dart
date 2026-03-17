import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Enum para definir los tamaños del botón
enum ButtonSize {
  small,
  medium,
  large,
}

/// Componente de botón reutilizable con atributos dinámicos
class ButtonComponent extends StatelessWidget {
  /// Texto del botón
  final String label;

  /// Tamaño del botón (small, medium, large)
  final ButtonSize size;

  /// Color de fondo del botón
  final Color? color;

  /// Color del texto del botón
  final Color? textColor;

  /// Icono del botón (opcional)
  final IconData? icon;

  /// Posición del icono respecto al texto (true = antes, false = después)
  final bool iconBefore;

  /// Callback cuando se presiona el botón
  final VoidCallback? onPressed;

  /// Si el botón está deshabilitado
  final bool isDisabled;

  /// Ancho del botón (opcional, null = ancho automático)
  final double? width;

  /// Constructor del componente
  const ButtonComponent({
    super.key,
    required this.label,
    this.size = ButtonSize.medium,
    this.color,
    this.textColor,
    this.icon,
    this.iconBefore = true,
    this.onPressed,
    this.isDisabled = false,
    this.width,
  });

  /// Obtiene el tamaño de fuente según el tamaño del botón
  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 12.0;
      case ButtonSize.medium:
        return 14.0;
      case ButtonSize.large:
        return 16.0;
    }
  }

  /// Obtiene el padding vertical según el tamaño del botón
  double _getVerticalPadding() {
    switch (size) {
      case ButtonSize.small:
        return 8.0;
      case ButtonSize.medium:
        return 12.0;
      case ButtonSize.large:
        return 16.0;
    }
  }

  /// Obtiene el padding horizontal según el tamaño del botón
  double _getHorizontalPadding() {
    switch (size) {
      case ButtonSize.small:
        return 16.0;
      case ButtonSize.medium:
        return 24.0;
      case ButtonSize.large:
        return 32.0;
    }
  }

  /// Obtiene el tamaño del icono según el tamaño del botón
  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16.0;
      case ButtonSize.medium:
        return 20.0;
      case ButtonSize.large:
        return 24.0;
    }
  }

  /// Obtiene el espaciado entre el icono y el texto
  double _getIconSpacing() {
    switch (size) {
      case ButtonSize.small:
        return 6.0;
      case ButtonSize.medium:
        return 8.0;
      case ButtonSize.large:
        return 10.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? VcomColors.oroLujoso;
    final effectiveTextColor = textColor ?? VcomColors.azulMedianocheTexto;
    final isEnabled = !isDisabled && onPressed != null;

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && iconBefore)
          Icon(
            icon,
            size: _getIconSize(),
            color: isEnabled ? effectiveTextColor : effectiveTextColor.withValues(alpha: 0.5),
          ),
        if (icon != null && iconBefore)
          SizedBox(width: _getIconSpacing()),
        Text(
          label,
          style: TextStyle(
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w600,
            color: isEnabled ? effectiveTextColor : effectiveTextColor.withValues(alpha: 0.5),
          ),
        ),
        if (icon != null && !iconBefore)
          SizedBox(width: _getIconSpacing()),
        if (icon != null && !iconBefore)
          Icon(
            icon,
            size: _getIconSize(),
            color: isEnabled ? effectiveTextColor : effectiveTextColor.withValues(alpha: 0.5),
          ),
      ],
    );

    Widget button = ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? effectiveColor : effectiveColor.withValues(alpha: 0.5),
        foregroundColor: effectiveTextColor,
        padding: EdgeInsets.symmetric(
          vertical: _getVerticalPadding(),
          horizontal: _getHorizontalPadding(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: isEnabled ? 2.0 : 0.0,
        minimumSize: width != null ? Size(width!, 0) : null,
      ),
      child: buttonContent,
    );

    return button;
  }
}

