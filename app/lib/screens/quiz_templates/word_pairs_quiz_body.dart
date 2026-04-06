import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';

/// Tap left column then matching right column (translations scrambled).
class WordPairsQuizBody extends StatefulWidget {
  const WordPairsQuizBody({
    super.key,
    required this.data,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final WordPairsQuestionData data;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<WordPairsQuizBody> createState() => _WordPairsQuizBodyState();
}

class _WordPairsQuizBodyState extends State<WordPairsQuizBody> {
  late List<String> _left;
  late List<String> _right;
  late Map<String, String> _match;

  int? _selectedLeftIndex;
  final Set<int> _matchedLeftIndices = {};
  bool _failed = false;
  int? _wrongRightIndex;
  int? _highlightCorrectRightIndex;

  @override
  void initState() {
    super.initState();
    _left = widget.data.pairs.map((p) => p.left).toList();
    _match = {for (final p in widget.data.pairs) p.left: p.right};
    _right = widget.data.pairs.map((p) => p.right).toList()..shuffle(Random());
  }

  void _onLeftTap(int i) {
    if (_failed || _matchedLeftIndices.contains(i)) return;
    setState(() => _selectedLeftIndex = i);
  }

  void _onRightTap(int rightIndex) {
    if (_failed || _selectedLeftIndex == null) return;
    final leftIndex = _selectedLeftIndex!;
    final expected = _match[_left[leftIndex]]!;
    final tapped = _right[rightIndex];
    if (tapped == expected) {
      setState(() {
        _matchedLeftIndices.add(leftIndex);
        _selectedLeftIndex = null;
      });
      if (_matchedLeftIndices.length >= _left.length) {
        widget.onPlayCorrect();
        widget.onOutcome(true);
      }
    } else {
      final correctIdx =
          _right.indexWhere((r) => r == expected);
      setState(() {
        _failed = true;
        _wrongRightIndex = rightIndex;
        _highlightCorrectRightIndex = correctIdx >= 0 ? correctIdx : null;
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_left.length, (i) {
              final matched = _matchedLeftIndices.contains(i);
              final sel = _selectedLeftIndex == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: matched
                      ? Colors.green.shade100
                      : sel
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: !_failed && !matched ? () => _onLeftTap(i) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _left[i],
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_right.length, (i) {
              final isWrong = _failed && _wrongRightIndex == i;
              final isCorrectHighlight =
                  _failed && _highlightCorrectRightIndex == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isWrong
                      ? Colors.red.shade100
                      : isCorrectHighlight
                          ? Colors.green.shade100
                          : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _failed ? null : () => _onRightTap(i),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _right[i],
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isWrong
                              ? Colors.red.shade900
                              : isCorrectHighlight
                                  ? Colors.green.shade900
                                  : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
