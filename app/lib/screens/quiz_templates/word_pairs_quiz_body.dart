import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../widgets/answer_palette.dart';

/// Tap any tile to select it (teal outline), then tap its match on the other side. Correct →
/// both tiles turn green with a check badge and lock **in place** (no reflow to a separate
/// "matched" section — row order never changes once the pairs are shuffled at init, so the
/// player can keep using position to remember what's left). Wrong → the two tapped tiles turn
/// red with an X badge and the whole panel locks (mirrors every other answer type's
/// one-mistake-ends-the-question contract) — unlike the old behavior, the correct partner is no
/// longer highlighted green as a hint, since the fixed-position redesign has no natural place to
/// show that without it reading as a second match.
class WordPairsQuizBody extends StatefulWidget {
  const WordPairsQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    required this.strings,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
    this.onGuideTargetRendered,
  });

  final WordPairsQuestionData data;
  final String userLanguage;

  /// Current-locale localized strings — used for the "Match the {English} and {Target} words"
  /// title and the two column headers.
  final Map<String, String> strings;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  /// Optional, purely additive: fires once, the first time the left-column tiles render, with a
  /// [GlobalKey] for the first tile — any tile can start a match, so this just points at a
  /// reasonable starting spot rather than "the" correct one. Does not affect scoring, locking, or
  /// any other existing behavior.
  final void Function(GlobalKey targetKey)? onGuideTargetRendered;

  @override
  State<WordPairsQuizBody> createState() => _WordPairsQuizBodyState();
}

class _WordPairsQuizBodyState extends State<WordPairsQuizBody> {
  late Map<String, String> _match; // leftWord → rightWord
  late Map<String, String> _reverseMatch; // rightWord → leftWord

  /// Fixed at init and never mutated afterward — the whole point of the redesign is that a
  /// word's row position is a stable landmark, not something that moves as pairs resolve.
  late List<String> _left;
  late List<String> _right;
  final Set<String> _matchedLeft = {};
  final Set<String> _matchedRight = {};

  /// Currently selected word, or null.
  String? _selectedWord;

  /// True when the selected word is from the left column.
  bool _selectedIsLeft = false;

  bool _failed = false;
  String? _redLeft;
  String? _redRight;
  late final Map<String, GlobalKey> _leftTileKeys;
  late final Map<String, GlobalKey> _rightTileKeys;
  bool _reportedInitialTarget = false;

  @override
  void initState() {
    super.initState();
    _match = {
      for (final p in widget.data.pairs)
        p.left: p.rightForLanguage(widget.userLanguage),
    };
    _reverseMatch = {for (final e in _match.entries) e.value: e.key};
    _left = widget.data.pairs.map((p) => p.left).toList();
    _right = _match.values.toList()..shuffle(Random());
    _leftTileKeys = {for (final word in _left) word: GlobalKey()};
    _rightTileKeys = {for (final word in _right) word: GlobalKey()};
  }

