import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../widgets/translation_reveal_button.dart';

/// First line of dialogue + four full-sentence replies.
class DialogueCompletionQuizBody extends StatefulWidget {
  const DialogueCompletionQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    this.line1Translation,
    this.answerTranslation,
    this.audio1Path,
    this.audio2Path,
    this.resolvedImagePath,
    required this.resolveAudioExists,
    required this.onPlayQuestionAudio,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final DialogueCompletionQuestionData data;
  final String userLanguage;
  final Map<String, String>? line1Translation;
  final Map<String, String>? answerTranslation;
  final String? audio1Path;
  final String? audio2Path;
  /// Pre-resolved asset path for the optional hero image (from `image_file_name` in JSON).
  final String? resolvedImagePath;
  final Future<bool> Function(String path) resolveAudioExists;
  final Future<void> Function(String path) onPlayQuestionAudio;
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
  bool _audio1Playing = false;
  bool _audio2Playing = false;
  bool _audio1Scheduled = false;
  bool? _audio1Ok;
  bool? _audio2Ok;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _options = [d.answer, ...d.distractors]..shuffle(Random());
    _correctIndex = _options.indexOf(d.answer);
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeAudio());
  }

  @override
  void didUpdateWidget(covariant DialogueCompletionQuizBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audio1Path != widget.audio1Path ||
        oldWidget.audio2Path != widget.audio2Path) {
      _audio1Scheduled = false;
      _primeAudio();
    }
  }

  Future<void> _primeAudio() async {
    final p1 = widget.audio1Path;
    final p2 = widget.audio2Path;
    if (p1 != null) {
      _audio1Ok = await widget.resolveAudioExists(p1);
    } else {
      _audio1Ok = false;
    }
    if (p2 != null) {
      _audio2Ok = await widget.resolveAudioExists(p2);
    } else {
      _audio2Ok = false;
    }
    if (!mounted) return;
    setState(() {});
    if (_audio1Scheduled) return;
    _audio1Scheduled = true;
    if (_audio1Ok == true && p1 != null) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _audio1Playing = true);
      try {
        await widget.onPlayQuestionAudio(p1);
      } finally {
        if (mounted) setState(() => _audio1Playing = false);
      }
    }
  }

  Future<void> _playAudio1Manual() async {
    final p = widget.audio1Path;
    if (p == null || _audio1Ok != true) return;
    setState(() => _audio1Playing = true);
    try {
      await widget.onPlayQuestionAudio(p);
    } finally {
      if (mounted) setState(() => _audio1Playing = false);
    }
  }

  String? _combinedTranslation() {
    final lang = widget.userLanguage;
    if (lang == 'en') return null;
    final m1 = widget.line1Translation;
    final ma = widget.answerTranslation;
    final t1 = m1?[lang];
    final ta = ma?[lang];
    final parts = <String>[];
    if (t1 != null && t1.isNotEmpty) parts.add(t1);
    if (ta != null && ta.isNotEmpty) parts.add(ta);
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  Future<void> _onTap(int i) async {
    if (_locked) return;
    final ok = _options[i] == widget.data.answer;
    setState(() {
      _locked = true;
      _selectedIndex = i;
    });
    final p2 = widget.audio2Path;
    if (_audio2Ok == true && p2 != null) {
      setState(() => _audio2Playing = true);
      try {
        await widget.onPlayQuestionAudio(p2);
      } finally {
        if (mounted) setState(() => _audio2Playing = false);
      }
    }
    if (!mounted) return;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslationRevealButton(
          translationText: _combinedTranslation(),
          userLanguage: lang,
        ),
        if (widget.resolvedImagePath != null) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                widget.resolvedImagePath!,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 72, height: 72),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
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
        if (_audio1Ok == true && widget.audio1Path != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: (_audio1Playing || _audio2Playing)
                    ? null
                    : _playAudio1Manual,
                icon: Icon(
                  _audio1Playing ? Icons.graphic_eq : Icons.volume_up,
                  color: (_audio1Playing || _audio2Playing)
                      ? cs.onSurface.withValues(alpha: 0.4)
                      : cs.primary,
                ),
              ),
            ],
          ),
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
                onPressed: (_locked || _audio2Playing) ? null : () => _onTap(i),
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
