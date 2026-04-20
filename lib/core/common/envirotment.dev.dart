/// Configuración de ambiente de desarrollo
class EnvironmentDev {
  /// URL base del API local
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://vcamb.microwesttechnologies.com',
  );
  // static const String baseUrl = 'http://192.168.1.2:8000'; // IP local (desarrollo)
  // static const String baseUrl = 'http://localhost:8000'; // Localhost (para web/desktop)
  // static const String baseUrl = 'http://10.0.2.2:8000'; // Emulador Android

  // ============================================================================
  // REGISTRO PÚBLICO (sin autenticación)
  // ============================================================================

  /// Registrar solicitud de membresía como modelo (público)
  static const String modelsRegister = '/api/v1/register/model';

  /// Listar plataformas disponibles para registro (público)
  static const String platformsPublic = '/api/v1/register/platforms';

  // ============================================================================
  // AUTENTICACIÓN
  // Endpoints de autenticación y gestión de usuarios
  // ============================================================================

  /// Iniciar sesión con email y contraseña
  static const String authLogin = '/api/v1/auth/login';

  /// Obtener información del usuario autenticado
  static const String authMe = '/api/v1/auth/me';

  /// Obtener permisos del módulo de grilla de permisos
  static const String authPermissions = '/api/v1/permisionsByModule/3';

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
  static String productsUploadImage(int productId) =>
      '/api/v1/products/$productId/uploadImageProduct';

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
  static String brandsByCategory(int categoryId) =>
      '/api/v1/brands/category/$categoryId';

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
  // CHAT (Node WebSocket Service)
  // ============================================================================
  static const String chatApiBaseUrl = String.fromEnvironment(
    'CHAT_API_BASE_URL',
    defaultValue: 'https://wschat.vcommunity.cloud',
  );

  static const String chatWebSocketBaseUrl = String.fromEnvironment(
    'CHAT_WS_BASE_URL',
    defaultValue: 'https://wschat.vcommunity.cloud',
  );

  static String get resolvedChatApiBaseUrl => chatApiBaseUrl;

  static String get resolvedChatWebSocketBaseUrl {
    return chatWebSocketBaseUrl;
  }

  static const String chatApiPath = '/api/chat';
  static const String chatWebSocketPath = '/ws';

  static const String chatPushTokensPath = '/devices/push-tokens';

  static String get chatWebSocketUrl {
    final base = resolvedChatWebSocketBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base$chatWebSocketPath';
  }

  // ============================================================================
  // VIDEOS / TRAINING
  // Endpoints para gestión de videos de entrenamiento
  // ============================================================================

  /// Listar todos los videos
  static const String videosList = '/api/v1/videos';

  /// Obtener un video por ID
  static String videosGet(int id) => '/api/v1/videos/$id';

  /// Crear un nuevo video
  static const String videosCreate = '/api/v1/videos';

  /// Actualizar un video
  static String videosUpdate(int id) => '/api/v1/videos/$id';

  /// Eliminar un video
  static String videosDelete(int id) => '/api/v1/videos/$id';

  // ============================================================================
  // EVENTOS
  // Endpoints para gestión de eventos y sus itinerarios
  // ============================================================================

  /// Listar todos los eventos
  static const String eventsList = '/api/v1/events';

  /// Crear un evento
  static const String eventsCreate = '/api/v1/events';

  /// Obtener un evento por ID
  static String eventsGet(int id) => '/api/v1/events/$id';

  /// Actualizar un evento por ID
  static String eventsUpdate(int id) => '/api/v1/events/$id';

  /// Eliminar un evento por ID
  static String eventsDelete(int id) => '/api/v1/events/$id';

  // ============================================================================
  // HUB
  // Endpoints para publicaciones estilo feed
  // ============================================================================

  /// Listar publicaciones del Hub
  static const String hubPostsList = '/api/v1/hub/posts';

  /// Ver detalle del post (admite UUID o numérico)
  static String hubPostDetail(dynamic post) => '/api/v1/hub/posts/$post';

  /// Listar comentarios de un post (admite UUID o numérico)
  static String hubPostComments(dynamic post) =>
      '/api/v1/hub/posts/$post/comments';

  /// Crear/actualizar comentario de un post (nuevo endpoint con body JSON)
  static const String hubPostCommentsCreate = '/api/v1/hub/post-comments';

  /// Resumen de reacciones de un post (admite UUID o numérico)
  static String hubPostReactions(dynamic post) =>
      '/api/v1/hub/posts/$post/reactions';

  /// Crear/actualizar reacción a un post (nuevo endpoint con body JSON)
  static const String hubPostReactionsCreate = '/api/v1/hub/post-reactions';

  /// Resumen de reacciones de un comentario (post admite UUID o numérico)
  static String hubCommentReactions(dynamic post, dynamic commentId) =>
      '/api/v1/hub/posts/$post/comments/$commentId/reactions';

  /// Crear/actualizar reacción a un comentario (nuevo endpoint con body JSON)
  static const String hubCommentReactionsCreate =
      '/api/v1/hub/comment-reactions';

  /// Listar tags del Hub
  static const String hubTagsList = '/api/v1/hub/tags';

  // ============================================================================
  // MODELO (Rol Modelo)
  // Endpoints para dashboard de modelos
  // ============================================================================

  /// Obtener saldo disponible del modelo
  static const String modelsBalance = '/api/v1/models/balance';

  /// Obtener próximo entrenamiento del modelo
  static const String modelsNextTraining = '/api/v1/models/next-training';

  // ============================================================================
  // PRODUCCIONES
  // Endpoints para registros de producción por modelo
  // ============================================================================

  /// Listar registros de producción de un modelo en un rango de fechas
  /// Parámetros query: start_date (YYYY-MM-DD), end_date (YYYY-MM-DD)
  static String productionsByModel(String modelId) =>
      '/api/v1/productions/model/$modelId';

  /// Calcular liquidación de pago para un período
  /// Body: { id_model, start_date, end_date }
  static const String productionsCalculatePayment =
      '/api/v1/productions/calculate-payment';

  /// Listar liquidaciones (desprendibles) generados
  /// Parámetros query: id_model, per_page, page, start_date, end_date
  static const String productionsLiquidations =
      '/api/v1/productions/liquidations';

  // ============================================================================
  // DEDUCCIONES
  // Endpoints para deducciones aplicadas a modelos
  // ============================================================================

  /// Listar deducciones de un modelo en un rango de fechas
  /// Parámetros query: start_date (YYYY-MM-DD), end_date (YYYY-MM-DD)
  static String deductionsByModel(String modelId) =>
      '/api/v1/deductions/model/$modelId';

  // ============================================================================
  // TRM (Tasa de cambio)
  // ============================================================================

  /// Obtener la TRM (tasa de cambio USD→COP) más reciente
  static const String trmLatest = '/api/v1/trm/latest';
}
