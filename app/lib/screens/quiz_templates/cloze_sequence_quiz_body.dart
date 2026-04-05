import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';

bool _isBlank(String s) => s == '___' || s == '_____';

/// Word-by-word reveal with numbered cloze blanks; fill in order from grid.
class ClozeSequenceQuizBody extends StatefulWidget {
  const ClozeSequenceQuizBody({
    super.key,
    required this.data,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final ClozeSequenceQuestionData data;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<ClozeSequenceQuizBody> createState() => _ClozeSequenceQuizBodyState();
}

class _ClozeSequenceQuizBodyState extends State<ClozeSequenceQuizBody> {
  late List<String> _shuffledTiles;
  int _streamIndex = 0;
  Timer? _streamTimer;
  bool _streamDone = false;

  final List<String?> _filledBlank = [];
  int _blankCount = 0;
  int _currentBlank = 0;
  bool _failed = false;
  bool _completed = false;
  int? _wrongTileIndex;
  int? _expectedTileIndex;

  List<String> get _sentence => widget.data.sentence;
  List<String> get _answers => widget.data.answers;

  @override
  void initState() {
    super.initState();
    _blankCount = _sentence.where(_isBlank).length;
    for (var i = 0; i < _blankCount; i++) {
      _filledBlank.add(null);
    }
    final tiles = [..._answers, ...widget.data.distractors]..shuffle(Random());
    _shuffledTiles = tiles;
    _startStream();
  }

  void _startStream() {
    _streamTimer?.cancel();
    if (_streamIndex >= _sentence.length) {
      setState(() => _streamDone = true);
      return;
    }
    setState(() {});
    _streamTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _streamIndex++;
        if (_streamIndex >= _sentence.length) {
          _streamDone = true;
        }
      });
      if (_streamIndex < _sentence.length) {
        _startStream();
      }
    });
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }

  String _buildFullSentenceDisplay() {
    final parts = <String>[];
    var blankI = 0;
    for (var i = 0; i < _sentence.length; i++) {
      final t = _sentence[i];
      if (_isBlank(t)) {
        if (_filledBlank[blankI] != null) {
          parts.add(_filledBlank[blankI]!);
        } else {
          parts.add('_____ (${blankI + 1})');
        }
        blankI++;
      } else {
        parts.add(t);
      }
    }
    return parts.join(' ');
  }

  String _buildStreamingLine() {
    if (_streamDone) {
      return _buildFullSentenceDisplay();
    }
    final parts = <String>[];
    var blankI = 0;
    for (var i = 0; i < _streamIndex && i < _sentence.length; i++) {
      final t = _sentence[i];
      if (_isBlank(t)) {
        if (_filledBlank[blankI] != null) {
          parts.add(_filledBlank[blankI]!);
        } else {
          parts.add('_____ (${blankI + 1})');
        }
        blankI++;
      } else {
        parts.add(t);
      }
    }
    if (_streamIndex < _sentence.length) {
      parts.add('…');
    }
    return parts.join(' ');
  }

  String _buildFullCorrectLine() {
    final buf = StringBuffer();
    var blankI = 0;
    for (var i = 0; i < _sentence.length; i++) {
      if (i > 0) buf.write(' ');
      final t = _sentence[i];
      if (_isBlank(t)) {
        buf.write(_answers[blankI]);
        blankI++;
      } else {
        buf.write(t);
      }
    }
    return buf.toString().trim();
  }

  void _onTileTap(int tileIndex) {
    if (!_streamDone || _failed || _completed) return;
    final word = _shuffledTiles[tileIndex];
    final expected = _answers[_currentBlank];
    if (word != expected) {
      var expIdx = -1;
      for (var g = 0; g < _shuffledTiles.length; g++) {
        if (_shuffledTiles[g] == expected) {
          expIdx = g;
          break;
        }
      }
      setState(() {
        _failed = true;
        _wrongTileIndex = tileIndex;
        _expectedTileIndex = expIdx >= 0 ? expIdx : null;
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
      return;
    }

    setState(() {
      _filledBlank[_currentBlank] = word;
      _currentBlank++;
    });
    if (_currentBlank >= _answers.length) {
      _completed = true;
      widget.onPlayCorrect();
      widget.onOutcome(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final oneBlank = _answers.length == 1;
    final cross = oneBlank ? 2 : 3;

    final lineText =
        _failed ? _buildFullCorrectLine() : _buildStreamingLine();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            lineText,
            style: theme.textTheme.titleMedium?.copyWith(
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.4,
            ),
            itemCount: _shuffledTiles.length,
            itemBuilder: (context, i) {
              final w = _shuffledTiles[i];
              final disabled = !_streamDone || _failed || _completed;
              final wrong = _failed && _wrongTileIndex == i;
              final expect = _failed && _expectedTileIndex == i;
              Color bg = cs.surfaceContainerHighest;
              if (wrong) bg = Colors.red.shade200;
              if (expect) bg = Colors.green.shade200;

              return Material(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: disabled ? null : () => _onTileTap(i),
                  borderRadius: BorderRadius.circular(10),
                  child: Center(
                    child: Text(
                      w,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
