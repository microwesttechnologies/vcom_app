import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para guardar y cargar credenciales de login
class CredentialsService {
  static const String _keyRememberCredentials = 'remember_credentials';
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPassword = 'saved_password';

  /// Guarda las credenciales si el usuario marcó "Recordar credenciales"
  Future<void> saveCredentials({
    required bool remember,
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_keyRememberCredentials, remember);
      
      if (remember) {
        await prefs.setString(_keySavedEmail, email);
        await prefs.setString(_keySavedPassword, password);
        debugPrint('✅ Credenciales guardadas: $email');
      } else {
        // Si no quiere recordar, eliminar las credenciales guardadas
        await prefs.remove(_keySavedEmail);
        await prefs.remove(_keySavedPassword);
        debugPrint('🗑️ Credenciales eliminadas');
      }
    } catch (e) {
      debugPrint('❌ Error al guardar credenciales: $e');
      // Si hay error con shared_preferences, simplemente ignorar
      // No queremos que esto bloquee el login
    }
  }

  /// Carga las credenciales guardadas
  Future<Map<String, String?>> loadCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final remember = prefs.getBool(_keyRememberCredentials) ?? false;
      
      if (remember) {
        final email = prefs.getString(_keySavedEmail);
        final password = prefs.getString(_keySavedPassword);
        debugPrint('📥 Credenciales cargadas: $email');
        return {
          'email': email,
          'password': password,
          'remember': 'true',
        };
      }
      
      debugPrint('ℹ️ No hay credenciales guardadas');
      return {
        'email': null,
        'password': null,
        'remember': 'false',
      };
    } catch (e) {
      debugPrint('❌ Error al cargar credenciales: $e');
      // Si hay error con shared_preferences, retornar valores por defecto
      return {
        'email': null,
        'password': null,
        'remember': 'false',
      };
    }
  }

  /// Verifica si hay credenciales guardadas
  Future<bool> hasSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRememberCredentials) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Elimina las credenciales guardadas
  Future<void> clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberCredentials);
      await prefs.remove(_keySavedEmail);
      await prefs.remove(_keySavedPassword);
    } catch (e) {
      // Si hay error, simplemente ignorar
    }
  }
}

