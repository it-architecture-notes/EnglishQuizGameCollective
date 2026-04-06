import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';

/// Immediate 3×3 grid: tap tokens in [SentenceBuilderQuestionData.correctOrder].
class SentenceBuilderQuizBody extends StatefulWidget {
  const SentenceBuilderQuizBody({
    super.key,
    required this.data,
    required this.strings,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final SentenceBuilderQuestionData data;
  final Map<String, String> strings;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<SentenceBuilderQuizBody> createState() =>
      _SentenceBuilderQuizBodyState();
}

class _SentenceBuilderQuizBodyState extends State<SentenceBuilderQuizBody> {
  late List<String> _shuffledGrid;
  late List<String> _sentence;

  int _tapProgress = 0;
  final List<String?> _slots = [];
  final List<bool> _slotFromPlayer = [];
  bool _failed = false;
  int? _wrongGridIndex;
  final Set<int> _correctGridIndices = {};
  final Map<int, int> _gridIndexToStep = {};
  bool _completed = false;

  List<String> get _target => widget.data.correctOrder;

  @override
  void initState() {
    super.initState();
    _sentence = List<String>.from(_target);
    final pool = [...widget.data.words, ...widget.data.distractors]..shuffle(Random());
    _shuffledGrid = pool;
    for (var i = 0; i < _sentence.length; i++) {
      _slots.add(null);
      _slotFromPlayer.add(false);
    }
  }

  void _onGridTap(int gridIndex) {
    if (_completed || _failed) return;
    final word = _shuffledGrid[gridIndex];
    final expected = _sentence[_tapProgress];
    if (word == expected) {
      setState(() {
        _slots[_tapProgress] = word;
        _slotFromPlayer[_tapProgress] = true;
        _correctGridIndices.add(gridIndex);
        _gridIndexToStep[gridIndex] = _tapProgress + 1;
        _tapProgress++;
      });
      if (_tapProgress >= _sentence.length) {
        _completed = true;
        widget.onPlayCorrect();
        widget.onOutcome(true);
      }
    } else {
      setState(() {
        _failed = true;
        _wrongGridIndex = gridIndex;
        for (var i = _tapProgress; i < _sentence.length; i++) {
          _slots[i] = _sentence[i];
          _slotFromPlayer[i] = false;
        }
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.strings['click_in_order'] ?? 'Click in order',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: List.generate(_sentence.length, (i) {
            final word = _slots[i];
            final fromPlayer = i < _slotFromPlayer.length && _slotFromPlayer[i];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minWidth: 56, minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: word != null
                    ? (fromPlayer
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest.withValues(alpha: 0.45))
                    : cs.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: fromPlayer ? cs.primary : cs.outline.withValues(alpha: 0.7),
                  width: fromPlayer ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  word ?? '___',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontStyle: word == null ? FontStyle.italic : null,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemCount: _shuffledGrid.length,
            itemBuilder: (context, i) {
              final word = _shuffledGrid[i];
              final disabled = _failed || _completed;
              final isWrong = _failed && _wrongGridIndex == i;
              final isCorrectTile = _correctGridIndices.contains(i);
              final orderLabel = _gridIndexToStep[i];

              return Material(
                color: isWrong
                    ? Colors.red.shade100
                    : isCorrectTile
                        ? Colors.green.shade100
                        : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: disabled ? null : () => _onGridTap(i),
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
                            color: isWrong
                                ? Colors.red.shade900
                                : isCorrectTile
                                    ? Colors.green.shade900
                                    : null,
                          ),
                        ),
                      ),
                      if (isCorrectTile && orderLabel != null)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.green.shade700,
                            child: Text(
                              '$orderLabel',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
      ],
    );
  }
}
