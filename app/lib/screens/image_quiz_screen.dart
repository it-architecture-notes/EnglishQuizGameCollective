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
const bool _kTestAutoComplete = true;

/// Minimum touch target size (accessibility).
const double kMinTouchTarget = 48;

enum _Phase { loading, playing, end }

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

class _ImageQuizScreenState extends ConsumerState<ImageQuizScreen> {
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

  static String _levelKey(SubLevel sub) =>
      imageQuizLevelKey(sub.iconImageName, sub.levelNumber);

  bool get _isReminder => widget.reminderMode;
  String? get _currentQuestionId =>
      _currentQuestionIds.isEmpty ? null : _currentQuestionIds[_currentIndex];

  @override
  void initState() {
    super.initState();
    if (_isReminder) {
      _loadReminderLevel();
    } else {
      _loadLevel();
    }
  }

  @override
  void dispose() {
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
          _phase = _Phase.playing;
          _quizStartTime = DateTime.now();
          _currentOptions = _buildOptions();
        });
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
        final (levelNumber, questionIndex) = parseReminderQuestionId(questionId);
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
        _reviewingMistakes = false;
        _phase = _Phase.playing;
        _quizStartTime = DateTime.now();
        _currentOptions = _buildOptions();
      });
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
        return;
      }
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

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (prev, next) {
      if (next.valueOrNull?.musicOn == true && _phase == _Phase.playing) {
        audio.startQuizMusic(musicOn: true);
      }
    });
    final soundFxOn = ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
    final strings = ref.watch(currentLocalizedStringsProvider).valueOrNull ?? {};
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
    final reminderProgress = _reviewingMistakes
        ? 1.0
        : (_initialQuestionCount <= 0 ? 0.0 : (_currentIndex + 1) / _initialQuestionCount);

    return Column(
      children: [
        if (_isReminder)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Text(
                  _reviewingMistakes
                      ? (strings['reviewing_mistakes'] ?? 'Reviewing Mistakes')
                      : '${_currentIndex + 1} / $_initialQuestionCount',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: reminderProgress),
              ],
            ),
          ),
        // Question image
        Expanded(
          flex: 2,
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
                      // Keep original grey look when disabled (avoid blue flicker)
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
