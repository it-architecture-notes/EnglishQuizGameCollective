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
    this.fontSize,
    this.minHeight,
    this.maxHeight,
    this.width,
  });

  final String label;
  final McqAnswerState state;
  final VoidCallback? onTap;

  /// Optional per-call overrides used by templates that run their own content-driven
  /// shrink/grow logic (e.g. `DialogueCompletionQuizBody`). Defaulting to the static values
  /// below keeps every other caller's rendering byte-identical.
  final double? fontSize;
  final double? minHeight;
  final double? maxHeight;
  final double? width;

  // Deliberately above Material's bare 48pt minimum touch target — a chunkier button reads as
  // "filled in" rather than sparse, and paired with centering (not spaceEvenly) the parent
  // Column, less leftover space needs absorbing as gaps between buttons in the first place.
  static const _minHeight = 52.0;
  static const _maxHeight = 72.0;
  static const _cornerRadius = 16.0;
  static const wrongStateIconSize = 26.0;
  static const wrongStateIconGap = 6.0;

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
    final effectiveMinHeight = minHeight ?? _minHeight;
    final effectiveMaxHeight = maxHeight ?? _maxHeight;
    final effectiveFontSize = fontSize ?? 18.0;
    return SizedBox(
      width: width ?? double.infinity,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: effectiveMinHeight,
          maxHeight: effectiveMaxHeight,
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            side: BorderSide(color: border),
            disabledBackgroundColor: bg,
            disabledForegroundColor: fg,
            minimumSize: Size(48, effectiveMinHeight),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_cornerRadius),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            textStyle: TextStyle(
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: state == McqAnswerState.wrong
              ? Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: wrongStateIconSize,
                      height: wrongStateIconSize,
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
                    const SizedBox(width: wrongStateIconGap),
                    // Centers within the space left after the icon+gap, rather than the full
                    // button width, so the icon can never overlap the label — the previous
                    // Stack(alignment: center) + Align(centerLeft) overlay assumed generous
                    // leftover space around short centered text, which held for full-width
                    // buttons but breaks once a button is sized tightly to its own text (the
                    // shared-width-from-widest-option rule in DialogueCompletionQuizBody has
                    // zero such slack by construction).
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
