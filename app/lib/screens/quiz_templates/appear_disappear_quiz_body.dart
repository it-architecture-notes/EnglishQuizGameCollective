import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../services/question_layout_budget.dart';
import '../../widgets/answer_palette.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/debug_layout_box.dart';
import '../../widgets/standard_question_media.dart';

typedef _RowPreset = ({double height, double fontSize});

/// Remainder height fraction dedicated to the prompt card (`line1 != null`). Flat 24% on every
/// tier (developer-directed parity with `SentenceBuilder`) — was previously tier-varying.
const Map<QuestionLayoutTier, double> _appearDisappearPromptShare = {
  QuestionLayoutTier.phoneUltraTall: 0.24,
  QuestionLayoutTier.phoneSuperTall: 0.24,
  QuestionLayoutTier.phoneFlagship: 0.24,
  QuestionLayoutTier.phoneTransition: 0.24,
  QuestionLayoutTier.phoneClassic2to1: 0.24,
  QuestionLayoutTier.phone16to9: 0.24,
  QuestionLayoutTier.tablet16to9: 0.24,
  QuestionLayoutTier.tablet16to10: 0.24,
  QuestionLayoutTier.tablet3to2: 0.24,
  QuestionLayoutTier.tablet4to3: 0.24,
};

/// Remainder height fraction dedicated to the slot row (answer blanks). Flat 30% on every tier
/// (developer-directed parity with `SentenceBuilder`) — was previously tier-varying.
const Map<QuestionLayoutTier, double> _appearDisappearSlotShare = {
  QuestionLayoutTier.phoneUltraTall: 0.30,
  QuestionLayoutTier.phoneSuperTall: 0.30,
  QuestionLayoutTier.phoneFlagship: 0.30,
  QuestionLayoutTier.phoneTransition: 0.30,
  QuestionLayoutTier.phoneClassic2to1: 0.30,
  QuestionLayoutTier.phone16to9: 0.30,
  QuestionLayoutTier.tablet16to9: 0.30,
  QuestionLayoutTier.tablet16to10: 0.30,
  QuestionLayoutTier.tablet3to2: 0.30,
  QuestionLayoutTier.tablet4to3: 0.30,
};

/// Remainder height fraction dedicated to the tile bank (word choices). Flat 46% on every tier
/// (developer-directed parity with `SentenceBuilder`) — was previously tier-varying.
const Map<QuestionLayoutTier, double> _appearDisappearTileBankShare = {
  QuestionLayoutTier.phoneUltraTall: 0.46,
  QuestionLayoutTier.phoneSuperTall: 0.46,
  QuestionLayoutTier.phoneFlagship: 0.46,
  QuestionLayoutTier.phoneTransition: 0.46,
  QuestionLayoutTier.phoneClassic2to1: 0.46,
  QuestionLayoutTier.phone16to9: 0.46,
  QuestionLayoutTier.tablet16to9: 0.46,
  QuestionLayoutTier.tablet16to10: 0.46,
  QuestionLayoutTier.tablet3to2: 0.46,
  QuestionLayoutTier.tablet4to3: 0.46,
};

/// Prompt card font/padding, standalone per tier — no ratio to tile/slot font since the caption
/// is an independent title line, not an "answer" hierarchy like `DialogueCompletion`'s.
typedef _PromptPreset = ({
  double fontSize,
  double cardPaddingTop,
  double cardPaddingBottom,
  double nominal1LineHeight,
  double nominal2LineHeight,
});

