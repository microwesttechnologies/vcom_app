import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Widget para mostrar el contenido de un mensaje (texto, imagen o video)
class MessageContentWidget extends StatefulWidget {
  final String content;
  final String messageType; // 'text', 'image', 'video'
  final bool isMe;

  const MessageContentWidget({
    super.key,
    required this.content,
    required this.messageType,
    required this.isMe,
  });

  @override
  State<MessageContentWidget> createState() => _MessageContentWidgetState();
}

class _MessageContentWidgetState extends State<MessageContentWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  File? _imageFile;
  bool _isLoadingImage = false;
  bool _imageError = false;

  @override
  void initState() {
    super.initState();
    if (widget.messageType == 'video') {
      _initializeVideo();
    } else if (widget.messageType == 'image') {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (_isLoadingImage || _imageFile != null) return;
    
    setState(() {
      _isLoadingImage = true;
      _imageError = false;
    });

    try {
      print('📥 Descargando imagen al dispositivo: ${widget.content}');
      
      // Obtener el nombre único del archivo desde la URL
      final uri = Uri.parse(widget.content);
      final fileName = uri.pathSegments.last;
      
      // Obtener el directorio temporal del dispositivo
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      // Verificar si ya existe el archivo descargado
      if (await file.exists()) {
        print('✅ Imagen ya existe en cache: $filePath');
        if (!mounted) return;
        setState(() {
          _imageFile = file;
          _isLoadingImage = false;
        });
        return;
      }
      
      print('📥 Descargando desde: ${widget.content}');
      print('💾 Guardando en: $filePath');
      
      // Descargar la imagen con manejo robusto
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(widget.content));
        final response = await client.send(request).timeout(
          const Duration(seconds: 30),
        );
        
        print('📥 Status Code: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          // Descargar por chunks y guardar
          final bytes = <int>[];
          await for (var chunk in response.stream) {
            bytes.addAll(chunk);
          }
          
          await file.writeAsBytes(bytes);
          print('✅ Imagen descargada y guardada: ${bytes.length} bytes');
          
          if (!mounted) return;
          setState(() {
            _imageFile = file;
            _isLoadingImage = false;
          });
        } else {
          throw Exception('Error HTTP ${response.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('❌ Error descargando imagen: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingImage = false;
        _imageError = true;
      });
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.content));
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print('❌ Error al inicializar video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.messageType) {
      case 'image':
        return _buildImageContent();
      case 'video':
        return _buildVideoContent();
      case 'text':
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    return Text(
      widget.content,
      style: TextStyle(
        color: widget.isMe
            ? VcomColors.azulMedianocheTexto
            : VcomColors.blancoCrema,
        fontSize: 15,
      ),
    );
  }

  Widget _buildImageContent() {
    print('🖼️ Construyendo imagen con URL: ${widget.content}');
    print('🖼️ Es mío?: ${widget.isMe}');
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () => _showFullImage(context),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 250,
            maxHeight: 300,
          ),
          child: _buildImageWidget(),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_isLoadingImage) {
      return Container(
        width: 200,
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(VcomColors.oroLujoso),
            ),
            const SizedBox(height: 12),
            Text(
              'Descargando imagen...',
              style: TextStyle(color: VcomColors.blancoCrema, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_imageError) {
      return Container(
        width: 200,
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(
              'Error al descargar',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: VcomColors.oroLujoso,
                foregroundColor: VcomColors.azulMedianocheTexto,
              ),
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_imageFile != null && _imageFile!.existsSync()) {
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
      );
    }

    return Container(
      width: 200,
      height: 200,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(VcomColors.oroLujoso),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        width: 250,
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(VcomColors.oroLujoso),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () => _showFullVideo(context),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 250,
            maxHeight: 200,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(_videoController!.value.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(widget.content),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullVideo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
