import 'dart:math';

import 'package:flutter/material.dart';

/// Globe control: tap once to reveal up to three `english : local` translation pairs.
/// Hidden when [userLanguage] is `en`, or when either list is empty.
class TranslationRevealButton extends StatefulWidget {
  const TranslationRevealButton({
    super.key,
    required this.englishItems,
    required this.localItems,
    required this.userLanguage,
    this.onRevealed,
  });

  final List<String> englishItems;
  final Map<String, List<String>> localItems;
  final String userLanguage;
  /// Called when the globe button is tapped. Use to apply a translation penalty.
  final VoidCallback? onRevealed;

  @override
  State<TranslationRevealButton> createState() =>
      _TranslationRevealButtonState();
}

class _TranslationRevealButtonState extends State<TranslationRevealButton> {
  bool _revealed = false;

  String? _buildText() {
    final local = widget.localItems[widget.userLanguage] ?? [];
    final lineCount = min(3, min(widget.englishItems.length, local.length));
    if (lineCount == 0) return null;
    return List.generate(lineCount, (i) => '${widget.englishItems[i]} : ${local[i]}')
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userLanguage == 'en') return const SizedBox.shrink();
    final t = _buildText();
    if (t == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: _revealed
                ? null
                : () {
                    widget.onRevealed?.call();
                    setState(() => _revealed = true);
                  },
            icon: Icon(
              Icons.language,
              color: _revealed
                  ? cs.onSurface.withValues(alpha: 0.4)
                  : cs.tertiary,
            ),
            tooltip: 'Show translation',
          ),
        ),
        if (_revealed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              t,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
