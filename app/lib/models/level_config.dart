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

/// [ConvoTemplate-SentenceBuilder]: immediate grid; [correctOrder] is the target token sequence.
class SentenceBuilderQuestionData {
  const SentenceBuilderQuestionData({
    required this.correctOrder,
    required this.words,
    required this.distractors,
    this.autoNextDelay = 1.0,
  });

  final List<String> correctOrder;
  final List<String> words;
  final List<String> distractors;
  final double autoNextDelay;
}

/// One left/right pair for [ConvoTemplate-WordPairs].
class WordPairItem {
  const WordPairItem({required this.left, required this.right});

  final String left;
  final String right;
}

/// [ConvoTemplate-WordPairs]: 3–4 pairs; UI scrambles the right column.
class WordPairsQuestionData {
  const WordPairsQuestionData({
    required this.pairs,
    this.autoNextDelay = 1.0,
  });

  final List<WordPairItem> pairs;
  final double autoNextDelay;
}

/// [imageQuizTemplate-3]: hero image + four full-sentence options.
class ImageQuizTemplate3Data {
  const ImageQuizTemplate3Data({
    required this.imageName,
    required this.answer,
    required this.distractors,
    this.distractorType,
  });

  final String imageName;
  final String answer;
  final List<String> distractors;
  /// Optional: `grammar` | `meaning` | `tense` — reserved for future use.
  final String? distractorType;
}

/// [imageQuizTemplate-SpotDifference]: two images + localized prompt.
class SpotDifferenceQuestionData {
  const SpotDifferenceQuestionData({
    required this.sentence,
    required this.correctImage,
    required this.wrongImage,
    this.autoNextDelay = 1.0,
  });

  final Map<String, String> sentence;
  final String correctImage;
  final String wrongImage;
  final double autoNextDelay;
}

/// [ConvoTemplate-GrammarForm]: cloze sentence + lemma hint + four word options.
class GrammarFormQuestionData {
  const GrammarFormQuestionData({
    required this.sentence,
    required this.hintWord,
    required this.answer,
    required this.distractors,
  });

  final Map<String, String> sentence;
  final String hintWord;
  final String answer;
  final List<String> distractors;
}

/// [ConvoTemplate-DialogueCompletion]: first speaker line + four response options.
class DialogueCompletionQuestionData {
  const DialogueCompletionQuestionData({
    required this.character1,
    required this.character2,
    required this.line1,
    required this.answer,
    required this.distractors,
  });

