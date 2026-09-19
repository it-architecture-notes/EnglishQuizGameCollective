import 'dart:async';
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
typedef _VideoClozeGapPreset = ({double x, double y, double z, double w});
typedef _ListenAgainPreset = ({double widthFraction});

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

/// Responsive sentence-to-tile gap fractions, applied to the available video-answer height.
/// X is used for a one-line sentence with a multi-row tile group, Y for a multi-line sentence
/// with a one-row tile group, Z for the sparse one-line/one-row permutation, and W for the
/// multi-line/multi-row permutation.
const Map<QuestionLayoutTier, _VideoClozeGapPreset> _videoClozeGapPresets = {
  QuestionLayoutTier.phoneUltraTall: (x: 0.075, y: 0.085, z: 0.180, w: 0.060),
  QuestionLayoutTier.phoneSuperTall: (x: 0.070, y: 0.080, z: 0.170, w: 0.055),
  QuestionLayoutTier.phoneFlagship: (x: 0.065, y: 0.075, z: 0.160, w: 0.050),
  QuestionLayoutTier.phoneTransition: (x: 0.060, y: 0.070, z: 0.150, w: 0.045),
  QuestionLayoutTier.phoneClassic2to1: (x: 0.055, y: 0.065, z: 0.140, w: 0.040),
  QuestionLayoutTier.phone16to9: (x: 0.050, y: 0.060, z: 0.120, w: 0.035),
  QuestionLayoutTier.tablet16to9: (x: 0.070, y: 0.080, z: 0.160, w: 0.050),
  QuestionLayoutTier.tablet16to10: (x: 0.075, y: 0.085, z: 0.170, w: 0.055),
  QuestionLayoutTier.tablet3to2: (x: 0.080, y: 0.090, z: 0.180, w: 0.060),
  QuestionLayoutTier.tablet4to3: (x: 0.085, y: 0.095, z: 0.190, w: 0.065),
};

/// SentenceBuilder gap fractions. SentenceBuilder has no Listen Again block, so its larger
/// available interaction area can use slightly more generous X/Y/Z/W spacing than recall.
const Map<QuestionLayoutTier, _VideoClozeGapPreset>
    _videoSentenceBuilderGapPresets = {
  QuestionLayoutTier.phoneUltraTall: (x: 0.085, y: 0.095, z: 0.200, w: 0.065),
  QuestionLayoutTier.phoneSuperTall: (x: 0.080, y: 0.090, z: 0.190, w: 0.060),
  QuestionLayoutTier.phoneFlagship: (x: 0.075, y: 0.085, z: 0.180, w: 0.055),
  QuestionLayoutTier.phoneTransition: (x: 0.070, y: 0.080, z: 0.170, w: 0.050),
  QuestionLayoutTier.phoneClassic2to1: (x: 0.065, y: 0.075, z: 0.160, w: 0.045),
  QuestionLayoutTier.phone16to9: (x: 0.060, y: 0.070, z: 0.145, w: 0.040),
  QuestionLayoutTier.tablet16to9: (x: 0.080, y: 0.090, z: 0.180, w: 0.055),
  QuestionLayoutTier.tablet16to10: (x: 0.085, y: 0.095, z: 0.190, w: 0.060),
  QuestionLayoutTier.tablet3to2: (x: 0.090, y: 0.100, z: 0.200, w: 0.065),
  QuestionLayoutTier.tablet4to3: (x: 0.095, y: 0.105, z: 0.210, w: 0.070),
};

double _videoClozeGapFraction(
  QuestionLayoutTier tier, {
  required int sentenceLines,
  required int tileRows,
}) {
  final preset = _videoClozeGapPresets[tier]!;
  if (sentenceLines >= 2 && tileRows >= 2) return preset.w;
  if (sentenceLines == 1 && tileRows >= 2) return preset.x;
  if (sentenceLines >= 2 && tileRows == 1) return preset.y;
  return preset.z;
}

double _videoSentenceBuilderGapFraction(
  QuestionLayoutTier tier, {
  required int slotRows,
  required int tileRows,
}) {
  final preset = _videoSentenceBuilderGapPresets[tier]!;
  if (slotRows >= 2 && tileRows >= 2) return preset.w;
  if (slotRows == 1 && tileRows >= 2) return preset.x;
  if (slotRows >= 2 && tileRows == 1) return preset.y;
  return preset.z;
}

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

