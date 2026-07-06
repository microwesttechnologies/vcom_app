import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/media_upload_video_validate.dart';
import 'package:vcom_app/core/common/token.service.dart';

class ChatUploadResult {
  final String url;
  final String? thumbnailUrl;
  final String? contentType;

  const ChatUploadResult({
    required this.url,
    this.thumbnailUrl,
    this.contentType,
  });
}

/// Archivo en memoria listo para multipart (web y nativo).
class MediaUploadPayload {
  const MediaUploadPayload({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;

  static String guessMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }

  static String resolveFilename(String name, {required String fallback}) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed : fallback;
  }
}

/// Servicio para seleccionar y subir archivos multimedia (web/PWA y nativo).
class MediaUploadService {
  MediaUploadService();

  final TokenService _tokenService = TokenService();
  final ImagePicker _picker = ImagePicker();

  static const int _chatImageQuality = 50;

  /// Selecciona una imagen de galería o cámara.
  Future<MediaUploadPayload?> pickImage({bool fromCamera = false}) async {
    try {
      if (kIsWeb && fromCamera) {
        throw Exception('La cámara no está disponible en la versión web');
      }

      final xFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      if (xFile == null) return null;

      final bytes = await xFile.readAsBytes();
      if (bytes.length > 30 * 1024 * 1024) {
        throw Exception('La imagen no debe superar los 30MB');
      }

      return MediaUploadPayload(
        bytes: bytes,
        filename: MediaUploadPayload.resolveFilename(
          xFile.name,
          fallback: 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        mimeType: MediaUploadPayload.guessMimeType(xFile.name),
      );
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      rethrow;
    }
  }

  /// Selecciona un video de galería o cámara.
  Future<MediaUploadPayload?> pickVideo({bool fromCamera = false}) async {
    try {
      if (kIsWeb && fromCamera) {
        throw Exception('La cámara no está disponible en la versión web');
      }

      final xFile = await _picker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );
      if (xFile == null) return null;

      final bytes = await xFile.readAsBytes();
      if (bytes.length > 50 * 1024 * 1024) {
        throw Exception('El video no debe superar los 50MB');
      }

      final filename = MediaUploadPayload.resolveFilename(
        xFile.name,
        fallback: 'chat_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      final isValid = await validateChatVideoDuration(bytes, filename);
      if (!isValid) {
        throw Exception('El video no debe superar 1 minuto de duración');
      }

      return MediaUploadPayload(
        bytes: bytes,
        filename: filename,
        mimeType: MediaUploadPayload.guessMimeType(filename),
      );
    } catch (e) {
      debugPrint('Error al seleccionar video: $e');
      rethrow;
    }
  }

  Future<Uint8List> _compressImageBytesForChat(Uint8List original) async {
    if (kIsWeb) return original;

    try {
      final compressed = await FlutterImageCompress.compressWithList(
        original,
        quality: _chatImageQuality,
        format: CompressFormat.jpeg,
        minWidth: 720,
        minHeight: 720,
        keepExif: false,
      );
      if (compressed.isNotEmpty && compressed.length < original.length) {
        return compressed;
      }
    } catch (e) {
      debugPrint('Compresión chat falló, usando original: $e');
    }
    return original;
  }

  /// Sube bytes al servidor de chat.
  Future<ChatUploadResult> uploadPayload({
    required MediaUploadPayload payload,
    required String type,
    int? conversationId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final url = Uri.parse(
        '${EnvironmentDev.resolvedChatApiBaseUrl}${EnvironmentDev.chatApiPath}/media/upload',
      );
      final request = http.MultipartRequest('POST', url);

      final token = _tokenService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        http.MultipartFile(
          'file',
          _byteStreamWithProgress(
            payload.bytes,
            onProgress: onProgress == null
                ? null
                : (sent, total) {
                    if (total <= 0) return;
                    onProgress(sent / total);
                  },
          ),
          payload.bytes.length,
          filename: payload.filename,
        ),
      );

      request.fields['type'] = type;
      if (conversationId != null && conversationId > 0) {
        request.fields['conversation_id'] = '$conversationId';
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Timeout al subir archivo'),
      );

      final response = await http.Response.fromStream(streamedResponse);
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final resolvedUrl = _resolveUploadedFileUrl(data);
        return ChatUploadResult(
          url: resolvedUrl,
          thumbnailUrl: (data['thumbnail_url'] ?? '').toString().trim().isEmpty
              ? null
              : (data['thumbnail_url'] ?? '').toString(),
          contentType: (data['content_type'] ?? '').toString().trim().isEmpty
              ? null
              : (data['content_type'] ?? '').toString(),
        );
      }

      throw Exception(
        'Error al subir archivo: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      debugPrint('Error en uploadPayload: $e');
      rethrow;
    }
  }

