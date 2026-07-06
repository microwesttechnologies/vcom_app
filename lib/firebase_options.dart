import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:vcom_app/core/common/firebase_env.dart';

/// Opciones Firebase para web (y fallback nativo si no hay google-services.json).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return web;
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: FirebaseEnv.apiKey,
    appId: FirebaseEnv.appId,
    messagingSenderId: FirebaseEnv.messagingSenderId,
    projectId: FirebaseEnv.projectId,
    authDomain: FirebaseEnv.authDomain.isEmpty
        ? '${FirebaseEnv.projectId}.firebaseapp.com'
        : FirebaseEnv.authDomain,
    storageBucket: FirebaseEnv.storageBucket.isEmpty
        ? '${FirebaseEnv.projectId}.appspot.com'
        : FirebaseEnv.storageBucket,
  );

  static FirebaseOptions get android => web;
  static FirebaseOptions get ios => web;
  static FirebaseOptions get macos => web;
}
