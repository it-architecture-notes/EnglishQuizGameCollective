import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../models/level_config.dart';
import '../../services/question_layout_budget.dart';
import '../../utils/cloze_blank.dart';
import '../../widgets/answer_palette.dart';
import '../../widgets/debug_layout_box.dart';
import '../../widgets/mcq_pill_answer_button.dart';
import '../../widgets/standard_question_media.dart';

typedef _RowPreset = ({double height, double fontSize});
typedef _VideoChoicePreset = ({double height, double fontSize, double gap});
typedef _VideoClozePreset = ({
  double sentenceFontSize,
  List<_RowPreset> tilePresets,
  double tileGap,
});

/// MCQ Pill button presets per tier, indexed by option count (`4` = the original nominal
/// size; `3`/`2` scale up since fewer, larger buttons use the room better — same low-end
/// ergonomics as `DialogueCompletion`'s per-count button ladder). Resolved via
/// `_resolveChoicePreset`, which clamps to `[2, 4]` — a 5th+ option freezes at the 4-option
/// size and the shortfall is absorbed by the existing cascade budget, same as the `[Warning]`
/// path already logs.
const Map<QuestionLayoutTier, Map<int, _VideoChoicePreset>>
    _videoChoicePresets = {
  QuestionLayoutTier.phoneUltraTall: {
    4: (height: 52.0, fontSize: 16.0, gap: 12.0),
    3: (height: 56.0, fontSize: 17.0, gap: 12.0),
    2: (height: 60.0, fontSize: 18.0, gap: 12.0),
  },
  QuestionLayoutTier.phoneSuperTall: {
    4: (height: 50.0, fontSize: 16.0, gap: 12.0),
    3: (height: 54.0, fontSize: 17.0, gap: 12.0),
    2: (height: 58.0, fontSize: 18.0, gap: 12.0),
  },
  QuestionLayoutTier.phoneFlagship: {
    4: (height: 48.0, fontSize: 15.5, gap: 10.0),
    3: (height: 52.0, fontSize: 16.5, gap: 10.0),
    2: (height: 56.0, fontSize: 17.5, gap: 10.0),
  },
  QuestionLayoutTier.phoneTransition: {
    4: (height: 48.0, fontSize: 15.0, gap: 10.0),
    3: (height: 52.0, fontSize: 16.0, gap: 10.0),
    2: (height: 56.0, fontSize: 17.0, gap: 10.0),
  },
  QuestionLayoutTier.phoneClassic2to1: {
    4: (height: 46.0, fontSize: 15.0, gap: 10.0),
    3: (height: 50.0, fontSize: 16.0, gap: 10.0),
    2: (height: 54.0, fontSize: 17.0, gap: 10.0),
  },
  QuestionLayoutTier.phone16to9: {
    4: (height: 44.0, fontSize: 14.5, gap: 8.0),
    3: (height: 48.0, fontSize: 15.5, gap: 8.0),
    2: (height: 52.0, fontSize: 16.5, gap: 8.0),
  },
  QuestionLayoutTier.tablet16to9: {
    4: (height: 58.0, fontSize: 18.0, gap: 14.0),
    3: (height: 62.0, fontSize: 19.0, gap: 14.0),
    2: (height: 66.0, fontSize: 20.0, gap: 14.0),
  },
  QuestionLayoutTier.tablet16to10: {
    4: (height: 60.0, fontSize: 18.0, gap: 14.0),
    3: (height: 64.0, fontSize: 19.0, gap: 14.0),
    2: (height: 68.0, fontSize: 20.0, gap: 14.0),
  },
  QuestionLayoutTier.tablet3to2: {
    4: (height: 62.0, fontSize: 19.0, gap: 16.0),
    3: (height: 66.0, fontSize: 20.0, gap: 16.0),
    2: (height: 70.0, fontSize: 21.0, gap: 16.0),
  },
  QuestionLayoutTier.tablet4to3: {
    4: (height: 64.0, fontSize: 19.0, gap: 16.0),
    3: (height: 68.0, fontSize: 20.0, gap: 16.0),
    2: (height: 72.0, fontSize: 21.0, gap: 16.0),
  },
};

/// Resolves the button preset for the actual option count, clamped to `[2, 4]` — covers the
/// low end (fewer options get bigger, more ergonomic buttons) and the high end (5+ options
/// freeze at the 4-option size rather than growing further; the cascade absorbs the rest).
_VideoChoicePreset _resolveChoicePreset(
    QuestionLayoutTier tier, int optionCount) {
  return _videoChoicePresets[tier]![optionCount.clamp(2, 4)]!;
}

