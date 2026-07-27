import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../utils/cloze_blank.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/translation_reveal_button.dart';

/// Cloze-sequence quiz: shows the sentence with blank(s) as soon as the
/// question appears. **Multiple blanks:** fill in order by tapping word tiles
/// in a horizontal wrap. **Single blank:** full-width [ElevatedButton] choices
/// like [GrammarFormQuizBody].
class ClozeSequenceQuizBody extends StatefulWidget {
  const ClozeSequenceQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    this.audioAssetPath,
    required this.resolveAudioExists,
    required this.onPlayQuestionAudio,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final ClozeSequenceQuestionData data;
  final String userLanguage;
  final String? audioAssetPath;
  final Future<bool> Function(String path) resolveAudioExists;
  final Future<void> Function(String path) onPlayQuestionAudio;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<ClozeSequenceQuizBody> createState() => _ClozeSequenceQuizBodyState();
}

enum _TileState { normal, correct, wrong, expected }

class _ClozeSequenceQuizBodyState extends State<ClozeSequenceQuizBody> {
  late List<String> _tokens;
  late List<int> _blankIndices;
  late List<String> _tiles;
  late List<String?> _filled;
  late List<_TileState> _tileStates;

  /// Single-blank mode: MCQ buttons (see [GrammarFormQuizBody]).
  late List<String> _buttonOptions;
  late int _buttonCorrectIndex;
  bool _buttonLocked = false;
  int? _buttonSelectedIndex;

  int _currentBlank = 0;
  bool _failed = false;
  bool _translationPenalized = false;
  bool _audioPlaying = false;
  Map<int, int> _expectedTileBlankIndex = {};

  bool get _singleBlank => widget.data.answers.length == 1;

  bool get _concluded =>
      _singleBlank
          ? _buttonLocked
          : _failed || _currentBlank >= widget.data.answers.length;

  @override
  void initState() {
    super.initState();
    _tokens = widget.data.sentence.split(' ');
    _blankIndices = [
      for (var i = 0; i < _tokens.length; i++)
        if (isClozeBlankToken(_tokens[i])) i
    ];
    _filled = List.filled(_blankIndices.length, null);

    if (_singleBlank) {
      final a = widget.data.answers.first;
      _buttonOptions = [a, ...widget.data.distractors]..shuffle(Random());
      _buttonCorrectIndex = _buttonOptions.indexOf(a);
      _tiles = [];
      _tileStates = [];
    } else {
      _tiles = [...widget.data.answers, ...widget.data.distractors]
        ..shuffle(Random());
      _tileStates = List.filled(_tiles.length, _TileState.normal);
      _buttonOptions = [];
      _buttonCorrectIndex = 0;
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

  Future<void> _onTranslationRevealedSingle() async {
    if (_buttonLocked || widget.data.trOk) return;
    setState(() {
      _buttonLocked = true;
      _translationPenalized = true;
    });
    widget.onPlayWrong();
    await _playAudio();
    if (!mounted) return;
    widget.onOutcome(false);
  }

  Future<void> _onTranslationRevealed() async {
    if (_singleBlank) {
      await _onTranslationRevealedSingle();
      return;
    }
    if (_failed || widget.data.trOk) return;
    if (_currentBlank >= widget.data.answers.length) return;
    final newFilled = List<String?>.from(_filled);
    final newTileStates = List<_TileState>.from(_tileStates);
    for (var b = _currentBlank; b < widget.data.answers.length; b++) {
      final answer = widget.data.answers[b];
      for (var t = 0; t < _tiles.length; t++) {
        if (_tiles[t] == answer && newTileStates[t] != _TileState.correct) {
          newTileStates[t] = _TileState.correct;
          newFilled[b] = answer;
          break;
        }
      }
    }
    setState(() {
      _failed = true;
      _translationPenalized = true;
      _filled = newFilled;
      _tileStates = newTileStates;
      _currentBlank = widget.data.answers.length;
    });
    widget.onPlayWrong();
    await _playAudio();
    if (!mounted) return;
    widget.onOutcome(false);
  }

  Future<void> _onSingleButtonTap(int i) async {
    if (_buttonLocked) return;
    final ok = _buttonOptions[i] == widget.data.answers.first;
    setState(() {
      _buttonLocked = true;
      _buttonSelectedIndex = i;
    });
    if (ok) {
      widget.onPlayCorrect();
      await _playAudio();
      if (!mounted) return;
      widget.onOutcome(true);
    } else {
      widget.onPlayWrong();
      await _playAudio();
      if (!mounted) return;
      widget.onOutcome(false);
    }
  }

  Future<void> _onTileTap(int tileIndex) async {
    if (_failed) return;
    final word = _tiles[tileIndex];
    final state = _tileStates[tileIndex];
    // Already-placed correct tiles are inert (no full-reset on re-tap).
    if (state == _TileState.correct) return;

    final expected = widget.data.answers[_currentBlank];

    if (word == expected) {
      setState(() {
        _tileStates[tileIndex] = _TileState.correct;
        _filled[_currentBlank] = word;
        _currentBlank++;
      });
      widget.onPlayCorrect();
      if (_currentBlank >= widget.data.answers.length) {
        await _playAudio();
        if (!mounted) return;
        widget.onOutcome(true);
      }
    } else {
      final newTileStates = List<_TileState>.from(_tileStates);
      newTileStates[tileIndex] = _TileState.wrong;
      final newExpectedMap = <int, int>{};
      for (var b = _currentBlank; b < widget.data.answers.length; b++) {
        final ans = widget.data.answers[b];
        for (var t = 0; t < _tiles.length; t++) {
          if (_tiles[t] == ans &&
              newTileStates[t] != _TileState.correct &&
              newTileStates[t] != _TileState.wrong) {
            newTileStates[t] = _TileState.expected;
            newExpectedMap[t] = b;
            break;
          }
        }
      }
      setState(() {
        _failed = true;
        _tileStates = newTileStates;
        _expectedTileBlankIndex = newExpectedMap;
      });
      widget.onPlayWrong();
      await _playAudio();
      if (!mounted) return;
      widget.onOutcome(false);
    }
  }

  List<InlineSpan> _buildSentenceSpans(ThemeData theme) {
    final cs = theme.colorScheme;
    final spans = <InlineSpan>[];
    var blankI = 0;

    for (var i = 0; i < _tokens.length; i++) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' '));
      final t = _tokens[i];
      if (isClozeBlankToken(t)) {
        final core = stripClozeBlankAffixes(t);
        final coreStart = t.indexOf(core);
        final prefix = coreStart > 0 ? t.substring(0, coreStart) : '';
        final suffix = t.substring(coreStart + core.length);
        final filled = _filled[blankI];
        late final String blankText;
        late final TextStyle blankStyle;
        if (filled != null) {
          blankText = filled;
          blankStyle = TextStyle(
            color: _translationPenalized
                ? Colors.blue.shade700
                : Colors.green.shade700,
            fontWeight: FontWeight.w700,
          );
        } else if (_failed) {
          final alreadyFilled = blankI < _currentBlank;
          blankText = widget.data.answers[blankI];
          blankStyle = TextStyle(
            color: alreadyFilled
                ? Colors.green.shade700
                : Colors.orange.shade700,
            fontWeight: FontWeight.w700,
            fontStyle: alreadyFilled ? null : FontStyle.italic,
          );
        } else {
          blankText = '_____ (${blankI + 1})';
          blankStyle = TextStyle(
            color: cs.primary,
            fontStyle: FontStyle.italic,
          );
        }
        if (prefix.isNotEmpty) spans.add(TextSpan(text: prefix));
        spans.add(TextSpan(text: blankText, style: blankStyle));
        if (suffix.isNotEmpty) spans.add(TextSpan(text: suffix));
        blankI++;
      } else {
        spans.add(TextSpan(text: t));
      }
    }

