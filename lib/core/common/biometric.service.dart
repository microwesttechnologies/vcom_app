import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Servicio para autenticación biométrica (huella / face ID)
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Verificación conservadora: intenta múltiples APIs para detectar soporte.
  /// Muchos dispositivos (Samsung, Xiaomi, OPPO, Huawei) no responden
  /// correctamente a `canCheckBiometrics` aunque tengan sensor.
  Future<bool> isAvailable() async {
    try {
      // 1. Verificar soporte de hardware
      final supported = await _auth.isDeviceSupported();
      debugPrint('[Biometric] isDeviceSupported=$supported');
      if (!supported) return false;

      // 2. Intentar canCheckBiometrics
      final canCheck = await _auth.canCheckBiometrics;
      debugPrint('[Biometric] canCheckBiometrics=$canCheck');

      // 3. Lista de biometrías disponibles
      final types = await _auth.getAvailableBiometrics();
      debugPrint('[Biometric] availableBiometrics=$types');

      // Considerar disponible si cualquiera de los tres da positivo
      return canCheck || types.isNotEmpty;
    } catch (e) {
      debugPrint('[Biometric] isAvailable error: $e');
      return false;
    }
  }

  /// Solicita autenticación biométrica al usuario.
  /// Devuelve true si la autenticación fue exitosa.
  /// Lanza [PlatformException] con el código de error si hay un problema.
  Future<bool> authenticate() async {
    return await _auth.authenticate(
      localizedReason: 'Usa tu huella dactilar para ingresar a VCOM',
      options: const AuthenticationOptions(
        // false → permite PIN como respaldo si el sensor falla (requerido en
        // muchos dispositivos Android como Samsung, Xiaomi, OPPO, etc.)
        biometricOnly: false,
        stickyAuth: true,
        useErrorDialogs: true,
      ),
    );
  }

  /// Devuelve el mensaje de error legible a partir de un PlatformException.
  static String errorMessage(PlatformException e) {
    debugPrint('[Biometric] PlatformException code=${e.code} msg=${e.message}');
    switch (e.code) {
      case 'NotAvailable':
        return 'El sensor de huella no está disponible en este momento.\nAsegúrate de que no haya otra app usando el sensor.';
      case 'NotEnrolled':
        return 'No hay huellas registradas.\nVe a Ajustes → Seguridad → Huella dactilar y registra una.';
      case 'LockedOut':
        return 'Demasiados intentos fallidos. Intenta de nuevo en unos segundos.';
      case 'PermanentlyLockedOut':
        return 'Sensor bloqueado. Desbloquea el teléfono con tu PIN primero.';
      case 'otherOperatingSystem':
        return 'Función no disponible en este sistema operativo.';
      default:
        return e.message ?? 'Error de autenticación (${e.code})';
    }
  }
}
