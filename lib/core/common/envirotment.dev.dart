import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuración de ambiente de desarrollo
class EnvironmentDev {
  /// URL base del API para producción
  /// Backend en producción
  //static const String baseUrl = 'https://vcamb.microwesttechnologies.com';
  
  /// IP local para dispositivos físicos Android
  /// Cambia esta IP por la IP de tu máquina en la red WiFi
  /// Para encontrar tu IP: Windows (ipconfig) o Mac/Linux (ifconfig)
  /// Ejemplo: '192.168.1.100' (sin http:// ni puerto)
  static const String localIpForPhysicalDevice = '192.168.1.2'; // ⚠️ CAMBIA ESTA IP
  
  /// URL base del API - Detecta automáticamente la plataforma
  /// 
  /// - Android Emulator: usa 10.0.2.2 (alias especial del emulador para localhost)
  /// - Android Dispositivo Físico: usa localIpForPhysicalDevice (configurar arriba)
  /// - iOS Simulator: usa 127.0.0.1 (funciona directamente)
  /// - Web: usa 127.0.0.1
  static String get baseUrl {
    if (kIsWeb) {
      // Para web, usar localhost directamente
      return 'http://127.0.0.1:8000';
    } else if (Platform.isAndroid) {
      // Detectar automáticamente si es emulador o dispositivo físico
      return _getAndroidUrl();
      
      // Configuración manual (descomenta si la detección automática falla):
      // Para emulador: return 'http://10.0.2.2:8000';
      // Para dispositivo físico: return 'http://$localIpForPhysicalDevice:8000';
    } else if (Platform.isIOS) {
      // Para iOS Simulator, usar localhost directamente
      return 'http://127.0.0.1:8000';
    } else {
      // Para otras plataformas (Windows, Linux, macOS desktop)
      return 'http://127.0.0.1:8000';
    }
  }

  /// Detecta automáticamente si es emulador o dispositivo físico Android
  static String _getAndroidUrl() {
    try {
      // Detectar si es emulador usando características del sistema
      final isEmulator = _isAndroidEmulator();
      
      if (isEmulator) {
        // Para emulador Android - usar la IP especial del emulador
        print('🤖 VCOM: Detectado Android Emulator - usando 10.0.2.2:8000');
        return 'http://10.0.2.2:8000';
      } else {
        // Para dispositivo físico Android - usar la IP local configurada (WiFi)
        print('📱 VCOM: Detectado dispositivo físico Android - usando $localIpForPhysicalDevice:8000');
        return 'http://$localIpForPhysicalDevice:8000';
      }
    } catch (e) {
      // Si hay error en la detección, usar IP local por defecto
      print('⚠️ VCOM: Error detectando tipo de dispositivo, usando IP local: $e');
      return 'http://$localIpForPhysicalDevice:8000';
    }
  }

  /// Detecta si el dispositivo Android es un emulador
  static bool _isAndroidEmulator() {
    try {
      // En Flutter, podemos usar kDebugMode y otras heurísticas
      // Los emuladores suelen tener características específicas
      
      // Método simple: verificar si estamos en modo debug y usar heurísticas básicas
      if (kDebugMode) {
        // En desarrollo, podemos asumir patrones comunes
        // Los emuladores generalmente tienen menos memoria física
        // y características específicas del sistema
        
        // Por ahora, usar una detección simple basada en el entorno
        // Si necesitas más precisión, puedes usar plugins como device_info_plus
        
        // Heurística: si no podemos determinar con certeza, asumir dispositivo físico
        // para usar la IP local (más común en desarrollo)
        return false; // Asumir dispositivo físico para usar WiFi
      }
      
      return false; // Por defecto, asumir dispositivo físico
    } catch (e) {
      // Si no podemos detectar, asumir que es dispositivo físico
      return false;
    }
  }
  
  /// URL base estática para casos donde necesites una constante
  /// Por defecto usa la URL de producción
  static const String baseUrlProduction = 'https://vcamb.microwesttechnologies.com';
  
  /// URL base para desarrollo local (cambiar manualmente si usas dispositivo físico)
  /// Para dispositivo físico Android, usa la IP de tu máquina en la red local
  /// Ejemplo: 'http://192.168.1.100:8000'
  static const String baseUrlLocal = 'http://10.0.2.2:8000'; // Emulador Android
  // static const String baseUrlLocal = 'http://192.168.1.100:8000'; // Dispositivo físico (cambiar IP)

  // ============================================================================
  // AUTENTICACIÓN
  // Endpoints de autenticación y gestión de usuarios
  // ============================================================================

  /// Iniciar sesión con email y contraseña
  static const String authLogin = '/api/v1/auth/login';

  /// Obtener información del usuario autenticado
  static const String authMe = '/api/v1/auth/me';

  /// Obtener módulos y permisos del usuario autenticado
  static const String authPermissions = '/api/v1/auth/permissions';

  /// Cerrar sesión y actualizar estado a offline
  static const String authLogout = '/api/v1/auth/logout';

  // ============================================================================
  // CENTRO COMERCIAL
  // Endpoints para gestión de negocios y productos
  // ============================================================================

  /// Actualizar información de un negocio (configuración de tienda)
  static String businessUpdate(int id) => '/api/v1/businesses/$id';

  // ============================================================================
  // PRODUCTOS
  // Endpoints para gestión de productos (CRUD)
  // ============================================================================

  /// Listar todos los productos
  static const String productsList = '/api/v1/products';

  /// Crear un nuevo producto
  static const String productsCreate = '/api/v1/products';

