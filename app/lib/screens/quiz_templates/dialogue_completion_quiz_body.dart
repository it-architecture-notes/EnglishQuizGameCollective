import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';

/// First line of dialogue + four full-sentence replies.
class DialogueCompletionQuizBody extends StatefulWidget {
  const DialogueCompletionQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    this.line1Translation,
    this.answerTranslation,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final DialogueCompletionQuestionData data;
  final String userLanguage;
  final Map<String, String>? line1Translation;
  final Map<String, String>? answerTranslation;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<DialogueCompletionQuizBody> createState() =>
      _DialogueCompletionQuizBodyState();
}

class _DialogueCompletionQuizBodyState extends State<DialogueCompletionQuizBody> {
  late List<String> _options;
  bool _locked = false;
  int? _selectedIndex;
  int? _correctIndex;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _options = [d.answer, ...d.distractors]..shuffle(Random());
    _correctIndex = _options.indexOf(d.answer);
  }

  void _onTap(int i) {
    if (_locked) return;
    final ok = _options[i] == widget.data.answer;
    setState(() {
      _locked = true;
      _selectedIndex = i;
    });
    if (ok) {
      widget.onPlayCorrect();
      widget.onOutcome(true);
    } else {
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final line = widget.data.line1['en'] ?? '';
    final lang = widget.userLanguage;
    final m1 = widget.line1Translation;
    final ma = widget.answerTranslation;
    final t1 = lang != 'en' && m1 != null ? m1[lang] : null;
    final ta = lang != 'en' && ma != null ? ma[lang] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.data.character1,
          style: theme.textTheme.labelLarge?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            line,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        if (t1 != null && t1.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            t1,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (ta != null && ta.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            ta,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          widget.data.character2,
          style: theme.textTheme.labelLarge?.copyWith(
            color: cs.tertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_options.length, (i) {
          final opt = _options[i];
          final isSel = _selectedIndex == i;
          final isCor = _locked && i == _correctIndex;
          Color? bg;
          Color? fg;
          if (_locked) {
            if (isCor) {
              bg = Colors.green.shade600;
              fg = Colors.white;
            } else if (isSel && !isCor) {
              bg = Colors.red.shade600;
              fg = Colors.white;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _locked ? null : () => _onTap(i),
                style: ElevatedButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: fg,
                  disabledBackgroundColor: bg,
                  disabledForegroundColor: fg,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(opt, textAlign: TextAlign.center),
              ),
            ),
          );
        }),
      ],
    );
  }
}
