import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:vcom_app/core/training/training_video_cache.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Miniatura del primer frame: usa archivo en caché si existe (sin red);
/// si no, preview por red y descarga en segundo plano para la próxima vez.
class VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  final Map<String, String>? httpHeaders;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const VideoThumbnail({
    super.key,
    required this.videoUrl,
    this.httpHeaders,
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
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  late final AnimationController _shimmerController;

  static const Color _shimmerBase = Color(0xFF152036);
  static const Color _shimmerHighlight = Color(0xFF2E4168);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        !_mapEquals(oldWidget.httpHeaders, widget.httpHeaders)) {
      unawaited(_disposeController());
      _isLoading = true;
      _hasError = false;
      _shimmerController.repeat();
      _loadThumbnail();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    unawaited(_disposeController());
    super.dispose();
  }

  bool _mapEquals(Map<String, String>? a, Map<String, String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  Future<VideoPlayerController> _createController(String url) async {
    if (TrainingVideoCache.isStreamUrl(url)) {
      return VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: widget.httpHeaders ?? const {},
      );
    }
    final trimmed = url.trim();
    final cached = await TrainingVideoCache.instance.getLocalFileIfCached(
      trimmed,
    );
    if (cached != null) {
      return VideoPlayerController.file(cached);
    }
    unawaited(_precacheForFullPlayer(trimmed));
    return VideoPlayerController.networkUrl(
      Uri.parse(trimmed),
      httpHeaders: widget.httpHeaders ?? const {},
    );
  }

  Future<void> _precacheForFullPlayer(String url) async {
    try {
      await TrainingVideoCache.instance.ensureCached(
        url,
        headers: widget.httpHeaders,
      );
    } catch (e) {
      debugPrint('[VideoThumbnail] precache: $e');
    }
  }

  Future<void> _seekPreviewFrame(VideoPlayerController c) async {
    try {
      await c.seekTo(const Duration(milliseconds: 200));
    } catch (_) {
      try {
        await c.seekTo(Duration.zero);
      } catch (_) {}
    }
    await c.pause();
  }

  Future<void> _loadThumbnail() async {
    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        _shimmerController.stop();
      }
      return;
    }

    try {
      final controller = await _createController(url);
      _controller = controller;

      await controller.initialize().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('inicializar vídeo');
        },
      );

      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(false);
      await controller.setVolume(0);
      await _seekPreviewFrame(controller);

      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }

      if (mounted && _controller == controller) {
        _shimmerController.stop();
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('[VideoThumbnail] $e');
      if (mounted) {
        _shimmerController.stop();
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

  Widget _defaultShimmerPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final t = _shimmerController.value;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(-1.2 + t * 2.4, 0),
                  end: Alignment(0.2 + t * 2.4, 0),
                  colors: const [_shimmerBase, _shimmerHighlight, _shimmerBase],
                  stops: const [0.25, 0.5, 0.75],
                ).createShader(bounds);
              },
              child: child,
            );
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return widget.placeholder ?? _defaultShimmerPlaceholder();
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
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
