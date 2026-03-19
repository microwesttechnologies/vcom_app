import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para guardar y cargar credenciales de login
class CredentialsService {
  static const String _keyRememberCredentials = 'remember_credentials';
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPassword = 'saved_password';
  // Bandera exclusiva: solo true cuando el usuario activa la huella manualmente
  static const String _keyBiometricEnabled = 'biometric_enabled';
  // Credenciales exclusivas para huella (no se sobrescriben con "Recordar credenciales")
  static const String _keyBiometricEmail = 'biometric_email';
  static const String _keyBiometricPassword = 'biometric_password';

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

  // ── Huella biométrica ──────────────────────────────────────────────────────

  /// true solo si el usuario activó explícitamente la autenticación por huella
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyBiometricEnabled) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Activa o desactiva la bandera de huella biométrica
  Future<void> setBiometricEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBiometricEnabled, value);
    } catch (_) {}
  }

  /// Guarda las credenciales asociadas a la huella (solo para login biométrico).
  /// No se sobrescriben con "Recordar credenciales" del login normal.
  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBiometricEmail, email);
      await prefs.setString(_keyBiometricPassword, password);
      debugPrint('✅ Credenciales biométricas guardadas: $email');
    } catch (e) {
      debugPrint('❌ Error al guardar credenciales biométricas: $e');
    }
  }

  /// Carga las credenciales guardadas para login con huella.
  /// Retorna null en email o password si no hay credenciales biométricas.
  Future<Map<String, String?>> loadBiometricCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_keyBiometricEmail);
      final password = prefs.getString(_keyBiometricPassword);
      return {'email': email, 'password': password};
    } catch (e) {
      debugPrint('❌ Error al cargar credenciales biométricas: $e');
      return {'email': null, 'password': null};
    }
  }

  /// Desactiva la huella y borra las credenciales biométricas
  Future<void> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBiometricEnabled, false);
      await prefs.remove(_keyBiometricEmail);
      await prefs.remove(_keyBiometricPassword);
    } catch (_) {}
  }
}