/// Choice tile presets (3 ladders) for SentenceBuilder and AppearDisappear.
const Map<QuestionLayoutTier, List<_RowPreset>> _videoTilePresets = {
  QuestionLayoutTier.phoneUltraTall: [
    (height: 46.0, fontSize: 16.0),
    (height: 42.0, fontSize: 15.0),
    (height: 38.0, fontSize: 14.0),
  ],
  QuestionLayoutTier.phoneSuperTall: [
    (height: 44.0, fontSize: 16.0),
    (height: 40.0, fontSize: 15.0),
    (height: 36.0, fontSize: 14.0),
  ],
  QuestionLayoutTier.phoneFlagship: [
    (height: 44.0, fontSize: 15.5),
    (height: 40.0, fontSize: 14.5),
    (height: 36.0, fontSize: 13.5),
  ],
  QuestionLayoutTier.phoneTransition: [
    (height: 42.0, fontSize: 15.0),
    (height: 38.0, fontSize: 14.0),
    (height: 34.0, fontSize: 13.0),
  ],
  QuestionLayoutTier.phoneClassic2to1: [
    (height: 42.0, fontSize: 15.0),
    (height: 38.0, fontSize: 14.0),
    (height: 34.0, fontSize: 13.0),
  ],
  QuestionLayoutTier.phone16to9: [
    (height: 40.0, fontSize: 14.0),
    (height: 36.0, fontSize: 13.0),
    (height: 32.0, fontSize: 12.0),
  ],
  QuestionLayoutTier.tablet16to9: [
    (height: 52.0, fontSize: 18.0),
    (height: 46.0, fontSize: 16.5),
    (height: 42.0, fontSize: 15.0),
  ],
  QuestionLayoutTier.tablet16to10: [
    (height: 54.0, fontSize: 18.0),
    (height: 48.0, fontSize: 17.0),
    (height: 42.0, fontSize: 15.5),
  ],
  QuestionLayoutTier.tablet3to2: [
    (height: 56.0, fontSize: 19.0),
    (height: 50.0, fontSize: 17.5),
    (height: 44.0, fontSize: 16.0),
  ],
  QuestionLayoutTier.tablet4to3: [
    (height: 56.0, fontSize: 19.0),
    (height: 50.0, fontSize: 17.5),
    (height: 44.0, fontSize: 16.0),
  ],
};

/// Slot row presets (2 ladders) for SentenceBuilder and AppearDisappear.
const Map<QuestionLayoutTier, List<_RowPreset>> _videoSlotPresets = {
  QuestionLayoutTier.phoneUltraTall: [
    (height: 44.0, fontSize: 16.0),
    (height: 38.0, fontSize: 14.5),
  ],
  QuestionLayoutTier.phoneSuperTall: [
    (height: 42.0, fontSize: 16.0),
    (height: 36.0, fontSize: 14.0),
  ],
  QuestionLayoutTier.phoneFlagship: [
    (height: 42.0, fontSize: 15.5),
    (height: 36.0, fontSize: 14.0),
  ],
  QuestionLayoutTier.phoneTransition: [
    (height: 40.0, fontSize: 15.0),
    (height: 34.0, fontSize: 13.0),
  ],
  QuestionLayoutTier.phoneClassic2to1: [
    (height: 40.0, fontSize: 15.0),
    (height: 34.0, fontSize: 13.0),
  ],
  QuestionLayoutTier.phone16to9: [
    (height: 38.0, fontSize: 14.0),
    (height: 32.0, fontSize: 12.0),
  ],
  QuestionLayoutTier.tablet16to9: [
    (height: 50.0, fontSize: 18.0),
    (height: 44.0, fontSize: 16.0),
  ],
  QuestionLayoutTier.tablet16to10: [
    (height: 52.0, fontSize: 18.0),
    (height: 44.0, fontSize: 16.0),
  ],
  QuestionLayoutTier.tablet3to2: [
    (height: 54.0, fontSize: 19.0),
    (height: 46.0, fontSize: 16.5),
  ],
  QuestionLayoutTier.tablet4to3: [
    (height: 54.0, fontSize: 19.0),
    (height: 46.0, fontSize: 16.5),
  ],
};

