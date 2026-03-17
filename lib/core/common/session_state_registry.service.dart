import 'package:flutter/foundation.dart';

/// Registro simple de estado en memoria que debe limpiarse al cerrar sesión.
class SessionStateRegistryService {
  static final SessionStateRegistryService _instance =
      SessionStateRegistryService._internal();
  factory SessionStateRegistryService() => _instance;
  SessionStateRegistryService._internal();

  final Map<String, VoidCallback> _clearers = <String, VoidCallback>{};

  void register(String key, VoidCallback clearCallback) {
    _clearers[key] = clearCallback;
  }

  void unregister(String key) {
    _clearers.remove(key);
  }

  void clearAll() {
    for (final clear in _clearers.values) {
      clear();
    }
  }
}