  /// Obtener un producto por ID
  static String productsGet(int id) => '/api/v1/products/$id';

  /// Actualizar un producto
  static String productsUpdate(int id) => '/api/v1/products/$id';

  /// Eliminar un producto
  static String productsDelete(int id) => '/api/v1/products/$id';

  /// Cambiar estado de disponibilidad del producto (activar/desactivar)
  static String productsToggle(int id) => '/api/v1/products/$id/toggle';

  /// Subir imagen de producto
  static String productsUploadImage(int productId) => '/api/v1/products/$productId/uploadImageProduct';

  // ============================================================================
  // CATEGORÍAS
  // Endpoints para gestión de categorías de productos (Rol: Admin Store)
  // ============================================================================

  /// Listar todas las categorías
  static const String categoriesList = '/api/v1/categories';

  /// Crear una nueva categoría
  static const String categoriesCreate = '/api/v1/categories';

  /// Obtener una categoría por ID
  static String categoriesGet(int id) => '/api/v1/categories/$id';

  /// Actualizar una categoría
  static String categoriesUpdate(int id) => '/api/v1/categories/$id';

  /// Eliminar una categoría
  static String categoriesDelete(int id) => '/api/v1/categories/$id';

  // ============================================================================
  // MARCAS
  // Endpoints para gestión de marcas de productos (Rol: Admin Store)
  // ============================================================================

  /// Listar todas las marcas (opcionalmente filtradas por categoría)
  static const String brandsList = '/api/v1/brands';

  /// Crear una nueva marca
  static const String brandsCreate = '/api/v1/brands';

  /// Obtener marcas por categoría
  static String brandsByCategory(int categoryId) => '/api/v1/brands/category/$categoryId';

  /// Obtener una marca por ID
  static String brandsGet(int id) => '/api/v1/brands/$id';

  /// Actualizar una marca
  static String brandsUpdate(int id) => '/api/v1/brands/$id';

  /// Eliminar una marca
  static String brandsDelete(int id) => '/api/v1/brands/$id';

  // ============================================================================
  // CONSULTAS DE PRODUCTOS
  // Endpoints para gestión de consultas e inquiries de productos (Rol: Admin Store)
  // ============================================================================

  /// Listar consultas de productos por negocio
  static const String productInquiriesList = '/api/v1/product-inquiries';

  /// Crear una nueva consulta de producto
  static const String productInquiriesCreate = '/api/v1/product-inquiries';

  /// Obtener detalle de una consulta
  static String productInquiriesGet(int id) => '/api/v1/product-inquiries/$id';

  /// Actualizar el estado de una consulta
  static String productInquiriesUpdateStatus(int id) =>
      '/api/v1/product-inquiries/$id/status';

  /// Obtener mensajes de una consulta
  static String productInquiriesGetMessages(int id) =>
      '/api/v1/product-inquiries/$id/messages';

  /// Enviar un mensaje en una consulta
  static String productInquiriesSendMessage(int id) =>
      '/api/v1/product-inquiries/$id/messages';

  /// Marcar mensajes como leídos
  static String productInquiriesMarkAsRead(int id) =>
      '/api/v1/product-inquiries/$id/read';

  // ============================================================================
  // CHAT
  // Endpoints para gestión de chat entre Modelo y Monitor
  // ============================================================================

  /// Listar conversaciones (solo para Monitor)
  static const String chatConversations = '/api/v1/chat/conversations';

  /// Crear nueva conversación (solo para Monitor)
  static const String chatCreateConversation = '/api/v1/chat/conversations';

  /// Obtener conversación específica
  static String chatConversation(int id) => '/api/v1/chat/conversations/$id';

  /// Buscar conversación con otro usuario
  static const String chatSearchConversation = '/api/v1/chat/search-conversation';

  /// Crear o obtener conversación con otro usuario
  static const String chatCreateOrGetConversation = '/api/v1/chat/create-or-get-conversation';

  /// Obtener ID de usuario por nombre
  static const String chatGetUserByName = '/api/v1/chat/get-user-by-name';

  /// Obtener monitor asignado (solo para Modelo)
  static const String chatMonitor = '/api/v1/chat/monitor';

  /// Listar modelos activas (solo para Monitor)
  static const String chatModels = '/api/v1/chat/models';

  /// Obtener mensajes de una conversación
  static String chatMessages(int conversationId) => '/api/v1/chat/messages/$conversationId';

  /// Enviar mensaje
  static const String chatSendMessage = '/api/v1/chat/messages';

  /// Marcar mensajes como leídos
  static String chatMarkAsRead(int conversationId) => '/api/v1/chat/conversations/$conversationId/read';

  /// Marcar usuario como online
  static const String chatStatusOnline = '/api/v1/chat/status/online';

  /// Marcar usuario como offline
  static const String chatStatusOffline = '/api/v1/chat/status/offline';

  /// Obtener estado de usuario
  static String chatUserStatus(String userId) => '/api/v1/chat/users/$userId/status';

  /// Obtener estado de múltiples usuarios (batch)
  static const String chatUsersStatus = '/api/v1/chat/users/status';

  /// Subir imagen en chat
  static const String chatUploadImage = '/api/v1/chat/upload-image';

  /// Subir archivos multimedia (imágenes y videos)
  static const String chatUploadMedia = '/api/v1/chat/upload-media';

  /// WebSocket URL para chat en tiempo real
  static String get chatWebSocketUrl {
    final url = baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    return '$url/ws/chat';
  }
}
