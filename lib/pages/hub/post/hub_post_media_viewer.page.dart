import 'package:flutter/material.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/hub/hub_post_media.dart';
import 'package:vcom_app/style/vcom_colors.dart';
import 'package:video_player/video_player.dart';

/// Pantalla completa: deslizar horizontal entre fotos y vídeos (reproductor con barra de progreso).
class HubPostMediaViewerPage extends StatefulWidget {
  const HubPostMediaViewerPage({
    required this.items,
    required this.initialIndex,
    super.key,
  });

  final List<HubPostMediaItem> items;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required List<HubPostMediaItem> items,
    required int initialIndex,
  }) {
    if (items.isEmpty) return Future.value();
    final i = initialIndex.clamp(0, items.length - 1);
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => HubPostMediaViewerPage(items: items, initialIndex: i),
      ),
    );
  }

  @override
  State<HubPostMediaViewerPage> createState() => _HubPostMediaViewerPageState();
}

class _HubPostMediaViewerPageState extends State<HubPostMediaViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              if (item.kind == HubMediaKind.video) {
                return _FullscreenVideoPage(url: item.url);
              }
              return _FullscreenImagePage(url: item.url);
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenImagePage extends StatelessWidget {
  const _FullscreenImagePage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final headers = hubImageRequestHeadersForUrl(url, TokenService());
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      clipBehavior: Clip.none,
      child: Center(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          headers: headers,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  color: VcomColors.oroLujoso,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image_outlined,
            color: Colors.white38,
            size: 64,
          ),
        ),
      ),
    );
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  const _FullscreenVideoPage({required this.url});

  final String url;

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: hubVideoRequestHeadersForUrl(widget.url, TokenService()),
    );
    _controller.addListener(_onTick);
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      await _controller.initialize();
      if (mounted) setState(() => _initialized = true);
    } catch (e, _) {
      debugPrint('[Hub viewer] video init error: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void deactivate() {
    if (_initialized && _controller.value.isPlaying) {
      _controller.pause();
    }
    super.deactivate();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final h = d.inHours.toString();
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.white38, size: 56),
      );
    }

    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }

    final playing = _controller.value.isPlaying;
    final aspect = _controller.value.aspectRatio == 0
        ? (16 / 9)
        : _controller.value.aspectRatio;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _togglePlay,
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: aspect,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      AnimatedOpacity(
                        opacity: playing ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _YoutubeStyleChrome(
          controller: _controller,
          playing: playing,
          onPlayPause: _togglePlay,
          formatDuration: _fmt,
        ),
      ],
    );
  }
}

/// Barra inferior tipo reproductor web: play/pausa, scrubber rojo, tiempos.
class _YoutubeStyleChrome extends StatelessWidget {
  const _YoutubeStyleChrome({
    required this.controller,
    required this.playing,
    required this.onPlayPause,
    required this.formatDuration,
  });

  final VideoPlayerController controller;
  final bool playing;
  final VoidCallback onPlayPause;
  final String Function(Duration) formatDuration;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(8, 10, 8, 8 + safeBottom),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: EdgeInsets.zero,
              colors: const VideoProgressColors(
                playedColor: Color(0xFFFF0000),
                bufferedColor: Color(0x44FFFFFF),
                backgroundColor: Color(0x22FFFFFF),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: onPlayPause,
                ),
                Text(
                  formatDuration(controller.value.position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                Text(
                  ' / ${formatDuration(controller.value.duration)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
