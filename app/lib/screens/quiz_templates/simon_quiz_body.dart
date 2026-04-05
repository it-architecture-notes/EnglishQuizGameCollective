import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../services/audio_service.dart' as audio;

/// Simon-style: demo highlights tiles in sentence order; player repeats.
class SimonQuizBody extends StatefulWidget {
  const SimonQuizBody({
    super.key,
    required this.data,
    required this.soundFxOn,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final SimonQuestionData data;
  final bool soundFxOn;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<SimonQuizBody> createState() => _SimonQuizBodyState();
}

class _SimonQuizBodyState extends State<SimonQuizBody> {
  late List<String> _grid;
  late List<int> _demoOrder;

  bool _demoPhase = true;
  int? _highlightIndex;
  int _playerStep = 0;
  bool _failed = false;
  bool _completed = false;
  int? _wrongTapIndex;
  int? _expectedIndex;
  final Map<int, int> _gridToStep = {};

  List<String> get _words => widget.data.words;

  @override
  void initState() {
    super.initState();
    _grid = [...widget.data.words, ...widget.data.distractors]..shuffle(Random());
    final byWord = <String, Queue<int>>{};
    for (var i = 0; i < 9; i++) {
      final w = _grid[i];
      byWord.putIfAbsent(w, () => Queue<int>()).add(i);
    }
    _demoOrder = [];
    for (final w in _words) {
      final qi = byWord[w];
      if (qi == null || qi.isEmpty) {
        throw StateError('Simon: word "$w" missing from grid');
      }
      _demoOrder.add(qi.removeFirst());
    }
    _runDemo();
  }

  Future<void> _runDemo() async {
    final ms = (widget.data.tileHighlightDuration * 1000).round();
    for (final idx in _demoOrder) {
      if (!mounted || _failed) return;
      setState(() => _highlightIndex = idx);
      audio.playClick(soundFxOn: widget.soundFxOn);
      await Future<void>.delayed(Duration(milliseconds: ms));
      if (!mounted) return;
      setState(() => _highlightIndex = null);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    if (mounted) setState(() => _demoPhase = false);
  }

  void _onTap(int i) {
    if (_demoPhase || _failed || _completed) return;
    final expectedIdx = _demoOrder[_playerStep];
    if (i != expectedIdx) {
      setState(() {
        _failed = true;
        _wrongTapIndex = i;
        _expectedIndex = expectedIdx;
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
      return;
    }

    setState(() {
      _gridToStep[i] = _playerStep + 1;
      _playerStep++;
    });
    if (_playerStep >= _words.length) {
      _completed = true;
      widget.onPlayCorrect();
      widget.onOutcome(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sentence = _words.join(' ');
    final dimGrid = _failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_failed) ...[
          Text(
            sentence,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ] else if (_demoPhase)
          Text(
            '…',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        Expanded(
          child: Opacity(
            opacity: dimGrid ? 0.45 : 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: 9,
              itemBuilder: (context, i) {
                final word = _grid[i];
                final highlight = _highlightIndex == i;
                final isWrong = _failed && _wrongTapIndex == i;
                final isExpected =
                    _failed && _expectedIndex != null && _expectedIndex == i;
                final doneStep = _gridToStep[i];
                final disabled = _demoPhase || _failed || _completed;

                Color bg = cs.surfaceContainerHighest;
                if (highlight) bg = Colors.amber.shade200;
                if (isWrong) bg = Colors.red.shade200;
                if (isExpected) bg = Colors.green.shade200;
                if (doneStep != null && !_failed) bg = Colors.green.shade100;

                return Material(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: disabled ? null : () => _onTap(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            word,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (doneStep != null)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.green.shade700,
                              child: Text(
                                '$doneStep',
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
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
