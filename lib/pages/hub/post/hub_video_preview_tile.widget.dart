import 'package:flutter/material.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/hub/hub_post_media.dart';
import 'package:vcom_app/style/vcom_colors.dart';
import 'package:video_player/video_player.dart';

/// Vista previa del vídeo en la tarjeta (primer fotograma), con las mismas
/// cabeceras HTTP que el reproductor a pantalla completa.
class HubVideoPreviewTile extends StatefulWidget {
  const HubVideoPreviewTile({super.key, required this.url});

  final String url;

  @override
  State<HubVideoPreviewTile> createState() => _HubVideoPreviewTileState();
}

class _HubVideoPreviewTileState extends State<HubVideoPreviewTile> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: hubVideoRequestHeadersForUrl(widget.url, TokenService()),
    );
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.setLooping(false);
      await c.setVolume(0);
      // Un fotograma visible (a veces el frame 0 sale negro según el códec).
      try {
        await c.seekTo(const Duration(milliseconds: 200));
      } catch (_) {
        try {
          await c.seekTo(Duration.zero);
        } catch (_) {}
      }
      await c.pause();
      setState(() => _controller = c);
    } catch (e, st) {
      debugPrint('[HubVideoPreviewTile] init failed: $e\n$st');
      await c.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _fallback();
    final c = _controller;
    if (c == null || !c.value.isInitialized) return _loading();

    final size = c.value.size;
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return _fallback();

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: w,
            height: h,
            child: VideoPlayer(c),
          ),
        ),
        Center(
          child: Icon(
            Icons.play_circle_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.9),
            shadows: const [
              Shadow(blurRadius: 12, color: Colors.black54),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loading() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF1A2740)),
        Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: VcomColors.oroLujoso.withValues(alpha: 0.75),
            ),
          ),
        ),
        Center(
          child: Icon(
            Icons.play_circle_rounded,
            size: 44,
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF1A2740)),
        Center(
          child: Icon(
            Icons.play_circle_rounded,
            size: 52,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
      ],
    );
  }
}
