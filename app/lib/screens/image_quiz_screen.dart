import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/level_completion_result.dart';
import '../../models/quiz_flow.dart';
import '../../models/reminder_progress.dart';
import '../../providers/localization_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/achievement_service.dart';
import '../../services/audio_service.dart' as audio;
import '../../services/game_config_loader.dart';
import '../../services/image_quiz_level_loader.dart';
import '../../services/profile_service.dart';
import '../../services/quiz_progress_service.dart';
import '../../services/reminder_progress_service.dart';

/// Minimum images per level (spec).
const int kMinImagesPerLevel = 4;

// TODO(test): remove before release — auto-completes after first answer.
const bool _kTestAutoComplete = false;

/// Minimum touch target size (accessibility).
const double kMinTouchTarget = 48;

enum _Phase { loading, playing, end, gameOver }

class ImageQuizScreen extends ConsumerStatefulWidget {
  const ImageQuizScreen({
    super.key,
    required this.subLevel,
    required this.quizType,
    required this.ordinalLevelIndex,
    this.reminderMode = false,
    this.reminderQuestionIds,
    this.reminderSourceLevelsByLevelNumber,
  });

  final SubLevel subLevel;
  final String quizType;

  /// 1-based position in subLevels list (progression key).
  final int ordinalLevelIndex;
  final bool reminderMode;
  final List<String>? reminderQuestionIds;
  final Map<int, SubLevel>? reminderSourceLevelsByLevelNumber;

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
  GameConfig _config = const GameConfig();
  int _currentIndex = 0;
  int _correctCount = 0;
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

  static String _levelKey(SubLevel sub) =>
      imageQuizLevelKey(sub.iconImageName, sub.levelNumber);

  bool get _isReminder => widget.reminderMode;
  String? get _currentQuestionId =>
      _currentQuestionIds.isEmpty ? null : _currentQuestionIds[_currentIndex];

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
      final config = await GameConfig.load();
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

