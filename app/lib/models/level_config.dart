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

/// Parsed `questionData` for [imageQuizTemplate-2] (noun prompt + pick image).
class ImageQuizTemplate2Data {
  const ImageQuizTemplate2Data({
    required this.imageName,
    required this.wrongAnswers,
    this.autoNextDelay = 1.0,
    this.showCorrectOnWrong = false,
  });

  final String imageName;
  final List<String> wrongAnswers;
  final double autoNextDelay;
  /// Parsed from `show_correct_on_wrong` in JSON; reserved — the grid always highlights the correct tile green when locked (same as template-1).
  final bool showCorrectOnWrong;
}

/// Parsed `questionData` for [ConvoTemplate-AppearDisappear].
class AppearDisappearQuestionData {
  const AppearDisappearQuestionData({
    required this.words,
    required this.distractors,
    this.displayDuration = 1.0,
    this.autoNextDelay = 1.0,
  });

  final List<String> words;
  final List<String> distractors;
  final double displayDuration;
  final double autoNextDelay;
}

/// Parsed `questionData` for [ConvoTemplate-Simon].
class SimonQuestionData {
  const SimonQuestionData({
    required this.words,
    required this.distractors,
    this.tileHighlightDuration = 0.5,
    this.autoNextDelay = 1.0,
  });

  final List<String> words;
  final List<String> distractors;
  final double tileHighlightDuration;
  final double autoNextDelay;
}

/// Parsed `questionData` for [ConvoTemplate-ClozeSequence].
class ClozeSequenceQuestionData {
  const ClozeSequenceQuestionData({
    required this.sentence,
    required this.answers,
    required this.distractors,
    this.autoNextDelay = 1.0,
  });

  /// Word tokens; use `"___"` for each blank in order.
  final List<String> sentence;
  final List<String> answers;
  final List<String> distractors;
  final double autoNextDelay;
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
    this.imageQuiz2Data,
    this.convoData,
    this.convo2Data,
    this.appearDisappearData,
    this.simonData,
    this.clozeSequenceData,
  });

  final String? questionId;
  final LevelQuestionType type;
  final String template;
  final ImageQuestionData? imageData;
  final ImageQuizTemplate2Data? imageQuiz2Data;
  final ConvoQuestionData? convoData;
  final ConvoTemplate2QuestionData? convo2Data;
  final AppearDisappearQuestionData? appearDisappearData;
  final SimonQuestionData? simonData;
  final ClozeSequenceQuestionData? clozeSequenceData;
}

/// Full level definition from `assets/quiz-data/levels/{iconImageName}.json`.
class LevelConfig {
  const LevelConfig({required this.questions});

  final List<LevelQuestion> questions;

  /// Maps JSON `type` string to [LevelQuestionType] or throws if unknown.
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