    return spans;
  }

  Widget _buildTile(int index, ThemeData theme) {
    final cs = theme.colorScheme;
    final word = _tiles[index];
    final state = _tileStates[index];
    final isCorrect = state == _TileState.correct;
    final isWrong = state == _TileState.wrong;
    final isExpected = state == _TileState.expected;

    Color bg = cs.surfaceContainerHighest;
    Color? fg;
    if (isCorrect) {
      bg = _translationPenalized ? Colors.blue.shade100 : Colors.green.shade100;
      fg = _translationPenalized ? Colors.blue.shade900 : Colors.green.shade900;
    } else if (isWrong) {
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
    } else if (isExpected) {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    }

    final disabled = _failed || isCorrect;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: disabled ? null : () => _onTileTap(index),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                word,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
        if (isCorrect || isExpected)
          Positioned(
            top: -6,
            right: -6,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: _translationPenalized
                  ? Colors.blue.shade700
                  : Colors.green.shade700,
              child: Text(
                isCorrect
                    ? '${_tileStates.take(index + 1).where((s) => s == _TileState.correct).length}'
                    : '${(_expectedTileBlankIndex[index] ?? 0) + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleBlankBody(ThemeData theme, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslationRevealButton(
          englishItems: widget.data.englishToTranslate,
          localItems: widget.data.localTranslation,
          userLanguage: widget.userLanguage,
          onRevealed: _onTranslationRevealedSingle,
          enabled: !_audioPlaying,
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.data.sentence,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.audioAssetPath != null)
          FutureBuilder<bool>(
            future: widget.resolveAudioExists(widget.audioAssetPath!),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done ||
                  snap.data != true) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AudioPlayButton(
                    isPlaying: _audioPlaying,
                    onPressed: !_concluded ? null : () => _playAudio(),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 8),
        ...List.generate(_buttonOptions.length, (i) {
          final opt = _buttonOptions[i];
          final isSel = _buttonSelectedIndex == i;
          final isCor = _buttonLocked && i == _buttonCorrectIndex;
          Color? bg;
          Color? fg;
          if (_buttonLocked) {
            if (isCor) {
              bg = _translationPenalized
                  ? Colors.blue.shade600
                  : Colors.green.shade600;
              fg = Colors.white;
            } else if (isSel) {
              bg = Colors.red.shade600;
              fg = Colors.white;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _buttonLocked ? null : () => _onSingleButtonTap(i),
                style: ElevatedButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: fg,
                  disabledBackgroundColor: bg,
                  disabledForegroundColor: fg,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(opt, textAlign: TextAlign.center),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_singleBlank) {
      return _buildSingleBlankBody(theme, cs);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslationRevealButton(
          englishItems: widget.data.englishToTranslate,
          localItems: widget.data.localTranslation,
          userLanguage: widget.userLanguage,
          onRevealed: _onTranslationRevealed,
          enabled: !_audioPlaying,
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.titleMedium?.copyWith(
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              children: _buildSentenceSpans(theme),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.audioAssetPath != null)
          FutureBuilder<bool>(
            future: widget.resolveAudioExists(widget.audioAssetPath!),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done ||
                  snap.data != true) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AudioPlayButton(
                    isPlaying: _audioPlaying,
                    onPressed: !_concluded ? null : () => _playAudio(),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            _tiles.length,
            (i) => _buildTile(i, theme),
          ),
        ),
      ],
    );
  }
}
