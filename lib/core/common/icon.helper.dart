import 'package:flutter/material.dart';

/// Helper para mapear nombres de iconos a IconData
class IconHelper {
  /// Convierte un string de icono a IconData
  static IconData getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'category':
      case 'categorias':
        return Icons.category;
      case 'brand':
      case 'marcas':
        return Icons.branding_watermark;
      case 'product':
      case 'productos':
        return Icons.inventory;
      case 'hub':
        return Icons.hub;
      case 'dashboard':
        return Icons.dashboard;
      case 'settings':
      case 'configuracion':
        return Icons.settings;
      case 'user':
      case 'usuario':
        return Icons.person;
      case 'notification':
      case 'notificaciones':
        return Icons.notifications;
      case 'help':
      case 'ayuda':
        return Icons.help;
      default:
        return Icons.folder;
    }
  }
}

