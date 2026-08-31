import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../app_flavor.dart';
import '../../models/guest_animal_conversations.dart';
import '../../models/level_completion_result.dart';
import '../../models/level_config.dart';
import '../../models/level_translations.dart';
import '../../models/quiz_flow.dart';
import '../../models/reminder_progress.dart';
import '../../providers/localization_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/achievement_service.dart';
import '../../services/audio_service.dart' as audio;
import '../../services/game_config_loader.dart';
import '../../services/guest_animal_conversations_loader.dart';
import '../../services/image_asset_resolver.dart';
import '../../services/image_quiz_level_loader.dart';
import '../../services/level_config_loader.dart';
import '../../services/profile_service.dart';
import '../../services/question_layout_budget.dart';
import '../../services/quiz_progress_service.dart';
import '../../services/reminder_progress_service.dart';
import '../../services/test_data_service.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/debug_layout_box.dart';
import '../../widgets/level_translations_view.dart';
import '../../widgets/image_quiz_template2_audio_controls.dart';
import '../../widgets/mcq_pill_answer_button.dart';
import '../../widgets/standard_question_media.dart';
import '../../widgets/tutorial/tutorial_controller.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import 'quiz_templates/appear_disappear_quiz_body.dart';
import 'quiz_templates/chapter_card_body.dart';
import 'quiz_templates/cloze_sequence_quiz_body.dart';
import 'quiz_templates/dialogue_completion_quiz_body.dart';
import 'quiz_templates/sentence_builder_quiz_body.dart';
import 'quiz_templates/video_conversation_quiz_body.dart';
import 'quiz_templates/word_pairs_quiz_body.dart';

/// Minimum images per level (spec).
const int kMinImagesPerLevel = 4;

// TODO(test): remove before release — auto-completes after first answer.
const bool _kTestAutoComplete = false;

const String _kBlank = '_____';

/// Matches any run of 2+ underscores anywhere in a string (cloze detection).
final RegExp _kBlankPattern = RegExp(r'_{2,}');

/// Minimum touch target size (accessibility).
const double kMinTouchTarget = 48;

/// Localization keys for per-template quiz titles ([localization.json]).
const Map<String, String> _kTemplateTitleL10nKeys = {
  'imageQuizTemplate-1': 'title_image_quiz',
  'imageQuizTemplate-2': 'title_image_word',
  'ConvoTemplate-1': 'title_fill_blank',
  'ClozeSequence': 'title_cloze',
  'AppearDisappear': 'click_in_order',
  'SentenceBuilder': 'title_build_sentence',
  'WordPairs': 'title_word_pairs',
  'DialogueCompletion': 'title_dialogue',
  'VideoConversation': 'title_video_conversation',
};

/// Set to true to re-enable the monster lane (animal, monster, step stones, timer, bubbles).
const bool _kMonsterLaneEnabled = false;

/// Image templates that show the guest animal / monster lane and count toward monster pressure.
bool _isMonsterEligibleImageTemplate(String template) =>
    template == 'imageQuizTemplate-1' || template == 'imageQuizTemplate-2';

typedef _ImageQuiz2Preset = ({
  double promptFontSize,
  double promptRowHeight,
  double maxCardWidth,
  double maxCardHeight,
  double gridGap,
});

/// Per-tier caps for `imageQuizTemplate-2`'s prompt row and 2x2 image-card grid — these are
/// upper bounds, not fixed absolute sizes. The final prompt font size is fixed (never shrinks;
/// truncation is logged instead, see `[QuestionLayout][ImageQuizTemplate2][Warning]`), but the
/// card width/height are clamped against the real `LayoutBuilder` constraints at render time so
/// unexpected viewport sizes, insets, or split-screen can never overflow — per Codex's review in
/// the pipe. Independent copy from `_imageQuiz1ButtonPresets`/`_imageQuiz2Presets` siblings, per
/// the 12-template-independence rule.
const Map<QuestionLayoutTier, _ImageQuiz2Preset> _imageQuiz2Presets = {
  QuestionLayoutTier.phoneUltraTall: (
    promptFontSize: 25.0,
    promptRowHeight: 120.0,
    maxCardWidth: 162.0,
    maxCardHeight: 158.0,
    gridGap: 14.0,
  ),
  QuestionLayoutTier.phoneSuperTall: (
    promptFontSize: 25.0,
    promptRowHeight: 120.0,
    maxCardWidth: 172.0,
    maxCardHeight: 164.0,
    gridGap: 14.0,
  ),
  QuestionLayoutTier.phoneFlagship: (
    promptFontSize: 24.0,
    promptRowHeight: 110.0,
    maxCardWidth: 164.0,
    maxCardHeight: 152.0,
    gridGap: 14.0,
  ),
  QuestionLayoutTier.phoneTransition: (
    promptFontSize: 23.5,
    promptRowHeight: 104.0,
    maxCardWidth: 162.0,
    maxCardHeight: 146.0,
    gridGap: 12.0,
  ),
  QuestionLayoutTier.phoneClassic2to1: (
    promptFontSize: 22.5,
    promptRowHeight: 96.0,
    maxCardWidth: 150.0,
    maxCardHeight: 136.0,
    gridGap: 12.0,
  ),
  QuestionLayoutTier.phone16to9: (
    promptFontSize: 22.0,
    promptRowHeight: 90.0,
    maxCardWidth: 154.0,
    maxCardHeight: 130.0,
    gridGap: 12.0,
  ),
  QuestionLayoutTier.tablet16to9: (
    promptFontSize: 28.0,
    promptRowHeight: 130.0,
    maxCardWidth: 230.0,
    maxCardHeight: 190.0,
    gridGap: 16.0,
  ),
  QuestionLayoutTier.tablet16to10: (
    promptFontSize: 30.0,
    promptRowHeight: 140.0,
    maxCardWidth: 240.0,
    maxCardHeight: 200.0,
    gridGap: 16.0,
  ),
  QuestionLayoutTier.tablet3to2: (
    promptFontSize: 32.0,
    promptRowHeight: 150.0,
    maxCardWidth: 250.0,
    maxCardHeight: 210.0,
    gridGap: 18.0,
  ),
  QuestionLayoutTier.tablet4to3: (
    promptFontSize: 32.0,
    promptRowHeight: 150.0,
    maxCardWidth: 250.0,
    maxCardHeight: 210.0,
    gridGap: 18.0,
  ),
};

