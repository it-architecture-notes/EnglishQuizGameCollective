import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../widgets/answer_palette.dart';
import '../../widgets/audio_play_button.dart';

enum _Phase { revealing, clearing, interaction }

/// Words visible immediately → audio plays → 500 ms after audio → words clear → recall.
class AppearDisappearQuizBody extends StatefulWidget {
  const AppearDisappearQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    this.audioAssetPath,
    required this.resolveAudioExists,
    required this.onPlayQuestionAudio,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
    this.onNextTileRendered,
  });

  final AppearDisappearQuestionData data;
  final String userLanguage;
  final String? audioAssetPath;
  final Future<bool> Function(String path) resolveAudioExists;
  final Future<void> Function(String path) onPlayQuestionAudio;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;
  final void Function(int expectedIndex, List<GlobalKey> tileKeys)? onNextTileRendered;

  @override
  State<AppearDisappearQuizBody> createState() =>
      _AppearDisappearQuizBodyState();
}

class _AppearDisappearQuizBodyState extends State<AppearDisappearQuizBody> {
  late List<String> _shuffledChoices;

  _Phase _phase = _Phase.revealing;
  bool _interactionEnabled = false;

  int _tapProgress = 0;
  final List<String?> _interactionSlots = [];
  final List<bool> _slotFromPlayer = [];
  bool _failed = false;
  bool _translationPenalized = false;
  int? _wrongGridIndex;
  final Set<int> _correctGridIndices = {};
  final Map<int, int> _gridIndexToStep = {};
  late final List<GlobalKey> _tileKeys;
  bool _completed = false;
  bool _audioPlaying = false;

  List<String> get _sentence => widget.data.words;

  @override
  void initState() {
    super.initState();
    final combined = [...widget.data.words, ...widget.data.distractors]
      ..shuffle(Random());
    _shuffledChoices = combined;
    _tileKeys = List.generate(_shuffledChoices.length, (_) => GlobalKey());
    for (var i = 0; i < _sentence.length; i++) {
      _interactionSlots.add(null);
      _slotFromPlayer.add(false);
    }
    _runAudioThenDisappear();
  }

  Future<void> _runAudioThenDisappear() async {
    final p = widget.audioAssetPath;
    if (p != null) {
      final ok = await widget.resolveAudioExists(p);
      if (mounted && ok) {
        await widget.onPlayQuestionAudio(p);
      }
    }
    if (!mounted) return;
    await Future<void>.delayed(
        Duration(milliseconds: (_sentence.length * 400).round()));
    if (!mounted) return;
    setState(() => _phase = _Phase.clearing);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _phase = _Phase.interaction;
      _interactionEnabled = true;
    });
    _reportNextTile();
  }

  Future<void> _playAudio() async {
    final p = widget.audioAssetPath;
    if (p == null) return;
    final ok = await widget.resolveAudioExists(p);
    if (!ok || !mounted) return;
    setState(() => _audioPlaying = true);
    try {
      await widget.onPlayQuestionAudio(p);
    } finally {
      if (mounted) setState(() => _audioPlaying = false);
    }
  }

  void _reportNextTile() {
    if (!_interactionEnabled || _tapProgress >= _sentence.length) return;
    final index = _shuffledChoices.indexWhere(
      (word) => word == _sentence[_tapProgress] && !_correctGridIndices.contains(_shuffledChoices.indexOf(word)),
    );
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onNextTileRendered?.call(_tapProgress, _tileKeys);
    });
  }

  void _onTranslationRevealed() {
    if (_failed || _completed || !_interactionEnabled || widget.data.trOk) return;
    setState(() {
      _failed = true;
      _translationPenalized = true;
      _wrongGridIndex = null;
      for (var pos = _tapProgress; pos < _sentence.length; pos++) {
        final word = _sentence[pos];
        for (var gi = 0; gi < _shuffledChoices.length; gi++) {
          if (_shuffledChoices[gi] == word && !_correctGridIndices.contains(gi)) {
            _correctGridIndices.add(gi);
            _gridIndexToStep[gi] = pos + 1;
            _interactionSlots[pos] = word;
            _slotFromPlayer[pos] = false;
            break;
          }
        }
      }
      _tapProgress = _sentence.length;
    });
    widget.onPlayWrong();
    widget.onOutcome(false);
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
      _reportNextTile();
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
      _reportNextTile();
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

        if (_phase == _Phase.clearing) {
          word = null;
        } else if (_phase == _Phase.revealing) {
          word = _sentence[i];
        } else {
          word = _interactionSlots[i];
          fromPlayer = i < _slotFromPlayer.length && _slotFromPlayer[i];
        }

        final isReveal = _phase == _Phase.revealing;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 36, minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: (isReveal || fromPlayer)
                    ? AnswerPalette.correctBorder
                    : cs.outline,
                width: (isReveal || fromPlayer) ? 2.5 : 1.5,
              ),
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: word == null
                  ? const SizedBox.shrink()
                  : Text(
                      word,
                      key: ValueKey(word),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isReveal || fromPlayer
                            ? AnswerPalette.correctFg
                            : null,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.audioAssetPath != null)
          FutureBuilder<bool>(
            future: widget.resolveAudioExists(widget.audioAssetPath!),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done || snap.data != true) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AudioPlayButton(
                    isPlaying: _audioPlaying,
                    onPressed: _failed && !_audioPlaying ? _playAudio : null,
                  ),
                ],
              );
            },
          ),
        _buildBoxRow(theme, cs),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
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
                  key: _tileKeys[i],
                  constraints: const BoxConstraints(
                    minWidth: 90,
                    minHeight: 52,
                    maxHeight: 68,
                  ),
                  child: Material(
                    color: isWrong
                        ? AnswerPalette.wrongBg
                        : isCorrectTile
                            ? (_translationPenalized
                                ? AnswerPalette.revealedBg
                                : AnswerPalette.correctBg)
                            : AnswerPalette.neutralBg,
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
                                    ? AnswerPalette.wrongFg
                                    : isCorrectTile
                                        ? (_translationPenalized
                                            ? AnswerPalette.revealedFg
                                            : AnswerPalette.correctFg)
                                        : AnswerPalette.neutralFg,
                              ),
                            ),
                          ),
                          if (isCorrectTile && orderLabel != null)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: _translationPenalized
                                    ? AnswerPalette.revealedBorder
                                    : AnswerPalette.correctBorder,
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
            ),
          ),
        ),
      ],
    );
  }
}
