import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/core/models/video.model.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página completa (uso con Navigator.push, ej. desde dashboard)
class VideoPlayerPage extends StatelessWidget {
  final VideoModel video;

  const VideoPlayerPage({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const ModeloNavbar(showBackButton: true),
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'training'),
      body: VideoPlayerBody(video: video),
    );
  }
}

/// Contenido del reproductor (video + info) reutilizable
class VideoPlayerBody extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerBody({super.key, required this.video});

  @override
  State<VideoPlayerBody> createState() => _VideoPlayerBodyState();
}

class _VideoPlayerBodyState extends State<VideoPlayerBody> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _disposed = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // Ocultar controles después de 3 segundos
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      final videoUrl = widget.video.urlSource;
      if (videoUrl.isEmpty) {
        if (mounted) setState(() => _isInitialized = false);
        return;
      }

      final ctrl = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _controller = ctrl;

      ctrl
          .initialize()
          .then((_) {
            if (_disposed || !mounted || _controller != ctrl) {
              ctrl.dispose();
              return;
            }
            if (!ctrl.value.isInitialized) return;
            setState(() {
              _isInitialized = true;
              _duration = ctrl.value.duration;
            });
            ctrl.addListener(_videoListener);
            ctrl.play();
            _isPlaying = true;
          })
          .catchError((error) {
            if (_disposed || !mounted) return;
            ctrl.dispose();
            if (_controller == ctrl) _controller = null;
            if (mounted) {
              setState(() => _isInitialized = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error al cargar el video. Verifica que la URL sea válida.',
                    style: TextStyle(color: VcomColors.blancoCrema),
                  ),
                  backgroundColor: VcomColors.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: TextStyle(color: VcomColors.blancoCrema),
            ),
            backgroundColor: VcomColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _videoListener() {
    if (_disposed || !mounted || _controller == null) return;
    try {
      final c = _controller!;
      if (!c.value.isInitialized) return;
      final pos = c.value.position;
      final playing = c.value.isPlaying;
      if (mounted && !_disposed) {
        setState(() {
          _position = pos;
          _isPlaying = playing;
        });
      }
    } catch (_) {}
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _safePausePlay(bool pause) {
    if (_disposed || _controller == null) return;
    final c = _controller!;
    if (!c.value.isInitialized) return;
    try {
      if (pause) {
        c.pause();
      } else {
        c.play();
      }
      if (mounted && !_disposed) {
        setState(() => _isPlaying = !pause);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    final c = _controller;
    _controller = null;
    if (c != null) {
      c.removeListener(_videoListener);
      try {
        if (c.value.isInitialized && c.value.isPlaying) {
          c.pause();
        }
      } catch (_) {}
      Future.microtask(() {
        try {
          c.dispose();
        } catch (_) {}
      });
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _enterFullscreen() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideoOverlay(
          controller: _controller!,
          video: widget.video,
          onPop: () {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          },
        ),
      ),
    ).then((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.8),
          radius: 1.2,
          colors: [
            Color(0xFF273C67),
            Color(0xFF1a2847),
            Color(0xFF0d1525),
            Color(0xFF000000),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 96, bottom: 96),
                      child: _buildVideoPlayer(),
                    ),
                    _buildVideoInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized || _controller == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: VcomColors.oroLujoso),
            const SizedBox(height: 16),
            Text(
              'Cargando video...',
              style: TextStyle(color: VcomColors.blancoCrema, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final c = _controller!;
    final aspectRatio = c.value.aspectRatio;
    final safeAspectRatio = aspectRatio > 0 && aspectRatio.isFinite
        ? aspectRatio
        : 16 / 9;

    final videoWidget = AspectRatio(
      aspectRatio: safeAspectRatio,
      child: VideoPlayer(c),
    );

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          videoWidget,

          // Botones arriba derecha: pantalla completa + más opciones
          if (_showControls)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _enterFullscreen,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

          // Controles inferiores (estilo imagen: play + timestamp + barra)
          if (_showControls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Botón play/pausa (negro redondeado, icono blanco)
                    Material(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          _safePausePlay(_isPlaying);
                          _hideControlsAfterDelay();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Timestamp (burbuja blanca)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDuration(_position),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Barra de progreso
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFB0B0B0),
                          inactiveTrackColor: const Color(0xFF505050),
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _duration.inSeconds > 0
                              ? _position.inSeconds
                                    .clamp(0, _duration.inSeconds)
                                    .toDouble()
                              : 0,
                          min: 0,
                          max: _duration.inSeconds > 0
                              ? _duration.inSeconds.toDouble()
                              : 1,
                          onChanged: (value) {
                            if (_disposed || _controller == null) return;
                            final c = _controller!;
                            if (!c.value.isInitialized) return;
                            try {
                              c.seekTo(Duration(seconds: value.toInt()));
                            } catch (_) {}
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tiempo total
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    final category = widget.video.categoryVideo?.nameCategoryVideo ?? '';
    final author = widget.video.subtitleVideo;
    final description = widget.video.description ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categoría (arriba, dorado, mayúsculas)
          if (category.isNotEmpty)
            Text(
              category.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFC107),
                letterSpacing: 1.2,
              ),
            ),
          if (category.isNotEmpty) const SizedBox(height: 12),

          // Título (grande, bold, blanco)
          Text(
            widget.video.titleVideo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),

          // Autor (si hay subtitle)
          if (author != null && author.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Por $author',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],

          // Descripción (gris claro, párrafos)
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Overlay de pantalla completa para el video (landscape)
class _FullscreenVideoOverlay extends StatefulWidget {
  final VideoPlayerController controller;
  final VideoModel video;
  final VoidCallback onPop;

  const _FullscreenVideoOverlay({
    required this.controller,
    required this.video,
    required this.onPop,
  });

  @override
  State<_FullscreenVideoOverlay> createState() =>
      _FullscreenVideoOverlayState();
}

class _FullscreenVideoOverlayState extends State<_FullscreenVideoOverlay> {
  Timer? _hideControlsTimer;
  bool _showControls = true;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  VideoPlayerController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _syncFromController();
    _controller.addListener(_handleControllerUpdate);
    _restartHideTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  void _handleControllerUpdate() {
    if (!mounted) return;
    _syncFromController();
  }

  void _syncFromController() {
    final value = _controller.value;
    if (!value.isInitialized) return;

    final isPlaying = value.isPlaying;
    final duration = value.duration;
    final position = value.position;

    if (mounted) {
      setState(() {
        _isPlaying = isPlaying;
        _duration = duration;
        _position = position;
      });
    }

    if (!_isPlaying) {
      _hideControlsTimer?.cancel();
      if (!_showControls && mounted) {
        setState(() => _showControls = true);
      }
    }
  }

  void _restartHideTimer() {
    _hideControlsTimer?.cancel();
    if (!_isPlaying || !_showControls) return;
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_isPlaying) return;
      setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _restartHideTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _togglePlayback() {
    if (!_controller.value.isInitialized) return;
    if (_isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() => _showControls = true);
    _restartHideTimer();
  }

  void _seekRelative(int seconds) {
    if (!_controller.value.isInitialized) return;
    final target = _position + Duration(seconds: seconds);
    final safeTarget = Duration(
      milliseconds: target.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    _controller.seekTo(safeTarget);
    setState(() => _showControls = true);
    _restartHideTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 54,
    double iconSize = 28,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) widget.onPop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: _toggleControls,
              child: Center(
                child: _controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio:
                            _controller.value.aspectRatio > 0 &&
                                _controller.value.aspectRatio.isFinite
                            ? _controller.value.aspectRatio
                            : 16 / 9,
                        child: VideoPlayer(_controller),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            if (_showControls) ...[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.0, 0.22, 0.62, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.fullscreen_exit,
                            color: VcomColors.oroLujoso,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildControlButton(
                      icon: Icons.replay_10,
                      onTap: () => _seekRelative(-10),
                    ),
                    const SizedBox(width: 20),
                    _buildControlButton(
                      icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                      onTap: _togglePlayback,
                      size: 72,
                      iconSize: 38,
                    ),
                    const SizedBox(width: 20),
                    _buildControlButton(
                      icon: Icons.forward_10,
                      onTap: () => _seekRelative(10),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: VcomColors.oroLujoso,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _duration.inMilliseconds > 0
                                ? _position.inMilliseconds
                                      .clamp(0, _duration.inMilliseconds)
                                      .toDouble()
                                : 0,
                            min: 0,
                            max: _duration.inMilliseconds > 0
                                ? _duration.inMilliseconds.toDouble()
                                : 1,
                            onChanged: (value) {
                              if (!_controller.value.isInitialized) return;
                              final target = Duration(
                                milliseconds: value.round(),
                              );
                              _controller.seekTo(target);
                              setState(() {
                                _position = target;
                                _showControls = true;
                              });
                              _restartHideTimer();
                            },
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDuration(_duration),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
