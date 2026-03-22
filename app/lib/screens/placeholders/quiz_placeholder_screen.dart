import 'package:flutter/material.dart';

import '../../models/quiz_flow.dart';

class QuizPlaceholderScreen extends StatelessWidget {
  const QuizPlaceholderScreen({
    super.key,
    required this.quizType,
    required this.subLevel,
    this.ordinalLevelIndex,
  });

  final String quizType;
  final SubLevel subLevel;
  /// 1-based position in subLevels list (optional, for API consistency).
  final int? ordinalLevelIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subLevel.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quiz – coming soon',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '$quizType • ${subLevel.progressKey}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
