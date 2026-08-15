import 'package:flutter/material.dart';

import 'answer_palette.dart';

enum McqAnswerState {
  neutral,
  correct,
  wrong,

  /// Correct answer shown as a penalty reveal (e.g. translation-reveal), not because the learner
  /// picked it — distinct blue tint so it doesn't read as a normal correct pick.
  revealed,
}

/// Full-width rounded-rectangle MCQ answer button shared by every four-choice answer panel
/// (video and image variants). Sizes to its own content — a minimum touch-target height, up to
/// 2 lines of text — rather than a height computed by dividing available space by the option
/// count: that division assumes 1-line English text, which breaks for a longer translation that
/// wraps or a larger system font-scale (accessibility text size) setting. `label` is never
/// truncated with `TextOverflow.ellipsis` alone: for a quiz answer the exact wording is the
/// content, not decoration, so 2 lines is the primary allowance and ellipsis only a last-resort
/// safeguard if even that overflows.
class McqPillAnswerButton extends StatelessWidget {
  const McqPillAnswerButton({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final McqAnswerState state;
  final VoidCallback? onTap;

  // Deliberately above Material's bare 48pt minimum touch target — a chunkier button reads as
  // "filled in" rather than sparse, and paired with centering (not spaceEvenly) the parent
  // Column, less leftover space needs absorbing as gaps between buttons in the first place.
  static const _minHeight = 52.0;
  static const _maxHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    var bg = AnswerPalette.neutralBg;
    var border = AnswerPalette.neutralBorder;
    var fg = AnswerPalette.neutralFg;
    if (state == McqAnswerState.correct) {
      bg = AnswerPalette.correctBg;
      border = AnswerPalette.correctBorder;
      fg = AnswerPalette.correctFg;
    } else if (state == McqAnswerState.wrong) {
      bg = AnswerPalette.wrongBg;
      border = AnswerPalette.wrongBorder;
      fg = AnswerPalette.wrongFg;
    } else if (state == McqAnswerState.revealed) {
      bg = AnswerPalette.revealedBg;
      border = AnswerPalette.revealedBorder;
      fg = AnswerPalette.revealedFg;
    }
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _minHeight,
          maxHeight: _maxHeight,
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            side: BorderSide(color: border),
            disabledBackgroundColor: bg,
            disabledForegroundColor: fg,
            minimumSize: const Size(48, _minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          child: state == McqAnswerState.wrong
              ? SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: AnswerPalette.wrongBorder,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    );
  }
}
