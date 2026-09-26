import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../models/level_config.dart';
import '../../services/question_layout_budget.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/debug_layout_box.dart';
import '../../widgets/mcq_pill_answer_button.dart';
import '../../widgets/standard_question_media.dart';

/// Remainder height fraction dedicated to the prompt card vs reply buttons.
/// Copied verbatim from `dialogue_completion_quiz_body.dart` — this template is deliberately
/// isolated from (not shared with) the standalone `DialogueCompletion` widget, even though the
/// two are visually identical apart from the media source (frozen video vs. static image).
const Map<QuestionLayoutTier, ({double prompt, double buttons})>
    _pausedDialogueCompletionRemainderShare = {
  QuestionLayoutTier.phone16to9: (prompt: 0.36, buttons: 0.64),
  QuestionLayoutTier.phoneClassic2to1: (prompt: 0.36, buttons: 0.64),
  QuestionLayoutTier.phoneTransition: (prompt: 0.37, buttons: 0.63),
  QuestionLayoutTier.phoneFlagship: (prompt: 0.38, buttons: 0.62),
  QuestionLayoutTier.phoneSuperTall: (prompt: 0.38, buttons: 0.62),
  QuestionLayoutTier.phoneUltraTall: (prompt: 0.39, buttons: 0.61),
  QuestionLayoutTier.tablet4to3: (prompt: 0.40, buttons: 0.60),
  QuestionLayoutTier.tablet3to2: (prompt: 0.40, buttons: 0.60),
  QuestionLayoutTier.tablet16to10: (prompt: 0.40, buttons: 0.60),
  QuestionLayoutTier.tablet16to9: (prompt: 0.42, buttons: 0.58),
};

typedef _PausedDialogueCompletionGaps = ({
  double promptToButtonsGap,
  double containerHorizontalPadding,
  double buttonSpacing,
});

const Map<QuestionLayoutTier, _PausedDialogueCompletionGaps>
    _pausedDialogueCompletionGaps = {
  QuestionLayoutTier.phone16to9: (
    promptToButtonsGap: 8.0,
    containerHorizontalPadding: 12.0,
    buttonSpacing: 8.0,
  ),
  QuestionLayoutTier.phoneClassic2to1: (
    promptToButtonsGap: 8.0,
    containerHorizontalPadding: 12.0,
    buttonSpacing: 8.0,
  ),
  QuestionLayoutTier.phoneTransition: (
    promptToButtonsGap: 8.0,
    containerHorizontalPadding: 12.0,
    buttonSpacing: 8.0,
  ),
  QuestionLayoutTier.phoneFlagship: (
    promptToButtonsGap: 10.0,
    containerHorizontalPadding: 14.0,
    buttonSpacing: 10.0,
  ),
  QuestionLayoutTier.phoneSuperTall: (
    promptToButtonsGap: 10.0,
    containerHorizontalPadding: 14.0,
    buttonSpacing: 10.0,
  ),
  QuestionLayoutTier.phoneUltraTall: (
    promptToButtonsGap: 10.0,
    containerHorizontalPadding: 16.0,
    buttonSpacing: 10.0,
  ),
  QuestionLayoutTier.tablet4to3: (
    promptToButtonsGap: 14.0,
    containerHorizontalPadding: 20.0,
    buttonSpacing: 12.0,
  ),
  QuestionLayoutTier.tablet3to2: (
    promptToButtonsGap: 14.0,
    containerHorizontalPadding: 22.0,
    buttonSpacing: 12.0,
  ),
  QuestionLayoutTier.tablet16to10: (
    promptToButtonsGap: 16.0,
    containerHorizontalPadding: 24.0,
    buttonSpacing: 14.0,
  ),
  QuestionLayoutTier.tablet16to9: (
    promptToButtonsGap: 16.0,
    containerHorizontalPadding: 24.0,
    buttonSpacing: 14.0,
  ),
};

typedef _PausedDialogueCompletionPromptPreset = ({
  double cardPaddingTop,
  double cardPaddingBottom,
  double cardPaddingHorizontal,
  double audioSpeakerSize,
  double nominal1LineHeight,
  double nominal2LineHeight,
});

