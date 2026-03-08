import 'package:flutter/material.dart';

import '../../../models/story_config.dart';

class StoryTemplateB extends StatelessWidget {
  const StoryTemplateB({
    super.key,
    required this.page,
    required this.languageCode,
  });

  final StoryPageConfig page;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final text = _localizedText(page, languageCode);
    final sceneImage = page.pageImageListForTemplate.isNotEmpty
        ? page.pageImageListForTemplate[0]
        : null;
    final animImage = page.pageAnimationListForTemplate.isNotEmpty
        ? page.pageAnimationListForTemplate[0]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sceneImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              sceneImage,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.image, size: 64),
              ),
            ),
          ),
        if (animImage != null) ...[
          const SizedBox(height: 12),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 28),
                  const SizedBox(width: 8),
                  Text(animImage,
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  static String _localizedText(StoryPageConfig page, String languageCode) {
    if (page.pageTextListForTemplate.isEmpty) return '';
    final textMap = page.pageTextListForTemplate.first;
    return textMap[languageCode] ?? textMap['en'] ?? '';
  }
}
