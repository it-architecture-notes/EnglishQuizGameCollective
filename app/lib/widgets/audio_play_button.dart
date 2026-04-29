import 'package:flutter/material.dart';

/// Speaker control for level TTS clips.
///
/// Visual states:
/// - [isPlaying] true → equalizer icon, full color, not pressable (never greys out mid-playback).
/// - [onPressed] null, not playing → volume icon, greyed (audio unavailable / state not ready).
/// - [onPressed] non-null, not playing → volume icon, full color, pressable.
///
/// Callers are responsible for hiding the widget entirely (return SizedBox.shrink) when audio
/// is not configured for the question at all.
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
    final cs = Theme.of(context).colorScheme;
    final available = isPlaying || onPressed != null;
    return IconButton(
      onPressed: isPlaying ? null : onPressed,
      icon: Icon(
        isPlaying ? Icons.graphic_eq : Icons.volume_up,
        color: available ? cs.primary : cs.onSurface.withValues(alpha: 0.38),
      ),
      tooltip: 'Play audio',
    );
  }
}