const Map<QuestionLayoutTier, _ListenAgainPreset> _listenAgainPresets = {
  QuestionLayoutTier.phoneUltraTall: (widthFraction: 0.48),
  QuestionLayoutTier.phoneSuperTall: (widthFraction: 0.47),
  QuestionLayoutTier.phoneFlagship: (widthFraction: 0.46),
  QuestionLayoutTier.phoneTransition: (widthFraction: 0.45),
  QuestionLayoutTier.phoneClassic2to1: (widthFraction: 0.44),
  QuestionLayoutTier.phone16to9: (widthFraction: 0.43),
  QuestionLayoutTier.tablet16to9: (widthFraction: 0.38),
  QuestionLayoutTier.tablet16to10: (widthFraction: 0.37),
  QuestionLayoutTier.tablet3to2: (widthFraction: 0.36),
  QuestionLayoutTier.tablet4to3: (widthFraction: 0.35),
};

const Map<QuestionLayoutTier, double> _listenAgainSlotsGapFractions = {
  QuestionLayoutTier.phoneUltraTall: 0.055,
  QuestionLayoutTier.phoneSuperTall: 0.052,
  QuestionLayoutTier.phoneFlagship: 0.050,
  QuestionLayoutTier.phoneTransition: 0.048,
  QuestionLayoutTier.phoneClassic2to1: 0.046,
  QuestionLayoutTier.phone16to9: 0.044,
  QuestionLayoutTier.tablet16to9: 0.050,
  QuestionLayoutTier.tablet16to10: 0.052,
  QuestionLayoutTier.tablet3to2: 0.054,
  QuestionLayoutTier.tablet4to3: 0.056,
};

double _listenAgainButtonHeightFor(QuestionLayoutBudget budget) =>
    questionSlotHeightFor(budget);

double _listenAgainButtonWidthFor(
    QuestionLayoutBudget budget, double answerWidth) {
  final preset = _listenAgainPresets[budget.tier]!;
  return min(answerWidth, max(120.0, answerWidth * preset.widthFraction));
}

