import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';

/// Returns true when [token] is a blank marker (2+ underscores, nothing else).
bool _isBlank(String token) => RegExp(r'^_{2,}$').hasMatch(token);

/// Cloze-sequence quiz: streams (or shows at once) a localized sentence with
/// numbered blank markers, then lets the player fill the blanks in order by
/// tapping tiles laid out horizontally like a train.
///
/// Also used by the ConvoTemplate-2 adapter (wordsAllTogether = true, single blank).
class ClozeSequenceQuizBody extends StatefulWidget {
  const ClozeSequenceQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    this.resolvedImagePath,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
    this.onReadyForAudio,
  });

  final ClozeSequenceQuestionData data;
  /// Active locale code (e.g. 'en', 'tr', 'es'). Used for the translation hint.
  final String userLanguage;
  /// Pre-resolved asset path for [data.imageName], or null if no image.
  final String? resolvedImagePath;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;
  final VoidCallback? onReadyForAudio;

  @override
  State<ClozeSequenceQuizBody> createState() => _ClozeSequenceQuizBodyState();
}

enum _TileState { normal, correct, wrong, expected }

class _ClozeSequenceQuizBodyState extends State<ClozeSequenceQuizBody> {
  late List<String> _tokens;       // sentence['en'].split(' ')
  late List<int> _blankIndices;    // positions of blank tokens in _tokens
  late List<String> _tiles;        // shuffled [answers + distractors]
  late List<String?> _filled;      // player-filled value per blank slot (null = unfilled)
  late List<_TileState> _tileStates;

  int _streamIndex = 0;            // how many tokens have been revealed
  Timer? _streamTimer;
  bool _streamDone = false;
  bool _audioReadyNotified = false;

  int _currentBlank = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _tokens = (widget.data.sentence['en'] ?? '').split(' ');
    _blankIndices =
        [for (var i = 0; i < _tokens.length; i++) if (_isBlank(_tokens[i])) i];
    _filled = List.filled(_blankIndices.length, null);
    _tiles = [...widget.data.answers, ...widget.data.distractors]
      ..shuffle(Random());
    _tileStates = List.filled(_tiles.length, _TileState.normal);

    if (widget.data.wordsAllTogether) {
      _streamIndex = _tokens.length;
      _streamDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyReadyForAudio();
      });
    } else {
      _scheduleNextToken();
    }
  }

  void _notifyReadyForAudio() {
    if (_audioReadyNotified) return;
    _audioReadyNotified = true;
    widget.onReadyForAudio?.call();
  }

  void _scheduleNextToken() {
    _streamTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _streamIndex++;
        if (_streamIndex >= _tokens.length) {
          _streamDone = true;
          _notifyReadyForAudio();
        }
      });
      if (!_streamDone) _scheduleNextToken();
    });
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }

  // ── Interaction ────────────────────────────────────────────────────────────

  void _onTileTap(int tileIndex) {
    if (!_streamDone || _failed) return;
    final word = _tiles[tileIndex];
    final expected = widget.data.answers[_currentBlank];

    if (word == expected) {
      setState(() {
        _tileStates[tileIndex] = _TileState.correct;
        _filled[_currentBlank] = word;
        _currentBlank++;
      });
      widget.onPlayCorrect();
      if (_currentBlank >= widget.data.answers.length) {
        widget.onOutcome(true);
      }
    } else {
      // Find first tile that holds the correct answer
      final expIdx = _tiles.indexOf(expected);
      setState(() {
        _failed = true;
        _tileStates[tileIndex] = _TileState.wrong;
        if (expIdx >= 0) _tileStates[expIdx] = _TileState.expected;
      });
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  // ── Sentence rendering ─────────────────────────────────────────────────────

  List<InlineSpan> _buildSentenceSpans(ThemeData theme) {
    final cs = theme.colorScheme;
    final spans = <InlineSpan>[];
    var blankI = 0;
    final limit = _streamDone ? _tokens.length : _streamIndex;

    for (var i = 0; i < limit; i++) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' '));
      final t = _tokens[i];
      if (_isBlank(t)) {
        final filled = _filled[blankI];
        if (filled != null) {
          // Player filled correctly — green bold
          spans.add(TextSpan(
            text: filled,
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w700,
            ),
          ));
        } else if (_failed) {
          // Failure state — show correct answer; orange if not yet reached, green if already filled
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
          // Unfilled blank placeholder
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

    if (!_streamDone) {
      spans.add(const TextSpan(text: ' …'));
    }

    // Translation hint — appended at end, shown only when not English
    if (_streamDone && widget.userLanguage != 'en') {
      final hint = widget.data.sentence[widget.userLanguage];
      if (hint != null && hint.isNotEmpty) {
        spans.add(TextSpan(
          text: ' ($hint)',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ));
      }
    }

    return spans;
  }

  // ── Tile rendering ─────────────────────────────────────────────────────────

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
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
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
        if (isCorrect)
          Positioned(
            top: -6,
            right: -6,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: Colors.green.shade700,
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Optional thumbnail image
        if (widget.resolvedImagePath != null) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                widget.resolvedImagePath!,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(width: 72, height: 72),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Sentence with blanks
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

        const SizedBox(height: 16),

        // Tile train (horizontal wrap)
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
