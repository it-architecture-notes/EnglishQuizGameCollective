import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Page transition used where a bouncy scale-in fits the UX better than a plain fade.
/// Called when navigating to a screen that should feel like it “pops” into place with overshoot.
Route<T> scaleElasticRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 600),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = Curves.elasticOut;
      final scale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: curve),
      );
      return ScaleTransition(
        scale: scale,
        child: child,
      );
    },
  );
}

/// 3D Y-flip plus scale for a card-flip style entrance between major screens.
/// Used when a route wants a more dramatic transition than fade or slide alone.
Route<T> flipScaleRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 500),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeInOut;
      final scale = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: curve),
      );
      final rotate = Tween<double>(begin: -0.5 * math.pi, end: 0.0).animate(
        CurvedAnimation(parent: animation, curve: curve),
      );
      return AnimatedBuilder(
        animation: animation,
        builder: (_, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotate.value)
              ..scale(scale.value),
            child: child,
          );
        },
        child: child,
      );
    },
  );
}

/// Default “soft” push: simultaneous fade and slight scale-up from the home and level map flows.
/// Used heavily for [LevelsScreen], [QuizRunnerScreen], and [ImageQuizScreen] so navigation feels consistent.
Route<T> popFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOut;
      final scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: curve),
      );
      final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: curve),
      );
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      );
    },
  );
}

/// Bottom sheet–like entrance: slide from below with fade for overlays or secondary flows.
/// Chosen when the next screen should read as rising into view rather than replacing center stage.
Route<T> slideUpFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOut;
      final offset = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: curve));
      final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: curve),
      );
      return SlideTransition(
        position: offset,
        child: FadeTransition(
          opacity: fade,
          child: child,
        ),
      );
    },
  );
}

/// Full pi/2 Y rotation without the initial scale tweak of [flipScaleRoute], for a strict card flip.
/// Available for routes that want a hinge-like transition between two full pages.
Route<T> cardFlipRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 550),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final rotate = Tween<double>(begin: -math.pi / 2, end: 0.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      );
      return AnimatedBuilder(
        animation: animation,
        builder: (_, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotate.value),
            child: child,
          );
        },
        child: child,
      );
    },
  );
}
