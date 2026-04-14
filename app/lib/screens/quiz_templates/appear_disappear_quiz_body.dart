import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../widgets/translation_reveal_button.dart';

enum _Phase { waiting, revealing, clearing, interaction }

/// Sequence memory: pause → words in boxes → clear → recall (no intro / flash).
class AppearDisappearQuizBody extends StatefulWidget {
  const AppearDisappearQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    this.translation,
    this.audioAssetPath,
    required this.resolveAudioExists,
    required this.onPlayQuestionAudio,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final AppearDisappearQuestionData data;
  final String userLanguage;
  final Map<String, String>? translation;
  final String? audioAssetPath;
  final Future<bool> Function(String path) resolveAudioExists;
  final Future<void> Function(String path) onPlayQuestionAudio;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<AppearDisappearQuizBody> createState() =>
      _AppearDisappearQuizBodyState();
}

class _AppearDisappearQuizBodyState extends State<AppearDisappearQuizBody> {
  late List<String> _shuffledChoices;

  _Phase _phase = _Phase.waiting;
  int _revealIndex = 0;

  bool _revealCycleDone = false;
  bool _audioDone = false;
  bool _interactionEnabled = false;

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
    final combined = [...widget.data.words, ...widget.data.distractors]
      ..shuffle(Random());
    _shuffledChoices = combined;
    for (var i = 0; i < _sentence.length; i++) {
      _interactionSlots.add(null);
      _slotFromPlayer.add(false);
    }
    _startWaiting();
  }

  Future<void> _runAudio() async {
    final p = widget.audioAssetPath;
    if (p == null) {
      _audioDone = true;
      _tryEnableInteraction();
      return;
    }
    final ok = await widget.resolveAudioExists(p);
    if (!mounted) return;
    if (!ok) {
      _audioDone = true;
      _tryEnableInteraction();
      return;
    }
    await widget.onPlayQuestionAudio(p);
    if (!mounted) return;
    _audioDone = true;
    _tryEnableInteraction();
  }

  void _startWaiting() {
    _runAudio();
    _timer = Timer(
      Duration(
        milliseconds: (widget.data.introPause * 1000).round(),
      ),
      _startReveal,
    );
  }

  void _startReveal() {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.revealing;
      _revealIndex = 0;
    });
    _timer = Timer(const Duration(milliseconds: 400), _revealNextWord);
  }

  void _revealNextWord() {
    if (!mounted) return;
    if (_revealIndex >= _sentence.length) {
      _afterRevealHold();
      return;
    }
    setState(() => _revealIndex++);
    _timer = Timer(
      Duration(milliseconds: (widget.data.displayDuration * 1000).round()),
      _revealNextWord,
    );
  }

  Future<void> _afterRevealHold() async {
    if (!mounted) return;
    setState(() => _phase = _Phase.clearing);
    await Future<void>.delayed(
      Duration(
        milliseconds: (widget.data.autoNextDelay * 1000).round(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _revealCycleDone = true;
    });
    _tryEnableInteraction();
  }

  void _tryEnableInteraction() {
    if (!mounted) return;
    if (_interactionEnabled) return;
    if (!_revealCycleDone) return;
    if (!_audioDone) return;
    setState(() {
      _interactionEnabled = true;
      _phase = _Phase.interaction;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onGridTap(int gridIndex) {
    if (!_interactionEnabled || _completed || _failed) return;
    if (_correctGridIndices.contains(gridIndex) && _tapProgress > 0) {
      setState(() {
        _tapProgress = 0;
        for (var i = 0; i < _interactionSlots.length; i++) {
          _interactionSlots[i] = null;
          _slotFromPlayer[i] = false;
        }
        _correctGridIndices.clear();
        _gridIndexToStep.clear();
        _wrongGridIndex = null;
      });
      return;
    }
    final word = _shuffledChoices[gridIndex];
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

  Widget _buildBoxRow(ThemeData theme, ColorScheme cs) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(_sentence.length, (i) {
        String? word;
        bool fromPlayer = false;

        if (_phase == _Phase.waiting || _phase == _Phase.clearing) {
          word = null;
        } else if (_phase == _Phase.revealing) {
          word = i < _revealIndex ? _sentence[i] : null;
        } else {
          word = _interactionSlots[i];
          fromPlayer = i < _slotFromPlayer.length && _slotFromPlayer[i];
        }

        final isReveal = _phase == _Phase.revealing;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 56, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: word != null
                ? (isReveal
                    ? cs.primaryContainer.withValues(alpha: 0.65)
                    : fromPlayer
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest.withValues(alpha: 0.45))
                : cs.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isReveal && word != null
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tr = widget.translation;
    final aux = widget.userLanguage != 'en' && tr != null
        ? tr[widget.userLanguage]
        : null;

    if (_phase == _Phase.waiting ||
        _phase == _Phase.revealing ||
        _phase == _Phase.clearing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TranslationRevealButton(
            translationText: aux,
            userLanguage: widget.userLanguage,
          ),
          Expanded(
            child: Center(child: _buildBoxRow(theme, cs)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslationRevealButton(
          translationText: aux,
          userLanguage: widget.userLanguage,
        ),
        _buildBoxRow(theme, cs),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_shuffledChoices.length, (i) {
                final word = _shuffledChoices[i];
                final disabled =
                    _failed || _completed || !_interactionEnabled;
                final isWrong = _failed && _wrongGridIndex == i;
                final isCorrectTile = _correctGridIndices.contains(i);
                final orderLabel = _gridIndexToStep[i];

                return ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 90, minHeight: 44),
                  child: Material(
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
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
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
