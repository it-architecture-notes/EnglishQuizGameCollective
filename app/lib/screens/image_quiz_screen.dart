import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/guest_animal_conversations.dart';
import '../../models/level_completion_result.dart';
import '../../models/level_config.dart';
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
import '../../services/quiz_progress_service.dart';
import '../../services/reminder_progress_service.dart';
import '../../services/test_data_service.dart';
import 'quiz_templates/appear_disappear_quiz_body.dart';
import 'quiz_templates/cloze_sequence_quiz_body.dart';
import 'quiz_templates/simon_quiz_body.dart';

/// Minimum images per level (spec).
const int kMinImagesPerLevel = 4;

// TODO(test): remove before release — auto-completes after first answer.
const bool _kTestAutoComplete = false;

const String _kBlank = '_____';

/// Minimum touch target size (accessibility).
const double kMinTouchTarget = 48;

enum _Phase { loading, playing, end, gameOver }

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
  /// When true, [_goNext] ends the run after the 3rd question (index 2) with 2 stars.
  bool _shortQuizDebug = false;
  bool _endedEarlyShortQuiz = false;
  bool _answerLocked = false;
  bool _showNext = false;
  bool _reviewingMistakes = false;
  int _initialQuestionCount = 0;
  int? _selectedIndex; // 0..3 index into current options
  List<String> _currentOptions = [];
  DateTime? _quizStartTime;

  // Timer
  late AnimationController _timerController;

  // Monster / guest animal
  int _monsterStep = 0;
  int _wrongCount = 0;
  int _monsterStepThreshold = 1;
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
  /// Parallel to [_convoQuestions]: asset path for [ConvoTemplate-2] hero image, else null.
  List<String?> _convo2HeroPaths = [];
  final Map<String, LevelQuestion> _convoByQuestionId = {};
  final Map<String, String> _convo2ImagePathByQuestionId = {};
  bool _showTranslation = false;

  // Unified mode (mixed question types in a single pass)
  List<LevelQuestion> _allQuestions = [];
  List<String?> _questionImagePaths = [];      // asset path per question (null for vocab)
  List<List<String>> _questionQuiz2Paths = []; // 4 paths per template-2 question (empty otherwise)
  List<String?> _questionConvo2HeroPaths = []; // hero image path for ConvoTemplate-2 (null otherwise)

  /// Asset-bundle prefix key for resolving images under this sub-level’s folder.
  static String _levelKey(SubLevel sub) =>
      imageQuizLevelKey(sub.iconImageName);

  /// True when this route is the reminder replay flow rather than a normal sub-level.
  bool get _isReminder => widget.reminderMode;
  /// Stable ID for the active question (reminder + progress tracking).
  String? get _currentQuestionId =>
      _currentQuestionIds.isEmpty ? null : _currentQuestionIds[_currentIndex];

  /// Whether the current index points at a non-image (vocab/grammar) template.
  bool get _isConvoMode {
    if (_allQuestions.isNotEmpty) {
      final i = _currentIndex.clamp(0, _allQuestions.length - 1);
      return _allQuestions[i].type != LevelQuestionType.image;
    }
    return _convoQuestions.isNotEmpty || _convoByQuestionId.isNotEmpty;
  }

  /// The structured row for the active convo question, or null during pure image prompts.
  LevelQuestion? get _currentConvoLevelQuestion {
    if (_allQuestions.isNotEmpty) {
      if (_currentIndex >= _allQuestions.length) return null;
      final q = _allQuestions[_currentIndex];
      return q.type != LevelQuestionType.image ? q : null;
    }
    if (!_isConvoMode) return null;
    if (_isReminder) return _convoByQuestionId[_currentQuestionId ?? ''];
    return _currentIndex < _convoQuestions.length
        ? _convoQuestions[_currentIndex]
        : null;
  }

  /// Used to offer “view full conversation” on the end card when any ConvoTemplate-1 appeared.
