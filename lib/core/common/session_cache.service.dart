import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

/// Cache cifrado por sesión para reutilizar payloads de red mientras el usuario
/// siga autenticado. Se invalida en logout/expiración.
class SessionCacheService {
  static final SessionCacheService _instance = SessionCacheService._internal();
  factory SessionCacheService() => _instance;
  SessionCacheService._internal();

  static const String _prefix = 'session_cache::';
  static const String _indexKey = 'session_cache::__index__';
  static const String _salt = 'vcom-session-cache-v1';

  final Map<String, String?> _memory = {};
  SharedPreferences? _prefs;
  String? _sessionSecret;

  void bindToken(String token) {
    _sessionSecret = _deriveSecret(token);
  }

  String scopedKey(
    String namespace, {
    required String role,
    required String userId,
    String suffix = '',
  }) {
    final normalizedSuffix = suffix.trim();
    return [
      role.trim().toUpperCase(),
      userId.trim(),
      namespace.trim(),
      if (normalizedSuffix.isNotEmpty) normalizedSuffix,
    ].join('::');
  }

  Future<String?> read(String key) async {
    if (_memory.containsKey(key)) {
      return _memory[key];
    }

    final prefs = await _getPrefs();
    final encryptedValue = prefs.getString('$_prefix$key');
    if (encryptedValue == null || encryptedValue.isEmpty) {
      _memory[key] = null;
      return null;
    }

    final secret = _resolveSecret();
    if (secret == null) {
      await remove(key);
      return null;
    }

    try {
      final value = _decrypt(encryptedValue, secret);
      _memory[key] = value;
      return value;
    } catch (_) {
      await remove(key);
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    final secret = _resolveSecret();
    if (secret == null || value.isEmpty) return;

    final prefs = await _getPrefs();
    final encryptedValue = _encrypt(value, secret);
    await prefs.setString('$_prefix$key', encryptedValue);

    final keys = prefs.getStringList(_indexKey) ?? const <String>[];
    if (!keys.contains(key)) {
      await prefs.setStringList(_indexKey, [...keys, key]);
    }

    _memory[key] = value;
  }

  Future<void> remove(String key) async {
    _memory.remove(key);
    final prefs = await _getPrefs();
    await prefs.remove('$_prefix$key');

    final keys = prefs.getStringList(_indexKey) ?? const <String>[];
    if (keys.contains(key)) {
      await prefs.setStringList(
        _indexKey,
        keys.where((entry) => entry != key).toList(growable: false),
      );
    }
  }

  Future<void> removeByPrefix(String prefix) async {
    final prefs = await _getPrefs();
    final keys = prefs.getStringList(_indexKey) ?? const <String>[];
    final toRemove = keys
        .where((entry) => entry.startsWith(prefix))
        .toList(growable: false);

    for (final key in toRemove) {
      _memory.remove(key);
      await prefs.remove('$_prefix$key');
    }

    if (toRemove.isNotEmpty) {
      await prefs.setStringList(
        _indexKey,
        keys
            .where((entry) => !entry.startsWith(prefix))
            .toList(growable: false),
      );
    }
  }

  Future<void> clearSession() async {
    final prefs = await _getPrefs();
    final keys = prefs.getStringList(_indexKey) ?? const <String>[];

    for (final key in keys) {
      await prefs.remove('$_prefix$key');
    }

    await prefs.remove(_indexKey);
    _memory.clear();
    _sessionSecret = null;
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String? _resolveSecret() {
    final existing = _sessionSecret;
    if (existing != null && existing.isNotEmpty) return existing;
    return null;
  }

  String _deriveSecret(String token) {
    return sha256.convert(utf8.encode('$_salt::$token')).toString();
  }

  String _encrypt(String value, String secret) {
    final keyBytes = sha256.convert(utf8.encode(secret)).bytes;
    final aesKey = encrypt.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(aesKey, mode: encrypt.AESMode.cbc),
    );
    final encryptedValue = encrypter.encrypt(value, iv: iv);
    return '${iv.base64}:${encryptedValue.base64}';
  }

  String _decrypt(String value, String secret) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid encrypted session cache payload');
    }

    final keyBytes = sha256.convert(utf8.encode(secret)).bytes;
    final aesKey = encrypt.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encryptedValue = encrypt.Encrypted.fromBase64(parts[1]);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(aesKey, mode: encrypt.AESMode.cbc),
    );

    return encrypter.decrypt(encryptedValue, iv: iv);
  }
}
