import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcom_app/core/pwa/pwa_platform.dart';

/// Preferencia de sonido en PWA instalada (no hay API nativa del navegador).
class PwaAudioPermissionService {
  PwaAudioPermissionService._();
  static final PwaAudioPermissionService instance = PwaAudioPermissionService._();

  static const _askedKey = 'pwa_audio_permission_asked';
  static const _grantedKey = 'pwa_audio_permission_granted';

  bool? _cachedGranted;
  bool _cachedAsked = false;

  /// PWA instalada y aún no se ha preguntado al usuario.
  bool get shouldAskPermission =>
      kIsWeb && isStandalonePwa && !_cachedAsked;

  /// Reproducir con sonido en PWA (solo si el usuario lo permitió).
  bool get shouldPlayWithSound =>
      kIsWeb && isStandalonePwa && (_cachedGranted ?? false);

  Future<void> initialize() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedAsked = prefs.getBool(_askedKey) ?? false;
    _cachedGranted = prefs.getBool(_grantedKey);
  }

  Future<void> saveChoice({required bool granted}) async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
    await prefs.setBool(_grantedKey, granted);
    _cachedAsked = true;
    _cachedGranted = granted;
  }
}
