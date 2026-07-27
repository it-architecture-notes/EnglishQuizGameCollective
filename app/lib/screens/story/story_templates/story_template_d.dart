import 'package:flutter/material.dart';

import '../../../models/story_config.dart';

/// Template D — "multi_image_gallery" (`page_template_id` 5)
///
/// Shows [StoryPageConfig.sceneImages] one at a time with a matching caption
/// from [StoryPageConfig.storyTexts]: `en` as primary line, and when
/// [languageCode] is not `en`, that locale's string as an italic secondary
/// line below it (same pattern as [StoryTemplateC]). Previous / Next
/// navigate; on the last slide, OK dismisses the overlay (and starts the
/// level for before_level).
class StoryTemplateD extends StatefulWidget {
  const StoryTemplateD({
    super.key,
    required this.page,
    required this.languageCode,
    required this.previousLabel,
    required this.nextLabel,
    required this.okLabel,
    this.scrollViewportHeight,
  });

  final StoryPageConfig page;
  final String languageCode;
  final String previousLabel;
  final String nextLabel;
  final String okLabel;
  final double? scrollViewportHeight;

  @override
  State<StoryTemplateD> createState() => _StoryTemplateDState();
}

class _StoryTemplateDState extends State<StoryTemplateD> {
  int _index = 0;

  List<String> get _images {
    if (widget.page.sceneImages.isNotEmpty) return widget.page.sceneImages;
    final single = widget.page.sceneImage;
    return single != null ? [single] : const <String>[];
  }

  bool get _isLast => _index >= _images.length - 1;
  bool get _isFirst => _index <= 0;

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final theme = Theme.of(context);
    final englishStyle = theme.textTheme.titleMedium?.copyWith(height: 1.4);
    final localStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      height: 1.35,
      fontStyle: FontStyle.italic,
    );

    if (images.isEmpty) {
      final englishText = widget.page.storyText['en'] ?? '';
      final localText = widget.languageCode != 'en'
          ? (widget.page.storyText[widget.languageCode] ?? '')
          : '';
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(englishText, textAlign: TextAlign.center, style: englishStyle),
            if (localText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(localText, textAlign: TextAlign.center, style: localStyle),
            ],
          ],
        ),
      );
    }

    final englishCaption = widget.page.englishStoryTextAt(_index);
    final localCaption = widget.languageCode != 'en'
        ? widget.page.localizedStoryTextAt(_index, widget.languageCode)
        : '';
    final showLocalCaption =
        localCaption.isNotEmpty && localCaption != englishCaption;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportH = widget.scrollViewportHeight != null
            ? (widget.scrollViewportHeight! - 8).clamp(160.0, double.infinity)
            : MediaQuery.sizeOf(context).height * 0.65;

        return SizedBox(
          height: viewportH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    images[_index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.image, size: 64)),
                    ),
                  ),
                ),
              ),
              if (englishCaption.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    englishCaption,
                    textAlign: TextAlign.center,
                    style: englishStyle,
                  ),
                ),
              ],
              if (showLocalCaption) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    localCaption,
                    textAlign: TextAlign.center,
                    style: localStyle,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${_index + 1} / ${images.length}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isFirst
                          ? null
                          : () => setState(() => _index--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(widget.previousLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (_isLast) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() => _index++);
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_isLast ? widget.okLabel : widget.nextLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
