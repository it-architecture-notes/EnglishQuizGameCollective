import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../models/level_config.dart';
import '../../services/question_layout_budget.dart';
import '../../widgets/answer_palette.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/debug_layout_box.dart';
import '../../widgets/standard_question_media.dart';

/// Layout tables copied verbatim from `sentence_builder_quiz_body.dart` — this template is
/// deliberately isolated from (not shared with) the standalone `SentenceBuilder` widget, even
/// though the two are visually identical apart from the media source (frozen video vs. image).
const Map<QuestionLayoutTier, double> _pausedSentenceBuilderPromptShare = {
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

const Map<QuestionLayoutTier, double> _pausedSentenceBuilderSlotShare = {
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

const Map<QuestionLayoutTier, double> _pausedSentenceBuilderTileBankShare = {
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

const Map<QuestionLayoutTier, List<_RowPreset>> _pausedSentenceBuilderTilePresets = {
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

const Map<QuestionLayoutTier, List<_RowPreset>> _pausedSentenceBuilderSlotPresets = {
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

double _pausedSentenceBuilderRowGap(double rowHeight) =>
    (rowHeight * 0.15).roundToDouble();

({double minWidth, double horizontalPadding}) _pausedSentenceBuilderCellMetrics(
    double height) {
  return (minWidth: height * 1.3, horizontalPadding: height * 0.5);
}

typedef _PresetResolution = ({
  double height,
  double fontSize,
  int rows,
  double shortfallHeight,
});

/// `VideoConversation` answer_type `pausedSentenceBuilder`: the shared video is frozen for this
/// whole row (never played, never resumed) and used as the media in place of a static image —
/// everything else (layout, prompt, tile/slot mechanics, audio rules) matches the standalone
/// `SentenceBuilderQuizBody` exactly (unscramble only — no decoy tiles). Deliberately a separate,
/// self-contained widget rather than a variant of `SentenceBuilderQuizBody` or
/// `VideoConversationQuizBody`.
class PausedSentenceBuilderQuizBody extends StatefulWidget {
  const PausedSentenceBuilderQuizBody({
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
    this.onNextTileRendered,
    this.debugShowLayoutBounds = false,
  });

  final PausedSequenceAnswerData data;
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
  final void Function(int expectedIndex, List<GlobalKey> tileKeys)?
      onNextTileRendered;

  @override
  State<PausedSentenceBuilderQuizBody> createState() =>
      _PausedSentenceBuilderQuizBodyState();
}

class _PausedSentenceBuilderQuizBodyState
    extends State<PausedSentenceBuilderQuizBody> {
  late List<int> _perm;
  final Set<int> _usedCellIndices = {};
  late List<String> _sentence;

  int _tapProgress = 0;
  final List<String?> _slots = [];
  bool _failed = false;
  int? _wrongGridIndex;
  final Map<int, int> _cellToStep = {};
  late final List<GlobalKey> _tileKeys;
  bool _completed = false;
  bool _audioPlaying = false;
  bool _audio1Playing = false;
  bool _audio1Scheduled = false;
  bool _setupAudioComplete = true;
  bool _frameReady = false;

  List<String> get _target => widget.data.targetSentence.split(' ');

  bool get _isAnswered => _failed || _completed;

  List<String>? get _manualAudioCue =>
      !_isAnswered ? widget.enterAudioCue : (_failed ? widget.exitWrongAudioCue : null);

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
    if (widget.enterAudioCue != null && widget.enterAudioCue!.isNotEmpty) {
      _setupAudioComplete = false;
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
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachFrozenFrame();
      _primeAudio1();
    });
    _reportNextTile();
  }

  Future<void> _attachFrozenFrame() async {
    final controller = widget.controller;
    if (controller == null) return;
    try {
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }
      if (!mounted) return;
      if (controller.value.isPlaying) {
        await controller.pause();
      }
      if (!mounted) return;
      if (controller.value.position != widget.startAt) {
        await controller.seekTo(widget.startAt);
      }
      if (!mounted) return;
      setState(() => _frameReady = true);
    } catch (e) {
      debugPrint('PausedSentenceBuilderQuizBody: video failed to load: $e');
    }
  }

  void _reportNextTile() {
    if (_tapProgress >= _sentence.length || _failed || _completed) return;
    final expectedIndex = _perm.indexOf(_tapProgress);
    if (expectedIndex < 0 || expectedIndex >= _tileKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onNextTileRendered?.call(expectedIndex, _tileKeys);
    });
  }

  bool _isIdentityPerm(List<int> p) {
    for (var i = 0; i < p.length; i++) {
      if (p[i] != i) return false;
    }
    return true;
  }

  String _wordAtCell(int cellIndex) => _sentence[_perm[cellIndex]];

  Future<void> _onGridTap(int cellIndex) async {
    if (_completed || _failed || _usedCellIndices.contains(cellIndex)) return;
    widget.onUserInteracted?.call();
    final sentencePos = _perm[cellIndex];
    final expectedPos = _tapProgress;
    if (sentencePos == expectedPos) {
      setState(() {
        _slots[_tapProgress] = _sentence[expectedPos];
        _usedCellIndices.add(cellIndex);
        _cellToStep[cellIndex] = _tapProgress + 1;
        _tapProgress++;
        if (_tapProgress >= _sentence.length) _completed = true;
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
        usedWidth = usedWidth == 0 ? itemWidth : usedWidth + spacing + itemWidth;
      }
    }
    return rows;
  }

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
      final metrics = _pausedSentenceBuilderCellMetrics(fixedHeight);
      final rows = _estimateWrapRows(
        items: items,
        availableWidth: availableWidth,
        spacing: _pausedSentenceBuilderRowGap(fixedHeight),
        minItemWidth: metrics.minWidth,
        horizontalPadding: metrics.horizontalPadding,
        fontSize: fixedFontSize,
        fontWeight: fontWeight,
      );
      final needed =
          rows * fixedHeight + (rows - 1) * _pausedSentenceBuilderRowGap(fixedHeight);
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
      final metrics = _pausedSentenceBuilderCellMetrics(preset.height);
      final rows = _estimateWrapRows(
        items: items,
        availableWidth: availableWidth,
        spacing: _pausedSentenceBuilderRowGap(preset.height),
        minItemWidth: metrics.minWidth,
        horizontalPadding: metrics.horizontalPadding,
        fontSize: fontSize,
        fontWeight: fontWeight,
      );
      if (rows <= i + 1) {
        final needed = rows * preset.height +
            (rows - 1) * _pausedSentenceBuilderRowGap(preset.height);
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
    final maxMetrics = _pausedSentenceBuilderCellMetrics(maxPreset.height);
    final actualRows = _estimateWrapRows(
      items: items,
      availableWidth: availableWidth,
      spacing: _pausedSentenceBuilderRowGap(maxPreset.height),
      minItemWidth: maxMetrics.minWidth,
      horizontalPadding: maxMetrics.horizontalPadding,
      fontSize: maxFontSize,
      fontWeight: fontWeight,
    );
    final needed = actualRows * maxPreset.height +
        (actualRows - 1) * _pausedSentenceBuilderRowGap(maxPreset.height);
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
    final metrics = _pausedSentenceBuilderCellMetrics(minHeight);
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
      bg = AnswerPalette.correctBg;
      border = AnswerPalette.correctBorder;
      fg = AnswerPalette.correctFg;
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

  String? _lastLayoutLogKey;

  @override
  Widget build(BuildContext context) {
    final hasLine1 = widget.data.line1 != null;
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
        final mediaHeight =
            min(mediaWidthLimit, budget.mediaHeightForAvailable(bodyConstraints.maxHeight));
        final remainderHeight = max(0.0, bodyConstraints.maxHeight - mediaHeight);

        final promptHeight =
            remainderHeight * _pausedSentenceBuilderPromptShare[budget.tier]!;
        final slotHeight =
            remainderHeight * _pausedSentenceBuilderSlotShare[budget.tier]!;
        final tileBankHeight =
            remainderHeight * _pausedSentenceBuilderTileBankShare[budget.tier]!;

        // The prompt card's own Container below has 16px left/right padding (unlike the
        // slot/tile boxes, which have none), so the real width available inside it is 32px
        // narrower than `answerWidth` — the wrap estimate must use this, or it silently assumes
        // more room than the prompt text actually renders into, under-counting wrapped lines and
        // letting real content overflow into the scroll fallback.
        final promptCardContentWidth = max(0.0, answerWidth - 32);
        final promptWrapWidth =
            promptCardContentWidth - (_hasAnyAudioIcon ? 56 : 0);
        final promptTextBudget = max(0.0, promptHeight - 28.0);

        final tilePreset = _resolvePreset(
          items: List<String?>.generate(_perm.length, (i) => _wordAtCell(i)),
          presets: _pausedSentenceBuilderTilePresets[budget.tier]!,
          availableWidth: answerWidth - 32,
          availableHeight: max(0.0, tileBankHeight - 8.0),
          fontWeight: FontWeight.w600,
          fixedHeight: questionTileHeightFor(budget),
          fixedFontSize: questionTileTextSizeFor(budget.tier),
        );
        final tileFontSize = tilePreset.fontSize;

        final slotPreset = _resolvePreset(
          items: List<String?>.from(_sentence),
          presets: _pausedSentenceBuilderSlotPresets[budget.tier]!,
          availableWidth: answerWidth - 24,
          availableHeight: max(0.0, slotHeight - 8.0),
          fontWeight: FontWeight.w600,
          fixedHeight: questionSlotHeightFor(budget),
          fixedFontSize: questionSlotTextSizeFor(budget.tier),
        );
        final emptySlotWidth =
            _pausedSentenceBuilderCellMetrics(slotPreset.height).minWidth;
        final slotFontSize = slotPreset.fontSize;

        final dialogFontSize = questionSentenceTextSizeFor(budget.tier);
        final promptNeeded = hasLine1
            ? _promptNeededHeight(dialogFontSize, promptWrapWidth, widget.data.line1!)
            : 0.0;
        final shortfallPrompt =
            hasLine1 ? max(0.0, promptNeeded - promptTextBudget) : 0.0;

        final shortfallSlots = slotPreset.shortfallHeight;
        final shortfallTiles = tilePreset.shortfallHeight;

        final totalShortfall = shortfallPrompt + shortfallSlots + shortfallTiles;
        final extensionCap = mediaHeight;
        final totalExtension = min(totalShortfall, extensionCap);
        final mediaVisibleHeight = mediaHeight - totalExtension;
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
            '[QuestionLayout][PausedSentenceBuilder] '
            'tier=${budget.tier.name} '
            'hasLine1=$hasLine1 video=$hasVideo',
          );
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
            SizedBox(
              height: mediaVisibleHeight + promptCardHeight,
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
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 18.0, 16, 8),
                          child: Center(
                            child: SizedBox(
                              width: promptCardContentWidth,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                            bottomLeft: Radius.circular(4),
                                            bottomRight: Radius.circular(12),
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                            width: 1.5,
                                          ),
                                        ),
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
                                    spacing:
                                        _pausedSentenceBuilderRowGap(slotPreset.height),
                                    runSpacing:
                                        _pausedSentenceBuilderRowGap(slotPreset.height),
                                    children: List.generate(_sentence.length, (i) {
                                      final word = _slots[i];
                                      final slotMetrics =
                                          _pausedSentenceBuilderCellMetrics(
                                              slotPreset.height);
                                      final slot = AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        width: word == null ? emptySlotWidth : null,
                                        height: slotPreset.height,
                                        padding: EdgeInsets.symmetric(
                                            horizontal:
                                                slotMetrics.horizontalPadding / 2,
                                            vertical: 4),
                                        decoration: BoxDecoration(
                                          color: word != null
                                              ? AnswerPalette.correctBg
                                              : Colors.white,
                                          border: Border.all(
                                            color: word != null
                                                ? AnswerPalette.correctBorder
                                                : AnswerPalette.neutralBorder,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: Center(
                                          child: word == null
                                              ? const SizedBox(width: 36, height: 12)
                                              : Text(
                                                  word,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: slotFontSize,
                                                    fontWeight: FontWeight.w600,
                                                    color: AnswerPalette.correctFg,
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
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing:
                                        _pausedSentenceBuilderRowGap(tilePreset.height),
                                    runSpacing:
                                        _pausedSentenceBuilderRowGap(tilePreset.height),
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
