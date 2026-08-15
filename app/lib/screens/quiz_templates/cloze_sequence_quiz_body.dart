import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../utils/cloze_blank.dart';
import '../../widgets/answer_palette.dart';
import '../../widgets/audio_play_button.dart';
import '../../widgets/mcq_pill_answer_button.dart';

/// Cloze-sequence quiz: shows the sentence with blank(s) as soon as the question appears.
/// **Multiple blanks:** fill in order by tapping word tiles in a horizontal wrap. **Single
/// blank:** [McqPillAnswerButton] choices, same as [DialogueCompletionQuizBody]. Visually mirrors
/// `VideoConversationQuizBody`'s `ClozeSequence` answer_type and `DialogueCompletionQuizBody`: an
/// image capped at 45% of the available height, a white answer panel pulled up over its bottom
/// edge, the sentence as the prompt (no separate instructional CTA — same as the video version),
/// then either pill buttons or a tile grid. The only structural difference from
/// `DialogueCompletionQuizBody` is a static [imagePath] instead of `line1`, and tiles instead of
/// buttons when there's more than one blank.
class ClozeSequenceQuizBody extends StatefulWidget {
  const ClozeSequenceQuizBody({
    super.key,
    required this.data,
    required this.userLanguage,
    this.imagePath,
    this.audioAssetPath,
    required this.resolveAudioExists,
    required this.onPlayQuestionAudio,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
    this.onNextChoiceRendered,
  });

  final ClozeSequenceQuestionData data;
  final String userLanguage;

  /// Resolved asset path for [ClozeSequenceQuestionData.imageName], or null if the question has
  /// no image (the image block is skipped entirely, not shown as a broken placeholder).
  final String? imagePath;
  final String? audioAssetPath;
  final Future<bool> Function(String path) resolveAudioExists;
  final Future<void> Function(String path) onPlayQuestionAudio;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;
  final void Function(int expectedIndex, List<GlobalKey> choiceKeys)? onNextChoiceRendered;

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

  /// Single-blank mode: MCQ buttons (see [DialogueCompletionQuizBody]).
  late List<String> _buttonOptions;
  late int _buttonCorrectIndex;
  bool _buttonLocked = false;
  int? _buttonSelectedIndex;

