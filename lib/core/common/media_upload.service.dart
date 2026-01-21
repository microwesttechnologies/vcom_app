import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'envirotment.dev.dart';
import 'token.service.dart';

/// Servicio para manejar la carga de archivos multimedia
class MediaUploadService {
  final TokenService _tokenService = TokenService();
  final ImagePicker _picker = ImagePicker();

  /// Selecciona una imagen de la galería o cámara
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

      // Validar tamaño máximo (30MB)
      if (fileSize > 30 * 1024 * 1024) {
        throw Exception('La imagen no debe superar los 30MB');
      }

      return file;
    } catch (e) {
      print('❌ Error al seleccionar imagen: $e');
      rethrow;
    }
  }

  /// Selecciona un video de la galería o cámara
  Future<File?> pickVideo({bool fromCamera = false}) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video == null) return null;

      final file = File(video.path);
      final fileSize = await file.length();

      // Validar tamaño máximo (50MB)
      if (fileSize > 50 * 1024 * 1024) {
        throw Exception('El video no debe superar los 50MB');
      }

      // Validar duración del video
      final isValid = await _validateVideoDuration(file);
      if (!isValid) {
        throw Exception('El video no debe superar 1 minuto de duración');
      }

      return file;
    } catch (e) {
      print('❌ Error al seleccionar video: $e');
      rethrow;
    }
  }

  /// Valida que el video no supere 1 minuto de duración
  Future<bool> _validateVideoDuration(File videoFile) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      final duration = controller.value.duration;
      final isValid = duration.inSeconds <= 60;

      print('📹 Duración del video: ${duration.inSeconds}s');
      return isValid;
    } catch (e) {
      print('⚠️ Error al validar duración del video: $e');
      return false;
    } finally {
      await controller?.dispose();
    }
  }

  /// Sube un archivo al servidor
  Future<String> uploadFile({
    required File file,
    required String type, // 'image' o 'video'
  }) async {
    try {
      final url = Uri.parse('${EnvironmentDev.baseUrl}/api/v1/chat/upload-media');
      final request = http.MultipartRequest('POST', url);

      // Agregar headers de autenticación
      final token = _tokenService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Agregar el archivo
      final fileName = file.path.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ),
      );

      // Agregar el tipo de archivo
      request.fields['type'] = type;

      print('📤 Subiendo archivo: $fileName');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Timeout al subir archivo');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('📤 Status Code: ${response.statusCode}');
      print('📤 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final fileUrl = data['url'] as String;
        print('✅ Archivo subido: $fileUrl');
        return fileUrl;
      } else {
        print('❌ Error Response: ${response.body}');
        throw Exception('Error al subir archivo: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error en uploadFile: $e');
      rethrow;
    }
  }

  /// Selecciona y sube una imagen (SIN COMPRESIÓN - el backend lo maneja)
  Future<String?> selectAndUploadImage({bool fromCamera = false}) async {
    try {
      print('📸 Seleccionando imagen...');
      
      final file = await pickImage(fromCamera: fromCamera);
      if (file == null) {
        print('⚠️ Usuario canceló la selección');
        return null;
      }
      
      final originalSize = await file.length();
      print('✅ Imagen seleccionada: ${(originalSize / 1024).toStringAsFixed(2)} KB');
      
      // Subir imagen DIRECTAMENTE (backend se encarga de comprimir)
      print('📤 Subiendo imagen al servidor...');
      final url = await uploadFile(file: file, type: 'image');
      
      print('✅ Imagen subida exitosamente: $url');
      
      return url;
    } catch (e) {
      print('❌ Error en selectAndUploadImage: $e');
      rethrow;
    }
  }

  /// Selecciona y sube un video
  Future<String?> selectAndUploadVideo({bool fromCamera = false}) async {
    try {
      final file = await pickVideo(fromCamera: fromCamera);
      if (file == null) return null;

      final url = await uploadFile(file: file, type: 'video');
      return url;
    } catch (e) {
      print('❌ Error en selectAndUploadVideo: $e');
      rethrow;
    }
  }
}
