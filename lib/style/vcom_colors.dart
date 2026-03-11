import 'package:flutter/material.dart';

/// Paleta de colores VCOM - "Lujo Nocturno"
/// 
/// Esta paleta se divide en:
/// - Colores primarios para el fondo
/// - Acentos metálicos para los elementos destacados
/// - Neutros para la tipografía
class VcomColors {
  VcomColors._();

  // ============================================================================
  // TONOS BASE (FONDOS Y ATMÓSFERA)
  // ============================================================================

  /// Azul Zafiro Profundo - Fondo Principal
  /// Es el color dominante del fondo, un azul muy oscuro que sugiere el cielo nocturno.
  /// RGB: 8, 24, 58
  static const Color azulZafiroProfundo = Color.fromRGBO(8, 24, 58, 1.0);

  /// Azul Noche Sombra
  /// Un tono casi negro, utilizado en las cargas de comercio, en los pliegues de texto
  /// de fondo y para dar profundidad al espacio de contenido.
  /// RGB: 3, 12, 30
  static const Color azulNocheSombra = Color.fromRGBO(3, 12, 30, 1.0);

  /// Azul Overlay Transparente
  /// Utilizado en los campos de entrada de una línea de la página.
  /// Es un azul oscuro con transparencia. También se usa con RGB: 20, 40, 80.
  /// Se recomienda usar con opacidad del 50-70% en CSS.
  /// RGB: 20, 40, 80
  static const Color azulOverlayTransparente = Color.fromRGBO(20, 40, 80, 1.0);

  /// Azul Overlay Transparente con opacidad recomendada (60%)
  static Color get azulOverlayTransparente60 => azulOverlayTransparente.withOpacity(0.6);

  /// Azul Overlay Transparente con opacidad recomendada (50%)
  static Color get azulOverlayTransparente50 => azulOverlayTransparente.withOpacity(0.5);

  /// Azul Overlay Transparente con opacidad recomendada (70%)
  static Color get azulOverlayTransparente70 => azulOverlayTransparente.withOpacity(0.7);

  // ============================================================================
  // ACENTOS METÁLICOS (ORO)
  // ============================================================================

  /// Oro Lujoso - Color Acento Principal
  /// Un oro medio dorado, utilizado en la mayoría de los iconos, las marcas de las
  /// cajas y los iconos.
  /// RGB: 196, 154, 72
  static const Color oroLujoso = Color.fromRGBO(196, 154, 72, 1.0);

  /// Oro Brillante - Iluminación y Hover
  /// Un tono más claro del degradado metálico, usado en los bordes superiores de las
  /// secciones y para efectos de 'hover' al pasar el mouse.
  /// RGB: 242, 216, 136
  static const Color oroBrillante = Color.fromRGBO(242, 216, 136, 1.0);

  /// Bronce Dorado - Sombra y Bordes
  /// El tono más oscuro y rico de metal, usado en los bordes inferiores y para dar volumen.
  /// Texto dorado como en el logo 'VCOM'.
  /// RGB: 138, 102, 40
  static const Color bronceDorado = Color.fromRGBO(138, 102, 40, 1.0);

  // ============================================================================
  // TIPOGRAFÍA Y NEUTROS
  // ============================================================================

  /// Blanco Crema - Texto Principal
  /// No es un blanco puro, sino un blanco ligeramente cálido que se complementa con el oro.
  /// Usado para los párrafos y descripciones.
  /// RGB: 245, 245, 235
  static const Color blancoCrema = Color.fromRGBO(245, 245, 235, 1.0);

  /// Azul Medianoche Texto - Texto sobre Oro
  /// Para el texto que va dentro de las burbujas o sobre las fuentes.
  /// No es un azul muy oscuro, es un negro puro para mantener la armonía cromática.
  /// RGB: 5, 15, 35
  static const Color azulMedianocheTexto = Color.fromRGBO(5, 15, 35, 1.0);

  // ============================================================================
  // COLORES ADICIONALES PARA LOGO Y VARIACIONES
  // ============================================================================

  /// Blanco puro para logo en negativo
  static const Color blanco = Color.fromRGBO(255, 255, 255, 1.0);

  /// Negro/Azul oscuro para logo en positivo
  static const Color negroAzul = Color.fromRGBO(0, 0, 0, 1.0);

  /// Beige/Crema claro para fondos en variación positiva del logo
  static const Color beigeClaro = Color.fromRGBO(250, 245, 235, 1.0);

  // ============================================================================
  // COLORES SEMÁNTICOS (ESTADOS Y ACCIONES)
  // ============================================================================

  /// Color para estados de éxito
  static const Color success = Color.fromRGBO(76, 175, 80, 1.0);

  /// Color para estados de error
  static const Color error = Color.fromRGBO(244, 67, 54, 1.0);

  /// Color para estados de advertencia
  static const Color warning = oroBrillante;

  /// Color para información
  static const Color info = Color.fromRGBO(33, 150, 243, 1.0);

  // ============================================================================
  // GRADIENTES
  // ============================================================================

  /// Gradiente metálico dorado (de bronce a oro brillante)
  static const LinearGradient gradienteOro = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      oroBrillante,
      oroLujoso,
      bronceDorado,
    ],
  );

  /// Gradiente de fondo nocturno
  static const LinearGradient gradienteNocturno = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      azulZafiroProfundo,
      azulNocheSombra,
    ],
  );

  /// Fondo velvet (como en la imagen de login)
  /// #1e293b -> #0f172a
  static const Color velvetDark = Color(0xFF0f172a);
  static const Color velvetLight = Color(0xFF1e293b);
  static const RadialGradient gradienteVelvet = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [velvetLight, velvetDark],
  );

  /// Dorado primario (#d4af37) para acentos
  static const Color oroPrimario = Color(0xFFd4af37);

  /// Primary púrpura (#2C097F) para botones y acentos del dashboard modelo
  static const Color primaryPurple = Color(0xFF2C097F);

  /// Secondary azul (#273C67) para badges
  static const Color secondaryBlue = Color(0xFF273C67);

  /// Fondo glassmorphism para tarjeta de login
  static Color get glassCardBg => const Color(0x66000000);
  static Color get glassCardBorder => Color.fromRGBO(241, 191, 39, 0.1);
  static Color get inputFieldBg => const Color(0xFF202020);

  // ============================================================================
  // COLORES PARA TEMA FLUTTER (Material Design)
  // ============================================================================

  /// ColorScheme para Material Design basado en la paleta VCOM
  static ColorScheme get colorScheme => ColorScheme(
        brightness: Brightness.dark,
        primary: oroLujoso,
        onPrimary: azulMedianocheTexto,
        secondary: oroBrillante,
        onSecondary: azulMedianocheTexto,
        tertiary: bronceDorado,
        onTertiary: blancoCrema,
        error: error,
        onError: blanco,
        surface: azulZafiroProfundo,
        onSurface: blancoCrema,
        surfaceContainerHighest: azulNocheSombra,
        onSurfaceVariant: blancoCrema.withOpacity(0.7),
        outline: oroLujoso.withOpacity(0.5),
        outlineVariant: oroBrillante.withOpacity(0.3),
        shadow: azulNocheSombra,
        scrim: azulNocheSombra,
        inverseSurface: blancoCrema,
        onInverseSurface: azulZafiroProfundo,
        inversePrimary: oroBrillante,
      );
}

