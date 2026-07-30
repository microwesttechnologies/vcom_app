import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:vcom_app/components/shared/pwa_audio_permission_dialog.dart';
import 'package:vcom_app/core/pwa/pwa_audio_permission.service.dart';
import 'package:vcom_app/core/pwa/pwa_platform.dart';
import 'package:vcom_app/pages/app_launch/post_intro_home.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';
import 'package:vcom_app/core/chat/chat_push.service.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class AppIntroPage extends StatefulWidget {
  const AppIntroPage({super.key});

  @override
  State<AppIntroPage> createState() => _AppIntroPageState();
}

class _AppIntroPageState extends State<AppIntroPage>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _navigated = false;
  bool _navigationStarted = false;
  bool _ready = false;
  bool _hasError = false;
  bool _waitingForIosTap = false;
  Timer? _safetyTimer;
  Timer? _playWatchdog;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const String _videoAsset = 'assets/video/ANIMACION_5_VCOM.mp4';

  bool get _isIosPwaWithSound =>
      kIsWeb &&
      isIosDevice &&
      isStandalonePwa &&
      PwaAudioPermissionService.instance.shouldPlayWithSound;

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
      await _prepareVideo();
      if (!mounted) return;

      final audioPermission = PwaAudioPermissionService.instance;

      if (kIsWeb && audioPermission.shouldAskPermission) {
        final granted = await showPwaAudioPermissionDialog(
          context,
          onAllow: _unlockIntroSoundFromUserGesture,
        );
        if (!mounted) return;

        final allowSound = granted ?? false;
        await audioPermission.saveChoice(granted: allowSound);

        if (allowSound) {
          await _playIntro(withSound: true);
        } else {
          await _playIntro(withSound: false);
        }
        return;
      }

      if (_isIosPwaWithSound) {
        setState(() => _waitingForIosTap = true);
        return;
      }

      final withSound = !kIsWeb || audioPermission.shouldPlayWithSound;
      await _playIntro(withSound: withSound);
    } catch (e) {
      debugPrint('Error en intro: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _ready = false;
        });
        _scheduleSafetyNavigation(const Duration(seconds: 2));
      }
    }
  }

  Future<void> _prepareVideo() async {
    await rootBundle.load(_videoAsset);

    final controller = VideoPlayerController.asset(_videoAsset);
    _controller = controller;

    await controller.initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Tiempo de espera agotado'),
    );

    if (!mounted) return;

    await controller.setLooping(false);
    await controller.setVolume(0);
    controller.addListener(_onVideoStateChanged);

    if (mounted) {
      setState(() {
        _ready = true;
        _hasError = false;
      });
    }
  }

  /// iOS exige desbloquear audio en el mismo toque del usuario (sin awaits previos).
  void _unlockIntroSoundFromUserGesture() {
    if (!kIsWeb) return;

    unlockWebAudioFromUserGesture();
    unmuteHtmlVideosFromUserGesture();

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    controller.setVolume(1.0);
    controller.seekTo(Duration.zero);
    controller.play();
  }

  Future<void> _onIosStartTap() async {
    _unlockIntroSoundFromUserGesture();
    if (!mounted) return;
    setState(() => _waitingForIosTap = false);
    await _playIntro(withSound: true);
  }

  Future<void> _playIntro({required bool withSound}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    await controller.setVolume(withSound ? 1.0 : 0.0);

    final duration = controller.value.duration;
    final safety = duration > Duration.zero
        ? duration + const Duration(seconds: 2)
        : const Duration(seconds: 10);
    _scheduleSafetyNavigation(safety);

    await controller.seekTo(Duration.zero);
    await controller.play();
    _startPlayWatchdog(controller);
  }

  void _startPlayWatchdog(VideoPlayerController controller) {
    _playWatchdog?.cancel();
    _playWatchdog = Timer(const Duration(seconds: 4), () {
      if (!mounted || _navigated) return;
      final value = controller.value;
      if (!value.isPlaying &&
          value.position < const Duration(milliseconds: 300)) {
        debugPrint('Intro: video no reprodujo, navegando con fallback.');
        _goNext();
      }
    });
  }

  void _scheduleSafetyNavigation(Duration delay) {
    _safetyTimer?.cancel();
    _safetyTimer = Timer(delay, () {
      if (mounted && !_navigated) _goNext();
    });
  }

  void _onVideoStateChanged() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final value = ctrl.value;

    final duration = value.duration;
    final nearEnd = duration > Duration.zero &&
        value.position >= duration - const Duration(milliseconds: 250);
    if (value.isCompleted || (nearEnd && !value.isPlaying)) {
      _goNext();
    }
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _safetyTimer?.cancel();
    _playWatchdog?.cancel();
    markIntroShownThisSession();

    final nextPage = buildPostIntroHome();

    _fadeController.forward().then((_) => _navigateTo(nextPage));
    Timer(const Duration(milliseconds: 900), () => _navigateTo(nextPage));
  }

  void _navigateTo(Widget nextPage) {
    if (_navigationStarted || !mounted) return;
    _navigationStarted = true;

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
    ).then((_) {
      if (nextPage is DashboardPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ChatPushService().openPendingDeepLinkIfAny();
        });
      }
    });
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _playWatchdog?.cancel();
    _fadeController.dispose();
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _waitingForIosTap ? null : _goNext,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: _ready && _controller != null
                  ? _buildVideoPlayer()
                  : _hasError
                      ? _buildFallback()
                      : const ColoredBox(
                          color: Colors.black,
                          child: SizedBox.expand(),
                        ),
            ),
            if (_waitingForIosTap) _buildIosStartOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildIosStartOverlay() {
    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  size: 48,
                  color: VcomColors.oroLujoso.withValues(alpha: 0.95),
                ),
                const SizedBox(height: 20),
                Text(
                  'Toca para comenzar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: VcomColors.blancoCrema,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'VCOM reproducirá el video de bienvenida con sonido.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: VcomColors.blancoCrema.withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _onIosStartTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: VcomColors.oroLujoso,
                    foregroundColor: VcomColors.azulMedianocheTexto,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Comenzar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final controller = _controller!;
    final size = controller.value.size;
    final videoWidth = size.width > 0 ? size.width : 9.0;
    final videoHeight = size.height > 0 ? size.height : 16.0;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: VideoPlayer(controller),
            ),
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
