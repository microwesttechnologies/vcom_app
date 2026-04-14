import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

Future<void> openFullscreenImageViewer({
  required BuildContext context,
  required List<String> imageUrls,
  int initialIndex = 0,
}) async {
  if (imageUrls.isEmpty) return;

  final safeInitialIndex = initialIndex.clamp(0, imageUrls.length - 1);

  await Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      pageBuilder: (routeContext, animation, secondaryAnimation) =>
          FullscreenImageViewer(
            imageUrls: imageUrls,
            initialIndex: safeInitialIndex,
          ),
      transitionsBuilder: (routeContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    ),
  );
}

class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length;

    return Scaffold(
      backgroundColor: VcomColors.negroAzul.withValues(alpha: 0.96),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (_, index) {
                return _ZoomableNetworkImage(
                  imageUrl: widget.imageUrls[index],
                  semanticLabel: 'Imagen ${index + 1} de $total',
                );
              },
            ),
            Positioned(
              top: 10,
              left: 12,
              child: _ViewerIconButton(
                icon: Icons.close,
                tooltip: 'Cerrar imagen',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            if (total > 1)
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: VcomColors.oroLujoso.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / $total',
                    style: const TextStyle(
                      color: VcomColors.blancoCrema,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewerIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ViewerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: VcomColors.oroLujoso.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(icon, color: VcomColors.blancoCrema, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ZoomableNetworkImage extends StatefulWidget {
  final String imageUrl;
  final String semanticLabel;

  const _ZoomableNetworkImage({
    required this.imageUrl,
    required this.semanticLabel,
  });

  @override
  State<_ZoomableNetworkImage> createState() => _ZoomableNetworkImageState();
}

class _ZoomableNetworkImageState extends State<_ZoomableNetworkImage> {
  final TransformationController _transformController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    const zoomScale = 2.5;
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    if (currentScale > 1.0) {
      _transformController.value = Matrix4.identity();
      return;
    }

    final localPosition = _doubleTapDetails?.localPosition;
    if (localPosition == null) {
      final matrix = Matrix4.identity();
      matrix.scaleByDouble(zoomScale, zoomScale, 1, 1);
      _transformController.value = matrix;
      return;
    }

    final x = -localPosition.dx * (zoomScale - 1);
    final y = -localPosition.dy * (zoomScale - 1);
    final matrix = Matrix4.identity();
    matrix.translateByDouble(x, y, 0, 1);
    matrix.scaleByDouble(zoomScale, zoomScale, 1, 1);
    _transformController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 1,
        maxScale: 5,
        panEnabled: true,
        clipBehavior: Clip.none,
        child: Center(
          child: Semantics(
            image: true,
            label: widget.semanticLabel,
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: VcomColors.oroLujoso),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const _ImageErrorPlaceholder(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VcomColors.error.withValues(alpha: 0.4)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: VcomColors.blancoCrema,
              size: 30,
            ),
            SizedBox(height: 8),
            Text(
              'No fue posible cargar la imagen',
              style: TextStyle(color: VcomColors.blancoCrema, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