const Map<QuestionLayoutTier, _PromptPreset> _appearDisappearPromptPresets = {
  QuestionLayoutTier.phone16to9: (
    fontSize: 15.4,
    cardPaddingTop: 12,
    cardPaddingBottom: 10,
    nominal1LineHeight: 68,
    nominal2LineHeight: 88,
  ),
  QuestionLayoutTier.phoneClassic2to1: (
    fontSize: 15.4,
    cardPaddingTop: 12,
    cardPaddingBottom: 10,
    nominal1LineHeight: 68,
    nominal2LineHeight: 88,
  ),
  QuestionLayoutTier.phoneTransition: (
    fontSize: 15.4,
    cardPaddingTop: 12,
    cardPaddingBottom: 10,
    nominal1LineHeight: 70,
    nominal2LineHeight: 90,
  ),
  QuestionLayoutTier.phoneFlagship: (
    fontSize: 16.5,
    cardPaddingTop: 14,
    cardPaddingBottom: 12,
    nominal1LineHeight: 76,
    nominal2LineHeight: 98,
  ),
  QuestionLayoutTier.phoneSuperTall: (
    fontSize: 16.5,
    cardPaddingTop: 14,
    cardPaddingBottom: 12,
    nominal1LineHeight: 78,
    nominal2LineHeight: 100,
  ),
  QuestionLayoutTier.phoneUltraTall: (
    fontSize: 17.6,
    cardPaddingTop: 14,
    cardPaddingBottom: 12,
    nominal1LineHeight: 80,
    nominal2LineHeight: 104,
  ),
  QuestionLayoutTier.tablet4to3: (
    fontSize: 19.8,
    cardPaddingTop: 16,
    cardPaddingBottom: 14,
    nominal1LineHeight: 88,
    nominal2LineHeight: 116,
  ),
  QuestionLayoutTier.tablet3to2: (
    fontSize: 20.9,
    cardPaddingTop: 18,
    cardPaddingBottom: 16,
    nominal1LineHeight: 94,
    nominal2LineHeight: 124,
  ),
  QuestionLayoutTier.tablet16to10: (
    fontSize: 20.9,
    cardPaddingTop: 18,
    cardPaddingBottom: 16,
    nominal1LineHeight: 98,
    nominal2LineHeight: 128,
  ),
  QuestionLayoutTier.tablet16to9: (
    fontSize: 22.0,
    cardPaddingTop: 20,
    cardPaddingBottom: 16,
    nominal1LineHeight: 104,
    nominal2LineHeight: 136,
  ),
};

/// Discrete tile presets keyed by row count (index 0 = 1 row, 1 = 2 rows, 2 = 3 rows — the
/// agreed max before content-authoring debt). Same numbers as `SentenceBuilder`'s tile ladder —
/// same underlying problem (word tiles wrapped in a `Wrap`), already vetted against real
/// per-tier remainder budgets.
const Map<QuestionLayoutTier, List<_RowPreset>> _appearDisappearTilePresets = {
  QuestionLayoutTier.phone16to9: [
    (height: 52, fontSize: 15),
    (height: 48, fontSize: 14),
    (height: 44, fontSize: 12),
  ],
  QuestionLayoutTier.phoneClassic2to1: [
    (height: 52, fontSize: 15),
    (height: 48, fontSize: 14),
    (height: 44, fontSize: 12),
  ],
  QuestionLayoutTier.phoneTransition: [
    (height: 52, fontSize: 15),
    (height: 48, fontSize: 14),
    (height: 44, fontSize: 12),
  ],
  QuestionLayoutTier.phoneFlagship: [
    (height: 54, fontSize: 16),
    (height: 49, fontSize: 14),
    (height: 44, fontSize: 12),
  ],
  QuestionLayoutTier.phoneSuperTall: [
    (height: 56, fontSize: 16),
    (height: 50, fontSize: 15),
    (height: 44, fontSize: 13),
  ],
  QuestionLayoutTier.phoneUltraTall: [
    (height: 58, fontSize: 17),
    (height: 51, fontSize: 15),
    (height: 44, fontSize: 13),
  ],
  QuestionLayoutTier.tablet4to3: [
    (height: 60, fontSize: 19),
    (height: 52, fontSize: 17),
    (height: 44, fontSize: 15),
  ],
  QuestionLayoutTier.tablet3to2: [
    (height: 62, fontSize: 20),
    (height: 54, fontSize: 18),
    (height: 44, fontSize: 16),
  ],
  QuestionLayoutTier.tablet16to10: [
    (height: 64, fontSize: 21),
    (height: 55, fontSize: 18),
    (height: 44, fontSize: 16),
  ],
  QuestionLayoutTier.tablet16to9: [
    (height: 66, fontSize: 22),
    (height: 56, fontSize: 19),
    (height: 44, fontSize: 17),
  ],
};

