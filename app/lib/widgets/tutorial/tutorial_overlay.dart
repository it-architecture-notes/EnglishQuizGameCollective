import 'package:flutter/material.dart';

import 'tutorial_controller.dart';

/// Renders the currently-active tutorial step (if any) as a full-screen scrim with a character
/// portrait, message card, and an OK button that dismisses it ([TutorialController.confirmActive])
/// — a blocking modal, not a non-blocking pointer at a live target.
///
/// Variety-pack guides (`assets/images/characters/guide-1.png` .. `guide-5.png`), one per
/// tutorial step per the level's `tutorial.steps` config — each is a real cutout (transparent
/// background), pre-cropped tight to its subject and normalized to the same source height, so
/// sizing every portrait here to the same [characterHeight] makes them read as the same visual
/// scale on screen regardless of pose (some are tighter head-and-shoulders, some have an
/// outstretched arm). No left/right mirroring: always bottom-left.
class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    super.key,
    required this.controller,
    required this.strings,
  });

  final TutorialController controller;
  final Map<String, String> strings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final messageKey = controller.activeMessageKey;
        final characterAsset = controller.activeCharacterAsset;
        if (messageKey == null) return const SizedBox.shrink();
        final text = strings[messageKey] ?? '';
        if (text.isEmpty) return const SizedBox.shrink();
        final screenWidth = MediaQuery.sizeOf(context).width;
        final screenHeight = MediaQuery.sizeOf(context).height;
        final characterHeight = screenHeight * 0.19;
        // Fixed regardless of which guide is active — some crops (an outstretched pointing arm)
        // are noticeably wider than a plain head-and-shoulders bust at the same height, so the
        // bubble's left edge can't be derived from character width without measuring the asset
        // first. A generous fixed inset comfortably clears the widest crop on a typical phone.
        const bubbleLeftInset = 0.42;

        final character = characterAsset == null
            ? Icon(Icons.face,
                size: characterHeight * 0.7, color: Colors.amber.shade300)
            : Image.asset(
                characterAsset,
                height: characterHeight,
                fit: BoxFit.fitHeight,
                alignment: Alignment.bottomLeft,
              );

        final bubble = Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  textAlign: TextAlign.left,
                  textScaler: MediaQuery.textScalerOf(context).clamp(
                    minScaleFactor: 1.0,
                    maxScaleFactor: 1.35,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF171A1F),
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: controller.confirmActive,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      minimumSize: const Size(0, 40),
                    ),
                    child: Text(strings['ok'] ?? 'OK'),
                  ),
                ),
              ],
            ),
          ),
        );

        return Material(
          color: Colors.black.withValues(alpha: 0.28),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  left: screenWidth * bubbleLeftInset,
                  right: 12,
                  bottom: 14,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      bubble,
                      Positioned(
                        bottom: 24,
                        left: -10,
                        child: Transform.rotate(
                          angle: -0.55,
                          child: Container(
                            width: 22,
                            height: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: character,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
