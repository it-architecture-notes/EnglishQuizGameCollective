import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';

/// Sequence memory: words appear one-by-one, disappear, then 3×3 grid + ghost slots.
class AppearDisappearQuizBody extends StatefulWidget {
  const AppearDisappearQuizBody({
    super.key,
    required this.data,
    required this.strings,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final AppearDisappearQuestionData data;
  final Map<String, String> strings;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  /// Single call per question: `true` = full success (parent auto-advances); `false` = failed (parent shows Next).
  final void Function(bool correct) onOutcome;

  @override
  State<AppearDisappearQuizBody> createState() => _AppearDisappearQuizBodyState();
}

class _AppearDisappearQuizBodyState extends State<AppearDisappearQuizBody> {
  late List<String> _shuffledGrid;

  int _wordRevealIndex = 0;
  String? _visibleWord;
  bool _showGridPhase = false;
  int _tapProgress = 0;
  final List<String?> _ghostSlots = [];
  final List<bool> _ghostFromPlayer = [];
  bool _failed = false;
  int? _wrongGridIndex;
  final Set<int> _correctGridIndices = {};
  final Map<int, int> _gridIndexToStep = {};
  Timer? _wordTimer;
  bool _completed = false;

  List<String> get _sentence => widget.data.words;

  @override
  void initState() {
    super.initState();
    final combined = [...widget.data.words, ...widget.data.distractors]..shuffle(Random());
    _shuffledGrid = combined;
    for (var i = 0; i < _sentence.length; i++) {
      _ghostSlots.add(null);
      _ghostFromPlayer.add(false);
    }
    _startWordSequence();
  }

  @override
  void dispose() {
    _wordTimer?.cancel();
    super.dispose();
  }

  void _startWordSequence() {
    _wordRevealIndex = 0;
    _showWordStep();
  }

  void _showWordStep() {
    _wordTimer?.cancel();
    if (_wordRevealIndex >= _sentence.length) {
      setState(() {
        _visibleWord = null;
        _showGridPhase = true;
      });
      return;
    }
    setState(() {
      _visibleWord = _sentence[_wordRevealIndex];
    });
    _wordTimer = Timer(
      Duration(
        milliseconds: (widget.data.displayDuration * 1000).round(),
      ),
      () {
        if (!mounted) return;
        setState(() => _visibleWord = null);
        _wordRevealIndex++;
        Future<void>.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _showWordStep();
        });
      },
    );
  }

  void _onGridTap(int gridIndex) {
    if (_completed || _failed || !_showGridPhase) return;
    final word = _shuffledGrid[gridIndex];
    final expected = _sentence[_tapProgress];
    if (word == expected) {
      setState(() {
        _ghostSlots[_tapProgress] = word;
        _ghostFromPlayer[_tapProgress] = true;
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
      _wordTimer?.cancel();
      setState(() {
        _failed = true;
        _wrongGridIndex = gridIndex;
        for (var i = 0; i < _tapProgress; i++) {
          // already filled
        }
        for (var i = _tapProgress; i < _sentence.length; i++) {
          _ghostSlots[i] = _sentence[i];
          _ghostFromPlayer[i] = false;
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
        if (!_showGridPhase) ...[
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _visibleWord != null
                    ? Text(
                        _visibleWord!,
                        key: ValueKey(_visibleWord),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : SizedBox(
                        key: const ValueKey('empty'),
                        height: 48,
                      ),
              ),
            ),
          ),
        ] else ...[
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
            children: List.generate(_ghostSlots.length, (i) {
              final w = _ghostSlots[i];
              final fromPlayer = i < _ghostFromPlayer.length && _ghostFromPlayer[i];
              return Container(
                constraints: const BoxConstraints(minWidth: 56, minHeight: 36),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: w != null
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
                    w ?? '___',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontStyle: w == null ? FontStyle.italic : null,
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
              itemCount: 9,
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
        ],
      ],
    );
  }
}