/// Cloze sequence presets per tier.
const Map<QuestionLayoutTier, _VideoClozePreset> _videoClozePresets = {
  QuestionLayoutTier.phoneUltraTall: (
    sentenceFontSize: 17.5,
    tilePresets: [
      (height: 44.0, fontSize: 15.5),
      (height: 38.0, fontSize: 14.0),
    ],
    tileGap: 8.0,
  ),
  QuestionLayoutTier.phoneSuperTall: (
    sentenceFontSize: 17.0,
    tilePresets: [
      (height: 42.0, fontSize: 15.0),
      (height: 36.0, fontSize: 13.5),
    ],
    tileGap: 8.0,
  ),
  QuestionLayoutTier.phoneFlagship: (
    sentenceFontSize: 16.5,
    tilePresets: [
      (height: 42.0, fontSize: 15.0),
      (height: 36.0, fontSize: 13.5),
    ],
    tileGap: 8.0,
  ),
  QuestionLayoutTier.phoneTransition: (
    sentenceFontSize: 16.0,
    tilePresets: [
      (height: 40.0, fontSize: 14.5),
      (height: 34.0, fontSize: 13.0),
    ],
    tileGap: 6.0,
  ),
  QuestionLayoutTier.phoneClassic2to1: (
    sentenceFontSize: 16.0,
    tilePresets: [
      (height: 40.0, fontSize: 14.5),
      (height: 34.0, fontSize: 13.0),
    ],
    tileGap: 6.0,
  ),
  QuestionLayoutTier.phone16to9: (
    sentenceFontSize: 15.0,
    tilePresets: [
      (height: 38.0, fontSize: 13.5),
      (height: 32.0, fontSize: 12.0),
    ],
    tileGap: 6.0,
  ),
  QuestionLayoutTier.tablet16to9: (
    sentenceFontSize: 20.0,
    tilePresets: [
      (height: 50.0, fontSize: 17.5),
      (height: 42.0, fontSize: 15.5),
    ],
    tileGap: 10.0,
  ),
  QuestionLayoutTier.tablet16to10: (
    sentenceFontSize: 20.0,
    tilePresets: [
      (height: 52.0, fontSize: 18.0),
      (height: 44.0, fontSize: 16.0),
    ],
    tileGap: 10.0,
  ),
  QuestionLayoutTier.tablet3to2: (
    sentenceFontSize: 21.0,
    tilePresets: [
      (height: 54.0, fontSize: 19.0),
      (height: 46.0, fontSize: 16.5),
    ],
    tileGap: 12.0,
  ),
  QuestionLayoutTier.tablet4to3: (
    sentenceFontSize: 21.0,
    tilePresets: [
      (height: 54.0, fontSize: 19.0),
      (height: 46.0, fontSize: 16.5),
    ],
    tileGap: 12.0,
  ),
};

({double minWidth, double horizontalPadding}) _videoTileCellMetrics(
    double height) {
  if (height >= 50) return (minWidth: 78.0, horizontalPadding: 24.0);
  if (height >= 44) return (minWidth: 70.0, horizontalPadding: 20.0);
  if (height >= 38) return (minWidth: 62.0, horizontalPadding: 16.0);
  return (minWidth: 54.0, horizontalPadding: 14.0);
}

double _videoRowGap(double height) {
  if (height >= 50) return 10.0;
  if (height >= 42) return 8.0;
  return 6.0;
}

typedef _PresetResolution = ({
  double height,
  double fontSize,
  int rows,
  double shortfallHeight,
});

/// DEBUG ONLY. Flip to `true` to bypass all question-pausing and just let the shared
/// [VideoPlayerController] play straight through to the end of the file.
const bool kDebugPlayVideoConversationToEndWithoutPausing = false;

/// Plays `[data.startAt, data.pauseAt]` of the level's shared video, pauses right at
/// [VideoConversationQuestionData.pauseAt], then renders whichever of [VideoConversationQuestionData.choiceData]
/// / [VideoConversationQuestionData.sequenceData] / [VideoConversationQuestionData.clozeData] is set as the
/// answer panel. Correct answer resumes playback; wrong answer locks the panel and leaves the video paused.
class VideoConversationQuizBody extends StatefulWidget {
  const VideoConversationQuizBody({
    super.key,
    required this.data,
    required this.controller,
    this.continueExistingPlayback = false,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
    this.onChoiceButtonsRendered,
    this.onNextTileRendered,
    this.setupAudioPath,
    this.confirmAudioPath,
    this.onPlayQuestionAudio,
    this.onStartQuestionAudio,
    this.waitForTutorial,
    this.debugShowLayoutBounds = false,
  });

  final VideoConversationQuestionData data;
  final VideoPlayerController? controller;

  /// True only inside the `testing-responsive-design` level — draws a visible outline + label
  /// around every major layout box so box boundaries/percentages can be visually audited.
  final bool debugShowLayoutBounds;

  /// True when the previous question used the same shared video controller.
  final bool continueExistingPlayback;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  final String? setupAudioPath;
  final String? confirmAudioPath;

  final Future<void> Function(String path)? onPlayQuestionAudio;
  final Future<void> Function(String path)? onStartQuestionAudio;
  final Future<void> Function()? waitForTutorial;
  final void Function(int correctIndex, List<GlobalKey> buttonKeys)?
      onChoiceButtonsRendered;
  final void Function(int expectedIndex, List<GlobalKey> tileKeys)?
      onNextTileRendered;

  @override
  State<VideoConversationQuizBody> createState() =>
      _VideoConversationQuizBodyState();
}

class _VideoConversationQuizBodyState extends State<VideoConversationQuizBody> {
  bool _paused = false;
  bool _pauseHandled = false;
  bool _listenerAttached = false;
  int _debugLastLoggedSecond = -1;

