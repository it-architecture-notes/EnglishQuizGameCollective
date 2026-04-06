import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';

enum _InternalPhase { intro, revealing, flashing, interaction }

/// Sequence memory: intro prompt → boxes fill word-by-word → flash → clear → player recalls.
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

  _InternalPhase _internalPhase = _InternalPhase.intro;
  int _revealIndex = 0;      // number of boxes filled during reveal
  bool _flashVisible = true; // toggles word visibility during flash phase

  // Interaction state
  int _tapProgress = 0;
  final List<String?> _interactionSlots = [];
  final List<bool> _slotFromPlayer = [];
  bool _failed = false;
  int? _wrongGridIndex;
  final Set<int> _correctGridIndices = {};
  final Map<int, int> _gridIndexToStep = {};
  bool _completed = false;

  Timer? _timer;

  List<String> get _sentence => widget.data.words;

  @override
  void initState() {
    super.initState();
    final combined = [...widget.data.words, ...widget.data.distractors]..shuffle(Random());
    _shuffledGrid = combined;
    for (var i = 0; i < _sentence.length; i++) {
      _interactionSlots.add(null);
      _slotFromPlayer.add(false);
    }
    // Show intro message for 3 seconds, then start reveal
    _timer = Timer(const Duration(seconds: 3), _startRevealPhase);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Phases ─────────────────────────────────────────────────────────────────

  void _startRevealPhase() {
    if (!mounted) return;
    setState(() {
      _internalPhase = _InternalPhase.revealing;
      _revealIndex = 0;
    });
    // Brief pause so the user sees empty boxes before words appear
    _timer = Timer(const Duration(milliseconds: 400), _revealNextWord);
  }

  void _revealNextWord() {
    if (!mounted) return;
    if (_revealIndex >= _sentence.length) {
      _startFlashing();
      return;
    }
    setState(() => _revealIndex++);
    _timer = Timer(
      Duration(milliseconds: (widget.data.displayDuration * 1000).round()),
      _revealNextWord,
    );
  }

  Future<void> _startFlashing() async {
    if (!mounted) return;
    setState(() {
      _internalPhase = _InternalPhase.flashing;
      _flashVisible = true;
    });
    // Hold full sentence visible briefly before flashing
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Flash twice: off → on → off → on
    for (var i = 0; i < 2; i++) {
      if (!mounted) return;
      setState(() => _flashVisible = false);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() => _flashVisible = true);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    // Clear boxes and enter interaction phase
    setState(() => _internalPhase = _InternalPhase.interaction);
  }

  // ── Interaction ─────────────────────────────────────────────────────────────

  void _onGridTap(int gridIndex) {
    if (_completed || _failed || _internalPhase != _InternalPhase.interaction) return;
    final word = _shuffledGrid[gridIndex];
    final expected = _sentence[_tapProgress];
    if (word == expected) {
      setState(() {
        _interactionSlots[_tapProgress] = word;
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
      _timer?.cancel();
      setState(() {
        _failed = true;
        _wrongGridIndex = gridIndex;
        for (var i = _tapProgress; i < _sentence.length; i++) {
          _interactionSlots[i] = _sentence[i];
          _slotFromPlayer[i] = false;
        }
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  // ── Shared box row ──────────────────────────────────────────────────────────

  Widget _buildBoxRow(ThemeData theme, ColorScheme cs) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(_sentence.length, (i) {
        String? word;
        bool fromPlayer = false;

        switch (_internalPhase) {
          case _InternalPhase.intro:
            word = null;
          case _InternalPhase.revealing:
            word = i < _revealIndex ? _sentence[i] : null;
          case _InternalPhase.flashing:
            word = _flashVisible ? _sentence[i] : null;
          case _InternalPhase.interaction:
            word = _interactionSlots[i];
            fromPlayer = i < _slotFromPlayer.length && _slotFromPlayer[i];
        }

        final isRevealOrFlash = _internalPhase == _InternalPhase.revealing ||
            _internalPhase == _InternalPhase.flashing;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 56, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: word != null
                ? (isRevealOrFlash
                    ? cs.primaryContainer.withValues(alpha: 0.65)
                    : fromPlayer
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest.withValues(alpha: 0.45))
                : cs.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isRevealOrFlash && word != null
                  ? cs.primary.withValues(alpha: 0.5)
                  : fromPlayer
                      ? cs.primary
                      : cs.outline.withValues(alpha: 0.7),
              width: fromPlayer ? 2 : 1,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Text(
                word ?? '___',
                key: ValueKey(word ?? '_empty_$i'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontStyle: word == null ? FontStyle.italic : null,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Intro phase: centered instructional message only
    if (_internalPhase == _InternalPhase.intro) {
      return Center(
        child: Text(
          widget.strings['follow_the_words'] ?? 'Follow the words',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Revealing / flashing: centered box row, no grid
    if (_internalPhase == _InternalPhase.revealing ||
        _internalPhase == _InternalPhase.flashing) {
      return Center(child: _buildBoxRow(theme, cs));
    }

    // Interaction: prompt + boxes + grid
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
        _buildBoxRow(theme, cs),
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
    );
  }
}
