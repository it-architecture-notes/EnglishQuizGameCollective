import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/translation_reveal_button.dart';

/// First line of dialogue + four full-sentence replies.
class DialogueCompletionQuizBody extends StatefulWidget {
  const DialogueCompletionQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    this.audio1Path,
    this.audio2Path,
    required this.resolveAudioExists,
    required this.onPlayQuestionAudio,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final DialogueCompletionQuestionData data;
  final String userLanguage;
  final String? audio1Path;
  final String? audio2Path;
  final Future<bool> Function(String path) resolveAudioExists;
  final Future<void> Function(String path) onPlayQuestionAudio;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<DialogueCompletionQuizBody> createState() =>
      _DialogueCompletionQuizBodyState();
}

class _DialogueCompletionQuizBodyState
    extends State<DialogueCompletionQuizBody> {
  late List<String> _options;
  bool _locked = false;
  bool _translationPenalized = false;
  int? _selectedIndex;
  int? _correctIndex;
  bool _audio1Playing = false;
  bool _audio2Playing = false;
  bool _audio1Scheduled = false;
  bool? _bothAudiosOk;
  bool _answeredWrong = false;

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
      setState(() {
        _audio1Scheduled = false;
        _locked = false;
        _selectedIndex = null;
        _answeredWrong = false;
        _bothAudiosOk = null;
        _audio1Playing = false;
        _audio2Playing = false;
      });
      _primeAudio();
    }
  }

  Future<void> _primeAudio() async {
    final p1 = widget.audio1Path;
    final p2 = widget.audio2Path;
    final ok1 = p1 != null && await widget.resolveAudioExists(p1);
    final ok2 = p2 != null && await widget.resolveAudioExists(p2);
    final bothOk = ok1 && ok2;
    if (!mounted) return;
    setState(() => _bothAudiosOk = bothOk);
    if (_audio1Scheduled) return;
    _audio1Scheduled = true;
    if (bothOk) {
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

  Future<void> _onTranslationRevealed() async {
    if (_locked || widget.data.trOk) return;
    setState(() {
      _locked = true;
      _translationPenalized = true;
      _answeredWrong = true;
    });
    widget.onPlayWrong();
    if (_bothAudiosOk == true) {
      final p2 = widget.audio2Path;
      if (p2 != null) {
        setState(() => _audio2Playing = true);
        try {
          await widget.onPlayQuestionAudio(p2);
        } finally {
          if (mounted) setState(() => _audio2Playing = false);
        }
      }
    }
    if (!mounted) return;
    widget.onOutcome(false);
  }

  Future<void> _playAudioManual() async {
    if (_bothAudiosOk != true) return;
    final p1 = widget.audio1Path;
    final p2 = widget.audio2Path;
    if (p1 == null || p2 == null) return;
    setState(() => _audio1Playing = true);
    try {
      await widget.onPlayQuestionAudio(p1);
    } finally {
      if (mounted) setState(() => _audio1Playing = false);
    }
    if (!mounted) return;
    if (!_answeredWrong) return;
    setState(() => _audio2Playing = true);
    try {
      await widget.onPlayQuestionAudio(p2);
    } finally {
      if (mounted) setState(() => _audio2Playing = false);
    }
  }

  Future<void> _onTap(int i) async {
    if (_locked) return;
    final ok = _options[i] == widget.data.answer;
    setState(() {
      _locked = true;
      _selectedIndex = i;
      _answeredWrong = !ok;
    });
    final p2 = widget.audio2Path;
    if (_bothAudiosOk == true && p2 != null) {
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
    final line = widget.data.line1;
    final lang = widget.userLanguage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslationRevealButton(
          englishItems: widget.data.englishToTranslate,
          localItems: widget.data.localTranslation,
          userLanguage: lang,
          onRevealed: _onTranslationRevealed,
          enabled: !(_audio1Playing || _audio2Playing),
        ),
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
        if (widget.audio1Path != null && _bothAudiosOk == true)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AudioPlayButton(
                isPlaying: _audio1Playing || _audio2Playing,
                onPressed: !(_locked && !_answeredWrong)
                    ? _playAudioManual
                    : null,
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
              bg = _translationPenalized
                  ? Colors.blue.shade600
                  : Colors.green.shade600;
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
                onPressed: (_locked || _audio1Playing || _audio2Playing) ? null : () => _onTap(i),
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
