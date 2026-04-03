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
import '../../quiz_game_constants.dart';
import '../../services/profile_service.dart';
import '../../services/quiz_progress_service.dart';
import '../../services/reminder_progress_service.dart';
import '../../services/test_data_service.dart';

/// Minimum images per level (spec).
const int kMinImagesPerLevel = 4;

// TODO(test): remove before release — auto-completes after first answer.
const bool _kTestAutoComplete = false;

const String _kBlank = '_____';

/// Minimum touch target size (accessibility).
const double kMinTouchTarget = 48;

enum _Phase { loading, playing, end, gameOver }

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
  bool _conversationUnlocked = false;

  static String _levelKey(SubLevel sub) =>
      imageQuizLevelKey(sub.iconImageName);

  bool get _isReminder => widget.reminderMode;
  String? get _currentQuestionId =>
      _currentQuestionIds.isEmpty ? null : _currentQuestionIds[_currentIndex];

  bool get _isConvoMode =>
      _convoQuestions.isNotEmpty || _convoByQuestionId.isNotEmpty;

  LevelQuestion? get _currentConvoLevelQuestion {
    if (!_isConvoMode) return null;
    if (_isReminder) return _convoByQuestionId[_currentQuestionId ?? ''];
    return _currentIndex < _convoQuestions.length
        ? _convoQuestions[_currentIndex]
        : null;
  }

  bool get _hasConvoTemplate1InCurrentRun {
    if (_isReminder) {
      for (final id in _currentQuestionIds) {
        final q = _convoByQuestionId[id];
        if (q != null && q.template == 'ConvoTemplate-1') return true;
      }
      return false;
    }
    return _convoQuestions.any((q) => q.template == 'ConvoTemplate-1');
  }

  String? _convoAnswer(LevelQuestion? q) {
    if (q == null) return null;
    if (q.template == 'ConvoTemplate-1') return q.convoData?.answer;
    if (q.template == 'ConvoTemplate-2') return q.convo2Data?.answer;
    return null;
  }

  int get _questionCount => _isConvoMode
      ? (_isReminder ? _currentQuestionIds.length : _convoQuestions.length)
      : _questionAssetPaths.length;

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

  @override
  void dispose() {
    _timerController.dispose();
    _windController.dispose();
    _monsterIdleController.dispose();
    audio.stopQuizMusic();
    super.dispose();
  }

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

      final imageRows = levelCfg.questions
          .where(
            (q) =>
                q.type == LevelQuestionType.image &&
                q.template == 'imageQuizTemplate-1',
          )
          .toList();
      if (imageRows.length == levelCfg.questions.length &&
          imageRows.isNotEmpty) {
        final paths = <String>[];
        final wrongLists = <List<String>>[];
        for (final row in imageRows) {
          final d = row.imageData;
          if (d == null) continue;
          final path = await resolveQuizImageAsset(key, d.imageName);
          if (path == null) {
            throw Exception('Missing image asset for: ${d.imageName}');
          }
          paths.add(path);
          wrongLists.add(d.wrongAnswers);
        }
        if (paths.length < kMinImagesPerLevel) {
          throw Exception(
            'This level needs at least $kMinImagesPerLevel images (found ${paths.length}).',
          );
        }
        final questionIds = List.generate(
          paths.length,
          (i) => buildReminderQuestionId(widget.progressKey, i),
        );
        final totalQuestions = paths.length;
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
          for (final path in paths) {
            if (!mounted) break;
            await precacheImage(AssetImage(path), context);
          }
        }

        if (mounted) {
          setState(() {
            _config = config;
            _conversations = conversations;
            _questionAssetPaths = paths;
            _currentQuestionIds = questionIds;
            _configWrongAnswers = wrongLists;
            _vocabulary = paths.map(assetPathToBasename).toList();
            _initialQuestionCount = paths.length;
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

      // Convo-only level
      final convoRows = levelCfg.questions
          .where((q) => q.type != LevelQuestionType.image)
          .toList();
      if (convoRows.isNotEmpty) {
        final convoList = <LevelQuestion>[];
        for (final q in convoRows) {
          if (q.template == 'ConvoTemplate-1' && q.convoData != null) {
            convoList.add(q);
          } else if (q.template == 'ConvoTemplate-2' && q.convo2Data != null) {
            convoList.add(q);
          } else {
            throw Exception(
              'Missing convo data for question (template ${q.template})',
            );
          }
        }
        final heroPaths = <String?>[];
        for (final q in convoList) {
          if (q.template == 'ConvoTemplate-2') {
            final d = q.convo2Data!;
            final path = await resolveQuizImageAsset(key, d.imageName);
            if (path == null) {
              throw Exception('Missing image asset for: ${d.imageName}');
            }
            heroPaths.add(path);
          } else {
            heroPaths.add(null);
          }
        }
        if (mounted) {
          for (final path in heroPaths) {
            if (path != null && mounted) {
              await precacheImage(AssetImage(path), context);
            }
          }
        }
        final questionIds = List.generate(
          convoList.length,
          (i) => buildReminderQuestionId(widget.progressKey, i),
        );
        if (mounted) {
          setState(() {
            _config = config;
            _convoQuestions = convoList;
            _convo2HeroPaths = heroPaths;
            _currentQuestionIds = questionIds;
            _initialQuestionCount = convoList.length;
            _shortQuizDebug = shortQuizDebug;
            _endedEarlyShortQuiz = false;
            _phase = _Phase.playing;
            _quizStartTime = DateTime.now();
            _currentOptions = _buildOptions();
          });
          final musicOn =
              ref.read(settingsProvider).valueOrNull?.musicOn ?? true;
          audio.startQuizMusic(musicOn: musicOn);
        }
        return;
      }
      throw Exception(
        'Unified level "${widget.subLevel.iconImageName}" has no recognized question types',
      );
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
          if (q.type == LevelQuestionType.image && q.imageData != null) {
            final path = await resolveQuizImageAsset(
              levelKey,
              q.imageData!.imageName,
            );
            if (path != null) {
              assetPathByQuestionId[questionId] = path;
              final manifestPaths = loadedPaths[progressKey] ??=
                  await loadImageQuizLevelAssetPaths(levelKey);
              final vocabulary = loadedVocabulary[progressKey] ??=
                  manifestPaths.map(assetPathToBasename).toList(growable: false);
              vocabularyByQuestionId[questionId] = vocabulary;
              wrongThreeByQuestionId[questionId] = q.imageData!.wrongAnswers;
              validQuestionIds.add(questionId);
              continue;
            }
          } else if (q.type != LevelQuestionType.image &&
              (q.convoData != null || q.convo2Data != null)) {
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

  void _startTimer() {
    _timerController
      ..reset()
      ..forward();
    if (!_monsterIdleController.isAnimating) {
      _monsterIdleController.repeat(reverse: true);
    }
  }

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

  // step 0=laughing(-1) … step 4=crying(-5)
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

  String _correctAnswer() {
    if (_isConvoMode) {
      return _convoAnswer(_currentConvoLevelQuestion) ?? '';
    }
    return assetPathToBasename(_questionAssetPaths[_currentIndex]);
  }

  List<String> _buildOptions() {
    if (_isConvoMode) {
      final q = _currentConvoLevelQuestion;
      if (q == null) return [];
      final ans = _convoAnswer(q);
      final dist = q.template == 'ConvoTemplate-1'
          ? q.convoData!.distractors
          : q.convo2Data!.distractors;
      if (ans == null) return [];
      return ([ans, ...dist]..shuffle(Random()));
    }
    final correct = _correctAnswer();
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
            milliseconds: (_config.autoAdvanceDelaySeconds * 1000).round(),
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
        if (_isConvoMode && !_isReminder) _conversationUnlocked = true;
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
        if (_isConvoMode && !_isReminder) _conversationUnlocked = true;
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
    if (!_isConvoMode) _startTimer();
  }

  int _stars() {
    if (_endedEarlyShortQuiz) return 2;
    if (_questionCount == 0) return 0;
    final rate = (_correctCount / _questionCount) * 100;
    if (rate >= 85) return 3;
    if (rate >= 70) return 2;
    if (rate >= 60) return 1;
    return 0;
  }

  int _diamondsEarned() => _correctCount;

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

  Widget _buildImagePlaying(bool soundFxOn, Map<String, String> strings) {
    final path = _questionAssetPaths[_currentIndex];
    final isLast = _currentIndex + 1 >= _questionAssetPaths.length;

    return Column(
      children: [
        // Reminder question counter (reminder mode only)
        if (_isReminder)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              _reviewingMistakes
                  ? (strings['reviewing_mistakes'] ?? 'Reviewing Mistakes')
                  : '${_currentIndex + 1} / $_initialQuestionCount',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        // Question image (smaller to give room for monster row)
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
        // Answer buttons
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
            if (_isConvoMode && _hasConvoTemplate1InCurrentRun) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  audio.playClick(soundFxOn: soundFxOn);
                  _showFullConversation(strings);
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(
                  strings['view_full_conversation'] ?? 'View Full Conversation',
                ),
              ),
            ],
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

  void _showFullConversation(Map<String, String> strings) {
    final title = strings['full_conversation'] ?? 'Full Conversation';
    final questions = _isReminder
        ? _currentQuestionIds
            .map((id) => _convoByQuestionId[id])
            .whereType<LevelQuestion>()
            .where((q) => q.template == 'ConvoTemplate-1')
            .toList()
        : _convoQuestions
            .where((q) => q.template == 'ConvoTemplate-1')
            .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  child: Text(
                    title,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final q = questions[i];
                      final conv = q.convoData!;
                      final c1 = _capitalize(conv.character1);
                      final c2 = _capitalize(conv.character2);
                      final ans = conv.answer;
                      final line1 = (conv.line1['en'] ?? '')
                          .replaceAll(_kBlank, ans);
                      final line2 = (conv.line2['en'] ?? '')
                          .replaceAll(_kBlank, ans);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$c1: $line1',
                            style: Theme.of(ctx)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$c2: $line2',
                            style: Theme.of(ctx).textTheme.bodyMedium,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConvoPlaying(
      bool soundFxOn, Map<String, String> strings, String userLanguage) {
    final q = _currentConvoLevelQuestion;
    if (q == null) return const Center(child: CircularProgressIndicator());
    final total = _isReminder ? _initialQuestionCount : _questionCount;
    final isLast = _currentIndex + 1 >= _questionCount;
    final reminderProgress = _reviewingMistakes
        ? 1.0
        : (total <= 0 ? 0.0 : (_currentIndex + 1) / total);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              Text(
                _isReminder && _reviewingMistakes
                    ? (strings['reviewing_mistakes'] ?? 'Reviewing Mistakes')
                    : _questionLabel(strings, _currentIndex + 1, total),
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
            child: q.template == 'ConvoTemplate-2'
                ? _buildConvoTemplate2Content(q, userLanguage)
                : _buildCharactersRow(q.convoData!, userLanguage),
          ),
        ),
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
        if (!_isReminder)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                if (userLanguage != 'en') ...[
                  Expanded(
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
                  if (_hasConvoTemplate1InCurrentRun) const SizedBox(width: 8),
                ],
                if (_hasConvoTemplate1InCurrentRun)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _conversationUnlocked
                          ? () {
                              audio.playClick(soundFxOn: soundFxOn);
                              _showFullConversation(strings);
                            }
                          : null,
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(
                          strings['full_conversation'] ?? 'Full Conversation'),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildConvoTemplate2Content(LevelQuestion q, String userLanguage) {
    final d = q.convo2Data!;
    final path = _isReminder
        ? _convo2ImagePathByQuestionId[_currentQuestionId ?? '']
        : (_currentIndex < _convo2HeroPaths.length
            ? _convo2HeroPaths[_currentIndex]
            : null);
    // Always show locale-aware sentence: English for 'en', English + (answer
    // translation) for other locales — no toggle needed.
    final line = d.sentence[userLanguage] ?? d.sentence['en'] ?? '';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (path != null)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(path, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
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
              ),
              if (path != null) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    path,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _questionLabel(Map<String, String> strings, int current, int total) {
    final template = strings['question_x_of_y'] ?? 'Question %s / %s';
    return template
        .replaceFirst('%s', '$current')
        .replaceFirst('%s', '$total');
  }

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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

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

class _PieTimerPainter extends CustomPainter {
  const _PieTimerPainter({required this.progress, required this.color});

  /// 1.0 = full circle (time just started), 0.0 = empty (time up).
  final double progress;
  final Color color;

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

  @override
  bool shouldRepaint(covariant _PieTimerPainter old) =>
      old.progress != progress || old.color != color;
}

class _WindPainter extends CustomPainter {
  _WindPainter(this.value);

  final double value;

  // Horizontal wind lines trailing to the RIGHT of the monster (behind it as it moves left).
  // Lines start just outside the right edge and extend further right.
  // Fade in fast, fade out slowly over the animation duration.
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

  @override
  bool shouldRepaint(covariant _WindPainter oldDelegate) =>
      oldDelegate.value != value;
}