/// Discrete slot presets keyed by row count (index 0 = 1 row, 1 = 2 rows — the agreed max).
/// Slots are display-only (not independently tappable), so no 44px touch-target floor —
/// same numbers as `SentenceBuilder`'s slot ladder.
const Map<QuestionLayoutTier, List<_RowPreset>> _appearDisappearSlotPresets = {
  QuestionLayoutTier.phone16to9: [
    (height: 44, fontSize: 14),
    (height: 34, fontSize: 12),
  ],
  QuestionLayoutTier.phoneClassic2to1: [
    (height: 44, fontSize: 14),
    (height: 34, fontSize: 12),
  ],
  QuestionLayoutTier.phoneTransition: [
    (height: 45, fontSize: 14),
    (height: 35, fontSize: 12),
  ],
  QuestionLayoutTier.phoneFlagship: [
    (height: 48, fontSize: 15),
    (height: 39, fontSize: 12),
  ],
  QuestionLayoutTier.phoneSuperTall: [
    (height: 50, fontSize: 15),
    (height: 43, fontSize: 13),
  ],
  QuestionLayoutTier.phoneUltraTall: [
    (height: 52, fontSize: 16),
    (height: 47, fontSize: 13),
  ],
  QuestionLayoutTier.tablet4to3: [
    (height: 54, fontSize: 18),
    (height: 48, fontSize: 15),
  ],
  QuestionLayoutTier.tablet3to2: [
    (height: 60, fontSize: 19),
    (height: 58, fontSize: 16),
  ],
  QuestionLayoutTier.tablet16to10: [
    (height: 64, fontSize: 20),
    (height: 62, fontSize: 16),
  ],
  QuestionLayoutTier.tablet16to9: [
    (height: 68, fontSize: 21),
    (height: 66, fontSize: 17),
  ],
};

/// Row gap as a percentage of the currently active row height — spacing scales with element
/// size instead of a flat px constant looking lost on large tiles or cramped on small ones.
double _appearDisappearRowGap(double rowHeight) =>
    (rowHeight * 0.15).roundToDouble();

/// Cell horizontal padding and minimum width, derived from the active row height — used
/// identically for measurement and the real rendered cell so the two never diverge.
({double minWidth, double horizontalPadding}) _appearDisappearCellMetrics(
    double height) {
  return (minWidth: height * 1.3, horizontalPadding: height * 0.5);
}

/// Result of resolving a component (tiles or slots) against its discrete preset ladder.
typedef _PresetResolution = ({
  double height,
  double fontSize,
  int rows,
  double shortfallHeight,
});

enum _Phase { revealing, clearing, interaction }

/// Words visible immediately → audio plays → 500 ms after audio → words clear → recall.
class AppearDisappearQuizBody extends StatefulWidget {
  const AppearDisappearQuizBody({
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
    this.onNextTileRendered,
    this.debugShowLayoutBounds = false,
  });

  final AppearDisappearQuestionData data;
  final String userLanguage;
  final String? imagePath;

  /// True only inside the `testing-responsive-design` level — draws a visible outline + label
  /// around every major layout box so box boundaries/percentages can be visually audited.
  final bool debugShowLayoutBounds;
  final String? audio1Path;
  final String? audio2Path;
  final Future<bool> Function(String path) resolveAudioExists;
  final Future<void> Function(String path) onPlayQuestionAudio;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;
  final void Function(int expectedIndex, List<GlobalKey> tileKeys)?
      onNextTileRendered;

  @override
  State<AppearDisappearQuizBody> createState() =>
      _AppearDisappearQuizBodyState();
}

class _AppearDisappearQuizBodyState extends State<AppearDisappearQuizBody> {
  late List<String> _shuffledChoices;

  _Phase _phase = _Phase.revealing;
  bool _interactionEnabled = false;

  int _tapProgress = 0;
  final List<String?> _interactionSlots = [];
  final List<bool> _slotFromPlayer = [];
  bool _failed = false;
  bool _translationPenalized = false;
  int? _wrongGridIndex;
  final Set<int> _correctGridIndices = {};
  final Map<int, int> _gridIndexToStep = {};
  late final List<GlobalKey> _tileKeys;
  bool _completed = false;
  bool _audio1Playing = false;
  bool _audio2Playing = false;
  bool _audio1Scheduled = false;

  /// True while the answer should be visible in the slots during the reveal sequence — set the
  /// moment the narrating audio actually *starts* playing (not after it ends), so the learner
  /// sees/hears the answer together, not sequentially. See `_runRevealSequence`.
  bool _revealAnswer = false;

  List<String> get _sentence => widget.data.words;

  @override
  void initState() {
    super.initState();
    final combined = [...widget.data.words, ...widget.data.distractors]
      ..shuffle(Random());
    _shuffledChoices = combined;
    _tileKeys = List.generate(_shuffledChoices.length, (_) => GlobalKey());
    for (var i = 0; i < _sentence.length; i++) {
      _interactionSlots.add(null);
      _slotFromPlayer.add(false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runRevealSequence();
    });
  }

