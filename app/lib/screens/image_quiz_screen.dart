import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/quiz_flow.dart';
import '../../services/game_config_loader.dart';
import '../../services/image_quiz_level_loader.dart';
import '../../services/quiz_progress_service.dart';

/// Minimum images per level (spec).
const int kMinImagesPerLevel = 4;

/// Minimum touch target size (accessibility).
const double kMinTouchTarget = 48;

enum _Phase { loading, playing, end }

class ImageQuizScreen extends StatefulWidget {
  const ImageQuizScreen({
    super.key,
    required this.subLevel,
    required this.quizType,
  });

  final SubLevel subLevel;
  final String quizType;

  @override
  State<ImageQuizScreen> createState() => _ImageQuizScreenState();
}

class _ImageQuizScreenState extends State<ImageQuizScreen> {
  _Phase _phase = _Phase.loading;
  String? _loadError;
  List<String> _questionAssetPaths = [];
  List<String> _vocabulary = [];
  GameConfig _config = const GameConfig();
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _answerLocked = false;
  bool _showNext = false;
  int? _selectedIndex; // 0..3 index into current options
  List<String> _currentOptions = [];

  static String _levelKey(SubLevel sub) =>
      imageQuizLevelKey(sub.iconImageName, sub.levelNumber);

  @override
  void initState() {
    super.initState();
    _loadLevel();
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
      // Precache images
      for (final path in shuffled) {
        await precacheImage(AssetImage(path), context);
      }

      if (mounted) {
        setState(() {
          _config = config;
          _questionAssetPaths = shuffled;
          _vocabulary = vocabulary;
          _phase = _Phase.playing;
          _currentOptions = _buildOptions();
        });
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

  String _correctAnswer() =>
      assetPathToBasename(_questionAssetPaths[_currentIndex]);

  List<String> _buildOptions() {
    final correct = _correctAnswer();
    final wrongPool =
        _vocabulary.where((s) => s != correct).toList()..shuffle(Random());
    final wrong = wrongPool.take(3).toList();
    final options = [correct, ...wrong]..shuffle(Random());
    return options;
  }

  void _onAnswerTap(int optionIndex) {
    if (_answerLocked) return;
    final option = _currentOptions[optionIndex];
    final correct = _correctAnswer();
    setState(() {
      _answerLocked = true;
      _selectedIndex = optionIndex;
      if (option == correct) {
        _correctCount++;
        _showNext = false;
        // Auto-advance after delay
        Future.delayed(
          Duration(
            milliseconds:
                (_config.autoAdvanceDelaySeconds * 1000).round(),
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
    final rate =
        (_correctCount / _questionAssetPaths.length) * 100;
    if (rate >= 85) return 3;
    if (rate >= 70) return 2;
    if (rate >= 60) return 1;
    return 0;
  }

  int _diamondsEarned() => _correctCount;

  Future<void> _onEndOk() async {
    final stars = _stars();
    if (stars >= 1) {
      await QuizProgressService.instance.recordLevelCompletion(
        quizType: widget.quizType,
        levelNumber: widget.subLevel.levelNumber,
        stars: stars,
        diamondsEarned: _diamondsEarned(),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subLevel.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.loading:
        return _buildLoading();
      case _Phase.playing:
        return _buildPlaying();
      case _Phase.end:
        return _buildEnd();
    }
  }

  Widget _buildLoading() {
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Levels'),
            ),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildPlaying() {
    final path = _questionAssetPaths[_currentIndex];
    final isLast = _currentIndex + 1 >= _questionAssetPaths.length;

    return Column(
      children: [
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
              if (_answerLocked) {
                if (isCorrect) {
                  bgColor = Colors.green.shade300;
                } else if (isSelected && !isCorrect) {
                  bgColor = Colors.red.shade300;
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: kMinTouchTarget + 8,
                  child: ElevatedButton(
                    onPressed: _answerLocked ? null : () => _onAnswerTap(i),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bgColor,
                      minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
                    ),
                    child: Text(
                      _capitalize(option),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Next / Finish
        if (_showNext)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: kMinTouchTarget + 8,
              child: FilledButton(
                onPressed: _goNext,
                child: Text(isLast ? 'Finish' : 'Next'),
              ),
            ),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEnd() {
    final stars = _stars();
    final diamonds = _diamondsEarned();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Level complete!',
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
                onPressed: _onEndOk,
                child: const Text('OK'),
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
