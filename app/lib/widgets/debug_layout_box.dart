import 'package:flutter/material.dart';

/// Wraps [child] with a visible outline and a small corner label — used only to visually audit
/// layout-box boundaries and percentages while tuning responsive sizing. Callers gate [enabled]
/// on whatever condition scopes this to a dev/test context (e.g. a specific level's
/// `directoryName`); when [enabled] is false this returns [child] unchanged, with zero cost.
class DebugLayoutBox extends StatelessWidget {
  const DebugLayoutBox({
    super.key,
    required this.enabled,
    required this.child,
    this.label,
    this.color = const Color(0xFFE53935),
  });

  final bool enabled;
  final Widget child;
  final String? label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: color, width: 1.5)),
          child: child,
        ),
        if (label != null)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              color: color,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              child: Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