  final String character1;
  final String character2;
  final Map<String, String> line1;
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
    this.imageQuiz3Data,
    this.spotDiffData,
    this.convoData,
    this.convo2Data,
    this.appearDisappearData,
    this.simonData,
    this.clozeSequenceData,
    this.sentenceBuilderData,
    this.wordPairsData,
    this.grammarFormData,
    this.dialogueCompletionData,
  });

  final String? questionId;
  final LevelQuestionType type;
  final String template;
  final ImageQuestionData? imageData;
  final ImageQuizTemplate2Data? imageQuiz2Data;
  final ImageQuizTemplate3Data? imageQuiz3Data;
  final SpotDifferenceQuestionData? spotDiffData;
  final ConvoQuestionData? convoData;
  final ConvoTemplate2QuestionData? convo2Data;
  final AppearDisappearQuestionData? appearDisappearData;
  final SimonQuestionData? simonData;
  final ClozeSequenceQuestionData? clozeSequenceData;
  final SentenceBuilderQuestionData? sentenceBuilderData;
  final WordPairsQuestionData? wordPairsData;
  final GrammarFormQuestionData? grammarFormData;
  final DialogueCompletionQuestionData? dialogueCompletionData;
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

  /// True if [a] and [b] are identical multisets (same length, same sorted tokens).
  static bool _sameMultiset(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort();
    final sb = [...b]..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  /// Parses [ConvoTemplate-SentenceBuilder]: [correct_order] and [words] must match as multisets.
  static SentenceBuilderQuestionData _parseSentenceBuilder(
    Map<String, dynamic> data,
  ) {
    final correctOrder = _stringList(data['correct_order']);
    final words = _stringList(data['words']);
    final distractors = _stringList(data['distractors']);
    if (correctOrder.isEmpty || !_sameMultiset(correctOrder, words)) {
      throw FormatException(
        'ConvoTemplate-SentenceBuilder: correct_order must match words as a multiset',
      );
    }
    final total = words.length + distractors.length;
    if (total != 9) {
      throw FormatException(
        'ConvoTemplate-SentenceBuilder expects words + distractors == 9 tiles (3×3), got $total',
      );
    }
    return SentenceBuilderQuestionData(
      correctOrder: correctOrder,
      words: words,
      distractors: distractors,
      autoNextDelay: (data['auto_next_delay'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Parses [ConvoTemplate-WordPairs]: 3–4 pairs.
  static WordPairsQuestionData _parseWordPairs(Map<String, dynamic> data) {
    final raw = data['pairs'] as List<dynamic>? ?? [];
    final pairs = <WordPairItem>[];
    for (final e in raw) {
      if (e is! Map<String, dynamic>) continue;
      pairs.add(
        WordPairItem(
          left: e['left']?.toString() ?? '',
          right: e['right']?.toString() ?? '',
        ),
      );
    }
    if (pairs.length < 3 || pairs.length > 4) {
      throw FormatException(
        'ConvoTemplate-WordPairs expects 3–4 pairs, got ${pairs.length}',
      );
    }
    return WordPairsQuestionData(
      pairs: pairs,
      autoNextDelay: (data['auto_next_delay'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Parses [imageQuizTemplate-3]: one correct sentence + three distractors.
  static ImageQuizTemplate3Data _parseImageQuiz3(Map<String, dynamic> data) {
    final distractors = (data['distractors'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (distractors.length != 3) {
      throw FormatException(
        'imageQuizTemplate-3 must have exactly 3 distractors (got ${distractors.length})',
      );
    }
    final dt = data['distractor_type']?.toString();
    return ImageQuizTemplate3Data(
      imageName: data['imageName'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      distractors: distractors,
      distractorType: dt,
    );
  }

  /// Parses [imageQuizTemplate-SpotDifference].
  static SpotDifferenceQuestionData _parseSpotDifference(
    Map<String, dynamic> data,
  ) {
    return SpotDifferenceQuestionData(
      sentence: _stringMap(data['sentence']),
      correctImage: data['correctImage'] as String? ?? '',
      wrongImage: data['wrongImage'] as String? ?? '',
      autoNextDelay: (data['auto_next_delay'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Parses [ConvoTemplate-GrammarForm]: localized sentence with blank + hint + four options.
  static GrammarFormQuestionData _parseGrammarForm(Map<String, dynamic> data) {
    final sentence = _stringMap(data['sentence']);
    final distractors = (data['distractors'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (distractors.length != 3) {
      throw FormatException(
        'ConvoTemplate-GrammarForm must have exactly 3 distractors',
      );
    }
    final en = sentence['en'] ?? '';
    if (!en.contains('___') && !en.contains('_____')) {
      throw FormatException(
        'ConvoTemplate-GrammarForm: sentence should contain a blank (___ or _____)',
      );
    }
    return GrammarFormQuestionData(
      sentence: sentence,
      hintWord: data['hintWord'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      distractors: distractors,
    );
  }

  /// Parses [ConvoTemplate-DialogueCompletion].
  static DialogueCompletionQuestionData _parseDialogueCompletion(
    Map<String, dynamic> data,
  ) {
    final distractors = (data['distractors'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (distractors.length != 3) {
      throw FormatException(
        'ConvoTemplate-DialogueCompletion must have exactly 3 distractors',
      );
    }
    return DialogueCompletionQuestionData(
      character1: data['character1'] as String? ?? '',
      character2: data['character2'] as String? ?? '',
      line1: _stringMap(data['line1']),
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
    ImageQuizTemplate3Data? imageQuiz3Data;
    SpotDifferenceQuestionData? spotDiffData;
    ConvoQuestionData? convoData;
    ConvoTemplate2QuestionData? convo2Data;
    AppearDisappearQuestionData? appearDisappearData;
    SimonQuestionData? simonData;
    ClozeSequenceQuestionData? clozeSequenceData;
    SentenceBuilderQuestionData? sentenceBuilderData;
    WordPairsQuestionData? wordPairsData;
    GrammarFormQuestionData? grammarFormData;
    DialogueCompletionQuestionData? dialogueCompletionData;
    switch (template) {
      case 'imageQuizTemplate-1':
        imageData = _parseImageData(qd);
        break;
      case 'imageQuizTemplate-2':
        imageQuiz2Data = _parseImageQuiz2Data(qd);
        break;
      case 'imageQuizTemplate-3':
      case 'imageQuizTemplate-SentenceChoice':
        imageQuiz3Data = _parseImageQuiz3(qd);
        break;
      case 'imageQuizTemplate-SpotDifference':
        spotDiffData = _parseSpotDifference(qd);
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
      case 'ConvoTemplate-SentenceBuilder':
        sentenceBuilderData = _parseSentenceBuilder(qd);
        break;
      case 'ConvoTemplate-WordPairs':
        wordPairsData = _parseWordPairs(qd);
        break;
      case 'ConvoTemplate-GrammarForm':
        grammarFormData = _parseGrammarForm(qd);
        break;
      case 'ConvoTemplate-DialogueCompletion':
        dialogueCompletionData = _parseDialogueCompletion(qd);
        break;
      default:
        throw FormatException('Unknown template: $template');
    }
    final normalizedTemplate =
        template == 'imageQuizTemplate-SentenceChoice'
            ? 'imageQuizTemplate-3'
            : template;
    return LevelQuestion(
      questionId: json['questionId'] as String?,
      type: type,
      template: normalizedTemplate,
      imageData: imageData,
      imageQuiz2Data: imageQuiz2Data,
      imageQuiz3Data: imageQuiz3Data,
      spotDiffData: spotDiffData,
      convoData: convoData,
      convo2Data: convo2Data,
      appearDisappearData: appearDisappearData,
      simonData: simonData,
      clozeSequenceData: clozeSequenceData,
      sentenceBuilderData: sentenceBuilderData,
      wordPairsData: wordPairsData,
      grammarFormData: grammarFormData,
      dialogueCompletionData: dialogueCompletionData,
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
