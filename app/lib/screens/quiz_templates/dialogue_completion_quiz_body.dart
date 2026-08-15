import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/mcq_pill_answer_button.dart';

/// Image + first speaker line + four full-sentence replies. Visually mirrors
/// `VideoConversationQuizBody`'s `DialogueCompletion` answer_type: an image capped at 45% of
/// the available height, a white answer panel pulled up over its bottom edge, [data.line1] as
/// the bold prompt, then the same [McqPillAnswerButton] pills — the only structural difference
/// is a static [imagePath] here instead of a shared video controller.
class DialogueCompletionQuizBody extends StatefulWidget {
  const DialogueCompletionQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    this.imagePath,
    this.audio1Path,
    this.audio2Path,
    required this.resolveAudioExists,
    required this.onPlayQuestionAudio,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
    this.onOptionButtonsRendered,
  });

  final DialogueCompletionQuestionData data;
  final String userLanguage;

  /// Resolved asset path for [DialogueCompletionQuestionData.imageName], or null if the question
  /// has no image (the image block is skipped entirely, not shown as a broken placeholder).
  final String? imagePath;
  final String? audio1Path;
  final String? audio2Path;
  final Future<bool> Function(String path) resolveAudioExists;
  final Future<void> Function(String path) onPlayQuestionAudio;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  /// Optional, purely additive: fires once, the first time the four reply buttons render, with
  /// the correct option's index and a [GlobalKey] per button — lets a caller (the tutorial
  /// overlay) measure exactly where the correct button is on screen. Does not affect scoring,
  /// locking, or any other existing behavior.
  final void Function(int correctIndex, List<GlobalKey> buttonKeys)?
      onOptionButtonsRendered;

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
  List<GlobalKey> _optionButtonKeys = const [];
  bool _reportedOptionButtons = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _options = [d.answer, ...d.distractors]..shuffle(Random());
    _correctIndex = _options.indexOf(d.answer);
    _optionButtonKeys = List.generate(_options.length, (_) => GlobalKey());
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
    if (!_reportedOptionButtons &&
        widget.onOptionButtonsRendered != null &&
        _correctIndex != null) {
      _reportedOptionButtons = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onOptionButtonsRendered!(_correctIndex!, _optionButtonKeys);
      });
    }

    final answerWidth = min(MediaQuery.sizeOf(context).width * 0.87, 560.0);
    final hasImage = widget.imagePath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage)
          LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight * 0.45
                  : constraints.maxWidth;
              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight,
                      maxWidth: constraints.maxWidth,
                    ),
                    child: Image.asset(
                      widget.imagePath!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        padding: const EdgeInsets.all(24),
                        child: const Icon(Icons.image_not_supported, size: 48),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        // Pulled up over the bottom edge of the image (negative translate, not a layout gap),
        // matching VideoConversationQuizBody's overlap — see that file for why Transform is used
        // instead of a negative margin.
        Transform.translate(
          offset: Offset(0, hasImage ? -18 : 0),
          child: Center(
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: hasImage
                      ? const BorderRadius.vertical(top: Radius.circular(24))
                      : null,
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Center(
                  child: SizedBox(
                    width: answerWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.data.line1,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF171A1F),
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                        ),
                        if (widget.audio1Path != null && _bothAudiosOk == true)
                          Align(
                            alignment: Alignment.centerRight,
                            child: AudioPlayButton(
                              isPlaying: _audio1Playing || _audio2Playing,
                              onPressed: !(_locked && !_answeredWrong)
                                  ? _playAudioManual
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Fills the available height and spaces buttons evenly (mirrors
        // VideoConversationQuizBody) instead of top-aligning them, which left a large empty gap
        // above the Next button. SingleChildScrollView stays as the last-resort fallback for
        // whatever still doesn't fit (long translations, large accessibility text scale).
        Expanded(
          child: Container(
            color: Colors.white,
            // LayoutBuilder must wrap SingleChildScrollView, not sit inside it — see
            // VideoConversationQuizBody for why (a LayoutBuilder inside a scroll view reads an
            // unbounded/infinite maxHeight, which fed into ConstrainedBox(minHeight: ...) would
            // force infinite height instead of "fill the real available space").
            child: LayoutBuilder(
              builder: (context, answerConstraints) {
                return SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: answerWidth,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: answerConstraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_options.length, (i) {
                              final opt = _options[i];
                              final isSel = _selectedIndex == i;
                              final isCor = _locked && i == _correctIndex;
                              final isWrongPick = _locked && isSel && !isCor;
                              final state = isCor
                                  ? (_translationPenalized
                                      ? McqAnswerState.revealed
                                      : McqAnswerState.correct)
                                  : isWrongPick
                                      ? McqAnswerState.wrong
                                      : McqAnswerState.neutral;
                              return Padding(
                                key: _optionButtonKeys.length > i
                                    ? _optionButtonKeys[i]
                                    : null,
                                padding: EdgeInsets.only(
                                  bottom: i == _options.length - 1 ? 0 : 12,
                                ),
                                child: McqPillAnswerButton(
                                  label: opt,
                                  state: state,
                                  onTap: (_locked ||
                                          _audio1Playing ||
                                          _audio2Playing)
                                      ? null
                                      : () => _onTap(i),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
