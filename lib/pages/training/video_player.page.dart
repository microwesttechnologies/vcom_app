import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:vcom_app/core/models/video.model.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página de reproductor de video
class VideoPlayerPage extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerPage({
    super.key,
    required this.video,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isFullscreen = false;
  bool _showControls = true;
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
      String videoUrl = widget.video.urlSource;

      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _duration = _controller!.value.duration;
            });
            _controller!.addListener(_videoListener);
            _controller!.play();
            _isPlaying = true;
          }
        }).catchError((error) {
          print('Error inicializando video: $error');
          if (mounted) {
            setState(() {
              _isInitialized = false;
            });
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
      print('Error: $e');
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
    if (mounted && _controller != null) {
      setState(() {
        _position = _controller!.value.position;
        _isPlaying = _controller!.value.isPlaying;
      });
    }
  }


  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    // Restaurar orientación al salir
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      // Modo pantalla completa: solo el video
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildVideoPlayer(),
            // Header flotante en pantalla completa
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: VcomColors.oroLujoso),
                          onPressed: () {
                            setState(() {
                              _isFullscreen = false;
                            });
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                            ]);
                            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                          },
                        ),
                        Expanded(
                          child: Text(
                            widget.video.titleVideo,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: VcomColors.oroLujoso,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.fullscreen_exit,
                            color: VcomColors.oroLujoso,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _isFullscreen = false;
                            });
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                            ]);
                            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    // Modo normal: con header e información
    return Scaffold(
      backgroundColor: VcomColors.azulZafiroProfundo,
      body: Container(
        decoration: const BoxDecoration(
          gradient: VcomColors.gradienteNocturno,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildVideoPlayer(),
              ),
              _buildVideoInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: VcomColors.oroLujoso),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Reproductor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VcomColors.oroLujoso,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: VcomColors.oroLujoso,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isFullscreen = !_isFullscreen;
                _showControls = true; // Mostrar controles al cambiar modo
              });
              if (_isFullscreen) {
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                _hideControlsAfterDelay();
              } else {
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                ]);
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                _hideControlsAfterDelay();
              }
            },
          ),
        ],
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
              style: TextStyle(
                color: VcomColors.blancoCrema,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // En pantalla completa, el video ocupa toda la pantalla
    Widget videoWidget = _isFullscreen
        ? SizedBox.expand(
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          )
        : AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          );

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          videoWidget,
          // Botón de play/pausa central (siempre visible cuando se toca)
          if (_showControls)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                    _isPlaying = !_isPlaying;
                  });
                  _hideControlsAfterDelay();
                },
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 50,
                        color: VcomColors.oroLujoso,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Controles inferiores (barra de progreso y botones)
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Barra de progreso y tiempo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          // Tiempo actual
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              color: VcomColors.blancoCrema,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Barra de progreso
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: VcomColors.oroLujoso,
                                inactiveTrackColor: VcomColors.blancoCrema.withOpacity(0.3),
                                thumbColor: VcomColors.oroLujoso,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: _position.inSeconds.toDouble(),
                                min: 0,
                                max: _duration.inSeconds.toDouble(),
                                onChanged: (value) {
                                  _controller!.seekTo(Duration(seconds: value.toInt()));
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tiempo total
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              color: VcomColors.blancoCrema,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botones de control
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Botón retroceder 10s
                        IconButton(
                          icon: Icon(
                            Icons.replay_10,
                            color: VcomColors.blancoCrema,
                            size: 32,
                          ),
                          onPressed: () {
                            final newPosition = _position - const Duration(seconds: 10);
                            _controller!.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                            _hideControlsAfterDelay();
                          },
                          tooltip: 'Retroceder 10s',
                        ),
                        const SizedBox(width: 16),
                        // Botón play/pausa
                        Container(
                          decoration: BoxDecoration(
                            color: VcomColors.oroLujoso,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: VcomColors.azulMedianocheTexto,
                              size: 36,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_isPlaying) {
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                                _isPlaying = !_isPlaying;
                              });
                              _hideControlsAfterDelay();
                            },
                            iconSize: 40,
                            tooltip: _isPlaying ? 'Pausar' : 'Reproducir',
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Botón avanzar 10s
                        IconButton(
                          icon: Icon(
                            Icons.forward_10,
                            color: VcomColors.blancoCrema,
                            size: 32,
                          ),
                          onPressed: () {
                            final newPosition = _position + const Duration(seconds: 10);
                            _controller!.seekTo(newPosition > _duration ? _duration : newPosition);
                            _hideControlsAfterDelay();
                          },
                          tooltip: 'Avanzar 10s',
                        ),
                      ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            widget.video.titleVideo,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: VcomColors.blancoCrema,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botón de categoría
          if (widget.video.categoryVideo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: VcomColors.azulOverlayTransparente60,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: VcomColors.oroLujoso,
                  width: 1,
                ),
              ),
              child: Text(
                widget.video.categoryVideo!.nameCategoryVideo,
                style: TextStyle(
                  color: VcomColors.oroLujoso,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Descripción
          if (widget.video.description != null)
            Text(
              widget.video.description!,
              style: TextStyle(
                fontSize: 14,
                color: VcomColors.blancoCrema.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }
}
