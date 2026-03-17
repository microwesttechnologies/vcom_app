import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:vcom_app/pages/auth/login.page.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';
import 'package:vcom_app/core/common/token.service.dart';

class AppIntroPage extends StatefulWidget {
  const AppIntroPage({super.key});

  @override
  State<AppIntroPage> createState() => _AppIntroPageState();
}

class _AppIntroPageState extends State<AppIntroPage>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _navigated = false;
  bool _ready = false;
  bool _hasError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const String _videoAsset = 'assets/video/ANIMACION_5_VCOM.mp4';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Verificar que el asset existe antes de cargar
      await rootBundle.load(_videoAsset);

      final controller = VideoPlayerController.asset(_videoAsset);
      _controller = controller;

      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Tiempo de espera agotado'),
      );

      if (!mounted) return;

      await controller.setLooping(false);
      controller.addListener(_onVideoStateChanged);

      if (mounted) {
        setState(() {
          _ready = true;
          _hasError = false;
        });
        // Reproducir después de que el widget esté en pantalla
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await controller.seekTo(Duration.zero);
          await controller.play();
        });
      }
    } catch (e) {
      debugPrint('Error cargando video de inicio: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _ready = false;
        });
        // Fallback: mostrar logo 2 segundos y navegar
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _goNext();
        });
      }
    }
  }

  void _onVideoStateChanged() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final value = ctrl.value;
    if (value.position >= value.duration && !value.isPlaying) {
      _goNext();
    }
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final tokenService = TokenService();
    final nextPage = tokenService.hasToken()
        ? const DashboardPage()
        : const LoginPage();

    // Fade out el video, luego transición a la app
    _fadeController.forward().then((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextPage,
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0)
                    .animate(curvedAnimation),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _ready && _controller != null
              ? ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio > 0
                          ? _controller!.value.aspectRatio
                          : 9 / 16,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                )
              : _hasError
                  ? _buildFallback()
                  : ColoredBox(
                      color: Colors.black,
                      child: const SizedBox.expand(),
                    ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Image.asset(
        'assets/image/VCOM_G_PNG.png',
        fit: BoxFit.contain,
        width: 200,
      ),
    );
  }
}
