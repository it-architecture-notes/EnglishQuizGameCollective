import 'package:flutter/material.dart';

/// Shared answer-surface palette (design spec) — used by every DialogueCompletion-shaped MCQ
/// panel (video and image) and the SentenceBuilder/AppearDisappear/ClozeSequence tile grid, so
/// every answer type reads as one visual family instead of each template inventing its own
/// colors.
class AnswerPalette {
  const AnswerPalette._();

  static const neutralBg = Color(0xFFF1F3F5);
  static const neutralBorder = Color(0xFFDDE1E6);
  static const neutralFg = Color(0xFF30343B);

  static const wrongBg = Color(0xFFFDEBEC);
  static const wrongBorder = Color(0xFFE5484D);
  static const wrongFg = Color(0xFFB4232A);

  static const correctBg = Color(0xFFE5F5ED);
  static const correctBorder = Color(0xFF25845B);
  static const correctFg = Color(0xFF176B48);

  /// Not part of the video-answer design spec — used only where a template needs to distinguish
  /// "the correct answer, revealed as a penalty" (e.g. translation-reveal) from "the correct
  /// answer, actually picked." Same tinted-pill visual language as the other three states.
  static const revealedBg = Color(0xFFE8F0FE);
  static const revealedBorder = Color(0xFF3B72E0);
  static const revealedFg = Color(0xFF1D4FA6);
}
