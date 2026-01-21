import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class MessageContentWidget extends StatefulWidget {
  final String content;
  final String messageType;
  final bool isMe;

  const MessageContentWidget({
    Key? key,
    required this.content,
    required this.messageType,
    required this.isMe,
  }) : super(key: key);

  @override
  State<MessageContentWidget> createState() => _MessageContentWidgetState();
}

class _MessageContentWidgetState extends State<MessageContentWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.messageType == 'video') {
      _initializeVideo();
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
    print('🖼️ Mostrando imagen desde URL: ${widget.content}');
    
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
    // SOLUCIÓN SIMPLE: Mostrar directamente desde URL
    // Flutter maneja el caché automáticamente
    return Image.network(
      widget.content,
      fit: BoxFit.cover,
      cacheWidth: 500, // Optimización de memoria
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Imagen cargada completamente
          return child;
        }
        
        // Mostrando progreso de carga
        final progress = loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
            : null;
        
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
                value: progress,
                valueColor: AlwaysStoppedAnimation<Color>(VcomColors.oroLujoso),
              ),
              const SizedBox(height: 12),
              Text(
                progress != null 
                    ? 'Cargando ${(progress * 100).toStringAsFixed(0)}%'
                    : 'Cargando...',
                style: TextStyle(color: VcomColors.blancoCrema, fontSize: 12),
              ),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Error cargando imagen: $error');
        print('❌ URL: ${widget.content}');
        
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
                'Error al cargar',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Toca para reintentar',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        );
      },
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

  /// Muestra la imagen en pantalla completa directamente desde URL
  void _showFullImage(BuildContext context) {
    print('🖼️ Abriendo imagen en pantalla completa: ${widget.content}');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text('Imagen', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                widget.content,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  
                  final progress = loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null;
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          valueColor: AlwaysStoppedAnimation<Color>(VcomColors.oroLujoso),
                        ),
                        SizedBox(height: 16),
                        Text(
                          progress != null 
                              ? 'Cargando ${(progress * 100).toStringAsFixed(0)}%'
                              : 'Cargando...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Error en pantalla completa: $error');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 60),
                        SizedBox(height: 16),
                        Text(
                          'Error al cargar la imagen',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Verifica tu conexión',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