  void _reportGuideTarget(GlobalKey? key) {
    if (key == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onGuideTargetRendered?.call(key);
    });
  }

  void _onTap(String word, bool isLeft) {
    if (_failed) return;
    if (isLeft ? _matchedLeft.contains(word) : _matchedRight.contains(word)) {
      return;
    }

    // Nothing selected yet → select this tile.
    if (_selectedWord == null) {
      setState(() {
        _selectedWord = word;
        _selectedIsLeft = isLeft;
      });
      final targetWord = isLeft ? _match[word] : _reverseMatch[word];
      _reportGuideTarget(
        isLeft ? _rightTileKeys[targetWord] : _leftTileKeys[targetWord],
      );
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
      setState(() {
        _matchedLeft.add(leftWord);
        _matchedRight.add(rightWord);
        _selectedWord = null;
      });
      final remaining = _left.where((w) => !_matchedLeft.contains(w));
      if (remaining.isNotEmpty) {
        _reportGuideTarget(_leftTileKeys[remaining.first]);
      }
      widget.onPlayCorrect();
      if (_matchedLeft.length == _left.length) {
        widget.onOutcome(true);
      }
    } else {
      setState(() {
        _failed = true;
        _selectedWord = null;
        _redLeft = leftWord;
        _redRight = rightWord;
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  /// One word box with a check/X badge overlapping its trailing edge when resolved.
  Widget _pairTile({
    required String text,
    required bool isLeft,
    required bool isSelected,
    required bool isRed,
    required bool isMatched,
    required GlobalKey key,
  }) {
    var bg = AnswerPalette.neutralBg;
    var border = AnswerPalette.neutralBorder;
    var fg = AnswerPalette.neutralFg;
    if (isMatched) {
      bg = AnswerPalette.correctBg;
      border = AnswerPalette.correctBorder;
      fg = AnswerPalette.correctFg;
    } else if (isRed) {
      bg = AnswerPalette.wrongBg;
      border = AnswerPalette.wrongBorder;
      fg = AnswerPalette.wrongFg;
    } else if (isSelected) {
      bg = const Color(0xFFE8F0FE);
      border = const Color(0xFF3B72E0);
      fg = const Color(0xFF1D4FA6);
    }
    final disabled = _failed || isMatched;

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: disabled ? null : () => _onTap(text, isLeft),
              borderRadius: BorderRadius.circular(14),
              splashFactory: NoSplash.splashFactory,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.4),
                ),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                ),
              ),
            ),
          ),
          if (isMatched || isRed)
            Positioned(
              right: -10,
              top: 0,
              bottom: 10,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMatched
                        ? AnswerPalette.correctBorder
                        : AnswerPalette.wrongBorder,
                  ),
                  child: Icon(
                    isMatched ? Icons.check : Icons.close,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_reportedInitialTarget &&
        widget.onGuideTargetRendered != null &&
        _left.isNotEmpty) {
      _reportedInitialTarget = true;
      _reportGuideTarget(_leftTileKeys[_left.first]);
    }

    final strings = widget.strings;
    final englishName = strings['language_name_en'] ?? 'English';
    final targetName = strings['language_name_${widget.userLanguage}'] ??
        widget.userLanguage.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The tutorial guide explains the matching action; do not repeat the
        // CTA above the tiles.
        Center(
          child: Container(
            width: 56,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        englishName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        targetName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Fills the available height and spaces each column's tiles evenly (mirrors
                // VideoConversationQuizBody / DialogueCompletionQuizBody / ConvoTemplate-1)
                // instead of stacking them tight at the top, which left an empty gap below the
                // tiles before the card's bottom edge. SingleChildScrollView stays as the
                // last-resort fallback for whatever still doesn't fit.
                // LayoutBuilder must wrap SingleChildScrollView, not sit inside it — see
                // VideoConversationQuizBody for why (a LayoutBuilder inside a scroll view reads
                // an unbounded/infinite maxHeight, which fed into ConstrainedBox(minHeight: ...)
                // would force infinite height instead of "fill the real available space").
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, pairsConstraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: pairsConstraints.maxHeight,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _left.map((word) {
                                    return _pairTile(
                                      key: _leftTileKeys[word]!,
                                      text: word,
                                      isLeft: true,
                                      isSelected: !_failed &&
                                          _selectedWord == word &&
                                          _selectedIsLeft,
                                      isRed: _failed && word == _redLeft,
                                      isMatched: _matchedLeft.contains(word),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _right.map((word) {
                                    return _pairTile(
                                      key: _rightTileKeys[word]!,
                                      text: word,
                                      isLeft: false,
                                      isSelected: !_failed &&
                                          _selectedWord == word &&
                                          !_selectedIsLeft,
                                      isRed: _failed && word == _redRight,
                                      isMatched: _matchedRight.contains(word),
                                    );
                                  }).toList(),
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
            ),
          ),
        ),
      ],
    );
  }
}
