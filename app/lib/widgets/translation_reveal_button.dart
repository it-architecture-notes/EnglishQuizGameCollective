import 'package:flutter/material.dart';

/// Globe control: tap once to reveal [translationText]. Hidden for English or empty text.
class TranslationRevealButton extends StatefulWidget {
  const TranslationRevealButton({
    super.key,
    required this.translationText,
    required this.userLanguage,
  });

  final String? translationText;
  final String userLanguage;

  @override
  State<TranslationRevealButton> createState() =>
      _TranslationRevealButtonState();
}

class _TranslationRevealButtonState extends State<TranslationRevealButton> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.translationText?.trim();
    if (t == null ||
        t.isEmpty ||
        widget.userLanguage == 'en') {
      return const SizedBox.shrink();
    }
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
                : () => setState(() => _revealed = true),
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