const Map<QuestionLayoutTier, _PausedDialogueCompletionPromptPreset>
    _pausedDialogueCompletionPromptPresets = {
  QuestionLayoutTier.phone16to9: (
    cardPaddingTop: 12.0,
    cardPaddingBottom: 10.0,
    cardPaddingHorizontal: 14.0,
    audioSpeakerSize: 44.0,
    nominal1LineHeight: 68.0,
    nominal2LineHeight: 88.0,
  ),
  QuestionLayoutTier.phoneClassic2to1: (
    cardPaddingTop: 12.0,
    cardPaddingBottom: 10.0,
    cardPaddingHorizontal: 14.0,
    audioSpeakerSize: 44.0,
    nominal1LineHeight: 68.0,
    nominal2LineHeight: 88.0,
  ),
  QuestionLayoutTier.phoneTransition: (
    cardPaddingTop: 12.0,
    cardPaddingBottom: 10.0,
    cardPaddingHorizontal: 14.0,
    audioSpeakerSize: 44.0,
    nominal1LineHeight: 70.0,
    nominal2LineHeight: 90.0,
  ),
  QuestionLayoutTier.phoneFlagship: (
    cardPaddingTop: 14.0,
    cardPaddingBottom: 12.0,
    cardPaddingHorizontal: 16.0,
    audioSpeakerSize: 48.0,
    nominal1LineHeight: 76.0,
    nominal2LineHeight: 98.0,
  ),
  QuestionLayoutTier.phoneSuperTall: (
    cardPaddingTop: 14.0,
    cardPaddingBottom: 12.0,
    cardPaddingHorizontal: 16.0,
    audioSpeakerSize: 48.0,
    nominal1LineHeight: 78.0,
    nominal2LineHeight: 100.0,
  ),
  QuestionLayoutTier.phoneUltraTall: (
    cardPaddingTop: 14.0,
    cardPaddingBottom: 12.0,
    cardPaddingHorizontal: 16.0,
    audioSpeakerSize: 48.0,
    nominal1LineHeight: 80.0,
    nominal2LineHeight: 104.0,
  ),
  QuestionLayoutTier.tablet4to3: (
    cardPaddingTop: 16.0,
    cardPaddingBottom: 14.0,
    cardPaddingHorizontal: 20.0,
    audioSpeakerSize: 48.0,
    nominal1LineHeight: 88.0,
    nominal2LineHeight: 116.0,
  ),
  QuestionLayoutTier.tablet3to2: (
    cardPaddingTop: 18.0,
    cardPaddingBottom: 16.0,
    cardPaddingHorizontal: 22.0,
    audioSpeakerSize: 52.0,
    nominal1LineHeight: 94.0,
    nominal2LineHeight: 124.0,
  ),
  QuestionLayoutTier.tablet16to10: (
    cardPaddingTop: 18.0,
    cardPaddingBottom: 16.0,
    cardPaddingHorizontal: 24.0,
    audioSpeakerSize: 52.0,
    nominal1LineHeight: 98.0,
    nominal2LineHeight: 128.0,
  ),
  QuestionLayoutTier.tablet16to9: (
    cardPaddingTop: 20.0,
    cardPaddingBottom: 16.0,
    cardPaddingHorizontal: 24.0,
    audioSpeakerSize: 52.0,
    nominal1LineHeight: 104.0,
    nominal2LineHeight: 136.0,
  ),
};

typedef _ButtonPreset = ({
  double fontSize,
  double singleLineHeight,
  double multiLineHeight,
  double horizontalPadding,
});

