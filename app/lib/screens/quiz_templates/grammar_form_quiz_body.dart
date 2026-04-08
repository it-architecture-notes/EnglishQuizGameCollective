import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';

/// Cloze + lemma hint + four word buttons.
class GrammarFormQuizBody extends StatefulWidget {
  const GrammarFormQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    this.translation,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final GrammarFormQuestionData data;
  final String userLanguage;
  final Map<String, String>? translation;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<GrammarFormQuizBody> createState() => _GrammarFormQuizBodyState();
}

class _GrammarFormQuizBodyState extends State<GrammarFormQuizBody> {
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
    final line = widget.data.sentence['en'] ?? '';
    final tr = widget.translation;
    final aux = widget.userLanguage != 'en' && tr != null
        ? tr[widget.userLanguage]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            line,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '(${widget.data.hintWord})',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (aux != null && aux.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            aux,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 16),
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
            } else if (isSel) {
              bg = Colors.red.shade600;
              fg = Colors.white;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              height: 48,
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