  /// Two reveal shapes, both developer-specified:
  /// - **No `line1`** (single-audio type): `audio1` narrates the answer (`words`) directly. The
  ///   answer becomes visible in the slots the moment `audio1` *starts* playing (not after it
  ///   ends), so the learner sees and hears it together.
  /// - **`line1` present** (dual-audio type): `line1` is shown from the start (unconditionally,
  ///   via `hasLine1` — not gated by this sequence) while `audio1` narrates it with the answer
  ///   still hidden; once `audio1` finishes, `audio2` narrates the answer and the answer becomes
  ///   visible the moment `audio2` starts playing.
  ///
  /// Either way, once revealed the answer stays up through the narrating audio plus a short
  /// extra hold (not tied to audio duration — a flat per-word timer, same as before), then
  /// hides, then interaction is enabled.
  Future<void> _runRevealSequence() async {
    if (_audio1Scheduled) return;
    _audio1Scheduled = true;
    final hasLine1 = widget.data.line1 != null;

    if (hasLine1) {
      await _playNarration(widget.audio1Path,
          setPlaying: (v) => _audio1Playing = v);
      if (!mounted) return;
      await _playNarration(
        widget.audio2Path,
        setPlaying: (v) => _audio2Playing = v,
        revealOnStart: true,
      );
    } else {
      await _playNarration(
        widget.audio1Path,
        setPlaying: (v) => _audio1Playing = v,
        revealOnStart: true,
      );
    }
    if (!mounted) return;

    // Hold the reveal a bit longer than the narrating audio itself.
    await Future<void>.delayed(
        Duration(milliseconds: (_sentence.length * 400).round()));
    if (!mounted) return;
    setState(() {
      _phase = _Phase.clearing;
      _revealAnswer = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _phase = _Phase.interaction;
      _interactionEnabled = true;
    });
    _reportNextTile();
  }

  /// Awaits [path]'s existence check and playback (no-op if null or missing). When
  /// [revealOnStart] is true, `_revealAnswer` flips true the instant playback actually begins
  /// (or immediately, if there's no audio to wait for at all) — not after it ends.
  Future<void> _playNarration(
    String? path, {
    required void Function(bool) setPlaying,
    bool revealOnStart = false,
  }) async {
    if (path == null) {
      if (revealOnStart && mounted) setState(() => _revealAnswer = true);
      return;
    }
    final exists = await widget.resolveAudioExists(path);
    if (!mounted) return;
    if (!exists) {
      if (revealOnStart) setState(() => _revealAnswer = true);
      return;
    }
    setState(() {
      setPlaying(true);
      if (revealOnStart) _revealAnswer = true;
    });
    try {
      await widget.onPlayQuestionAudio(path);
    } finally {
      if (mounted) setState(() => setPlaying(false));
    }
  }

  Future<void> _playAudio1() async {
    final p = widget.audio1Path;
    if (p == null || _audio1Playing) return;
    if (!await widget.resolveAudioExists(p) || !mounted) return;
    setState(() => _audio1Playing = true);
    try {
      await widget.onPlayQuestionAudio(p);
    } finally {
      if (mounted) setState(() => _audio1Playing = false);
    }
  }

  Future<void> _playAudio2() async {
    final p = widget.audio2Path;
    if (p == null || _audio2Playing) return;
    if (!await widget.resolveAudioExists(p) || !mounted) return;
    setState(() => _audio2Playing = true);
    try {
      await widget.onPlayQuestionAudio(p);
    } finally {
      if (mounted) setState(() => _audio2Playing = false);
    }
  }

