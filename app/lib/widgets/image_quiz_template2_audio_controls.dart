import 'dart:async';

import 'package:flutter/material.dart';

import '../services/audio_service.dart' as audio;

/// Auto-plays level audio once after [autoPlayDelay] when [assetPath] exists; optional replay.
class ImageQuizTemplate2AudioControls extends StatefulWidget {
  const ImageQuizTemplate2AudioControls({
    super.key,
    required this.assetPath,
    required this.resolveExists,
    this.autoPlayDelay = const Duration(seconds: 1),
  });

  /// e.g. `quiz-data/levels/greetings/foo.m4a`
  final String? assetPath;
  final Future<bool> Function(String path) resolveExists;
  final Duration autoPlayDelay;

  @override
  State<ImageQuizTemplate2AudioControls> createState() =>
      _ImageQuizTemplate2AudioControlsState();
}

class _ImageQuizTemplate2AudioControlsState
    extends State<ImageQuizTemplate2AudioControls> {
  bool? _exists;
  bool _playing = false;
  Timer? _autoTimer;
  bool _autoFired = false;

  @override
  void initState() {
    super.initState();
    _prime();
  }

  @override
  void didUpdateWidget(covariant ImageQuizTemplate2AudioControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _autoTimer?.cancel();
      _autoFired = false;
      _playing = false;
      _exists = null;
      _prime();
    }
  }

  Future<void> _prime() async {
    final p = widget.assetPath;
    if (p == null) {
      if (mounted) setState(() => _exists = false);
      return;
    }
    final ok = await widget.resolveExists(p);
    if (!mounted) return;
    setState(() => _exists = ok);
    if (!ok) return;
    _autoTimer = Timer(widget.autoPlayDelay, _autoPlayOnce);
  }

  Future<void> _autoPlayOnce() async {
    if (!mounted || _autoFired) return;
    final p = widget.assetPath;
    if (p == null || _exists != true) return;
    _autoFired = true;
    await _play(p);
  }

  Future<void> _play(String p) async {
    if (_playing) return;
    setState(() => _playing = true);
    try {
      await audio.playQuestionAudio(p);
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.assetPath;
    if (p == null || _exists != true) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _playing ? null : () => _play(p),
          icon: Icon(
            _playing ? Icons.graphic_eq : Icons.volume_up,
            color: _playing ? cs.onSurface.withValues(alpha: 0.4) : cs.primary,
          ),
          tooltip: 'Play audio',
        ),
      ],
    );
  }
}