const Map<QuestionLayoutTier, Map<int, _ButtonPreset>>
    _pausedDialogueCompletionButtonPresets = {
  QuestionLayoutTier.phone16to9: {
    4: (fontSize: 14.0, singleLineHeight: 44.0, multiLineHeight: 56.0, horizontalPadding: 24.0),
    3: (fontSize: 15.0, singleLineHeight: 48.0, multiLineHeight: 60.0, horizontalPadding: 24.0),
    2: (fontSize: 16.0, singleLineHeight: 52.0, multiLineHeight: 64.0, horizontalPadding: 24.0),
  },
  QuestionLayoutTier.phoneClassic2to1: {
    4: (fontSize: 14.0, singleLineHeight: 44.0, multiLineHeight: 56.0, horizontalPadding: 24.0),
    3: (fontSize: 15.0, singleLineHeight: 48.0, multiLineHeight: 60.0, horizontalPadding: 24.0),
    2: (fontSize: 16.0, singleLineHeight: 52.0, multiLineHeight: 64.0, horizontalPadding: 24.0),
  },
  QuestionLayoutTier.phoneTransition: {
    4: (fontSize: 14.0, singleLineHeight: 45.0, multiLineHeight: 58.0, horizontalPadding: 24.0),
    3: (fontSize: 15.0, singleLineHeight: 49.0, multiLineHeight: 62.0, horizontalPadding: 24.0),
    2: (fontSize: 16.0, singleLineHeight: 53.0, multiLineHeight: 66.0, horizontalPadding: 24.0),
  },
  QuestionLayoutTier.phoneFlagship: {
    4: (fontSize: 15.0, singleLineHeight: 48.0, multiLineHeight: 60.0, horizontalPadding: 28.0),
    3: (fontSize: 16.0, singleLineHeight: 52.0, multiLineHeight: 64.0, horizontalPadding: 28.0),
    2: (fontSize: 17.0, singleLineHeight: 56.0, multiLineHeight: 70.0, horizontalPadding: 28.0),
  },
  QuestionLayoutTier.phoneSuperTall: {
    4: (fontSize: 15.0, singleLineHeight: 50.0, multiLineHeight: 62.0, horizontalPadding: 28.0),
    3: (fontSize: 16.0, singleLineHeight: 54.0, multiLineHeight: 66.0, horizontalPadding: 28.0),
    2: (fontSize: 17.0, singleLineHeight: 58.0, multiLineHeight: 72.0, horizontalPadding: 28.0),
  },
  QuestionLayoutTier.phoneUltraTall: {
    4: (fontSize: 16.0, singleLineHeight: 52.0, multiLineHeight: 64.0, horizontalPadding: 28.0),
    3: (fontSize: 17.0, singleLineHeight: 56.0, multiLineHeight: 68.0, horizontalPadding: 28.0),
    2: (fontSize: 18.0, singleLineHeight: 60.0, multiLineHeight: 74.0, horizontalPadding: 28.0),
  },
  QuestionLayoutTier.tablet4to3: {
    4: (fontSize: 18.0, singleLineHeight: 54.0, multiLineHeight: 68.0, horizontalPadding: 32.0),
    3: (fontSize: 19.0, singleLineHeight: 58.0, multiLineHeight: 72.0, horizontalPadding: 32.0),
    2: (fontSize: 20.0, singleLineHeight: 64.0, multiLineHeight: 78.0, horizontalPadding: 32.0),
  },
  QuestionLayoutTier.tablet3to2: {
    4: (fontSize: 19.0, singleLineHeight: 58.0, multiLineHeight: 72.0, horizontalPadding: 34.0),
    3: (fontSize: 20.0, singleLineHeight: 62.0, multiLineHeight: 76.0, horizontalPadding: 34.0),
    2: (fontSize: 21.0, singleLineHeight: 66.0, multiLineHeight: 82.0, horizontalPadding: 34.0),
  },
  QuestionLayoutTier.tablet16to10: {
    4: (fontSize: 19.0, singleLineHeight: 60.0, multiLineHeight: 74.0, horizontalPadding: 36.0),
    3: (fontSize: 20.0, singleLineHeight: 64.0, multiLineHeight: 78.0, horizontalPadding: 36.0),
    2: (fontSize: 21.0, singleLineHeight: 68.0, multiLineHeight: 84.0, horizontalPadding: 36.0),
  },
  QuestionLayoutTier.tablet16to9: {
    4: (fontSize: 20.0, singleLineHeight: 62.0, multiLineHeight: 76.0, horizontalPadding: 36.0),
    3: (fontSize: 21.0, singleLineHeight: 66.0, multiLineHeight: 80.0, horizontalPadding: 36.0),
    2: (fontSize: 22.0, singleLineHeight: 70.0, multiLineHeight: 86.0, horizontalPadding: 36.0),
  },
};

