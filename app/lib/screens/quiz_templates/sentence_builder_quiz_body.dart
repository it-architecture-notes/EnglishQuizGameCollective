import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../services/question_layout_budget.dart';
import '../../widgets/answer_palette.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/debug_layout_box.dart';
import '../../widgets/standard_question_media.dart';

/// Remainder height fraction dedicated to the prompt bubble area (`line1 != null`). Flat 24%
/// on every tier (developer-directed) — was previously tier-varying (18%-26%); now derived as
/// the 100% remainder after the slot/tile-bank flat shares below.
const Map<QuestionLayoutTier, double> _sentenceBuilderPromptShare = {
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

/// Remainder height fraction dedicated to the Sentence Assembly Slot Area (`line1 != null`).
/// Flat 30% on every tier (developer-directed) — was previously tier-varying (25%-28%).
const Map<QuestionLayoutTier, double> _sentenceBuilderSlotShare = {
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

/// Remainder height fraction dedicated to the Word Tile Choice Bank (`line1 != null`).
/// Flat 46% on every tier (developer-directed) — was previously tier-varying (49%-54%).
const Map<QuestionLayoutTier, double> _sentenceBuilderTileBankShare = {
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

typedef _RowPreset = ({double height, double fontSize});

/// Discrete tile presets keyed by row count (index 0 = 1 row, 1 = 2 rows, 2 = 3 rows — the
/// agreed max before a question is considered content-design debt). Height is pinned to the
/// 44px touch-target floor only at 3 rows; 1-row/2-row get real headroom that scales with each
/// tier's actual available tile-bank budget (verified against `QuestionLayoutBudget` real
/// per-tier remainder heights, not guessed) — tablets get meaningfully larger, comfortable
/// tiles instead of settling for the phone-safe size.
const Map<QuestionLayoutTier, List<_RowPreset>> _sentenceBuilderTilePresets = {
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
/// Slots aren't independently tappable (just display targets the learner fills by tapping
/// tiles), so they don't share the 44px touch-target floor the way tiles do; heights scale
/// down further than tiles on compact phones.
const Map<QuestionLayoutTier, List<_RowPreset>> _sentenceBuilderSlotPresets = {
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

/// Row gap as a percentage of the currently active row height, not a flat px constant — so
/// spacing scales with element size the same way height/font do, instead of a tiny gap looking
/// lost between large tablet tiles or a relatively huge gap cramping small phone tiles.
double _sentenceBuilderRowGap(double rowHeight) =>
    (rowHeight * 0.15).roundToDouble();

/// Cell horizontal padding and minimum width, derived from the active row height — same
/// reasoning as the gap: a smaller preset (more rows) needs proportionally tighter padding and
/// a smaller minimum width, or shrinking the font/height for more rows achieves nothing (the
/// cells still can't pack any more densely per row than the largest preset did). This is used
/// identically for measurement (`_resolvePreset`) and for the real rendered cell (`_buildTile`)
/// — the two must never diverge, that mismatch was the root cause of an earlier session bug.
({double minWidth, double horizontalPadding}) _sentenceBuilderCellMetrics(
    double height) {
  return (minWidth: height * 1.3, horizontalPadding: height * 0.5);
}

/// Result of resolving a component (tiles or slots) against its discrete preset ladder: which
/// preset applies, and how many extra px of height the live content still needs beyond what the
/// nominal box real provides (0 unless the real measured content doesn't fit — either because
/// it exceeded the ladder's row cap, or because real chrome left less room than assumed — in
/// which case the size stays frozen at the resolved preset and the box grows instead, the
/// cascade-extension case).
typedef _PresetResolution = ({
  double height,
  double fontSize,
  int rows,
  double shortfallHeight,
});

/// Sentence tokens only, shuffled on tiles; tap in [SentenceBuilderQuestionData.correctOrder].
/// Uses a random permutation of sentence positions so duplicate words are unambiguous.
class SentenceBuilderQuizBody extends StatefulWidget {
  const SentenceBuilderQuizBody({
    super.key,
    required this.data,
    required this.strings,
    required this.userLanguage,
    this.imagePath,
    this.enterAudioCue,
    this.exitCorrectAudioCue,
    this.exitWrongAudioCue,
    required this.onPlayQuestionAudio,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
    this.onUserInteracted,
    this.onNextTileRendered,
    this.debugShowLayoutBounds = false,
  });

  final SentenceBuilderQuestionData data;
  final Map<String, String> strings;
  final String userLanguage;
  final String? imagePath;

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

  /// Fired on the very first interaction with this question (tile tap, translation reveal, or
  /// audio icon press) — used to hide the footer guide hint.
  final VoidCallback? onUserInteracted;
  final void Function(int expectedIndex, List<GlobalKey> tileKeys)?
      onNextTileRendered;

  @override
  State<SentenceBuilderQuizBody> createState() =>
      _SentenceBuilderQuizBodyState();
}

class _SentenceBuilderQuizBodyState extends State<SentenceBuilderQuizBody> {
  /// Random permutation of `0..n-1`: cell `i` shows sentence token at index [_perm[i]].
  late List<int> _perm;
  final Set<int> _usedCellIndices = {};

  late List<String> _sentence;

  int _tapProgress = 0;
  final List<String?> _slots = [];
  final List<bool> _slotFromPlayer = [];
  bool _failed = false;
  bool _translationPenalized = false;
  int? _wrongGridIndex;
  final Map<int, int> _cellToStep = {};
  late final List<GlobalKey> _tileKeys;
  bool _completed = false;
  bool _audioPlaying = false;
  bool _audio1Playing = false;
  bool _audio1Scheduled = false;
  bool _setupAudioComplete = true;

  List<String> get _target => widget.data.correctOrder;

  bool get _isAnswered => _failed || _completed;

  /// What the audio icon plays right now: [enterAudioCue] before answering, the
  /// (already-effective) [exitWrongAudioCue] once answered wrong, nothing once answered
  /// correctly (the question is about to advance).
  List<String>? get _manualAudioCue =>
      !_isAnswered ? widget.enterAudioCue : (_failed ? widget.exitWrongAudioCue : null);

  bool get _hasManualAudio {
    final cue = _manualAudioCue;
    return cue != null && cue.isNotEmpty;
  }

  /// True if the audio icon could ever be relevant for this question (enter pre-answer, or
  /// exit-wrong post-wrong) — used to reserve layout space regardless of the current phase.
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
    if (widget.enterAudioCue != null && widget.enterAudioCue!.isNotEmpty) {
      _setupAudioComplete = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _primeAudio1());
    }
    _sentence = List<String>.from(_target);
    final n = _sentence.length;
    _tileKeys = List.generate(n, (_) => GlobalKey());
    _perm = List.generate(n, (i) => i)..shuffle(Random());
    if (n > 1) {
      var guard = 0;
      while (_isIdentityPerm(_perm) && guard < 40) {
        _perm.shuffle(Random());
        guard++;
      }
    }
    for (var i = 0; i < _sentence.length; i++) {
      _slots.add(null);
      _slotFromPlayer.add(false);
    }
    _reportNextTile();
  }

  void _reportNextTile() {
    if (_tapProgress >= _sentence.length || _failed || _completed) {
      return;
    }
    final expectedIndex = _perm.indexOf(_tapProgress);
    if (expectedIndex < 0 || expectedIndex >= _tileKeys.length) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onNextTileRendered?.call(expectedIndex, _tileKeys);
      }
    });
  }

  bool _isIdentityPerm(List<int> p) {
    for (var i = 0; i < p.length; i++) {
      if (p[i] != i) return false;
    }
    return true;
  }

  String _wordAtCell(int cellIndex) => _sentence[_perm[cellIndex]];

  Future<void> _onTranslationRevealed() async {
    if (_failed || _completed || widget.data.trOk) return;
    widget.onUserInteracted?.call();
    setState(() {
      _failed = true;
      _translationPenalized = true;
      _wrongGridIndex = null;
      for (var pos = _tapProgress; pos < _sentence.length; pos++) {
        for (var cell = 0; cell < _perm.length; cell++) {
          if (_perm[cell] == pos && !_usedCellIndices.contains(cell)) {
            _usedCellIndices.add(cell);
            _slots[pos] = _sentence[pos];
            _slotFromPlayer[pos] = false;
            _cellToStep[cell] = pos + 1;
            break;
          }
        }
      }
      _tapProgress = _sentence.length;
    });
    widget.onPlayWrong();
    widget.onOutcome(false);
  }

  Future<void> _onGridTap(int cellIndex) async {
    if (_completed || _failed || _usedCellIndices.contains(cellIndex)) return;
    widget.onUserInteracted?.call();
    final sentencePos = _perm[cellIndex];
    final expectedPos = _tapProgress;
    if (sentencePos == expectedPos) {
      setState(() {
        _slots[_tapProgress] = _sentence[expectedPos];
        _slotFromPlayer[_tapProgress] = true;
        _usedCellIndices.add(cellIndex);
        _cellToStep[cellIndex] = _tapProgress + 1;
        _tapProgress++;
        if (_tapProgress >= _sentence.length) {
          _completed = true;
        }
      });
      _reportNextTile();
      if (_tapProgress >= _sentence.length) {
        widget.onPlayCorrect();
        await _playOutcomeAudio();
        if (!mounted) return;
        widget.onOutcome(true);
      }
    } else {
      setState(() {
        _failed = true;
        _wrongGridIndex = cellIndex;
        for (var i = _tapProgress; i < _sentence.length; i++) {
          _slots[i] = _sentence[i];
          _slotFromPlayer[i] = false;
          // Mark expected step badges on remaining unplaced tiles
          for (var cell = 0; cell < _perm.length; cell++) {
            if (_perm[cell] == i && !_usedCellIndices.contains(cell)) {
              _cellToStep[cell] = i + 1;
              break;
            }
          }
        }
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
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

  double _promptNeededHeight(
    double fontSize,
    double maxWidth,
    String text,
  ) {
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
  /// **real live content** — the actual `_perm`-ordered tiles or the actual current `_slots`
  /// state — at each preset's real font size, stepping up the ladder until the content fits
  /// within that preset's row cap. This replaces the old shuffle-safe worst-case estimate: that
  /// was needed when the box was a *fixed* size the content had to be forced into (so a
  /// different shuffle order could need more rows than a fixed box allowed, causing scroll).
  /// Now the box adapts to whatever row count the live content actually needs (discrete preset
  /// up to the cap, then cascade extension beyond it), so measuring the exact live order is
  /// correct, not risky — there's no fixed target for a different order to overflow.
  ///
  /// `availableHeight` is the component's real content-area height (nominal box height minus
  /// its own chrome — outer padding etc. — not just the raw per-tier percentage). The shortfall
  /// is computed directly from real measured rows against that real height, rather than trusted
  /// to match hand-derived preset numbers exactly — a preset can be *within* its row cap and
  /// still need a few px of cascade extension if real chrome eats into the nominal box more
  /// than assumed; this reports that correctly instead of silently scrolling.
  /// [fontSizeOverride], when given, is measured (and returned) in place of each preset's own
  /// `fontSize` — used by the slot resolver so slot text renders at the exact same size as the
  /// resolved tile font instead of its own independent size ladder. The preset's `height`
  /// column is still used unmodified (slot/tile chrome heights can legitimately differ), only
  /// the font dimension is unified.
  _PresetResolution _resolvePreset({
    required List<String?> items,
    required List<_RowPreset> presets,
    required double availableWidth,
    required double availableHeight,
    required FontWeight fontWeight,
    double? fontSizeOverride,
    double? fixedHeight,
    double? fixedFontSize,
  }) {
    if (fixedHeight != null && fixedFontSize != null) {
      final metrics = _sentenceBuilderCellMetrics(fixedHeight);
      final rows = _estimateWrapRows(
        items: items,
        availableWidth: availableWidth,
        spacing: _sentenceBuilderRowGap(fixedHeight),
        minItemWidth: metrics.minWidth,
        horizontalPadding: metrics.horizontalPadding,
        fontSize: fixedFontSize,
        fontWeight: fontWeight,
      );
      final needed = rows * fixedHeight +
          (rows - 1) * _sentenceBuilderRowGap(fixedHeight);
      return (
        height: fixedHeight,
        fontSize: fixedFontSize,
        rows: rows,
        shortfallHeight: max(0.0, needed - availableHeight),
      );
    }
    for (var i = 0; i < presets.length; i++) {
      final preset = presets[i];
      final fontSize = fontSizeOverride ?? preset.fontSize;
      final metrics = _sentenceBuilderCellMetrics(preset.height);
      final rows = _estimateWrapRows(
        items: items,
        availableWidth: availableWidth,
        spacing: _sentenceBuilderRowGap(preset.height),
        minItemWidth: metrics.minWidth,
        horizontalPadding: metrics.horizontalPadding,
        fontSize: fontSize,
        fontWeight: fontWeight,
      );
      if (rows <= i + 1) {
        final needed = rows * preset.height +
            (rows - 1) * _sentenceBuilderRowGap(preset.height);
        return (
          height: preset.height,
          fontSize: fontSize,
          rows: rows,
          shortfallHeight: max(0.0, needed - availableHeight),
        );
      }
    }
    // Exceeded the ladder's row cap entirely: freeze at the last (smallest) preset.
    final maxPreset = presets.last;
    final maxFontSize = fontSizeOverride ?? maxPreset.fontSize;
    final maxMetrics = _sentenceBuilderCellMetrics(maxPreset.height);
    final actualRows = _estimateWrapRows(
      items: items,
      availableWidth: availableWidth,
      spacing: _sentenceBuilderRowGap(maxPreset.height),
      minItemWidth: maxMetrics.minWidth,
      horizontalPadding: maxMetrics.horizontalPadding,
      fontSize: maxFontSize,
      fontWeight: fontWeight,
    );
    final needed = actualRows * maxPreset.height +
        (actualRows - 1) * _sentenceBuilderRowGap(maxPreset.height);
    return (
      height: maxPreset.height,
      fontSize: maxFontSize,
      rows: actualRows,
      shortfallHeight: max(0.0, needed - availableHeight),
    );
  }

  Widget _buildBubble({
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = colorScheme.surfaceContainerHighest;
    final borderColor = colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(12),
        ),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: child,
    );
  }

  Widget _buildTile(
    int index, {
    required double fontSize,
    required double minHeight,
    required double maxHeight,
  }) {
    final metrics = _sentenceBuilderCellMetrics(minHeight);
    final word = _wordAtCell(index);
    final disabled = _failed ||
        _completed ||
        _usedCellIndices.contains(index) ||
        !_setupAudioComplete ||
        _audioPlaying ||
        _audio1Playing;
    final isWrong = _failed && _wrongGridIndex == index;
    final step = _cellToStep[index];
    final tapped = _usedCellIndices.contains(index);

    final Color bg;
    final Color border;
    final Color fg;

    if (isWrong) {
      bg = AnswerPalette.wrongBg;
      border = AnswerPalette.wrongBorder;
      fg = AnswerPalette.wrongFg;
    } else if (tapped) {
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
                // `metrics.horizontalPadding` is the *total* (both sides) added to text width
                // in the measurement pass — halve it here since `symmetric` applies per side,
                // so measurement and render agree on the same real footprint.
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
              if (step != null && step > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: border,
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

  void revealTranslation() => _onTranslationRevealed();

  String? _lastLayoutLogKey;

  @override
  Widget build(BuildContext context) {
    final hasLine1 = widget.data.line1 != null;
    final hasImage = widget.imagePath != null;
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

        final promptHeight = hasLine1
            ? remainderHeight * _sentenceBuilderPromptShare[budget.tier]!
            : 0.0;
        final slotHeight = hasLine1
            ? remainderHeight * _sentenceBuilderSlotShare[budget.tier]!
            : remainderHeight * 0.38;
        final tileBankHeight = hasLine1
            ? remainderHeight * _sentenceBuilderTileBankShare[budget.tier]!
            : remainderHeight * 0.62;

        // Prompt sizing. The prompt card's own Container below has 16px left/right padding
        // (unlike the slot/tile boxes, which have none), so the real width available inside it
        // is 32px narrower than `answerWidth` — every prompt-side width/wrap calculation must
        // go through this, or the wrap estimate silently assumes more room than the prompt text
        // actually renders into, under-counting wrapped lines and letting real content overflow.
        final promptCardContentWidth = max(0.0, answerWidth - 32);
        final promptWrapWidth =
            promptCardContentWidth - (_hasAnyAudioIcon ? 56 : 0);
        final promptTextBudget = max(0.0, promptHeight - 28.0);

        // Resolve tiles from their fixed question geometry. Resolve slots from the complete
        // target sentence rather than the currently filled values so a short answer cannot
        // collapse the slot group and move the tile bank during a tap.
        // Real content-area height: nominal box minus the Wrap's own outer padding (`vertical:
        // 4` on each side = 8px), so the shortfall check compares against what's actually left
        // for rows, not the full nominal box.
        // `tablet4to3` only: developer-directed prototype trying a fill-the-box, continuous
        // font-percentage ladder instead of the fixed 3-entry table every other tier still
        // uses below. Scoped narrowly so this experiment can't affect any other device tier.
        final tilePreset = _resolvePreset(
          items: List<String?>.generate(_perm.length, (i) => _wordAtCell(i)),
          presets: _sentenceBuilderTilePresets[budget.tier]!,
          availableWidth: answerWidth - 32,
          availableHeight: max(0.0, tileBankHeight - 8.0),
          fontWeight: FontWeight.w600,
          fixedHeight: questionTileHeightFor(budget),
          fixedFontSize: questionTileTextSizeFor(budget.tier),
        );
        final tileFontSize = tilePreset.fontSize;

        // Slot dimensions and text use the shared device metric, independent of row count.
        final slotPreset = _resolvePreset(
          items: List<String?>.from(_sentence),
          presets: _sentenceBuilderSlotPresets[budget.tier]!,
          availableWidth: answerWidth - 24,
          availableHeight: max(0.0, slotHeight - 8.0),
          fontWeight: FontWeight.w600,
          fixedHeight: questionSlotHeightFor(budget),
          fixedFontSize: questionSlotTextSizeFor(budget.tier),
        );
        // Same formula used for measurement and render, at the preset that actually resolved
        // (not the ladder's first rung) — an empty-slot placeholder for whichever preset won.
        final emptySlotWidth =
            _sentenceBuilderCellMetrics(slotPreset.height).minWidth;

        final slotFontSize = slotPreset.fontSize;

        final dialogFontSize = questionSentenceTextSizeFor(budget.tier);
        final promptNeeded = hasLine1
            ? _promptNeededHeight(
                dialogFontSize, promptWrapWidth, widget.data.line1!)
            : 0.0;
        final shortfallPrompt =
            hasLine1 ? max(0.0, promptNeeded - promptTextBudget) : 0.0;

        final shortfallSlots = slotPreset.shortfallHeight;
        final shortfallTiles = tilePreset.shortfallHeight;

        // Cascading extension: whichever of prompt/slots/tiles needs more room than its
        // nominal box borrows it from media. Media is always rendered at its full, fixed
        // `mediaHeight` — it is never shrunk. The prompt card (the box actually adjacent to
        // media in the Stack) grows to cover the borrowed amount instead, painted on top of
        // the still-full-height media; downstream slot/tile boxes get their own extra room
        // from the space freed in the Column. Extension is only capped at the full media
        // height (it can be covered up to 100% if content genuinely needs it) — how much of
        // the media ends up covered is a content-authoring concern, not a hard code floor.
        final totalShortfall =
            shortfallPrompt + shortfallSlots + shortfallTiles;
        final extensionCap = hasImage ? mediaHeight : 0.0;
        final totalExtension = min(totalShortfall, extensionCap);
        // Accounting height only — how much of the container's reserved space is *not*
        // covered by the prompt card. The media widget itself always renders at the full
        // `mediaHeight` regardless of this value.
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
          dialogFontSize,
          tileFontSize,
          slotFontSize,
          budget.tier,
        ].join('|');

        if (_lastLayoutLogKey != layoutLogKey) {
          _lastLayoutLogKey = layoutLogKey;
          debugPrint(
            '[QuestionLayout][SentenceBuilder] '
            'tier=${budget.tier.name} '
            'localBody=${bodyConstraints.maxWidth.toStringAsFixed(1)}x'
            '${bodyConstraints.maxHeight.toStringAsFixed(1)}px '
            'media=${mediaWidthLimit.toStringAsFixed(1)}x'
            '${mediaVisibleHeight.toStringAsFixed(1)}px '
            'promptBox=${answerWidth.toStringAsFixed(1)}x'
            '${promptHeight.toStringAsFixed(1)}px '
            'promptCardContentWidth=${promptCardContentWidth.toStringAsFixed(1)}px '
            'promptShortfall=${shortfallPrompt.toStringAsFixed(1)}px '
            'slotBox=${answerWidth.toStringAsFixed(1)}x'
            '${slotHeightFinal.toStringAsFixed(1)}px slotRows=${slotPreset.rows} '
            'tileBox=${answerWidth.toStringAsFixed(1)}x'
            '${tileBankHeightFinal.toStringAsFixed(1)}px tileRows=${tilePreset.rows} '
            'promptText=${dialogFontSize.toStringAsFixed(1)}px '
            'tileText=${tileFontSize.toStringAsFixed(1)}px '
            'slotText=${slotFontSize.toStringAsFixed(1)}px '
            'hasLine1=$hasLine1 '
            'image=$hasImage',
          );
          // Content-authoring signal: the design's row caps (3 tiles / 2 slots) are meant to be
          // a ceiling real questions never reach — this fires whenever content needed the
          // cascade at all, so it shows up during content review rather than only when someone
          // happens to notice the answer area looks cramped.
          if (shortfallSlots > 0 || shortfallTiles > 0) {
            debugPrint(
              '[QuestionLayout][SentenceBuilder][Warning] content exceeded its normal row cap '
              '(slotRows=${slotPreset.rows}/2 tileRows=${tilePreset.rows}/3) — consider '
              'shortening this question; cascade extension is absorbing '
              '${(shortfallSlots + shortfallTiles).toStringAsFixed(1)}px.',
            );
          }
          // Severe case: even the cascade couldn't fully absorb the shortfall (media exhausted
          // down to its safety floor) — this is the one case where the answer area's own
          // last-resort scroll can still engage. Should be rare-to-never with real content.
          if (totalShortfall > extensionCap) {
            debugPrint(
              '[QuestionLayout][SentenceBuilder][Warning] shortfall '
              '(${totalShortfall.toStringAsFixed(1)}px) exceeds available media extension '
              '(${extensionCap.toStringAsFixed(1)}px) — this question needs shortening, the '
              'answer area will scroll.',
            );
          }
        }

        final promptStyle = TextStyle(
          color: const Color(0xFF171A1F),
          fontWeight: FontWeight.w700,
          fontSize: dialogFontSize,
          height: 1.2,
          fontFamily: 'Inter',
        );

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
                        // Media always renders at its full, fixed `mediaHeight` — never
                        // shrunk. When the prompt card below grows past its nominal size,
                        // this container is shorter than `mediaHeight + promptCardHeight`,
                        // so the card (painted after media, on top) covers the bottom
                        // portion of the media rather than the media itself shrinking.
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
                              hasImage ? 18.0 : 14.0,
                              16,
                              8,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: promptCardContentWidth,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (_hasAnyAudioIcon) ...[
                                        AudioPlayButton(
                                          isPlaying: _audio1Playing,
                                          onPressed: _hasManualAudio
                                              ? () => _replayAudio1()
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Flexible(
                                        child: _buildBubble(
                                          child: Text(
                                            widget.data.line1!,
                                            style: promptStyle,
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
                      ),
                  ],
                ),
              ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: SizedBox(
                    width: answerWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Zone 2: Sentence Assembly Slot Area (Target Bank)
                        SizedBox(
                          height: slotHeightFinal,
                          child: DebugLayoutBox(
                            enabled: widget.debugShowLayoutBounds,
                            label: 'slot',
                            color: Colors.teal,
                            child: Center(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: _sentenceBuilderRowGap(
                                        slotPreset.height),
                                    runSpacing: _sentenceBuilderRowGap(
                                        slotPreset.height),
                                    children:
                                        List.generate(_sentence.length, (i) {
                                      final word = _slots[i];
                                      final fromPlayer =
                                          i < _slotFromPlayer.length &&
                                              _slotFromPlayer[i];
                                      final slotMetrics =
                                          _sentenceBuilderCellMetrics(
                                              slotPreset.height);
                                      final slot = AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        width: word == null
                                            ? emptySlotWidth
                                            : null,
                                        height: slotPreset.height,
                                        padding: EdgeInsets.symmetric(
                                            horizontal:
                                                slotMetrics.horizontalPadding /
                                                    2,
                                            vertical: 4),
                                        decoration: BoxDecoration(
                                          color: word != null
                                              ? (_translationPenalized
                                                  ? AnswerPalette.revealedBg
                                                  : AnswerPalette.correctBg)
                                              : Colors.white,
                                          border: Border.all(
                                            color: word != null
                                                ? (_translationPenalized
                                                    ? AnswerPalette
                                                        .revealedBorder
                                                    : AnswerPalette
                                                        .correctBorder)
                                                : AnswerPalette.neutralBorder,
                                            width: 1.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        child: Center(
                                          child: word == null
                                              ? const SizedBox(
                                                  width: 36,
                                                  height: 12,
                                                )
                                              : Text(
                                                  word,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: slotFontSize,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: fromPlayer
                                                        ? null
                                                        : FontStyle.italic,
                                                    color: _translationPenalized
                                                        ? AnswerPalette
                                                            .revealedFg
                                                        : AnswerPalette
                                                            .correctFg,
                                                  ),
                                                ),
                                        ),
                                      );
                                      return word == null
                                          ? slot
                                          : IntrinsicWidth(child: slot);
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Zone 3: Word Tile Choice Bank (Scrambled Source)
                        Expanded(
                          child: DebugLayoutBox(
                            enabled: widget.debugShowLayoutBounds,
                            label: 'tileBank',
                            color: Colors.green,
                            child: Center(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: _sentenceBuilderRowGap(
                                        tilePreset.height),
                                    runSpacing: _sentenceBuilderRowGap(
                                        tilePreset.height),
                                    children: List.generate(
                                      _perm.length,
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
                        ),
                      ],
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
