import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Componente de botón flotante para agregar nuevos elementos
/// Muestra solo un icono de más sin texto
class AddButtonComponent extends StatelessWidget {
  /// Callback cuando se presiona el botón
  final VoidCallback onPressed;

  /// Color de fondo del botón
  final Color? backgroundColor;

  /// Color del icono
  final Color? iconColor;

  /// Constructor del componente
  const AddButtonComponent({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? VcomColors.oroLujoso,
      shape: const CircleBorder(),
      child: Icon(
        Icons.add,
        color: iconColor ?? VcomColors.azulMedianocheTexto,
      ),
    );
  }
}

