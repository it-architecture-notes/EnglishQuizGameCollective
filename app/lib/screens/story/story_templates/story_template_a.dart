import 'package:flutter/material.dart';

import '../../../models/story_config.dart';

class StoryTemplateA extends StatelessWidget {
  const StoryTemplateA({
    super.key,
    required this.page,
    required this.languageCode,
  });

  final StoryPageConfig page;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final text = _localizedText(page, languageCode);
    final characterImage = page.pageImageListForTemplate.isNotEmpty
        ? page.pageImageListForTemplate[0]
        : null;
    final sceneImage = page.pageImageListForTemplate.length > 1
        ? page.pageImageListForTemplate[1]
        : null;
    final animImage = page.pageAnimationListForTemplate.isNotEmpty
        ? page.pageAnimationListForTemplate[0]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (characterImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  characterImage,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, size: 48),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.4),
                ),
              ),
            ),
          ],
        ),
        if (sceneImage != null) ...[
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              sceneImage,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image, size: 48),
              ),
            ),
          ),
        ],
        if (animImage != null) ...[
          const SizedBox(height: 20),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 40),
                  const SizedBox(height: 8),
                  Text(animImage,
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _localizedText(StoryPageConfig page, String languageCode) {
    if (page.pageTextListForTemplate.isEmpty) return '';
    final textMap = page.pageTextListForTemplate.first;
    return textMap[languageCode] ?? textMap['en'] ?? '';
  }
}
