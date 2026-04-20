import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';

/// Tap any tile to select it (blue), then tap its match on the other side.
/// Correct → both move to the matched section. Wrong → both tapped tiles turn
/// red, the correct partner turns green.
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
  final List<(String, String)> _matchedPairs = [];

  /// Currently selected word, or null.
  String? _selectedWord;
  /// True when the selected word is from the left column.
  bool _selectedIsLeft = false;

  bool _failed = false;
  String? _redLeft;
  String? _redRight;
  String? _greenLeft;
  String? _greenRight;

  @override
  void initState() {
    super.initState();
    _match = {
      for (final p in widget.data.pairs)
        p.left: p.rightForLanguage(widget.userLanguage),
    };
    _reverseMatch = {for (final e in _match.entries) e.value: e.key};
    _activeLeft = widget.data.pairs.map((p) => p.left).toList();
    _activeRight = _match.values.toList()..shuffle(Random());
  }

  void _onTap(String word, bool isLeft) {
    if (_failed) return;

    // Nothing selected yet → select this tile.
    if (_selectedWord == null) {
      setState(() {
        _selectedWord = word;
        _selectedIsLeft = isLeft;
      });
      return;
    }

    // Same tile tapped again → deselect.
    if (_selectedWord == word && _selectedIsLeft == isLeft) {
      setState(() => _selectedWord = null);
      return;
    }

    // Same side tapped → switch selection to new tile.
    if (_selectedIsLeft == isLeft) {
      setState(() => _selectedWord = word);
      return;
    }

    // Other side tapped → attempt match.
    final sel = _selectedWord!;
    final selIsLeft = _selectedIsLeft;

    final leftWord = selIsLeft ? sel : word;
    final rightWord = selIsLeft ? word : sel;

    if (_match[leftWord] == rightWord) {
      // Correct pair.
      setState(() {
        _activeLeft.remove(leftWord);
        _activeRight.remove(rightWord);
        _matchedPairs.add((leftWord, rightWord));
        _selectedWord = null;
      });
      widget.onPlayCorrect();
      if (_activeLeft.isEmpty) {
        widget.onOutcome(true);
      }
    } else {
      // Wrong pair — both tapped tiles red, correct partner green.
      setState(() {
        _failed = true;
        _selectedWord = null;
        _redLeft = leftWord;
        _redRight = rightWord;
        if (selIsLeft) {
          // Selected left, tapped wrong right → show correct right green.
          _greenRight = _match[sel];
          _greenLeft = null;
        } else {
          // Selected right, tapped wrong left → show correct left green.
          _greenLeft = _reverseMatch[sel];
          _greenRight = null;
        }
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
                  final isSelected =
                      !_failed && _selectedWord == word && _selectedIsLeft;
                  final isRed = _failed && word == _redLeft;
                  final isGreen = _failed && word == _greenLeft;
                  return _activeTile(
                    text: word,
                    bgColor: isGreen
                        ? Colors.green.shade100
                        : isRed
                            ? Colors.red.shade100
                            : null,
                    textColor: isGreen
                        ? Colors.green.shade900
                        : isRed
                            ? Colors.red.shade900
                            : null,
                    selected: isSelected,
                    onTap: !_failed ? () => _onTap(word, true) : null,
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
                  final isSelected =
                      !_failed && _selectedWord == word && !_selectedIsLeft;
                  final isRed = _failed && word == _redRight;
                  final isGreen = _failed && word == _greenRight;
                  return _activeTile(
                    text: word,
                    bgColor: isGreen
                        ? Colors.green.shade100
                        : isRed
                            ? Colors.red.shade100
                            : null,
                    textColor: isGreen
                        ? Colors.green.shade900
                        : isRed
                            ? Colors.red.shade900
                            : null,
                    selected: isSelected,
                    onTap: !_failed ? () => _onTap(word, false) : null,
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
