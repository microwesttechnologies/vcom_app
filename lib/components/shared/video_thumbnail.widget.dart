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

class _VideoThumbnailState extends State<VideoThumbnail>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _isLoading = true;
      _hasError = false;
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      _controller = controller;

      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado');
        },
      );

      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }

      await controller.seekTo(Duration.zero);
      await controller.pause();
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && _controller == controller) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
              color: VcomColors.oroLujoso.withValues(alpha: 0.5),
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
