import 'package:flutter/material.dart';
import 'package:vcom_app/pages/hub/hub_shimmer.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Placeholder animado alineado con [PostCardWidget]: franja, rejilla 4:3, cabecera, texto, acciones.
class HubFeedSkeleton extends StatelessWidget {
  const HubFeedSkeleton({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 120),
    this.cardCount = 3,
  });

  final EdgeInsets padding;
  final int cardCount;

  static const double _mediaAspect = 4 / 3;
  static const double _gridGap = 2;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        HubShimmer(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _box(h: 48, r: 12),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _box(h: 32, r: 12)),
                  const SizedBox(width: 8),
                  _box(h: 32, w: 72, r: 12),
                  const SizedBox(width: 8),
                  _box(h: 32, w: 88, r: 12),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < cardCount; i++) _skeletonPostCard(),
      ],
    );
  }

  Widget _skeletonPostCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1520),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: VcomColors.oroLujoso.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      VcomColors.oroLujoso,
                      VcomColors.oroLujoso.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: HubShimmer(
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _skeletonMediaGrid(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _skeletonHeader(),
                            const SizedBox(height: 12),
                            _box(h: 17, r: 8),
                            const SizedBox(height: 6),
                            _box(h: 13, w: double.infinity, r: 6),
                            const SizedBox(height: 6),
                            _box(h: 13, w: 200, r: 6),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _box(h: 18, w: 48, r: 6),
                                const SizedBox(width: 20),
                                _box(h: 18, w: 36, r: 6),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonMediaGrid() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topRight: Radius.circular(15)),
      child: AspectRatio(
        aspectRatio: _mediaAspect,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _cell()),
                  SizedBox(width: _gridGap),
                  Expanded(child: _cell()),
                ],
              ),
            ),
            SizedBox(height: _gridGap),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _cell()),
                  SizedBox(width: _gridGap),
                  Expanded(child: _cell()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell() => const ColoredBox(color: Colors.white);

  Widget _skeletonHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(h: 12, w: double.infinity, r: 6),
              const SizedBox(height: 4),
              _box(h: 10, w: 130, r: 5),
            ],
          ),
        ),
        _box(h: 26, w: 78, r: 20),
      ],
    );
  }

  Widget _box({
    required double h,
    double? w,
    double r = 8,
  }) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}
