import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/pwa_install_visuals.dart';
import 'package:vcom_app/core/pwa/pwa_install_guide_content.dart';
import 'package:vcom_app/core/pwa/pwa_install_platform.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Logo VCOM usado en cabecera y paso final de los instructivos.
const String _kVcomLogoAsset = PwaInstallAssets.logo;

Future<void> showPwaInstallGuide(
  BuildContext context, {
  required PwaInstallPlatform platform,
}) {
  final content = PwaInstallGuideContent.forPlatform(platform);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0A1528),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _PwaInstallGuideSheet(content: content),
  );
}

class _PwaInstallGuideSheet extends StatefulWidget {
  const _PwaInstallGuideSheet({required this.content});

  final PwaInstallGuideContent content;

  @override
  State<_PwaInstallGuideSheet> createState() => _PwaInstallGuideSheetState();
}

class _PwaInstallGuideSheetState extends State<_PwaInstallGuideSheet> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.content.steps;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: VcomColors.oroLujoso.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Image.asset(
                    _kVcomLogoAsset,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      _platformIcon(widget.content.platform),
                      color: VcomColors.oroLujoso,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.content.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.content.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 340,
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _StepCard(
                  stepNumber: index + 1,
                  step: steps[index],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _currentPage == index ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? VcomColors.oroLujoso
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      );
                    },
                    child: const Text('Anterior'),
                  )
                else
                  const SizedBox(width: 8),
                const Spacer(),
                Text(
                  '${_currentPage + 1} / ${steps.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    if (_currentPage < steps.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    _currentPage < steps.length - 1 ? 'Siguiente' : 'Listo',
                    style: const TextStyle(
                      color: VcomColors.oroLujoso,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _platformIcon(PwaInstallPlatform platform) {
    switch (platform) {
      case PwaInstallPlatform.iosSafari:
      case PwaInstallPlatform.iosChrome:
        return Icons.phone_iphone_rounded;
      case PwaInstallPlatform.android:
        return Icons.phone_android_rounded;
      case PwaInstallPlatform.desktop:
        return Icons.computer_rounded;
    }
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.stepNumber,
    required this.step,
  });

  final int stepNumber;
  final PwaInstallStep step;

  Widget _buildStepVisual() {
    if (step.visual != null) {
      return PwaInstallVisual(type: step.visual!);
    }
    if (step.imageAsset != null) {
      return _StepImage(
        asset: step.imageAsset!,
        isLogo: step.imageAsset == PwaInstallAssets.logo,
        fallbackIcon: step.icon,
      );
    }
    return _IconFallback(icon: step.icon);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: VcomColors.oroLujoso,
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: const Color(0xFF111C33),
                child: _buildStepVisual(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111C33),
      alignment: Alignment.center,
      child: Icon(
        icon ?? Icons.touch_app_rounded,
        size: 56,
        color: VcomColors.oroLujoso.withValues(alpha: 0.85),
      ),
    );
  }
}

class _StepImage extends StatelessWidget {
  const _StepImage({
    required this.asset,
    required this.isLogo,
    this.fallbackIcon,
  });

  final String asset;
  final bool isLogo;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (isLogo) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _IconFallback(icon: fallbackIcon),
        ),
      );
    }

    return Image.asset(
      asset,
      width: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, _, _) => _IconFallback(icon: fallbackIcon),
    );
  }
}
