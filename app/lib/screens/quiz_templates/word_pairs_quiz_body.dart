import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../services/question_layout_budget.dart';
import '../../widgets/answer_palette.dart';
import '../../widgets/debug_layout_box.dart';

typedef _WordPairsPreset = ({
  double fontSize,
  double singleLineHeight,
  double multiLineHeight,
});

/// Per-tier presets keyed by pair count (design range: 4–8 pairs, audited against all 83
/// production questions — real range is 4–6 today). More pairs get a modestly smaller preset
/// (same principle as `DialogueCompletion`'s option-count ladder) so the grid uses the screen
/// well at both ends of the range; within whichever preset is selected, a tile's own height
/// still grows for genuinely long/wrapping text (real production content includes multi-word
/// phrases like "as soon as possible") rather than ever shrinking the font below tier size.
const Map<QuestionLayoutTier, Map<int, _WordPairsPreset>> _wordPairsPresets = {
  QuestionLayoutTier.phone16to9: {
    4: (fontSize: 15.0, singleLineHeight: 56.0, multiLineHeight: 70.0),
    5: (fontSize: 14.5, singleLineHeight: 52.0, multiLineHeight: 66.0),
    6: (fontSize: 14.0, singleLineHeight: 48.0, multiLineHeight: 62.0),
    7: (fontSize: 13.5, singleLineHeight: 44.0, multiLineHeight: 58.0),
    8: (fontSize: 13.0, singleLineHeight: 40.0, multiLineHeight: 54.0),
  },
  QuestionLayoutTier.phoneClassic2to1: {
    4: (fontSize: 15.0, singleLineHeight: 56.0, multiLineHeight: 70.0),
    5: (fontSize: 14.5, singleLineHeight: 52.0, multiLineHeight: 66.0),
    6: (fontSize: 14.0, singleLineHeight: 48.0, multiLineHeight: 62.0),
    7: (fontSize: 13.5, singleLineHeight: 44.0, multiLineHeight: 58.0),
    8: (fontSize: 13.0, singleLineHeight: 40.0, multiLineHeight: 54.0),
  },
  QuestionLayoutTier.phoneTransition: {
    4: (fontSize: 15.0, singleLineHeight: 58.0, multiLineHeight: 72.0),
    5: (fontSize: 14.5, singleLineHeight: 54.0, multiLineHeight: 68.0),
    6: (fontSize: 14.0, singleLineHeight: 50.0, multiLineHeight: 64.0),
    7: (fontSize: 13.5, singleLineHeight: 46.0, multiLineHeight: 60.0),
    8: (fontSize: 13.0, singleLineHeight: 42.0, multiLineHeight: 56.0),
  },
  QuestionLayoutTier.phoneFlagship: {
    4: (fontSize: 15.5, singleLineHeight: 60.0, multiLineHeight: 74.0),
    5: (fontSize: 15.0, singleLineHeight: 56.0, multiLineHeight: 70.0),
    6: (fontSize: 14.5, singleLineHeight: 52.0, multiLineHeight: 66.0),
    7: (fontSize: 14.0, singleLineHeight: 48.0, multiLineHeight: 62.0),
    8: (fontSize: 13.5, singleLineHeight: 44.0, multiLineHeight: 58.0),
  },
  QuestionLayoutTier.phoneSuperTall: {
    4: (fontSize: 16.0, singleLineHeight: 62.0, multiLineHeight: 76.0),
    5: (fontSize: 15.5, singleLineHeight: 58.0, multiLineHeight: 72.0),
    6: (fontSize: 15.0, singleLineHeight: 54.0, multiLineHeight: 68.0),
    7: (fontSize: 14.5, singleLineHeight: 50.0, multiLineHeight: 64.0),
    8: (fontSize: 14.0, singleLineHeight: 46.0, multiLineHeight: 60.0),
  },
  QuestionLayoutTier.phoneUltraTall: {
    4: (fontSize: 16.5, singleLineHeight: 64.0, multiLineHeight: 78.0),
    5: (fontSize: 16.0, singleLineHeight: 60.0, multiLineHeight: 74.0),
    6: (fontSize: 15.5, singleLineHeight: 56.0, multiLineHeight: 70.0),
    7: (fontSize: 15.0, singleLineHeight: 52.0, multiLineHeight: 66.0),
    8: (fontSize: 14.5, singleLineHeight: 48.0, multiLineHeight: 62.0),
  },
  QuestionLayoutTier.tablet4to3: {
    4: (fontSize: 19.0, singleLineHeight: 70.0, multiLineHeight: 84.0),
    5: (fontSize: 18.5, singleLineHeight: 66.0, multiLineHeight: 80.0),
    6: (fontSize: 18.0, singleLineHeight: 62.0, multiLineHeight: 76.0),
    7: (fontSize: 17.5, singleLineHeight: 58.0, multiLineHeight: 72.0),
    8: (fontSize: 17.0, singleLineHeight: 54.0, multiLineHeight: 68.0),
  },
  QuestionLayoutTier.tablet3to2: {
    4: (fontSize: 19.5, singleLineHeight: 74.0, multiLineHeight: 88.0),
    5: (fontSize: 19.0, singleLineHeight: 70.0, multiLineHeight: 84.0),
    6: (fontSize: 18.5, singleLineHeight: 66.0, multiLineHeight: 80.0),
    7: (fontSize: 18.0, singleLineHeight: 62.0, multiLineHeight: 76.0),
    8: (fontSize: 17.5, singleLineHeight: 58.0, multiLineHeight: 72.0),
  },
  QuestionLayoutTier.tablet16to10: {
    4: (fontSize: 20.0, singleLineHeight: 76.0, multiLineHeight: 90.0),
    5: (fontSize: 19.5, singleLineHeight: 72.0, multiLineHeight: 86.0),
    6: (fontSize: 19.0, singleLineHeight: 68.0, multiLineHeight: 82.0),
    7: (fontSize: 18.5, singleLineHeight: 64.0, multiLineHeight: 78.0),
    8: (fontSize: 18.0, singleLineHeight: 60.0, multiLineHeight: 74.0),
  },
  QuestionLayoutTier.tablet16to9: {
    4: (fontSize: 20.5, singleLineHeight: 80.0, multiLineHeight: 94.0),
    5: (fontSize: 20.0, singleLineHeight: 76.0, multiLineHeight: 90.0),
    6: (fontSize: 19.5, singleLineHeight: 72.0, multiLineHeight: 86.0),
    7: (fontSize: 19.0, singleLineHeight: 68.0, multiLineHeight: 82.0),
    8: (fontSize: 18.5, singleLineHeight: 64.0, multiLineHeight: 78.0),
  },
};

