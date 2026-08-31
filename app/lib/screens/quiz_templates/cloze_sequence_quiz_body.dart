import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../services/question_layout_budget.dart';
import '../../utils/cloze_blank.dart';
import '../../widgets/answer_palette.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/debug_layout_box.dart';
import '../../widgets/mcq_pill_answer_button.dart';
import '../../widgets/standard_question_media.dart';

// Share of the post-media remainder given to the dialogue box (the rest goes to the answer
// area / 2x2 grid or centered word tiles). Values match the table agreed by
// Claude/Codex/Antigravity; local to ClozeSequenceQuizBody, not shared across templates.
double _clozeSequenceDialogueShareOfRemainder(QuestionLayoutTier tier) {
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

/// Fixed per-tier answer-button text size for single-blank 2x2 MCQ mode.
const Map<QuestionLayoutTier, double> _clozeSequenceButtonTextSizeForTier = {
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

const double _clozeSequenceButtonMinTouchTarget = 44.0;

/// Grid row gap / preferred bottom padding as a percentage of the tier's single-blank button
/// font size, not a flat px constant — this mode has no independent per-tier button-height
/// preset (button height fills whatever space is available), so the font size is the only
/// tier-varying quantity available before that fill computation runs. Ratio chosen so phones
/// land back on the original flat `12.0`.
double _clozeSequenceGridGap(double buttonFontSize) =>
    (buttonFontSize * 0.67).roundToDouble();

/// Tile-wrap spacing/padding as a percentage of `_clozeTileTextProfile(tier).min` (the one
/// tier-varying bound in that profile — `.max` is flat `16` on every tier) rather than a flat
/// px constant. Ratios chosen so phones land back on the original flat values (`8.0`/`14.0`).
double _clozeTileGapFor(QuestionLayoutTier tier) =>
    (_clozeTileTextProfile(tier).min * 0.67).roundToDouble();
double _clozeTileHorizontalPaddingFor(QuestionLayoutTier tier) =>
    (_clozeTileTextProfile(tier).min * 1.17).roundToDouble();

/// Fixed per-tier max/min word-tile text size. `max` matches the app's global `bodyMedium`
/// (16px) — the size every tile used unconditionally before this fix. `min` is the floor the
/// shrink-to-fit solve below is allowed to reach on that tier before falling back to the
/// answer area's own last-resort scroll (never below the 44px touch-target floor, which is a
/// separate, unrelated invariant).
({double min, double max}) _clozeTileTextProfile(QuestionLayoutTier tier) {
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

/// Cloze-sequence quiz: shows the sentence with blank(s) as soon as the question appears.
/// **Multiple blanks:** fill in order by tapping word tiles in a horizontal wrap. **Single
/// blank:** [McqPillAnswerButton] choices, same as [DialogueCompletionQuizBody]. Visually mirrors
/// `VideoConversationQuizBody`'s `ClozeSequence` answer_type and `DialogueCompletionQuizBody`:
/// the shared regular-question media frame, a white answer panel pulled up over its bottom edge,
/// the sentence as the prompt, then either answer buttons or a tile grid. The structural
/// difference from `DialogueCompletionQuizBody` is the sentence in place of `line1`, and tiles
/// instead of buttons when there's more than one blank.
class ClozeSequenceQuizBody extends StatefulWidget {
  const ClozeSequenceQuizBody({
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
    this.onNextChoiceRendered,
    this.debugShowLayoutBounds = false,
  });

  final ClozeSequenceQuestionData data;
  final String userLanguage;

  /// True only inside the `testing-responsive-design` level — draws a visible outline + label
  /// around every major layout box so box boundaries/percentages can be visually audited.
  final bool debugShowLayoutBounds;

  /// Resolved asset path for [ClozeSequenceQuestionData.imageName], or null if the question has
  /// no image (the image block is skipped entirely, not shown as a broken placeholder).
  final String? imagePath;

  /// Setup clip for [ClozeSequenceQuestionData.line1] — plays automatically before the learner
  /// answers, mirroring [DialogueCompletionQuizBody]'s `audio1Path`.
  final String? audio1Path;

  /// Confirm clip played after the learner answers.
  final String? audio2Path;
  final Future<bool> Function(String path) resolveAudioExists;
  final Future<void> Function(String path) onPlayQuestionAudio;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;
  final void Function(int expectedIndex, List<GlobalKey> choiceKeys)?
      onNextChoiceRendered;

  @override
  State<ClozeSequenceQuizBody> createState() => _ClozeSequenceQuizBodyState();
}

enum _TileState { normal, correct, wrong, expected }

class _ClozeSequenceQuizBodyState extends State<ClozeSequenceQuizBody> {
  late List<String> _tokens;
  late List<int> _blankIndices;
  late List<String> _tiles;
  late List<String?> _filled;
  late List<_TileState> _tileStates;

  /// Single-blank mode: MCQ buttons (see [DialogueCompletionQuizBody]).
  late List<String> _buttonOptions;
  late int _buttonCorrectIndex;
  bool _buttonLocked = false;
  int? _buttonSelectedIndex;

  int _currentBlank = 0;
  bool _failed = false;
  bool _translationPenalized = false;
  bool _audioPlaying = false;
  bool _audio1Playing = false;
  bool _audio1Scheduled = false;
  bool _setupAudioComplete = true;
  Map<int, int> _expectedTileBlankIndex = {};
  late final List<GlobalKey> _choiceKeys;

  bool get _singleBlank => widget.data.answers.length == 1;

  bool get _concluded => _singleBlank
      ? _buttonLocked
      : _failed || _currentBlank >= widget.data.answers.length;

  /// True when [ClozeSequenceQuestionData.line1] has its own setup/confirm clip pair — an image
  /// question with a spoken prompt line, not the common bare-sentence case. See
  /// [DialogueCompletionQuizBody] for the pattern this mirrors.
  bool get _isDualAudio =>
      widget.audio1Path != null && widget.audio2Path != null;

  @override
  void initState() {
    super.initState();
    if (widget.audio1Path != null) {
      _setupAudioComplete = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _primeAudio1());
    }
    _tokens = widget.data.sentence.split(' ');
    _blankIndices = [
      for (var i = 0; i < _tokens.length; i++)
        if (isClozeBlankToken(_tokens[i])) i
    ];
    _filled = List.filled(_blankIndices.length, null);

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
    _reportNextChoice();
  }

  void _reportNextChoice() {
    if (_singleBlank && _buttonLocked) {
      return;
    }
    if (!_singleBlank &&
        (_failed || _currentBlank >= widget.data.answers.length)) {
      return;
    }
    final expected = _singleBlank
        ? _buttonCorrectIndex
        : _tiles.indexOf(widget.data.answers[_currentBlank]);
    if (expected < 0 || expected >= _choiceKeys.length) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onNextChoiceRendered?.call(expected, _choiceKeys);
    });
  }

  /// Fire-and-forget: plays [audio1Path] shortly after mount, before the learner answers —
  /// same 500ms-then-play pattern as [DialogueCompletionQuizBody]'s `_primeAudio`.
  Future<void> _primeAudio1() async {
    if (_audio1Scheduled) return;
    _audio1Scheduled = true;
    final p = widget.audio1Path;
    if (p == null) return;
    final ok = await widget.resolveAudioExists(p);
    if (!ok || !mounted) {
      if (mounted) setState(() => _setupAudioComplete = true);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _audio1Playing = true);
    try {
      await widget.onPlayQuestionAudio(p);
    } finally {
      if (mounted) {
        setState(() {
          _audio1Playing = false;
          _setupAudioComplete = true;
        });
      }
    }
  }

  /// Manual replay of [audio1Path] via the on-screen button — unlike [_primeAudio1], not gated
  /// by [_audio1Scheduled], so it works after the initial auto-play too.
  Future<void> _replayAudio1() async {
    final p = widget.audio1Path;
    if (p == null || _audio1Playing) return;
    final ok = await widget.resolveAudioExists(p);
    if (!ok || !mounted) return;
    setState(() => _audio1Playing = true);
    try {
      await widget.onPlayQuestionAudio(p);
    } finally {
      if (mounted) setState(() => _audio1Playing = false);
    }
  }

  /// Plays the outcome clip after the learner answers: [audio2Path] in dual mode (an image
  /// question with its own setup/confirm pair).
  Future<void> _playOutcomeAudio() async {
    if (!_isDualAudio) return;
    final p = widget.audio2Path;
    if (p == null) return;
    final ok = await widget.resolveAudioExists(p);
    if (!ok || !mounted) return;
    setState(() => _audioPlaying = true);
    try {
      await widget.onPlayQuestionAudio(p);
    } finally {
      if (mounted) setState(() => _audioPlaying = false);
    }
  }

  Future<void> _onTranslationRevealedSingle() async {
    if (_buttonLocked || widget.data.trOk) return;
    setState(() {
      _buttonLocked = true;
      _translationPenalized = true;
      _filled[0] = widget.data.answers.first;
    });
    widget.onPlayWrong();
    await _playOutcomeAudio();
    if (!mounted) return;
    widget.onOutcome(false);
  }

  Future<void> _onTranslationRevealed() async {
    if (_singleBlank) {
      await _onTranslationRevealedSingle();
      return;
    }
    if (_failed || widget.data.trOk) return;
    if (_currentBlank >= widget.data.answers.length) return;
    final newFilled = List<String?>.from(_filled);
    final newTileStates = List<_TileState>.from(_tileStates);
    for (var b = _currentBlank; b < widget.data.answers.length; b++) {
      final answer = widget.data.answers[b];
      for (var t = 0; t < _tiles.length; t++) {
        if (_tiles[t] == answer && newTileStates[t] != _TileState.correct) {
          newTileStates[t] = _TileState.correct;
          newFilled[b] = answer;
          break;
        }
      }
    }
    setState(() {
      _failed = true;
      _translationPenalized = true;
      _filled = newFilled;
      _tileStates = newTileStates;
      _currentBlank = widget.data.answers.length;
    });
    widget.onPlayWrong();
    await _playOutcomeAudio();
    if (!mounted) return;
    widget.onOutcome(false);
  }

  Future<void> _onSingleButtonTap(int i) async {
    if (_buttonLocked) return;
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
      await _playOutcomeAudio();
      if (!mounted) return;
      widget.onOutcome(false);
    }
  }

  Future<void> _onTileTap(int tileIndex) async {
    if (_failed) return;
    final word = _tiles[tileIndex];
    final state = _tileStates[tileIndex];
    // Already-placed correct tiles are inert (no full-reset on re-tap).
    if (state == _TileState.correct) return;

    final expected = widget.data.answers[_currentBlank];

    if (word == expected) {
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
          // The wrongly-tapped tile itself is eligible here too — it still shows its own
          // blank-position badge (styled wrong, i.e. red, not the blue "expected" tint) even
          // though its own tap didn't match the *current* blank.
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
      await _playOutcomeAudio();
      if (!mounted) return;
      widget.onOutcome(false);
    }
  }

  /// Revealed correct answers always render in the same correct-green (italic when
  /// revealed-not-by-the-learner rather than a separate color), instead of the old
  /// green-vs-orange distinction.
  List<InlineSpan> _buildSentenceSpans(
    ThemeData theme, {
    TextStyle? baseStyle,
  }) {
    final cs = theme.colorScheme;
    final spans = <InlineSpan>[];
    var blankI = 0;
    final defaultStyle = baseStyle ??
        theme.textTheme.titleMedium?.copyWith(
          color: const Color(0xFF171A1F),
          fontWeight: FontWeight.w700,
          fontSize: 20,
          fontFamily: 'Inter',
        );

    for (var i = 0; i < _tokens.length; i++) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' '));
      final t = _tokens[i];
      if (isClozeBlankToken(t)) {
        final core = stripClozeBlankAffixes(t);
        final coreStart = t.indexOf(core);
        final prefix = coreStart > 0 ? t.substring(0, coreStart) : '';
        final suffix = t.substring(coreStart + core.length);
        final filled = _filled[blankI];
        late final String blankText;
        late final TextStyle blankStyle;
        if (filled != null) {
          final userFilled = blankI < _currentBlank;
          blankText = filled;
          blankStyle = (defaultStyle ?? const TextStyle()).copyWith(
            color: _translationPenalized
                ? AnswerPalette.revealedFg
                : AnswerPalette.correctFg,
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
        blankI++;
      } else {
        spans.add(TextSpan(text: t, style: defaultStyle));
      }
    }
    return spans;
  }

  /// Mirrors `VideoConversationQuizBody._buildTilePanel`'s word-tile styling: stadium pill,
  /// shared [AnswerPalette], leading "x" on a wrong tap, step badge on a correct/expected tile.
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
      bg = _translationPenalized
          ? AnswerPalette.revealedBg
          : AnswerPalette.correctBg;
      border = _translationPenalized
          ? AnswerPalette.revealedBorder
          : AnswerPalette.correctBorder;
      fg = _translationPenalized
          ? AnswerPalette.revealedFg
          : AnswerPalette.correctFg;
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

  /// Dialogue text is tied to the answer text for this question. The normal and
  /// maximum dialogue size is exactly 1.10x the answer size; it may only become
  /// smaller when the dialogue box cannot fit the text at that size.
  ({double min, double regular, double max}) _clozeBubbleTextProfile(
    QuestionLayoutTier tier,
    double answerFontSize,
  ) {
    final regular = answerFontSize * 1.10;
    double tierMinimum;
    switch (tier) {
      case QuestionLayoutTier.phoneUltraTall:
      case QuestionLayoutTier.phoneSuperTall:
        tierMinimum = 15;
        break;
      case QuestionLayoutTier.phoneFlagship:
        tierMinimum = 14;
        break;
      case QuestionLayoutTier.phoneTransition:
      case QuestionLayoutTier.phoneClassic2to1:
        tierMinimum = 15;
        break;
      case QuestionLayoutTier.phone16to9:
        tierMinimum = 16;
        break;
      case QuestionLayoutTier.tablet16to9:
      case QuestionLayoutTier.tablet16to10:
        tierMinimum = 18;
        break;
      case QuestionLayoutTier.tablet3to2:
        tierMinimum = 19;
        break;
      case QuestionLayoutTier.tablet4to3:
        tierMinimum = 20;
        break;
    }
    return (
      min: min(tierMinimum, regular),
      regular: regular,
      max: regular,
    );
  }

  double _clozeNeededHeight(
    double fontSize,
    double maxWidth,
  ) {
    final line1 = widget.data.line1;
    final style = TextStyle(
      fontSize: fontSize,
      height: 1.2,
      fontWeight: FontWeight.w700,
      fontFamily: 'Inter',
    );
    final textMaxWidth = max(0.0, maxWidth - 23.0);

    double measureSentence() {
      final span = TextSpan(
        style: style,
        children: _buildSentenceSpans(Theme.of(context), baseStyle: style),
      );
      final painter = TextPainter(
        text: span,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: textMaxWidth);
      return painter.height + 19;
    }

    double measurePlain(String text) {
      final span = TextSpan(text: text, style: style);
      final painter = TextPainter(
        text: span,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: textMaxWidth);
      return painter.height + 19;
    }

    if (line1 != null) {
      return measurePlain(line1) + 10 + measureSentence();
    } else {
      return measureSentence();
    }
  }

  ({double fontSize, double overflow}) _clozeBubbleFontSizeForBox(
    QuestionLayoutTier tier,
    double maxWidth,
    double dialogueHeight,
    double answerFontSize,
  ) {
    final profile = _clozeBubbleTextProfile(tier, answerFontSize);
    final neededAtMax = _clozeNeededHeight(profile.max, maxWidth);
    if (neededAtMax <= dialogueHeight) {
      return (fontSize: profile.max, overflow: 0.0);
    }
    final neededAtMin = _clozeNeededHeight(profile.min, maxWidth);
    if (neededAtMin > dialogueHeight) {
      return (fontSize: profile.min, overflow: neededAtMin - dialogueHeight);
    }
    var lo = profile.min, hi = profile.max;
    for (var i = 0; i < 16; i++) {
      final mid = (lo + hi) / 2;
      if (_clozeNeededHeight(mid, maxWidth) <= dialogueHeight) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (fontSize: lo, overflow: 0.0);
  }

  /// Greedy left-to-right row packing that mirrors how `Wrap` actually lays tiles out (same
  /// `spacing`/`runSpacing` values used in `build()`), for a given tile order.
  int _clozeTileRowCountForOrder(
    List<String> words,
    double fontSize,
    double maxWidth,
    QuestionLayoutTier tier,
  ) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600);
    final horizontalPadding = _clozeTileHorizontalPaddingFor(tier);
    final tileGap = _clozeTileGapFor(tier);
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

  /// Row-count estimate used for the tile-shrink sizing decision — deliberately not fed the
  /// live `_tiles` order. `_tiles` is reshuffled fresh every time the learner sees this
  /// question (`initState`), and greedy `Wrap` packing is order-dependent, so sizing against
  /// today's specific shuffle let the same question sometimes need the answer area's scroll
  /// fallback and sometimes not, purely by luck of shuffle order. Sampling both a
  /// length-ascending and a length-descending copy and taking the worse (higher-row) result
  /// gives a deterministic, shuffle-independent bound instead.
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

  /// Shrink-to-fit solve for tile text size: the largest size (down to the tier floor) that
  /// packs every tile into the available `gridHeight` without needing the answer area's
  /// last-resort scroll. Mirrors `_clozeBubbleFontSizeForBox`'s bisection shape.
  double _clozeTileFontSizeForBox(
    QuestionLayoutTier tier,
    double maxWidth,
    double availableHeight,
  ) {
    final profile = _clozeTileTextProfile(tier);
    final tileGap = _clozeTileGapFor(tier);
    double neededHeightForRows(int rows) =>
        rows * _clozeSequenceButtonMinTouchTarget + (rows - 1) * tileGap;

    final rowsAtMax = _clozeTileRowCount(profile.max, maxWidth, tier);
    if (neededHeightForRows(rowsAtMax) <= availableHeight) return profile.max;

    final rowsAtMin = _clozeTileRowCount(profile.min, maxWidth, tier);
    if (neededHeightForRows(rowsAtMin) > availableHeight) return profile.min;

    var lo = profile.min, hi = profile.max;
    for (var i = 0; i < 10; i++) {
      final mid = (lo + hi) / 2;
      final rows = _clozeTileRowCount(mid, maxWidth, tier);
      if (neededHeightForRows(rows) <= availableHeight) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  Widget _buildBubble({
    required Widget child,
    required bool alignRight,
  }) {
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
        ? (_translationPenalized
            ? McqAnswerState.revealed
            : McqAnswerState.correct)
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

  void revealTranslation() => _onTranslationRevealed();

  String? _lastLayoutLogKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = widget.imagePath != null;
    final budget = QuestionLayoutBudget.of(context);
    final answerWidth =
        budget.answerWidthForAvailable(MediaQuery.sizeOf(context).width);

    return LayoutBuilder(
      builder: (context, bodyConstraints) {
        final mediaWidthLimit =
            budget.mediaWidthForAvailable(bodyConstraints.maxWidth);
        final mediaHeight = hasImage
            ? min(
                mediaWidthLimit,
                budget.mediaHeightForAvailable(bodyConstraints.maxHeight),
              )
            : 0.0;
        final remainderHeight = max(
          0.0,
          bodyConstraints.maxHeight - mediaHeight,
        );
        final dialogueHeight = remainderHeight *
            _clozeSequenceDialogueShareOfRemainder(budget.tier);
        final gridHeight = max(0.0, remainderHeight - dialogueHeight);

        final buttonFontSize =
            _clozeSequenceButtonTextSizeForTier[budget.tier]!;
        final tileFontSize = _singleBlank
            ? 0.0
            : _clozeTileFontSizeForBox(
                budget.tier,
                max(0.0, answerWidth - 32.0),
                max(0.0, gridHeight - 16.0),
              );
        final answerFontSize = _singleBlank ? buttonFontSize : tileFontSize;

        final bubbleWrapWidth =
            answerWidth - (widget.audio1Path != null ? 56 : 0);
        final dialogueTextBudget = max(0.0, dialogueHeight - 20.0 - 8.0);
        final bubbleResult = _clozeBubbleFontSizeForBox(
          budget.tier,
          bubbleWrapWidth,
          dialogueTextBudget,
          answerFontSize,
        );

        // Media is always rendered at its full, fixed `mediaHeight` — never
        // shrunk. The dialogue card covers over it as it grows, up to the
        // full media height; there is no baseline overlap floor.
        final extensionCap = hasImage ? mediaHeight : 0.0;
        final dialogueExtension = min(bubbleResult.overflow, extensionCap);
        final dialogueCardHeight = dialogueHeight + dialogueExtension;

        final numRows = max(1, (_buttonOptions.length / 2).ceil());
        final clozeGridGap = _clozeSequenceGridGap(
            _clozeSequenceButtonTextSizeForTier[budget.tier]!);
        final maxSafeGridBottomPadding = max(
          0.0,
          gridHeight -
              (numRows - 1) * clozeGridGap -
              numRows * _clozeSequenceButtonMinTouchTarget,
        );
        final gridBottomPadding = min(clozeGridGap, maxSafeGridBottomPadding);
        final buttonRowHeight = max(
          _clozeSequenceButtonMinTouchTarget,
          (gridHeight - (numRows - 1) * clozeGridGap - gridBottomPadding) /
              numRows,
        );

        final layoutLogKey = [
          bodyConstraints.maxWidth,
          bodyConstraints.maxHeight,
          mediaHeight,
          dialogueHeight,
          dialogueExtension,
          gridHeight,
          gridBottomPadding,
          bubbleResult.fontSize,
          buttonFontSize,
          buttonRowHeight,
          tileFontSize,
          budget.tier,
        ].join('|');
        if (_lastLayoutLogKey != layoutLogKey) {
          _lastLayoutLogKey = layoutLogKey;
          final dialogueAnswerRatio = answerFontSize > 0
              ? (bubbleResult.fontSize / answerFontSize).toStringAsFixed(2)
              : 'n/a';
          debugPrint(
            '[QuestionLayout][ClozeSequence] '
            'tier=${budget.tier.name} '
            'localBody=${bodyConstraints.maxWidth.toStringAsFixed(1)}x'
            '${bodyConstraints.maxHeight.toStringAsFixed(1)}px '
            'media=${mediaWidthLimit.toStringAsFixed(1)}x'
            '${mediaHeight.toStringAsFixed(1)}px '
            'dialogueBox=${answerWidth.toStringAsFixed(1)}x'
            '${dialogueHeight.toStringAsFixed(1)}px '
            'dialogueExtension=${dialogueExtension.toStringAsFixed(1)}px '
            'gridBox=${answerWidth.toStringAsFixed(1)}x'
            '${gridHeight.toStringAsFixed(1)}px '
            'gridBottomPadding=${gridBottomPadding.toStringAsFixed(1)}px '
            'bubbleText=${bubbleResult.fontSize.toStringAsFixed(1)}px '
            'tileText=${tileFontSize.toStringAsFixed(1)}px '
            'dialogueAnswerRatio=${dialogueAnswerRatio}x '
            'singleBlank=$_singleBlank '
            'hasLine1=${widget.data.line1 != null} '
            'image=$hasImage',
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
              height: mediaHeight + dialogueHeight,
              child: Stack(
                children: [
                  if (hasImage)
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
                          aspectRatio: 1,
                          heightOverride: mediaHeight,
                          widthOverride: mediaWidthLimit,
                          child: Image.asset(
                            widget.imagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child:
                                    Icon(Icons.image_not_supported, size: 48),
                              ),
                            ),
                          ),
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: hasImage
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(24))
                              : null,
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: SingleChildScrollView(
                          child: Center(
                            child: SizedBox(
                              width: answerWidth,
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
                                                  child: Text(
                                                    widget.data.line1!,
                                                    style: sharedStyle,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (widget.audio1Path != null) ...[
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 48,
                                                child: AudioPlayButton(
                                                  isPlaying: _audio1Playing,
                                                  onPressed: () =>
                                                      _replayAudio1(),
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
              height: gridHeight,
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
                                constraints: BoxConstraints(
                                  minHeight: gridHeight,
                                ),
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
                                constraints: BoxConstraints(
                                  minHeight: gridHeight,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: _clozeTileGapFor(budget.tier),
                                      runSpacing: _clozeTileGapFor(budget.tier),
                                      children: List.generate(
                                        _tiles.length,
                                        (i) => _buildTile(
                                          i,
                                          theme,
                                          minHeight:
                                              _clozeSequenceButtonMinTouchTarget,
                                          maxHeight:
                                              _clozeSequenceButtonMinTouchTarget,
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
