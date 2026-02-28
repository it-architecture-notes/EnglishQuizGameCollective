/// A single conversation exchange / quiz question.
///
/// The blank `_____` (five underscores) appears in exactly one of [line1] or
/// [line2] in the English text. [answer] is the word that fills that blank.
/// [distractors] provides the three wrong answer options.
class VocabularyQuestion {
  const VocabularyQuestion({
    required this.line1,
    required this.line2,
    required this.answer,
    required this.distractors,
  });

  /// First character's dialogue line, keyed by language code (e.g. "en", "tr").
  final Map<String, String> line1;

  /// Second character's dialogue line, keyed by language code.
  final Map<String, String> line2;

  /// The correct answer word that fills the blank.
  final String answer;

  /// Three wrong answer words.
  final List<String> distractors;

  /// True when the blank `_____` is in [line1] (first character's line).
  bool get blankInLine1 => line1['en']?.contains('_____') ?? false;

  /// English text for [line1] with the blank filled by [answer].
  String get line1Resolved => (line1['en'] ?? '').replaceAll('_____', answer);

  /// English text for [line2] with the blank filled (if any).
  String get line2Resolved => (line2['en'] ?? '').replaceAll('_____', answer);

  static VocabularyQuestion fromJson(Map<String, dynamic> json) {
    Map<String, String> parseLineMap(dynamic value) {
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return {};
    }

    return VocabularyQuestion(
      line1: parseLineMap(json['line1']),
      line2: parseLineMap(json['line2']),
      answer: json['answer'] as String? ?? '',
      distractors: (json['distractors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// The full content of one vocabulary level file.
///
/// [character1] and [character2] are the icon/image names for the two speakers
/// (e.g. "mike", "sarah"). They are shared across all [questions] in the level.
class VocabularyLevel {
  const VocabularyLevel({
    required this.character1,
    required this.character2,
    required this.questions,
  });

  /// Icon/image name for the first character (e.g. "mike").
  final String character1;

  /// Icon/image name for the second character (e.g. "sarah").
  final String character2;

  final List<VocabularyQuestion> questions;

  static VocabularyLevel fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return VocabularyLevel(
      character1: json['character1'] as String? ?? '',
      character2: json['character2'] as String? ?? '',
      questions: rawQuestions
          .map((e) => VocabularyQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
