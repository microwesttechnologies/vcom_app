import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Widget que muestra una miniatura del primer frame de un video
class VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const VideoThumbnail({
    super.key,
    required this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      
      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );
      
      if (!mounted) return;
      
      // Pausar el video en el primer frame
      await _controller!.seekTo(Duration.zero);
      await _controller!.pause();
      
      // Esperar un momento para que el frame se renderice
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: VcomColors.azulOverlayTransparente60,
            child: Center(
              child: CircularProgressIndicator(
                color: VcomColors.oroLujoso,
                strokeWidth: 2,
              ),
            ),
          );
    }

    if (_hasError || _controller == null || !_controller!.value.isInitialized) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: VcomColors.azulOverlayTransparente60,
            child: Icon(
              Icons.video_library,
              color: VcomColors.oroLujoso.withOpacity(0.5),
              size: 50,
            ),
          );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FittedBox(
        fit: widget.fit,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
