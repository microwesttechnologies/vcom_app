/// Servicio para gestionar el token de autenticación y datos del usuario
class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  String? _token;
  String? _role;
  String? _userName;
  String? _userId;

  /// Guarda el token de autenticación
  void setToken(String token) {
    _token = token;
  }

  /// Obtiene el token de autenticación
  String? getToken() {
    return _token;
  }

  /// Guarda el rol del usuario
  void setRole(String role) {
    _role = role;
  }

  /// Obtiene el rol del usuario
  String? getRole() {
    return _role;
  }

  /// Guarda el nombre del usuario
  void setUserName(String name) {
    _userName = name;
  }

  /// Obtiene el nombre del usuario
  String? getUserName() {
    return _userName;
  }

  /// Guarda el ID del usuario
  void setUserId(String id) {
    _userId = id;
  }

  /// Obtiene el ID del usuario
  String? getUserId() {
    return _userId;
  }

  /// Verifica si hay un token guardado
  bool hasToken() {
    return _token != null && _token!.isNotEmpty;
  }

  /// Limpia todos los datos de autenticación
  void clear() {
    _token = null;
    _role = null;
    _userName = null;
    _userId = null;
  }

  /// Obtiene el header de autorización para las peticiones HTTP
  Map<String, String> getAuthHeaders() {
    if (_token == null) {
      return {};
    }
    return {
      'Authorization': 'Bearer $_token',
    };
  }
}

