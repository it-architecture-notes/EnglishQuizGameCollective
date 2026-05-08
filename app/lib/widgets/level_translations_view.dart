import 'package:flutter/material.dart';

import '../models/level_translations.dart';

/// Scrollable English | locale table + primary action — shared by quiz interstitial and levels-map dialog.
class LevelTranslationsView extends StatelessWidget {
  const LevelTranslationsView({
    super.key,
    required this.entries,
    required this.userLanguage,
    required this.title,
    required this.primaryLabel,
    required this.onPrimary,
    required this.listViewportHeight,
  });

  final List<TranslationEntry> entries;
  final String userLanguage;
  final String title;
  final String primaryLabel;
  final VoidCallback onPrimary;
  /// Bounded height for the scrollable list (parent handles full layout).
  final double listViewportHeight;

  String _localText(TranslationEntry e) =>
      e.translations[userLanguage] ?? e.englishWord;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: listViewportHeight,
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outlineVariant),
            itemBuilder: (context, i) {
              final e = entries[i];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        e.englishWord,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Text(
                        _localText(e),
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onPrimary,
          child: Text(primaryLabel),
        ),
      ],
    );
  }
}