  int _currentBlank = 0;
  bool _failed = false;
  bool _translationPenalized = false;
  bool _audioPlaying = false;
  Map<int, int> _expectedTileBlankIndex = {};
  late final List<GlobalKey> _choiceKeys;

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
      _choiceKeys = List.generate(_buttonOptions.length, (_) => GlobalKey());
      _tiles = [];
      _tileStates = [];
    } else {
      _tiles = [...widget.data.answers, ...widget.data.distractors]
        ..shuffle(Random());
      _tileStates = List.filled(_tiles.length, _TileState.normal);
      _buttonOptions = [];
      _buttonCorrectIndex = 0;
      _choiceKeys = List.generate(_tiles.length, (_) => GlobalKey());
    }
    _reportNextChoice();
  }

  void _reportNextChoice() {
    if (_singleBlank && _buttonLocked) return;
    if (!_singleBlank && (_failed || _currentBlank >= widget.data.answers.length)) return;
    final expected = _singleBlank
        ? _buttonCorrectIndex
        : _tiles.indexOf(widget.data.answers[_currentBlank]);
    if (expected < 0 || expected >= _choiceKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onNextChoiceRendered?.call(expected, _choiceKeys);
    });
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
      _filled[0] = widget.data.answers.first;
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
      _filled[0] = widget.data.answers.first;
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
      _reportNextChoice();
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

  /// Mirrors `VideoConversationQuizBody._buildClozeSentenceSpans`: revealed correct answers
  /// always render in the same correct-green (italic when revealed-not-by-the-learner rather
  /// than a separate color), instead of the old green-vs-orange distinction.
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
          final userFilled = blankI < _currentBlank;
          blankText = filled;
          blankStyle = TextStyle(
            color: _translationPenalized
                ? AnswerPalette.revealedFg
                : AnswerPalette.correctFg,
            fontWeight: FontWeight.w700,
            fontStyle: userFilled ? null : FontStyle.italic,
          );
        } else {
          blankText = _singleBlank ? '_____' : '_____ (${blankI + 1})';
          blankStyle = TextStyle(color: cs.primary, fontStyle: FontStyle.italic);
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

  /// Mirrors `VideoConversationQuizBody._buildTilePanel`'s word-tile styling: stadium pill,
  /// shared [AnswerPalette], leading "x" on a wrong tap, step badge on a correct/expected tile.
  Widget _buildTile(int index, ThemeData theme) {
    final word = _tiles[index];
    final state = _tileStates[index];
    final isCorrect = state == _TileState.correct;
    final isWrong = state == _TileState.wrong;
    final isExpected = state == _TileState.expected;

    var bg = AnswerPalette.neutralBg;
    var border = AnswerPalette.neutralBorder;
    var fg = AnswerPalette.neutralFg;
    if (isWrong) {
      bg = AnswerPalette.wrongBg;
      border = AnswerPalette.wrongBorder;
      fg = AnswerPalette.wrongFg;
    } else if (isCorrect || isExpected) {
      final revealed = isExpected || _translationPenalized;
      bg = revealed ? AnswerPalette.revealedBg : AnswerPalette.correctBg;
      border = revealed ? AnswerPalette.revealedBorder : AnswerPalette.correctBorder;
      fg = revealed ? AnswerPalette.revealedFg : AnswerPalette.correctFg;
    }

    final disabled = _failed || isCorrect;
    final step = isCorrect
        ? _tileStates.take(index + 1).where((s) => s == _TileState.correct).length
        : (_expectedTileBlankIndex[index] ?? -1) + 1;

    return Material(
      key: _choiceKeys[index],
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border)),
      child: InkWell(
        onTap: disabled ? null : () => _onTileTap(index),
        customBorder: StadiumBorder(side: BorderSide(color: border)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isWrong) ...[
                      Icon(Icons.close, size: 14, color: border),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      word,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
              if ((isCorrect || isExpected) && step > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: border,
                    child: Text(
                      '$step',
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answerWidth = min(MediaQuery.sizeOf(context).width * 0.87, 560.0);
    final hasImage = widget.imagePath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage)
          LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight * 0.45
                  : constraints.maxWidth;
              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight,
                      maxWidth: constraints.maxWidth,
                    ),
                    child: Image.asset(
                      widget.imagePath!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        padding: const EdgeInsets.all(24),
                        child: const Icon(Icons.image_not_supported, size: 48),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        // Pulled up over the bottom edge of the image (negative translate, not a layout gap),
        // matching VideoConversationQuizBody's / DialogueCompletionQuizBody's overlap.
        Transform.translate(
          offset: Offset(0, hasImage ? -18 : 0),
          child: Center(
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: hasImage
                      ? const BorderRadius.vertical(top: Radius.circular(24))
                      : null,
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Center(
                  child: SizedBox(
                    width: answerWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF171A1F),
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                            children: _buildSentenceSpans(theme),
                          ),
                        ),
                        if (widget.audioAssetPath != null)
                          FutureBuilder<bool>(
                            future: widget.resolveAudioExists(widget.audioAssetPath!),
                            builder: (context, snap) {
                              if (snap.connectionState != ConnectionState.done ||
                                  snap.data != true) {
                                return const SizedBox.shrink();
                              }
                              return Align(
                                alignment: Alignment.centerRight,
                                child: AudioPlayButton(
                                  isPlaying: _audioPlaying,
                                  onPressed: !_concluded ? null : () => _playAudio(),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            // LayoutBuilder must wrap SingleChildScrollView, not sit inside it — see
            // VideoConversationQuizBody for why (a LayoutBuilder inside a scroll view reads an
            // unbounded/infinite maxHeight, which fed into ConstrainedBox(minHeight: ...) would
            // force infinite height instead of "fill the real available space").
            child: LayoutBuilder(
              builder: (context, answerConstraints) {
                if (_singleBlank) {
                  return SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: answerWidth,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: answerConstraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_buttonOptions.length, (i) {
                                final opt = _buttonOptions[i];
                                final isSel = _buttonSelectedIndex == i;
                                final isCor = _buttonLocked && i == _buttonCorrectIndex;
                                final isWrongPick = _buttonLocked && isSel && !isCor;
                                final state = isCor
                                    ? (_translationPenalized
                                        ? McqAnswerState.revealed
                                        : McqAnswerState.correct)
                                    : isWrongPick
                                        ? McqAnswerState.wrong
                                        : McqAnswerState.neutral;
                                return Padding(
                                  key: _choiceKeys[i],
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: McqPillAnswerButton(
                                    label: opt,
                                    state: state,
                                    onTap: _buttonLocked
                                        ? null
                                        : () => _onSingleButtonTap(i),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: answerConstraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            _tiles.length,
                            (i) => _buildTile(i, theme),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