_ButtonPreset _resolveButtonPreset(QuestionLayoutTier tier, int optionCount) {
  final countKey = optionCount.clamp(2, 4);
  return _pausedDialogueCompletionButtonPresets[tier]![countKey]!;
}

int _measureWrappedLines({
  required String text,
  required double fontSize,
  required FontWeight fontWeight,
  required double maxWidth,
  required TextScaler textScaler,
  String? fontFamily,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: fontFamily ?? 'Inter',
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout(maxWidth: max(0.0, maxWidth));
  return painter.computeLineMetrics().length;
}

double _measureWrappedHeight({
  required String text,
  required double fontSize,
  required FontWeight fontWeight,
  required double maxWidth,
  required TextScaler textScaler,
  String? fontFamily,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: fontFamily ?? 'Inter',
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout(maxWidth: max(0.0, maxWidth));
  return painter.size.height;
}

class _PausedDialogueCompletionLayout {
  const _PausedDialogueCompletionLayout({
    required this.line1FontSize,
    required this.buttonFontSize,
    required this.buttonHeight,
    required this.buttonWidth,
    required this.promptBoxHeight,
    required this.promptExtension,
    required this.mediaVisibleHeight,
    required this.promptCardHeight,
    required this.containerHeight,
    required this.measuredButtonsHeight,
    required this.buttonSpacing,
    required this.promptToButtonsGap,
  });

  final double line1FontSize;
  final double buttonFontSize;
  final double buttonHeight;
  final double buttonWidth;

  final double promptBoxHeight;
  final double promptExtension;
  final double mediaVisibleHeight;
  final double promptCardHeight;
  final double containerHeight;
  final double measuredButtonsHeight;
  final double buttonSpacing;
  final double promptToButtonsGap;
}

/// `VideoConversation` answer_type `pausedDialogueCompletion`: the shared video is frozen for
/// this whole row (never played, never resumed) and used as the media in place of a static
/// image — everything else (layout, prompt card, reply buttons, audio rules) matches the
/// standalone `DialogueCompletionQuizBody` exactly. Deliberately a separate, self-contained
/// widget rather than a variant of `DialogueCompletionQuizBody` or `VideoConversationQuizBody`.
class PausedDialogueCompletionQuizBody extends StatefulWidget {
  const PausedDialogueCompletionQuizBody({
    super.key,
    required this.data,
    required this.controller,
    required this.startAt,
    this.enterAudioCue,
    this.exitCorrectAudioCue,
    this.exitWrongAudioCue,
    required this.onPlayQuestionAudio,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
    this.onUserInteracted,
    this.onOptionButtonsRendered,
    this.debugShowLayoutBounds = false,
  });

  final PausedChoiceAnswerData data;

  /// Shared `VideoPlayerController` for this level's video file — muted, seeked to [startAt],
  /// and never played by this widget. May be null/uninitialized momentarily while loading.
  final VideoPlayerController? controller;

  /// Timestamp this row's frame is frozen at (row's `start_at`/`pause_at`/`answer_until`, all
  /// equal for paused rows).
  final Duration startAt;

  /// True only inside the `testing-responsive-design` level — draws a visible outline + label
  /// around every major layout box so box boundaries/percentages can be visually audited.
  final bool debugShowLayoutBounds;

  /// Clips played in sequence, automatically, the first time this question is presented — and
  /// replayable via the audio icon any time before answering. `null`/empty disables the icon
  /// pre-answer.
  final List<String>? enterAudioCue;

  /// Clips played in sequence after a correct answer, before advancing.
  final List<String>? exitCorrectAudioCue;

  /// Clips played in sequence after a wrong answer (already resolved with the
  /// `question_exit_correct_audio` fallback applied by the caller) — also what the audio icon
  /// replays once the question has been answered wrong. `null`/empty disables the icon
  /// post-wrong.
  final List<String>? exitWrongAudioCue;
  final Future<void> Function(String path) onPlayQuestionAudio;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  /// Fired on the very first interaction with this question (button tap or audio icon press) —
  /// used to hide the footer guide hint.
  final VoidCallback? onUserInteracted;

  final void Function(int correctIndex, List<GlobalKey> buttonKeys)?
      onOptionButtonsRendered;

  @override
  State<PausedDialogueCompletionQuizBody> createState() =>
      _PausedDialogueCompletionQuizBodyState();
}

class _PausedDialogueCompletionQuizBodyState
    extends State<PausedDialogueCompletionQuizBody> {
  late List<String> _options;
  bool _locked = false;
  int? _selectedIndex;
  int? _correctIndex;
  bool _audio1Playing = false;
  bool _audio2Playing = false;
  bool _audio1Scheduled = false;
  bool _setupAudioComplete = true;
  bool _answeredWrong = false;
  bool _frameReady = false;
  List<GlobalKey> _optionButtonKeys = const [];
  bool _reportedOptionButtons = false;
  String? _lastLayoutLogKey;

  bool get _isAnswered => _locked;

  List<String>? get _manualAudioCue => !_isAnswered
      ? widget.enterAudioCue
      : (_answeredWrong ? widget.exitWrongAudioCue : null);

  bool get _hasManualAudio {
    final cue = _manualAudioCue;
    return cue != null && cue.isNotEmpty;
  }

  bool get _hasAnyAudioIcon =>
      (widget.enterAudioCue != null && widget.enterAudioCue!.isNotEmpty) ||
      (widget.exitWrongAudioCue != null && widget.exitWrongAudioCue!.isNotEmpty);

  Future<void> _playCue(List<String> cue) async {
    for (final path in cue) {
      await widget.onPlayQuestionAudio(path);
    }
  }

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _options = [d.answer, ...d.distractors]..shuffle(Random());
    _correctIndex = _options.indexOf(d.answer);
    _optionButtonKeys = List.generate(_options.length, (_) => GlobalKey());
    _setupAudioComplete =
        widget.enterAudioCue == null || widget.enterAudioCue!.isEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachFrozenFrame();
      _primeAudio();
    });
  }

  /// Ensures the shared controller is initialized, paused, and seeked to [widget.startAt].
  /// Never calls `play()` — this row's frame stays frozen for its entire lifetime.
  Future<void> _attachFrozenFrame() async {
    final controller = widget.controller;
    if (controller == null) return;
    try {
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }
      if (!mounted) return;
      debugPrint(
        '[VideoDebug] PausedDialogueCompletion._attachFrozenFrame: startAt=${widget.startAt} '
        'pos=${controller.value.position} isPlaying=${controller.value.isPlaying}',
      );
      if (controller.value.isPlaying) {
        debugPrint('[VideoDebug] PAUSE (paused-row attach) at pos=${controller.value.position}');
        await controller.pause();
      }
      if (!mounted) return;
      if (controller.value.position != widget.startAt) {
        debugPrint(
          '[VideoDebug] seekTo(${widget.startAt}) (paused-row attach) from pos=${controller.value.position}',
        );
        await controller.seekTo(widget.startAt);
        debugPrint('[VideoDebug] seekTo done, posAfter=${controller.value.position}');
      }
      if (!mounted) return;
      setState(() => _frameReady = true);
    } catch (e) {
      debugPrint(
          'PausedDialogueCompletionQuizBody: video failed to load: $e');
    }
  }

  Future<void> _primeAudio() async {
    if (_audio1Scheduled) return;
    _audio1Scheduled = true;
    final cue = widget.enterAudioCue;
    if (cue != null && cue.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _audio1Playing = true);
      try {
        await _playCue(cue);
      } finally {
        if (mounted) {
          setState(() {
            _audio1Playing = false;
            _setupAudioComplete = true;
          });
        }
      }
    } else if (mounted) {
      setState(() => _setupAudioComplete = true);
    }
  }

  Future<void> _playAudioManual() async {
    final cue = _manualAudioCue;
    if (cue == null || cue.isEmpty || _audio1Playing) return;
    widget.onUserInteracted?.call();
    setState(() => _audio1Playing = true);
    try {
      await _playCue(cue);
    } finally {
      if (mounted) setState(() => _audio1Playing = false);
    }
  }

  Future<void> _onTap(int i) async {
    if (_locked) return;
    widget.onUserInteracted?.call();
    final ok = _options[i] == widget.data.answer;
    setState(() {
      _locked = true;
      _selectedIndex = i;
      _answeredWrong = !ok;
    });
    if (ok) {
      widget.onPlayCorrect();
      final cue = widget.exitCorrectAudioCue;
      if (cue != null && cue.isNotEmpty) {
        setState(() => _audio2Playing = true);
        try {
          await _playCue(cue);
        } finally {
          if (mounted) setState(() => _audio2Playing = false);
        }
      }
    } else {
      widget.onPlayWrong();
    }
    if (!mounted) return;
    widget.onOutcome(ok);
  }

  _PausedDialogueCompletionLayout _computeLayout({
    required BuildContext context,
    required QuestionLayoutTier tier,
    required double availableHeight,
    required double answerWidth,
    required bool hasAudioButton,
    required double mediaHeight,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);
    final gaps = _pausedDialogueCompletionGaps[tier]!;
    final promptPreset = _pausedDialogueCompletionPromptPresets[tier]!;
    final remainderSplit = _pausedDialogueCompletionRemainderShare[tier]!;
    final buttonPreset = _resolveButtonPreset(tier, _options.length);

    final nominalPromptHeight = availableHeight * remainderSplit.prompt;
    final nominalButtonsHeight = availableHeight * remainderSplit.buttons;

    // The button column below is wrapped in `Padding(horizontal: gaps.containerHorizontalPadding)`
    // — both the shared button width and its text-wrap measurement must account for that or they
    // assume more room than the buttons actually render into, same class of bug as the prompt
    // card: under-counting wrapped lines and letting real content overflow into scroll.
    final buttonAreaWidth =
        max(0.0, answerWidth - gaps.containerHorizontalPadding * 2);

    final buttonContentWidth = max(
      0.0,
      buttonAreaWidth -
          buttonPreset.horizontalPadding -
          McqPillAnswerButton.wrongStateIconSize -
          McqPillAnswerButton.wrongStateIconGap,
    );

    int maxOptionLines = 1;
    for (final opt in _options) {
      final lines = _measureWrappedLines(
        text: opt,
        fontSize: buttonPreset.fontSize,
        fontWeight: FontWeight.w500,
        maxWidth: buttonContentWidth,
        textScaler: textScaler,
      );
      if (lines > maxOptionLines) maxOptionLines = lines;
    }

    final double sharedButtonHeight;
    if (maxOptionLines <= 1) {
      sharedButtonHeight = buttonPreset.singleLineHeight;
    } else if (maxOptionLines == 2) {
      sharedButtonHeight = buttonPreset.multiLineHeight;
    } else {
      sharedButtonHeight =
          buttonPreset.multiLineHeight + (maxOptionLines - 2) * 20.0;
    }

    final optionCount = _options.length;
    final measuredButtonsHeight = optionCount * sharedButtonHeight +
        max(0, optionCount - 1) * gaps.buttonSpacing;
    final measuredButtonsTotalHeight =
        measuredButtonsHeight + gaps.promptToButtonsGap;

    final buttonWidth = buttonAreaWidth;

    // The prompt card's own Container (below) has a fixed 16px left/right padding regardless of
    // tier — `promptPreset.cardPaddingHorizontal` (14–24, tier-varying) doesn't actually match
    // that literal render padding, so subtracting it under-corrected the real available width on
    // several tiers. Use the real fixed 32px instead, matching what the Container actually
    // renders — otherwise the wrap estimate assumes more room than line1 renders into,
    // under-counting wrapped lines and letting real content overflow into the scroll fallback.
    final line1FontSize = buttonPreset.fontSize * 1.1;
    final line1WrapWidth = max(
      0.0,
      answerWidth -
          (hasAudioButton ? promptPreset.audioSpeakerSize + 8.0 : 0.0) -
          32.0,
    );

    final line1TextHeight = _measureWrappedHeight(
      text: widget.data.line1 ?? '',
      fontSize: line1FontSize,
      fontWeight: FontWeight.w700,
      maxWidth: line1WrapWidth,
      textScaler: textScaler,
    );

    final measuredPromptHeight = max(
      promptPreset.nominal1LineHeight,
      line1TextHeight +
          promptPreset.cardPaddingTop +
          promptPreset.cardPaddingBottom,
    );

    final buttonsShortfall =
        max(0.0, measuredButtonsTotalHeight - nominalButtonsHeight);
    final promptShortfall =
        max(0.0, measuredPromptHeight - nominalPromptHeight);
    final totalShortfall = buttonsShortfall + promptShortfall;

    // Media (the frozen video frame) is always rendered at its full, fixed `mediaHeight` — it
    // is never shrunk. Cascade extension is covered by drawing the prompt card on top of it.
    final maxMediaExtension = mediaHeight;
    final promptExtension = min(totalShortfall, maxMediaExtension);
    final overflowBeyondMedia = max(0.0, totalShortfall - maxMediaExtension);

    final mediaVisibleHeight = max(0.0, mediaHeight - promptExtension);
    final promptCardHeight = nominalPromptHeight + promptShortfall;
    final containerHeight = mediaVisibleHeight + promptCardHeight;

    if (maxOptionLines > 2 || optionCount > 4) {
      debugPrint(
        '[QuestionLayout][PausedDialogueCompletion][Warning] '
        'content exceeded standard row cap (maxLines=$maxOptionLines, optionCount=$optionCount) '
        '— consider shortening question; cascade extension is absorbing ${promptExtension.toStringAsFixed(1)}px.',
      );
    }
    if (overflowBeyondMedia > 0.0) {
      debugPrint(
        '[QuestionLayout][PausedDialogueCompletion][Severe] '
        'total shortfall (${totalShortfall.toStringAsFixed(1)}px) exceeds available media extension (${maxMediaExtension.toStringAsFixed(1)}px); '
        'answer area will scroll ${overflowBeyondMedia.toStringAsFixed(1)}px.',
      );
    }

    return _PausedDialogueCompletionLayout(
      line1FontSize: line1FontSize,
      buttonFontSize: buttonPreset.fontSize,
      buttonHeight: sharedButtonHeight,
      buttonWidth: buttonWidth,
      promptBoxHeight: nominalPromptHeight,
      promptExtension: promptExtension,
      mediaVisibleHeight: containerHeight - promptCardHeight,
      promptCardHeight: promptCardHeight,
      containerHeight: containerHeight,
      measuredButtonsHeight: measuredButtonsHeight,
      buttonSpacing: gaps.buttonSpacing,
      promptToButtonsGap: gaps.promptToButtonsGap,
    );
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

    final controller = widget.controller;
    final hasVideo =
        _frameReady && controller != null && controller.value.isInitialized;
    final videoAspectRatio = hasVideo ? controller.value.aspectRatio : 1.0;
    final dcBudget = QuestionLayoutBudget.of(context);

    return LayoutBuilder(
      builder: (context, bodyConstraints) {
        final budget = QuestionLayoutBudget.of(context);
        // Must come from the LayoutBuilder's real local constraints, not MediaQuery's screen
        // width — the question body has its own horizontal padding, so the screen width is
        // wider than what's actually available here. Using the screen width would make every
        // downstream text-wrap estimate assume more room than options actually render into,
        // under-counting wrapped lines and letting real content silently overflow.
        final answerWidth =
            dcBudget.answerWidthForAvailable(bodyConstraints.maxWidth);
        final mediaWidthLimit =
            budget.mediaWidthForAvailable(bodyConstraints.maxWidth);
        final mediaHeight =
            min(mediaWidthLimit, budget.mediaHeightForAvailable(bodyConstraints.maxHeight));

        final hasAudioButton = _hasAnyAudioIcon;
        final availableRemainderHeight = max(
          0.0,
          bodyConstraints.maxHeight - mediaHeight,
        );

        final layout = _computeLayout(
          context: context,
          tier: budget.tier,
          availableHeight: availableRemainderHeight,
          answerWidth: answerWidth,
          hasAudioButton: hasAudioButton,
          mediaHeight: mediaHeight,
        );

        final gaps = _pausedDialogueCompletionGaps[budget.tier]!;
        final promptPreset = _pausedDialogueCompletionPromptPresets[budget.tier]!;

        final textScaler = MediaQuery.textScalerOf(context);
        final layoutLogKey = [
          bodyConstraints.maxWidth,
          bodyConstraints.maxHeight,
          mediaWidthLimit,
          mediaHeight,
          layout.promptBoxHeight,
          layout.promptExtension,
          layout.measuredButtonsHeight,
          layout.buttonWidth,
          layout.buttonHeight,
          layout.line1FontSize,
          layout.buttonFontSize,
          textScaler.scale(1.0),
          budget.tier,
        ].join('|');

        if (_lastLayoutLogKey != layoutLogKey) {
          _lastLayoutLogKey = layoutLogKey;
          debugPrint(
            '[QuestionLayout][PausedDialogueCompletion] '
            'tier=${budget.tier.name} '
            'textScale=${textScaler.scale(1.0).toStringAsFixed(2)} '
            'localBody=${bodyConstraints.maxWidth.toStringAsFixed(1)}x${bodyConstraints.maxHeight.toStringAsFixed(1)}px '
            'media=${mediaWidthLimit.toStringAsFixed(1)}x${mediaHeight.toStringAsFixed(1)}px '
            'promptCard=${answerWidth.toStringAsFixed(1)}x${layout.promptCardHeight.toStringAsFixed(1)}px '
            'promptExtension=${layout.promptExtension.toStringAsFixed(1)}px '
            'buttonsHeight=${layout.measuredButtonsHeight.toStringAsFixed(1)}px '
            'button=${layout.buttonWidth.toStringAsFixed(1)}x${layout.buttonHeight.toStringAsFixed(1)}px '
            'promptText=${layout.line1FontSize.toStringAsFixed(1)}px '
            'buttonText=${layout.buttonFontSize.toStringAsFixed(1)}px '
            'video=$hasVideo audio=$hasAudioButton',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: layout.containerHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: mediaHeight,
                    child: DebugLayoutBox(
                      enabled: widget.debugShowLayoutBounds,
                      label: 'media',
                      child: StandardQuestionMedia(
                        availableBodyHeight: bodyConstraints.maxHeight,
                        aspectRatio: videoAspectRatio,
                        heightOverride: mediaHeight,
                        widthOverride: mediaWidthLimit,
                        child: hasVideo
                            ? AspectRatio(
                                aspectRatio: videoAspectRatio,
                                child: VideoPlayer(controller),
                              )
                            : ColoredBox(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: layout.promptCardHeight,
                    child: DebugLayoutBox(
                      enabled: widget.debugShowLayoutBounds,
                      label: 'prompt',
                      color: Colors.orange,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          promptPreset.cardPaddingTop,
                          16,
                          promptPreset.cardPaddingBottom,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: max(0.0, answerWidth - 32.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.data.line1 ?? '',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: const Color(0xFF171A1F),
                                          fontWeight: FontWeight.w700,
                                          fontSize: layout.line1FontSize,
                                        ),
                                  ),
                                ),
                                if (_hasAnyAudioIcon) ...[
                                  const SizedBox(width: 8),
                                  AudioPlayButton(
                                    isPlaying: _audio1Playing || _audio2Playing,
                                    onPressed: _hasManualAudio
                                        ? _playAudioManual
                                        : null,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DebugLayoutBox(
                enabled: widget.debugShowLayoutBounds,
                label: 'buttons',
                color: Colors.blue,
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: gaps.containerHorizontalPadding,
                        vertical: gaps.promptToButtonsGap / 2,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: !_setupAudioComplete
                            ? const [SizedBox.shrink()]
                            : List.generate(_options.length, (i) {
                                final opt = _options[i];
                                final isSel = _selectedIndex == i;
                                final isCor = _locked && i == _correctIndex;
                                final isWrongPick = _locked && isSel && !isCor;
                                final state = isCor
                                    ? McqAnswerState.correct
                                    : isWrongPick
                                        ? McqAnswerState.wrong
                                        : McqAnswerState.neutral;
                                return Padding(
                                  key: _optionButtonKeys.length > i
                                      ? _optionButtonKeys[i]
                                      : null,
                                  padding: EdgeInsets.only(
                                    bottom: i == _options.length - 1
                                        ? 0
                                        : layout.buttonSpacing,
                                  ),
                                  child: McqPillAnswerButton(
                                    label: opt,
                                    state: state,
                                    fontSize: layout.buttonFontSize,
                                    minHeight: layout.buttonHeight,
                                    maxHeight: layout.buttonHeight,
                                    width: layout.buttonWidth,
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
            ),
          ],
        );
      },
    );
  }
}
