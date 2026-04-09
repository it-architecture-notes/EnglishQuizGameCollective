import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';

/// Tap right column to select (blue), then tap left column to pair.
/// Correct match → both tiles slide to the matched section at the bottom.
/// Wrong match → wrong left turns red, selected right turns red, correct right
/// turns green; nothing moves to the bottom section.
class WordPairsQuizBody extends StatefulWidget {
  const WordPairsQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final WordPairsQuestionData data;
  final String userLanguage;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<WordPairsQuizBody> createState() => _WordPairsQuizBodyState();
}

class _WordPairsQuizBodyState extends State<WordPairsQuizBody> {
  late Map<String, String> _match;        // leftWord → rightWord
  late Map<String, String> _reverseMatch; // rightWord → leftWord

  late List<String> _activeLeft;
  late List<String> _activeRight;
  final List<(String, String)> _matchedPairs = []; // (leftWord, rightWord)

  String? _selectedRightWord;

  bool _failed = false;
  String? _failedLeftWord;
  String? _failedRightWord;
  String? _correctLeftWord; // correct left for the selected right word → shown green

  @override
  void initState() {
    super.initState();
    _match = {
      for (final p in widget.data.pairs)
        p.left: p.rightForLanguage(widget.userLanguage),
    };
    _reverseMatch = {for (final e in _match.entries) e.value: e.key};
    _activeLeft = widget.data.pairs.map((p) => p.left).toList();
    _activeRight = _match.values.toList()
      ..shuffle(Random());
  }

  void _onRightTap(String word) {
    if (_failed) return;
    setState(() {
      _selectedRightWord = (_selectedRightWord == word) ? null : word;
    });
  }

  void _onLeftTap(String leftWord) {
    if (_failed) return;
    final selected = _selectedRightWord;
    if (selected == null) return;

    final expectedRight = _match[leftWord]!;
    if (selected == expectedRight) {
      setState(() {
        _activeLeft.remove(leftWord);
        _activeRight.remove(selected);
        _matchedPairs.add((leftWord, selected));
        _selectedRightWord = null;
      });
      widget.onPlayCorrect();
      if (_activeLeft.isEmpty) {
        widget.onOutcome(true);
      }
    } else {
      setState(() {
        _failed = true;
        _failedLeftWord = leftWord;
        _failedRightWord = selected;
        _correctLeftWord = _reverseMatch[selected];
        _selectedRightWord = null;
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  Widget _activeTile({
    required String text,
    Color? bgColor,
    Color? textColor,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bgColor ??
            (selected ? Colors.blue.shade100 : cs.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor ??
                    (selected ? Colors.blue.shade900 : null),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Active (unmatched) area ──────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _activeLeft.map((word) {
                  final isWrong = _failed && word == _failedLeftWord;
                  final isCorrect = _failed && word == _correctLeftWord;
                  return _activeTile(
                    text: word,
                    bgColor: isCorrect
                        ? Colors.green.shade100
                        : isWrong
                            ? Colors.red.shade100
                            : null,
                    textColor: isCorrect
                        ? Colors.green.shade900
                        : isWrong
                            ? Colors.red.shade900
                            : null,
                    onTap: !_failed ? () => _onLeftTap(word) : null,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 12),
            // Right column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _activeRight.map((word) {
                  final isSelected = !_failed && _selectedRightWord == word;
                  final isWrong = _failed && word == _failedRightWord;
                  return _activeTile(
                    text: word,
                    bgColor: isWrong ? Colors.red.shade100 : null,
                    textColor: isWrong ? Colors.red.shade900 : null,
                    selected: isSelected,
                    onTap: !_failed ? () => _onRightTap(word) : null,
                  );
                }).toList(),
              ),
            ),
          ],
        ),

        // ── Matched pairs section ────────────────────────────────────────────
        if (_matchedPairs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: cs.outlineVariant),
          ),
          ..._matchedPairs.map(
            (pair) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pair.$1,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pair.$2,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