      // Shuffle question order
      final shuffled = List<String>.from(paths)..shuffle(Random());
      final questionIds = shuffled
          .map((path) => buildReminderQuestionId(
                widget.subLevel.levelNumber,
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

      // Precache images (only use context when mounted)
      if (mounted) {
        for (final path in shuffled) {
          if (!mounted) break;
          await precacheImage(AssetImage(path), context);
        }
      }

      if (mounted) {
        setState(() {
          _config = config;
          _questionAssetPaths = shuffled;
          _currentQuestionIds = questionIds;
          _vocabulary = vocabulary;
          _initialQuestionCount = shuffled.length;
          _monsterStepThreshold = threshold;
          _guestAnimal = guestAnimal;
          _selectedMonster = selectedMonster;
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
      final config = await GameConfig.load();
      final reminderQuestionIds = widget.reminderQuestionIds ?? const [];
      final sourceLevels = widget.reminderSourceLevelsByLevelNumber ?? const {};
      final loadedPaths = <int, List<String>>{};
      final loadedVocabulary = <int, List<String>>{};
      final assetPathByQuestionId = <String, String>{};
      final vocabularyByQuestionId = <String, List<String>>{};
      final validQuestionIds = <String>[];

      for (final questionId in reminderQuestionIds) {
        final (levelNumber, questionIndex) =
            parseReminderQuestionId(questionId);
        final sourceLevel = sourceLevels[levelNumber];
        if (sourceLevel == null) continue;
        final levelKey = imageQuizLevelKey(
          sourceLevel.iconImageName,
          sourceLevel.levelNumber,
        );
        final paths = loadedPaths[levelNumber] ??=
            await loadImageQuizLevelAssetPaths(levelKey);
        if (questionIndex < 0 || questionIndex >= paths.length) continue;
        final vocabulary = loadedVocabulary[levelNumber] ??=
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
          if (path == null || !mounted) continue;
          await precacheImage(AssetImage(path), context);
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

      if (!mounted) return;
      setState(() {
        _config = config;
        _assetPathByQuestionId
          ..clear()
          ..addAll(assetPathByQuestionId);
        _vocabularyByQuestionId
          ..clear()
          ..addAll(vocabularyByQuestionId);
        _currentQuestionIds = List<String>.from(validQuestionIds);
        _initialReminderQuestionIds = List<String>.from(validQuestionIds);
        _questionAssetPaths = validQuestionIds
            .map((questionId) => assetPathByQuestionId[questionId]!)
            .toList(growable: false);
        _initialQuestionCount = validQuestionIds.length;
        _monsterStepThreshold = threshold;
        _guestAnimal = guestAnimal;
        _selectedMonster = selectedMonster;
        _reviewingMistakes = false;
        _phase = _Phase.playing;
        _quizStartTime = DateTime.now();
        _currentOptions = _buildOptions();
      });
      _timerController.duration =
          Duration(seconds: _config.imageQuizTimerSeconds);
      _startTimer();
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
      ReminderProgressService.instance.recordWrongAnswer(
        widget.quizType,
        questionId,
      );
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
        }
      });
      if (_monsterStep >= 4) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _monsterIdleController
              ..stop()
              ..reset();
            setState(() => _phase = _Phase.gameOver);
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

  String _correctAnswer() =>
      assetPathToBasename(_questionAssetPaths[_currentIndex]);

  List<String> _buildOptions() {
    final correct = _correctAnswer();
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
    _timerController.stop();
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
        ReminderProgressService.instance.recordWrongAnswer(
          widget.quizType,
          questionId,
        );
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
    if (_currentIndex + 1 >= _questionAssetPaths.length) {
      if (_isReminder && _nextReviewQuestionIds.isNotEmpty) {
        final nextQuestionIds = List<String>.from(_nextReviewQuestionIds)
          ..shuffle(Random());
        _nextReviewQuestionIds.clear();
        setState(() {
          _currentQuestionIds = nextQuestionIds;
          _questionAssetPaths = nextQuestionIds
              .map((questionId) => _assetPathByQuestionId[questionId]!)
              .toList(growable: false);
          _currentIndex = 0;
          _answerLocked = false;
          _showNext = false;
          _selectedIndex = null;
          _currentOptions = _buildOptions();
          _reviewingMistakes = true;
        });
        _startTimer();
        return;
      }
      _monsterIdleController
        ..stop()
        ..reset();
      setState(() {
        _phase = _Phase.end;
      });
      return;
    }
    setState(() {
      _currentIndex++;
      _answerLocked = false;
      _showNext = false;
      _selectedIndex = null;
      _currentOptions = _buildOptions();
    });
    _startTimer();
  }

  int _stars() {
    if (_questionAssetPaths.isEmpty) return 0;
    final rate = (_correctCount / _questionAssetPaths.length) * 100;
    if (rate >= 85) return 3;
    if (rate >= 70) return 2;
    if (rate >= 60) return 1;
    return 0;
  }

  int _diamondsEarned() => _correctCount;

  Future<void> _onEndOk() async {
    if (_isReminder) {
      await ReminderProgressService.instance.markReminderCompleted(
        quizType: widget.quizType,
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
        quizType: widget.quizType,
        levelNumber: widget.ordinalLevelIndex,
        stars: stars,
        diamondsEarned: _diamondsEarned(),
      );
    }
    if (stars >= 1) {
      await ProfileService.instance.registerQuizCompletion(
        quizType: widget.quizType,
        questionCount: _questionAssetPaths.length,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subLevel.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
        child: _buildBody(soundFxOn, strings),
      ),
    );
  }

  Widget _buildBody(bool soundFxOn, Map<String, String> strings) {
    switch (_phase) {
      case _Phase.loading:
        return _buildLoading(soundFxOn, strings);
      case _Phase.playing:
        return _buildPlaying(soundFxOn, strings);
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

  Widget _buildPlaying(bool soundFxOn, Map<String, String> strings) {
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animal and monster face to face
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _animalImage(step: 4),
                const SizedBox(width: 8),
                // Flip monster horizontally so it faces the animal
                Transform.scale(
                  scaleX: -1,
                  child: _monsterImage(),
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
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
