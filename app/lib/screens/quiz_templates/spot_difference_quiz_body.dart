import 'dart:math';

import 'package:flutter/material.dart';

/// Two images side by side; randomises which side shows the correct asset.
class SpotDifferenceQuizBody extends StatefulWidget {
  const SpotDifferenceQuizBody({
    super.key,
    required this.sentenceLine,
    required this.correctPath,
    required this.wrongPath,
    required this.onPlayCorrect,
    required this.onPlayWrong,
    required this.onOutcome,
  });

  final String sentenceLine;
  final String correctPath;
  final String wrongPath;
  final VoidCallback onPlayCorrect;
  final VoidCallback onPlayWrong;
  final void Function(bool correct) onOutcome;

  @override
  State<SpotDifferenceQuizBody> createState() =>
      _SpotDifferenceQuizBodyState();
}

class _SpotDifferenceQuizBodyState extends State<SpotDifferenceQuizBody> {
  late List<bool> _correctOnLeft;
  bool _locked = false;
  int? _wrongSide;

  @override
  void initState() {
    super.initState();
    final swap = Random().nextBool();
    _correctOnLeft = swap ? [false, true] : [true, false];
  }

  void _onTap(int sideIndex) {
    if (_locked) return;
    final correctHere = _correctOnLeft[sideIndex];
    setState(() {
      _locked = true;
      if (!correctHere) _wrongSide = sideIndex;
    });
    if (correctHere) {
      widget.onPlayCorrect();
      widget.onOutcome(true);
    } else {
      widget.onPlayWrong();
      widget.onOutcome(false);
    }
  }

  String _pathAt(int sideIndex) =>
      _correctOnLeft[sideIndex] ? widget.correctPath : widget.wrongPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            widget.sentenceLine,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(2, (sideIndex) {
              final wrongHere = _locked && _wrongSide == sideIndex;
              final correctHere =
                  _locked && _correctOnLeft[sideIndex]; // always show both greens? spec: wrong red, other green
              final showGreen = _locked && _correctOnLeft[sideIndex];
              final borderColor = ! _locked
                  ? null
                  : wrongHere
                      ? Colors.red
                      : showGreen
                          ? Colors.green
                          : Colors.green.shade300;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: sideIndex == 0 ? 0 : 6,
                    right: sideIndex == 1 ? 0 : 6,
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    color: wrongHere
                        ? Colors.red.shade50
                        : correctHere && _locked
                            ? Colors.green.shade50
                            : null,
                    child: InkWell(
                      onTap: _locked ? null : () => _onTap(sideIndex),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: borderColor != null
                              ? Border.all(color: borderColor, width: 3)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          _pathAt(sideIndex),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child:
                                const Icon(Icons.image_not_supported, size: 48),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
