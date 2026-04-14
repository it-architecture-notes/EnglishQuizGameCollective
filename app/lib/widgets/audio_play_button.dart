import 'package:flutter/material.dart';

/// Speaker control for level TTS clips. Hidden when [onPressed] is null.
class AudioPlayButton extends StatelessWidget {
  const AudioPlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
  });

  final bool isPlaying;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: isPlaying ? null : onPressed,
      icon: Icon(
        isPlaying ? Icons.graphic_eq : Icons.volume_up,
        color: isPlaying ? cs.onSurface.withValues(alpha: 0.4) : cs.primary,
      ),
      tooltip: 'Play audio',
    );
  }
}
