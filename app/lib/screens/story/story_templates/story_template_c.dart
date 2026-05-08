import 'package:flutter/material.dart';

import '../../../models/story_config.dart';

/// Template C — "scene_story_text" layout (`page_template_id` 4)
///
/// Scene area uses a placeholder. [StoryPageConfig.storyText]: `en` as primary line;
/// when [languageCode] is not `en`, that locale’s string as italic secondary.
///
/// Layout: one [kSectionGap] between placeholder and primary text, the same gap
/// between primary and secondary text when both exist.
class StoryTemplateC extends StatelessWidget {
  const StoryTemplateC({
    super.key,
    required this.page,
    required this.languageCode,
    this.scrollViewportHeight,
  });

  final StoryPageConfig page;
  final String languageCode;

  /// Height of the scroll area in [StoryOverlayScreen] (between header and
  /// Continue button). When set, centering uses this viewport.
  final double? scrollViewportHeight;

  /// Vertical space between image ↔ first text block ↔ second text block.
  static const double kSectionGap = 18.0;

  /// Outer vertical inset inside the scroll area.
  static const double kEdgeInset = 20.0;

  /// Max height for the image as a fraction of the inner viewport height.
  static const double kMaxImageHeightFraction = 0.48;

  @override
  Widget build(BuildContext context) {
    final englishText = page.storyText['en'] ?? '';
    final localText = languageCode != 'en'
        ? (page.storyText[languageCode] ?? '')
        : '';

    final imageBlock = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: page.sceneImage != null
          ? Image.asset(
              page.sceneImage!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context),
            )
          : _placeholder(context),
    );

    final englishStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          height: 1.45,
        );
    final localStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.6),
          height: 1.4,
          fontStyle: FontStyle.italic,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerH = _innerViewportHeight(context);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: kEdgeInset),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: innerH),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                        maxHeight: _maxImageHeight(innerH),
                      ),
                      child: imageBlock,
                    ),
                  ),
                  SizedBox(height: kSectionGap),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      englishText,
                      textAlign: TextAlign.center,
                      style: englishStyle,
                    ),
                  ),
                  if (localText.isNotEmpty) ...[
                    SizedBox(height: kSectionGap),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        localText,
                        textAlign: TextAlign.center,
                        style: localStyle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Inner height available for centering (after vertical edge padding).
  double _innerViewportHeight(BuildContext context) {
    if (scrollViewportHeight != null) {
      return (scrollViewportHeight! - 2 * kEdgeInset)
          .clamp(120.0, double.infinity);
    }
    final fallback = MediaQuery.sizeOf(context).height * 0.65;
    return (fallback - 2 * kEdgeInset).clamp(120.0, double.infinity);
  }

  /// Caps image height so text blocks keep room; scales with viewport.
  double _maxImageHeight(double innerViewportHeight) {
    return (innerViewportHeight * kMaxImageHeightFraction).clamp(120.0, 420.0);
  }

  Widget _placeholder(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Icon(Icons.image, size: 64)),
      );
}