  // MCQ state
  late final List<String> _choiceOptions;
  late final int? _choiceCorrectIndex;
  late final List<GlobalKey> _choiceButtonKeys;
  bool _choiceLocked = false;
  int? _choiceSelectedIndex;
  bool _reportedChoiceButtons = false;

  // Tile / Sequence / Cloze state
  late final List<String> _tileTarget;
  late final List<String> _tileChoices;
  late final List<String?> _tileSlots;
  late final List<GlobalKey> _tileChoiceKeys;
  int _tapProgress = 0;
  final Set<int> _tileUsedIndices = {};
  final Map<int, int> _tileStepOf = {};
  bool _tileFailed = false;
  int? _tileWrongIndex;
  bool _tileCompleted = false;

  @override
  void initState() {
    super.initState();
    _initAnswerState();
    _reportTileTarget();
    _attachAndPlay();
  }

  void _reportTileTarget() {
    if (widget.onNextTileRendered == null) return;
    if (!_paused) return;
    if (_tapProgress >= _tileTarget.length) return;
    final expectedWord = _tileTarget[_tapProgress];
    var expectedIndex = -1;
    for (var i = 0; i < _tileChoices.length; i++) {
      if (_tileChoices[i] == expectedWord && !_tileUsedIndices.contains(i)) {
        expectedIndex = i;
        break;
      }
    }
    if (expectedIndex < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onNextTileRendered!(expectedIndex, _tileChoiceKeys);
    });
  }

  void _initAnswerState() {
    final d = widget.data;
    if (d.choiceData != null) {
      _choiceOptions = [d.choiceData!.answer, ...d.choiceData!.distractors]
        ..shuffle(Random());
      _choiceCorrectIndex = _choiceOptions.indexOf(d.choiceData!.answer);
      _choiceButtonKeys =
          List.generate(_choiceOptions.length, (_) => GlobalKey());
      _tileTarget = const [];
      _tileChoices = const [];
      _tileSlots = [];
      _tileChoiceKeys = const [];
    } else if (d.sequenceData != null) {
      _choiceOptions = const [];
      _choiceCorrectIndex = null;
      _choiceButtonKeys = const [];
      _tileTarget = d.sequenceData!.targetSentence.split(' ');
      _tileChoices = [..._tileTarget, ...d.sequenceData!.distractors]
        ..shuffle(Random());
      _tileSlots = List<String?>.filled(_tileTarget.length, null);
      _tileChoiceKeys = List.generate(_tileChoices.length, (_) => GlobalKey());
    } else if (d.clozeData != null) {
      _choiceOptions = const [];
      _choiceCorrectIndex = null;
      _choiceButtonKeys = const [];
      _tileTarget = d.clozeData!.answers;
      _tileChoices = [...d.clozeData!.answers, ...d.clozeData!.distractors]
        ..shuffle(Random());
      _tileSlots = List<String?>.filled(_tileTarget.length, null);
      _tileChoiceKeys = List.generate(_tileChoices.length, (_) => GlobalKey());
    } else {
      _choiceOptions = const [];
      _choiceCorrectIndex = null;
      _choiceButtonKeys = const [];
      _tileTarget = const [];
      _tileChoices = const [];
      _tileSlots = [];
      _tileChoiceKeys = const [];
    }
  }

  Future<void> _attachAndPlay() async {
    final controller = widget.controller;
    if (widget.waitForTutorial != null) {
      if (controller != null &&
          controller.value.isInitialized &&
          controller.value.isPlaying) {
        await controller.pause();
      }
      await widget.waitForTutorial!();
      if (!mounted) return;
    }
    if (controller == null) {
      setState(() => _paused = true);
      return;
    }
    try {
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }
      if (!mounted) return;
      if (!widget.continueExistingPlayback &&
          controller.value.position < widget.data.startAt) {
        await controller.seekTo(widget.data.startAt);
      }
      if (!mounted) return;
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      controller.addListener(_onPositionChanged);
      _listenerAttached = true;
      if (!controller.value.isPlaying) {
        final setupPath = widget.setupAudioPath;
        final startAudio = widget.onStartQuestionAudio;
        if (setupPath != null && startAudio != null) {
          await startAudio(setupPath);
        }
        if (!mounted) return;
        await controller.play();
        debugPrint(
          'Video conversation started: ${DateTime.now().millisecondsSinceEpoch} ms '
          '(asset: ${controller.dataSource})',
        );
      }
      if (widget.setupAudioPath == null ||
          widget.onStartQuestionAudio == null) {
        _playSetupAudio();
      }
    } catch (e) {
      debugPrint(
          'VideoConversationQuizBody: video failed to load, skipping to answer panel: $e');
      if (mounted) setState(() => _paused = true);
    }
  }

  void _playSetupAudio() {
    final path = widget.setupAudioPath;
    final play = widget.onPlayQuestionAudio;
    if (path == null || play == null) return;
    play(path);
  }

  void _playConfirmAudio() {
    final path = widget.confirmAudioPath;
    final play = widget.onPlayQuestionAudio;
    if (path == null || play == null) return;
    play(path);
  }

  void _onPositionChanged() {
    final controller = widget.controller;
    if (controller == null) return;
    if (kDebugPlayVideoConversationToEndWithoutPausing) {
      final second = controller.value.position.inSeconds;
      if (second != _debugLastLoggedSecond) {
        _debugLastLoggedSecond = second;
        debugPrint(
          'VideoConversation debug: position=${controller.value.position} '
          'duration=${controller.value.duration} '
          'isPlaying=${controller.value.isPlaying} '
          'buffered=${controller.value.buffered}',
        );
      }
      return;
    }
    if (_pauseHandled) return;
    final duration = controller.value.duration;
    final target = (duration > Duration.zero && widget.data.pauseAt > duration)
        ? duration
        : widget.data.pauseAt;
    if (controller.value.position >= target) {
      _pauseHandled = true;
      controller.removeListener(_onPositionChanged);
      _listenerAttached = false;
      _pauseThenReveal(controller);
    }
  }

  Future<void> _pauseThenReveal(VideoPlayerController controller) async {
    try {
      await controller.pause();
    } catch (e, st) {
      debugPrint('[VideoConversation] pause failed: $e\n$st');
    }
    if (mounted) {
      setState(() => _paused = true);
      _reportTileTarget();
    }
  }

  void _resumeVideo() {
    widget.controller?.play().catchError((Object e, StackTrace st) {
      debugPrint(
          '[VideoConversation] controller.play() (resume) failed: $e\n$st');
    });
    _playConfirmAudio();
  }

  @override
  void dispose() {
    if (_listenerAttached) {
      widget.controller?.removeListener(_onPositionChanged);
    }
    super.dispose();
  }

  void _onChoiceTap(int index) {
    if (_choiceLocked) return;
    final correct = index == _choiceCorrectIndex;
    setState(() {
      _choiceLocked = true;
      _choiceSelectedIndex = index;
    });
    if (correct) {
      widget.onPlayCorrect();
      _resumeVideo();
      widget.onOutcome(true);
    } else {
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  void _onTileTap(int choiceIndex) {
    if (_tileFailed ||
        _tileCompleted ||
        _tileUsedIndices.contains(choiceIndex)) {
      return;
    }
    final word = _tileChoices[choiceIndex];
    final expected = _tileTarget[_tapProgress];
    if (word == expected) {
      setState(() {
        _tileSlots[_tapProgress] = word;
        _tileUsedIndices.add(choiceIndex);
        _tileStepOf[choiceIndex] = _tapProgress + 1;
        _tapProgress++;
        if (_tapProgress >= _tileTarget.length) _tileCompleted = true;
      });
      if (_tileCompleted) {
        widget.onPlayCorrect();
        _resumeVideo();
        widget.onOutcome(true);
      } else {
        _reportTileTarget();
      }
    } else {
      setState(() {
        _tileFailed = true;
        _tileWrongIndex = choiceIndex;
        for (var i = _tapProgress; i < _tileTarget.length; i++) {
          _tileSlots[i] = _tileTarget[i];
        }
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
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

  _PresetResolution _resolvePreset({
    required List<String?> items,
    required List<_RowPreset> presets,
    required double availableWidth,
    required double availableHeight,
    required FontWeight fontWeight,
  }) {
    for (var i = 0; i < presets.length; i++) {
      final preset = presets[i];
      final metrics = _videoTileCellMetrics(preset.height);
      final rows = _estimateWrapRows(
        items: items,
        availableWidth: availableWidth,
        spacing: _videoRowGap(preset.height),
        minItemWidth: metrics.minWidth,
        horizontalPadding: metrics.horizontalPadding,
        fontSize: preset.fontSize,
        fontWeight: fontWeight,
      );
      if (rows <= i + 1) {
        final needed =
            rows * preset.height + (rows - 1) * _videoRowGap(preset.height);
        return (
          height: preset.height,
          fontSize: preset.fontSize,
          rows: rows,
          shortfallHeight: max(0.0, needed - availableHeight),
        );
      }
    }
    final maxPreset = presets.last;
    final maxMetrics = _videoTileCellMetrics(maxPreset.height);
    final actualRows = _estimateWrapRows(
      items: items,
      availableWidth: availableWidth,
      spacing: _videoRowGap(maxPreset.height),
      minItemWidth: maxMetrics.minWidth,
      horizontalPadding: maxMetrics.horizontalPadding,
      fontSize: maxPreset.fontSize,
      fontWeight: fontWeight,
    );
    final needed = actualRows * maxPreset.height +
        (actualRows - 1) * _videoRowGap(maxPreset.height);
    return (
      height: maxPreset.height,
      fontSize: maxPreset.fontSize,
      rows: actualRows,
      shortfallHeight: max(0.0, needed - availableHeight),
    );
  }

  double _measureClozeSentenceHeight(
    String sentence,
    double fontSize,
    double availableWidth,
  ) {
    if (sentence.isEmpty || availableWidth <= 0) return 0.0;
    final painter = TextPainter(
      text: TextSpan(
        text: sentence,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: availableWidth);
    return painter.height + 16.0;
  }

  int _measureMaxButtonLines(
    List<String> options,
    double fontSize,
    double buttonWidth,
  ) {
    final textMaxWidth = max(1.0, buttonWidth - 48.0);
    final direction = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    var maxLines = 1;
    for (final opt in options) {
      final painter = TextPainter(
        text: TextSpan(
          text: opt,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: direction,
        textScaler: textScaler,
      )..layout(maxWidth: textMaxWidth);
      if (painter.computeLineMetrics().length > maxLines) {
        maxLines = painter.computeLineMetrics().length;
      }
    }
    return maxLines;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final hasVideo = controller != null && controller.value.isInitialized;
    final aspectRatio = hasVideo ? controller.value.aspectRatio : 1.0;
    final layoutBudget = QuestionLayoutBudget.of(context);

    return LayoutBuilder(
      builder: (context, bodyConstraints) {
        final mediaHeight =
            layoutBudget.mediaHeightForAvailable(bodyConstraints.maxHeight);
        final mediaWidthLimit =
            layoutBudget.mediaWidthForAvailable(bodyConstraints.maxWidth);
        final answerWidth = layoutBudget
            .answerWidthForAvailable(MediaQuery.sizeOf(context).width);
        final remainderHeight =
            max(0.0, bodyConstraints.maxHeight - mediaHeight);

        // Compute shortfalls and cascade extension per answer type
        var totalShortfall = 0.0;
        var buttonHeight = 48.0;
        var buttonFontSize = 15.0;
        var buttonGap = 10.0;

        _PresetResolution? slotPreset;
        _PresetResolution? tilePreset;
        _VideoClozePreset? clozePreset;
        var clozeSentenceHeight = 0.0;

        if (_paused) {
          if (widget.data.choiceData != null) {
            final preset =
                _resolveChoicePreset(layoutBudget.tier, _choiceOptions.length);
            buttonFontSize = preset.fontSize;
            buttonGap = preset.gap;
            final maxLines = _measureMaxButtonLines(
                _choiceOptions, buttonFontSize, answerWidth);
            buttonHeight = maxLines > 1
                ? max(preset.height + (maxLines - 1) * 20.0, preset.height)
                : preset.height;
            final totalButtonsHeight = _choiceOptions.length * buttonHeight +
                max(0, _choiceOptions.length - 1) * buttonGap +
                16.0;
            totalShortfall = max(0.0, totalButtonsHeight - remainderHeight);

            if (_choiceOptions.length > 4) {
              debugPrint(
                '[QuestionLayout][VideoConversation][Warning] options count (${_choiceOptions.length}) exceeded nominal cap of 4.',
              );
            }
          } else if (widget.data.clozeData != null) {
            clozePreset = _videoClozePresets[layoutBudget.tier]!;
            final clozeBudget = remainderHeight * 0.45;
            final tileBudget = remainderHeight * 0.55;
            clozeSentenceHeight = _measureClozeSentenceHeight(
              widget.data.clozeData!.sentence,
              clozePreset.sentenceFontSize,
              answerWidth,
            );
            final shortfallCloze = max(0.0, clozeSentenceHeight - clozeBudget);
            tilePreset = _resolvePreset(
              items: _tileChoices,
              presets: clozePreset.tilePresets,
              availableWidth: answerWidth - 24.0,
              availableHeight: max(0.0, tileBudget - 16.0),
              fontWeight: FontWeight.w600,
            );
            totalShortfall = shortfallCloze + tilePreset.shortfallHeight;

            if (tilePreset.rows > 2) {
              debugPrint(
                '[QuestionLayout][VideoConversation][Warning] cloze tiles exceeded nominal 2-row cap (rows=${tilePreset.rows}).',
              );
            }
          } else {
            // Sequence / SentenceBuilder / AppearDisappear
            final slotBudget = remainderHeight * 0.38;
            final tileBudget = remainderHeight * 0.62;
            slotPreset = _resolvePreset(
              items: _tileSlots,
              presets: _videoSlotPresets[layoutBudget.tier]!,
              availableWidth: answerWidth - 24.0,
              availableHeight: max(0.0, slotBudget - 16.0),
              fontWeight: FontWeight.w800,
            );
            tilePreset = _resolvePreset(
              items: _tileChoices,
              presets: _videoTilePresets[layoutBudget.tier]!,
              availableWidth: answerWidth - 32.0,
              availableHeight: max(0.0, tileBudget - 16.0),
              fontWeight: FontWeight.w600,
            );
            totalShortfall =
                slotPreset.shortfallHeight + tilePreset.shortfallHeight;

            if (slotPreset.rows > 2 || tilePreset.rows > 3) {
              debugPrint(
                '[QuestionLayout][VideoConversation][Warning] sequence content exceeded row cap (slots=${slotPreset.rows}/2, tiles=${tilePreset.rows}/3).',
              );
            }
          }

          if (totalShortfall > mediaHeight) {
            debugPrint(
              '[QuestionLayout][VideoConversation][Severe] shortfall (${totalShortfall.toStringAsFixed(1)}px) exceeds available media extension (${mediaHeight.toStringAsFixed(1)}px) — answer area will scroll.',
            );
          }
        }

        final cascadeExtension = min(totalShortfall, mediaHeight);
        final mediaVisibleHeight = max(0.0, mediaHeight - cascadeExtension);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed media container: renders fixed media underneath while contracting bounding box
            SizedBox(
              height: mediaVisibleHeight,
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
                        aspectRatio: aspectRatio,
                        heightOverride: min(
                          mediaWidthLimit / aspectRatio,
                          mediaHeight,
                        ),
                        widthOverride: mediaWidthLimit,
                        child: hasVideo
                            ? VideoPlayer(controller)
                            : ColoredBox(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                child: _paused
                                    ? const SizedBox.shrink()
                                    : const Center(
                                        child: CircularProgressIndicator()),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_paused)
              Expanded(
                child: DebugLayoutBox(
                  enabled: widget.debugShowLayoutBounds,
                  label: 'answer',
                  color: Colors.blue,
                  child: Container(
                    color: Colors.white,
                    child: LayoutBuilder(
                      builder: (context, answerConstraints) {
                        final content = widget.data.choiceData != null
                            ? _buildChoicePanel(
                                answerWidth: answerWidth,
                                buttonHeight: buttonHeight,
                                fontSize: buttonFontSize,
                                gap: buttonGap,
                              )
                            : widget.data.clozeData != null
                                ? _buildClozePanel(
                                    context: context,
                                    cloze: widget.data.clozeData!,
                                    clozePreset: clozePreset!,
                                    tilePreset: tilePreset!,
                                    answerWidth: answerWidth,
                                  )
                                : _buildSequencePanel(
                                    context: context,
                                    slotPreset: slotPreset!,
                                    tilePreset: tilePreset!,
                                    answerWidth: answerWidth,
                                  );

                        return SingleChildScrollView(
                          child: Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: SizedBox(
                                width: answerWidth,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight:
                                        answerConstraints.maxHeight - 16.0,
                                  ),
                                  child: content,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildChoicePanel({
    required double answerWidth,
    required double buttonHeight,
    required double fontSize,
    required double gap,
  }) {
    if (!_reportedChoiceButtons && widget.onChoiceButtonsRendered != null) {
      _reportedChoiceButtons = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _choiceCorrectIndex == null) return;
        widget.onChoiceButtonsRendered!(_choiceCorrectIndex, _choiceButtonKeys);
      });
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_choiceOptions.length, (i) {
        final isCorrect = _choiceLocked && i == _choiceCorrectIndex;
        final isWrongPick = _choiceLocked &&
            i == _choiceSelectedIndex &&
            i != _choiceCorrectIndex;
        final state = isCorrect
            ? McqAnswerState.correct
            : isWrongPick
                ? McqAnswerState.wrong
                : McqAnswerState.neutral;
        return Padding(
          key: _choiceButtonKeys[i],
          padding: EdgeInsets.only(
            bottom: i == _choiceOptions.length - 1 ? 0 : gap,
          ),
          child: McqPillAnswerButton(
            label: _choiceOptions[i],
            state: state,
            width: answerWidth,
            minHeight: buttonHeight,
            maxHeight: buttonHeight,
            fontSize: fontSize,
            onTap: _choiceLocked ? null : () => _onChoiceTap(i),
          ),
        );
      }),
    );
  }

  List<InlineSpan> _buildClozeSentenceSpans(
    ThemeData theme,
    VideoClozeAnswerData cloze,
    double fontSize,
  ) {
    final cs = theme.colorScheme;
    final tokens = cloze.sentence.split(' ');
    final spans = <InlineSpan>[];
    var blankI = 0;
    for (var i = 0; i < tokens.length; i++) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' '));
      final t = tokens[i];
      if (isClozeBlankToken(t)) {
        final core = stripClozeBlankAffixes(t);
        final coreStart = t.indexOf(core);
        final prefix = coreStart > 0 ? t.substring(0, coreStart) : '';
        final suffix = t.substring(coreStart + core.length);
        final filled = blankI < _tileSlots.length ? _tileSlots[blankI] : null;
        late final String blankText;
        late final TextStyle blankStyle;
        if (filled != null) {
          final userFilled = blankI < _tapProgress;
          blankText = filled;
          blankStyle = TextStyle(
            fontFamily: 'Inter',
            fontSize: fontSize,
            color: AnswerPalette.correctFg,
            fontWeight: FontWeight.w700,
            fontStyle: userFilled ? null : FontStyle.italic,
          );
        } else {
          blankText = '_____';
          blankStyle = TextStyle(
            fontFamily: 'Inter',
            fontSize: fontSize,
            color: cs.primary,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
          );
        }
        if (prefix.isNotEmpty) spans.add(TextSpan(text: prefix));
        spans.add(TextSpan(text: blankText, style: blankStyle));
        if (suffix.isNotEmpty) spans.add(TextSpan(text: suffix));
        blankI++;
      } else {
        spans.add(TextSpan(text: t));
      }
    }
    return spans;
  }

  Widget _buildClozePanel({
    required BuildContext context,
    required VideoClozeAnswerData cloze,
    required _VideoClozePreset clozePreset,
    required _PresetResolution tilePreset,
    required double answerWidth,
  }) {
    final theme = Theme.of(context);
    final tileMetrics = _videoTileCellMetrics(tilePreset.height);
    final gap = _videoRowGap(tilePreset.height);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: clozePreset.sentenceFontSize,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              children: _buildClozeSentenceSpans(
                  theme, cloze, clozePreset.sentenceFontSize),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: List.generate(_tileChoices.length, (i) {
            return _buildTile(
              i,
              fontSize: tilePreset.fontSize,
              height: tilePreset.height,
              metrics: tileMetrics,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSequencePanel({
    required BuildContext context,
    required _PresetResolution slotPreset,
    required _PresetResolution tilePreset,
    required double answerWidth,
  }) {
    final slotMetrics = _videoTileCellMetrics(slotPreset.height);
    final tileMetrics = _videoTileCellMetrics(tilePreset.height);
    final slotGap = _videoRowGap(slotPreset.height);
    final tileGap = _videoRowGap(tilePreset.height);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: slotGap,
          runSpacing: slotGap,
          children: List.generate(_tileTarget.length, (i) {
            final word = _tileSlots[i];
            final filled = word != null;
            final slot = AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: slotPreset.height,
              width: filled ? null : slotMetrics.minWidth,
              padding: EdgeInsets.symmetric(
                horizontal: slotMetrics.horizontalPadding / 2,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: filled ? AnswerPalette.correctBg : Colors.white,
                border: Border.all(
                  color: filled
                      ? AnswerPalette.correctBorder
                      : AnswerPalette.neutralBorder,
                  width: filled ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: word == null
                    ? const SizedBox.shrink()
                    : Text(
                        word,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: slotPreset.fontSize,
                          fontWeight: FontWeight.w700,
                          color: AnswerPalette.correctFg,
                        ),
                      ),
              ),
            );
            return filled ? IntrinsicWidth(child: slot) : slot;
          }),
        ),
        const SizedBox(height: 16.0),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: tileGap,
          runSpacing: tileGap,
          children: List.generate(_tileChoices.length, (i) {
            return _buildTile(
              i,
              fontSize: tilePreset.fontSize,
              height: tilePreset.height,
              metrics: tileMetrics,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTile(
    int index, {
    required double fontSize,
    required double height,
    required ({double minWidth, double horizontalPadding}) metrics,
  }) {
    final word = _tileChoices[index];
    final disabled =
        _tileFailed || _tileCompleted || _tileUsedIndices.contains(index);
    final isWrong = _tileFailed && _tileWrongIndex == index;
    final isCorrectTile = _tileUsedIndices.contains(index);
    final step = _tileStepOf[index];

    final Color bg;
    final Color border;
    final Color fg;
    if (isWrong) {
      bg = AnswerPalette.wrongBg;
      border = AnswerPalette.wrongBorder;
      fg = AnswerPalette.wrongFg;
    } else if (isCorrectTile) {
      bg = AnswerPalette.correctBg;
      border = AnswerPalette.correctBorder;
      fg = AnswerPalette.correctFg;
    } else {
      bg = AnswerPalette.neutralBg;
      border = AnswerPalette.neutralBorder;
      fg = AnswerPalette.neutralFg;
    }

    return Material(
      key: _tileChoiceKeys.length > index ? _tileChoiceKeys[index] : null,
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border)),
      child: InkWell(
        onTap: disabled ? null : () => _onTileTap(index),
        customBorder: StadiumBorder(side: BorderSide(color: border)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: metrics.minWidth,
            minHeight: height,
            maxHeight: height,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding / 2,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isWrong) ...[
                      Icon(Icons.close, size: 14, color: border),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      word,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCorrectTile && step != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: AnswerPalette.correctBorder,
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
}
