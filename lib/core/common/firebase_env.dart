/// Credenciales Firebase vía `--dart-define` (no commitear secretos).
///
/// Web push también requiere `web/firebase-config.js` con los mismos valores
/// y una clave VAPID en Firebase Console → Cloud Messaging → Web Push certificates.
class FirebaseEnv {
  FirebaseEnv._();

  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String vapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty;

  static bool get isWebPushConfigured => isConfigured && vapidKey.isNotEmpty;
}