  /// Coerces a JSON object into `Map<String,String>` for localized line maps.
  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Expected object for localized lines');
    }
    return value.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    );
  }

  /// Validates and builds [ImageQuestionData] for `imageQuizTemplate-1` rows (exactly three wrong answers).
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

  /// Parses noun + four-image grid settings including optional delays and wrong-answer highlight flag.
  static ImageQuizTemplate2Data _parseImageQuiz2Data(Map<String, dynamic> data) {
    final imageName = data['imageName'] as String? ?? '';
    final wrong = (data['wrongAnswers'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (wrong.length != 3) {
      throw FormatException(
        'imageQuizTemplate-2 must have exactly 3 wrongAnswers (got ${wrong.length})',
      );
    }
    return ImageQuizTemplate2Data(
      imageName: imageName,
      wrongAnswers: wrong,
      autoNextDelay: (data['auto_next_delay'] as num?)?.toDouble() ?? 1.0,
      showCorrectOnWrong:
          data['show_correct_on_wrong'] as bool? ?? false,
    );
  }

  /// Safe coercion of JSON arrays to `List<String>` for word lists and similar fields.
  static List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e.toString()).toList();
  }

  /// Parses appear/disappear grid question; enforces nine total tiles for the 3×3 layout.
  static AppearDisappearQuestionData _parseAppearDisappear(
    Map<String, dynamic> data,
  ) {
    final words = _stringList(data['words']);
    final distractors = _stringList(data['distractors']);
    if (words.length + distractors.length != 9) {
      throw FormatException(
        'ConvoTemplate-AppearDisappear expects words.length + distractors.length == 9 (3×3), '
        'got ${words.length} + ${distractors.length}',
      );
    }
    return AppearDisappearQuestionData(
      words: words,
      distractors: distractors,
      displayDuration: (data['display_duration'] as num?)?.toDouble() ?? 1.0,
      autoNextDelay: (data['auto_next_delay'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Parses Simon template data with the same nine-tile constraint as appear/disappear.
  static SimonQuestionData _parseSimon(Map<String, dynamic> data) {
    final words = _stringList(data['words']);
    final distractors = _stringList(data['distractors']);
    if (words.length + distractors.length != 9) {
      throw FormatException(
        'ConvoTemplate-Simon expects words.length + distractors.length == 9 (3×3), '
        'got ${words.length} + ${distractors.length}',
      );
    }
    return SimonQuestionData(
      words: words,
      distractors: distractors,
      tileHighlightDuration:
          (data['tile_highlight_duration'] as num?)?.toDouble() ?? 0.5,
      autoNextDelay: (data['auto_next_delay'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Recognizes blank markers in cloze sentence tokens independent of underscore count in JSON.
  static bool _isBlankToken(String s) => s == '___' || s == '_____';

  /// Parses streaming cloze rows; checks blank count vs answers and grid tile totals (4 or 9).
  static ClozeSequenceQuestionData _parseClozeSequence(
    Map<String, dynamic> data,
  ) {
    final sentence = _stringList(data['sentence']);
    final answers = _stringList(data['answers']);
    final distractors = _stringList(data['distractors']);
    final blankCount = sentence.where(_isBlankToken).length;
    if (blankCount != answers.length) {
      throw FormatException(
        'ConvoTemplate-ClozeSequence: ${answers.length} answers but $blankCount blanks in sentence',
      );
    }
    final expectedTiles = answers.length + distractors.length;
    if (answers.length == 1) {
      if (expectedTiles != 4) {
        throw FormatException(
          'ConvoTemplate-ClozeSequence with 1 blank expects 4 grid tiles (answers + distractors), got $expectedTiles',
        );
      }
    } else {
      if (expectedTiles != 9) {
        throw FormatException(
          'ConvoTemplate-ClozeSequence with ${answers.length} blanks expects 9 grid tiles, got $expectedTiles',
        );
      }
    }
    return ClozeSequenceQuestionData(
      sentence: sentence,
      answers: answers,
      distractors: distractors,
      autoNextDelay: (data['auto_next_delay'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Builds two-character dialogue data plus answer and distractors for ConvoTemplate-1.
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

  /// Parses image-backed cloze (hero image name, localized sentence, three distractors).
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

  /// Dispatches one `levelQuestions[]` element to the correct parser based on `template`.
  static LevelQuestion _parseQuestion(Map<String, dynamic> json) {
    final type = _parseType(json['type'] as String? ?? '');
    final template = json['template'] as String? ?? '';
    final qd = json['questionData'];
    if (qd is! Map<String, dynamic>) {
      throw const FormatException('questionData must be an object');
    }
    ImageQuestionData? imageData;
    ImageQuizTemplate2Data? imageQuiz2Data;
    ConvoQuestionData? convoData;
    ConvoTemplate2QuestionData? convo2Data;
    AppearDisappearQuestionData? appearDisappearData;
    SimonQuestionData? simonData;
    ClozeSequenceQuestionData? clozeSequenceData;
    switch (template) {
      case 'imageQuizTemplate-1':
        imageData = _parseImageData(qd);
        break;
      case 'imageQuizTemplate-2':
        imageQuiz2Data = _parseImageQuiz2Data(qd);
        break;
      case 'ConvoTemplate-1':
        convoData = _parseConvoData(qd);
        break;
      case 'ConvoTemplate-2':
        convo2Data = _parseConvo2Data(qd);
        break;
      case 'ConvoTemplate-AppearDisappear':
        appearDisappearData = _parseAppearDisappear(qd);
        break;
      case 'ConvoTemplate-Simon':
        simonData = _parseSimon(qd);
        break;
      case 'ConvoTemplate-ClozeSequence':
        clozeSequenceData = _parseClozeSequence(qd);
        break;
      default:
        throw FormatException('Unknown template: $template');
    }
    return LevelQuestion(
      questionId: json['questionId'] as String?,
      type: type,
      template: template,
      imageData: imageData,
      imageQuiz2Data: imageQuiz2Data,
      convoData: convoData,
      convo2Data: convo2Data,
      appearDisappearData: appearDisappearData,
      simonData: simonData,
      clozeSequenceData: clozeSequenceData,
    );
  }

  /// Entry point from [loadLevelConfig]: reads `levelQuestions` into ordered [LevelQuestion] list.
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
