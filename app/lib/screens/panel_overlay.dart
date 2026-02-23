import 'dart:ui';

import 'package:flutter/material.dart';

/// Shows a centered panel over the current screen with a blurred backdrop.
/// Tap outside the panel or the close button to dismiss.
/// [horizontalMarginFraction] and [verticalMarginFraction] are 0–1 (e.g. 0.1 = 10% gap each side).
void showPanelOverlay(
  BuildContext context, {
  required String title,
  required Widget body,
  double horizontalMarginFraction = 0.10,
  double verticalMarginFraction = 0.10,
  double blurSigma = 8,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, _, __) {
        final size = MediaQuery.sizeOf(context);
        final panelWidth = size.width * (1 - 2 * horizontalMarginFraction);
        final maxHeight = size.height * (1 - 2 * verticalMarginFraction);
        return _PanelContent(
          title: title,
          body: body,
          width: panelWidth,
          height: maxHeight,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final scale = Tween<double>(begin: 0.96, end: 1.0).animate(curve);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: AnimatedBuilder(
                  animation: curve,
                  builder: (_, __) {
                    return BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: curve.value * blurSigma,
                        sigmaY: curve.value * blurSigma,
                      ),
                      child: Container(
                        color: Colors.black.withOpacity(0.15 * curve.value),
                      ),
                    );
                  },
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: curve,
                child: ScaleTransition(
                  scale: scale,
                  alignment: Alignment.center,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.title,
    required this.body,
    required this.width,
    required this.height,
  });

  final String title;
  final Widget body;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: GestureDetector(
          onTap: () {},
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 8,
            child: SizedBox(
              width: width,
              height: height,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
