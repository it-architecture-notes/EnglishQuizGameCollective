import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/translation_reveal_button.dart';

/// Sentence tokens only, shuffled on tiles; tap in [SentenceBuilderQuestionData.correctOrder].
/// Uses a random permutation of sentence positions so duplicate words are unambiguous.
class SentenceBuilderQuizBody extends StatefulWidget {
  const SentenceBuilderQuizBody({
    super.key,
    required this.data,
    required this.strings,
    required this.userLanguage,
    this.audioAssetPath,
    required this.resolveAudioExists,
    required this.onPlayQuestionAudio,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final SentenceBuilderQuestionData data;
  final Map<String, String> strings;
  final String userLanguage;
  final String? audioAssetPath;
  final Future<bool> Function(String path) resolveAudioExists;
  final Future<void> Function(String path) onPlayQuestionAudio;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<SentenceBuilderQuizBody> createState() =>
      _SentenceBuilderQuizBodyState();
}

class _SentenceBuilderQuizBodyState extends State<SentenceBuilderQuizBody> {
  /// Random permutation of `0..n-1`: cell `i` shows sentence token at index [_perm[i]].
  late List<int> _perm;
  final Set<int> _usedCellIndices = {};

  late List<String> _sentence;

  int _tapProgress = 0;
  final List<String?> _slots = [];
  final List<bool> _slotFromPlayer = [];
  bool _failed = false;
  bool _translationPenalized = false;
  int? _wrongGridIndex;
  final Map<int, int> _cellToStep = {};
  bool _completed = false;
  bool _audioPlaying = false;

  List<String> get _target => widget.data.correctOrder;

  @override
  void initState() {
    super.initState();
    _sentence = List<String>.from(_target);
    final n = _sentence.length;
    _perm = List.generate(n, (i) => i)..shuffle(Random());
    if (n > 1) {
      var guard = 0;
      while (_isIdentityPerm(_perm) && guard < 40) {
        _perm.shuffle(Random());
        guard++;
      }
    }
    for (var i = 0; i < _sentence.length; i++) {
      _slots.add(null);
      _slotFromPlayer.add(false);
    }
  }

  bool _isIdentityPerm(List<int> p) {
    for (var i = 0; i < p.length; i++) {
      if (p[i] != i) return false;
    }
    return true;
  }

  String _wordAtCell(int cellIndex) => _sentence[_perm[cellIndex]];

  void _onTranslationRevealed() {
    if (_failed || _completed || widget.data.trOk) return;
    setState(() {
      _failed = true;
      _translationPenalized = true;
      _wrongGridIndex = null;
      for (var pos = _tapProgress; pos < _sentence.length; pos++) {
        for (var cell = 0; cell < _perm.length; cell++) {
          if (_perm[cell] == pos && !_usedCellIndices.contains(cell)) {
            _usedCellIndices.add(cell);
            _slots[pos] = _sentence[pos];
            _slotFromPlayer[pos] = false;
            _cellToStep[cell] = pos + 1;
            break;
          }
        }
      }
      _tapProgress = _sentence.length;
    });
    widget.onPlayWrong();
    widget.onOutcome(false);
  }

  void _onGridTap(int cellIndex) {
    if (_completed || _failed || _usedCellIndices.contains(cellIndex)) return;
    final sentencePos = _perm[cellIndex];
    final expectedPos = _tapProgress;
    if (sentencePos == expectedPos) {
      setState(() {
        _slots[_tapProgress] = _sentence[expectedPos];
        _slotFromPlayer[_tapProgress] = true;
        _usedCellIndices.add(cellIndex);
        _cellToStep[cellIndex] = _tapProgress + 1;
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
        _wrongGridIndex = cellIndex;
        for (var i = _tapProgress; i < _sentence.length; i++) {
          _slots[i] = _sentence[i];
          _slotFromPlayer[i] = false;
        }
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final n = _perm.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslationRevealButton(
          englishItems: widget.data.englishToTranslate,
          localItems: widget.data.localTranslation,
          userLanguage: widget.userLanguage,
          onRevealed: _onTranslationRevealed,
        ),
        FutureBuilder<bool>(
          future: widget.audioAssetPath == null
              ? Future.value(false)
              : widget.resolveAudioExists(widget.audioAssetPath!),
          builder: (context, snap) {
            final ok = snap.data == true;
            final p = widget.audioAssetPath;
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AudioPlayButton(
                  isPlaying: _audioPlaying,
                  onPressed: !ok || p == null ? null : _playAudio,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
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
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(n, (i) {
                final word = _wordAtCell(i);
                final disabled = _failed || _completed || _usedCellIndices.contains(i);
                final isWrong = _failed && _wrongGridIndex == i;
                final step = _cellToStep[i];
                final tapped = _usedCellIndices.contains(i);

                return Material(
                  color: isWrong
                      ? Colors.red.shade100
                      : tapped
                          ? (_translationPenalized
                              ? Colors.blue.shade100
                              : Colors.green.shade100)
                          : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: disabled ? null : () => _onGridTap(i),
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 72,
                        minHeight: 44,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Text(
                              word,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isWrong
                                    ? Colors.red.shade900
                                    : tapped
                                        ? (_translationPenalized
                                            ? Colors.blue.shade900
                                            : Colors.green.shade900)
                                        : null,
                              ),
                            ),
                          ),
                          if (step != null)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: _translationPenalized
                                    ? Colors.blue.shade700
                                    : Colors.green.shade700,
                                child: Text(
                                  '$step',
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
