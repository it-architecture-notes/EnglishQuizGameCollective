import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../models/level_config.dart';
import '../../services/question_layout_budget.dart';
import '../../utils/cloze_blank.dart';
import '../../widgets/answer_palette.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/debug_layout_box.dart';
import '../../widgets/mcq_pill_answer_button.dart';
import '../../widgets/standard_question_media.dart';

/// Layout tables copied verbatim from `cloze_sequence_quiz_body.dart` — this template is
/// deliberately isolated from (not shared with) the standalone `ClozeSequence` widget, even
/// though the two are visually identical apart from the media source (frozen video vs. image).
double _pausedClozeDialogueShareOfRemainder(QuestionLayoutTier tier) {
  switch (tier) {
    case QuestionLayoutTier.phoneUltraTall:
      return 0.54;
    case QuestionLayoutTier.phoneSuperTall:
      return 0.54;
    case QuestionLayoutTier.phoneFlagship:
      return 0.52;
    case QuestionLayoutTier.phoneTransition:
      return 0.53;
    case QuestionLayoutTier.phoneClassic2to1:
      return 0.54;
    case QuestionLayoutTier.phone16to9:
      return 0.54;
    case QuestionLayoutTier.tablet16to9:
      return 0.60;
    case QuestionLayoutTier.tablet16to10:
      return 0.60;
    case QuestionLayoutTier.tablet3to2:
      return 0.62;
    case QuestionLayoutTier.tablet4to3:
      return 0.63;
  }
}

const Map<QuestionLayoutTier, double> _pausedClozeButtonTextSizeForTier = {
  QuestionLayoutTier.phoneUltraTall: 18,
  QuestionLayoutTier.phoneSuperTall: 18,
  QuestionLayoutTier.phoneFlagship: 18,
  QuestionLayoutTier.phoneTransition: 18,
  QuestionLayoutTier.phoneClassic2to1: 18,
  QuestionLayoutTier.phone16to9: 18,
  QuestionLayoutTier.tablet16to9: 20,
  QuestionLayoutTier.tablet16to10: 20,
  QuestionLayoutTier.tablet3to2: 21,
  QuestionLayoutTier.tablet4to3: 22,
};

const double _pausedClozeButtonMinTouchTarget = 44.0;

double _pausedClozeGridGap(double buttonFontSize) =>
    (buttonFontSize * 0.67).roundToDouble();

double _pausedClozeTileGapFor(QuestionLayoutTier tier) =>
    (_pausedClozeTileTextProfile(tier).min * 0.67).roundToDouble();
double _pausedClozeTileHorizontalPaddingFor(QuestionLayoutTier tier) =>
    (_pausedClozeTileTextProfile(tier).min * 1.17).roundToDouble();

({double min, double max}) _pausedClozeTileTextProfile(
    QuestionLayoutTier tier) {
  switch (tier) {
    case QuestionLayoutTier.phoneUltraTall:
    case QuestionLayoutTier.phoneSuperTall:
    case QuestionLayoutTier.phoneFlagship:
    case QuestionLayoutTier.phoneTransition:
    case QuestionLayoutTier.phoneClassic2to1:
    case QuestionLayoutTier.phone16to9:
      return (min: 12, max: 16);
    case QuestionLayoutTier.tablet16to9:
    case QuestionLayoutTier.tablet16to10:
    case QuestionLayoutTier.tablet3to2:
    case QuestionLayoutTier.tablet4to3:
      return (min: 14, max: 16);
  }
}

/// `VideoConversation` answer_type `pausedClozeSequence`: the shared video is frozen for this
/// whole row (never played, never resumed) and used as the media in place of a static image —
/// everything else (layout, sentence-with-blanks, MCQ/tile mechanics, audio rules) matches the
/// standalone `ClozeSequenceQuizBody` exactly. Deliberately a separate, self-contained widget
/// rather than a variant of `ClozeSequenceQuizBody` or `VideoConversationQuizBody`.
class PausedClozeSequenceQuizBody extends StatefulWidget {
  const PausedClozeSequenceQuizBody({
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
    this.onNextChoiceRendered,
    this.debugShowLayoutBounds = false,
  });