double _listenAgainSlotsGapFor(
  QuestionLayoutBudget budget,
  double heightAfterButton,
) {
  final fraction = _listenAgainSlotsGapFractions[budget.tier]!;
  return max(8.0, heightAfterButton * fraction);
}

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
    this.onUserInteracted,
    this.onChoiceButtonsRendered,
    this.onNextTileRendered,
    this.exitCorrectAudioCue,
    this.enterAudioCue,
    this.onPlayQuestionAudio,
    this.onStartQuestionAudio,
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

  /// Fired on the very first interaction with this question (choice tap, tile tap, or "Listen
  /// Again") — used to hide the footer guide hint.
  final VoidCallback? onUserInteracted;

  /// Clips played in sequence after a correct answer, once the video resumes. Also the *only*
  /// thing the AppearDisappear/recall sub-type's "Listen Again" button ever plays — no
  /// fallback, no separate repeat clip.
  final List<String>? exitCorrectAudioCue;

  /// Clips played in sequence once, automatically, the first time this question is presented.
  /// No fallback: if unset, nothing plays automatically on entry.
  final List<String>? enterAudioCue;

  final Future<void> Function(String path)? onPlayQuestionAudio;
  final Future<void> Function(String path)? onStartQuestionAudio;
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
  final Map<int, int> _tileRevealedStepOf = {};
  bool _tileFailed = false;
  int? _tileWrongIndex;
  bool _tileCompleted = false;
  bool _listenAgainConsumed = false;
  bool _listenAgainPlaying = false;

  bool get _isAppearDisappear => widget.data.sequenceData?.isRecall == true;

  bool get _canListenAgain =>
      _isAppearDisappear &&
      widget.exitCorrectAudioCue != null &&
      widget.exitCorrectAudioCue!.isNotEmpty &&
      widget.onPlayQuestionAudio != null;

  bool get _showListenAgain =>
      _paused && _canListenAgain && !_listenAgainConsumed;

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
      final shouldStartSetup = !controller.value.isPlaying;
      if (shouldStartSetup) {
        final cue = _entryAudioCue;
        final startAudio = widget.onStartQuestionAudio;
        if (cue != null && cue.isNotEmpty && startAudio != null) {
          await startAudio(cue.first);
          if (cue.length > 1) {
            unawaited(_playCue(cue.sublist(1)));
          }
        } else {
          // No entry audio to sync with the video start, or no sync mechanism available
          // — still play it as a normal (unsynced) clip if there is one.
          _playSetupAudio();
        }
        if (!mounted) return;
        if (!controller.value.isPlaying) await controller.play();
        debugPrint(
          'Video conversation started: ${DateTime.now().millisecondsSinceEpoch} ms '
          '(asset: ${controller.dataSource})',
        );
      } else {
        // The shared video is already rolling straight through from the previous
        // question (e.g. that question's answer_until == its own pause_at, so it never
        // re-paused) — there's no "start" to sync with, but this question's own entry
        // audio still needs to play.
        _playSetupAudio();
      }
    } catch (e) {
      debugPrint(
          'VideoConversationQuizBody: video failed to load, skipping to answer panel: $e');
      if (mounted) setState(() => _paused = true);
    }
  }

  /// Audio played the first time this question is presented. No fallback: if
  /// [VideoConversationQuizBody.enterAudioCue] is unset, nothing plays on entry.
  List<String>? get _entryAudioCue => widget.enterAudioCue;

  Future<void> _playCue(List<String> cue) async {
    final play = widget.onPlayQuestionAudio;
    if (play == null) return;
    for (final path in cue) {
      await play(path);
    }
  }

  void _playSetupAudio() {
    final cue = _entryAudioCue;
    if (cue == null || cue.isEmpty) return;
    unawaited(_playCue(cue));
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

  /// Resumes the (muted) video and plays the exit-correct clip, awaiting it in full before
  /// returning — the caller must not advance to the next question (which stops all question
  /// audio, and whose own entry audio needs the video to actually be at this question's
  /// `answer_until` when it starts, not mid-flight) until this completes, or the clip gets cut
  /// off mid-line. If there's no exit-correct clip, still holds until `answer_until` so the
  /// video gets its authored time to keep rolling forward with nothing spoken over it.
  Future<void> _resumeVideo() async {
    final controller = widget.controller;
    // AppearDisappear/recall: nothing new to show past the pause point (the muted track
    // has no fresh content), so the video stays paused — matches the wrong-answer path in
    // image_quiz_screen.dart's _waitForWrongAnswerAudio. Resuming here would let the video
    // free-run, unsupervised (no position listener attached again until the next question
    // mounts), straight into the next question's own video segment before it's ready.
    if (!_isAppearDisappear) {
      final playFuture = controller?.play().catchError((Object e, StackTrace st) {
        debugPrint(
            '[VideoConversation] controller.play() (resume) failed: $e\n$st');
      });
      if (playFuture != null) unawaited(playFuture);
    }
    final cue = widget.exitCorrectAudioCue;
    if (cue != null && cue.isNotEmpty) {
      await _playCue(cue);
      return;
    }
    if (controller == null || _isAppearDisappear) return;
    // No explicit answer_until: let the video play out to its own natural end instead of
    // cutting immediately — matters most for the last VideoConversation row in a run, where
    // there's no next question to hand off to and an abrupt cut would read as mid-sentence.
    final duration = controller.value.duration;
    final end = widget.data.answerUntil ??
        (duration > Duration.zero ? duration : widget.data.pauseAt);
    while (mounted && controller.value.position < end) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  @override
  void dispose() {
    if (_listenerAttached) {
      widget.controller?.removeListener(_onPositionChanged);
    }
    super.dispose();
  }

  Future<void> _onChoiceTap(int index) async {
    if (_choiceLocked) return;
    widget.onUserInteracted?.call();
    final correct = index == _choiceCorrectIndex;
    setState(() {
      _choiceLocked = true;
      _choiceSelectedIndex = index;
    });
    if (correct) {
      widget.onPlayCorrect();
      await _resumeVideo();
      if (!mounted) return;
      widget.onOutcome(true);
    } else {
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  Future<void> _onTileTap(int choiceIndex) async {
    if (_tileFailed ||
        _tileCompleted ||
        _listenAgainPlaying ||
        _tileUsedIndices.contains(choiceIndex)) {
      return;
    }
    widget.onUserInteracted?.call();
    final word = _tileChoices[choiceIndex];
    final expected = _tileTarget[_tapProgress];
    if (word == expected) {
      setState(() {
        _listenAgainConsumed = true;
        _tileSlots[_tapProgress] = word;
        _tileUsedIndices.add(choiceIndex);
        _tileStepOf[choiceIndex] = _tapProgress + 1;
        _tapProgress++;
        if (_tapProgress >= _tileTarget.length) _tileCompleted = true;
      });
      if (_tileCompleted) {
        widget.onPlayCorrect();
        await _resumeVideo();
        if (!mounted) return;
        widget.onOutcome(true);
      } else {
        _reportTileTarget();
      }
    } else {
      final revealedSteps = <int, int>{};
      for (var blank = _tapProgress; blank < _tileTarget.length; blank++) {
        final expectedAnswer = _tileTarget[blank];
        for (var i = 0; i < _tileChoices.length; i++) {
          if (_tileChoices[i] == expectedAnswer &&
              !_tileUsedIndices.contains(i) &&
              !revealedSteps.containsKey(i)) {
            revealedSteps[i] = blank + 1;
            break;
          }
        }
      }
      setState(() {
        _listenAgainConsumed = true;
        _tileFailed = true;
        _tileWrongIndex = choiceIndex;
        _tileRevealedStepOf.addAll(revealedSteps);
        for (var i = _tapProgress; i < _tileTarget.length; i++) {
          _tileSlots[i] = _tileTarget[i];
        }
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  Future<void> _onListenAgainTap() async {
    final cue = widget.exitCorrectAudioCue;
    final play = widget.onPlayQuestionAudio;
    if (!_showListenAgain || cue == null || cue.isEmpty || play == null) {
      return;
    }
    widget.onUserInteracted?.call();

    setState(() {
      _listenAgainConsumed = true;
      _listenAgainPlaying = true;
    });
    try {
      await _playCue(cue);
    } finally {
      if (mounted) {
        setState(() => _listenAgainPlaying = false);
        _reportTileTarget();
      }
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

  /// Same greedy row-packing as [_estimateWrapRows], but returns which row each item lands in
  /// (0-indexed) instead of just the row count — for the full-layout debug dump only.
  List<int> _estimateWrapRowAssignments({
    required List<String?> items,
    required double availableWidth,
    required double spacing,
    required double minItemWidth,
    required double horizontalPadding,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    final assignments = <int>[];
    if (items.isEmpty || availableWidth <= 0) return assignments;
    final direction = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    var row = 0;
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
        row++;
        usedWidth = itemWidth;
      } else {
        usedWidth =
            usedWidth == 0 ? itemWidth : usedWidth + spacing + itemWidth;
      }
      assignments.add(row);
    }
    return assignments;
  }

  String? _lastFullLayoutDumpKey;

  /// One-off debugging aid (developer ask): dumps every computed layout number and each
  /// tile/slot's estimated row assignment for the current build, so a full picture is visible
  /// in the console on reload without needing to reproduce a specific overflow interactively.
  void _debugDumpFullLayout({
    required double mediaHeight,
    required double mediaVisibleHeight,
    required double cascadeExtension,
    required double remainderHeight,
    required double totalShortfall,
    required _PresetResolution? slotPreset,
    required _PresetResolution? tilePreset,
    required double slotBoxHeight,
    required double tileBoxHeight,
    required double slotTileGap,
    required double listenAgainButtonHeight,
    required double listenAgainSlotsGap,
    required _VideoClozePreset? clozePreset,
    required double clozeSentenceBoxHeight,
    required double clozeTileBoxHeight,
    required double clozeSentenceTileGap,
    required double answerWidth,
  }) {
    final buffer = StringBuffer()
      ..writeln(
          '[QuestionLayout][VideoConversation][FullDump] ===== ${widget.data.choiceData != null ? 'DialogueCompletion' : widget.data.clozeData != null ? 'ClozeSequence' : _isAppearDisappear ? 'AppearDisappear' : 'SentenceBuilder'} =====')
      ..writeln(
          '  media: height=${mediaHeight.toStringAsFixed(1)} visibleHeight=${mediaVisibleHeight.toStringAsFixed(1)} cascadeExtension=${cascadeExtension.toStringAsFixed(1)}')
      ..writeln(
          '  remainderHeight=${remainderHeight.toStringAsFixed(1)} totalShortfall=${totalShortfall.toStringAsFixed(1)} answerWidth=${answerWidth.toStringAsFixed(1)}')
      ..writeln(
          '  textScale(16px)=${MediaQuery.textScalerOf(context).scale(16.0).toStringAsFixed(3)} devicePixelRatio=${MediaQuery.devicePixelRatioOf(context).toStringAsFixed(3)}');

    if (widget.data.clozeData != null && clozePreset != null) {
      buffer.writeln(
          '  cloze: sentenceBoxHeight=${clozeSentenceBoxHeight.toStringAsFixed(1)} gap=${clozeSentenceTileGap.toStringAsFixed(1)} tileBoxHeight=${clozeTileBoxHeight.toStringAsFixed(1)}');
      buffer.writeln(
          '  tilePreset: height=${tilePreset?.height.toStringAsFixed(1)} fontSize=${tilePreset?.fontSize.toStringAsFixed(1)} rows=${tilePreset?.rows} shortfall=${tilePreset?.shortfallHeight.toStringAsFixed(1)}');
      final metrics = _videoTileCellMetrics(tilePreset!.height);
      final rowsOf = _estimateWrapRowAssignments(
        items: _tileChoices,
        availableWidth: answerWidth - 24.0,
        spacing: _videoRowGap(tilePreset.height),
        minItemWidth: metrics.minWidth,
        horizontalPadding: metrics.horizontalPadding,
        fontSize: tilePreset.fontSize,
        fontWeight: FontWeight.w600,
      );
      for (var i = 0; i < _tileChoices.length; i++) {
        buffer.writeln(
            '    tile[$i] "${_tileChoices[i]}" -> row ${rowsOf.length > i ? rowsOf[i] : '?'}');
      }
    } else if (widget.data.choiceData != null) {
      for (var i = 0; i < _choiceOptions.length; i++) {
        buffer.writeln('    option[$i] "${_choiceOptions[i]}"');
      }
    } else if (slotPreset != null && tilePreset != null) {
      buffer.writeln(
          '  listenAgain: buttonHeight=${listenAgainButtonHeight.toStringAsFixed(1)} slotsGap=${listenAgainSlotsGap.toStringAsFixed(1)} shown=$_showListenAgain');
      buffer.writeln(
          '  slot: boxHeight=${slotBoxHeight.toStringAsFixed(1)} height=${slotPreset.height.toStringAsFixed(1)} fontSize=${slotPreset.fontSize.toStringAsFixed(1)} rows=${slotPreset.rows} shortfall=${slotPreset.shortfallHeight.toStringAsFixed(1)}');
      buffer.writeln('  slotTileGap=${slotTileGap.toStringAsFixed(1)}');
      buffer.writeln(
          '  tile: boxHeight=${tileBoxHeight.toStringAsFixed(1)} height=${tilePreset.height.toStringAsFixed(1)} fontSize=${tilePreset.fontSize.toStringAsFixed(1)} rows=${tilePreset.rows} shortfall=${tilePreset.shortfallHeight.toStringAsFixed(1)}');
      final slotMetrics = _videoTileCellMetrics(slotPreset.height);
      final slotRowsOf = _estimateWrapRowAssignments(
        items: List<String?>.from(_tileTarget),
        availableWidth: answerWidth - 24.0,
        spacing: _videoRowGap(slotPreset.height),
        minItemWidth: slotMetrics.minWidth,
        horizontalPadding: slotMetrics.horizontalPadding,
        fontSize: slotPreset.fontSize,
        fontWeight: FontWeight.w800,
      );
      for (var i = 0; i < _tileTarget.length; i++) {
        buffer.writeln(
            '    slot[$i] target="${_tileTarget[i]}" -> row ${slotRowsOf.length > i ? slotRowsOf[i] : '?'}');
      }
      final tileMetrics = _videoTileCellMetrics(tilePreset.height);
      final tileRowsOf = _estimateWrapRowAssignments(
        items: _tileChoices,
        availableWidth: answerWidth - 24.0,
        spacing: _videoRowGap(tilePreset.height),
        minItemWidth: tileMetrics.minWidth,
        horizontalPadding: tileMetrics.horizontalPadding,
        fontSize: tilePreset.fontSize,
        fontWeight: FontWeight.w600,
      );
      for (var i = 0; i < _tileChoices.length; i++) {
        buffer.writeln(
            '    tile[$i] "${_tileChoices[i]}" -> row ${tileRowsOf.length > i ? tileRowsOf[i] : '?'}');
      }
    }

    final key = buffer.toString();
    if (_lastFullLayoutDumpKey == key) return;
    _lastFullLayoutDumpKey = key;
    debugPrint(key);
  }

  _PresetResolution _resolvePreset({
    required List<String?> items,
    required List<_RowPreset> presets,
    required double availableWidth,
    required double availableHeight,
    required FontWeight fontWeight,
    double? fixedHeight,
    double? fixedFontSize,
  }) {
    if (fixedHeight != null && fixedFontSize != null) {
      final metrics = _videoTileCellMetrics(fixedHeight);
      final rows = _estimateWrapRows(
        items: items,
        availableWidth: availableWidth,
        spacing: _videoRowGap(fixedHeight),
        minItemWidth: metrics.minWidth,
        horizontalPadding: metrics.horizontalPadding,
        fontSize: fixedFontSize,
        fontWeight: fontWeight,
      );
      final needed =
          rows * fixedHeight + (rows - 1) * _videoRowGap(fixedHeight);
      return (
        height: fixedHeight,
        fontSize: fixedFontSize,
        rows: rows,
        shortfallHeight: max(0.0, needed - availableHeight),
      );
    }
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

  ({double height, int lines}) _measureClozeSentence(
    String sentence,
    double fontSize,
    double availableWidth,
  ) {
    if (sentence.isEmpty || availableWidth <= 0) {
      return (height: 0.0, lines: 0);
    }
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
    return (
      height: painter.height,
      lines: max(1, painter.computeLineMetrics().length),
    );
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
        final answerWidth =
            layoutBudget.answerWidthForAvailable(bodyConstraints.maxWidth);
        final remainderHeight =
            max(0.0, bodyConstraints.maxHeight - mediaHeight);

        // Compute shortfalls and cascade extension per answer type
        var totalShortfall = 0.0;
        var buttonHeight = 48.0;
        var buttonFontSize = 15.0;
        var buttonGap = 10.0;
        final listenAgainButtonHeight =
            _listenAgainButtonHeightFor(layoutBudget);
        final listenAgainButtonWidth =
            _listenAgainButtonWidthFor(layoutBudget, answerWidth);

        _PresetResolution? slotPreset;
        _PresetResolution? tilePreset;
        _VideoClozePreset? clozePreset;
        var slotBoxHeight = 0.0;
        var tileBoxHeight = 0.0;
        var slotTileGap = 0.0;
        var listenAgainSlotsGap = 0.0;
        var clozeSentenceHeight = 0.0;
        var clozeSentenceLines = 0;
        var clozeSentenceBoxHeight = 0.0;
        var clozeTileBoxHeight = 0.0;
        var clozeSentenceTileGap = 0.0;

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
            final sentenceMeasurement = _measureClozeSentence(
              widget.data.clozeData!.sentence,
              questionSentenceTextSizeFor(layoutBudget.tier),
              answerWidth,
            );
            clozeSentenceHeight = sentenceMeasurement.height;
            clozeSentenceLines = sentenceMeasurement.lines;
            final answerContentHeight = max(0.0, remainderHeight - 16.0);

            // Resolve rows from width first. The final height budgets are reduced by the
            // responsive sentence-to-tile gap after the row permutation is known.
            final initialTilePreset = _resolvePreset(
              items: _tileChoices,
              presets: clozePreset.tilePresets,
              availableWidth: answerWidth - 24.0,
              availableHeight: answerContentHeight * 0.55,
              fontWeight: FontWeight.w600,
              fixedHeight: questionTileHeightFor(layoutBudget),
              fixedFontSize: questionTileTextSizeFor(layoutBudget.tier),
            );
            final gapFraction = _videoClozeGapFraction(
              layoutBudget.tier,
              sentenceLines: clozeSentenceLines,
              tileRows: initialTilePreset.rows,
            );
            clozeSentenceTileGap = answerContentHeight * gapFraction;
            final boxedRemainder =
                max(0.0, answerContentHeight - clozeSentenceTileGap);
            final clozeBudget = boxedRemainder * 0.45;
            final tileBudget = boxedRemainder * 0.55;

            tilePreset = _resolvePreset(
              items: _tileChoices,
              presets: clozePreset.tilePresets,
              availableWidth: answerWidth - 24.0,
              availableHeight: tileBudget,
              fontWeight: FontWeight.w600,
              fixedHeight: questionTileHeightFor(layoutBudget),
              fixedFontSize: questionTileTextSizeFor(layoutBudget.tier),
            );
            final tileHeight = tilePreset.rows * tilePreset.height +
                max(0, tilePreset.rows - 1) * _videoRowGap(tilePreset.height);

            // Multi-line/multi-row content gets a box and is centered inside it. Sparse content
            // stays intrinsic so the responsive gap can use the otherwise empty vertical space.
            clozeSentenceBoxHeight = clozeSentenceLines >= 2
                ? max(clozeBudget, clozeSentenceHeight)
                : clozeSentenceHeight;
            clozeTileBoxHeight =
                tilePreset.rows >= 2 ? max(tileBudget, tileHeight) : tileHeight;
            totalShortfall = max(
              0.0,
              clozeSentenceBoxHeight +
                  clozeSentenceTileGap +
                  clozeTileBoxHeight -
                  answerContentHeight,
            );

            if (tilePreset.rows > 2) {
              debugPrint(
                '[QuestionLayout][VideoConversation][Warning] cloze tiles exceeded nominal 2-row cap (rows=${tilePreset.rows}).',
              );
            }
          } else {
            // Sequence / SentenceBuilder / AppearDisappear
            final answerContentHeight = max(0.0, remainderHeight - 16.0);
            listenAgainSlotsGap = _showListenAgain
                ? _listenAgainSlotsGapFor(
                    layoutBudget,
                    max(0.0, answerContentHeight - listenAgainButtonHeight),
                  )
                : 0.0;
            final listenAgainBlockHeight = _showListenAgain
                ? listenAgainButtonHeight + listenAgainSlotsGap
                : 0.0;
            final sequenceRemainderHeight =
                max(0.0, answerContentHeight - listenAgainBlockHeight);
            final initialSlotPreset = _resolvePreset(
              items: List<String?>.from(_tileTarget),
              presets: _videoSlotPresets[layoutBudget.tier]!,
              availableWidth: answerWidth - 24.0,
              availableHeight: sequenceRemainderHeight * 0.38,
              fontWeight: FontWeight.w800,
              fixedHeight: questionSlotHeightFor(layoutBudget),
              fixedFontSize: questionSlotTextSizeFor(layoutBudget.tier),
            );
            final initialTilePreset = _resolvePreset(
              items: _tileChoices,
              presets: _videoTilePresets[layoutBudget.tier]!,
              availableWidth: answerWidth - 24.0,
              availableHeight: sequenceRemainderHeight * 0.62,
              fontWeight: FontWeight.w600,
              fixedHeight: questionTileHeightFor(layoutBudget),
              fixedFontSize: questionTileTextSizeFor(layoutBudget.tier),
            );
            final interactionGapFraction = _isAppearDisappear
                ? _videoClozeGapFraction(
                    layoutBudget.tier,
                    sentenceLines: initialSlotPreset.rows,
                    tileRows: initialTilePreset.rows,
                  )
                : _videoSentenceBuilderGapFraction(
                    layoutBudget.tier,
                    slotRows: initialSlotPreset.rows,
                    tileRows: initialTilePreset.rows,
                  );
            slotTileGap = sequenceRemainderHeight * interactionGapFraction;
            final boxedRemainder =
                max(0.0, sequenceRemainderHeight - slotTileGap);
            final slotBudget = boxedRemainder * 0.38;
            final tileBudget = boxedRemainder * 0.62;

            slotPreset = _resolvePreset(
              items: List<String?>.from(_tileTarget),
              presets: _videoSlotPresets[layoutBudget.tier]!,
              availableWidth: answerWidth - 24.0,
              availableHeight: slotBudget,
              fontWeight: FontWeight.w800,
              fixedHeight: questionSlotHeightFor(layoutBudget),
              fixedFontSize: questionSlotTextSizeFor(layoutBudget.tier),
            );
            tilePreset = _resolvePreset(
              items: _tileChoices,
              presets: _videoTilePresets[layoutBudget.tier]!,
              availableWidth: answerWidth - 24.0,
              availableHeight: tileBudget,
              fontWeight: FontWeight.w600,
              fixedHeight: questionTileHeightFor(layoutBudget),
              fixedFontSize: questionTileTextSizeFor(layoutBudget.tier),
            );
            final slotHeight = slotPreset.rows * slotPreset.height +
                max(0, slotPreset.rows - 1) * _videoRowGap(slotPreset.height);
            final tileHeight = tilePreset.rows * tilePreset.height +
                max(0, tilePreset.rows - 1) * _videoRowGap(tilePreset.height);
            slotBoxHeight =
                slotPreset.rows >= 2 ? max(slotBudget, slotHeight) : slotHeight;
            tileBoxHeight =
                tilePreset.rows >= 2 ? max(tileBudget, tileHeight) : tileHeight;
            totalShortfall = max(
              0.0,
              listenAgainBlockHeight +
                  slotBoxHeight +
                  slotTileGap +
                  tileBoxHeight -
                  answerContentHeight,
            );

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

        if (_paused) {
          _debugDumpFullLayout(
            mediaHeight: mediaHeight,
            mediaVisibleHeight: mediaVisibleHeight,
            cascadeExtension: cascadeExtension,
            remainderHeight: remainderHeight,
            totalShortfall: totalShortfall,
            slotPreset: slotPreset,
            tilePreset: tilePreset,
            slotBoxHeight: slotBoxHeight,
            tileBoxHeight: tileBoxHeight,
            slotTileGap: slotTileGap,
            listenAgainButtonHeight: listenAgainButtonHeight,
            listenAgainSlotsGap: listenAgainSlotsGap,
            clozePreset: clozePreset,
            clozeSentenceBoxHeight: clozeSentenceBoxHeight,
            clozeTileBoxHeight: clozeTileBoxHeight,
            clozeSentenceTileGap: clozeSentenceTileGap,
            answerWidth: answerWidth,
          );
        }

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
                                    sentenceFontSize:
                                        questionSentenceTextSizeFor(
                                            layoutBudget.tier),
                                    sentenceLines: clozeSentenceLines,
                                    sentenceBoxHeight: clozeSentenceBoxHeight,
                                    tileBoxHeight: clozeTileBoxHeight,
                                    sentenceTileGap: clozeSentenceTileGap,
                                  )
                                : _buildSequencePanel(
                                    context: context,
                                    slotPreset: slotPreset!,
                                    tilePreset: tilePreset!,
                                    answerWidth: answerWidth,
                                    listenAgainButtonHeight:
                                        listenAgainButtonHeight,
                                    listenAgainButtonWidth:
                                        listenAgainButtonWidth,
                                    slotBoxHeight: slotBoxHeight,
                                    tileBoxHeight: tileBoxHeight,
                                    slotTileGap: slotTileGap,
                                    listenAgainSlotsGap: listenAgainSlotsGap,
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
    required double sentenceFontSize,
    required int sentenceLines,
    required double sentenceBoxHeight,
    required double tileBoxHeight,
    required double sentenceTileGap,
  }) {
    final theme = Theme.of(context);
    final tileMetrics = _videoTileCellMetrics(tilePreset.height);
    final tileRowGap = _videoRowGap(tilePreset.height);
    final sentence = Text.rich(
      TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: sentenceFontSize,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        children: _buildClozeSentenceSpans(theme, cloze, sentenceFontSize),
      ),
      textAlign: TextAlign.center,
    );
    final tiles = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: tileRowGap,
      runSpacing: tileRowGap,
      children: List.generate(_tileChoices.length, (i) {
        return _buildTile(
          i,
          fontSize: tilePreset.fontSize,
          height: tilePreset.height,
          metrics: tileMetrics,
        );
      }),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sentenceLines >= 2
            ? SizedBox(
                height: sentenceBoxHeight,
                child: Center(child: sentence),
              )
            : sentence,
        SizedBox(height: sentenceTileGap),
        tilePreset.rows >= 2
            ? SizedBox(
                height: tileBoxHeight,
                child: Center(child: tiles),
              )
            : tiles,
      ],
    );
  }

  Widget _buildSequencePanel({
    required BuildContext context,
    required _PresetResolution slotPreset,
    required _PresetResolution tilePreset,
    required double answerWidth,
    required double listenAgainButtonHeight,
    required double listenAgainButtonWidth,
    required double slotBoxHeight,
    required double tileBoxHeight,
    required double slotTileGap,
    required double listenAgainSlotsGap,
  }) {
    final slotMetrics = _videoTileCellMetrics(slotPreset.height);
    final tileMetrics = _videoTileCellMetrics(tilePreset.height);
    final slotGap = _videoRowGap(slotPreset.height);
    final tileGap = _videoRowGap(tilePreset.height);
    final slots = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: slotGap,
      runSpacing: slotGap,
      children: List.generate(_tileTarget.length, (i) {
        final word = _listenAgainPlaying ? _tileTarget[i] : _tileSlots[i];
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
    );
    final tiles = Wrap(
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
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showListenAgain) ...[
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: listenAgainButtonWidth,
              height: listenAgainButtonHeight,
              child: ElevatedButton(
                onPressed: _onListenAgainTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AnswerPalette.correctBorder,
                  foregroundColor: Colors.white,
                  minimumSize: Size(48, listenAgainButtonHeight),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: const StadiumBorder(),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('listen again'),
              ),
            ),
          ),
          SizedBox(height: listenAgainSlotsGap),
        ],
        slotPreset.rows >= 2
            ? SizedBox(
                height: slotBoxHeight,
                child: Center(child: slots),
              )
            : slots,
        SizedBox(height: slotTileGap),
        tilePreset.rows >= 2
            ? SizedBox(
                height: tileBoxHeight,
                child: Center(child: tiles),
              )
            : tiles,
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
    final disabled = _tileFailed ||
        _tileCompleted ||
        _listenAgainPlaying ||
        _tileUsedIndices.contains(index);
    final isWrong = _tileFailed && _tileWrongIndex == index;
    final isCorrectTile = _tileUsedIndices.contains(index);
    final isRevealed = _tileRevealedStepOf.containsKey(index);
    final step = isCorrectTile
        ? _tileStepOf[index]
        : _tileRevealedStepOf[index];

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
    } else if (isRevealed) {
      bg = AnswerPalette.revealedBg;
      border = AnswerPalette.revealedBorder;
      fg = AnswerPalette.revealedFg;
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
              if ((isCorrectTile || isRevealed || isWrong) && step != null)
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
}
