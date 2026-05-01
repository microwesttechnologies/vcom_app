import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Provee un [AnimationController] repetido para shimmer del Hub (feed + tiles).
class HubShimmerScope extends StatefulWidget {
  const HubShimmerScope({super.key, required this.child});

  final Widget child;

  static Animation<double>? maybeAnimationOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_HubShimmerInherited>()
        ?.animation;
  }

  @override
  State<HubShimmerScope> createState() => _HubShimmerScopeState();
}

class _HubShimmerScopeState extends State<HubShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HubShimmerInherited(
      animation: _controller,
      child: widget.child,
    );
  }
}

class _HubShimmerInherited extends InheritedWidget {
  const _HubShimmerInherited({
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_HubShimmerInherited oldWidget) => false;
}

/// Aplica brillo diagonal; [content] debe ser opaco (p. ej. blanco).
class HubShimmer extends StatelessWidget {
  const HubShimmer({super.key, required this.content});

  final Widget content;

  static const Color _base = Color(0xFF152036);
  static const Color _highlight = Color(0xFF2E4168);

  @override
  Widget build(BuildContext context) {
    final animation = HubShimmerScope.maybeAnimationOf(context);
    if (animation == null) return content;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, maskChild) {
        final t = animation.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.2 + t * 2.4, 0),
              end: Alignment(0.2 + t * 2.4, 0),
              colors: const [_base, _highlight, _base],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: maskChild,
        );
      },
      child: content,
    );
  }
}

/// Placeholder mientras carga imagen o vídeo en tarjeta; continúa el shimmer del feed.
class HubMediaLoadingPlaceholder extends StatelessWidget {
  const HubMediaLoadingPlaceholder({
    super.key,
    this.showVideoPlayHint = false,
  });

  final bool showVideoPlayHint;

  @override
  Widget build(BuildContext context) {
    final hasScope = HubShimmerScope.maybeAnimationOf(context) != null;
    if (!hasScope) {
      return ColoredBox(
        color: const Color(0xFF1A2740),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: VcomColors.oroLujoso.withValues(alpha: 0.75),
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const HubShimmer(
          content: ColoredBox(color: Colors.white),
        ),
        if (showVideoPlayHint)
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
}
