import 'package:flutter/material.dart';

import 'app_flavor.dart';

class AppTheme {
  static ThemeData forFlavor(AppFlavor flavor) {
    const primary = Color(0xFF0F8F83);
    const background = Color(0xFFF4F6F8);
    const text = Color(0xFF171A1F);
    const secondaryText = Color(0xFF5F6670);
    const answerBackground = Color(0xFFF1F3F5);
    const answerBorder = Color(0xFFDDE1E6);
    return ThemeData(
      // Set once here, not per-widget: every TextStyle built from `theme.textTheme` — and every
      // literal `TextStyle(fontSize: ...)` that leaves `fontFamily` null — inherits this via the
      // ambient `DefaultTextStyle`, so this one line covers every screen without touching each
      // template's own font-size overrides individually.
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        surface: background,
        onSurface: text,
        onSurfaceVariant: secondaryText,
        error: Color(0xFFE5484D),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      // Sized to match the target design's scale (large bold headline, roomy body/button text) —
      // anything that reads a size from here rather than hard-coding its own picks this up
      // automatically; templates with their own literal `fontSize` overrides (the prompt/button
      // text built during the video-question redesign) were bumped to match alongside this.
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: text, fontSize: 18),
        bodyMedium: TextStyle(color: text, fontSize: 16),
        titleLarge: TextStyle(color: text, fontSize: 30, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(color: text, fontSize: 26, fontWeight: FontWeight.w700),
        labelLarge: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: answerBackground,
          foregroundColor: Color(0xFF30343B),
          side: const BorderSide(color: answerBorder),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      useMaterial3: true,
    );
  }
}
