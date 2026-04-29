import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/translation_reveal_button.dart';

/// Returns true when [token] is a blank marker (2+ underscores, nothing else).
bool _isBlank(String token) => RegExp(r'^_{2,}$').hasMatch(token);

/// Cloze-sequence quiz: shows the full localized sentence with numbered blank
/// markers as soon as the question appears, then the player fills the blanks
/// in order by tapping tiles laid out horizontally like a train.
class ClozeSequenceQuizBody extends StatefulWidget {
  const ClozeSequenceQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    this.resolvedImagePath,
    this.audioAssetPath,
    required this.resolveAudioExists,
    required this.onPlayQuestionAudio,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final ClozeSequenceQuestionData data;
  final String userLanguage;
  final String? resolvedImagePath;
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

  int _currentBlank = 0;
  bool _failed = false;
  bool _translationPenalized = false;
  bool _audioPlaying = false;
  bool get _concluded => _failed || _currentBlank >= widget.data.answers.length;

  @override
  void initState() {
    super.initState();
    _tokens = widget.data.sentence.split(' ');
    _blankIndices = [
      for (var i = 0; i < _tokens.length; i++)
        if (_isBlank(_tokens[i])) i
    ];
    _filled = List.filled(_blankIndices.length, null);
    _tiles = [...widget.data.answers, ...widget.data.distractors]
      ..shuffle(Random());
    _tileStates = List.filled(_tiles.length, _TileState.normal);
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

  Future<void> _onTranslationRevealed() async {
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

  Future<void> _onTileTap(int tileIndex) async {
    if (_failed) return;
    final word = _tiles[tileIndex];
    final state = _tileStates[tileIndex];
    final multi = widget.data.answers.length > 1;

    if (multi && state == _TileState.correct) {
      setState(() {
        _currentBlank = 0;
        _filled = List.filled(_blankIndices.length, null);
        _tileStates = List.filled(_tiles.length, _TileState.normal);
      });
      return;
    }

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
      final expIdx = _tiles.indexOf(expected);
      setState(() {
        _failed = true;
        _tileStates[tileIndex] = _TileState.wrong;
        if (expIdx >= 0) _tileStates[expIdx] = _TileState.expected;
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
      if (_isBlank(t)) {
        final filled = _filled[blankI];
        if (filled != null) {
          spans.add(TextSpan(
            text: filled,
            style: TextStyle(
              color: _translationPenalized
                  ? Colors.blue.shade700
                  : Colors.green.shade700,
              fontWeight: FontWeight.w700,
            ),
          ));
        } else if (_failed) {
          final alreadyFilled = blankI < _currentBlank;
          spans.add(TextSpan(
            text: widget.data.answers[blankI],
            style: TextStyle(
              color: alreadyFilled
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
              fontWeight: FontWeight.w700,
              fontStyle: alreadyFilled ? null : FontStyle.italic,
            ),
          ));
        } else {
          spans.add(TextSpan(
            text: '_____ (${blankI + 1})',
            style: TextStyle(
              color: cs.primary,
              fontStyle: FontStyle.italic,
            ),
          ));
        }
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
    final multi = widget.data.answers.length > 1;

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

    final disabled = _failed || (isCorrect && !multi);

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
        if (isCorrect)
          Positioned(
            top: -6,
            right: -6,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: _translationPenalized
                  ? Colors.blue.shade700
                  : Colors.green.shade700,
              child: Text(
                '${_tileStates.take(index + 1).where((s) => s == _TileState.correct).length}',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
        if (widget.resolvedImagePath != null) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                widget.resolvedImagePath!,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 72, height: 72),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
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
              final ok = snap.data == true;
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AudioPlayButton(
                    isPlaying: _audioPlaying,
                    onPressed: (!ok || !_concluded)
                        ? null
                        : () => _playAudio(),
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
