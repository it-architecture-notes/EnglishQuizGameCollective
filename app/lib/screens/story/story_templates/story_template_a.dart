import 'package:flutter/material.dart';

import '../../../models/story_config.dart';

/// Template A — "character_dialog_scene" layout (page_template_id: 1)
///
/// Image slots (page_image_list_for_template):
///   [0] scene image  — fills the content area (e.g. the subject of the story)
///   [1] character image — shown bottom-left, overlapping the scene
///
/// Text slots (page_text_list_for_template):
///   [0] speech bubble text (localised map)
class StoryTemplateA extends StatelessWidget {
  const StoryTemplateA({
    super.key,
    required this.page,
    required this.languageCode,
    this.scrollViewportHeight,
  });

  final StoryPageConfig page;
  final String languageCode;

  /// When set (from [StoryOverlayScreen]), vertical inset matches template C.
  final double? scrollViewportHeight;

  static const double _verticalInset = 20.0;

  @override
  Widget build(BuildContext context) {
    final sceneImage = page.pageImageListForTemplate.isNotEmpty
        ? page.pageImageListForTemplate[0]
        : null;
    final characterImage = page.pageImageListForTemplate.length > 1
        ? page.pageImageListForTemplate[1]
        : null;
    final text = _localizedText(page, languageCode);
    final fallbackHeight = MediaQuery.of(context).size.height * 0.65;
    final contentHeight = scrollViewportHeight != null
        ? (scrollViewportHeight! - 2 * _verticalInset).clamp(120.0, double.infinity)
        : fallbackHeight;
    final characterSize = contentHeight * 0.25;

    return Padding(
      padding: scrollViewportHeight != null
          ? const EdgeInsets.symmetric(vertical: _verticalInset)
          : EdgeInsets.zero,
      child: SizedBox(
        height: contentHeight,
        child: Stack(
        children: [
          // ── Scene image fills the entire area ──────────────────────────
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: sceneImage != null
                  ? Image.asset(
                      sceneImage,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _scenePlaceholder(context),
                    )
                  : _scenePlaceholder(context),
            ),
          ),

          // ── Character — bottom left ─────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: characterImage != null
                  ? Image.asset(
                      characterImage,
                      width: characterSize,
                      height: characterSize,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          _characterPlaceholder(context, characterSize),
                    )
                  : _characterPlaceholder(context, characterSize),
            ),
          ),

          // ── Speech bubble — above and to the right of character ─────────
          Positioned(
            bottom: characterSize * 0.55,
            left: characterSize * 0.4,
            right: 12,
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
                // Tail pointing down-left toward character
                Positioned(
                  left: 0,
                  bottom: -10,
                  child: CustomPaint(
                    size: const Size(14, 10),
                    painter: _BubbleTailPainter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _scenePlaceholder(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Icon(Icons.image, size: 64)),
      );

  Widget _characterPlaceholder(BuildContext context, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.person, size: size * 0.33),
      );

  static String _localizedText(StoryPageConfig page, String languageCode) {
    if (page.pageTextListForTemplate.isEmpty) return '';
    final textMap = page.pageTextListForTemplate.first;
    return textMap[languageCode] ?? textMap['en'] ?? '';
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    // Triangle pointing down-left toward the character below
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) => false;
}
