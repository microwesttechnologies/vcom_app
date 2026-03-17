import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Enum para definir los tamaños del label
enum LabelSize {
  small,
  medium,
  large,
}

/// Componente de label reutilizable con atributos dinámicos
class LabelComponent extends StatelessWidget {
  /// Texto del label
  final String label;

  /// Tamaño del label (small, medium, large)
  final LabelSize size;

  /// Color del texto del label
  final Color? color;

  /// Color de fondo del label (opcional)
  final Color? backgroundColor;

  /// Icono del label (opcional)
  final IconData? icon;

  /// Posición del icono respecto al texto (true = antes, false = después)
  final bool iconBefore;

  /// Si el label está deshabilitado (texto atenuado)
  final bool isDisabled;

  /// Peso de la fuente
  final FontWeight? fontWeight;

  /// Constructor del componente
  const LabelComponent({
    super.key,
    required this.label,
    this.size = LabelSize.medium,
    this.color,
    this.backgroundColor,
    this.icon,
    this.iconBefore = true,
    this.isDisabled = false,
    this.fontWeight,
  });

  /// Obtiene el tamaño de fuente según el tamaño del label
  double _getFontSize() {
    switch (size) {
      case LabelSize.small:
        return 12.0;
      case LabelSize.medium:
        return 14.0;
      case LabelSize.large:
        return 16.0;
    }
  }

  /// Obtiene el padding vertical según el tamaño del label
  double _getVerticalPadding() {
    switch (size) {
      case LabelSize.small:
        return 4.0;
      case LabelSize.medium:
        return 6.0;
      case LabelSize.large:
        return 8.0;
    }
  }

  /// Obtiene el padding horizontal según el tamaño del label
  double _getHorizontalPadding() {
    switch (size) {
      case LabelSize.small:
        return 8.0;
      case LabelSize.medium:
        return 12.0;
      case LabelSize.large:
        return 16.0;
    }
  }

  /// Obtiene el tamaño del icono según el tamaño del label
  double _getIconSize() {
    switch (size) {
      case LabelSize.small:
        return 14.0;
      case LabelSize.medium:
        return 18.0;
      case LabelSize.large:
        return 22.0;
    }
  }

  /// Obtiene el espaciado entre el icono y el texto
  double _getIconSpacing() {
    switch (size) {
      case LabelSize.small:
        return 4.0;
      case LabelSize.medium:
        return 6.0;
      case LabelSize.large:
        return 8.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? VcomColors.blancoCrema;
    final effectiveBackgroundColor = backgroundColor;
    final effectiveFontWeight = fontWeight ?? FontWeight.normal;
    final opacity = isDisabled ? 0.5 : 1.0;

    Widget labelContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null && iconBefore)
          Icon(
            icon,
            size: _getIconSize(),
            color: effectiveColor.withValues(alpha: opacity),
          ),
        if (icon != null && iconBefore)
          SizedBox(width: _getIconSpacing()),
        Text(
          label,
          style: TextStyle(
            fontSize: _getFontSize(),
            fontWeight: effectiveFontWeight,
            color: effectiveColor.withValues(alpha: opacity),
          ),
        ),
        if (icon != null && !iconBefore)
          SizedBox(width: _getIconSpacing()),
        if (icon != null && !iconBefore)
          Icon(
            icon,
            size: _getIconSize(),
            color: effectiveColor.withValues(alpha: opacity),
          ),
      ],
    );

    if (effectiveBackgroundColor != null) {
      return Container(
        padding: EdgeInsets.symmetric(
          vertical: _getVerticalPadding(),
          horizontal: _getHorizontalPadding(),
        ),
        decoration: BoxDecoration(
          color: effectiveBackgroundColor.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: labelContent,
      );
    }

    return labelContent;
  }
}

