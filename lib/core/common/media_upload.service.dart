import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'envirotment.dev.dart';
import 'token.service.dart';

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

/// Servicio para manejar la carga de archivos multimedia.
class MediaUploadService {
  final TokenService _tokenService = TokenService();
  final ImagePicker _picker = ImagePicker();

  static const int _chatImageQuality = 50;

  /// Selecciona una imagen de galeria o camara.
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (image == null) return null;

      final file = File(image.path);
      final fileSize = await file.length();

      if (fileSize > 30 * 1024 * 1024) {
        throw Exception('La imagen no debe superar los 30MB');
      }

      return file;
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      rethrow;
    }
  }

  /// Selecciona un video de galeria o camara.
  Future<File?> pickVideo({bool fromCamera = false}) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video == null) return null;

      final file = File(video.path);
      final fileSize = await file.length();

      if (fileSize > 50 * 1024 * 1024) {
        throw Exception('El video no debe superar los 50MB');
      }

      final isValid = await _validateVideoDuration(file);
      if (!isValid) {
        throw Exception('El video no debe superar 1 minuto de duracion');
      }

      return file;
    } catch (e) {
      debugPrint('Error al seleccionar video: $e');
      rethrow;
    }
  }

  Future<bool> _validateVideoDuration(File videoFile) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      final duration = controller.value.duration;
      return duration.inSeconds <= 60;
    } catch (_) {
      return false;
    } finally {
      await controller?.dispose();
    }
  }

  Future<File> _compressImageForChat(File originalFile) async {
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${tempDir.path}${Platform.pathSeparator}chat_$now.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      outputPath,
      quality: _chatImageQuality,
      format: CompressFormat.jpeg,
      minWidth: 720,
      minHeight: 720,
      keepExif: false,
    );

    if (compressed == null) {
      return originalFile;
    }

    final compressedFile = File(compressed.path);
    final originalSize = await originalFile.length();
    final compressedSize = await compressedFile.length();

    if (compressedSize <= 0) {
      return originalFile;
    }

    return compressedSize <= originalSize ? compressedFile : originalFile;
  }

  /// Sube un archivo al servidor.
  Future<ChatUploadResult> uploadFile({
    required File file,
    required String type, // image o video
    int? conversationId,
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

      final fileName = file.path.split(Platform.pathSeparator).last;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
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

      throw Exception('Error al subir archivo: ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('Error en uploadFile: $e');
      rethrow;
    }
  }

  /// Selecciona y sube una imagen comprimida al 50%.
  Future<String?> selectAndUploadImage({
    bool fromCamera = false,
    int? conversationId,
  }) async {
    try {
      final file = await pickImage(fromCamera: fromCamera);
      if (file == null) return null;

      final originalSize = await file.length();
      final compressedFile = await _compressImageForChat(file);
      final compressedSize = await compressedFile.length();

      final reduction = originalSize > 0
          ? max(0, 100 - ((compressedSize * 100) / originalSize)).toStringAsFixed(1)
          : '0.0';

      debugPrint(
        'Imagen chat comprimida ($_chatImageQuality%): '
        '${(originalSize / 1024).toStringAsFixed(1)}KB -> '
        '${(compressedSize / 1024).toStringAsFixed(1)}KB '
        '(reduccion $reduction%)',
      );

      ChatUploadResult upload;
      try {
        upload = await uploadFile(
          file: compressedFile,
          type: 'image',
          conversationId: conversationId,
        );
      } catch (e) {
        final shouldRetryWithoutConversation =
            conversationId != null && _shouldRetryWithoutConversationId(e.toString());
        if (!shouldRetryWithoutConversation) rethrow;

        upload = await uploadFile(
          file: compressedFile,
          type: 'image',
          conversationId: null,
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
  }) async {
    try {
      final file = await pickVideo(fromCamera: fromCamera);
      if (file == null) return null;

      ChatUploadResult upload;
      try {
        upload = await uploadFile(
          file: file,
          type: 'video',
          conversationId: conversationId,
        );
      } catch (e) {
        final shouldRetryWithoutConversation =
            conversationId != null && _shouldRetryWithoutConversationId(e.toString());
        if (!shouldRetryWithoutConversation) rethrow;

        upload = await uploadFile(
          file: file,
          type: 'video',
          conversationId: null,
        );
      }
      return upload;
    } catch (e) {
      debugPrint('Error en selectAndUploadVideo: $e');
      rethrow;
    }
  }

  String _resolveUploadedFileUrl(Map<String, dynamic> data) {
    final rawUrl = (data['url'] ?? '').toString().trim();
    if (rawUrl.isNotEmpty) return rawUrl;

    final rawPath = (data['path'] ?? '').toString().trim();
    if (rawPath.isEmpty) return '';

    final normalizedPath = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    return '${EnvironmentDev.resolvedChatApiBaseUrl}/media/chat$normalizedPath';
  }

  bool _shouldRetryWithoutConversationId(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('403') ||
        normalized.contains('404') ||
        normalized.contains('conversation_id') ||
        normalized.contains('no tienes acceso');
  }
}
