import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../models/level_config.dart';
import '../../utils/cloze_blank.dart';
import '../../widgets/answer_palette.dart';
import '../../widgets/mcq_pill_answer_button.dart';

/// DEBUG ONLY. Flip to `true` to bypass all question-pausing and just let the shared
/// [VideoPlayerController] play straight through to the end of the file — no answer panel
/// ever appears, the level just sits on the first `VideoConversation` question while the
/// video (hopefully) keeps running to completion. Use this to isolate whether a playback
/// stall is coming from our own pause/seek/resume logic or from the `video_player` plugin
/// itself: if it still stalls with this on, the bug is in the plugin/platform, not our code.
/// Logs position once per second to the console so a stall is visible without watching the
/// screen. Must be `false` before shipping.
const bool kDebugPlayVideoConversationToEndWithoutPausing = false;

/// Plays `[data.startAt, data.pauseAt]` of the level's shared video, pauses right at
/// [VideoConversationQuestionData.pauseAt], then renders whichever of [VideoConversationQuestionData.choiceData]
/// / [VideoConversationQuestionData.sequenceData] / [VideoConversationQuestionData.clozeData] is set as the
/// answer panel. Correct answer resumes playback (the next line plays as confirmation and doubles as the
/// lead-in to the next `VideoConversation` row); wrong answer locks the panel and leaves the video paused,
/// mirroring every other convo template's `onOutcome`/Next-button contract.
///
/// [controller] is owned by the parent screen and shared across every `VideoConversation` row in the
/// level (one asset, one decoder) rather than being created fresh per question — consecutive rows chain
/// `start_at(N+1) == pause_at(N)`, so the same controller just keeps playing straight through each
/// question-widget swap instead of stuttering on a fresh re-init every round. Null means the asset
/// couldn't be resolved; the widget then skips straight to the answer panel with no video.
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
  });

  final VideoConversationQuestionData data;
  final VideoPlayerController? controller;

  /// True when the previous question used the same shared video controller.
  /// Continuation rows must not seek, since browser video seeking may land on an
  /// earlier keyframe and replay the previous line.
  final bool continueExistingPlayback;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  /// Audio for the line(s) spoken during `[data.startAt, data.pauseAt]` — played in parallel
  /// with the (now permanently muted) video as it plays that segment, since the embedded track
  /// can't be trusted to stop precisely at a runtime pause point without bleeding into the next
  /// line. Null means this question has no separately-extracted setup clip yet (silent for now).
  final String? setupAudioPath;

  /// Audio for the confirmation line spoken after a correct answer, played in parallel with the
  /// video resuming. Null for answer types with nothing to confirm (e.g. `AppearDisappear`,
  /// where the line was already heard during the setup clip) or not yet extracted.
  final String? confirmAudioPath;

  /// Required whenever [setupAudioPath]/[confirmAudioPath] are non-null.
  final Future<void> Function(String path)? onPlayQuestionAudio;
  final Future<void> Function(String path)? onStartQuestionAudio;
  final Future<void> Function()? waitForTutorial;

  /// Optional, purely additive: fires once, the first time the choice buttons (answer_type
  /// `DialogueCompletion`) actually render, with the index of the correct option and a
  /// [GlobalKey] per button so a caller (the tutorial overlay) can measure exactly where the
  /// correct button is on screen. Never fires for other answer_types (nothing to report). Does
  /// not affect scoring, locking, or any other existing behavior — purely a read of already-public
  /// render info, reported outward.
  final void Function(int correctIndex, List<GlobalKey> buttonKeys)?
      onChoiceButtonsRendered;

  /// Optional, purely additive: mirrors [onChoiceButtonsRendered] but for the tile-based answer
  /// types (`SentenceBuilder` / `AppearDisappear` / `ClozeSequence`) — fires once, the first time
  /// the tile-choice grid renders, with the index (within [tileKeys]) of the first tile the
  /// learner needs to tap and a [GlobalKey] per tile.
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
  int? _debugLastLoggedSecond;

  // Choice-panel state (answer_type: DialogueCompletion).
  late List<String> _choiceOptions;
  int? _choiceCorrectIndex;
  int? _choiceSelectedIndex;
  bool _choiceLocked = false;
  List<GlobalKey> _choiceButtonKeys = const [];
  bool _reportedChoiceButtons = false;

  // Shared tap-in-order tile state (answer_type: SentenceBuilder / AppearDisappear / ClozeSequence).
  List<String> _tileTarget = const [];
  List<String> _tileChoices = const [];
  List<GlobalKey> _tileChoiceKeys = const [];
  int _tapProgress = 0;
  List<String?> _tileSlots = const [];
  final Set<int> _tileUsedIndices = {};
  final Map<int, int> _tileStepOf = {};
  int? _tileWrongIndex;
  bool _tileFailed = false;
  bool _tileCompleted = false;

  @override
  void initState() {
    super.initState();
    _initAnswerState();
    _reportTileTarget();
    _attachAndPlay();
  }

  /// Reports the next tile the learner needs to tap to [widget.onNextTileRendered], keyed off
  /// [_tapProgress] — called again after every correct tap (mirroring the standalone
  /// `SentenceBuilderQuizBody`/`AppearDisappearQuizBody`'s `_reportNextTile()`) so the guide's
  /// hand actually advances tile-by-tile instead of freezing on the first one. No-op once the
  /// sequence is complete/failed (the outcome callback ends this question either way).
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
    } else if (d.sequenceData != null) {
      _tileTarget = d.sequenceData!.targetSentence.split(' ');
      _tileChoices = [..._tileTarget, ...d.sequenceData!.distractors]
        ..shuffle(Random());
      _tileSlots = List<String?>.filled(_tileTarget.length, null);
      _tileChoiceKeys = List.generate(_tileChoices.length, (_) => GlobalKey());
    } else if (d.clozeData != null) {
      _tileTarget = d.clozeData!.answers;
      _tileChoices = [...d.clozeData!.answers, ...d.clozeData!.distractors]
        ..shuffle(Random());
      _tileSlots = List<String?>.filled(_tileTarget.length, null);
      _tileChoiceKeys = List.generate(_tileChoices.length, (_) => GlobalKey());
    }
  }

  /// Attaches to the parent-owned [widget.controller]. Only seeks when the controller's current
  /// position is genuinely *behind* [VideoConversationQuestionData.startAt] (a fresh/cold controller,
  /// e.g. the very first question) — on the normal chained-continuation path the controller has
  /// already played past `startAt` on its own (it kept playing during the auto-advance delay between
  /// questions), and seeking backward there would rewind and restart playback mid-stream, which can
  /// leave some `video_player` backends stuck never resuming (previously always seeking on any drift
  /// caused exactly this: the question got permanently stuck on the loading spinner). Any failure
  /// (missing/corrupt asset, decoder error) falls back to showing the answer panel immediately rather
  /// than leaving the question stuck.
  Future<void> _attachAndPlay() async {
    final controller = widget.controller;
    if (widget.waitForTutorial != null) {
      // Consecutive video questions share a controller. Stop it before showing
      // the blocking guide so the next line cannot play underneath the guide.
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
      // Show the (paused) first frame before starting playback, so audio doesn't start before
      // anything is visible on screen. Deliberately a fixed timer, not `endOfFrame`: on the
      // continuing-playback path (question 2+) neither await above actually suspends (already
      // initialized, already past startAt), so this runs synchronously inside initState with
      // nothing else in the convo phase requesting a new frame — `endOfFrame` waited on a frame
      // that might never get scheduled and hung forever (this is what caused the freeze). A
      // timer always resolves regardless of frame scheduling.
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      controller.addListener(_onPositionChanged);
      _listenerAttached = true;
      // Only call play() if it isn't already playing — on the continuing-playback path
      // (question 2+), the previous question's correct-answer resume already started it, and a
      // redundant play() call here on video_player_web has been observed to reset position back
      // toward the start instead of being a harmless no-op like it is on native platforms.
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

  /// Fire-and-forget: plays [widget.setupAudioPath] in parallel with the (muted) video as it
  /// plays `[data.startAt, data.pauseAt]`. No-op if there's no clip for this question yet.
  void _playSetupAudio() {
    final path = widget.setupAudioPath;
    final play = widget.onPlayQuestionAudio;
    if (path == null || play == null) return;
    play(path);
  }

  /// Fire-and-forget: plays [widget.confirmAudioPath] in parallel with the video resuming after
  /// a correct answer. No-op if there's no clip for this question yet (e.g. `AppearDisappear`,
  /// where the line was already heard during the setup clip).
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
      // Stop listening before our own pause/seek below — we don't need further position
      // notifications for this question, and it avoids any re-entrant calls while we're
      // mid-transition (on top of the _pauseHandled guard above).
      controller.removeListener(_onPositionChanged);
      _listenerAttached = false;
      _pauseThenReveal(controller);
    }
  }

  /// Pauses at the (possibly slightly overshot) crossing point. Deliberately does **not** also
  /// `seekTo(target)` to correct that overshoot — a prior version did, but on the web platform
  /// `video_player_web`'s `seekTo()` Future can resolve before the browser has actually finished
  /// applying the seek internally (it doesn't reliably wait for the native `seeked` event). That
  /// gave false confidence: we'd think playback was parked exactly at `target`, but the browser
  /// might not have committed the seek yet, and the subsequent `play()` (on tapping an answer)
  /// could then resume from a stale position — observed in practice as full lines replaying from
  /// the start of the video instead of continuing from the pause point. A little overshoot bleed
  /// into the next line's audio (mitigated at the data level via tight `pause_at` tuning in
  /// questions.json) is a smaller problem than that. Still awaits `pause()` itself before
  /// revealing the answer panel, so a fast tap can't call `play()` while pause is still in flight.
  Future<void> _pauseThenReveal(VideoPlayerController controller) async {
    try {
      await controller.pause();
    } catch (e, st) {
      debugPrint('[VideoConversation] pause failed: $e\n$st');
    }
    if (mounted) {
      setState(() => _paused = true);
      // Call directly, not wrapped in another addPostFrameCallback: `_reportTileTarget()`
      // already schedules its own single post-frame callback internally. Wrapping it in a
      // second one here meant the actual report only fired on some *later* frame — and since
      // nothing else in this phase (video paused, nothing animating) requests a new frame, it
      // could sit pending indefinitely until an unrelated event (e.g. a mouse-move hover
      // repaint) happened to trigger one. That's why the guide hand only appeared after
      // dragging the mouse instead of right when the video paused.
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
    if (_listenerAttached)
      widget.controller?.removeListener(_onPositionChanged);
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final hasVideo = controller != null && controller.value.isInitialized;
    // Sized from the video's own aspect ratio (whatever the source file actually is) rather
    // than a hard-coded guess, so a 16:9 clip today or a square/portrait one later both come
    // out right with no layout change. Before the controller reports its real ratio, assume
    // square for the loading placeholder — closer to most conversation clips than 16:9 and
    // avoids a visible reflow the instant the real video attaches.
    final aspectRatio = hasVideo ? controller.value.aspectRatio : 1.0;
    // 87% of screen width on a phone, but capped at 560pt so it doesn't keep growing on a
    // tablet — full-bleed-style buttons at ~87% of an iPad's width would turn into oversized
    // horizontal pills with the same (phone-sized) font, not a genuinely tablet-tuned layout.
    // Capping here at least keeps proportions sane; typography and the tutorial guide remain
    // separate concerns from the media profile calculated below.
    final answerPanelWidth = min(
      MediaQuery.sizeOf(context).width * 0.87,
      560.0,
    );
    return LayoutBuilder(
      builder: (context, bodyConstraints) {
        final viewport = MediaQuery.sizeOf(context);
        final isTablet = viewport.shortestSide >= 600;

        // One deterministic media box per viewport profile. It deliberately does not inspect
        // the current answer type or item count, so DialogueCompletion, SentenceBuilder,
        // AppearDisappear, and ClozeSequence cannot make the continuous video jump in size
        // between questions.
        //
        // Phones aim for the full width available inside the page padding and stop at 45% of
        // the full viewport height. Tablets use a centered 80%-width column, may use up to 55%
        // of viewport height, and stop growing at 700 logical pixels. Both profiles reserve the
        // normal four-choice answer stack (4 x 52 plus 3 x 12, with a small top allowance)
        // before assigning height to media. If an exceptionally short viewport cannot provide
        // both that reserve and the media floor, the media floor wins and the existing answer
        // scroller remains the final safety valve.
        final widthFraction = isTablet ? 0.80 : 1.0;
        final heightFraction = isTablet ? 0.55 : 0.45;
        final widthLimit = bodyConstraints.maxWidth * widthFraction;
        final viewportHeightLimit = viewport.height * heightFraction;
        final absoluteHeightLimit = isTablet ? 700.0 : double.infinity;
        final compactActionRegion = viewport.height < 900 ||
            MediaQuery.textScalerOf(context).scale(16) > 16.01;
        // A compact action region returns 16px to this body. Add that gain to the answer reserve
        // so the video cannot consume it and grow; the reclaimed height belongs to buttons,
        // tiles, and the sentence/slot region.
        final normalAnswerReserve = 252.0 + (compactActionRegion ? 16.0 : 0.0);
        const mediaAnswerGap = 4.0;
        final budgetHeightLimit = bodyConstraints.maxHeight.isFinite
            ? max(
                0.0,
                bodyConstraints.maxHeight -
                    normalAnswerReserve -
                    mediaAnswerGap)
            : double.infinity;
        final mediaFloor = isTablet ? 280.0 : 180.0;
        final effectiveBudgetLimit =
            budgetHeightLimit < mediaFloor ? mediaFloor : budgetHeightLimit;

        var videoWidth = widthLimit;
        var videoHeight = videoWidth / aspectRatio;
        final heightLimit = min(
          min(viewportHeightLimit, absoluteHeightLimit),
          effectiveBudgetLimit,
        );
        if (videoHeight > heightLimit) {
          videoHeight = heightLimit;
          videoWidth = videoHeight * aspectRatio;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: videoWidth,
                  height: videoHeight,
                  child: hasVideo
                      ? VideoPlayer(controller)
                      : ColoredBox(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                ),
              ),
            ),
            if (_paused) ...[
              // The instructional CTA is provided by the tutorial guide. Keep
              // the answer area directly below the video so the tiles/buttons get
              // the vertical space previously occupied by the repeated prompt.
              // The only Expanded left in this Column, so it claims all height the (intrinsically
              // sized) video and prompt above didn't use. Content sizes itself (min-height buttons,
              // up to 2 lines of text) rather than a height computed by dividing available space —
              // that division assumed 1-line English text, which breaks for longer translations or a
              // larger system font-scale setting. Top-aligned + scrollable is the fallback for
              // whatever that content doesn't fit, instead of clipping or overflowing.
              Expanded(
                child: Container(
                  color: Colors.white,
                  // LayoutBuilder wraps SingleChildScrollView, not the other way round:
                  // SingleChildScrollView gives its child unbounded constraints along the scroll
                  // axis (it needs the child's natural size to know how much there is to scroll),
                  // so a LayoutBuilder placed *inside* it would read maxHeight as infinite — feeding
                  // that into ConstrainedBox(minHeight: ...) below would force infinite height
                  // instead of "fill the real available space." Capturing the real, bounded height
                  // out here first and only applying it inside the scroll view is what makes
                  // fill-when-short-but-scroll-when-tall actually work.
                  child: LayoutBuilder(
                    builder: (context, answerConstraints) {
                      final content = widget.data.choiceData != null
                          ? _buildChoicePanel()
                          : _buildTilePanel(
                              context,
                              cloze: widget.data.clozeData,
                            );
                      return SingleChildScrollView(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: answerPanelWidth,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: answerConstraints.maxHeight,
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
            ],
          ],
        );
      },
    );
  }

  /// MCQ buttons — see [McqPillAnswerButton] for why they're sized by content, not by dividing
  /// available space by the option count.
  Widget _buildChoicePanel() {
    if (!_reportedChoiceButtons && widget.onChoiceButtonsRendered != null) {
      _reportedChoiceButtons = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _choiceCorrectIndex == null) return;
        widget.onChoiceButtonsRendered!(
            _choiceCorrectIndex!, _choiceButtonKeys);
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
            bottom: i == _choiceOptions.length - 1 ? 0 : 12,
          ),
          child: McqPillAnswerButton(
            label: _choiceOptions[i],
            state: state,
            onTap: _choiceLocked ? null : () => _onChoiceTap(i),
          ),
        );
      }),
    );
  }

  /// Renders [cloze]'s sentence with each blank token replaced inline by its slot's current
  /// content (from [_tileSlots]) — underscores while empty, the tapped word in green once
  /// filled, or (once [_tileFailed]) the correct word for every still-empty blank shown in
  /// orange, mirroring the standalone `ClozeSequenceQuizBody`'s `_buildSentenceSpans`. Replaces
  /// the old plain-text sentence + separate tile-slot row, which visually disconnected the
  /// answer from where it actually belongs in the sentence.
  List<InlineSpan> _buildClozeSentenceSpans(
      ThemeData theme, VideoClozeAnswerData cloze) {
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
            // Revealed correct answers remain green; red is reserved for the
            // distractor tile that the learner selected incorrectly.
            color: AnswerPalette.correctFg,
            fontWeight: FontWeight.w700,
            fontStyle: userFilled ? null : FontStyle.italic,
          );
        } else {
          blankText = '_____';
          blankStyle =
              TextStyle(color: cs.primary, fontStyle: FontStyle.italic);
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

  Widget _buildTilePanel(BuildContext context, {VideoClozeAnswerData? cloze}) {
    final theme = Theme.of(context);
    // Adaptive on content volume, not on answer_type or video size: the video stays the same
    // size across every question in a level regardless of which one is showing (it's one
    // continuous asset chained across consecutive rows — resizing it per-question would make
    // playback visibly jump in size question to question, which is worse than a tighter tile
    // grid). A question with a long word-bank *and* a large tile-choice set (recall-type
    // AppearDisappear rounds especially) genuinely needs more of the shared space than a short
    // one — so only the tiles/word-bank compact themselves, and only when there's enough content
    // to actually warrant it.
    final itemCount = _tileTarget.length + _tileChoices.length;
    final compact = itemCount > 8;
    final slotHeight = compact ? 30.0 : 36.0;
    final slotPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 6);
    final tileMinHeight = compact ? 40.0 : 52.0;
    final tileMaxHeight = compact ? 52.0 : 68.0;
    final tilePadding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    final wrapSpacing = compact ? 6.0 : 8.0;
    final tileTextStyle =
        compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cloze != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyLarge,
                children: _buildClozeSentenceSpans(theme, cloze),
              ),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_tileTarget.length, (i) {
              final word = _tileSlots[i];
              final filled = word != null;
              final slot = AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: slotHeight,
                width: filled ? null : 56,
                padding: slotPadding,
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
                          style: tileTextStyle?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AnswerPalette.correctFg,
                          ),
                        ),
                ),
              );
              return word == null ? slot : IntrinsicWidth(child: slot);
            }),
          ),
          SizedBox(height: compact ? 8 : 12),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: wrapSpacing,
          runSpacing: wrapSpacing,
          children: List.generate(_tileChoices.length, (i) {
            final word = _tileChoices[i];
            final disabled =
                _tileFailed || _tileCompleted || _tileUsedIndices.contains(i);
            final isWrong = _tileFailed && _tileWrongIndex == i;
            final isCorrectTile = _tileUsedIndices.contains(i);
            final step = _tileStepOf[i];
            var tileBg = AnswerPalette.neutralBg;
            var tileBorder = AnswerPalette.neutralBorder;
            var tileFg = AnswerPalette.neutralFg;
            if (isWrong) {
              tileBg = AnswerPalette.wrongBg;
              tileBorder = AnswerPalette.wrongBorder;
              tileFg = AnswerPalette.wrongFg;
            } else if (isCorrectTile) {
              tileBg = AnswerPalette.correctBg;
              tileBorder = AnswerPalette.correctBorder;
              tileFg = AnswerPalette.correctFg;
            }
            return Material(
              key: _tileChoiceKeys.length > i ? _tileChoiceKeys[i] : null,
              color: tileBg,
              shape: StadiumBorder(side: BorderSide(color: tileBorder)),
              child: InkWell(
                onTap: disabled ? null : () => _onTileTap(i),
                customBorder:
                    StadiumBorder(side: BorderSide(color: tileBorder)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 72,
                    minHeight: tileMinHeight,
                    maxHeight: tileMaxHeight,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: tilePadding,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isWrong) ...[
                              Icon(Icons.close, size: 14, color: tileBorder),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              word,
                              textAlign: TextAlign.center,
                              style: tileTextStyle?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: tileFg,
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
          }),
        ),
      ],
    );
  }
}
