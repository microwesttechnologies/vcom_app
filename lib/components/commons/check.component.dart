import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Enum para definir los tamaños del check
enum CheckSize {
  small,
  medium,
  large,
}

/// Componente de check (checkbox) reutilizable con atributos dinámicos
class CheckComponent extends StatelessWidget {
  /// Texto del label del check
  final String label;

  /// Tamaño del check (small, medium, large)
  final CheckSize size;

  /// Color del check cuando está marcado
  final Color? color;

  /// Color del texto del label
  final Color? textColor;

  /// Icono personalizado para el check (opcional, si no se proporciona usa el checkbox estándar)
  final IconData? icon;

  /// Si el check está marcado
  final bool isChecked;

  /// Si el check está deshabilitado
  final bool isDisabled;

  /// Posición del check respecto al texto (true = antes, false = después)
  final bool checkBefore;

  /// Callback cuando cambia el estado del check
  final ValueChanged<bool>? onChanged;

  /// Constructor del componente
  const CheckComponent({
    super.key,
    required this.label,
    this.size = CheckSize.medium,
    this.color,
    this.textColor,
    this.icon,
    this.isChecked = false,
    this.isDisabled = false,
    this.checkBefore = true,
    this.onChanged,
  });

  /// Obtiene el tamaño de fuente según el tamaño del check
  double _getFontSize() {
    switch (size) {
      case CheckSize.small:
        return 12.0;
      case CheckSize.medium:
        return 14.0;
      case CheckSize.large:
        return 16.0;
    }
  }

  /// Obtiene el tamaño del check según el tamaño seleccionado
  double _getCheckSize() {
    switch (size) {
      case CheckSize.small:
        return 18.0;
      case CheckSize.medium:
        return 24.0;
      case CheckSize.large:
        return 30.0;
    }
  }

  /// Obtiene el espaciado entre el check y el texto
  double _getCheckSpacing() {
    switch (size) {
      case CheckSize.small:
        return 8.0;
      case CheckSize.medium:
        return 12.0;
      case CheckSize.large:
        return 16.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? VcomColors.oroLujoso;
    final effectiveTextColor = textColor ?? VcomColors.blancoCrema;
    final isEnabled = !isDisabled && onChanged != null;
    final opacity = isEnabled ? 1.0 : 0.5;

    Widget checkWidget;

    if (icon != null) {
      // Usar icono personalizado
      checkWidget = GestureDetector(
        onTap: isEnabled ? () => onChanged!(!isChecked) : null,
        child: Container(
          width: _getCheckSize(),
          height: _getCheckSize(),
          decoration: BoxDecoration(
            color: isChecked
                ? effectiveColor.withValues(alpha: opacity)
                : Colors.transparent,
            border: Border.all(
              color: effectiveColor.withValues(alpha: opacity),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: isChecked
              ? Icon(
                  icon,
                  size: _getCheckSize() * 0.6,
                  color: VcomColors.azulMedianocheTexto,
                )
              : null,
        ),
      );
    } else {
      // Usar checkbox estándar de Flutter
      checkWidget = SizedBox(
        width: _getCheckSize(),
        height: _getCheckSize(),
        child: Checkbox(
          value: isChecked,
          onChanged: isEnabled ? (value) => onChanged!(value ?? false) : null,
          activeColor: effectiveColor,
          checkColor: VcomColors.azulMedianocheTexto,
          side: BorderSide(
            color: effectiveColor.withValues(alpha: opacity),
            width: 2.0,
          ),
        ),
      );
    }

    Widget labelWidget = Text(
      label,
      style: TextStyle(
        fontSize: _getFontSize(),
        color: effectiveTextColor.withValues(alpha: opacity),
      ),
    );

    return InkWell(
      onTap: isEnabled ? () => onChanged!(!isChecked) : null,
      borderRadius: BorderRadius.circular(4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (checkBefore) checkWidget,
            if (checkBefore) SizedBox(width: _getCheckSpacing()),
            Flexible(child: labelWidget),
            if (!checkBefore) SizedBox(width: _getCheckSpacing()),
            if (!checkBefore) checkWidget,
          ],
        ),
      ),
    );
  }
}