/// Correct MCQ string for ConvoTemplate-1/2 only (other templates self-score).
  String? _convoAnswer(LevelQuestion? q) {
    if (q == null) return null;
    if (q.template == 'ConvoTemplate-1') return q.convoData?.answer;
    if (q.template == 'ConvoTemplate-2') return q.convo2Data?.answer;
    return null;
  }

  /// Number of questions in this run (unified list, reminder IDs, legacy image-only, or convo-only).
  int get _questionCount {
    if (_allQuestions.isNotEmpty) return _allQuestions.length;
    if (_isReminder) return _currentQuestionIds.length;
    if (_convoQuestions.isNotEmpty || _convoByQuestionId.isNotEmpty) return _convoQuestions.length;
    if (_configImageQuestions != null) return _configImageQuestions!.length;
    return _questionAssetPaths.length;
  }

  /// 1-based index shown in the header (“Question N / M”).
  int get _displayQuestionIndexOneBased => _currentIndex + 1;

  /// Denominator for the header; in reminder mode uses the initial batch size.
  int get _displayQuestionTotal {
    if (_isReminder) return _initialQuestionCount;
    return _questionCount;
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
    _timerController.dispose();
    _windController.dispose();
    _monsterIdleController.dispose();
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
          levelCfg = await loadLevelConfig(widget.subLevel.iconImageName);
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

        final totalQuestions = shuffled.length;
        final threshold = max(1, min(4, (totalQuestions * 0.1).round()));
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
            _monsterStepThreshold = threshold;
            _guestAnimal = guestAnimal;
            _selectedMonster = selectedMonster;
            _shortQuizDebug = shortQuizDebug;
            _endedEarlyShortQuiz = false;
            _phase = _Phase.playing;
            _quizStartTime = DateTime.now();
            _currentOptions = _buildOptions();
          });
          _timerController.duration =
              Duration(seconds: _config.imageQuizTimerSeconds);
          _startTimer();
          final musicOn = ref.read(settingsProvider).valueOrNull?.musicOn ?? true;
          audio.startQuizMusic(musicOn: musicOn);
        }
        return;
      }

      // Unified: load all questions (image + vocab/grammar) in a single pass
      final questions = levelCfg.questions.toList();
      final imgPaths = <String?>[];
      final q2Paths = <List<String>>[];
      final convo2HeroPaths = <String?>[];

      for (final q in questions) {
        if (q.type == LevelQuestionType.image) {
          if (q.template == 'imageQuizTemplate-1') {
            final d = q.imageData!;
            final path = await resolveQuizImageAsset(key, d.imageName);
            if (path == null) throw Exception('Missing image asset for: ${d.imageName}');
            imgPaths.add(path);
            q2Paths.add(const []);
            convo2HeroPaths.add(null);
          } else if (q.template == 'imageQuizTemplate-2') {
            final d = q.imageQuiz2Data!;
            final path = await resolveQuizImageAsset(key, d.imageName);
            if (path == null) throw Exception('Missing image asset for: ${d.imageName}');
            imgPaths.add(path);
            final four = <String>[];
            for (final stem in [d.imageName, ...d.wrongAnswers]) {
              final p = await resolveQuizImageAsset(key, stem);
              if (p == null) throw Exception('Missing image asset for: $stem');
              four.add(p);
            }
            q2Paths.add(four);
            convo2HeroPaths.add(null);
          } else {
            imgPaths.add(null);
            q2Paths.add(const []);
            convo2HeroPaths.add(null);
          }
        } else {
          // vocab / grammar
          imgPaths.add(null);
          q2Paths.add(const []);
          if (q.template == 'ConvoTemplate-2') {
            final d = q.convo2Data!;
            final path = await resolveQuizImageAsset(key, d.imageName);
            if (path == null) throw Exception('Missing image asset for: ${d.imageName}');
            convo2HeroPaths.add(path);
          } else {
            convo2HeroPaths.add(null);
          }
        }
      }

      // Precache images
      if (mounted) {
        for (var i = 0; i < questions.length; i++) {
          if (!mounted) break;
          final q = questions[i];
          if (q.type == LevelQuestionType.image) {
            if (q.template == 'imageQuizTemplate-2') {
              for (final p in q2Paths[i]) {
                await precacheImage(AssetImage(p), context);
              }
            } else if (imgPaths[i] != null) {
              await precacheImage(AssetImage(imgPaths[i]!), context);
            }
          } else if (convo2HeroPaths[i] != null) {
            await precacheImage(AssetImage(convo2HeroPaths[i]!), context);
          }
        }
      }

      final questionIds = List.generate(
        questions.length,
        (i) => buildReminderQuestionId(widget.progressKey, i),
      );
      final totalQuestions = questions.length;
      final threshold = max(1, min(4, (totalQuestions * 0.1).round()));
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

      if (mounted) {
        setState(() {
          _config = config;
          _conversations = conversations;
          _allQuestions = questions;
          _questionImagePaths = imgPaths;
          _questionQuiz2Paths = q2Paths;
          _questionConvo2HeroPaths = convo2HeroPaths;
          _currentQuestionIds = questionIds;
          _initialQuestionCount = questions.length;
          _monsterStepThreshold = threshold;
          _guestAnimal = guestAnimal;
          _selectedMonster = selectedMonster;
          _shortQuizDebug = shortQuizDebug;
          _endedEarlyShortQuiz = false;
          _phase = _Phase.playing;
          _quizStartTime = DateTime.now();
          _currentOptions = _buildOptions();
        });
        // Start timer only for image questions (first question might be vocab)
        if (questions.isNotEmpty && questions.first.type == LevelQuestionType.image) {
          _timerController.duration = Duration(seconds: _config.imageQuizTimerSeconds);
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
      final convo2PathByQuestionId = <String, String>{};
      final reminderImageQuestionById = <String, LevelQuestion>{};
      final reminderImageQuiz2PathsById = <String, List<String>>{};
      final validQuestionIds = <String>[];

      for (final questionId in reminderQuestionIds) {
        final (progressKey, questionIndex) =
            parseReminderQuestionId(questionId);
        final sourceItem = sourceLevels[progressKey];
        if (sourceItem == null) continue;
        final levelKey = imageQuizLevelKey(sourceItem.sub.iconImageName);
        LevelConfig? lc;
        try {
          lc = await loadLevelConfig(sourceItem.sub.iconImageName);
        } catch (_) {
          lc = null;
        }
        if (lc != null &&
            questionIndex >= 0 &&
            questionIndex < lc.questions.length) {
          final q = lc.questions[questionIndex];
          if (q.type == LevelQuestionType.image &&
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
              final vocabulary = loadedVocabulary[progressKey] ??=
                  manifestPaths.map(assetPathToBasename).toList(growable: false);
              vocabularyByQuestionId[questionId] = vocabulary;
              wrongThreeByQuestionId[questionId] = q.imageData!.wrongAnswers;
              validQuestionIds.add(questionId);
              continue;
            }
          } else if (q.type == LevelQuestionType.image &&
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
              final vocabulary = loadedVocabulary[progressKey] ??=
                  manifestPaths.map(assetPathToBasename).toList(growable: false);
              vocabularyByQuestionId[questionId] = vocabulary;
              wrongThreeByQuestionId[questionId] = d.wrongAnswers;
              validQuestionIds.add(questionId);
              continue;
            }
          } else if (q.type != LevelQuestionType.image &&
              (q.convoData != null ||
                  q.convo2Data != null ||
                  q.appearDisappearData != null ||
                  q.simonData != null ||
                  q.clozeSequenceData != null)) {
            convoByQuestionId[questionId] = q;
            if (q.template == 'ConvoTemplate-2' && q.convo2Data != null) {
              final p = await resolveQuizImageAsset(
                levelKey,
                q.convo2Data!.imageName,
              );
              if (p != null) convo2PathByQuestionId[questionId] = p;
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
          final c2 = convo2PathByQuestionId[questionId];
          if (c2 != null && mounted) {
            await precacheImage(AssetImage(c2), context);
          }
        }
      }

      final totalQuestions = validQuestionIds.length;
      final threshold = max(1, min(4, (totalQuestions * 0.1).round()));
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
        _convo2ImagePathByQuestionId
          ..clear()
          ..addAll(convo2PathByQuestionId);
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
        _monsterStepThreshold = threshold;
        _guestAnimal = guestAnimal;
        _selectedMonster = selectedMonster;
        _shortQuizDebug = shortQuizDebug;
        _endedEarlyShortQuiz = false;
        _reviewingMistakes = false;
        _phase = _Phase.playing;
        _quizStartTime = DateTime.now();
        _currentOptions = _buildOptions();
      });
      if (!isConvoReminder) {
        _timerController.duration =
            Duration(seconds: _config.imageQuizTimerSeconds);
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

  /// Restarts the pie countdown and monster idle loop for the current image question.
  void _startTimer() {
    _timerController
      ..reset()
      ..forward();
    if (!_monsterIdleController.isAnimating) {
      _monsterIdleController.repeat(reverse: true);
    }
  }

  /// Fires when the image timer completes without an answer; counts as wrong and shows Next.
  void _onTimerExpired() {
    if (_answerLocked) return;
    _timerController.stop();
    final soundFxOn = ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
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
    _wrongCount++;
    final newStep = min(4, _wrongCount ~/ _monsterStepThreshold);
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
          if (_monsterStep >= 1 && _monsterStep <= 3 && _conversations != null) {
            final pair = pickRandomStepConversation(_conversations!, _monsterStep);
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
      if (q.type == LevelQuestionType.image) {
        if (q.template == 'imageQuizTemplate-2') return q.imageQuiz2Data!.imageName;
        final path = _currentIndex < _questionImagePaths.length ? _questionImagePaths[_currentIndex] : null;
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
        return rq!.imageQuiz2Data!.imageName;
      }
    }
    if (_configImageQuestions != null) {
      final q = _configImageQuestions![_currentIndex];
      if (q.template == 'imageQuizTemplate-2') {
        return q.imageQuiz2Data!.imageName;
      }
    }
    return assetPathToBasename(_questionAssetPaths[_currentIndex]);
  }

  /// Shuffled four choices for MCQ templates; empty when the template renders its own grid.
  List<String> _buildOptions() {
    if (_allQuestions.isNotEmpty) {
      if (_currentIndex >= _allQuestions.length) return [];
      final q = _allQuestions[_currentIndex];
      if (q.type != LevelQuestionType.image) {
        if (q.template != 'ConvoTemplate-1' && q.template != 'ConvoTemplate-2') return [];
        final ans = _convoAnswer(q);
        final dist = q.template == 'ConvoTemplate-1'
            ? q.convoData!.distractors
            : q.convo2Data!.distractors;
        if (ans == null) return [];
        return ([ans, ...dist]..shuffle(Random()));
      }
      // Image question
      if (q.template == 'imageQuizTemplate-2' && q.imageQuiz2Data != null) {
        final d = q.imageQuiz2Data!;
        return ([d.imageName, ...d.wrongAnswers]..shuffle(Random()));
      }
      final correct = _correctAnswer();
      if (q.imageData != null && q.imageData!.wrongAnswers.length == 3) {
        return ([correct, ...q.imageData!.wrongAnswers]..shuffle(Random()));
      }
      final wrongPool = _vocabulary.where((s) => s != correct).toList()..shuffle(Random());
      return ([correct, ...wrongPool.take(3)]..shuffle(Random()));
    }
    if (_isConvoMode) {
      final q = _currentConvoLevelQuestion;
      if (q == null) return [];
      // Interactive templates (AppearDisappear, Simon, ClozeSequence) manage
      // their own options internally — no shared options list needed.
      if (q.template != 'ConvoTemplate-1' && q.template != 'ConvoTemplate-2') {
        return [];
      }
      final ans = _convoAnswer(q);
      final dist = q.template == 'ConvoTemplate-1'
          ? q.convoData!.distractors
          : q.convo2Data!.distractors;
      if (ans == null) return [];
      return ([ans, ...dist]..shuffle(Random()));
    }
    if (_isReminder && _currentQuestionId != null) {
      final rq = _reminderImageQuestionsById[_currentQuestionId!];
      if (rq?.template == 'imageQuizTemplate-2' && rq!.imageQuiz2Data != null) {
        final d = rq.imageQuiz2Data!;
        return ([d.imageName, ...d.wrongAnswers]..shuffle(Random()));
      }
    }
    final correct = _correctAnswer();
    if (_configImageQuestions != null) {
      final q = _configImageQuestions![_currentIndex];
      if (q.template == 'imageQuizTemplate-2' && q.imageQuiz2Data != null) {
        final d = q.imageQuiz2Data!;
        return ([d.imageName, ...d.wrongAnswers]..shuffle(Random()));
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

  /// Handles ConvoTemplate-1/2 and image multiple-choice taps; schedules advance or Next on wrong.
  void _onAnswerTap(int optionIndex) {
    if (_answerLocked) return;
    if (_kTestAutoComplete) {
      _correctCount = 100;
      setState(() => _phase = _Phase.end);
      return;
    }
    if (!_isConvoMode) _timerController.stop();
    final option = _currentOptions[optionIndex];
    final correct = _correctAnswer();
    final isCorrect = option == correct;
    final soundFxOn = ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
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

  /// Advances index or ends the run; handles debug short-quiz, reminder review pass, and per-question timers.
  void _goNext() {
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
        _phase = _Phase.end;
        _bubbleConversation = null;
      });
      return;
    }
    setState(() {
      _currentIndex++;
      _answerLocked = false;
      _showNext = false;
      _selectedIndex = null;
      _bubbleConversation = null;
      _currentOptions = _buildOptions();
    });
    if (_allQuestions.isNotEmpty) {
      if (_currentIndex < _allQuestions.length &&
          _allQuestions[_currentIndex].type == LevelQuestionType.image) {
        _timerController.duration = Duration(seconds: _config.imageQuizTimerSeconds);
        _startTimer();
      }
    } else if (!_isConvoMode) {
      _startTimer();
    }
  }

  /// Maps accuracy percentage to 0–3 stars (fixed 2 stars when debug early-exit fired).
  int _stars() {
    if (_endedEarlyShortQuiz) return 2;
    if (_questionCount == 0) return 0;
    final rate = (_correctCount / _questionCount) * 100;
    if (rate >= 85) return 3;
    if (rate >= 70) return 2;
    if (rate >= 60) return 1;
    return 0;
  }

  /// Diamonds shown on the end screen equal correct answers earned this session.
  int _diamondsEarned() => _correctCount;

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
        questionCount: _endedEarlyShortQuiz ? 3 : _questionCount,
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
    final soundFxOn = ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
    final strings =
        ref.watch(currentLocalizedStringsProvider).valueOrNull ?? {};
    final userLanguage =
        ref.watch(settingsProvider).valueOrNull?.language ?? 'en';
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: SafeArea(
        child: _buildBody(soundFxOn, strings, userLanguage),
      ),
    );
  }

  /// Central phase switch between loading spinner, playing layouts, summary, and game-over screen.
  Widget _buildBody(bool soundFxOn, Map<String, String> strings, String userLanguage) {
    switch (_phase) {
      case _Phase.loading:
        return _buildLoading(soundFxOn, strings);
      case _Phase.playing:
        return _isConvoMode
            ? _buildConvoPlaying(soundFxOn, strings, userLanguage)
            : _buildImagePlaying(soundFxOn, strings);
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
    final order = [d.imageName, ...d.wrongAnswers];
    final i = order.indexOf(stem);
    if (i < 0 || i >= fourOrdered.length) return null;
    return fourOrdered[i];
  }

  /// Seconds to wait after a correct image answer before auto-calling [_goNext].
  double _autoAdvanceDelayForCurrentImageQuestion() {
    final d2 = _currentImageQuiz2Data();
    if (d2 != null) return d2.autoNextDelay;
    return _config.autoAdvanceDelaySeconds;
  }

  /// Callback from interactive convo widgets; correct path scores and delays [_goNext], wrong shows Next.
  void _handleInteractiveConvoOutcome(LevelQuestion q, bool correct) {
    if (correct) {
      AchievementService.instance.recordAnswer(true);
      final delaySec = switch (q.template) {
        'ConvoTemplate-AppearDisappear' =>
          q.appearDisappearData!.autoNextDelay,
        'ConvoTemplate-Simon' => q.simonData!.autoNextDelay,
        'ConvoTemplate-ClozeSequence' => q.clozeSequenceData!.autoNextDelay,
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
        _showNext = true;
      });
    }
  }

  /// Image phase layout: hero image or template-2 grid, monster lane, timer, and option buttons.
  Widget _buildImagePlaying(bool soundFxOn, Map<String, String> strings) {
    final path = _allQuestions.isNotEmpty
        ? (_currentIndex < _questionImagePaths.length ? _questionImagePaths[_currentIndex] ?? '' : '')
        : _questionAssetPaths[_currentIndex];
    final isLast = _currentIndex + 1 >= _questionCount;
    final d2 = _currentImageQuiz2Data();
    final four = _fourOrderedPathsForCurrentImageQuiz2();
    final isTemplate2 = d2 != null && four != null;
    final iq2 = d2;
    final paths4 = four;

    return Column(
      children: [
        // Reminder question counter (reminder mode only)
        if (_isReminder)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              _reviewingMistakes
                  ? (strings['reviewing_mistakes'] ?? 'Reviewing Mistakes')
                  : '$_displayQuestionIndexOneBased / $_displayQuestionTotal',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        if (isTemplate2 && iq2 != null)
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  _nounLabelFromImageStem(iq2.imageName),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Expanded(
            flex: 1,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.25,
                  maxWidth: MediaQuery.sizeOf(context).width * 0.5,
                ),
                child: Image.asset(
                  path,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported, size: 64),
                  ),
                ),
              ),
            ),
          ),
        // Speech bubbles — appear above animal/monster after slide completes
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              final minMonsterCenter = animalSize + gap + monsterSize / 2;
              final range = maxMonsterCenter - minMonsterCenter;

              // Stone i=0 is rightmost (step-0 landing), i=3 is leftmost (step-3 landing)
              // Monster center at step k aligns with stone k center
              final step = _monsterStep.clamp(0, 3);
              final monsterCenter = maxMonsterCenter - step * (range / 3);
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
                                painter: _WindPainter(_windController.value),
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
                                final remaining = 1.0 - _timerController.value;
                                final color = Color.lerp(
                                    Colors.red, Colors.green, remaining)!;
                                return CustomPaint(
                                  size: Size(pieTimerSize, pieTimerSize),
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
                                offset: Offset(-monsterSize * 0.10 * t, 0),
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
                      final stoneCenter = maxMonsterCenter - i * (range / 3);
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
        if (isTemplate2 && iq2 != null && paths4 != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: List.generate(4, (i) {
                final option = _currentOptions[i];
                final assetPath =
                    _assetPathForImageQuiz2Stem(iq2, paths4, option);
                final isCorrect = option == _correctAnswer();
                final isSelected = _selectedIndex == i;
                // Same as imageQuizTemplate-1 MCQ: correct cell turns green when locked; wrong pick turns red.
                final showGreen = _answerLocked && isCorrect;
                final showRed = _answerLocked && isSelected && !isCorrect;
                return Material(
                  color: showGreen
                      ? Colors.green.shade200
                      : showRed
                          ? Colors.red.shade200
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _answerLocked
                        ? null
                        : () {
                            audio.playClick(soundFxOn: soundFxOn);
                            _onAnswerTap(i);
                          },
                    child: assetPath != null
                        ? Image.asset(
                            assetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              size: 48,
                            ),
                          )
                        : const Icon(Icons.image_not_supported),
                  ),
                );
              }),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(4, (i) {
                final option = _currentOptions[i];
                final isCorrect = option == _correctAnswer();
                final isSelected = _selectedIndex == i;
                Color? bgColor;
                Color? fgColor;
                if (_answerLocked) {
                  if (isCorrect) {
                    bgColor = Colors.green.shade600;
                    fgColor = Colors.white;
                  } else if (isSelected && !isCorrect) {
                    bgColor = Colors.red.shade600;
                    fgColor = Colors.white;
                  }
                }
                final buttonStyle = bgColor != null
                    ? ElevatedButton.styleFrom(
                        backgroundColor: bgColor,
                        foregroundColor: fgColor,
                        surfaceTintColor: Colors.transparent,
                        disabledBackgroundColor: bgColor,
                        disabledForegroundColor: fgColor,
                        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
                      )
                    : ElevatedButton.styleFrom(
                        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade800,
                        surfaceTintColor: Colors.transparent,
                      );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: kMinTouchTarget + 8,
                    child: ElevatedButton(
                      onPressed: _answerLocked
                          ? null
                          : () {
                              audio.playClick(soundFxOn: soundFxOn);
                              _onAnswerTap(i);
                            },
                      style: buttonStyle,
                      child: Text(
                        _capitalize(option),
                        style: fgColor != null
                            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: fgColor,
                                  fontWeight: FontWeight.w600,
                                )
                            : Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        // Next / Finish — reserve space so layout doesn't jump when button appears
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: kMinTouchTarget + 8,
            child: _showNext
                ? FilledButton(
                    onPressed: () {
                      audio.playClick(soundFxOn: soundFxOn);
                      _goNext();
                    },
                    child: Text(
                      _isReminder
                          ? (strings['next'] ?? 'Next')
                          : (isLast
                              ? (strings['finish'] ?? 'Finish')
                              : (strings['next'] ?? 'Next')),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
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
    final displayTotal = _displayQuestionTotal;
    final isLast = _currentIndex + 1 >= _questionCount;
    final reminderProgress = _reviewingMistakes
        ? 1.0
        : (_initialQuestionCount <= 0
            ? 0.0
            : (_currentIndex + 1) / _initialQuestionCount);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              Text(
                _isReminder && _reviewingMistakes
                    ? (strings['reviewing_mistakes'] ?? 'Reviewing Mistakes')
                    : _questionLabel(
                        strings, _displayQuestionIndexOneBased, displayTotal),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (_isReminder) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: reminderProgress),
              ],
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _buildConvoQuestionBody(q, userLanguage, soundFxOn, strings),
          ),
        ),
        if (q.template == 'ConvoTemplate-1' || q.template == 'ConvoTemplate-2')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                  4, (i) => _buildConvoAnswerButton(i, q, soundFxOn)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: kMinTouchTarget + 8,
            child: _showNext
                ? FilledButton(
                    onPressed: () {
                      audio.playClick(soundFxOn: soundFxOn);
                      _goNext();
                    },
                    child: Text(
                      _isReminder
                          ? (strings['next'] ?? 'Next')
                          : (isLast
                              ? (strings['finish'] ?? 'Finish')
                              : (strings['next'] ?? 'Next')),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        if (!_isReminder && userLanguage != 'en')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  audio.playClick(soundFxOn: soundFxOn);
                  setState(() => _showTranslation = !_showTranslation);
                },
                icon: Icon(
                  _showTranslation
                      ? Icons.translate
                      : Icons.g_translate_outlined,
                  size: 18,
                ),
                label: Text(
                  _showTranslation
                      ? (strings['english'] ?? 'English')
                      : (strings['translate'] ?? 'Translate'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Picks the correct child widget for the active convo template (including interactive mini-games).
  Widget _buildConvoQuestionBody(
    LevelQuestion q,
    String userLanguage,
    bool soundFxOn,
    Map<String, String> strings,
  ) {
    switch (q.template) {
      case 'ConvoTemplate-AppearDisappear':
        return AppearDisappearQuizBody(
          key: ValueKey('ad-${_currentQuestionId ?? '$_currentIndex'}'),
          data: q.appearDisappearData!,
          strings: strings,
          onPlayCorrect: () =>
              audio.playCorrect(soundFxOn: soundFxOn),
          onPlayWrong: () => audio.playWrong(soundFxOn: soundFxOn),
          onOutcome: (correct) => _handleInteractiveConvoOutcome(q, correct),
        );
      case 'ConvoTemplate-Simon':
        return SimonQuizBody(
          key: ValueKey('simon-${_currentQuestionId ?? '$_currentIndex'}'),
          data: q.simonData!,
          soundFxOn: soundFxOn,
          onPlayCorrect: () =>
              audio.playCorrect(soundFxOn: soundFxOn),
          onPlayWrong: () => audio.playWrong(soundFxOn: soundFxOn),
          onOutcome: (correct) => _handleInteractiveConvoOutcome(q, correct),
        );
      case 'ConvoTemplate-ClozeSequence':
        return ClozeSequenceQuizBody(
          key: ValueKey('clz-${_currentQuestionId ?? '$_currentIndex'}'),
          data: q.clozeSequenceData!,
          onPlayCorrect: () =>
              audio.playCorrect(soundFxOn: soundFxOn),
          onPlayWrong: () => audio.playWrong(soundFxOn: soundFxOn),
          onOutcome: (correct) => _handleInteractiveConvoOutcome(q, correct),
        );
      case 'ConvoTemplate-2':
        return _buildConvoTemplate2Content(q, userLanguage);
      default:
        return _buildCharactersRow(q.convoData!, userLanguage);
    }
  }

  /// Sentence bubble plus small hero image for ConvoTemplate-2 cloze prompts.
  Widget _buildConvoTemplate2Content(LevelQuestion q, String userLanguage) {
    final d = q.convo2Data!;
    final path = _isReminder
        ? _convo2ImagePathByQuestionId[_currentQuestionId ?? '']
        : (_allQuestions.isNotEmpty
            ? (_currentIndex < _questionConvo2HeroPaths.length ? _questionConvo2HeroPaths[_currentIndex] : null)
            : (_currentIndex < _convo2HeroPaths.length ? _convo2HeroPaths[_currentIndex] : null));
    // Always show locale-aware sentence: English for 'en', English + (answer
    // translation) for other locales — no toggle needed.
    final line = d.sentence[userLanguage] ?? d.sentence['en'] ?? '';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!,
              child: _buildBubbleText(line, isActive: true),
            ),
          ),
          if (path != null) ...[
            const SizedBox(height: 12),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  path,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Localized “Question X / Y” string for the convo header line.
  String _questionLabel(Map<String, String> strings, int current, int total) {
    final template = strings['question_x_of_y'] ?? 'Question %s / %s';
    return template
        .replaceFirst('%s', '$current')
        .replaceFirst('%s', '$total');
  }

  /// Side-by-side character columns for classic ConvoTemplate-1 presentation.
  Widget _buildCharactersRow(ConvoQuestionData q, String userLanguage) {
    final blankInLine1 = q.line1['en']?.contains(_kBlank) ?? false;
    final line1Text = _showTranslation
        ? (q.line1[userLanguage] ?? q.line1['en'] ?? '')
        : (q.line1['en'] ?? '');
    final line2Text = _showTranslation
        ? (q.line2[userLanguage] ?? q.line2['en'] ?? '')
        : (q.line2['en'] ?? '');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildCharacterColumn(
            name: q.character1,
            dialogueLine: line1Text,
            isActive: blankInLine1,
            alignment: CrossAxisAlignment.start,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCharacterColumn(
            name: q.character2,
            dialogueLine: line2Text,
            isActive: !blankInLine1,
            alignment: CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }

  /// One speaker column: bubble, name label, and circular avatar asset.
  Widget _buildCharacterColumn({
    required String name,
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
        const SizedBox(height: 8),
        Text(
          _capitalize(name),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _buildCharacterAvatar(name, size: 64),
      ],
    );
  }

  /// Loads `assets/images/characters/{name}.png` or falls back to an initial letter avatar.
  Widget _buildCharacterAvatar(String name, {required double size}) {
    final imagePath = 'assets/images/characters/$name.png';
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            return CircleAvatar(
              radius: size / 2,
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Rounded bubble around dialogue text with alignment for left/right speakers.
  Widget _buildDialogueBubble({
    required String text,
    required bool isActive,
    required bool alignRight,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isActive
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final borderColor =
        isActive ? colorScheme.primary : colorScheme.outlineVariant;

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
      child: _buildBubbleText(text, isActive: isActive),
    );
  }

  /// Renders convo line text with blank highlighting when that side holds the missing word.
  Widget _buildBubbleText(String text, {required bool isActive}) {
    if (!text.contains(_kBlank)) {
      return Text(text, style: Theme.of(context).textTheme.bodySmall);
    }
    final parts = text.split(_kBlank);
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
              child: Text(
                ' ____ ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
              ),
            ),
          ),
        );
      }
    }
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: spans,
      ),
    );
  }

  /// One shuffled MCQ row for ConvoTemplate-1/2 with locked-state coloring after answering.
  Widget _buildConvoAnswerButton(
      int optionIndex, LevelQuestion q, bool soundFxOn) {
    final option = _currentOptions[optionIndex];
    final correct = _convoAnswer(q) ?? '';
    final isCorrect = option == correct;
    final isSelected = _selectedIndex == optionIndex;

    Color? bgColor;
    Color? fgColor;
    if (_answerLocked) {
      if (isCorrect) {
        bgColor = Colors.green.shade600;
        fgColor = Colors.white;
      } else if (isSelected) {
        bgColor = Colors.red.shade600;
        fgColor = Colors.white;
      }
    }

    final buttonStyle = bgColor != null
        ? ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            surfaceTintColor: Colors.transparent,
            disabledBackgroundColor: bgColor,
            disabledForegroundColor: fgColor,
            minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
          )
        : ElevatedButton.styleFrom(
            minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade800,
            surfaceTintColor: Colors.transparent,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: kMinTouchTarget + 8,
        child: ElevatedButton(
          onPressed: _answerLocked
              ? null
              : () {
                  audio.playClick(soundFxOn: soundFxOn);
                  _onAnswerTap(optionIndex);
                },
          style: buttonStyle,
          child: Text(
            _capitalize(option),
            style: fgColor != null
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                    )
                : Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }

  /// Title-cases option labels shown on convo and image answer buttons.
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
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