/// Resolves the preset for the actual pair count, clamped to the `[4, 8]` design range — a
/// count below 4 uses the 4-pair preset, and one above 8 freezes at the 8-pair preset (font
/// never shrinks further; the existing `SingleChildScrollView` last resort absorbs the rest).
_WordPairsPreset _resolveWordPairsPreset(
    QuestionLayoutTier tier, int pairCount) {
  return _wordPairsPresets[tier]![pairCount.clamp(4, 8)]!;
}

int _measureWrappedLines({
  required String text,
  required double fontSize,
  required double maxWidth,
  required TextScaler textScaler,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout(maxWidth: max(0.0, maxWidth));
  return painter.computeLineMetrics().length;
}

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
    this.debugShowLayoutBounds = false,
  });

  final WordPairsQuestionData data;
  final String userLanguage;

  /// True only inside the `testing-responsive-design` level — draws a visible outline + label
  /// around every major layout box so box boundaries/percentages can be visually audited.
  final bool debugShowLayoutBounds;

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
  String? _lastLayoutLogKey;

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
    required double height,
    required double fontSize,
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
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.4),
                ),
                child: Center(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
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
    final budget = QuestionLayoutBudget.of(context);
    final pairCount = _left.length;
    final preset = _resolveWordPairsPreset(budget.tier, pairCount);
    const rowGap = 10.0; // matches _pairTile's own bottom padding
    const columnGap = 20.0;

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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    const SizedBox(width: columnGap),
                    Expanded(
                      child: Text(
                        targetName,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                // last-resort fallback for whatever still doesn't fit (developer-approved: the
                // 4-8 pair design range is content-authoring policed, not code-enforced).
                // LayoutBuilder must wrap SingleChildScrollView, not sit inside it — see
                // VideoConversationQuizBody for why (a LayoutBuilder inside a scroll view reads
                // an unbounded/infinite maxHeight, which fed into ConstrainedBox(minHeight: ...)
                // would force infinite height instead of "fill the real available space").
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, pairsConstraints) {
                      final textScaler = MediaQuery.textScalerOf(context);
                      final columnWidth = max(
                        0.0,
                        (pairsConstraints.maxWidth - columnGap) / 2 - 24.0,
                      );

                      // Live-measure every tile (both columns) at the resolved preset's fixed
                      // font size — text never shrinks below it, so the only unknown is how
                      // many lines each real word/phrase needs at this device's actual column
                      // width. The tallest requirement across the *entire* grid sets one shared
                      // height for every tile (both columns, all rows) — never per-row/per-column.
                      var maxLines = 1;
                      for (final word in [..._left, ..._right]) {
                        final lines = _measureWrappedLines(
                          text: word,
                          fontSize: preset.fontSize,
                          maxWidth: columnWidth,
                          textScaler: textScaler,
                        );
                        if (lines > maxLines) maxLines = lines;
                      }
                      final sharedHeight = maxLines <= 1
                          ? preset.singleLineHeight
                          : maxLines == 2
                              ? preset.multiLineHeight
                              : preset.multiLineHeight + (maxLines - 2) * 20.0;

                      // Every tile — including the last — carries its own trailing
                      // `Padding(bottom: rowGap)` (see `_pairTile`), so the real per-tile
                      // footprint is `sharedHeight + rowGap` for all `pairCount` tiles, not
                      // `sharedHeight` with gaps only *between* tiles.
                      final measuredGridHeight =
                          pairCount * (sharedHeight + rowGap);

                      final layoutLogKey = [
                        pairsConstraints.maxWidth,
                        pairsConstraints.maxHeight,
                        pairCount,
                        sharedHeight,
                        preset.fontSize,
                        budget.tier,
                      ].join('|');
                      if (_lastLayoutLogKey != layoutLogKey) {
                        _lastLayoutLogKey = layoutLogKey;
                        debugPrint(
                          '[QuestionLayout][WordPairs] '
                          'tier=${budget.tier.name} '
                          'pairCount=$pairCount '
                          'tileFont=${preset.fontSize.toStringAsFixed(1)}px '
                          'tileHeight=${sharedHeight.toStringAsFixed(1)}px '
                          'maxLines=$maxLines '
                          'gridHeight=${measuredGridHeight.toStringAsFixed(1)}px '
                          'available=${pairsConstraints.maxHeight.toStringAsFixed(1)}px',
                        );
                        if (pairCount > 8) {
                          debugPrint(
                            '[QuestionLayout][WordPairs][Warning] '
                            'pairCount ($pairCount) exceeds the supported design range of 8 '
                            '— content should be shortened; the answer area will scroll.',
                          );
                        } else if (measuredGridHeight >
                            pairsConstraints.maxHeight) {
                          debugPrint(
                            '[QuestionLayout][WordPairs][Warning] '
                            'measured grid height (${measuredGridHeight.toStringAsFixed(1)}px) '
                            'exceeds available height '
                            '(${pairsConstraints.maxHeight.toStringAsFixed(1)}px) at '
                            '$pairCount pairs — the answer area will scroll.',
                          );
                        }
                      }

                      // Explicit height (not `ConstrainedBox(minHeight:)`) — inside a
                      // `SingleChildScrollView` the incoming maxHeight is infinite, and a
                      // `Row(crossAxisAlignment: stretch)` given an infinite/indeterminate
                      // height throws when its `Column` children try to center within it. An
                      // explicit height (viewport height, or the measured grid height when
                      // that's taller — the scroll-triggering case) keeps the height always
                      // determinate.
                      final rowHeight =
                          max(measuredGridHeight, pairsConstraints.maxHeight);

                      return SingleChildScrollView(
                        child: DebugLayoutBox(
                          enabled: widget.debugShowLayoutBounds,
                          label: 'grid',
                          color: Colors.blue,
                          child: SizedBox(
                            height: rowHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                                        height: sharedHeight,
                                        fontSize: preset.fontSize,
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(width: columnGap),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                                        height: sharedHeight,
                                        fontSize: preset.fontSize,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
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