  final PausedClozeAnswerData data;
  final VideoPlayerController? controller;
  final Duration startAt;
  final bool debugShowLayoutBounds;

  final List<String>? enterAudioCue;
  final List<String>? exitCorrectAudioCue;
  final List<String>? exitWrongAudioCue;
  final Future<void> Function(String path) onPlayQuestionAudio;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;
  final VoidCallback? onUserInteracted;
  final void Function(int expectedIndex, List<GlobalKey> choiceKeys)?
      onNextChoiceRendered;

  @override
  State<PausedClozeSequenceQuizBody> createState() =>
      _PausedClozeSequenceQuizBodyState();
}

enum _TileState { normal, correct, wrong, expected }

class _PausedClozeSequenceQuizBodyState
    extends State<PausedClozeSequenceQuizBody> {
  late List<String> _line1Tokens;
  late List<int> _line1BlankIndices;
  late List<String> _tokens;
  late List<int> _blankIndices;
  late List<String> _tiles;
  late List<String?> _filled;
  late List<_TileState> _tileStates;

  late List<String> _buttonOptions;
  late int _buttonCorrectIndex;
  bool _buttonLocked = false;
  int? _buttonSelectedIndex;

  int _currentBlank = 0;
  bool _failed = false;
  bool _audioPlaying = false;
  bool _audio1Playing = false;
  bool _audio1Scheduled = false;
  bool _setupAudioComplete = true;
  bool _frameReady = false;
  Map<int, int> _expectedTileBlankIndex = {};
  late final List<GlobalKey> _choiceKeys;

  bool get _singleBlank => widget.data.answers.length == 1;

  bool get _concluded => _singleBlank
      ? _buttonLocked
      : _failed || _currentBlank >= widget.data.answers.length;

  bool get _isAnswered => _singleBlank ? _buttonLocked : _concluded;

  bool get _isWrong => _singleBlank
      ? (_buttonLocked && _buttonSelectedIndex != _buttonCorrectIndex)
      : _failed;

  List<String>? get _manualAudioCue => !_isAnswered
      ? widget.enterAudioCue
      : (_isWrong ? widget.exitWrongAudioCue : null);

  bool get _hasManualAudio {
    final cue = _manualAudioCue;
    return cue != null && cue.isNotEmpty;
  }

  bool get _hasAnyAudioIcon =>
      (widget.enterAudioCue != null && widget.enterAudioCue!.isNotEmpty) ||
      (widget.exitWrongAudioCue != null &&
          widget.exitWrongAudioCue!.isNotEmpty);

  Future<void> _playCue(List<String> cue) async {
    for (final path in cue) {
      await widget.onPlayQuestionAudio(path);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.enterAudioCue != null && widget.enterAudioCue!.isNotEmpty) {
      _setupAudioComplete = false;
    }
    final line1 = widget.data.line1;
    _line1Tokens = line1 == null ? <String>[] : line1.split(' ');
    _line1BlankIndices = [
      for (var i = 0; i < _line1Tokens.length; i++)
        if (isClozeBlankToken(_line1Tokens[i])) i
    ];
    _tokens = widget.data.sentence.split(' ');
    _blankIndices = [
      for (var i = 0; i < _tokens.length; i++)
        if (isClozeBlankToken(_tokens[i])) i
    ];
    _filled = List.filled(
      _line1BlankIndices.length + _blankIndices.length,
      null,
    );

    if (_singleBlank) {
      final a = widget.data.answers.first;
      _buttonOptions = [a, ...widget.data.distractors]..shuffle(Random());
      _buttonCorrectIndex = _buttonOptions.indexOf(a);
      _choiceKeys = List.generate(_buttonOptions.length, (_) => GlobalKey());
      _tiles = [];
      _tileStates = [];
    } else {
      _tiles = [...widget.data.answers, ...widget.data.distractors]
        ..shuffle(Random());
      _tileStates = List.filled(_tiles.length, _TileState.normal);
      _buttonOptions = [];
      _buttonCorrectIndex = 0;
      _choiceKeys = List.generate(_tiles.length, (_) => GlobalKey());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachFrozenFrame();
      _primeAudio1();
    });
    _reportNextChoice();
  }

  Future<void> _attachFrozenFrame() async {
    final controller = widget.controller;
    if (controller == null) return;
    try {
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }
      if (!mounted) return;
      debugPrint(
        '[VideoDebug] PausedClozeSequence._attachFrozenFrame: startAt=${widget.startAt} '
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
      debugPrint('PausedClozeSequenceQuizBody: video failed to load: $e');
    }
  }

  void _reportNextChoice() {
    if (_singleBlank && _buttonLocked) return;
    if (!_singleBlank &&
        (_failed || _currentBlank >= widget.data.answers.length)) {
      return;
    }
    final expected = _singleBlank
        ? _buttonCorrectIndex
        : widget.data.noOrder
            ? _firstRemainingTileIndex()
            : _tiles.indexOf(widget.data.answers[_currentBlank]);
    if (expected < 0 || expected >= _choiceKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onNextChoiceRendered?.call(expected, _choiceKeys);
    });
  }

  /// no_order tutorial-highlight target: the first not-yet-placed tile whose word is still
  /// among the remaining (unfilled) answers, since any of them is a valid next tap.
  int _firstRemainingTileIndex() {
    final remaining = widget.data.answers.sublist(_currentBlank);
    for (var t = 0; t < _tiles.length; t++) {
      if (_tileStates[t] == _TileState.correct) continue;
      if (remaining.contains(_tiles[t])) return t;
    }
    return -1;
  }

  Future<void> _primeAudio1() async {
    if (_audio1Scheduled) return;
    _audio1Scheduled = true;
    final cue = widget.enterAudioCue;
    if (cue == null || cue.isEmpty || !mounted) {
      if (mounted) setState(() => _setupAudioComplete = true);
      return;
    }
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
  }

  Future<void> _replayAudio1() async {
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

  Future<void> _playOutcomeAudio() async {
    final cue = widget.exitCorrectAudioCue;
    if (cue == null || cue.isEmpty) return;
    setState(() => _audioPlaying = true);
    try {
      await _playCue(cue);
    } finally {
      if (mounted) setState(() => _audioPlaying = false);
    }
  }

  Future<void> _onSingleButtonTap(int i) async {
    if (_buttonLocked) return;
    widget.onUserInteracted?.call();
    final ok = _buttonOptions[i] == widget.data.answers.first;
    setState(() {
      _buttonLocked = true;
      _buttonSelectedIndex = i;
      _filled[0] = widget.data.answers.first;
    });
    if (ok) {
      widget.onPlayCorrect();
      await _playOutcomeAudio();
      if (!mounted) return;
      widget.onOutcome(true);
    } else {
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  Future<void> _onTileTap(int tileIndex) async {
    if (_failed) return;
    final word = _tiles[tileIndex];
    final state = _tileStates[tileIndex];
    if (state == _TileState.correct) return;
    widget.onUserInteracted?.call();

    // no_order: any not-yet-filled answer is accepted at the current blank, not just the one
    // positionally assigned to it — e.g. "clean" and "relaxed" are each valid regardless of
    // which one the learner taps first, since both orderings read as correct English.
    final remainingAnswers = widget.data.answers.sublist(_currentBlank);
    final matched = widget.data.noOrder
        ? remainingAnswers.contains(word)
        : word == remainingAnswers.first;

    if (matched) {
      setState(() {
        _tileStates[tileIndex] = _TileState.correct;
        _filled[_currentBlank] = word;
        _currentBlank++;
      });
      _reportNextChoice();
      widget.onPlayCorrect();
      if (_currentBlank >= widget.data.answers.length) {
        await _playOutcomeAudio();
        if (!mounted) return;
        widget.onOutcome(true);
      }
    } else {
      final newTileStates = List<_TileState>.from(_tileStates);
      newTileStates[tileIndex] = _TileState.wrong;
      final newExpectedMap = <int, int>{};
      final newFilled = List<String?>.from(_filled);
      for (var b = _currentBlank; b < widget.data.answers.length; b++) {
        final ans = widget.data.answers[b];
        newFilled[b] = ans;
        for (var t = 0; t < _tiles.length; t++) {
          if (_tiles[t] == ans &&
              newTileStates[t] != _TileState.correct &&
              !newExpectedMap.containsKey(t)) {
            if (newTileStates[t] == _TileState.normal) {
              newTileStates[t] = _TileState.expected;
            }
            newExpectedMap[t] = b;
            break;
          }
        }
      }
      setState(() {
        _failed = true;
        _tileStates = newTileStates;
        _expectedTileBlankIndex = newExpectedMap;
        _filled = newFilled;
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  List<InlineSpan> _buildLineSpans(
    ThemeData theme, {
    required List<String> tokens,
    required int blankOffset,
    TextStyle? baseStyle,
  }) {
    final cs = theme.colorScheme;
    final spans = <InlineSpan>[];
    var lineBlankI = 0;
    final defaultStyle = baseStyle ??
        theme.textTheme.titleMedium?.copyWith(
          color: const Color(0xFF171A1F),
          fontWeight: FontWeight.w700,
          fontSize: 20,
          fontFamily: 'Inter',
        );

    for (var i = 0; i < tokens.length; i++) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' '));
      final t = tokens[i];
      if (isClozeBlankToken(t)) {
        final core = stripClozeBlankAffixes(t);
        final coreStart = t.indexOf(core);
        final prefix = coreStart > 0 ? t.substring(0, coreStart) : '';
        final suffix = t.substring(coreStart + core.length);
        final blankI = blankOffset + lineBlankI;
        final filled = _filled[blankI];
        late final String blankText;
        late final TextStyle blankStyle;
        if (filled != null) {
          final userFilled = blankI < _currentBlank;
          blankText = filled;
          blankStyle = (defaultStyle ?? const TextStyle()).copyWith(
            color: AnswerPalette.correctFg,
            fontWeight: FontWeight.w700,
            fontStyle: userFilled ? null : FontStyle.italic,
          );
        } else {
          blankText = _singleBlank ? '_____' : '_____ (${blankI + 1})';
          blankStyle = (defaultStyle ?? const TextStyle()).copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          );
        }
        if (prefix.isNotEmpty) {
          spans.add(TextSpan(text: prefix, style: defaultStyle));
        }
        spans.add(TextSpan(text: blankText, style: blankStyle));
        if (suffix.isNotEmpty) {
          spans.add(TextSpan(text: suffix, style: defaultStyle));
        }
        lineBlankI++;
      } else {
        spans.add(TextSpan(text: t, style: defaultStyle));
      }
    }
    return spans;
  }

  List<InlineSpan> _buildLine1Spans(ThemeData theme, {TextStyle? baseStyle}) =>
      _buildLineSpans(
        theme,
        tokens: _line1Tokens,
        blankOffset: 0,
        baseStyle: baseStyle,
      );

  List<InlineSpan> _buildSentenceSpans(
    ThemeData theme, {
    TextStyle? baseStyle,
  }) =>
      _buildLineSpans(
        theme,
        tokens: _tokens,
        blankOffset: _line1BlankIndices.length,
        baseStyle: baseStyle,
      );

  Widget _buildTile(
    int index,
    ThemeData theme, {
    double? minHeight,
    double? maxHeight,
    required double fontSize,
    bool compact = false,
  }) {
    final word = _tiles[index];
    final state = _tileStates[index];
    final isCorrect = state == _TileState.correct;
    final isWrong = state == _TileState.wrong;
    final isExpected = state == _TileState.expected;

    final Color bg;
    final Color border;
    final Color fg;

    if (isCorrect) {
      bg = AnswerPalette.correctBg;
      border = AnswerPalette.correctBorder;
      fg = AnswerPalette.correctFg;
    } else if (isWrong) {
      bg = AnswerPalette.wrongBg;
      border = AnswerPalette.wrongBorder;
      fg = AnswerPalette.wrongFg;
    } else if (isExpected) {
      bg = AnswerPalette.revealedBg;
      border = AnswerPalette.revealedBorder;
      fg = AnswerPalette.revealedFg;
    } else {
      bg = AnswerPalette.neutralBg;
      border = AnswerPalette.neutralBorder;
      fg = AnswerPalette.neutralFg;
    }

    final disabled = _concluded ||
        !_setupAudioComplete ||
        _audioPlaying ||
        _audio1Playing ||
        state != _TileState.normal;

    final step = isCorrect
        ? _tileStates
            .take(index + 1)
            .where((s) => s == _TileState.correct)
            .length
        : (_expectedTileBlankIndex[index] ?? -1) + 1;

    return Material(
      key: _choiceKeys[index],
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border)),
      child: InkWell(
        onTap: disabled ? null : () => _onTileTap(index),
        customBorder: StadiumBorder(side: BorderSide(color: border)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 72,
            minHeight: minHeight ?? 44,
            maxHeight: maxHeight ?? 44,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 14,
                  vertical: compact ? 6 : 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isWrong) ...[
                      Icon(Icons.close, size: 14, color: border),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        word,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if ((isCorrect || isExpected || isWrong) && step > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: border,
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _clozeNeededHeight(double fontSize, double maxWidth) {
    final line1 = widget.data.line1;
    final style = TextStyle(
      fontSize: fontSize,
      height: 1.2,
      fontWeight: FontWeight.w700,
      fontFamily: 'Inter',
    );
    final textMaxWidth = max(0.0, maxWidth - 23.0);

    double measureLine(List<String> tokens, int blankOffset) {
      final span = TextSpan(
        style: style,
        children: _buildLineSpans(
          Theme.of(context),
          tokens: tokens,
          blankOffset: blankOffset,
          baseStyle: style,
        ),
      );
      final painter = TextPainter(
        text: span,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: textMaxWidth);
      return painter.height + 19;
    }

    final sentenceHeight = measureLine(_tokens, _line1BlankIndices.length);
    return line1 != null
        ? measureLine(_line1Tokens, 0) + 10 + sentenceHeight
        : sentenceHeight;
  }

  int _clozeTileRowCountForOrder(
    List<String> words,
    double fontSize,
    double maxWidth,
    QuestionLayoutTier tier,
  ) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600);
    final horizontalPadding = _pausedClozeTileHorizontalPaddingFor(tier);
    final tileGap = _pausedClozeTileGapFor(tier);
    double tileWidth(String word) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      return max(72.0, painter.width + horizontalPadding * 2 + 4.0);
    }

    var rows = 1;
    var rowWidth = 0.0;
    for (final word in words) {
      final w = tileWidth(word);
      final needed = rowWidth == 0 ? w : rowWidth + tileGap + w;
      if (needed > maxWidth && rowWidth > 0) {
        rows++;
        rowWidth = w;
      } else {
        rowWidth = needed;
      }
    }
    return rows;
  }

  int _clozeTileRowCount(
      double fontSize, double maxWidth, QuestionLayoutTier tier) {
    final ascending = List<String>.from(_tiles)
      ..sort((a, b) => a.length.compareTo(b.length));
    final descending = ascending.reversed.toList();
    final rowsAscending =
        _clozeTileRowCountForOrder(ascending, fontSize, maxWidth, tier);
    final rowsDescending =
        _clozeTileRowCountForOrder(descending, fontSize, maxWidth, tier);
    return max(rowsAscending, rowsDescending);
  }

  Widget _buildBubble({required Widget child, required bool alignRight}) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = colorScheme.surfaceContainerHighest;
    final borderColor = colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(alignRight ? 12 : 4),
          bottomRight: Radius.circular(alignRight ? 4 : 12),
        ),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: child,
    );
  }

  Widget _buildSingleAnswerButton(
    int optionIndex, {
    required double fontSize,
    required double height,
  }) {
    if (optionIndex >= _buttonOptions.length) return const SizedBox.shrink();
    final opt = _buttonOptions[optionIndex];
    final isSel = _buttonSelectedIndex == optionIndex;
    final isCor = _buttonLocked && optionIndex == _buttonCorrectIndex;
    final isWrongPick = _buttonLocked && isSel && !isCor;
    final state = isCor
        ? McqAnswerState.correct
        : isWrongPick
            ? McqAnswerState.wrong
            : McqAnswerState.neutral;
    final busy = _buttonLocked ||
        !_setupAudioComplete ||
        _audioPlaying ||
        _audio1Playing;
    return McqPillAnswerButton(
      key: _choiceKeys[optionIndex],
      label: opt,
      state: state,
      fontSize: fontSize,
      minHeight: height,
      maxHeight: height,
      onTap: busy ? null : () => _onSingleButtonTap(optionIndex),
    );
  }

  String? _lastLayoutLogKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;
    final hasVideo =
        _frameReady && controller != null && controller.value.isInitialized;
    final videoAspectRatio = hasVideo ? controller.value.aspectRatio : 1.0;
    final budget = QuestionLayoutBudget.of(context);

    return LayoutBuilder(
      builder: (context, bodyConstraints) {
        // Must come from the LayoutBuilder's real local constraints, not MediaQuery's screen
        // width — the question body has its own horizontal padding, so the screen width is
        // wider than what's actually available here. Using the screen width would make every
        // downstream text-wrap estimate assume more room than tiles/slots actually render
        // into, under-counting wrapped rows and letting real content silently overflow.
        final answerWidth =
            budget.answerWidthForAvailable(bodyConstraints.maxWidth);
        final mediaWidthLimit =
            budget.mediaWidthForAvailable(bodyConstraints.maxWidth);
        final mediaHeight = min(mediaWidthLimit,
            budget.mediaHeightForAvailable(bodyConstraints.maxHeight));
        final remainderHeight =
            max(0.0, bodyConstraints.maxHeight - mediaHeight);
        final dialogueHeight =
            remainderHeight * _pausedClozeDialogueShareOfRemainder(budget.tier);
        final gridHeight = max(0.0, remainderHeight - dialogueHeight);

        final buttonFontSize = _pausedClozeButtonTextSizeForTier[budget.tier]!;
        final tileFontSize =
            _singleBlank ? 0.0 : questionTileTextSizeFor(budget.tier);
        final tileHeight = _singleBlank ? 0.0 : questionTileHeightFor(budget);
        final tileRows = _singleBlank
            ? 0
            : _clozeTileRowCount(
                tileFontSize,
                max(0.0, answerWidth - 32.0),
                budget.tier,
              );
        final tileNeededHeight = _singleBlank
            ? 0.0
            : tileRows * tileHeight +
                max(0, tileRows - 1) * _pausedClozeTileGapFor(budget.tier) +
                16.0;

        // The dialogue card's own Container below has 16px left/right padding (unlike the grid
        // box, which has none), so the real width available inside it is 32px narrower than
        // `answerWidth` — the wrap estimate must use this, or it silently assumes more room than
        // the sentence text actually renders into, under-counting wrapped lines and letting real
        // content overflow into the scroll fallback.
        final dialogueCardContentWidth = max(0.0, answerWidth - 32);
        final bubbleWrapWidth =
            dialogueCardContentWidth - (_hasAnyAudioIcon ? 56 : 0);
        final dialogueTextBudget = max(0.0, dialogueHeight - 20.0 - 8.0);
        final sentenceFontSize = questionSentenceTextSizeFor(budget.tier);
        final sentenceNeededHeight =
            _clozeNeededHeight(sentenceFontSize, bubbleWrapWidth);
        final bubbleResult = (
          fontSize: sentenceFontSize,
          overflow: max(0.0, sentenceNeededHeight - dialogueTextBudget),
        );

        final extensionCap = mediaHeight;
        final dialogueExtension = min(bubbleResult.overflow, extensionCap);
        final tileExtension = min(
          max(0.0, tileNeededHeight - gridHeight),
          max(0.0, extensionCap - dialogueExtension),
        );
        final totalExtension = dialogueExtension + tileExtension;
        final dialogueCardHeight = dialogueHeight + dialogueExtension;
        final gridHeightFinal = gridHeight + tileExtension;

        final numRows = max(1, (_buttonOptions.length / 2).ceil());
        final clozeGridGap = _pausedClozeGridGap(
            _pausedClozeButtonTextSizeForTier[budget.tier]!);
        final maxSafeGridBottomPadding = max(
          0.0,
          gridHeight -
              (numRows - 1) * clozeGridGap -
              numRows * _pausedClozeButtonMinTouchTarget,
        );
        final gridBottomPadding = min(clozeGridGap, maxSafeGridBottomPadding);
        final buttonRowHeight = max(
          _pausedClozeButtonMinTouchTarget,
          (gridHeight - (numRows - 1) * clozeGridGap - gridBottomPadding) /
              numRows,
        );

        final layoutLogKey = [
          bodyConstraints.maxWidth,
          bodyConstraints.maxHeight,
          mediaHeight,
          dialogueHeight,
          dialogueExtension,
          gridHeightFinal,
          gridBottomPadding,
          bubbleResult.fontSize,
          buttonFontSize,
          buttonRowHeight,
          tileFontSize,
          budget.tier,
        ].join('|');
        if (_lastLayoutLogKey != layoutLogKey) {
          _lastLayoutLogKey = layoutLogKey;
          debugPrint(
            '[QuestionLayout][PausedClozeSequence] '
            'tier=${budget.tier.name} singleBlank=$_singleBlank '
            'hasLine1=${widget.data.line1 != null} video=$hasVideo',
          );
        }

        final sharedStyle = TextStyle(
          color: const Color(0xFF171A1F),
          fontWeight: FontWeight.w700,
          fontSize: bubbleResult.fontSize,
          height: 1.2,
          fontFamily: 'Inter',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: (mediaHeight - totalExtension) + dialogueHeight,
              child: Stack(
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
                    height: dialogueCardHeight,
                    child: DebugLayoutBox(
                      enabled: widget.debugShowLayoutBounds,
                      label: 'dialogue',
                      color: Colors.orange,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: SingleChildScrollView(
                          child: Center(
                            child: SizedBox(
                              width: dialogueCardContentWidth,
                              child: widget.data.line1 != null
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: _buildBubble(
                                                  alignRight: false,
                                                  child: RichText(
                                                    textScaler:
                                                        MediaQuery.textScalerOf(
                                                            context),
                                                    text: TextSpan(
                                                      style: sharedStyle,
                                                      children:
                                                          _buildLine1Spans(
                                                        theme,
                                                        baseStyle: sharedStyle,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (_hasAnyAudioIcon) ...[
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 48,
                                                child: AudioPlayButton(
                                                  isPlaying: _audio1Playing,
                                                  onPressed: _hasManualAudio
                                                      ? () => _replayAudio1()
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: _buildBubble(
                                            alignRight: true,
                                            child: RichText(
                                              textScaler:
                                                  MediaQuery.textScalerOf(
                                                      context),
                                              text: TextSpan(
                                                style: sharedStyle,
                                                children: _buildSentenceSpans(
                                                  theme,
                                                  baseStyle: sharedStyle,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: _buildBubble(
                                        alignRight: false,
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          textScaler:
                                              MediaQuery.textScalerOf(context),
                                          text: TextSpan(
                                            style: sharedStyle,
                                            children: _buildSentenceSpans(
                                              theme,
                                              baseStyle: sharedStyle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: gridHeightFinal,
              child: DebugLayoutBox(
                enabled: widget.debugShowLayoutBounds,
                label: 'grid',
                color: Colors.blue,
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: SizedBox(
                      width: answerWidth,
                      child: _singleBlank
                          ? SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(minHeight: gridHeightFinal),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var r = 0; r < numRows; r++) ...[
                                      if (r > 0) SizedBox(height: clozeGridGap),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildSingleAnswerButton(
                                              r * 2,
                                              fontSize: buttonFontSize,
                                              height: buttonRowHeight,
                                            ),
                                          ),
                                          if (r * 2 + 1 <
                                              _buttonOptions.length) ...[
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildSingleAnswerButton(
                                                r * 2 + 1,
                                                fontSize: buttonFontSize,
                                                height: buttonRowHeight,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                    if (gridBottomPadding > 0)
                                      SizedBox(height: gridBottomPadding),
                                  ],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(minHeight: gridHeight),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing:
                                          _pausedClozeTileGapFor(budget.tier),
                                      runSpacing:
                                          _pausedClozeTileGapFor(budget.tier),
                                      children: List.generate(
                                        _tiles.length,
                                        (i) => _buildTile(
                                          i,
                                          theme,
                                          minHeight: tileHeight,
                                          maxHeight: tileHeight,
                                          fontSize: tileFontSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
