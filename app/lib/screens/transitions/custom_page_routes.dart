import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Scale + Elastic: page scales up with an elastic (overshoot) curve.
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

/// Flip + Scale: page flips on Y axis while scaling up.
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

/// Pop + Fade: scale and fade in (pop-style entrance).
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

/// Slide up + Fade: page slides from bottom to top while fading in.
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

/// Card Flip: page rotates in like a card (full 3D flip on Y axis).
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
