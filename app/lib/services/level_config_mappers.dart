import '../models/level_config.dart';
import '../models/vocabulary_quiz.dart';

/// Converts unified [LevelConfig] conversation rows to [VocabularyLevel] for the convo UI.
VocabularyLevel vocabularyLevelFromConfig(LevelConfig cfg) {
  final convos =
      cfg.questions.where((q) => q.template == 'ConvoTemplate-1').toList();
  if (convos.isEmpty) {
    throw Exception('Level has no ConvoTemplate-1 questions');
  }
  final vq = <VocabularyQuestion>[];
  for (final q in convos) {
    final d = q.convoData;
    if (d == null) {
      throw Exception('Missing convoData for question');
    }
    vq.add(
      VocabularyQuestion(
        line1: d.line1,
        line2: d.line2,
        answer: d.answer,
        distractors: d.distractors,
      ),
    );
  }
  final first = convos.first.convoData!;
  return VocabularyLevel(
    character1: first.character1,
    character2: first.character2,
    questions: vq,
  );
}