// Share of the post-media remainder given to the dialogue box (the rest goes to the 2x2 answer
// grid, computed independently — see `_buildConvo1Panel`). Values match the table agreed by
// Claude/Codex/Antigravity in the pipe; local to ConvoTemplate-1, not shared with
// DialogueCompletion's own remainder split, per the 12-template-independence rule.
double _convo1DialogueShareOfRemainder(QuestionLayoutTier tier) {
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
      return 0.56;
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

/// Fixed per-tier answer-button text size — buttons assume single-line content per the
/// Section D authoring rule, so no min/max/solving, just a lookup. Same values as
/// DialogueCompletion's `_textSizeForTier` but kept as an independent local copy.
const Map<QuestionLayoutTier, double> _convo1ButtonTextSizeForTier = {
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

/// Grid row gap / preferred bottom padding as a percentage of the resolved button height, not
/// a flat px constant — same pattern `SentenceBuilder` already uses (`_sentenceBuilderRowGap`),
/// so spacing scales with the tier's actual button size instead of staying fixed regardless of
/// device. Takes `buttonPreset.oneLineHeight` (the tier's nominal preset, known before content
/// measurement) rather than the final content-driven `buttonRowHeight`, to avoid a circular
/// dependency (the gap itself is needed to compute `cellWidth`, which feeds into
/// `buttonRowHeight`).
double _convo1GridGap(double buttonHeight) =>
    (buttonHeight * 0.15).roundToDouble();
const double _convo1ButtonMinTouchTarget = 44.0;

typedef _Convo1ButtonPreset = ({
  double oneLineHeight,
  double twoLineHeight,
});

// ConvoTemplate-1 keeps one fixed button height for the whole 2x2 grid. The
// selected row-count preset is based on the tallest answer, including room for
// the wrong-state icon; it is never calculated independently per button.
const Map<QuestionLayoutTier, _Convo1ButtonPreset> _convo1ButtonPresets = {
  QuestionLayoutTier.phoneUltraTall: (oneLineHeight: 52, twoLineHeight: 64),
  QuestionLayoutTier.phoneSuperTall: (oneLineHeight: 50, twoLineHeight: 62),
  QuestionLayoutTier.phoneFlagship: (oneLineHeight: 48, twoLineHeight: 60),
  QuestionLayoutTier.phoneTransition: (oneLineHeight: 45, twoLineHeight: 58),
  QuestionLayoutTier.phoneClassic2to1: (oneLineHeight: 44, twoLineHeight: 56),
  QuestionLayoutTier.phone16to9: (oneLineHeight: 44, twoLineHeight: 56),
  QuestionLayoutTier.tablet16to9: (oneLineHeight: 62, twoLineHeight: 76),
  QuestionLayoutTier.tablet16to10: (oneLineHeight: 60, twoLineHeight: 74),
  QuestionLayoutTier.tablet3to2: (oneLineHeight: 58, twoLineHeight: 72),
  QuestionLayoutTier.tablet4to3: (oneLineHeight: 54, twoLineHeight: 68),
};

/// Fixed per-tier answer-button text size for standalone `imageQuizTemplate-1`'s 2x2 grid —
/// independent copy of the same shape as `_convo1ButtonTextSizeForTier`, per the
/// 12-template-independence rule (values happen to match; kept as a separate table so either
/// can be tuned later without affecting the other).
const Map<QuestionLayoutTier, double> _imageQuiz1ButtonTextSizeForTier = {
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

/// Grid row gap as a percentage of the resolved button height — same pattern as
/// `_convo1GridGap`/`_sentenceBuilderRowGap`, not a flat px constant.
double _imageQuiz1GridGap(double buttonHeight) =>
    (buttonHeight * 0.15).roundToDouble();
const double _imageQuiz1ButtonMinTouchTarget = 44.0;

typedef _ImageQuiz1ButtonPreset = ({
  double oneLineHeight,
  double twoLineHeight,
});

// Standalone `imageQuizTemplate-1` keeps one fixed button height for the whole 2x2 grid,
// selected from the tallest answer (including room for the wrong-state icon) — never
// calculated independently per button. 99% of production answers are single words, but real
// sentence-length answers exist (audited), so the 2-line preset and beyond-cap freeze-and-grow
// (+20px per extra line) both matter, not just a theoretical safety net.
const Map<QuestionLayoutTier, _ImageQuiz1ButtonPreset>
    _imageQuiz1ButtonPresets = {
  QuestionLayoutTier.phoneUltraTall: (oneLineHeight: 52, twoLineHeight: 64),
  QuestionLayoutTier.phoneSuperTall: (oneLineHeight: 50, twoLineHeight: 62),
  QuestionLayoutTier.phoneFlagship: (oneLineHeight: 48, twoLineHeight: 60),
  QuestionLayoutTier.phoneTransition: (oneLineHeight: 45, twoLineHeight: 58),
  QuestionLayoutTier.phoneClassic2to1: (oneLineHeight: 44, twoLineHeight: 56),
  QuestionLayoutTier.phone16to9: (oneLineHeight: 44, twoLineHeight: 56),
  QuestionLayoutTier.tablet16to9: (oneLineHeight: 62, twoLineHeight: 76),
  QuestionLayoutTier.tablet16to10: (oneLineHeight: 60, twoLineHeight: 74),
  QuestionLayoutTier.tablet3to2: (oneLineHeight: 58, twoLineHeight: 72),
  QuestionLayoutTier.tablet4to3: (oneLineHeight: 54, twoLineHeight: 68),
};

/// Maps cumulative wrong answers on [monsterEligibleImageTemplate] questions to step 0..4.
/// If the level has at most 6 such questions, advance every wrong. If more than 6, use a
/// 1,2,1,2 wrong-answer pattern between advances (cumulative thresholds at 1, 3, 4, 6).
int _monsterStepFromEligibleWrongs(
  int eligibleWrongCount,
  int eligibleQuestionCount,
) {
  if (eligibleQuestionCount <= 0) return 0;
  if (eligibleQuestionCount <= 6) {
    return min(4, eligibleWrongCount);
  }
  if (eligibleWrongCount < 1) return 0;
  if (eligibleWrongCount < 3) return 1;
  if (eligibleWrongCount < 4) return 2;
  if (eligibleWrongCount < 6) return 3;
  return 4;
}

enum _Phase { loading, playing, translations, end, gameOver }

/// In-quiz experience for one sub-level: image templates, convo templates, monster/timer, and completion UI.
class ImageQuizScreen extends ConsumerStatefulWidget {
  const ImageQuizScreen({
    super.key,
    required this.subLevel,
    required this.ordinalLevelIndex,
    required this.progressKey,
    this.reminderMode = false,
    this.reminderQuestionIds,
    this.reminderSourceLevelsByProgressKey,
    this.preloadedLevelConfig,
  });

  /// When set, questions load from unified level JSON instead of manifest discovery.
  final LevelConfig? preloadedLevelConfig;

  final SubLevel subLevel;

  /// 1-based position in subLevels list; used for scroll navigation only.
  final int ordinalLevelIndex;

  /// Stable progress key used for persisting completion state.
  final String progressKey;
  final bool reminderMode;
  final List<String>? reminderQuestionIds;
  final Map<String, SubLevelItem>? reminderSourceLevelsByProgressKey;

  /// Creates mutable state that loads questions and drives the quiz lifecycle.
  @override
  ConsumerState<ImageQuizScreen> createState() => _ImageQuizScreenState();
}

class _ImageQuizScreenState extends ConsumerState<ImageQuizScreen>
    with TickerProviderStateMixin {
  _Phase _phase = _Phase.loading;
  String? _loadError;
  List<String> _questionAssetPaths = [];
  List<String> _currentQuestionIds = [];
  List<String> _initialReminderQuestionIds = [];
  final List<String> _nextReviewQuestionIds = [];
  final Map<String, String> _assetPathByQuestionId = {};
  final Map<String, List<String>> _vocabularyByQuestionId = {};
  List<String> _vocabulary = [];

  /// Per-question wrong answers when using [LevelConfig] (same order as [_questionAssetPaths]).
  List<List<String>>? _configWrongAnswers;

  /// Unified image phase: `imageQuizTemplate-1` and/or `imageQuizTemplate-2` rows (null = legacy path-only mode).
  List<LevelQuestion>? _configImageQuestions;

  /// Per question index: four asset paths in order [correct, wrong1, wrong2, wrong3] for template-2.
  List<List<String>> _configImageQuiz2Paths = [];

  /// Reminder mode: four image paths per question for [imageQuizTemplate-2] (shuffled order built in UI).
  final Map<String, List<String>> _reminderImageQuiz2PathsByQuestionId = {};
  final Map<String, LevelQuestion> _reminderImageQuestionsById = {};
  GameConfig _config = const GameConfig();
  int _currentIndex = 0;
  int _correctCount = 0;

  /// Highest correct-answer count recorded for this level before this run; used to compute diamond delta.
  int _previousHighestDiamonds = 0;

  /// When true, [_goNext] ends the run after the 3rd question (index 2) with 2 stars.
  bool _shortQuizDebug = false;
  bool _endedEarlyShortQuiz = false;

  /// Settings "Test Mode": when true, [_goNext] ends the run after the first
  /// answered question, awarding 2 stars if that question was answered correctly.
  bool _testMode = false;
  bool _endedEarlyTestMode = false;
  bool _answerLocked = false;
  bool _convo1TranslationPenalized = false;
  String? _convo1LastLayoutLogKey;
  bool _showNext = false;
  bool _reviewingMistakes = false;
  int _initialQuestionCount = 0;
  int? _selectedIndex; // 0..3 index into current options
  bool _convoTtsPlaying = false;

  /// [ConvoTemplate-1] with `audio_file1` + `audio_file2`: auto-play line 1 once per question.
  String? _convo1DualPrimedKey;
  bool _convo1DualA1Playing = false;
  bool _convo1DualA2Playing = false;
  bool _convo1PostAnswerAudioPlaying = false;
  List<String> _currentOptions = [];
  DateTime? _quizStartTime;

  // Timer
  late AnimationController _timerController;

  // Monster / guest animal (only [imageQuizTemplate-1] and [-2])
  int _monsterStep = 0;
  int _monsterEligibleWrongCount = 0;
  int _monsterEligibleQuestionCount = 0;
  String _guestAnimal = 'squirrel';
  String _selectedMonster = 'monster';

  // Wind effect when monster moves to next stone
  late AnimationController _windController;

  // Idle attack loop while waiting for an answer
  late AnimationController _monsterIdleController;

  // Speech bubbles (step 1–3 in-play; step 4 on game-over)
  LanguageConversations? _conversations;
  StepChoice? _bubbleConversation;
  StepChoice? _gameOverBubble;

  // Convo mode
  List<LevelQuestion> _convoQuestions = [];
  final Map<String, LevelQuestion> _convoByQuestionId = {};

  /// Reminder mode: resolved asset path for optional convo thumbnail (ClozeSequence `imageName`, etc.).
  final Map<String, String> _convoThumbPathByQuestionId = {};

  // Unified mode (mixed question types in a single pass)
  List<LevelQuestion> _allQuestions = [];
  List<String?> _questionImagePaths =
      []; // asset path per question (null for vocab)
  List<List<String>> _questionQuiz2Paths =
      []; // 4 paths per template-2 question (empty otherwise)
  /// Parallel to [_allQuestions]: optional hero image path per convo/interactive question.
  List<String?> _questionConvoThumbPaths = [];
  final Map<String, bool> _audioExistsCache = {};

  /// Level-wide timer override from `timer_seconds` in `questions.json` root. Null = use global config.
  int? _levelTimerSeconds;

  /// Optional `translations.json` for end-of-level table (non-reminder only).
  TranslationsPageData? _translationsData;

  /// Non-null only when the loaded level's `questions.json` has a `tutorial` block with
  /// `enabled: true` (see [LevelTutorialConfig]) — null means zero tutorial behavior anywhere on
  /// screen, including the overlay (`_buildTutorialOverlay`) rendering nothing. Only ever set in
  /// [_loadLevel] (the regular, non-reminder path) — reminder mode never shows tutorial guidance.
  TutorialController? _tutorialController;

  /// Asset-bundle prefix key for resolving images under this sub-level’s folder.
  static String _levelKey(SubLevel sub) => imageQuizLevelKey(sub.directoryName);

  /// True when this route is the reminder replay flow rather than a normal sub-level.
  bool get _isReminder => widget.reminderMode;

  /// Stable ID for the active question (reminder + progress tracking).
  String? get _currentQuestionId =>
      _currentQuestionIds.isEmpty ? null : _currentQuestionIds[_currentIndex];

  /// Whether the current index points at a non-image (vocab/grammar) template.
  bool get _isConvoMode {
    if (_allQuestions.isNotEmpty) {
      final i = _currentIndex.clamp(0, _allQuestions.length - 1);
      return !_allQuestions[i]!.isImageTemplate;
    }
    return _convoQuestions.isNotEmpty || _convoByQuestionId.isNotEmpty;
  }

  /// The structured row for the active convo question, or null during pure image prompts.
  LevelQuestion? get _currentConvoLevelQuestion {
    if (_allQuestions.isNotEmpty) {
      if (_currentIndex >= _allQuestions.length) return null;
      final q = _allQuestions[_currentIndex];
      return !q!.isImageTemplate ? q : null;
    }
    if (!_isConvoMode) return null;
    if (_isReminder) return _convoByQuestionId[_currentQuestionId ?? ''];
    return _currentIndex < _convoQuestions.length
        ? _convoQuestions[_currentIndex]
        : null;
  }

  /// Used to offer “view full conversation” on the end card when any ConvoTemplate-1 appeared.
  /// Correct MCQ string for ConvoTemplate-1 only (other templates self-score).
  String? _convoAnswer(LevelQuestion? q) {
    if (q == null) return null;
    if (q.template == 'ConvoTemplate-1') return q.convoData?.answer;
    return null;
  }

  /// Number of questions in this run (unified list, reminder IDs, legacy image-only, or convo-only).
  int get _questionCount {
    if (_allQuestions.isNotEmpty) return _allQuestions.length;
    if (_isReminder) return _currentQuestionIds.length;
    if (_convoQuestions.isNotEmpty || _convoByQuestionId.isNotEmpty)
      return _convoQuestions.length;
    if (_configImageQuestions != null) return _configImageQuestions!.length;
    return _questionAssetPaths.length;
  }

  /// The ordered question list backing the current play session, when one is available as
  /// [LevelQuestion]s (image-quiz-config-only paths have no [LevelQuestion] list and no Chapter
  /// cards, so they fall back to the raw counts below).
  List<LevelQuestion>? get _activeLevelQuestions {
    if (_allQuestions.isNotEmpty) return _allQuestions;
    if (_convoQuestions.isNotEmpty) return _convoQuestions;
    return null;
  }

  /// 1-based index shown in the header (“Question N / M”). Chapter cards are interstitial, not
  /// real questions — they still occupy a slot in [_questionCount] (that denominator also drives
  /// the [_correctCount] star-rate ratio, so it must keep including them), but the header should
  /// count only real questions the learner has reached, or a Chapter card would visibly shift the
  /// numbering by one for every card before it (e.g. reading "2 / N" on what is actually the
  /// first real question, if a Chapter card sits at index 0).
  int get _displayQuestionIndexOneBased {
    final list = _activeLevelQuestions;
    if (list == null) return _currentIndex + 1;
    final end = _currentIndex.clamp(0, list.length - 1);
    var count = 0;
    for (var i = 0; i <= end; i++) {
      if (!list[i].isChapter) count++;
    }
    // On (or before) a leading Chapter card, no real question has been reached yet — show "1"
    // rather than "0", matching what the learner is about to start.
    return count == 0 ? 1 : count;
  }

  /// Denominator for the header; in reminder mode uses the initial batch size. Otherwise counts
  /// only non-Chapter questions — see [_displayQuestionIndexOneBased].
  int get _displayQuestionTotal {
    if (_isReminder) return _initialQuestionCount;
    final list = _activeLevelQuestions;
    if (list == null) return _questionCount;
    final nonChapterCount = list.where((q) => !q.isChapter).length;
    return nonChapterCount == 0 ? _questionCount : nonChapterCount;
  }

  /// AppBar counter text ("Q N / M" or the reminder "Reviewing Mistakes" label). Null outside
  /// the playing phase (loading/translations/end/game-over screens have no question to count).
  String? _headerCounterText(Map<String, String> strings) {
    if (_phase != _Phase.playing || _questionCount == 0) return null;
    if (_isReminder && _reviewingMistakes) {
      return strings['reviewing_mistakes'] ?? 'Reviewing Mistakes';
    }
    return '$_displayQuestionIndexOneBased / $_displayQuestionTotal';
  }

  /// Sets up animations and kicks off [_loadLevel] or [_loadReminderLevel] for this route.
  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _config.imageQuizTimerSeconds),
    );
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onTimerExpired();
    });
    _windController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _monsterIdleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (_isReminder) {
      _loadReminderLevel();
    } else {
      _loadLevel();
    }
  }

  /// Stops music and releases animation controllers when leaving the quiz.
  @override
  void dispose() {
    audio.stopQuestionAudio();
    _timerController.dispose();
    _windController.dispose();
    _monsterIdleController.dispose();
    _videoConversationController?.dispose();
    _tutorialController?.dispose();
    audio.stopQuizMusic();
    super.dispose();
  }

  /// Loads unified `questions.json` (or legacy image manifest), precaches assets, enters [_Phase.playing].
  Future<void> _loadLevel() async {
    final key = _levelKey(widget.subLevel);
    try {
      final shortQuizDebug =
          await TestDataService.instance.isShortQuizEndAfter3With2Stars();
      final config = await GameConfig.load();

      LevelConfig? levelCfg = widget.preloadedLevelConfig;
      if (levelCfg == null) {
        try {
          levelCfg = await loadLevelConfig(widget.subLevel.directoryName);
        } catch (_) {
          levelCfg = null;
        }
      }

      if (levelCfg == null) {
        // Legacy: manifest discovery (no unified level JSON)
        final paths = await loadImageQuizLevelAssetPaths(key);
        final vocabulary = paths.map(assetPathToBasename).toList();

        if (vocabulary.length < kMinImagesPerLevel) {
          if (mounted) {
            setState(() {
              _loadError =
                  'This level needs at least $kMinImagesPerLevel images (found ${vocabulary.length}).';
              _phase = _Phase.loading;
            });
          }
          return;
        }

        final shuffled = List<String>.from(paths)..shuffle(Random());
        final questionIds = shuffled
            .map((path) => buildReminderQuestionId(
                  widget.progressKey,
                  paths.indexOf(path),
                ))
            .toList(growable: false);

        final monsterEligibleCount = shuffled.length;
        final animalNames = await discoverGuestAnimalNames();
        final monsterNames = await discoverMonsterNames();
        final guestAnimal = animalNames.isNotEmpty
            ? animalNames[Random().nextInt(animalNames.length)]
            : 'squirrel';
        final selectedMonster = monsterNames.isNotEmpty
            ? monsterNames[Random().nextInt(monsterNames.length)]
            : 'monster';

        final conversationsConfig = await loadGuestAnimalConversations();
        final language =
            ref.read(settingsProvider).valueOrNull?.language ?? 'en';
        final conversations = getForLanguage(conversationsConfig, language);

        if (mounted) {
          for (final path in shuffled) {
            if (!mounted) break;
            await precacheImage(AssetImage(path), context);
          }
        }

        final prevProgress = await QuizProgressService.instance.loadProgress();
        final prevHighestDiamonds =
            prevProgress.level(widget.progressKey).highestDiamonds;
        final translationsPageData =
            await loadLevelTranslations(widget.subLevel.directoryName);

        if (mounted) {
          setState(() {
            _configWrongAnswers = null;
            _configImageQuestions = null;
            _configImageQuiz2Paths = [];
            _config = config;
            _conversations = conversations;
            _questionAssetPaths = shuffled;
            _currentQuestionIds = questionIds;
            _vocabulary = vocabulary;
            _initialQuestionCount = shuffled.length;
            _monsterEligibleQuestionCount = monsterEligibleCount;
            _guestAnimal = guestAnimal;
            _selectedMonster = selectedMonster;
            _shortQuizDebug = shortQuizDebug;
            _endedEarlyShortQuiz = false;
            _testMode =
                ref.read(settingsProvider).valueOrNull?.testModeOn ?? false;
            _endedEarlyTestMode = false;
            _translationsData = translationsPageData;
            _previousHighestDiamonds = prevHighestDiamonds;
            _phase = _Phase.playing;
            _quizStartTime = DateTime.now();
            _currentOptions = _buildOptions();
          });
          _timerController.duration =
              Duration(seconds: _timerSecondsForCurrentQuestion());
          _startTimer();
          final musicOn =
              ref.read(settingsProvider).valueOrNull?.musicOn ?? true;
          audio.startQuizMusic(musicOn: musicOn);
        }
        return;
      }

      // Unified: load all questions (image + vocab/grammar) in a single pass
      final questions = <LevelQuestion>[];
      final imgPaths = <String?>[];
      final q2Paths = <List<String>>[];
      final convoThumbPaths = <String?>[];
      final selectedLanguage =
          ref.read(settingsProvider).valueOrNull?.language ?? 'en';

      await _resolveFlavorAudioStarted();
      await _resolveFlavorVideoStarted();
      for (final q in levelCfg.questions) {
        // Word-pair questions compare English with its translation, so they
        // are not useful when English is the selected language. Filter them
        // before building the unified question list so totals, progress, and
        // question numbering all use the reduced list.
        if (selectedLanguage == 'en' && q.template == 'WordPairs') {
          continue;
        }
        if (q.isSkipPlaceholder) {
          questions.add(q);
          imgPaths.add(null);
          q2Paths.add(const []);
          convoThumbPaths.add(null);
          continue;
        }
        try {
          if (q.isImageTemplate) {
            if (q.template == 'imageQuizTemplate-1') {
              final d = q.imageData;
              if (d == null) {
                throw StateError('imageQuizTemplate-1 missing imageData');
              }
              final path = await resolveQuizImageAsset(key, d.imageName);
              if (path == null) {
                throw StateError('Missing image: ${d.imageName}');
              }
              questions.add(q);
              imgPaths.add(path);
              q2Paths.add(const []);
              convoThumbPaths.add(null);
            } else if (q.template == 'imageQuizTemplate-2') {
              final d = q.imageQuiz2Data;
              if (d == null) {
                throw StateError('imageQuizTemplate-2 missing data');
              }
              final path = await resolveQuizImageAsset(key, d.imageName);
              if (path == null) {
                throw StateError('Missing image: ${d.imageName}');
              }
              final four = <String>[];
              for (final stem in [d.imageName, ...d.wrongAnswers]) {
                final p = await resolveQuizImageAsset(key, stem);
                if (p == null) throw StateError('Missing image: $stem');
                four.add(p);
              }
              questions.add(q);
              imgPaths.add(path);
              q2Paths.add(four);
              convoThumbPaths.add(null);
            } else {
              questions.add(q);
              imgPaths.add(null);
              q2Paths.add(const []);
              convoThumbPaths.add(null);
            }
          } else {
            String? thumb;
            final thumbStem = _optionalConvoThumbStem(q);
            if (thumbStem != null) {
              thumb = await resolveQuizImageAsset(key, thumbStem);
            }
            questions.add(q);
            imgPaths.add(null);
            q2Paths.add(const []);
            convoThumbPaths.add(thumb);
          }
        } catch (e, st) {
          debugPrint(
            'Question (${q.template}) asset resolution replaced with skip: $e\n$st',
          );
          questions.add(LevelQuestion.parseError(questionId: q.questionId));
          imgPaths.add(null);
          q2Paths.add(const []);
          convoThumbPaths.add(null);
        }
      }

      if (questions.isEmpty) {
        if (mounted) {
          setState(() {
            _loadError = 'This level has no questions.';
            _phase = _Phase.loading;
          });
        }
        return;
      }

      // Precache images (swallow per-image errors — tiles still try AssetImage on demand)
      if (mounted) {
        for (var i = 0; i < questions.length; i++) {
          if (!mounted) break;
          final q = questions[i];
          if (q.isSkipPlaceholder) continue;
          try {
            if (q.isImageTemplate) {
              if (q.template == 'imageQuizTemplate-2') {
                for (final p in q2Paths[i]) {
                  await precacheImage(AssetImage(p), context);
                }
              } else if (imgPaths[i] != null) {
                await precacheImage(AssetImage(imgPaths[i]!), context);
              }
            } else if (convoThumbPaths[i] != null) {
              await precacheImage(AssetImage(convoThumbPaths[i]!), context);
            }
          } catch (e, st) {
            debugPrint('Precache failed for question $i: $e\n$st');
          }
        }
      }

      // Randomize question order for image-only levels so replaying a level
      // does not repeat the same sequence. Question IDs keep encoding the
      // original file index so reminder generation still resolves questions.
      final bool imageOnlyLevel =
          questions.any((q) => !q.isSkipPlaceholder && q.isImageTemplate) &&
              questions
                  .where((q) => !q.isSkipPlaceholder)
                  .every((q) => q.isImageTemplate);
      final displayOrder = List<int>.generate(questions.length, (i) => i);
      if (imageOnlyLevel) {
        displayOrder.shuffle(Random());
      }
      final orderedQuestions = [for (final i in displayOrder) questions[i]];
      final orderedImgPaths = [for (final i in displayOrder) imgPaths[i]];
      final orderedQ2Paths = [for (final i in displayOrder) q2Paths[i]];
      final orderedConvoThumbPaths = [
        for (final i in displayOrder) convoThumbPaths[i]
      ];
      final questionIds = [
        for (final i in displayOrder)
          buildReminderQuestionId(widget.progressKey, i)
      ];
      final monsterEligibleCount = questions
          .where(
            (q) =>
                !q.isSkipPlaceholder &&
                q.isImageTemplate &&
                _isMonsterEligibleImageTemplate(q.template),
          )
          .length;

      // Fully initialize the first video before exposing the playing phase. This removes
      // the first-run Chrome decoder startup race from the video widget.
      final firstVideoQuestion =
          orderedQuestions.cast<LevelQuestion?>().firstWhere(
                (q) => q?.videoConversationData != null,
                orElse: () => null,
              );
      if (firstVideoQuestion != null) {
        final firstVideoPath = _videoAssetPathForRaw(
          firstVideoQuestion.videoConversationData!.videoFile,
        );
        final controller = _videoControllerFor(firstVideoPath);
        if (controller != null && !controller.value.isInitialized) {
          await controller.initialize();
          await controller
              .seekTo(firstVideoQuestion.videoConversationData!.startAt);
        }
        final firstAudioPath =
            _audioAssetPathForRaw(firstVideoQuestion.audioFile1);
        if (firstAudioPath != null) {
          await _resolveAudioExists(firstAudioPath);
        }
      }
      final animalNames = await discoverGuestAnimalNames();
      final monsterNames = await discoverMonsterNames();
      final guestAnimal = animalNames.isNotEmpty
          ? animalNames[Random().nextInt(animalNames.length)]
          : 'squirrel';
      final selectedMonster = monsterNames.isNotEmpty
          ? monsterNames[Random().nextInt(monsterNames.length)]
          : 'monster';
      final conversationsConfig = await loadGuestAnimalConversations();
      final language = ref.read(settingsProvider).valueOrNull?.language ?? 'en';
      final conversations = getForLanguage(conversationsConfig, language);

      final prevProgress = await QuizProgressService.instance.loadProgress();
      final prevHighestDiamonds =
          prevProgress.level(widget.progressKey).highestDiamonds;
      final translationsPageData =
          await loadLevelTranslations(widget.subLevel.directoryName);

      final tutorialConfig = levelCfg.tutorial;
      if (tutorialConfig != null && tutorialConfig.enabled) {
        _tutorialController = TutorialController(
          config: tutorialConfig,
          tutorialId: widget.subLevel.directoryName,
        );
        await _tutorialController!.load();
      }

      if (mounted) {
        setState(() {
          _config = config;
          _conversations = conversations;
          _allQuestions = orderedQuestions;
          _questionImagePaths = orderedImgPaths;
          _questionQuiz2Paths = orderedQ2Paths;
          _questionConvoThumbPaths = orderedConvoThumbPaths;
          _currentQuestionIds = questionIds;
          _initialQuestionCount = orderedQuestions.length;
          _monsterEligibleQuestionCount = monsterEligibleCount;
          _guestAnimal = guestAnimal;
          _selectedMonster = selectedMonster;
          _shortQuizDebug = shortQuizDebug;
          _endedEarlyShortQuiz = false;
          _testMode =
              ref.read(settingsProvider).valueOrNull?.testModeOn ?? false;
          _endedEarlyTestMode = false;
          _levelTimerSeconds = levelCfg?.timerSeconds;
          _translationsData = translationsPageData;
          _previousHighestDiamonds = prevHighestDiamonds;
          _phase = _Phase.playing;
          _quizStartTime = DateTime.now();
          _currentOptions = _buildOptions();
        });
        // Start timer only for image questions (first question might be vocab)
        if (orderedQuestions.isNotEmpty &&
            !orderedQuestions.first.isSkipPlaceholder &&
            orderedQuestions.first.isImageTemplate) {
          _timerController.duration =
              Duration(seconds: _timerSecondsForCurrentQuestion());
          _startTimer();
        }
        final musicOn = ref.read(settingsProvider).valueOrNull?.musicOn ?? true;
        audio.startQuizMusic(musicOn: musicOn);
      }
      return;
    } catch (e, st) {
      debugPrint('ImageQuizScreen _loadLevel: $e\n$st');
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _phase = _Phase.loading;
        });
      }
    }
  }

  /// Resolves reminder IDs against source levels, builds per-id maps, then starts the review pass.
  Future<void> _loadReminderLevel() async {
    try {
      final shortQuizDebug =
          await TestDataService.instance.isShortQuizEndAfter3With2Stars();
      final config = await GameConfig.load();
      final reminderQuestionIds = widget.reminderQuestionIds ?? const [];
      final sourceLevels = widget.reminderSourceLevelsByProgressKey ?? const {};
      final loadedPaths = <String, List<String>>{};
      final loadedVocabulary = <String, List<String>>{};
      final assetPathByQuestionId = <String, String>{};
      final vocabularyByQuestionId = <String, List<String>>{};
      final wrongThreeByQuestionId = <String, List<String>>{};
      final convoByQuestionId = <String, LevelQuestion>{};
      final convoThumbPathByQuestionId = <String, String>{};
      final reminderImageQuestionById = <String, LevelQuestion>{};
      final reminderImageQuiz2PathsById = <String, List<String>>{};
      final validQuestionIds = <String>[];

      await _resolveFlavorAudioStarted();
      await _resolveFlavorVideoStarted();
      for (final questionId in reminderQuestionIds) {
        final (progressKey, questionIndex) =
            parseReminderQuestionId(questionId);
        final sourceItem = sourceLevels[progressKey];
        if (sourceItem == null) continue;
        final levelKey = imageQuizLevelKey(sourceItem.sub.directoryName);
        LevelConfig? lc;
        try {
          lc = await loadLevelConfig(sourceItem.sub.directoryName);
        } catch (_) {
          lc = null;
        }
        if (lc != null &&
            questionIndex >= 0 &&
            questionIndex < lc.questions.length) {
          final q = lc.questions[questionIndex];
          if (q.isImageTemplate &&
              q.template == 'imageQuizTemplate-1' &&
              q.imageData != null) {
            final path = await resolveQuizImageAsset(
              levelKey,
              q.imageData!.imageName,
            );
            if (path != null) {
              assetPathByQuestionId[questionId] = path;
              reminderImageQuestionById[questionId] = q;
              final manifestPaths = loadedPaths[progressKey] ??=
                  await loadImageQuizLevelAssetPaths(levelKey);
              final vocabulary = loadedVocabulary[progressKey] ??= manifestPaths
                  .map(assetPathToBasename)
                  .toList(growable: false);
              vocabularyByQuestionId[questionId] = vocabulary;
              wrongThreeByQuestionId[questionId] = q.imageData!.wrongAnswers;
              validQuestionIds.add(questionId);
              continue;
            }
          } else if (q.isImageTemplate &&
              q.template == 'imageQuizTemplate-2' &&
              q.imageQuiz2Data != null) {
            final d = q.imageQuiz2Data!;
            final fourPaths = <String>[];
            for (final stem in [d.imageName, ...d.wrongAnswers]) {
              final p = await resolveQuizImageAsset(levelKey, stem);
              if (p == null) break;
              fourPaths.add(p);
            }
            if (fourPaths.length == 4) {
              assetPathByQuestionId[questionId] = fourPaths.first;
              reminderImageQuiz2PathsById[questionId] = fourPaths;
              reminderImageQuestionById[questionId] = q;
              final manifestPaths = loadedPaths[progressKey] ??=
                  await loadImageQuizLevelAssetPaths(levelKey);
              final vocabulary = loadedVocabulary[progressKey] ??= manifestPaths
                  .map(assetPathToBasename)
                  .toList(growable: false);
              vocabularyByQuestionId[questionId] = vocabulary;
              wrongThreeByQuestionId[questionId] = d.wrongAnswers;
              validQuestionIds.add(questionId);
              continue;
            }
          } else if (!q!.isImageTemplate &&
              (q.convoData != null ||
                  q.appearDisappearData != null ||
                  q.clozeSequenceData != null ||
                  q.sentenceBuilderData != null ||
                  q.dialogueCompletionData != null ||
                  q.wordPairsData != null)) {
            convoByQuestionId[questionId] = q;
            final thumbStem = _optionalConvoThumbStem(q);
            if (thumbStem != null) {
              final p = await resolveQuizImageAsset(levelKey, thumbStem);
              if (p != null) convoThumbPathByQuestionId[questionId] = p;
            }
            validQuestionIds.add(questionId);
            continue;
          }
        }
        final paths = loadedPaths[progressKey] ??=
            await loadImageQuizLevelAssetPaths(levelKey);
        if (questionIndex < 0 || questionIndex >= paths.length) continue;
        final vocabulary = loadedVocabulary[progressKey] ??=
            paths.map(assetPathToBasename).toList(growable: false);
        assetPathByQuestionId[questionId] = paths[questionIndex];
        vocabularyByQuestionId[questionId] = vocabulary;
        validQuestionIds.add(questionId);
      }

      if (validQuestionIds.isEmpty) {
        throw Exception('No reminder questions were available for this level.');
      }

      if (mounted) {
        for (final questionId in validQuestionIds) {
          final path = assetPathByQuestionId[questionId];
          if (path != null && mounted) {
            await precacheImage(AssetImage(path), context);
          }
          final four = reminderImageQuiz2PathsById[questionId];
          if (four != null) {
            for (final p in four) {
              if (!mounted) break;
              await precacheImage(AssetImage(p), context);
            }
          }
          final thumb = convoThumbPathByQuestionId[questionId];
          if (thumb != null && mounted) {
            await precacheImage(AssetImage(thumb), context);
          }
        }
      }

      var monsterEligibleCount = 0;
      for (final id in validQuestionIds) {
        if (convoByQuestionId.containsKey(id)) continue;
        final rq = reminderImageQuestionById[id];
        if (rq != null) {
          if (rq.isImageTemplate &&
              _isMonsterEligibleImageTemplate(rq.template)) {
            monsterEligibleCount++;
          }
        } else if (assetPathByQuestionId[id] != null) {
          monsterEligibleCount++;
        }
      }
      final animalNames = await discoverGuestAnimalNames();
      final monsterNames = await discoverMonsterNames();
      final guestAnimal = animalNames.isNotEmpty
          ? animalNames[Random().nextInt(animalNames.length)]
          : 'squirrel';
      final selectedMonster = monsterNames.isNotEmpty
          ? monsterNames[Random().nextInt(monsterNames.length)]
          : 'monster';

      final conversationsConfig = await loadGuestAnimalConversations();
      final language = ref.read(settingsProvider).valueOrNull?.language ?? 'en';
      final conversations = getForLanguage(conversationsConfig, language);

      final isConvoReminder = convoByQuestionId.isNotEmpty;

      if (!mounted) return;
      setState(() {
        _config = config;
        _conversations = conversations;
        _convoByQuestionId
          ..clear()
          ..addAll(convoByQuestionId);
        _convoThumbPathByQuestionId
          ..clear()
          ..addAll(convoThumbPathByQuestionId);
        _reminderImageQuestionsById
          ..clear()
          ..addAll(reminderImageQuestionById);
        _reminderImageQuiz2PathsByQuestionId
          ..clear()
          ..addAll(reminderImageQuiz2PathsById);
        _assetPathByQuestionId
          ..clear()
          ..addAll(assetPathByQuestionId);
        _vocabularyByQuestionId
          ..clear()
          ..addAll(vocabularyByQuestionId);
        _currentQuestionIds = List<String>.from(validQuestionIds);
        _initialReminderQuestionIds = List<String>.from(validQuestionIds);
        if (!isConvoReminder) {
          _questionAssetPaths = validQuestionIds
              .map((id) => assetPathByQuestionId[id]!)
              .toList(growable: false);
          _configWrongAnswers = validQuestionIds
              .map((id) => wrongThreeByQuestionId[id] ?? <String>[])
              .toList(growable: false);
        }
        _initialQuestionCount = validQuestionIds.length;
        _monsterEligibleQuestionCount = monsterEligibleCount;
        _guestAnimal = guestAnimal;
        _selectedMonster = selectedMonster;
        _shortQuizDebug = shortQuizDebug;
        _endedEarlyShortQuiz = false;
        _testMode = ref.read(settingsProvider).valueOrNull?.testModeOn ?? false;
        _endedEarlyTestMode = false;
        _reviewingMistakes = false;
        _phase = _Phase.playing;
        _quizStartTime = DateTime.now();
        _currentOptions = _buildOptions();
      });
      if (!isConvoReminder) {
        _timerController.duration =
            Duration(seconds: _timerSecondsForCurrentQuestion());
        _startTimer();
      }
      final musicOn = ref.read(settingsProvider).valueOrNull?.musicOn ?? true;
      audio.startQuizMusic(musicOn: musicOn);
    } catch (e, st) {
      debugPrint('ImageQuizScreen _loadReminderLevel: $e\n$st');
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _phase = _Phase.loading;
        });
      }
    }
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  /// Returns the timer duration for the current question: level-wide override
  /// from `timer_seconds` at the root of `questions.json`, or the global config value.
  int _timerSecondsForCurrentQuestion() {
    return _levelTimerSeconds ?? _config.imageQuizTimerSeconds;
  }

  /// Whether the current question uses the monster lane and counts wrongs toward monster pressure.
  bool _currentQuestionIsMonsterEligible() {
    if (_monsterEligibleQuestionCount <= 0) return false;
    if (_allQuestions.isNotEmpty && _currentIndex < _allQuestions.length) {
      final q = _allQuestions[_currentIndex];
      if (!q!.isImageTemplate) return false;
      return _isMonsterEligibleImageTemplate(q.template);
    }
    if (_isReminder && _currentQuestionId != null) {
      final rq = _reminderImageQuestionsById[_currentQuestionId!];
      if (rq != null) return _isMonsterEligibleImageTemplate(rq.template);
      return true;
    }
    if (_configImageQuestions != null &&
        _currentIndex < _configImageQuestions!.length) {
      return _isMonsterEligibleImageTemplate(
        _configImageQuestions![_currentIndex].template,
      );
    }
    if (_questionAssetPaths.isNotEmpty &&
        _currentIndex < _questionAssetPaths.length) {
      return true;
    }
    return false;
  }

  bool get _showMonsterLaneForCurrentQuestion =>
      _kMonsterLaneEnabled &&
      _monsterEligibleQuestionCount > 0 &&
      _currentQuestionIsMonsterEligible();

  /// True only inside the `testing-responsive-design` level — draws a visible outline + label
  /// around every major layout box (media, prompt/dialogue, tile-bank, slot, answer-grid,
  /// action region) across every template, so box boundaries/percentages can be visually
  /// audited from a screenshot. Never true for real player-facing levels.
  bool get _debugShowLayoutBounds =>
      widget.subLevel.directoryName == 'testing-responsive-design';

  /// Restarts the pie countdown and monster idle loop for the current image question.
  void _startTimer() {
    if (!_kMonsterLaneEnabled) return;
    _timerController
      ..reset()
      ..forward();
    if (_showMonsterLaneForCurrentQuestion) {
      if (!_monsterIdleController.isAnimating) {
        _monsterIdleController.repeat(reverse: true);
      }
    } else {
      _monsterIdleController
        ..stop()
        ..reset();
    }
  }

  /// Fires when the image timer completes without an answer; counts as wrong and shows Next.
  void _onTimerExpired() {
    if (_answerLocked) return;
    _timerController.stop();
    final soundFxOn =
        ref.read(settingsProvider).valueOrNull?.soundFxOn ?? false;
    audio.playWrong(soundFxOn: soundFxOn);
    final questionId = _currentQuestionId;
    if (_isReminder) {
      if (questionId != null) _nextReviewQuestionIds.add(questionId);
    } else if (questionId != null) {
      ReminderProgressService.instance.recordWrongAnswer(questionId);
    }
    AchievementService.instance.recordAnswer(false);
    _recordWrongForMonster();
    setState(() {
      _answerLocked = true;
      _selectedIndex = null; // no option tapped — only correct highlighted
      _showNext = true;
    });
  }

  // ── Monster ───────────────────────────────────────────────────────────────

  /// Advances monster proximity, wind animation, and bubbles; step 4 triggers game over.
  void _recordWrongForMonster() {
    if (!_kMonsterLaneEnabled) return;
    if (!_currentQuestionIsMonsterEligible()) return;
    _monsterEligibleWrongCount++;
    final newStep = _monsterStepFromEligibleWrongs(
      _monsterEligibleWrongCount,
      _monsterEligibleQuestionCount,
    );
    if (newStep > _monsterStep) {
      _monsterStep = newStep;
      // Pause idle during the 500ms stone-movement transition, then resume
      _monsterIdleController
        ..stop()
        ..reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _windController.forward(from: 0);
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _phase == _Phase.playing) {
          _monsterIdleController.repeat(reverse: true);
          // Show speech bubbles after the slide completes (steps 1–3 only)
          if (_monsterStep >= 1 &&
              _monsterStep <= 3 &&
              _conversations != null) {
            final pair =
                pickRandomStepConversation(_conversations!, _monsterStep);
            if (pair != null) setState(() => _bubbleConversation = pair);
          }
        }
      });
      if (_monsterStep >= 4) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _monsterIdleController
              ..stop()
              ..reset();
            final step4Bubble = _conversations != null
                ? pickRandomStepConversation(_conversations!, 4)
                : null;
            setState(() {
              _phase = _Phase.gameOver;
              _gameOverBubble = step4Bubble;
            });
          }
        });
      }
    }
  }

  /// Guest animal sprite for the current distress step (or fixed step for game-over layout).
  Widget _animalImage({int step = -1}) {
    final index = (step < 0 ? _monsterStep : step).clamp(0, 4) + 1;
    final path = 'assets/images/animals/$_guestAnimal/$_guestAnimal-$index.png';
    return Image.asset(
      path,
      width: 72,
      height: 72,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade400),
        ),
        child: Icon(Icons.pets, color: Colors.amber.shade700, size: 32),
      ),
    );
  }

  /// Antagonist sprite beside the animal during image-quiz pressure segments.
  Widget _monsterImage() {
    final path = 'assets/images/monsters/$_selectedMonster.png';
    return Image.asset(
      path,
      width: 72,
      height: 72,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.purple.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade400),
        ),
        child:
            Icon(Icons.pest_control, color: Colors.purple.shade700, size: 32),
      ),
    );
  }

  // ── Answer logic ──────────────────────────────────────────────────────────

  /// Canonical correct key for scoring: image basename, template-2 stem, or convo answer string.
  String _correctAnswer() {
    if (_allQuestions.isNotEmpty) {
      if (_currentIndex >= _allQuestions.length) return '';
      final q = _allQuestions[_currentIndex];
      if (q.videoConversationData == null) {
        if (q.template == 'imageQuizTemplate-2') {
          return q.imageQuiz2Data!.correctAnswerStem;
        }
        if (q.imageData?.answer != null) return q.imageData!.answer!;
        final path = _currentIndex < _questionImagePaths.length
            ? _questionImagePaths[_currentIndex]
            : null;
        return path != null ? assetPathToBasename(path) : '';
      }
      return _convoAnswer(q) ?? '';
    }
    if (_isConvoMode) {
      return _convoAnswer(_currentConvoLevelQuestion) ?? '';
    }
    if (_isReminder && _currentQuestionId != null) {
      final rq = _reminderImageQuestionsById[_currentQuestionId!];
      if (rq?.template == 'imageQuizTemplate-2') {
        return rq!.imageQuiz2Data!.correctAnswerStem;
      }
      if (rq?.template == 'imageQuizTemplate-1' &&
          rq!.imageData?.answer != null) {
        return rq.imageData!.answer!;
      }
    }
    if (_configImageQuestions != null) {
      final q = _configImageQuestions![_currentIndex];
      if (q.template == 'imageQuizTemplate-2') {
        return q.imageQuiz2Data!.correctAnswerStem;
      }
    }
    return assetPathToBasename(_questionAssetPaths[_currentIndex]);
  }

  /// Shuffled four choices for MCQ templates; empty when the template renders its own grid.
  List<String> _buildOptions() {
    if (_allQuestions.isNotEmpty) {
      if (_currentIndex >= _allQuestions.length) return [];
      final q = _allQuestions[_currentIndex];
      if (!q!.isImageTemplate) {
        if (q.template != 'ConvoTemplate-1') return [];
        final ans = _convoAnswer(q);
        final dist = q.convoData!.distractors;
        if (ans == null) return [];
        return ([ans, ...dist]..shuffle(Random()));
      }
      // Image question
      if (q.template == 'imageQuizTemplate-2' && q.imageQuiz2Data != null) {
        final d = q.imageQuiz2Data!;
        return ([d.correctAnswerStem, ...d.wrongAnswers]..shuffle(Random()));
      }
      final correct = _correctAnswer();
      if (q.imageData != null && q.imageData!.wrongAnswers.length == 3) {
        return ([correct, ...q.imageData!.wrongAnswers]..shuffle(Random()));
      }
      final wrongPool = _vocabulary.where((s) => s != correct).toList()
        ..shuffle(Random());
      return ([correct, ...wrongPool.take(3)]..shuffle(Random()));
    }
    if (_isConvoMode) {
      final q = _currentConvoLevelQuestion;
      if (q == null) return [];
      // Interactive templates manage their own tiles — no shared options list.
      if (q.template != 'ConvoTemplate-1') return [];
      final ans = _convoAnswer(q);
      final dist = q.convoData!.distractors;
      if (ans == null) return [];
      return ([ans, ...dist]..shuffle(Random()));
    }
    if (_isReminder && _currentQuestionId != null) {
      final rq = _reminderImageQuestionsById[_currentQuestionId!];
      if (rq?.template == 'imageQuizTemplate-2' && rq!.imageQuiz2Data != null) {
        final d = rq.imageQuiz2Data!;
        return ([d.correctAnswerStem, ...d.wrongAnswers]..shuffle(Random()));
      }
    }
    final correct = _correctAnswer();
    if (_configImageQuestions != null) {
      final q = _configImageQuestions![_currentIndex];
      if (q.template == 'imageQuizTemplate-2' && q.imageQuiz2Data != null) {
        final d = q.imageQuiz2Data!;
        return ([d.correctAnswerStem, ...d.wrongAnswers]..shuffle(Random()));
      }
    }
    if (_configWrongAnswers != null &&
        _currentIndex < _configWrongAnswers!.length) {
      final wrong = _configWrongAnswers![_currentIndex];
      if (wrong.length == 3) {
        return ([correct, ...wrong]..shuffle(Random()));
      }
    }
    final vocabularyPool = _isReminder
        ? (_currentQuestionId != null
            ? _vocabularyByQuestionId[_currentQuestionId!] ?? const <String>[]
            : const <String>[])
        : _vocabulary;
    final wrongPool = vocabularyPool.where((s) => s != correct).toList()
      ..shuffle(Random());
    final wrong = wrongPool.take(3).toList();
    final options = [correct, ...wrong]..shuffle(Random());
    return options;
  }

  /// Fires when translation is revealed on a ConvoTemplate-1 question with [trOk] == false.
  Future<void> _triggerConvo1TranslationPenalty(LevelQuestion q) async {
    if (_answerLocked) return;
    if (q.convoData?.trOk ?? false) return;
    final soundFxOn =
        ref.read(settingsProvider).valueOrNull?.soundFxOn ?? false;
    audio.playWrong(soundFxOn: soundFxOn);
    final questionId = _currentQuestionId;
    if (_isReminder) {
      if (questionId != null) _nextReviewQuestionIds.add(questionId);
    } else if (questionId != null) {
      ReminderProgressService.instance.recordWrongAnswer(questionId);
    }
    _recordWrongForMonster();
    AchievementService.instance.recordAnswer(false);
    setState(() {
      _answerLocked = true;
      _convo1TranslationPenalized = true;
      _showNext = false;
    });
    if (_convo1UsesDualAudio(q)) {
      final p1 = _audioAssetPathForRaw(q.audioFile1);
      final p2 = _audioAssetPathForRaw(q.audioFile2);
      if (p1 != null && p2 != null) {
        final ok1 = await _resolveAudioExists(p1);
        final ok2 = await _resolveAudioExists(p2);
        if (ok1 && ok2) {
          final startIndex = _currentIndex;
          final startQuestionId = _currentQuestionId;
          bool sameQuestion() =>
              mounted &&
              _currentIndex == startIndex &&
              _currentQuestionId == startQuestionId;
          final caseA = !_convo1Line1HasCloze(q) && _convo1Line2HasCloze(q);
          setState(() => _convo1PostAnswerAudioPlaying = true);
          if (!caseA) {
            setState(() => _convo1DualA1Playing = true);
            try {
              await audio.playQuestionAudio(p1);
            } finally {
              if (mounted) setState(() => _convo1DualA1Playing = false);
            }
            if (!sameQuestion()) return;
          }
          setState(() => _convo1DualA2Playing = true);
          try {
            await audio.playQuestionAudio(p2);
          } finally {
            if (mounted) setState(() => _convo1DualA2Playing = false);
          }
          if (!sameQuestion()) return;
          setState(() => _convo1PostAnswerAudioPlaying = false);
        }
      }
    }
    if (!mounted) return;
    setState(() => _showNext = true);
  }

  /// Handles ConvoTemplate-1/2 and image multiple-choice taps; schedules advance or Next on wrong.
  Future<void> _onAnswerTap(int optionIndex) async {
    if (_answerLocked) return;
    if (_kTestAutoComplete) {
      _correctCount = 100;
      setState(() => _phase = _Phase.end);
      return;
    }
    if (!_isConvoMode) _timerController.stop();
    final option = _currentOptions[optionIndex];
    final renderedQuestion = _currentConvoLevelQuestion;
    final correct = renderedQuestion?.template == 'ConvoTemplate-1'
        ? renderedQuestion?.convoData?.answer ?? ''
        : _correctAnswer();
    final isCorrect = option == correct;
    final soundFxOn =
        ref.read(settingsProvider).valueOrNull?.soundFxOn ?? false;
    final cq = _currentConvoLevelQuestion;
    if (cq != null && _convo1UsesDualAudio(cq)) {
      final p1 = _audioAssetPathForRaw(cq.audioFile1);
      final p2 = _audioAssetPathForRaw(cq.audioFile2);
      final dualReady = p1 != null &&
          p2 != null &&
          await _resolveAudioExists(p1) &&
          await _resolveAudioExists(p2);
      final line1HasCloze = _convo1Line1HasCloze(cq);
      final line2HasCloze = _convo1Line2HasCloze(cq);
      final caseA = !line1HasCloze && line2HasCloze;
      final playBoth = !caseA;

      Future<void> playClip(String path, {required bool line1}) async {
        if (!mounted) return;
        setState(() {
          if (line1) {
            _convo1DualA1Playing = true;
          } else {
            _convo1DualA2Playing = true;
          }
        });
        try {
          await audio.playQuestionAudio(path);
        } finally {
          if (mounted) {
            setState(() {
              if (line1) {
                _convo1DualA1Playing = false;
              } else {
                _convo1DualA2Playing = false;
              }
            });
          }
        }
      }

      if (dualReady) {
        final startIndex = _currentIndex;
        final startQuestionId = _currentQuestionId;
        bool sameQuestion() =>
            mounted &&
            _currentIndex == startIndex &&
            _currentQuestionId == startQuestionId;

        if (isCorrect) {
          audio.playCorrect(soundFxOn: soundFxOn);
          AchievementService.instance.recordAnswer(true);
          setState(() {
            _answerLocked = true;
            _selectedIndex = optionIndex;
            _correctCount++;
            _showNext = false;
            _bubbleConversation = null;
            _convo1PostAnswerAudioPlaying = true;
          });
          if (playBoth) {
            await playClip(p1, line1: true);
            if (!sameQuestion()) return;
          }
          await playClip(p2, line1: false);
          if (!sameQuestion()) return;
          setState(() => _convo1PostAnswerAudioPlaying = false);
          Future.delayed(
            Duration(
              milliseconds:
                  (_autoAdvanceDelayForCurrentImageQuestion() * 1000).round(),
            ),
            () {
              if (!sameQuestion()) return;
              _goNext();
            },
          );
          return;
        }

        audio.playWrong(soundFxOn: soundFxOn);
        final questionId = _currentQuestionId;
        if (_isReminder) {
          if (questionId != null) {
            _nextReviewQuestionIds.add(questionId);
          }
        } else if (questionId != null) {
          ReminderProgressService.instance.recordWrongAnswer(questionId);
        }
        _recordWrongForMonster();
        AchievementService.instance.recordAnswer(false);
        setState(() {
          _answerLocked = true;
          _selectedIndex = optionIndex;
          _showNext = false;
          _convo1PostAnswerAudioPlaying = true;
        });
        if (playBoth) {
          await playClip(p1, line1: true);
          if (!sameQuestion()) return;
        }
        await playClip(p2, line1: false);
        if (!sameQuestion()) return;
        setState(() {
          _convo1PostAnswerAudioPlaying = false;
          _showNext = true;
        });
        return;
      }
    }

    if (isCorrect) {
      audio.playCorrect(soundFxOn: soundFxOn);
    } else {
      audio.playWrong(soundFxOn: soundFxOn);
      final questionId = _currentQuestionId;
      if (_isReminder) {
        if (questionId != null) {
          _nextReviewQuestionIds.add(questionId);
        }
      } else if (questionId != null) {
        ReminderProgressService.instance.recordWrongAnswer(questionId);
      }
      _recordWrongForMonster();
    }
    AchievementService.instance.recordAnswer(isCorrect);
    setState(() {
      _answerLocked = true;
      _selectedIndex = optionIndex;
      if (isCorrect) {
        _correctCount++;
        _showNext = false;
        _bubbleConversation = null;
        // Auto-advance after delay
        Future.delayed(
          Duration(
            milliseconds:
                (_autoAdvanceDelayForCurrentImageQuestion() * 1000).round(),
          ),
          () {
            if (!mounted) return;
            _goNext();
          },
        );
      } else {
        _showNext = true;
      }
    });
  }

  /// End-of-level translations interstitial (non-reminder, non-English, `translations.json` present).
  bool _shouldShowTranslations() {
    final lang = ref.read(settingsProvider).valueOrNull?.language ?? 'en';
    final data = _translationsData;
    return data != null &&
        data.entries.isNotEmpty &&
        !_isReminder &&
        lang != 'en';
  }

  /// Advances index or ends the run; handles debug short-quiz, reminder review pass, and per-question timers.
  void _goNext() {
    _tutorialController?.dismissActive();
    audio.stopQuestionAudio();
    if (_testMode && !_reviewingMistakes) {
      _endedEarlyTestMode = true;
      if (!_isConvoMode) {
        _monsterIdleController
          ..stop()
          ..reset();
      }
      setState(() {
        _phase = _Phase.end;
        _bubbleConversation = null;
      });
      return;
    }
    if (_shortQuizDebug &&
        !_reviewingMistakes &&
        !_isReminder &&
        _questionCount >= 3 &&
        _currentIndex >= 2) {
      _endedEarlyShortQuiz = true;
      if (!_isConvoMode) {
        _monsterIdleController
          ..stop()
          ..reset();
      }
      setState(() {
        _phase = _Phase.end;
        _bubbleConversation = null;
      });
      return;
    }
    if (_currentIndex + 1 >= _questionCount) {
      if (_isReminder && _nextReviewQuestionIds.isNotEmpty) {
        final nextQuestionIds = List<String>.from(_nextReviewQuestionIds)
          ..shuffle(Random());
        _nextReviewQuestionIds.clear();
        setState(() {
          _currentQuestionIds = nextQuestionIds;
          if (!_isConvoMode) {
            _questionAssetPaths = nextQuestionIds
                .map((id) => _assetPathByQuestionId[id]!)
                .toList(growable: false);
          }
          _currentIndex = 0;
          _answerLocked = false;
          _showNext = false;
          _selectedIndex = null;
          _convo1TranslationPenalized = false;
          _convo1PostAnswerAudioPlaying = false;
          _convo1DualPrimedKey = null;
          _convo1DualA1Playing = false;
          _convo1DualA2Playing = false;
          _bubbleConversation = null;
          _currentOptions = _buildOptions();
          _reviewingMistakes = true;
        });
        if (!_isConvoMode) _startTimer();
        return;
      }
      if (!_isConvoMode) {
        _monsterIdleController
          ..stop()
          ..reset();
      }
      setState(() {
        _phase = _shouldShowTranslations() ? _Phase.translations : _Phase.end;
        _bubbleConversation = null;
      });
      return;
    }
    setState(() {
      _currentIndex++;
      _answerLocked = false;
      _showNext = false;
      _selectedIndex = null;
      _convo1TranslationPenalized = false;
      _convo1PostAnswerAudioPlaying = false;
      _convo1DualPrimedKey = null;
      _convo1DualA1Playing = false;
      _convo1DualA2Playing = false;
      _bubbleConversation = null;
      _currentOptions = _buildOptions();
      _convoTtsPlaying = false;
    });
    if (_allQuestions.isNotEmpty) {
      if (_currentIndex < _allQuestions.length) {
        final nq = _allQuestions[_currentIndex];
        if (nq.isImageTemplate && !nq.isSkipPlaceholder) {
          _timerController.duration = Duration(
            seconds: _timerSecondsForCurrentQuestion(),
          );
          _startTimer();
        }
        // Moving off VideoConversation questions entirely (this level's video segment is
        // done) — stop the shared controller so its audio doesn't keep playing in the
        // background under a question that no longer shows it on screen.
        if (nq.videoConversationData == null) {
          _videoConversationController?.pause();
        }
      }
    } else if (!_isConvoMode) {
      _timerController.duration =
          Duration(seconds: _timerSecondsForCurrentQuestion());
      _startTimer();
    }
  }

  LevelQuestion? get _currentLevelQuestion {
    if (_allQuestions.isNotEmpty) {
      if (_currentIndex < 0 || _currentIndex >= _allQuestions.length)
        return null;
      return _allQuestions[_currentIndex];
    }
    if (_isReminder && _currentQuestionId != null) {
      final id = _currentQuestionId!;
      return _convoByQuestionId[id] ?? _reminderImageQuestionsById[id];
    }
    if (_convoQuestions.isNotEmpty &&
        _currentIndex >= 0 &&
        _currentIndex < _convoQuestions.length) {
      return _convoQuestions[_currentIndex];
    }
    if (_configImageQuestions != null &&
        _currentIndex >= 0 &&
        _currentIndex < _configImageQuestions!.length) {
      return _configImageQuestions![_currentIndex];
    }
    return null;
  }

  /// Builds the audio asset path for [raw]. Uses `{level}/{flavor}/{file}.{ext}`
  /// once that flavor's audio folder has started being populated for this
  /// level ([_flavorAudioStarted], resolved once in [_loadLevel]); a missing
  /// individual clip within that folder simply hides (via [_resolveAudioExists]
  /// downstream), it does not borrow the other flavor's voice. Until the
  /// flavor's audio folder has any clips at all, falls back to the level's
  /// root `{level}/{file}.{ext}` (today's shared/legacy recordings).
  ///
  /// `.{ext}` is `.m4a` unless [raw] already names an explicit extension (e.g.
  /// `"foo.mp3"`), or the resolved folder has an `.mp3` file for that base name
  /// and no `.m4a` one — see [_audioExtensionByBase]. `audioplayers` (used for
  /// all playback here and for the music/SFX clips, which already ship as
  /// `.mp3`) plays either format identically; this just decides which file on
  /// disk a bare `audio_file`/`audio_file1`/`audio_file2` name resolves to.
  String? _audioAssetPathForRaw(String? raw) {
    final r = raw?.trim();
    if (r == null || r.isEmpty) return null;
    final lower = r.toLowerCase();
    final String base;
    final String? explicitExt;
    if (lower.endsWith('.m4a') || lower.endsWith('.mp3')) {
      base = r.substring(0, r.length - 4);
      explicitExt = lower.substring(lower.length - 3);
    } else {
      base = r;
      explicitExt = null;
    }
    final levelKey = _levelKey(widget.subLevel);
    final dir = _flavorAudioStarted == true
        ? '$levelKey/${AppConfig.flavorDir}'
        : levelKey;
    final ext = explicitExt ?? _audioExtensionByBase[base] ?? 'm4a';
    return 'quiz-data/levels/$dir/$base.$ext';
  }

  /// Whether this level's `{flavor}/` folder has any `.m4a`/`.mp3` clips at all.
  /// Null until resolved once by [_resolveFlavorAudioStarted] during [_loadLevel].
  bool? _flavorAudioStarted;

  /// Base clip name (no extension) -> `'m4a'` or `'mp3'`, for whichever actually exists on
  /// disk in the resolved audio folder — populated once alongside [_flavorAudioStarted].
  /// `.m4a` wins when both exist for the same base name (this pipeline's default format);
  /// `.mp3` is only used when there's no `.m4a` counterpart. A base name not in this map
  /// (clip doesn't exist under either extension) defaults to `.m4a` in
  /// [_audioAssetPathForRaw], same as before this map existed — [_resolveAudioExists]
  /// downstream still hides the audio feature for a genuinely missing clip either way.
  final Map<String, String> _audioExtensionByBase = {};

  /// Resolves and caches [_flavorAudioStarted] / [_audioExtensionByBase] for the current
  /// level. Call once during [_loadLevel], before any question widgets that read
  /// [_audioAssetPathForRaw] are built.
  Future<void> _resolveFlavorAudioStarted() async {
    if (_flavorAudioStarted != null) return;
    final levelKey = _levelKey(widget.subLevel);
    final flavorPrefix =
        'assets/quiz-data/levels/$levelKey/${AppConfig.flavorDir}/';
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    _flavorAudioStarted = assets.any((p) =>
        p.startsWith(flavorPrefix) &&
        (p.toLowerCase().endsWith('.m4a') || p.toLowerCase().endsWith('.mp3')));
    final dirPrefix = _flavorAudioStarted == true
        ? flavorPrefix
        : 'assets/quiz-data/levels/$levelKey/';
    // Two passes so `.m4a` always wins over `.mp3` for the same base name, regardless of
    // manifest ordering.
    for (final p in assets) {
      if (!p.startsWith(dirPrefix)) continue;
      final rest = p.substring(dirPrefix.length);
      if (rest.contains('/') || !rest.toLowerCase().endsWith('.m4a')) continue;
      _audioExtensionByBase[rest.substring(0, rest.length - 4)] = 'm4a';
    }
    for (final p in assets) {
      if (!p.startsWith(dirPrefix)) continue;
      final rest = p.substring(dirPrefix.length);
      if (rest.contains('/') || !rest.toLowerCase().endsWith('.mp3')) continue;
      _audioExtensionByBase.putIfAbsent(
          rest.substring(0, rest.length - 4), () => 'mp3');
    }
  }

  String? _audioAssetPath(LevelQuestion q) =>
      _audioAssetPathForRaw(q.audioFile);

  /// Whether this level's `{flavor}/` folder has any `.mp4` clips at all.
  /// Null until resolved once by [_resolveFlavorVideoStarted] during [_loadLevel].
  bool? _flavorVideoStarted;

  /// Resolves and caches [_flavorVideoStarted] for the current level, mirroring
  /// [_resolveFlavorAudioStarted]. Call once during [_loadLevel].
  Future<void> _resolveFlavorVideoStarted() async {
    if (_flavorVideoStarted != null) return;
    final levelKey = _levelKey(widget.subLevel);
    final prefix = 'assets/quiz-data/levels/$levelKey/${AppConfig.flavorDir}/';
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _flavorVideoStarted = manifest
        .listAssets()
        .any((p) => p.startsWith(prefix) && p.toLowerCase().endsWith('.mp4'));
  }

  /// Builds the full Flutter asset key for [raw] (a `videoFile` value with no extension),
  /// mirroring [_audioAssetPathForRaw]'s `{level}/{flavor}/{file}` fallback logic. Unlike the
  /// audio helper, this returns the full key including the `assets/` prefix, since
  /// `VideoPlayerController.asset()` expects the same path shape as `Image.asset`.
  String? _videoAssetPathForRaw(String? raw) {
    final r = raw?.trim();
    if (r == null || r.isEmpty) return null;
    final base =
        r.toLowerCase().endsWith('.mp4') ? r.substring(0, r.length - 4) : r;
    final levelKey = _levelKey(widget.subLevel);
    final dir = _flavorVideoStarted == true
        ? '$levelKey/${AppConfig.flavorDir}'
        : levelKey;
    return 'assets/quiz-data/levels/$dir/$base.mp4';
  }

  /// Single [VideoPlayerController] shared across every `VideoConversation` row in the level
  /// (keyed by asset path, not by question), so consecutive rows play through the same decoder
  /// without a re-init stutter at each question-widget swap. See [_videoControllerFor].
  VideoPlayerController? _videoConversationController;
  String? _videoConversationControllerAssetPath;

  /// Returns the controller for [assetPath], creating (and disposing any stale prior) one only
  /// when the asset path actually changes. Safe to call every build — it's a cheap memoized
  /// lookup, not a new controller per call.
  VideoPlayerController? _videoControllerFor(String? assetPath) {
    if (assetPath == null) return null;
    if (_videoConversationControllerAssetPath == assetPath) {
      return _videoConversationController;
    }
    _videoConversationController?.dispose();
    final controller = VideoPlayerController.asset(assetPath);
    // Muted permanently: spoken lines are driven by separately-triggered, precisely-trimmed
    // audio clips (`audio_file1`/`audio_file2`, played via VideoConversationQuizBody) instead of
    // this video's own embedded track. The embedded track's audio can't be cut off precisely at
    // a runtime pause point (async pause + buffered-audio overrun let it bleed into the next
    // line), whereas a trimmed clip file simply has nothing left to play past its own end.
    controller.setVolume(0);
    _videoConversationController = controller;
    _videoConversationControllerAssetPath = assetPath;
    return controller;
  }

  bool _convo1UsesDualAudio(LevelQuestion q) {
    if (q.template != 'ConvoTemplate-1') return false;
    final a1 = q.audioFile1?.trim() ?? '';
    final a2 = q.audioFile2?.trim() ?? '';
    return a1.isNotEmpty && a2.isNotEmpty;
  }

  bool _convo1AnswerWasCorrect(LevelQuestion q) {
    if (q.template != 'ConvoTemplate-1' || !_answerLocked) return false;
    final idx = _selectedIndex;
    if (idx == null || idx < 0 || idx >= _currentOptions.length) return false;
    final ans = _convoAnswer(q);
    return ans != null && _currentOptions[idx] == ans;
  }

  bool _convo1Line1HasCloze(LevelQuestion q) =>
      q.convoData?.line1.contains(_kBlankPattern) ?? false;

  bool _convo1Line2HasCloze(LevelQuestion q) =>
      q.convoData?.line2.contains(_kBlankPattern) ?? false;

  void _scheduleConvo1DualLine1IfNeeded(LevelQuestion q) {
    if (!_convo1UsesDualAudio(q)) return;
    if (_convo1Line1HasCloze(q)) return;
    final key = '${_currentQuestionId ?? ''}#$_currentIndex';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_convo1DualPrimedKey == key) return;
      _convo1DualPrimedKey = key;
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted) return;
        final cur = _currentConvoLevelQuestion;
        if (cur == null || !_convo1UsesDualAudio(cur)) return;
        final p1 = _audioAssetPathForRaw(cur.audioFile1);
        final p2 = _audioAssetPathForRaw(cur.audioFile2);
        if (p1 == null || p2 == null) return;
        if (!await _resolveAudioExists(p1) || !await _resolveAudioExists(p2)) {
          return;
        }
        if (!mounted) return;
        setState(() => _convo1DualA1Playing = true);
        try {
          await audio.playQuestionAudio(p1);
        } finally {
          if (mounted) setState(() => _convo1DualA1Playing = false);
        }
      });
    });
  }

  Future<bool> _resolveAudioExists(String path) async {
    if (_audioExistsCache.containsKey(path)) return _audioExistsCache[path]!;
    try {
      await rootBundle.load('assets/$path');
      _audioExistsCache[path] = true;
      return true;
    } catch (_) {
      _audioExistsCache[path] = false;
      return false;
    }
  }

  /// Maps accuracy percentage to 0–3 stars (fixed 2 stars when debug early-exit fired).
  int _stars() {
    if (_endedEarlyTestMode) return _correctCount >= 1 ? 2 : 0;
    if (_endedEarlyShortQuiz) return 2;
    if (_questionCount == 0) return 0;
    final rate = (_correctCount / _questionCount) * 100;
    if (rate >= 85) return 3;
    if (rate >= 70) return 2;
    if (rate >= 60) return 1;
    return 0;
  }

  /// Diamonds shown on the end screen: only the improvement over the previous best (0 if no improvement).
  int _diamondsEarned() =>
      (_correctCount - _previousHighestDiamonds).clamp(0, _correctCount);

  /// Persists reminder completion or normal level progress, then pops [LevelCompletionResult] to the runner.
  Future<void> _onEndOk() async {
    if (_isReminder) {
      await ReminderProgressService.instance.markReminderCompleted(
        mainLevel: widget.subLevel.mainLevel,
        reminderIndex: widget.subLevel.reminderIndex,
        answeredIds: _initialReminderQuestionIds,
      );
      if (mounted) {
        Navigator.of(context).pop(LevelCompletionResult(
          ordinalLevelIndex: widget.ordinalLevelIndex,
          completed: true,
          isReminder: true,
        ));
      }
      return;
    }

    final stars = _stars();
    if (_quizStartTime != null) {
      final duration = DateTime.now().difference(_quizStartTime!).inSeconds;
      await AchievementService.instance.recordQuizCompleted(duration);
    }
    if (stars >= 1) {
      await QuizProgressService.instance.recordLevelCompletion(
        progressKey: widget.progressKey,
        stars: stars,
        diamondsEarned: _diamondsEarned(),
      );
    }
    if (stars >= 1) {
      await ProfileService.instance.registerQuizCompletion(
        quizType: kQuizGameType,
        questionCount: _endedEarlyTestMode
            ? 1
            : (_endedEarlyShortQuiz ? 3 : _questionCount),
      );
    }
    if (mounted) {
      Navigator.of(context).pop(LevelCompletionResult(
        ordinalLevelIndex: widget.ordinalLevelIndex,
        completed: stars >= 1,
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  /// Quiz shell: listens for music setting changes, wires AppBar close, delegates body to [_buildBody].
  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (prev, next) {
      if (next.valueOrNull?.musicOn == true && _phase == _Phase.playing) {
        audio.startQuizMusic(musicOn: true);
      }
    });
    final soundFxOn =
        ref.read(settingsProvider).valueOrNull?.soundFxOn ?? false;
    final strings =
        ref.watch(currentLocalizedStringsProvider).valueOrNull ?? {};
    final userLanguage =
        ref.watch(settingsProvider).valueOrNull?.language ?? 'en';
    final headerCounterText = _headerCounterText(strings);
    final usesStandardShell = _usesStandardQuestionShell;
    final standardProfile = StandardQuestionLayoutProfile.of(context);
    final scaffold = Scaffold(
      appBar: AppBar(
        toolbarHeight: usesStandardShell ? standardProfile.headerHeight : null,
        // Smaller than the app-wide 24sp AppBar title (app_theme.dart) — this header sits in the
        // device-fixed, percentage-height quiz header band (7-9% of usable height on phones),
        // which the global size crowds; scoped to this screen only so other screens (levels,
        // profile, settings) keep the standard title size.
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
              fontSize: 18,
            ),
        title: Text(widget.subLevel.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () {
            audio.playClick(soundFxOn: soundFxOn);
            Navigator.of(context).pop(LevelCompletionResult(
              ordinalLevelIndex: widget.ordinalLevelIndex,
              completed: false,
            ));
          },
        ),
        actions: [
          if (headerCounterText != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  headerCounterText,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(soundFxOn, strings, userLanguage),
      ),
    );
    final tutorial = _tutorialController;
    if (tutorial == null) return scaffold;
    // Sits as a sibling of the Scaffold, over its full bounds, so the guide card and scrim cover
    // the AppBar too, not just the body.
    return Stack(
      children: [
        scaffold,
        Positioned.fill(
          child: TutorialOverlay(controller: tutorial, strings: strings),
        ),
      ],
    );
  }

  Widget _buildTranslationsPhase(
    bool soundFxOn,
    Map<String, String> strings,
    String userLanguage,
  ) {
    final data = _translationsData!;
    final h = MediaQuery.sizeOf(context).height;
    final listH = (h - 220).clamp(200.0, 560.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LevelTranslationsView(
        entries: data.entries,
        userLanguage: userLanguage,
        title: strings['translations_page_title'] ?? 'Words Used In This Level',
        primaryLabel: strings['next'] ?? 'Next',
        listViewportHeight: listH,
        onPrimary: () {
          audio.playClick(soundFxOn: soundFxOn);
          setState(() => _phase = _Phase.end);
        },
      ),
    );
  }

  /// Central phase switch between loading spinner, playing layouts, summary, and game-over screen.
  Widget _buildBody(
      bool soundFxOn, Map<String, String> strings, String userLanguage) {
    switch (_phase) {
      case _Phase.loading:
        return _buildLoading(soundFxOn, strings);
      case _Phase.playing:
        return _isConvoMode
            ? _buildConvoPlaying(soundFxOn, strings, userLanguage)
            : _buildImagePlaying(soundFxOn, strings, userLanguage);
      case _Phase.translations:
        return _buildTranslationsPhase(soundFxOn, strings, userLanguage);
      case _Phase.end:
        return _buildEnd(soundFxOn, strings);
      case _Phase.gameOver:
        return _buildGameOver(soundFxOn, strings);
    }
  }

  /// Shown while assets load or when [_loadError] is set with a back affordance.
  Widget _buildLoading(bool soundFxOn, Map<String, String> strings) {
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                audio.playClick(soundFxOn: soundFxOn);
                Navigator.of(context).pop(LevelCompletionResult(
                  ordinalLevelIndex: widget.ordinalLevelIndex,
                  completed: false,
                ));
              },
              child: Text(strings['back_to_levels'] ?? 'Back to Levels'),
            ),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  /// Template-2 payload for the active index if present (unified, legacy image-only, or reminder maps).
  ImageQuizTemplate2Data? _currentImageQuiz2Data() {
    if (_allQuestions.isNotEmpty) {
      if (_currentIndex >= _allQuestions.length) return null;
      final q = _allQuestions[_currentIndex];
      return q.template == 'imageQuizTemplate-2' ? q.imageQuiz2Data : null;
    }
    if (_configImageQuestions != null) {
      final q = _configImageQuestions![_currentIndex];
      if (q.template == 'imageQuizTemplate-2') return q.imageQuiz2Data;
    }
    if (_isReminder && _currentQuestionId != null) {
      final rq = _reminderImageQuestionsById[_currentQuestionId!];
      if (rq?.template == 'imageQuizTemplate-2') return rq!.imageQuiz2Data;
    }
    return null;
  }

  /// Ordered asset paths [correct, wrong…] for template-2 grid rendering at the current index.
  List<String>? _fourOrderedPathsForCurrentImageQuiz2() {
    if (_allQuestions.isNotEmpty) {
      if (_currentIndex >= _questionQuiz2Paths.length) return null;
      final paths = _questionQuiz2Paths[_currentIndex];
      return paths.isEmpty ? null : paths;
    }
    if (_configImageQuestions != null &&
        _currentIndex < _configImageQuiz2Paths.length) {
      final p = _configImageQuiz2Paths[_currentIndex];
      if (p.length == 4) return p;
    }
    if (_isReminder && _currentQuestionId != null) {
      final p = _reminderImageQuiz2PathsByQuestionId[_currentQuestionId!];
      if (p != null && p.length == 4) return p;
    }
    return null;
  }

  /// Turns `file-name` stems into Title Case for the template-2 noun prompt above the grid.
  String _nounLabelFromImageStem(String stem) {
    if (stem.isEmpty) return stem;
    return stem
        .split('-')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Maps a logical stem to its resolved asset path using the fixed template-2 ordering list.
  String? _assetPathForImageQuiz2Stem(
    ImageQuizTemplate2Data d,
    List<String> fourOrdered,
    String stem,
  ) {
    final correctStem = d.correctAnswerStem;
    if (stem == correctStem || stem == d.imageName) {
      return fourOrdered.isNotEmpty ? fourOrdered[0] : null;
    }
    final wi = d.wrongAnswers.indexOf(stem);
    if (wi >= 0 && wi + 1 < fourOrdered.length) {
      return fourOrdered[wi + 1];
    }
    return null;
  }

  /// Seconds to wait after a correct image answer before auto-calling [_goNext].
  double _autoAdvanceDelayForCurrentImageQuestion() {
    return _config.autoAdvanceDelaySeconds;
  }

  /// For the last [VideoConversation] row in the run (the next question isn't also a video
  /// row), let the shared controller's remaining tail play out as a proper closing beat before
  /// advancing — a fixed short delay would cut the video off mid-sentence right as the screen
  /// switches to an unrelated (non-video) question. Capped so an unusually long unused tail
  /// can't stall the level.
  double _videoEndingDelaySeconds(LevelQuestion q) {
    final data = q.videoConversationData;
    final controller = _videoConversationController;
    if (data == null || controller == null)
      return _config.autoAdvanceDelaySeconds;
    final nextIndex = _currentIndex + 1;
    final hasNextVideoRow = nextIndex < _allQuestions.length &&
        _allQuestions[nextIndex].videoConversationData != null;
    if (hasNextVideoRow && data.answerUntil != null) {
      final answerRemaining =
          (data.answerUntil! - data.pauseAt).inMilliseconds / 1000.0;
      return answerRemaining.clamp(0.0, 6.0);
    }
    if (hasNextVideoRow) return _config.autoAdvanceDelaySeconds;
    final duration = controller.value.duration;
    if (duration <= Duration.zero) return _config.autoAdvanceDelaySeconds;
    final end = data.answerUntil ?? duration;
    final remaining = (end - data.pauseAt).inMilliseconds / 1000.0;
    return remaining.clamp(_config.autoAdvanceDelaySeconds, 6.0);
  }

  /// Continue button on a [Chapter] card. Not a real question — no achievement tracking, no
  /// reminder wrong-answer bookkeeping, no wrong path at all (there's nothing to get wrong).
  /// Still increments [_correctCount] alongside advancing so this row can never lower the
  /// end-of-level star rate: it always counts as "correct" in the same breath it's passed,
  /// keeping the [_correctCount] / [_questionCount] ratio exactly as it would be without it.
  void _advancePastChapter() {
    setState(() => _correctCount++);
    _goNext();
  }

  /// Callback from interactive convo widgets; correct path scores and delays [_goNext], wrong shows Next.
  Future<void> _handleInteractiveConvoOutcome(
      LevelQuestion q, bool correct) async {
    // Guide, not enforcer: the tutorial step dismisses on the learner's action regardless of
    // whether it was correct — scoring/achievement/reminder bookkeeping below is unaffected.
    final tutorial = _tutorialController;
    if (correct) {
      if (tutorial != null) {
        final stepKey = _tutorialStepKeyFor(q);
        if (stepKey != null) tutorial.onUserActed(stepKey);
      }
      AchievementService.instance.recordAnswer(true);
      final delaySec = switch (q.template) {
        'DialogueCompletion' => 0.0,
        'VideoConversation' => _videoEndingDelaySeconds(q),
        _ => _config.autoAdvanceDelaySeconds,
      };
      setState(() => _correctCount++);
      Future.delayed(
        Duration(milliseconds: (delaySec * 1000).round()),
        () {
          if (!mounted) return;
          _goNext();
        },
      );
    } else {
      AchievementService.instance.recordAnswer(false);
      final questionId = _currentQuestionId;
      if (_isReminder) {
        if (questionId != null) _nextReviewQuestionIds.add(questionId);
      } else if (questionId != null) {
        ReminderProgressService.instance.recordWrongAnswer(questionId);
      }
      setState(() {
        _answerLocked = true;
        _showNext = false;
      });
      await _waitForWrongAnswerAudio(q);
      if (!mounted) return;
      setState(() => _showNext = true);
    }
  }

  Future<void> _waitForWrongAnswerAudio(LevelQuestion q) async {
    final data = q.videoConversationData;
    final controller = _videoConversationController;
    if (q.template != 'VideoConversation' || data == null || controller == null)
      return;
    // AppearDisappear already played the target line before recall; a wrong answer should not
    // replay that line automatically. The learner can use its manual replay control instead.
    if (data.sequenceData?.isRecall == true) return;
    try {
      // Keep the (permanently muted, see _videoControllerFor) video moving forward for visual
      // continuity regardless of where the confirm audio comes from.
      unawaited(controller.play());
      final confirmPath = _audioAssetPathForRaw(q.audioFile2);
      if (confirmPath != null) {
        // The confirm line now lives in its own precisely-trimmed clip (played the same way
        // VideoConversationQuizBody._resumeVideo does for a *correct* answer) instead of the
        // video's own (muted) track, so await that clip directly rather than polling position —
        // polling would just wait through in silence now that the track has no audio.
        await audio.playQuestionAudio(confirmPath);
      } else {
        final end = data.answerUntil ?? controller.value.duration;
        while (mounted && controller.value.position < end) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
      }
      await controller.pause();
    } catch (_) {
      // A platform video failure should not leave the learner without a Next button.
    }
  }

  /// Stable viewport/accessibility profile for the fixed question action region. It never
  /// depends on the current answer type, so moving between buttons, tiles, and sentence/slot
  /// questions cannot make Next jump in size.
  bool _usesCompactQuestionActionRegion(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final scaledBodySize = MediaQuery.textScalerOf(context).scale(16);
    return viewport.height < 900 || scaledBodySize > 16.01;
  }

  bool get _usesStandardQuestionShell {
    if (_phase != _Phase.playing) return false;
    final question = _currentLevelQuestion;
    return question != null &&
        !question.isChapter &&
        question.template != 'WordPairs' &&
        (question.isImageTemplate || _isConvoMode);
  }

  Widget _buildQuestionActionRegion({
    required bool soundFxOn,
    required bool isLast,
  }) {
    final standardProfile = StandardQuestionLayoutProfile.of(context);
    final usesStandardShell = _usesStandardQuestionShell;
    final compact = _usesCompactQuestionActionRegion(context);
    final buttonHeight = usesStandardShell
        ? standardProfile.actionButtonHeight
        : compact
            ? kMinTouchTarget
            : kMinTouchTarget + 8;
    final verticalPadding = usesStandardShell
        ? standardProfile.actionVerticalPadding
        : compact
            ? 4.0
            : 8.0;
    return DebugLayoutBox(
      enabled: _debugShowLayoutBounds,
      label: 'action',
      color: Colors.purple,
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
        child: SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: _showNext
              ? FilledButton(
                  onPressed: () {
                    audio.playClick(soundFxOn: soundFxOn);
                    _goNext();
                  },
                  child: Text(isLast ? 'FINISH' : 'NEXT'),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Image phase layout: hero image or template-2 grid, monster lane, timer, and option buttons.
  Widget _buildImagePlaying(
    bool soundFxOn,
    Map<String, String> strings,
    String userLanguage,
  ) {
    final path = _allQuestions.isNotEmpty
        ? (_currentIndex < _questionImagePaths.length
            ? _questionImagePaths[_currentIndex] ?? ''
            : '')
        : _questionAssetPaths[_currentIndex];
    final d2 = _currentImageQuiz2Data();
    final four = _fourOrderedPathsForCurrentImageQuiz2();
    final isTemplate2 = d2 != null && four != null;
    final iq2 = d2;
    final paths4 = four;
    final q = _currentLevelQuestion;
    final isLast = _currentIndex + 1 >= _questionCount;

    return LayoutBuilder(
      builder: (context, bodyConstraints) => Column(
        children: [
          // Everything above the action region is wrapped in Expanded so it fills the leftover
          // body height and the action region below always resolves to the true bottom of the
          // screen — same placement mechanism `_buildConvoPlaying` uses for every other template.
          Expanded(
            child: Column(
              children: [
                if (isTemplate2 && iq2 != null && q != null) ...[
                  Builder(
                    builder: (context) {
                      final budget = QuestionLayoutBudget.of(context);
                      final preset = _imageQuiz2Presets[budget.tier]!;
                      final label =
                          _nounLabelFromImageStem(iq2.correctAnswerStem);
                      return DebugLayoutBox(
                        enabled: _debugShowLayoutBounds,
                        label: 'prompt',
                        child: SizedBox(
                          height: preset.promptRowHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: LayoutBuilder(
                              builder: (context, promptConstraints) {
                                // Font size is fixed per tier and never shrinks — if a label would
                                // truncate at maxLines:1, that's logged rather than silently
                                // hidden. Real risk, not hypothetical: `_nounLabelFromImageStem`
                                // title-cases hyphenated stems into multi-word labels (e.g.
                                // "blood-pressure-monitor" → "Blood Pressure Monitor"), and the
                                // `imageQuizTemplate-1` content audit found compound answers of
                                // that same shape in production.
                                final painter = TextPainter(
                                  text: TextSpan(
                                    text: label,
                                    style: TextStyle(
                                      fontSize: preset.promptFontSize,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  textDirection: TextDirection.ltr,
                                  maxLines: 1,
                                  textScaler: MediaQuery.textScalerOf(context),
                                )..layout(maxWidth: promptConstraints.maxWidth);
                                if (painter.didExceedMaxLines) {
                                  debugPrint(
                                    '[QuestionLayout][ImageQuizTemplate2][Warning] '
                                    'label truncated at maxLines=1 '
                                    '(tier=${budget.tier.name}, '
                                    'fontSize=${preset.promptFontSize.toStringAsFixed(1)}px, '
                                    'maxWidth=${promptConstraints.maxWidth.toStringAsFixed(1)}px): '
                                    '"$label"',
                                  );
                                }
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: preset.promptFontSize,
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.color,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 6),
                                      ImageQuizTemplate2AudioControls(
                                        key: ValueKey(
                                          'iq2-audio-${q.questionId ?? _currentIndex}',
                                        ),
                                        assetPath: _audioAssetPath(q),
                                        resolveExists: _resolveAudioExists,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ] else
                  // Media + answer grid share one Stack so the grid can extend upward and cover
                  // the media from below, the same cascade mechanism `ConvoTemplate-1` uses —
                  // simplified to a single growing box, since this template has no separate
                  // dialogue panel to split the extension budget with. The media itself is always
                  // rendered at its fixed per-tier size and never resized.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, stackConstraints) {
                        final budget = QuestionLayoutBudget.of(context);
                        final mediaWidthLimit = budget
                            .mediaWidthForAvailable(stackConstraints.maxWidth);
                        final mediaHeight = budget.mediaHeightForAvailable(
                          stackConstraints.maxHeight,
                        );
                        final remainderHeight = max(
                          0.0,
                          stackConstraints.maxHeight - mediaHeight,
                        );

                        final answerWidth = budget
                            .answerWidthForAvailable(stackConstraints.maxWidth);
                        final buttonFontSize =
                            _imageQuiz1ButtonTextSizeForTier[budget.tier]!;
                        final preset = _imageQuiz1ButtonPresets[budget.tier]!;
                        final imageQuiz1GridGap =
                            _imageQuiz1GridGap(preset.oneLineHeight);
                        final cellWidth =
                            max(1.0, (answerWidth - imageQuiz1GridGap) / 2);
                        final buttonTextWidth = max(1.0, cellWidth - 48.0);
                        final maxAnswerLines = _currentOptions
                            .take(4)
                            .map((option) => _convo1LineCount(
                                  option,
                                  fontSize: buttonFontSize,
                                  maxWidth: buttonTextWidth,
                                  fontWeight: FontWeight.w500,
                                ))
                            .fold<int>(1, max);
                        final buttonRowHeight = max(
                          _imageQuiz1ButtonMinTouchTarget,
                          maxAnswerLines <= 1
                              ? preset.oneLineHeight
                              : preset.twoLineHeight +
                                  max(0, maxAnswerLines - 2) * 20.0,
                        );
                        final measuredGridHeight =
                            buttonRowHeight * 2 + imageQuiz1GridGap;

                        // Fallback cascade: the grid grows upward over the media only once it no
                        // longer fits the normal remainder budget (3+ wrapped answer lines).
                        final gridShortfall =
                            max(0.0, measuredGridHeight - remainderHeight);
                        final gridExtension = min(gridShortfall, mediaHeight);
                        final gridHeightFinal = remainderHeight + gridExtension;
                        final gridNeedsScroll =
                            gridShortfall > gridExtension + 0.1;

                        if (maxAnswerLines > 2) {
                          debugPrint(
                            '[QuestionLayout][ImageQuizTemplate-1][Warning] '
                            'content exceeded standard line cap '
                            '(answerLines=$maxAnswerLines) — cascade extension '
                            'is absorbing ${gridExtension.toStringAsFixed(1)}px.',
                          );
                        }
                        if (gridNeedsScroll) {
                          debugPrint(
                            '[QuestionLayout][ImageQuizTemplate-1][Fallback] '
                            'answer content exceeds the media-cascade safety '
                            'cap; answerRegionScroll=true.',
                          );
                        }

                        Widget cell(int i) {
                          final option = _currentOptions[i];
                          final isCorrect = option == _correctAnswer();
                          final isSelected = _selectedIndex == i;
                          final state = _answerLocked && isCorrect
                              ? McqAnswerState.correct
                              : _answerLocked && isSelected && !isCorrect
                                  ? McqAnswerState.wrong
                                  : McqAnswerState.neutral;
                          return Expanded(
                            child: McqPillAnswerButton(
                              label: option,
                              state: state,
                              width: cellWidth,
                              minHeight: buttonRowHeight,
                              maxHeight: buttonRowHeight,
                              fontSize: buttonFontSize,
                              onTap: _answerLocked
                                  ? null
                                  : () {
                                      audio.playClick(soundFxOn: soundFxOn);
                                      _onAnswerTap(i);
                                    },
                            ),
                          );
                        }

                        return SizedBox(
                          height: stackConstraints.maxHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Media container keeps the same fixed-per-tier footprint every
                              // other redesigned template uses. The picture itself renders at
                              // half-width × half-height (a quarter of that footprint's area),
                              // centered, cropped to fill exactly via `BoxFit.cover` — a
                              // deliberate "smaller picture in a same-size frame" look,
                              // developer-specified.
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: mediaHeight,
                                child: DebugLayoutBox(
                                  enabled: _debugShowLayoutBounds,
                                  label: 'media',
                                  child: StandardQuestionMedia(
                                    availableBodyHeight:
                                        stackConstraints.maxHeight,
                                    aspectRatio: 1,
                                    heightOverride: mediaHeight,
                                    widthOverride: mediaWidthLimit,
                                    // `StandardQuestionMedia` can shrink the actual rendered box
                                    // below `widthOverride` via its own aspect-ratio-driven fit
                                    // logic — reading real constraints here (rather than assuming
                                    // `mediaWidthLimit`/`mediaHeight` directly) guarantees "half
                                    // width × half height" is always relative to the frame that's
                                    // actually drawn, not the pre-shrink input values.
                                    child: LayoutBuilder(
                                      builder: (context, mediaBoxConstraints) =>
                                          Center(
                                        child: SizedBox(
                                          width:
                                              mediaBoxConstraints.maxWidth / 2,
                                          height:
                                              mediaBoxConstraints.maxHeight / 2,
                                          child: Image.asset(
                                            path,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              color: Colors.grey.shade300,
                                              child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 64),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Answer grid: normally sits directly below the media with no
                              // overlap. Only when a wrapped answer needs more room than the
                              // remainder budget does it grow upward and cover the media from
                              // below — signaled by the rounded white card, matching the same
                              // "cascade covers media" treatment used elsewhere.
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: gridHeightFinal,
                                child: DebugLayoutBox(
                                  enabled: _debugShowLayoutBounds,
                                  label: 'grid',
                                  color: Colors.blue,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: gridExtension > 0
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: gridExtension > 0
                                          ? const BorderRadius.vertical(
                                              top: Radius.circular(24))
                                          : null,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: SingleChildScrollView(
                                        physics: gridNeedsScroll
                                            ? const BouncingScrollPhysics()
                                            : const NeverScrollableScrollPhysics(),
                                        child: Center(
                                          child: SizedBox(
                                            width: answerWidth,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(children: [
                                                  cell(0),
                                                  SizedBox(
                                                      width: imageQuiz1GridGap),
                                                  cell(1)
                                                ]),
                                                SizedBox(
                                                    height: imageQuiz1GridGap),
                                                Row(children: [
                                                  cell(2),
                                                  SizedBox(
                                                      width: imageQuiz1GridGap),
                                                  cell(3)
                                                ]),
                                              ],
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
                        );
                      },
                    ),
                  ),
                // Speech bubbles + monster lane — only for templates that use monster pressure
                if (_showMonsterLaneForCurrentQuestion) ...[
                  if (_showNext && _bubbleConversation != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _SpeechBubble(
                              _bubbleConversation!.guest,
                              maxWidth: 160,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SpeechBubble(
                              _bubbleConversation!.attacker,
                              maxWidth: 160,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Guest animal + monster (jumps stone to stone) + step stones below
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const animalSize = 72.0;
                        const monsterSize = 72.0;
                        const stoneSize = 20.0;
                        const stoneRowHeight = 26.0;
                        const gap = 8.0;
                        final totalWidth = constraints.maxWidth;

                        // Monster center range: starts above rightmost stone, ends above leftmost stone
                        final maxMonsterCenter = totalWidth - monsterSize / 2;
                        final minMonsterCenter =
                            animalSize + gap + monsterSize / 2;
                        final range = maxMonsterCenter - minMonsterCenter;

                        // Stone i=0 is rightmost (step-0 landing), i=3 is leftmost (step-3 landing)
                        // Monster center at step k aligns with stone k center
                        final step = _monsterStep.clamp(0, 3);
                        final monsterCenter =
                            maxMonsterCenter - step * (range / 3);
                        final monsterLeft = monsterCenter - monsterSize / 2;

                        const pieTimerSize = 40.0;
                        const pieTimerGap = 6.0;
                        const monsterTop = pieTimerSize + pieTimerGap;

                        return SizedBox(
                          height: monsterTop + monsterSize + stoneRowHeight,
                          child: Stack(
                            children: [
                              // Animal — fixed at left, aligned with monster
                              Positioned(
                                left: 0,
                                top: monsterTop,
                                child: _animalImage(),
                              ),
                              // Monster — moves stone to stone with wind behind it
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                left: monsterLeft,
                                top: monsterTop,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: _windController,
                                        builder: (context, _) => CustomPaint(
                                          painter: _WindPainter(
                                              _windController.value),
                                          size: const Size(72, 72),
                                        ),
                                      ),
                                    ),
                                    // Pie countdown timer — centered above monster, moves with it
                                    Positioned(
                                      top: -(pieTimerSize + pieTimerGap),
                                      left: (monsterSize - pieTimerSize) / 2,
                                      child: AnimatedBuilder(
                                        animation: _timerController,
                                        builder: (context, _) {
                                          final remaining =
                                              1.0 - _timerController.value;
                                          final color = Color.lerp(Colors.red,
                                              Colors.green, remaining)!;
                                          return CustomPaint(
                                            size: Size(
                                                pieTimerSize, pieTimerSize),
                                            painter: _PieTimerPainter(
                                              progress: remaining,
                                              color: color,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Idle attack loop: scale up 10% + lunge left 10% of size
                                    AnimatedBuilder(
                                      animation: _monsterIdleController,
                                      builder: (context, child) {
                                        final t = CurvedAnimation(
                                          parent: _monsterIdleController,
                                          curve: Curves.easeInOut,
                                        ).value;
                                        return Transform.translate(
                                          offset: Offset(
                                              -monsterSize * 0.10 * t, 0),
                                          child: Transform.scale(
                                            scale: 1.0 + 0.10 * t,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _monsterImage(),
                                    ),
                                  ],
                                ),
                              ),
                              // Step stones — individually positioned to align with monster landing spots
                              // i=0 rightmost (green) → i=3 leftmost (red); grey when consumed
                              ...List.generate(4, (i) {
                                const stoneColors = [
                                  Colors.green,
                                  Colors.yellow,
                                  Colors.orange,
                                  Colors.red,
                                ];
                                final stoneCenter =
                                    maxMonsterCenter - i * (range / 3);
                                final stoneLeft = stoneCenter - stoneSize / 2;
                                final consumed = i < _monsterStep;
                                return Positioned(
                                  bottom: 0,
                                  left: stoneLeft,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: stoneSize,
                                    height: stoneSize,
                                    decoration: BoxDecoration(
                                      color: consumed
                                          ? Colors.grey.shade300
                                          : stoneColors[i],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (isTemplate2 && iq2 != null && paths4 != null)
                  // Fills whatever height remains after the fixed-height prompt row above (real
                  // remainder, not a MediaQuery screen-fraction guess) — same "Expanded fills
                  // leftover body height" mechanism used everywhere else in this method. Card
                  // width/height are capped per-tier but always clamped against the real
                  // constraints measured here, so they can never overflow regardless of viewport
                  // size, insets, or split-screen — per Codex's review in the pipe.
                  Expanded(
                    child: DebugLayoutBox(
                      enabled: _debugShowLayoutBounds,
                      label: 'grid',
                      color: Colors.blue,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Builder(
                          builder: (context) {
                            final budget = QuestionLayoutBudget.of(context);
                            final preset = _imageQuiz2Presets[budget.tier]!;
                            return LayoutBuilder(
                              builder: (context, gridConstraints) {
                                final availableWidth =
                                    budget.mediaWidthForAvailable(
                                        gridConstraints.maxWidth);
                                final widthCap = max(
                                  1.0,
                                  (availableWidth - preset.gridGap) / 2,
                                );
                                final heightCap = max(
                                  1.0,
                                  (gridConstraints.maxHeight - preset.gridGap) /
                                      2,
                                );
                                final cardWidth =
                                    min(preset.maxCardWidth, widthCap);
                                final cardHeight =
                                    min(preset.maxCardHeight, heightCap);

                                Widget card(int i) {
                                  final option = _currentOptions[i];
                                  final assetPath = _assetPathForImageQuiz2Stem(
                                      iq2, paths4, option);
                                  final isCorrect = option == _correctAnswer();
                                  final isSelected = _selectedIndex == i;
                                  // Same as imageQuizTemplate-1 MCQ: correct cell turns green when
                                  // locked; wrong pick turns red.
                                  final showGreen = _answerLocked && isCorrect;
                                  final showRed =
                                      _answerLocked && isSelected && !isCorrect;
                                  return SizedBox(
                                    width: cardWidth,
                                    height: cardHeight,
                                    child: Material(
                                      color: showGreen
                                          ? Colors.green.shade200
                                          : showRed
                                              ? Colors.red.shade200
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: _answerLocked
                                            ? null
                                            : () {
                                                audio.playClick(
                                                    soundFxOn: soundFxOn);
                                                _onAnswerTap(i);
                                              },
                                        child: assetPath != null
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Image.asset(
                                                  assetPath,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(
                                                    Icons.image_not_supported,
                                                    size: 48,
                                                  ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.image_not_supported),
                                      ),
                                    ),
                                  );
                                }

                                return Center(
                                  child: SingleChildScrollView(
                                    // Defensive last-resort only — card dimensions are already
                                    // clamped to `gridConstraints` above, so this should never
                                    // actually need to scroll.
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    child: SizedBox(
                                      width: cardWidth * 2 + preset.gridGap,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(children: [
                                            card(0),
                                            SizedBox(width: preset.gridGap),
                                            card(1),
                                          ]),
                                          SizedBox(height: preset.gridGap),
                                          Row(children: [
                                            card(2),
                                            SizedBox(width: preset.gridGap),
                                            card(3),
                                          ]),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Reserve the action region before it appears. Compact profiles return the reclaimed
          // height to answer controls while preserving the 48px touch-target floor.
          _buildQuestionActionRegion(soundFxOn: soundFxOn, isLast: isLast),
        ],
      ),
    );
  }

  /// Pass/fail summary with stars and diamonds (or reminder-specific copy) and OK → [_onEndOk].
  Widget _buildEnd(bool soundFxOn, Map<String, String> strings) {
    if (_isReminder) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings['level_complete'] ?? 'Level complete!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                strings['reviewing_mistakes'] ?? 'Reviewing Mistakes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: kMinTouchTarget + 8,
                child: FilledButton(
                  onPressed: () {
                    audio.playClick(soundFxOn: soundFxOn);
                    _onEndOk();
                  },
                  child: Text(strings['ok'] ?? 'OK'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stars = _stars();
    final diamonds = _diamondsEarned();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings['level_complete'] ?? 'Level complete!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  size: 48,
                  color: Colors.amber,
                );
              }),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Text(
                  strings['correct_answers'] ?? 'Correct answers',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '$_correctCount / $_questionCount',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.diamond, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 8),
                Text(
                  '+$diamonds',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: kMinTouchTarget + 8,
              child: FilledButton(
                onPressed: () {
                  audio.playClick(soundFxOn: soundFxOn);
                  _onEndOk();
                },
                child: Text(strings['ok'] ?? 'OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Monster caught the guest: final pose, narrative copy, and back to levels without saving pass.
  Widget _buildGameOver(bool soundFxOn, Map<String, String> strings) {
    const bubbleMaxWidth = 100.0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animal and monster face to face, with step-4 bubbles above if available
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_gameOverBubble != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _SpeechBubble(
                          _gameOverBubble!.guest,
                          maxWidth: bubbleMaxWidth,
                        ),
                      ),
                    _animalImage(step: 4),
                  ],
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_gameOverBubble != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _SpeechBubble(
                          _gameOverBubble!.attacker,
                          maxWidth: bubbleMaxWidth,
                        ),
                      ),
                    Transform.scale(
                      scaleX: -1,
                      child: _monsterImage(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              strings['game_over'] ?? 'Game Over!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              strings['monster_caught_animal'] ??
                  'The monster caught your friend!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: kMinTouchTarget + 8,
              child: FilledButton(
                onPressed: () {
                  audio.playClick(soundFxOn: soundFxOn);
                  Navigator.of(context).pop(LevelCompletionResult(
                    ordinalLevelIndex: widget.ordinalLevelIndex,
                    completed: false,
                    isReminder: _isReminder,
                  ));
                },
                child: Text(strings['back_to_levels'] ?? 'Back to Levels'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Convo mode ────────────────────────────────────────────────────────────

  /// Non-image question chrome: progress label, template body, MCQ buttons when applicable, Next/Finish row.
  Widget _buildConvoPlaying(
      bool soundFxOn, Map<String, String> strings, String userLanguage) {
    final q = _currentConvoLevelQuestion;
    if (q == null) return const Center(child: CircularProgressIndicator());
    if (q.isSkipPlaceholder) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_currentIndex >= _allQuestions.length) return;
        if (!_allQuestions[_currentIndex].isSkipPlaceholder) return;
        _goNext();
      });
      return const Center(child: SizedBox.shrink());
    }
    if (q.isChapter) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ChapterCardBody(
          key: ValueKey('chapter-${_currentQuestionId ?? '$_currentIndex'}'),
          imagePathFuture: resolveQuizImageAsset(
            _levelKey(widget.subLevel),
            q.chapterData!.displayImage,
          ),
          continueLabel: strings['next'] ?? 'Next',
          onContinue: _advancePastChapter,
        ),
      );
    }
    final reminderProgress = _reviewingMistakes
        ? 1.0
        : (_initialQuestionCount <= 0
            ? 0.0
            : (_currentIndex + 1) / _initialQuestionCount);
    final isLast = _currentIndex + 1 >= _questionCount;

    final heroImagePath = _resolvedClozeImagePath();
    final rendersOwnMedia = q.template == 'VideoConversation' ||
        q.template == 'DialogueCompletion' ||
        q.template == 'ConvoTemplate-1' ||
        q.template == 'ClozeSequence' ||
        q.template == 'SentenceBuilder' ||
        q.template == 'AppearDisappear';
    final usesStandardQuestionShell = q.template != 'WordPairs';

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: usesStandardQuestionShell
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: LayoutBuilder(
              builder: (context, bodyConstraints) {
                final questionBody = q.template == 'ConvoTemplate-1'
                    ? Builder(
                        builder: (context) {
                          _scheduleConvo1DualLine1IfNeeded(q);
                          return _buildConvo1Panel(
                            q,
                            userLanguage,
                            soundFxOn,
                          );
                        },
                      )
                    : _buildConvoQuestionBody(
                        q,
                        userLanguage,
                        soundFxOn,
                        strings,
                      );
                if (heroImagePath == null || rendersOwnMedia) {
                  return questionBody;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StandardQuestionMedia(
                      availableBodyHeight: bodyConstraints.maxHeight,
                      aspectRatio: 1,
                      child: Image.asset(
                        heroImagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 48),
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: questionBody),
                  ],
                );
              },
            ),
          ),
        ),
        _buildQuestionActionRegion(soundFxOn: soundFxOn, isLast: isLast),
      ],
    );
  }

  /// Tutorial step key for [q] (see [LevelTutorialConfig.steps]) — `"VideoConversation:<answer
  /// type>"` for rows inside the video, or the plain template name otherwise. Returns null when
  /// [q]'s shape doesn't map to a step key at all (distinct from "not configured," which the
  /// controller itself checks).
  String? _tutorialStepKeyFor(LevelQuestion q) {
    if (q.template == 'VideoConversation') {
      final data = q.videoConversationData;
      if (data == null) return null;
      final String answerType;
      if (data.choiceData != null) {
        answerType = 'DialogueCompletion';
      } else if (data.clozeData != null) {
        answerType = 'ClozeSequence';
      } else if (data.sequenceData != null) {
        answerType =
            data.sequenceData!.isRecall ? 'AppearDisappear' : 'SentenceBuilder';
      } else {
        return null;
      }
      return 'VideoConversation:$answerType';
    }
    return q.template;
  }

  /// Shows this question's tutorial guide (if configured and not already shown this level entry)
  /// once its answer controls have rendered. Called from every template's "controls rendered"
  /// callback — see call sites in [_buildConvoQuestionBody] and [_buildConvoAnswerButton].
  void _maybeShowTutorialFor(LevelQuestion q) {
    final stepKey = _tutorialStepKeyFor(q);
    if (stepKey == null) return;
    _tutorialController?.maybeShowFor(stepKey);
  }

  /// Picks the correct child widget for the active convo template (including interactive mini-games).
  Widget _buildConvoQuestionBody(
    LevelQuestion q,
    String userLanguage,
    bool soundFxOn,
    Map<String, String> strings,
  ) {
    switch (q.template) {
      case 'AppearDisappear':
        return AppearDisappearQuizBody(
          key: ValueKey('ad-${_currentQuestionId ?? '$_currentIndex'}'),
          data: q.appearDisappearData!,
          userLanguage: userLanguage,
          imagePath: _resolvedClozeImagePath(),
          audio1Path: _audioAssetPathForRaw(q.audioFile1),
          audio2Path: _audioAssetPathForRaw(q.audioFile2),
          resolveAudioExists: _resolveAudioExists,
          onPlayQuestionAudio: (path) => audio.playQuestionAudio(path),
          onPlayCorrect: () => audio.playCorrect(soundFxOn: soundFxOn),
          onPlayWrong: () => audio.playWrong(soundFxOn: soundFxOn),
          onOutcome: (correct) => _handleInteractiveConvoOutcome(q, correct),
          onNextTileRendered: (_, __) => _maybeShowTutorialFor(q),
          debugShowLayoutBounds: _debugShowLayoutBounds,
        );
      case 'ClozeSequence':
        return ClozeSequenceQuizBody(
          key: ValueKey('clz-${_currentQuestionId ?? '$_currentIndex'}'),
          data: q.clozeSequenceData!,
          userLanguage: userLanguage,
          imagePath: _resolvedClozeImagePath(),
          audio1Path: _audioAssetPathForRaw(q.audioFile1),
          audio2Path: _audioAssetPathForRaw(q.audioFile2),
          resolveAudioExists: _resolveAudioExists,
          onPlayQuestionAudio: (path) => audio.playQuestionAudio(path),
          onPlayCorrect: () => audio.playCorrect(soundFxOn: soundFxOn),
          onPlayWrong: () => audio.playWrong(soundFxOn: soundFxOn),
          onOutcome: (correct) => _handleInteractiveConvoOutcome(q, correct),
          onNextChoiceRendered: (_, __) => _maybeShowTutorialFor(q),
          debugShowLayoutBounds: _debugShowLayoutBounds,
        );
      case 'SentenceBuilder':
        return SentenceBuilderQuizBody(
          key: ValueKey('sb-${_currentQuestionId ?? '$_currentIndex'}'),
          data: q.sentenceBuilderData!,
          strings: strings,
          userLanguage: userLanguage,
          imagePath: _resolvedClozeImagePath(),
          audio1Path: _audioAssetPathForRaw(q.audioFile1),
          audio2Path: _audioAssetPathForRaw(q.audioFile2),
          resolveAudioExists: _resolveAudioExists,
          onPlayQuestionAudio: (path) => audio.playQuestionAudio(path),
          onPlayCorrect: () => audio.playCorrect(soundFxOn: soundFxOn),
          onPlayWrong: () => audio.playWrong(soundFxOn: soundFxOn),
          onOutcome: (correct) => _handleInteractiveConvoOutcome(q, correct),
          onNextTileRendered: (_, __) => _maybeShowTutorialFor(q),
          debugShowLayoutBounds: _debugShowLayoutBounds,
        );
      case 'WordPairs':
        return WordPairsQuizBody(
          key: ValueKey('wp-${_currentQuestionId ?? '$_currentIndex'}'),
          data: q.wordPairsData!,
          userLanguage: userLanguage,
          strings: strings,
          onPlayCorrect: () => audio.playCorrect(soundFxOn: soundFxOn),
          onPlayWrong: () => audio.playWrong(soundFxOn: soundFxOn),
          onOutcome: (correct) => _handleInteractiveConvoOutcome(q, correct),
          onGuideTargetRendered: (_) => _maybeShowTutorialFor(q),
          debugShowLayoutBounds: _debugShowLayoutBounds,
        );
      case 'DialogueCompletion':
        return DialogueCompletionQuizBody(
          key: ValueKey('dc-${_currentQuestionId ?? '$_currentIndex'}'),
          data: q.dialogueCompletionData!,
          userLanguage: userLanguage,
          imagePath: _resolvedClozeImagePath(),
          audio1Path: _audioAssetPathForRaw(q.audioFile1),
          audio2Path: _audioAssetPathForRaw(q.audioFile2),
          resolveAudioExists: _resolveAudioExists,
          onPlayQuestionAudio: (path) => audio.playQuestionAudio(path),
          onPlayCorrect: () => audio.playCorrect(soundFxOn: soundFxOn),
          onPlayWrong: () => audio.playWrong(soundFxOn: soundFxOn),
          onOutcome: (correct) => _handleInteractiveConvoOutcome(q, correct),
          onOptionButtonsRendered: (_, __) => _maybeShowTutorialFor(q),
          debugShowLayoutBounds: _debugShowLayoutBounds,
        );
      case 'VideoConversation':
        final previousIsVideo = _currentIndex > 0 &&
            _allQuestions[_currentIndex - 1].videoConversationData != null;
        return VideoConversationQuizBody(
          key: ValueKey('vc-${_currentQuestionId ?? '$_currentIndex'}'),
          data: q.videoConversationData!,
          controller: _videoControllerFor(
            _videoAssetPathForRaw(q.videoConversationData!.videoFile),
          ),
          continueExistingPlayback: previousIsVideo,
          onPlayCorrect: () => audio.playCorrect(soundFxOn: soundFxOn),
          onPlayWrong: () => audio.playWrong(soundFxOn: soundFxOn),
          onOutcome: (correct) => _handleInteractiveConvoOutcome(q, correct),
          onChoiceButtonsRendered: (_, __) => _maybeShowTutorialFor(q),
          onNextTileRendered: (_, __) => _maybeShowTutorialFor(q),
          setupAudioPath: _audioAssetPathForRaw(q.audioFile1),
          confirmAudioPath: _audioAssetPathForRaw(q.audioFile2),
          onPlayQuestionAudio: (path) => audio.playQuestionAudio(path),
          onStartQuestionAudio: (path) => audio.startQuestionAudio(path),
          waitForTutorial: () {
            final stepKey = _tutorialStepKeyFor(q);
            if (stepKey == null) return Future<void>.value();
            return _tutorialController?.showBeforePlayback(stepKey) ??
                Future<void>.value();
          },
          debugShowLayoutBounds: _debugShowLayoutBounds,
        );
      default:
        if (q.isSkipPlaceholder) {
          return const SizedBox.shrink();
        }
        throw StateError('Unexpected convo template: ${q.template}');
    }
  }

  /// Returns the pre-resolved image path for the current ClozeSequence question, or null.
  String? _resolvedClozeImagePath() {
    if (_isReminder) {
      return _convoThumbPathByQuestionId[_currentQuestionId ?? ''];
    }
    if (_allQuestions.isNotEmpty) {
      return _currentIndex < _questionConvoThumbPaths.length
          ? _questionConvoThumbPaths[_currentIndex]
          : null;
    }
    return null;
  }

  /// Optional thumbnail basename from any convo/interactive template that supports one.
  static String? _optionalConvoThumbStem(LevelQuestion q) {
    return q.convoData?.imageName ??
        q.clozeSequenceData?.imageName ??
        q.dialogueCompletionData?.imageName ??
        q.appearDisappearData?.imageName ??
        q.sentenceBuilderData?.imageName;
  }

  /// Localized “Question X / Y” string for the convo header line.
  String _questionLabel(Map<String, String> strings, int current, int total) {
    final template = strings['question_x_of_y'] ?? 'Question %s / %s';
    return template.replaceFirst('%s', '$current').replaceFirst('%s', '$total');
  }

  String _titleForTemplate(String template, Map<String, String> strings) {
    final key = _kTemplateTitleL10nKeys[template];
    if (key == null) return '';
    return strings[key] ?? '';
  }

  Widget _convo1AudioControls(LevelQuestion q) {
    if (_convo1UsesDualAudio(q)) {
      final p1 = _audioAssetPathForRaw(q.audioFile1);
      final p2 = _audioAssetPathForRaw(q.audioFile2);
      final dualBusy = _convo1DualA1Playing || _convo1DualA2Playing;
      return FutureBuilder<List<bool>>(
        key: ValueKey('convo1-dual-audio-${q.questionId ?? _currentIndex}'),
        future: Future.wait([
          p1 != null ? _resolveAudioExists(p1) : Future.value(false),
          p2 != null ? _resolveAudioExists(p2) : Future.value(false),
        ]),
        builder: (context, snap) {
          final ok1 = snap.data != null && snap.data![0];
          final ok2 = snap.data != null && snap.data![1];
          if (p1 == null || p2 == null) return const SizedBox.shrink();
          if (snap.connectionState != ConnectionState.done || !ok1 || !ok2) {
            return const SizedBox.shrink();
          }
          final line1HasCloze = _convo1Line1HasCloze(q);
          final line2HasCloze = _convo1Line2HasCloze(q);
          final caseA = !line1HasCloze && line2HasCloze;
          final isCorrect = _convo1AnswerWasCorrect(q);
          final isWrongAnswered = _answerLocked && !isCorrect;
          final beforeAnswer = !_answerLocked;

          Future<void> playClip(String path, {required bool line1}) async {
            if (!mounted) return;
            setState(() {
              if (line1) {
                _convo1DualA1Playing = true;
              } else {
                _convo1DualA2Playing = true;
              }
            });
            try {
              await audio.playQuestionAudio(path);
            } finally {
              if (mounted) {
                setState(() {
                  if (line1) {
                    _convo1DualA1Playing = false;
                  } else {
                    _convo1DualA2Playing = false;
                  }
                });
              }
            }
          }

          final allowPress = beforeAnswer ? caseA : isWrongAnswered;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AudioPlayButton(
                  isPlaying: dualBusy || _convo1PostAnswerAudioPlaying,
                  onPressed: (!ok1 || !ok2 || !allowPress)
                      ? null
                      : () async {
                          if (beforeAnswer) {
                            await playClip(p1, line1: true);
                            return;
                          }
                          final startIndex = _currentIndex;
                          final startQuestionId = _currentQuestionId;
                          bool sameQuestion() =>
                              mounted &&
                              _currentIndex == startIndex &&
                              _currentQuestionId == startQuestionId;
                          setState(() => _convo1PostAnswerAudioPlaying = true);
                          try {
                            await playClip(p1, line1: true);
                            if (!sameQuestion()) return;
                            await playClip(p2, line1: false);
                          } finally {
                            if (sameQuestion()) {
                              setState(() {
                                _convo1PostAnswerAudioPlaying = false;
                              });
                            }
                          }
                        },
                ),
              ],
            ),
          );
        },
      );
    }
    final path = _audioAssetPath(q);
    if (path == null) return const SizedBox.shrink();
    return FutureBuilder<bool>(
      key: ValueKey('convo1-audio-${q.questionId ?? _currentIndex}'),
      future: _resolveAudioExists(path),
      builder: (context, snap) {
        final exists = snap.data == true;
        if (snap.connectionState != ConnectionState.done || !exists) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AudioPlayButton(
                isPlaying: _convoTtsPlaying,
                onPressed: !exists
                    ? null
                    : () async {
                        setState(() => _convoTtsPlaying = true);
                        try {
                          await audio.playQuestionAudio(path);
                        } finally {
                          if (mounted) {
                            setState(() => _convoTtsPlaying = false);
                          }
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  /// ConvoTemplate-1 body: shared regular-question media frame, a white answer panel pulled up
  /// over its bottom edge, the two dialogue bubbles as the prompt, then the 4 answer buttons.
  /// No character names or avatars appear in this panel.
  int _convo1LineCount(
    String text, {
    required double fontSize,
    required double maxWidth,
    required FontWeight fontWeight,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.2,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: max(1.0, maxWidth));
    return max(1, painter.computeLineMetrics().length);
  }

  Widget _buildConvo1Panel(
    LevelQuestion q,
    String userLanguage,
    bool soundFxOn,
  ) {
    final heroImagePath = _resolvedClozeImagePath();
    final hasImage = heroImagePath != null;
    final convoBudget = QuestionLayoutBudget.of(context);
    final answerWidth =
        convoBudget.answerWidthForAvailable(MediaQuery.sizeOf(context).width);

    return LayoutBuilder(
      builder: (context, bodyConstraints) {
        final convoMediaWidthLimit =
            convoBudget.mediaWidthForAvailable(bodyConstraints.maxWidth);
        final mediaHeight = hasImage
            ? min(
                convoMediaWidthLimit,
                convoBudget.mediaHeightForAvailable(bodyConstraints.maxHeight),
              )
            : 0.0;
        final remainderHeight = max(
          0.0,
          bodyConstraints.maxHeight - mediaHeight,
        );
        final dialogueHeight =
            remainderHeight * _convo1DialogueShareOfRemainder(convoBudget.tier);
        final gridHeight = max(0.0, remainderHeight - dialogueHeight);

        final buttonFontSize = _convo1ButtonTextSizeForTier[convoBudget.tier]!;
        final buttonPreset = _convo1ButtonPresets[convoBudget.tier]!;
        final convo1GridGap = _convo1GridGap(buttonPreset.oneLineHeight);
        final cellWidth = max(1.0, (answerWidth - convo1GridGap) / 2);
        final buttonTextWidth = max(1.0, cellWidth - 48.0);
        final maxAnswerLines = _currentOptions
            .map((option) => _convo1LineCount(
                  option,
                  fontSize: buttonFontSize,
                  maxWidth: buttonTextWidth,
                  fontWeight: FontWeight.w500,
                ))
            .fold<int>(1, max);
        final buttonRowHeight = max(
          _convo1ButtonMinTouchTarget,
          maxAnswerLines <= 1
              ? buttonPreset.oneLineHeight
              : buttonPreset.twoLineHeight + max(0, maxAnswerLines - 2) * 20.0,
        );
        final measuredGridHeight = buttonRowHeight * 2 + convo1GridGap;
        final buttonShortfall = max(0.0, measuredGridHeight - gridHeight);

        // Both dialogue lines use the same fixed hierarchy size, derived only after the
        // answer preset is selected. The dialogue card may extend upward when its measured
        // content needs more than its nominal row-count allocation.
        final bubbleFontSize = buttonFontSize * 1.1;
        final bubbleWrapWidth = answerWidth - 56;
        final dialogueContentHeight = _convo1BubbleNeededHeight(
          q.convoData!,
          bubbleFontSize,
          bubbleWrapWidth,
        );
        final dialogueTextBudget = max(0.0, dialogueHeight - 28.0);
        final dialogueShortfall =
            max(0.0, dialogueContentHeight - dialogueTextBudget);
        final dialogueLine1Count = _convo1LineCount(
          q.convoData!.line1,
          fontSize: bubbleFontSize,
          maxWidth: bubbleWrapWidth - 23.0,
          fontWeight: FontWeight.w700,
        );
        final dialogueLine2Count = _convo1LineCount(
          q.convoData!.line2,
          fontSize: bubbleFontSize,
          maxWidth: bubbleWrapWidth - 23.0,
          fontWeight: FontWeight.w700,
        );
        // Keep the media widget full-size. The parent footprint is reduced by the cascade amount
        // so the dialogue/grid can cover the media from above without resizing the media.
        final extensionCap = hasImage ? mediaHeight : 0.0;
        final totalShortfall = dialogueShortfall + buttonShortfall;
        final dialogueExtension = min(dialogueShortfall, extensionCap);
        final totalExtension = min(totalShortfall, extensionCap);
        final bubbleResult = (
          fontSize: bubbleFontSize,
          overflow: max(0.0, totalShortfall - extensionCap),
        );
        final dialogueCardHeight = dialogueHeight + dialogueExtension;
        // Spend the media-cascade budget on the grid only after the dialogue has received its
        // required extension. If the remaining shortfall cannot be absorbed without covering the
        // whole media frame, keep the grid at the largest safe height and let the answer region
        // (and only that region) use the last-resort scroll fallback.
        final gridExtension = min(
          buttonShortfall,
          max(0.0, extensionCap - dialogueExtension),
        );
        final gridHeightFinal = gridHeight + gridExtension;
        final gridNeedsScroll = buttonShortfall > gridExtension + 0.1;
        final gridBottomPadding = min(
          convo1GridGap,
          max(0.0, gridHeightFinal - convo1GridGap - measuredGridHeight),
        );

        if (maxAnswerLines > 2 ||
            dialogueLine1Count > 2 ||
            dialogueLine2Count > 2) {
          debugPrint(
            '[QuestionLayout][ConvoTemplate-1][Warning] '
            'content exceeded standard line cap '
            '(answerLines=$maxAnswerLines, '
            'line1Lines=$dialogueLine1Count, line2Lines=$dialogueLine2Count) '
            '— cascade extension is absorbing ${totalExtension.toStringAsFixed(1)}px.',
          );
        }
        if (bubbleResult.overflow > 0.1 || gridNeedsScroll) {
          debugPrint(
            '[QuestionLayout][ConvoTemplate-1][Fallback] '
            'answer content exceeds the media-cascade safety cap; '
            'answerRegionScroll=true overflow='
            '${bubbleResult.overflow.toStringAsFixed(1)}px',
          );
        }

        final convo1LayoutLogKey = [
          bodyConstraints.maxWidth,
          bodyConstraints.maxHeight,
          mediaHeight,
          totalExtension,
          dialogueHeight,
          dialogueExtension,
          gridHeight,
          gridBottomPadding,
          bubbleResult.fontSize,
          buttonFontSize,
          buttonRowHeight,
          convoBudget.tier,
        ].join('|');
        if (_convo1LastLayoutLogKey != convo1LayoutLogKey) {
          _convo1LastLayoutLogKey = convo1LayoutLogKey;
          // Explicit per-line breakdown, developer ask — both lines are driven by the exact same
          // `bubbleResult.fontSize`/`FontWeight.w700` (from `_buildConvoDialogueBubbles`'s shared
          // `TextStyle` instance), printed separately here so that can be checked directly in the
          // log instead of taken on trust.
          final revealAnswerForLog = _answerLocked ? q.convoData!.answer : null;
          final blankInLine1ForLog =
              q.convoData!.line1.contains(_kBlankPattern);
          final line1ForLog = revealAnswerForLog == null
              ? q.convoData!.line1
              : q.convoData!.line1
                  .replaceAll(_kBlankPattern, revealAnswerForLog);
          final line2ForLog = revealAnswerForLog == null
              ? q.convoData!.line2
              : q.convoData!.line2
                  .replaceAll(_kBlankPattern, revealAnswerForLog);
          debugPrint(
            '[QuestionLayout][ConvoTemplate-1] '
            'tier=${convoBudget.tier.name} '
            'localBody=${bodyConstraints.maxWidth.toStringAsFixed(1)}x'
            '${bodyConstraints.maxHeight.toStringAsFixed(1)}px '
            'media=${convoMediaWidthLimit.toStringAsFixed(1)}x'
            '${mediaHeight.toStringAsFixed(1)}px '
            'dialogueBox=${answerWidth.toStringAsFixed(1)}x'
            '${dialogueHeight.toStringAsFixed(1)}px '
            'dialogueExtension=${dialogueExtension.toStringAsFixed(1)}px '
            'totalExtension=${totalExtension.toStringAsFixed(1)}px '
            'answerLines=$maxAnswerLines '
            'gridBox=${answerWidth.toStringAsFixed(1)}x'
            '${gridHeight.toStringAsFixed(1)}px '
            'gridBottomPadding=${gridBottomPadding.toStringAsFixed(1)}px '
            'bubbleText=${bubbleResult.fontSize.toStringAsFixed(1)}px '
            'line1FontSize=${bubbleResult.fontSize.toStringAsFixed(1)}px '
            'line1Weight=w700 '
            'line1HasBlank=$blankInLine1ForLog '
            'line1="$line1ForLog" '
            'line2FontSize=${bubbleResult.fontSize.toStringAsFixed(1)}px '
            'line2Weight=w700 '
            'line2HasBlank=${!blankInLine1ForLog} '
            'line2="$line2ForLog" '
            'buttonText=${buttonFontSize.toStringAsFixed(1)}px '
            'buttonRowHeight=${buttonRowHeight.toStringAsFixed(1)}px '
            'bubbleVsButtonRatio='
            '${(bubbleResult.fontSize / buttonFontSize).toStringAsFixed(2)}x '
            'image=$hasImage',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height:
                  max(0.0, mediaHeight - totalExtension) + dialogueCardHeight,
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
                        enabled: _debugShowLayoutBounds,
                        label: 'media',
                        child: StandardQuestionMedia(
                          availableBodyHeight: bodyConstraints.maxHeight,
                          aspectRatio: 1,
                          heightOverride: mediaHeight,
                          widthOverride: convoMediaWidthLimit,
                          child: Image.asset(
                            heroImagePath,
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
                  // Dialogue card: normally a fixed device-tier share of the remainder — only
                  // the bubble font size adapts. If content still doesn't fit even at the tier's
                  // minimum readability size, `dialogueExtension` grows this card upward over
                  // the image instead of shrinking text further, capped so it can never fully
                  // cover the image.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: dialogueCardHeight,
                    child: DebugLayoutBox(
                      enabled: _debugShowLayoutBounds,
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
                        // SingleChildScrollView is pure insurance against a measurement drifting a
                        // few px from real font-metric rendering — the bisected font size and
                        // `dialogueExtension` are already solved to fit, so this should never
                        // actually need to scroll.
                        child: SingleChildScrollView(
                          child: Center(
                            child: SizedBox(
                              width: answerWidth,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildConvoDialogueBubbles(
                                      q.convoData!,
                                      fontSize: bubbleResult.fontSize,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 48,
                                    child: _convo1AudioControls(q),
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
            // Answer grid: fixed device-tier share of the remainder, divided evenly among the
            // 2x2 buttons — always the same place/size regardless of content, so buttons never
            // scroll and never lose space to dialogue-card extension.
            SizedBox(
              height: gridHeightFinal,
              child: DebugLayoutBox(
                enabled: _debugShowLayoutBounds,
                label: 'grid',
                color: Colors.blue,
                child: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    physics: gridNeedsScroll
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: Center(
                      child: SizedBox(
                        width: answerWidth,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildConvoAnswerButton(
                                    0,
                                    q,
                                    soundFxOn,
                                    fontSize: buttonFontSize,
                                    height: buttonRowHeight,
                                    width: cellWidth,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildConvoAnswerButton(
                                    1,
                                    q,
                                    soundFxOn,
                                    fontSize: buttonFontSize,
                                    height: buttonRowHeight,
                                    width: cellWidth,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: convo1GridGap),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildConvoAnswerButton(
                                    2,
                                    q,
                                    soundFxOn,
                                    fontSize: buttonFontSize,
                                    height: buttonRowHeight,
                                    width: cellWidth,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildConvoAnswerButton(
                                    3,
                                    q,
                                    soundFxOn,
                                    fontSize: buttonFontSize,
                                    height: buttonRowHeight,
                                    width: cellWidth,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: gridBottomPadding),
                          ],
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

  /// Min/regular/max bubble text size per tier — `regular` = button size × 1.10 (developer's
  /// ask: dialogue lines read 10% bigger than answer buttons). `min` is a real readability
  /// floor (never crossed — the dialogue box extends over the image instead, see
  /// `_buildConvo1Panel`), `max` a growth cap on spacious devices with short content.
  ({double min, double regular, double max}) _convo1BubbleTextProfile(
    QuestionLayoutTier tier,
  ) {
    switch (tier) {
      case QuestionLayoutTier.phoneUltraTall:
      case QuestionLayoutTier.phoneSuperTall:
        return (min: 15, regular: 20, max: 22);
      case QuestionLayoutTier.phoneFlagship:
        return (min: 14, regular: 20, max: 21);
      case QuestionLayoutTier.phoneTransition:
      case QuestionLayoutTier.phoneClassic2to1:
        return (min: 15, regular: 20, max: 22);
      case QuestionLayoutTier.phone16to9:
        return (min: 16, regular: 20, max: 22);
      case QuestionLayoutTier.tablet16to9:
      case QuestionLayoutTier.tablet16to10:
        return (min: 18, regular: 22, max: 27);
      case QuestionLayoutTier.tablet3to2:
        return (min: 19, regular: 23, max: 29);
      case QuestionLayoutTier.tablet4to3:
        return (min: 20, regular: 24, max: 31);
    }
  }

  double _convo1BubbleNeededHeight(
    ConvoQuestionData q,
    double fontSize,
    double maxWidth,
  ) {
    final answer = _answerLocked ? q.answer : null;
    final line1 =
        answer == null ? q.line1 : q.line1.replaceAll(_kBlankPattern, answer);
    final line2 =
        answer == null ? q.line2 : q.line2.replaceAll(_kBlankPattern, answer);
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: fontSize,
              height: 1.2,
              fontFamily: 'Inter',
            ) ??
        TextStyle(fontSize: fontSize, height: 1.2, fontFamily: 'Inter');
    final textMaxWidth = max(0.0, maxWidth - 23.0);
    // Whichever line holds the blank renders as RichText with a styled nested span for "_____ "
    // (bold, colored, letterSpacing: 1 — see `_buildBubbleText`), not as one flat run of plain
    // text. Measuring it as plain text understates its real width (no letterSpacing), which can
    // under-count how many lines it actually wraps to — mirror the same span structure here so
    // the estimate matches what's actually painted, not an approximation of it.
    double lineHeight(String text) {
      final InlineSpan span;
      if (text.contains(_kBlank)) {
        final parts = text.split(_kBlank);
        final children = <InlineSpan>[];
        for (var i = 0; i < parts.length; i++) {
          if (parts[i].isNotEmpty) children.add(TextSpan(text: parts[i]));
          if (i < parts.length - 1) {
            children.add(
              TextSpan(
                text: '_____ ',
                style: style.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            );
          }
        }
        span = TextSpan(style: style, children: children);
      } else {
        span = TextSpan(text: text, style: style);
      }
      final painter = TextPainter(
        text: span,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: textMaxWidth);
      return painter.height + 19;
    }

    return lineHeight(line1) + 10 + lineHeight(line2);
  }

  /// Largest bubble font size in `[min, max]` whose combined two-bubble height fits
  /// `dialogueHeight`, found by continuous bisection (not a 3-value snap) — mirrors
  /// `DialogueCompletionQuizBody`'s `_solveFontSizeForBox` shape, kept local since each
  /// template owns its own independent sizing logic. Also returns `overflow`: 0 if the chosen
  /// size fits, or how far even `min` exceeds `dialogueHeight` otherwise — the caller uses this
  /// to extend the dialogue box upward over the image rather than shrinking further.
  ({double fontSize, double overflow}) _convo1BubbleFontSizeForBox(
    ConvoQuestionData q,
    QuestionLayoutTier tier,
    double maxWidth,
    double dialogueHeight,
  ) {
    final profile = _convo1BubbleTextProfile(tier);
    final neededAtMax = _convo1BubbleNeededHeight(q, profile.max, maxWidth);
    if (neededAtMax <= dialogueHeight) {
      return (fontSize: profile.max, overflow: 0.0);
    }
    final neededAtMin = _convo1BubbleNeededHeight(q, profile.min, maxWidth);
    if (neededAtMin > dialogueHeight) {
      return (fontSize: profile.min, overflow: neededAtMin - dialogueHeight);
    }
    var lo = profile.min, hi = profile.max;
    for (var i = 0; i < 16; i++) {
      final mid = (lo + hi) / 2;
      if (_convo1BubbleNeededHeight(q, mid, maxWidth) <= dialogueHeight) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (fontSize: lo, overflow: 0.0);
  }

  /// Image-backed ConvoTemplate-1 dialogue presentation: speech bubbles only, without the
  /// character names and portrait circles used by the older conversation layout.
  Widget _buildConvoDialogueBubbles(
    ConvoQuestionData q, {
    double fontSize = 20,
  }) {
    final blankInLine1 = q.line1.contains(_kBlankPattern);
    // Always reveal the *correct* word once locked, never whichever option the learner tapped —
    // filling the blank with a wrong pick (e.g. "am") read as the game accepting it, since
    // nothing else in the sentence itself marked it wrong (the answer button's own red state was
    // the only signal). The completed sentence should be the grammatically correct one either way.
    final revealAnswer = _answerLocked ? q.answer : null;
    final line1 = revealAnswer == null
        ? q.line1
        : q.line1.replaceAll(_kBlankPattern, revealAnswer);
    final line2 = revealAnswer == null
        ? q.line2
        : q.line2.replaceAll(_kBlankPattern, revealAnswer);

    // Built once and passed to both bubbles as the same object — line1/line2 must never render
    // at different sizes (developer report: Q3 showed a visible mismatch). This removes any
    // possibility of the two bubbles' styles diverging, even though both already received the
    // same `fontSize` double before this change; constructing one shared `TextStyle` instance
    // makes that guarantee explicit rather than relying on two separate, identically-argued
    // `Theme.of(context).textTheme.titleMedium?.copyWith(...)` calls staying in sync.
    final bubbleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: fontSize,
              height: 1.2,
            ) ??
        TextStyle(fontSize: fontSize, height: 1.2);

    return Column(
      children: [
        _buildDialogueBubble(
          text: line1,
          isActive: blankInLine1,
          alignRight: false,
          style: bubbleStyle,
        ),
        const SizedBox(height: 10),
        _buildDialogueBubble(
          text: line2,
          isActive: !blankInLine1,
          alignRight: true,
          style: bubbleStyle,
        ),
      ],
    );
  }

  /// Side-by-side character columns for classic ConvoTemplate-1 presentation.
  Widget _buildCharactersRow(ConvoQuestionData q, String userLanguage) {
    final blankInLine1 = q.line1.contains(_kBlankPattern);
    final selectedAnswer = _answerLocked &&
            _selectedIndex != null &&
            _selectedIndex! < _currentOptions.length
        ? _currentOptions[_selectedIndex!]
        : null;
    final line1Text = selectedAnswer == null
        ? q.line1
        : q.line1.replaceAll(_kBlankPattern, selectedAnswer);
    final line2Text = selectedAnswer == null
        ? q.line2
        : q.line2.replaceAll(_kBlankPattern, selectedAnswer);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildCharacterColumn(
            dialogueLine: line1Text,
            isActive: blankInLine1,
            alignment: CrossAxisAlignment.start,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCharacterColumn(
            dialogueLine: line2Text,
            isActive: !blankInLine1,
            alignment: CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }

  /// One speaker column: just the dialogue bubble — no name label or avatar (no template shows
  /// character names or pictures; `character1`/`character2` still exist on the data model purely
  /// to pick a TTS voice, see `ConversationCharacterPool`).
  Widget _buildCharacterColumn({
    required String dialogueLine,
    required bool isActive,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        _buildDialogueBubble(
          text: dialogueLine,
          isActive: isActive,
          alignRight: alignment == CrossAxisAlignment.end,
        ),
      ],
    );
  }

  /// Rounded bubble around dialogue text with alignment for left/right speakers. `style`, when
  /// given, takes precedence over `fontSize` — callers that must guarantee two bubbles render
  /// at byte-identical size (`ConvoTemplate-1`'s `_buildConvoDialogueBubbles`) pass the exact
  /// same `TextStyle` instance to both, rather than relying on two separate calls with a
  /// matching-but-separately-constructed style.
  Widget _buildDialogueBubble({
    required String text,
    required bool isActive,
    required bool alignRight,
    double fontSize = 20,
    TextStyle? style,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    // Keep both dialogue lines visually consistent; the active missing word is
    // indicated by its colored underline rather than a different bubble fill.
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
      child: _buildBubbleText(
        text,
        isActive: isActive,
        fontSize: fontSize,
        style: style,
      ),
    );
  }

  /// Renders convo line text with blank highlighting when that side holds the missing word.
  /// `style` (when given) is used as-is for the base text; `fontSize` alone is the legacy path.
  Widget _buildBubbleText(
    String text, {
    required bool isActive,
    double fontSize = 20,
    TextStyle? style,
  }) {
    final baseStyle = style ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: fontSize,
              height: 1.2,
            );
    if (!text.contains(_kBlank)) {
      return Text(text, style: baseStyle);
    }
    final parts = text.split(_kBlank);
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Text(
              '_____ ',
              style: baseStyle?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      }
    }
    return RichText(
      // Unlike `Text`, `RichText` does not automatically read the ambient text scale from
      // `MediaQuery` — it must be passed explicitly, or it silently renders at 1.0x regardless
      // of the device's accessibility text-size setting. This was the actual bug behind the
      // developer's "second bubble looks bigger" report: whichever line has no blank renders
      // via plain `Text` (auto-scaled), the line with the blank renders via this `RichText`
      // (previously unscaled) — at any ambient scale above 1.0 the two would visibly diverge
      // even though `baseStyle`'s `fontSize` was already provably identical between them.
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }

  Widget _buildConvoAnswerButton(
    int optionIndex,
    LevelQuestion q,
    bool soundFxOn, {
    double? fontSize,
    double? height,
    double? width,
  }) {
    final option = _currentOptions[optionIndex];
    final correct = _convoAnswer(q) ?? '';
    final isCorrect = option == correct;
    final isSelected = _selectedIndex == optionIndex;
    if (optionIndex == 0) {
      _maybeShowTutorialFor(q);
    }

    final state = !_answerLocked
        ? McqAnswerState.neutral
        : isCorrect
            ? (_convo1TranslationPenalized
                ? McqAnswerState.revealed
                : McqAnswerState.correct)
            : isSelected
                ? McqAnswerState.wrong
                : McqAnswerState.neutral;

    final busy = _answerLocked ||
        _convoTtsPlaying ||
        _convo1DualA1Playing ||
        _convo1DualA2Playing ||
        _convo1PostAnswerAudioPlaying;

    return McqPillAnswerButton(
      label: option,
      state: state,
      fontSize: fontSize,
      minHeight: height,
      maxHeight: height,
      width: width,
      onTap: busy
          ? null
          : () {
              audio.playClick(soundFxOn: soundFxOn);
              _onAnswerTap(optionIndex);
            },
    );
  }
}

/// Compact white bubble used above guest/monster sprites during banter steps.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble(this.text, {this.maxWidth = 120});

  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Draws the circular countdown wedge for image-quiz time pressure (filled fraction = remaining time).
class _PieTimerPainter extends CustomPainter {
  const _PieTimerPainter({required this.progress, required this.color});

  /// 1.0 = full circle (time just started), 0.0 = empty (time up).
  final double progress;
  final Color color;

  /// Paints grey track, colored sweep from 12 o’clock, and outer ring stroke.
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.grey.shade300,
    );

    // Filled pie slice (shrinks clockwise as time runs out)
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -pi / 2, // start at 12 o'clock
        2 * pi * progress, // sweep clockwise
        true, // close to center (pie slice)
        Paint()..color = color,
      );
    }

    // Border ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey.shade500
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  /// Repaints when the animation value or color changes between frames.
  @override
  bool shouldRepaint(covariant _PieTimerPainter old) =>
      old.progress != progress || old.color != color;
}

/// Streak lines trailing the monster during slide transitions after wrong answers.
class _WindPainter extends CustomPainter {
  _WindPainter(this.value);

  final double value;

  // Horizontal wind lines trailing to the RIGHT of the monster (behind it as it moves left).
  // Lines start just outside the right edge and extend further right.
  // Fade in fast, fade out slowly over the animation duration.
  /// Draws fading horizontal strokes keyed by [value] for the wind gust effect.
  @override
  void paint(Canvas canvas, Size size) {
    if (value <= 0 || value >= 1) return;
    // Fade in during first 30%, stay visible, fade out in last 30%
    final opacity = value < 0.3
        ? value / 0.3
        : value > 0.7
            ? (1 - value) / 0.3
            : 1.0;
    if (opacity <= 0) return;

    // Lines shift rightward as animation progresses (trail effect)
    final shift = size.width * 0.4 * value;

    // 5 horizontal lines at different vertical positions and lengths
    const lineSpecs = [
      (yFrac: 0.20, length: 48.0, width: 2.5),
      (yFrac: 0.35, length: 36.0, width: 2.0),
      (yFrac: 0.50, length: 56.0, width: 3.0),
      (yFrac: 0.65, length: 32.0, width: 2.0),
      (yFrac: 0.80, length: 44.0, width: 2.5),
    ];

    for (final spec in lineSpecs) {
      final paint = Paint()
        ..color = Colors.lightBlue.withValues(alpha: opacity * 0.85)
        ..strokeWidth = spec.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final y = size.height * spec.yFrac;
      // Start just beyond the right edge, extend further right
      final startX = size.width + 6 + shift;
      final endX = startX + spec.length;
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    }
  }

  /// Repaints every tick of the wind animation controller.
  @override
  bool shouldRepaint(covariant _WindPainter oldDelegate) =>
      oldDelegate.value != value;
}
