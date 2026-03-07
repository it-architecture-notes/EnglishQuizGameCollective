// Grammar quiz question types and level model.
// Question types: conversation (vocab-like), word_order, banked_cloze,
// yes_no, which_correct. Discriminated by [GrammarQuestion.questionType].

/// Base type for a single grammar question.
abstract class GrammarQuestion {
  const GrammarQuestion({required this.questionType});
  final String questionType;

  static GrammarQuestion fromJson(Map<String, dynamic> json) {
    final type = json['questionType'] as String? ?? '';
    switch (type) {
      case 'conversation':
        return GrammarConversationQuestion.fromJson(json);
      case 'word_order':
        return GrammarWordOrderQuestion.fromJson(json);
      case 'banked_cloze':
        return GrammarBankedClozeQuestion.fromJson(json);
      case 'yes_no':
        return GrammarYesNoQuestion.fromJson(json);
      case 'which_correct':
        return GrammarWhichCorrectQuestion.fromJson(json);
      default:
        throw ArgumentError('Unknown grammar questionType: $type');
    }
  }
}

/// Two characters, one blank (tense/auxiliary); same shape as vocabulary.
class GrammarConversationQuestion extends GrammarQuestion {
  const GrammarConversationQuestion({
    required this.character1,
    required this.character2,
    required this.line1,
    required this.line2,
    required this.answer,
    required this.distractors,
  }) : super(questionType: 'conversation');

  final String character1;
  final String character2;
  final Map<String, String> line1;
  final Map<String, String> line2;
  final String answer;
  final List<String> distractors;

  bool get blankInLine1 => line1['en']?.contains('_____') ?? false;

  static GrammarConversationQuestion fromJson(Map<String, dynamic> json) {
    Map<String, String> parseLineMap(dynamic value) {
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return {};
    }
    return GrammarConversationQuestion(
      character1: json['character1'] as String? ?? '',
      character2: json['character2'] as String? ?? '',
      line1: parseLineMap(json['line1']),
      line2: parseLineMap(json['line2']),
      answer: json['answer'] as String? ?? '',
      distractors: (json['distractors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// One correct sentence among 4 word-order variants.
class GrammarWordOrderQuestion extends GrammarQuestion {
  const GrammarWordOrderQuestion({
    required this.sentence,
    required this.distractors,
  }) : super(questionType: 'word_order');

  final String sentence;
  final List<String> distractors;

  static GrammarWordOrderQuestion fromJson(Map<String, dynamic> json) {
    return GrammarWordOrderQuestion(
      sentence: json['sentence'] as String? ?? '',
      distractors: (json['distractors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// One sentence with multiple blanks; one option fills all (e.g. "was/have/asked").
class GrammarBankedClozeQuestion extends GrammarQuestion {
  const GrammarBankedClozeQuestion({
    required this.sentenceWithBlanks,
    required this.answer,
    required this.distractors,
  }) : super(questionType: 'banked_cloze');

  final String sentenceWithBlanks;
  final String answer;
  final List<String> distractors;

  static GrammarBankedClozeQuestion fromJson(Map<String, dynamic> json) {
    return GrammarBankedClozeQuestion(
      sentenceWithBlanks: json['sentenceWithBlanks'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      distractors: (json['distractors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Is the sentence grammatically correct? Two options: Yes / No.
class GrammarYesNoQuestion extends GrammarQuestion {
  const GrammarYesNoQuestion({
    required this.sentence,
    required this.correctAnswer,
    this.correction,
  }) : super(questionType: 'yes_no');

  final String sentence;
  /// "yes" or "no"
  final String correctAnswer;
  /// When sentence is wrong (correctAnswer is "no"), optional corrected sentence to show.
  final String? correction;

  static GrammarYesNoQuestion fromJson(Map<String, dynamic> json) {
    return GrammarYesNoQuestion(
      sentence: json['sentence'] as String? ?? '',
      correctAnswer: json['correctAnswer'] as String? ?? 'no',
      correction: json['correction'] as String?,
    );
  }
}

/// One of 4 sentences is correct for context.
class GrammarWhichCorrectQuestion extends GrammarQuestion {
  const GrammarWhichCorrectQuestion({
    this.context,
    required this.options,
    required this.correctIndex,
  }) : super(questionType: 'which_correct');

  final String? context;
  final List<String> options;
  final int correctIndex;

  static GrammarWhichCorrectQuestion fromJson(Map<String, dynamic> json) {
    return GrammarWhichCorrectQuestion(
      context: json['context'] as String?,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Full content of one grammar level file.
class GrammarLevel {
  const GrammarLevel({
    this.character1 = '',
    this.character2 = '',
    required this.questions,
  });

  /// Used for first (conversation) question only.
  final String character1;
  final String character2;
  final List<GrammarQuestion> questions;

  static GrammarLevel fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return GrammarLevel(
      character1: json['character1'] as String? ?? '',
      character2: json['character2'] as String? ?? '',
      questions: rawQuestions
          .map((e) => GrammarQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
