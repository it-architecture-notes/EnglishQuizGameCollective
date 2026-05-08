import 'package:flutter/material.dart';

import '../../../models/story_config.dart';

/// Template A — "character_dialog_scene" (`page_template_id` 1)
///
/// Layout (top → bottom):
///   1. Scene image — BoxFit.contain so the dominant dimension fills first.
///   2. Row: character sprite (left) + speech bubble (right).
class StoryTemplateA extends StatelessWidget {
  const StoryTemplateA({
    super.key,
    required this.page,
    required this.languageCode,
    this.scrollViewportHeight,
  });

  final StoryPageConfig page;
  final String languageCode;
  final double? scrollViewportHeight;

  static const double _edgeInset = 20.0;
  static const double _gap = 16.0;
  static const double _characterSize = 72.0;

  @override
  Widget build(BuildContext context) {
    final text = page.localizedStoryText(languageCode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportH = scrollViewportHeight != null
            ? (scrollViewportHeight! - 2 * _edgeInset).clamp(120.0, double.infinity)
            : MediaQuery.sizeOf(context).height * 0.65;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: _edgeInset),
          child: SizedBox(
            height: viewportH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Scene image — contain-fit so no cropping ───────────────
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: page.sceneImage != null
                        ? Image.asset(
                            page.sceneImage!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _scenePlaceholder(context),
                          )
                        : _scenePlaceholder(context),
                  ),
                ),

                const SizedBox(height: _gap),

                // ── Character + speech bubble ──────────────────────────────
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Character sprite
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: page.characterImage != null
                            ? Image.asset(
                                page.characterImage!,
                                width: _characterSize,
                                height: _characterSize,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _characterPlaceholder(context),
                              )
                            : _characterPlaceholder(context),
                      ),

                      const SizedBox(width: 10),

                      // Speech bubble
                      Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                text,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(height: 1.4),
                              ),
                            ),
                            // Tail pointing left toward character
                            Positioned(
                              left: -10,
                              bottom: 14,
                              child: CustomPaint(
                                size: const Size(10, 14),
                                painter: _BubbleTailPainter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _scenePlaceholder(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Icon(Icons.image, size: 64)),
      );

  Widget _characterPlaceholder(BuildContext context) => Container(
        width: _characterSize,
        height: _characterSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.person, size: _characterSize * 0.33),
      );
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    // Triangle pointing left: tip at (0, mid), base on right edge
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) => false;
}
