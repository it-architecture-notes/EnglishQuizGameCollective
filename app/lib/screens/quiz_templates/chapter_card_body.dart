import 'dart:async';

import 'package:flutter/material.dart';

/// Passive, non-quiz interstitial for template [Chapter] — a "movie chapter card": an image and a
/// Continue button, nothing to answer. Used e.g. to mark the start of a video segment or the
/// switch from a video story into standalone practice questions. Deliberately has no header/score
/// chrome of its own; the parent screen renders it full-content and bypasses the normal
/// "Question N/M" header for this row.
///
/// Auto-advances after [autoAdvanceAfter] (like a movie chapter card lingering briefly before the
/// film continues), but the Continue button lets the player skip ahead immediately if they don't
/// want to wait.
class ChapterCardBody extends StatefulWidget {
  const ChapterCardBody({
    super.key,
    required this.imagePathFuture,
    required this.onContinue,
    required this.continueLabel,
    this.autoAdvanceAfter = const Duration(seconds: 3),
  });

  final Future<String?> imagePathFuture;
  final VoidCallback onContinue;
  final String continueLabel;
  final Duration autoAdvanceAfter;

  @override
  State<ChapterCardBody> createState() => _ChapterCardBodyState();
}

class _ChapterCardBodyState extends State<ChapterCardBody> {
  Timer? _autoAdvanceTimer;
  bool _continued = false;

  @override
  void initState() {
    super.initState();
    _autoAdvanceTimer = Timer(widget.autoAdvanceAfter, _continue);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _continue() {
    if (_continued) return;
    _continued = true;
    _autoAdvanceTimer?.cancel();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: FutureBuilder<String?>(
              future: widget.imagePathFuture,
              builder: (context, snapshot) {
                final path = snapshot.data;
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator();
                }
                if (path == null) return const SizedBox.shrink();
                return Image.asset(
                  path,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _continue,
              child: Text(widget.continueLabel),
            ),
          ),
        ),
      ],
    );
  }
}