  /// Selecciona y sube una imagen comprimida.
  Future<String?> selectAndUploadImage({
    bool fromCamera = false,
    int? conversationId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final picked = await pickImage(fromCamera: fromCamera);
      if (picked == null) return null;

      final originalSize = picked.bytes.length;
      final compressedBytes = await _compressImageBytesForChat(picked.bytes);
      final compressedSize = compressedBytes.length;

      final reduction = originalSize > 0
          ? max(
              0,
              100 - ((compressedSize * 100) / originalSize),
            ).toStringAsFixed(1)
          : '0.0';

      debugPrint(
        'Imagen chat comprimida ($_chatImageQuality%): '
        '${(originalSize / 1024).toStringAsFixed(1)}KB -> '
        '${(compressedSize / 1024).toStringAsFixed(1)}KB '
        '(reduccion $reduction%)',
      );

      final filename = picked.filename.contains('.')
          ? picked.filename.replaceAll(RegExp(r'\.[^.]+$'), '.jpg')
          : '${picked.filename}.jpg';

      final payload = MediaUploadPayload(
        bytes: compressedBytes,
        filename: filename,
        mimeType: 'image/jpeg',
      );

      ChatUploadResult upload;
      try {
        upload = await uploadPayload(
          payload: payload,
          type: 'image',
          conversationId: conversationId,
          onProgress: onProgress,
        );
      } catch (e) {
        final shouldRetryWithoutConversation =
            conversationId != null &&
            _shouldRetryWithoutConversationId(e.toString());
        if (!shouldRetryWithoutConversation) rethrow;

        upload = await uploadPayload(
          payload: payload,
          type: 'image',
          conversationId: null,
          onProgress: onProgress,
        );
      }
      return upload.url;
    } catch (e) {
      debugPrint('Error en selectAndUploadImage: $e');
      rethrow;
    }
  }

  /// Selecciona y sube un video.
  Future<ChatUploadResult?> selectAndUploadVideo({
    bool fromCamera = false,
    int? conversationId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final picked = await pickVideo(fromCamera: fromCamera);
      if (picked == null) return null;

      ChatUploadResult upload;
      try {
        upload = await uploadPayload(
          payload: picked,
          type: 'video',
          conversationId: conversationId,
          onProgress: onProgress,
        );
      } catch (e) {
        final shouldRetryWithoutConversation =
            conversationId != null &&
            _shouldRetryWithoutConversationId(e.toString());
        if (!shouldRetryWithoutConversation) rethrow;

        upload = await uploadPayload(
          payload: picked,
          type: 'video',
          conversationId: null,
          onProgress: onProgress,
        );
      }
      return upload;
    } catch (e) {
      debugPrint('Error en selectAndUploadVideo: $e');
      rethrow;
    }
  }

  String _resolveUploadedFileUrl(Map<String, dynamic> data) {
    final base = EnvironmentDev.resolvedChatApiBaseUrl.replaceAll(RegExp(r'/+$'), '');

    String toAbsolute(String raw) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return '';
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return trimmed;
      }
      final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
      return '$base$path';
    }

    final url = toAbsolute((data['url'] ?? '').toString());
    if (url.isNotEmpty) return url;

    final rawPath = (data['path'] ?? '').toString().trim();
    if (rawPath.isEmpty) return '';

    final absolutePath = toAbsolute(rawPath);
    if (absolutePath.contains('/media/')) return absolutePath;

    final normalizedPath = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    return '$base/media/chat$normalizedPath';
  }

  bool _shouldRetryWithoutConversationId(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('403') ||
        normalized.contains('404') ||
        normalized.contains('conversation_id') ||
        normalized.contains('no tienes acceso');
  }

  Stream<List<int>> _byteStreamWithProgress(
    Uint8List bytes, {
    void Function(int sent, int total)? onProgress,
  }) {
    final total = bytes.length;
    const chunkSize = 32 * 1024;

    return Stream<List<int>>.multi((controller) {
      Future<void>(() async {
        try {
          for (var offset = 0; offset < bytes.length; offset += chunkSize) {
            final end = min(offset + chunkSize, bytes.length);
            controller.add(bytes.sublist(offset, end));
            onProgress?.call(end, total);
          }
          await controller.close();
        } catch (error, stackTrace) {
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
        }
      });
    });
  }
}
