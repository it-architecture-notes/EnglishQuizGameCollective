import 'package:flutter/foundation.dart';

/// Discriminator for a question row in unified level JSON.
enum LevelQuestionType { image, vocab, grammar }

/// Parsed `questionData` for [imageQuizTemplate-1].
class ImageQuestionData {
  const ImageQuestionData({
    required this.imageName,
    required this.wrongAnswers,
  });

  final String imageName;
  final List<String> wrongAnswers;
}

/// Parsed `questionData` for [ConvoTemplate-1] (vocabulary or grammar).
class ConvoQuestionData {
  const ConvoQuestionData({
    required this.character1,
    required this.character2,
    required this.line1,
    required this.line2,
    required this.answer,
    required this.distractors,
  });

  final String character1;
  final String character2;
  final Map<String, String> line1;
  final Map<String, String> line2;
  final String answer;
  final List<String> distractors;
}

/// Parsed `questionData` for [ConvoTemplate-2] (image + cloze sentence + cloze image).
class ConvoTemplate2QuestionData {
  const ConvoTemplate2QuestionData({
    required this.imageName,
    required this.sentence,
    required this.answer,
    required this.distractors,
  });

  /// Basename without extension; must exist under the level folder.
  final String imageName;
  final Map<String, String> sentence;
  final String answer;
  final List<String> distractors;
}

/// One entry in `levelQuestions`.
class LevelQuestion {
  const LevelQuestion({
    this.questionId,
    required this.type,
    required this.template,
    this.imageData,
    this.convoData,
    this.convo2Data,
  });

  final String? questionId;
  final LevelQuestionType type;
  final String template;
  final ImageQuestionData? imageData;
  final ConvoQuestionData? convoData;
  final ConvoTemplate2QuestionData? convo2Data;

}

/// Full level definition from `assets/quiz-data/levels/{iconImageName}.json`.
class LevelConfig {
  const LevelConfig({required this.questions});

  final List<LevelQuestion> questions;

  static LevelQuestionType _parseType(String raw) {
    switch (raw) {
      case 'image':
        return LevelQuestionType.image;
      case 'vocab':
        return LevelQuestionType.vocab;
      case 'grammar':
        return LevelQuestionType.grammar;
      default:
        throw FormatException('Unknown question type: $raw');
    }
  }

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Expected object for localized lines');
    }
    return value.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    );
  }

  static ImageQuestionData _parseImageData(Map<String, dynamic> data) {
    final imageName = data['imageName'] as String? ?? '';
    final wrong = (data['wrongAnswers'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    assert(() {
      if (wrong.length != 3) {
        debugPrint(
          'LevelConfig: image question expects exactly 3 wrongAnswers, got ${wrong.length}',
        );
      }
      return true;
    }());
    if (wrong.length != 3) {
      throw FormatException(
        'image question must have exactly 3 wrongAnswers (got ${wrong.length})',
      );
    }
    return ImageQuestionData(imageName: imageName, wrongAnswers: wrong);
  }

  static ConvoQuestionData _parseConvoData(Map<String, dynamic> data) {
    return ConvoQuestionData(
      character1: data['character1'] as String? ?? '',
      character2: data['character2'] as String? ?? '',
      line1: _stringMap(data['line1']),
      line2: _stringMap(data['line2']),
      answer: data['answer'] as String? ?? '',
      distractors: (data['distractors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  static ConvoTemplate2QuestionData _parseConvo2Data(Map<String, dynamic> data) {
    final imageName = data['imageName'] as String? ?? '';
    final distractors = (data['distractors'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (distractors.length != 3) {
      throw FormatException(
        'ConvoTemplate-2 must have exactly 3 distractors (got ${distractors.length})',
      );
    }
    return ConvoTemplate2QuestionData(
      imageName: imageName,
      sentence: _stringMap(data['sentence']),
      answer: data['answer'] as String? ?? '',
      distractors: distractors,
    );
  }

  static LevelQuestion _parseQuestion(Map<String, dynamic> json) {
    final type = _parseType(json['type'] as String? ?? '');
    final template = json['template'] as String? ?? '';
    final qd = json['questionData'];
    if (qd is! Map<String, dynamic>) {
      throw const FormatException('questionData must be an object');
    }
    ImageQuestionData? imageData;
    ConvoQuestionData? convoData;
    ConvoTemplate2QuestionData? convo2Data;
    switch (template) {
      case 'imageQuizTemplate-1':
        imageData = _parseImageData(qd);
        break;
      case 'ConvoTemplate-1':
        convoData = _parseConvoData(qd);
        break;
      case 'ConvoTemplate-2':
        convo2Data = _parseConvo2Data(qd);
        break;
      default:
        throw FormatException('Unknown template: $template');
    }
    return LevelQuestion(
      questionId: json['questionId'] as String?,
      type: type,
      template: template,
      imageData: imageData,
      convoData: convoData,
      convo2Data: convo2Data,
    );
  }

  factory LevelConfig.fromJson(Map<String, dynamic> json) {
    final list = json['levelQuestions'] as List<dynamic>? ?? [];
    final questions = <LevelQuestion>[];
    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      questions.add(_parseQuestion(e));
    }
    return LevelConfig(questions: questions);
  }
}