  void _reportNextTile() {
    if (!_interactionEnabled || _tapProgress >= _sentence.length) return;
    final index = _shuffledChoices.indexWhere(
      (word) =>
          word == _sentence[_tapProgress] &&
          !_correctGridIndices.contains(_shuffledChoices.indexOf(word)),
    );
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onNextTileRendered?.call(_tapProgress, _tileKeys);
    });
  }

  Future<void> _onTranslationRevealed() async {
    if (_failed || _completed || !_interactionEnabled || widget.data.trOk) {
      return;
    }
    setState(() {
      _failed = true;
      _translationPenalized = true;
      _wrongGridIndex = null;
      for (var pos = _tapProgress; pos < _sentence.length; pos++) {
        final word = _sentence[pos];
        for (var gi = 0; gi < _shuffledChoices.length; gi++) {
          if (_shuffledChoices[gi] == word &&
              !_correctGridIndices.contains(gi)) {
            _correctGridIndices.add(gi);
            _gridIndexToStep[gi] = pos + 1;
            _interactionSlots[pos] = word;
            _slotFromPlayer[pos] = false;
            break;
          }
        }
      }
      _tapProgress = _sentence.length;
    });
    widget.onPlayWrong();
    await _playAudio2();
    if (!mounted) return;
    widget.onOutcome(false);
  }

  Future<void> _onGridTap(int gridIndex) async {
    if (!_interactionEnabled || _completed || _failed) return;
    if (_correctGridIndices.contains(gridIndex) && _tapProgress > 0) {
      setState(() {
        _tapProgress = 0;
        for (var i = 0; i < _interactionSlots.length; i++) {
          _interactionSlots[i] = null;
          _slotFromPlayer[i] = false;
        }
        _correctGridIndices.clear();
        _gridIndexToStep.clear();
        _wrongGridIndex = null;
      });
      _reportNextTile();
      return;
    }
    final word = _shuffledChoices[gridIndex];
    final expected = _sentence[_tapProgress];
    if (word == expected) {
      setState(() {
        _interactionSlots[_tapProgress] = word;
        _slotFromPlayer[_tapProgress] = true;
        _correctGridIndices.add(gridIndex);
        _gridIndexToStep[gridIndex] = _tapProgress + 1;
        _tapProgress++;
      });
      _reportNextTile();
      if (_tapProgress >= _sentence.length) {
        _completed = true;
        widget.onPlayCorrect();
        await _playAudio2();
        if (!mounted) return;
        widget.onOutcome(true);
      }
    } else {
      setState(() {
        _failed = true;
        _wrongGridIndex = gridIndex;
        for (var i = _tapProgress; i < _sentence.length; i++) {
          _interactionSlots[i] = _sentence[i];
          _slotFromPlayer[i] = false;
        }
      });
      widget.onPlayWrong();
      await _playAudio2();
      if (!mounted) return;
      widget.onOutcome(false);
    }
  }

  void revealTranslation() => _onTranslationRevealed();

  double _promptNeededHeight(double fontSize, double maxWidth, String text) {
    final style = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      height: 1.2,
      fontFamily: 'Inter',
    );
    final textMaxWidth = max(0.0, maxWidth - 23.0);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: textMaxWidth);
    return painter.height + 19;
  }

  int _estimateWrapRows({
    required List<String?> items,
    required double availableWidth,
    required double spacing,
    required double minItemWidth,
    required double horizontalPadding,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    if (items.isEmpty || availableWidth <= 0) return 0;
    final direction = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    var rows = 1;
    var usedWidth = 0.0;
    for (final item in items) {
      final textWidth = item == null
          ? 0.0
          : (TextPainter(
              text: TextSpan(
                text: item,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
              textDirection: direction,
              textScaler: textScaler,
            )..layout())
              .width;
      final itemWidth = max(
        minItemWidth,
        item == null ? minItemWidth : textWidth + horizontalPadding,
      );
      if (usedWidth > 0 && usedWidth + spacing + itemWidth > availableWidth) {
        rows++;
        usedWidth = itemWidth;
      } else {
        usedWidth =
            usedWidth == 0 ? itemWidth : usedWidth + spacing + itemWidth;
      }
    }
    return rows;
  }

  /// Resolves a component (tiles or slots) against its discrete preset ladder by measuring the
  /// real live content, stepping up the ladder until it fits within that preset's row cap. Same
  /// pattern as `SentenceBuilder`'s `_resolvePreset` — the box adapts to whatever row count the
  /// live content actually needs (up to the cap, then cascade extension beyond it).
  /// [fontSizeOverride], when given, is measured (and returned) in place of each preset's own
  /// `fontSize` — used so slot text renders at the exact same size as the resolved tile font
  /// instead of its own independent size ladder (developer-directed parity with
  /// `SentenceBuilder`). The preset's `height` column is still used unmodified.
  _PresetResolution _resolvePreset({
    required List<String?> items,
    required List<_RowPreset> presets,
    required double availableWidth,
    required double availableHeight,
    required FontWeight fontWeight,
    double? fontSizeOverride,
  }) {
    for (var i = 0; i < presets.length; i++) {
      final preset = presets[i];
      final fontSize = fontSizeOverride ?? preset.fontSize;
      final metrics = _appearDisappearCellMetrics(preset.height);
      final rows = _estimateWrapRows(
        items: items,
        availableWidth: availableWidth,
        spacing: _appearDisappearRowGap(preset.height),
        minItemWidth: metrics.minWidth,
        horizontalPadding: metrics.horizontalPadding,
        fontSize: fontSize,
        fontWeight: fontWeight,
      );
      if (rows <= i + 1) {
        final needed = rows * preset.height +
            (rows - 1) * _appearDisappearRowGap(preset.height);
        return (
          height: preset.height,
          fontSize: fontSize,
          rows: rows,
          shortfallHeight: max(0.0, needed - availableHeight),
        );
      }
    }
    final maxPreset = presets.last;
    final maxFontSize = fontSizeOverride ?? maxPreset.fontSize;
    final maxMetrics = _appearDisappearCellMetrics(maxPreset.height);
    final actualRows = _estimateWrapRows(
      items: items,
      availableWidth: availableWidth,
      spacing: _appearDisappearRowGap(maxPreset.height),
      minItemWidth: maxMetrics.minWidth,
      horizontalPadding: maxMetrics.horizontalPadding,
      fontSize: maxFontSize,
      fontWeight: fontWeight,
    );
    final needed = actualRows * maxPreset.height +
        (actualRows - 1) * _appearDisappearRowGap(maxPreset.height);
    return (
      height: maxPreset.height,
      fontSize: maxFontSize,
      rows: actualRows,
      shortfallHeight: max(0.0, needed - availableHeight),
    );
  }

  Widget _buildTile(
    int index, {
    required double fontSize,
    required double minHeight,
    required double maxHeight,
  }) {
    final metrics = _appearDisappearCellMetrics(minHeight);
    final word = _shuffledChoices[index];
    final disabled = _failed ||
        _completed ||
        !_interactionEnabled ||
        _correctGridIndices.contains(index);
    final isWrong = _failed && _wrongGridIndex == index;
    final isCorrectTile = _correctGridIndices.contains(index);
    final orderLabel = _gridIndexToStep[index];

    final Color bg;
    final Color border;
    final Color fg;
    if (isWrong) {
      bg = AnswerPalette.wrongBg;
      border = AnswerPalette.wrongBorder;
      fg = AnswerPalette.wrongFg;
    } else if (isCorrectTile) {
      bg = _translationPenalized
          ? AnswerPalette.revealedBg
          : AnswerPalette.correctBg;
      border = _translationPenalized
          ? AnswerPalette.revealedBorder
          : AnswerPalette.correctBorder;
      fg = _translationPenalized
          ? AnswerPalette.revealedFg
          : AnswerPalette.correctFg;
    } else {
      bg = AnswerPalette.neutralBg;
      border = AnswerPalette.neutralBorder;
      fg = AnswerPalette.neutralFg;
    }

    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border)),
      key: _tileKeys[index],
      child: InkWell(
        onTap: disabled ? null : () => _onGridTap(index),
        customBorder: StadiumBorder(side: BorderSide(color: border)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: metrics.minWidth,
            minHeight: minHeight,
            maxHeight: maxHeight,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding / 2,
                  vertical: metrics.horizontalPadding * 0.35,
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
                          fontFamily: 'Inter',
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCorrectTile && orderLabel != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: border,
                    child: Text(
                      '$orderLabel',
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

  String? _lastLayoutLogKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasLine1 = widget.data.line1 != null;
    final hasImage = widget.imagePath != null;
    final budget = QuestionLayoutBudget.of(context);
    final answerWidth =
        budget.answerWidthForAvailable(MediaQuery.sizeOf(context).width);

    return LayoutBuilder(
      builder: (context, bodyConstraints) {
        final mediaWidthLimit =
            budget.mediaWidthForAvailable(bodyConstraints.maxWidth);
        final mediaHeight = hasImage
            ? min(mediaWidthLimit,
                budget.mediaHeightForAvailable(bodyConstraints.maxHeight))
            : 0.0;
        final remainderHeight =
            max(0.0, bodyConstraints.maxHeight - mediaHeight);

        final promptHeight = hasLine1
            ? remainderHeight * _appearDisappearPromptShare[budget.tier]!
            : 0.0;
        final slotHeight = hasLine1
            ? remainderHeight * _appearDisappearSlotShare[budget.tier]!
            : remainderHeight * 0.38;
        final tileBankHeight = hasLine1
            ? remainderHeight * _appearDisappearTileBankShare[budget.tier]!
            : remainderHeight * 0.62;

        final promptPreset = _appearDisappearPromptPresets[budget.tier]!;
        final promptWrapWidth = answerWidth -
            (widget.audio1Path != null || widget.audio2Path != null ? 56 : 0);
        final promptTextBudget = max(
          0.0,
          promptHeight -
              promptPreset.cardPaddingTop -
              promptPreset.cardPaddingBottom,
        );

        // Determine what each slot currently displays: the answer during the reveal window
        // (see `_runRevealSequence`/`_revealAnswer`), nothing while clearing, and whatever the
        // player has tapped so far once interaction begins.
        final displaySlots = List.generate(_sentence.length, (i) {
          if (_phase == _Phase.interaction) return _interactionSlots[i];
          return _revealAnswer ? _sentence[i] : null;
        });

        final tilePreset = _resolvePreset(
          items: List<String?>.generate(
              _shuffledChoices.length, (i) => _shuffledChoices[i]),
          presets: _appearDisappearTilePresets[budget.tier]!,
          availableWidth: answerWidth - 32,
          availableHeight: max(0.0, tileBankHeight - 8.0),
          fontWeight: FontWeight.w600,
        );
        // Slot and dialog text render at the exact same size as the resolved tile font
        // (developer-directed parity with `SentenceBuilder`: tiles, slots, and dialog all
        // share one text size, only dialog is bold). Slot keeps its own height ladder (chrome
        // height can legitimately differ) and non-bold weight (`w600`, matching tiles).
        final slotPreset = _resolvePreset(
          items: displaySlots,
          presets: _appearDisappearSlotPresets[budget.tier]!,
          availableWidth: answerWidth - 24,
          availableHeight: max(0.0, slotHeight - 8.0),
          fontWeight: FontWeight.w600,
          fontSizeOverride: tilePreset.fontSize,
        );
        final emptySlotWidth =
            _appearDisappearCellMetrics(slotPreset.height).minWidth;

        final tileFontSize = tilePreset.fontSize;
        final slotFontSize = slotPreset.fontSize;
        // Dialog/prompt text renders at the exact same size as tiles/slots (developer ask:
        // all three share one text size, only dialog is bold).
        final dialogFontSize = tileFontSize;

        final promptNeeded = hasLine1
            ? _promptNeededHeight(
                dialogFontSize, promptWrapWidth, widget.data.line1!)
            : 0.0;
        final shortfallPrompt =
            hasLine1 ? max(0.0, promptNeeded - promptTextBudget) : 0.0;
        final shortfallSlots = slotPreset.shortfallHeight;
        final shortfallTiles = tilePreset.shortfallHeight;

        // Media is always rendered at its full, fixed `mediaHeight` — never shrunk. Whichever
        // of prompt/slots/tiles needs more room than its nominal box borrows it from media: the
        // prompt card (the box adjacent to media) grows to cover the borrowed amount, painted
        // on top of the still-full-height media; downstream slot/tile boxes get their own extra
        // room from the space freed in the Column. Extension is capped at the full media height
        // — how much ends up covered is a content-authoring concern, not a hard code floor.
        final totalShortfall =
            shortfallPrompt + shortfallSlots + shortfallTiles;
        final extensionCap = hasImage ? mediaHeight : 0.0;
        final totalExtension = min(totalShortfall, extensionCap);
        final mediaVisibleHeight =
            hasImage ? mediaHeight - totalExtension : 0.0;
        final promptCardHeight = promptHeight + shortfallPrompt;
        final slotHeightFinal = slotHeight + shortfallSlots;
        final tileBankHeightFinal = tileBankHeight + shortfallTiles;

        final layoutLogKey = [
          bodyConstraints.maxWidth,
          bodyConstraints.maxHeight,
          mediaHeight,
          promptHeight,
          shortfallPrompt,
          slotHeightFinal,
          tileBankHeightFinal,
          tileFontSize,
          slotFontSize,
          _phase,
          budget.tier,
        ].join('|');

        if (_lastLayoutLogKey != layoutLogKey) {
          _lastLayoutLogKey = layoutLogKey;
          debugPrint(
            '[QuestionLayout][AppearDisappear] '
            'tier=${budget.tier.name} '
            'localBody=${bodyConstraints.maxWidth.toStringAsFixed(1)}x'
            '${bodyConstraints.maxHeight.toStringAsFixed(1)}px '
            'media=${mediaWidthLimit.toStringAsFixed(1)}x'
            '${mediaVisibleHeight.toStringAsFixed(1)}px '
            'promptBox=${answerWidth.toStringAsFixed(1)}x'
            '${promptCardHeight.toStringAsFixed(1)}px '
            'promptShortfall=${shortfallPrompt.toStringAsFixed(1)}px '
            'slotBox=${answerWidth.toStringAsFixed(1)}x'
            '${slotHeightFinal.toStringAsFixed(1)}px slotRows=${slotPreset.rows} '
            'tileBox=${answerWidth.toStringAsFixed(1)}x'
            '${tileBankHeightFinal.toStringAsFixed(1)}px tileRows=${tilePreset.rows} '
            'tileText=${tileFontSize.toStringAsFixed(1)}px '
            'slotText=${slotFontSize.toStringAsFixed(1)}px '
            'hasLine1=$hasLine1 image=$hasImage phase=$_phase',
          );
          if (shortfallSlots > 0 || shortfallTiles > 0 || shortfallPrompt > 0) {
            debugPrint(
              '[QuestionLayout][AppearDisappear][Warning] content exceeded its normal row cap '
              '(slotRows=${slotPreset.rows}/2 tileRows=${tilePreset.rows}/3) — consider '
              'shortening this question; cascade extension is absorbing '
              '${totalExtension.toStringAsFixed(1)}px.',
            );
          }
          if (totalShortfall > extensionCap) {
            debugPrint(
              '[QuestionLayout][AppearDisappear][Severe] shortfall '
              '(${totalShortfall.toStringAsFixed(1)}px) exceeds available media extension '
              '(${extensionCap.toStringAsFixed(1)}px) — this question needs shortening, the '
              'answer area will scroll.',
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasImage || hasLine1)
              SizedBox(
                height: mediaVisibleHeight + promptCardHeight,
                child: Stack(
                  clipBehavior: Clip.none,
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
                    if (hasLine1)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: promptCardHeight,
                        child: DebugLayoutBox(
                          enabled: widget.debugShowLayoutBounds,
                          label: 'prompt',
                          color: Colors.orange,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: hasImage
                                  ? const BorderRadius.vertical(
                                      top: Radius.circular(24))
                                  : null,
                            ),
                            padding: EdgeInsets.fromLTRB(
                              16,
                              promptPreset.cardPaddingTop,
                              16,
                              promptPreset.cardPaddingBottom,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: answerWidth,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.data.line1!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: const Color(0xFF171A1F),
                                          fontWeight: FontWeight.w700,
                                          fontSize: dialogFontSize,
                                        ),
                                      ),
                                    ),
                                    if (widget.audio1Path != null ||
                                        widget.audio2Path != null) ...[
                                      const SizedBox(width: 8),
                                      AudioPlayButton(
                                        isPlaying:
                                            _audio1Playing || _audio2Playing,
                                        onPressed: _audio1Playing
                                            ? null
                                            : (_failed || _completed)
                                                ? () => _playAudio2()
                                                : () => _playAudio1(),
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
                label: 'slot+tileBank',
                color: Colors.teal,
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: SizedBox(
                      width: answerWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Slot row: answer blanks, filled during recall (or shown directly
                          // during the reveal phase).
                          SizedBox(
                            height: slotHeightFinal,
                            child: Center(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 6,
                                    runSpacing: _appearDisappearRowGap(
                                        slotPreset.height),
                                    children:
                                        List.generate(_sentence.length, (i) {
                                      final word = displaySlots[i];
                                      final fromPlayer =
                                          i < _slotFromPlayer.length &&
                                              _slotFromPlayer[i];
                                      final isReveal = _revealAnswer;

                                      final slot = AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        height: slotPreset.height,
                                        width: word == null
                                            ? emptySlotWidth
                                            : null,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: (isReveal || fromPlayer)
                                                  ? AnswerPalette.correctBorder
                                                  : cs.outline,
                                              width: (isReveal || fromPlayer)
                                                  ? 2.5
                                                  : 1.5,
                                            ),
                                          ),
                                        ),
                                        child: Center(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 160),
                                            child: word == null
                                                ? const SizedBox.shrink()
                                                : Text(
                                                    word,
                                                    key: ValueKey(word),
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: slotFontSize,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          isReveal || fromPlayer
                                                              ? AnswerPalette
                                                                  .correctFg
                                                              : null,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      );
                                      // Empty slots get an explicit fixed width via
                                      // `AnimatedContainer.width`. Filled slots leave width
                                      // unset so the `Center` child would otherwise expand to
                                      // fill the full row (Wrap offers loose max-width
                                      // constraints) — `IntrinsicWidth` forces it to hug the
                                      // real text instead, same fix `SentenceBuilder` uses for
                                      // this exact shape of Wrap-cell sizing.
                                      return word == null
                                          ? slot
                                          : IntrinsicWidth(child: slot);
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Tile bank: shuffled words + distractors, tapped in recall order.
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: _appearDisappearRowGap(
                                        tilePreset.height),
                                    runSpacing: _appearDisappearRowGap(
                                        tilePreset.height),
                                    children: List.generate(
                                      _shuffledChoices.length,
                                      (i) => _buildTile(
                                        i,
                                        fontSize: tileFontSize,
                                        minHeight: tilePreset.height,
                                        maxHeight: tilePreset.height,
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
