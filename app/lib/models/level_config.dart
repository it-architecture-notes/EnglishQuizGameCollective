import 'package:flutter/foundation.dart';


/// Parsed `questionData` for [imageQuizTemplate-1].
class ImageQuestionData {
  const ImageQuestionData({
    required this.imageName,
    required this.wrongAnswers,
    this.answer,
  });

  final String imageName;
  final List<String> wrongAnswers;
  /// Optional override for the correct answer label shown in MCQ buttons.
  /// When null the image basename is used instead.
  final String? answer;
}

/// Parsed `questionData` for [imageQuizTemplate-2] (noun prompt + pick image).
class ImageQuizTemplate2Data {
  const ImageQuizTemplate2Data({
    required this.imageName,
    required this.wrongAnswers,
    this.answer,
  });

  final String imageName;
  final List<String> wrongAnswers;
  /// Optional override for the correct tile’s option key (same role as [ImageQuestionData.answer]).
  /// When null or empty, [imageName] is used. The correct image file is always [imageName].
  final String? answer;

  /// Stem identifying the correct choice in the shuffled grid (for scoring and option keys).
  String get correctAnswerStem =>
      (answer != null && answer!.isNotEmpty) ? answer! : imageName;
}

/// Parsed `questionData` for [ConvoTemplate-AppearDisappear].
class AppearDisappearQuestionData {
  const AppearDisappearQuestionData({
    required this.words,
    required this.distractors,
    this.displayDuration = 1.0,
    this.introPause = 2.0,
  });

  final List<String> words;
  final List<String> distractors;
  final double displayDuration;
  /// Pause (seconds) with empty boxes before word reveal starts.
  final double introPause;
}

/// Parsed `questionData` for [ConvoTemplate-ClozeSequence] (and the adapter for ConvoTemplate-2).
class ClozeSequenceQuestionData {
  const ClozeSequenceQuestionData({
    required this.sentence,
    required this.answers,
    required this.distractors,
    this.imageName,
  });

  /// Localized sentence map. English value uses 2+ underscores as blank markers (e.g. `_____`).
  final Map<String, String> sentence;
  final List<String> answers;
  final List<String> distractors;
  /// Optional image basename under the level folder. Null = no image.
  final String? imageName;
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
    this.line1Translation,
    this.line2Translation,
    this.imageName,
  });

  final String character1;
  final String character2;
  final Map<String, String> line1;
  final Map<String, String> line2;
  final String answer;
  final List<String> distractors;
  final Map<String, String>? line1Translation;
  final Map<String, String>? line2Translation;
  /// Optional image basename (no extension) under the level folder.
  final String? imageName;
}

/// Parsed `questionData` for [ConvoTemplate-2] (optional hero image + cloze sentence).
class ConvoTemplate2QuestionData {
  const ConvoTemplate2QuestionData({
    this.imageName,
    required this.sentence,
    required this.answer,
    required this.distractors,
  });

  /// Basename without extension under the level folder; omit or null = no image.
  final String? imageName;
  final Map<String, String> sentence;
  final String answer;
  final List<String> distractors;
}

/// [ConvoTemplate-SentenceBuilder]: tiles are only the sentence tokens, shuffled; player taps in [correctOrder].
class SentenceBuilderQuestionData {
  const SentenceBuilderQuestionData({
    required this.correctOrder,
    this.translation,
  });

  /// Target sentence token sequence (left-to-right).
  final List<String> correctOrder;
  final Map<String, String>? translation;
}

/// One left/right pair for [ConvoTemplate-WordPairs].
class WordPairItem {
  const WordPairItem({required this.left, required this.translations});

  final String left;
  /// Locale → translation (e.g. `tr`, `es`, `fr`).
  final Map<String, String> translations;

  String rightForLanguage(String userLanguage) {
    String? normalized(String? value) {
      final trimmed = value?.trim() ?? '';
      return trimmed.isEmpty ? null : trimmed;
    }

    if (userLanguage != 'en') {
      final direct = normalized(translations[userLanguage]);
      if (direct != null) return direct;
    }

    // Prefer common non-English fallbacks before English.
    final tr = normalized(translations['tr']);
    if (tr != null) return tr;
    final es = normalized(translations['es']);
    if (es != null) return es;
    final fr = normalized(translations['fr']);
    if (fr != null) return fr;

    final en = normalized(translations['en']);
    if (en != null) return en;

    for (final value in translations.values) {
      final fallback = normalized(value);
      if (fallback != null) return fallback;
    }

    return left;
  }
}

/// [ConvoTemplate-WordPairs]: 3–4 pairs; UI scrambles the right column.
class WordPairsQuestionData {
  const WordPairsQuestionData({required this.pairs});

  final List<WordPairItem> pairs;
}

/// [ConvoTemplate-GrammarForm]: English cloze sentence + four word options.
class GrammarFormQuestionData {
  const GrammarFormQuestionData({
    required this.sentence,
    required this.answer,
    required this.distractors,
    this.translation,
  });

  final String sentence;
  final String answer;
  final List<String> distractors;
  final Map<String, String>? translation;
}

/// [ConvoTemplate-DialogueCompletion]: first speaker line + four response options.
class DialogueCompletionQuestionData {
  const DialogueCompletionQuestionData({
    required this.character1,
    required this.character2,
    required this.line1,
    required this.answer,
    required this.distractors,
    this.line1Translation,
    this.answerTranslation,
    this.imageName,
  });

  final String character1;
  final String character2;
  final Map<String, String> line1;
  final String answer;
  final List<String> distractors;
  final Map<String, String>? line1Translation;
  final Map<String, String>? answerTranslation;
  /// Optional image basename (no extension) under the level folder.
  final String? imageName;
}

/// One entry in `levelQuestions`.
class LevelQuestion {
  const LevelQuestion({
    this.questionId,
    this.audioFile,
    this.audioFile1,
    this.audioFile2,
    required this.template,
    this.imageData,
    this.imageQuiz2Data,
    this.convoData,
    this.convo2Data,
    this.appearDisappearData,
    this.clozeSequenceData,
    this.sentenceBuilderData,
    this.wordPairsData,
    this.grammarFormData,
    this.dialogueCompletionData,
    this.appearDisappearTranslation,
  });

  final String? questionId;
  final String? audioFile;
  /// [ConvoTemplate-DialogueCompletion]: question line audio (top-level JSON).
  final String? audioFile1;
  /// [ConvoTemplate-DialogueCompletion]: correct-answer audio (top-level JSON).
  final String? audioFile2;
  final String template;
  final ImageQuestionData? imageData;
  final ImageQuizTemplate2Data? imageQuiz2Data;
  final ConvoQuestionData? convoData;
  final ConvoTemplate2QuestionData? convo2Data;
  final AppearDisappearQuestionData? appearDisappearData;
  final ClozeSequenceQuestionData? clozeSequenceData;
  final SentenceBuilderQuestionData? sentenceBuilderData;
  final WordPairsQuestionData? wordPairsData;
  final GrammarFormQuestionData? grammarFormData;
  final DialogueCompletionQuestionData? dialogueCompletionData;

  /// Top-level `translation` map for [ConvoTemplate-AppearDisappear] only (sibling to `questionData` in JSON).
  final Map<String, String>? appearDisappearTranslation;

  /// True when this question uses an image-mode template (imageQuizTemplate-*).
  bool get isImageTemplate => template.startsWith('imageQuizTemplate');
}

/// Full level definition from `assets/quiz-data/levels/{iconImageName}.json`.
class LevelConfig {
  const LevelConfig({required this.questions, this.timerSeconds});

  final List<LevelQuestion> questions;
  /// Level-wide monster timer override (seconds). Null = use global `imageQuizTimerSeconds` from `game_config.json`.
  final int? timerSeconds;


  /// Coerces a JSON object into `Map<String,String>` for localized line maps.
  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Expected object for localized lines');
    }
    return value.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    );
  }

  static Map<String, String>? _stringMapOrNull(dynamic value) {
    if (value == null || value is! Map) return null;
    return value.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    );
  }

  /// Validates and builds [ImageQuestionData] for `imageQuizTemplate-1` rows (exactly three wrong answers).
  /// Accepts `wrongAnswers` or `distractors` (the latter is used by the former imageQuizTemplate-3 JSON).
  static ImageQuestionData _parseImageData(Map<String, dynamic> data) {
    final imageName = data['imageName'] as String? ?? '';
    final wrongRaw = data['wrongAnswers'] ?? data['distractors'];
    final wrong = (wrongRaw as List<dynamic>? ?? [])
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
    return ImageQuestionData(
      imageName: imageName,
      wrongAnswers: wrong,
      answer: data['answer'] as String?,
    );
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
      answer: data['answer'] as String?,
    );
  }

  /// Safe coercion of JSON arrays to `List<String>` for word lists and similar fields.
  static List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e.toString()).toList();
  }

  /// Parses words from either:
  /// - legacy array format: ["I", "love", "tea"]
  /// - new sentence format: "I love tea"
  static List<String> _wordsFromArrayOrSentence(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    if (v is String) {
      final trimmed = v.trim();
      if (trimmed.isEmpty) return const [];
      return trimmed.split(RegExp(r'\s+'));
    }
    return const [];
  }

  /// Parses appear/disappear sequence question with flexible choice count.
  static AppearDisappearQuestionData _parseAppearDisappear(
    Map<String, dynamic> data,
  ) {
    final words = _wordsFromArrayOrSentence(data['words']);
    final distractors = _stringList(data['distractors']);
    if (words.isEmpty) {
      throw FormatException(
        'ConvoTemplate-AppearDisappear expects at least 1 target word',
      );
    }
    return AppearDisappearQuestionData(
      words: words,
      distractors: distractors,
      displayDuration: (data['display_duration'] as num?)?.toDouble() ?? 1.0,
      introPause: (data['intro_pause'] as num?)?.toDouble() ?? 2.0,
    );
  }

  /// Returns true when a space-delimited token is a blank marker (2+ underscores, nothing else).
  static bool _isBlankToken(String s) => RegExp(r'^_{2,}$').hasMatch(s);

  /// Counts blanks in the English value of a localized sentence map.
  static int _countBlanks(Map<String, String> sentence) =>
      (sentence['en'] ?? '').split(' ').where(_isBlankToken).length;

  /// Parses [ConvoTemplate-ClozeSequence]: localized sentence map, ordered answers, flexible distractors.
  static ClozeSequenceQuestionData _parseClozeSequence(
    Map<String, dynamic> data,
  ) {
    final sentence = _stringMap(data['sentence']);
    // Accept 'answer' (array or single string) or 'answers' (array)
    final rawAnswer = data['answer'] ?? data['answers'];
    final List<String> answers;
    if (rawAnswer is List) {
      answers = rawAnswer.map((e) => e.toString()).toList();
    } else if (rawAnswer is String) {
      answers = [rawAnswer];
    } else {
      answers = const [];
    }
    final distractors = _stringList(data['distractors']);
    final blankCount = _countBlanks(sentence);
    if (blankCount != answers.length) {
      throw FormatException(
        'ConvoTemplate-ClozeSequence: ${answers.length} answers but $blankCount blanks in sentence["en"]',
      );
    }
    final rawName = data['imageName'];
    final String? imageName =
        rawName is String && rawName.trim().isNotEmpty ? rawName.trim() : null;
    return ClozeSequenceQuestionData(
      sentence: sentence,
      answers: answers,
      distractors: distractors,
      imageName: imageName,
    );
  }

  /// Converts a [ConvoTemplate-2] payload into a [ClozeSequenceQuestionData] for the unified widget.
  static ClozeSequenceQuestionData _parseConvo2AsCloze(
    Map<String, dynamic> data,
  ) {
    final c2 = _parseConvo2Data(data);
    return ClozeSequenceQuestionData(
      sentence: c2.sentence,
      answers: [c2.answer],
      distractors: c2.distractors,
      imageName: c2.imageName,
    );
  }

  /// Builds two-character dialogue data plus answer and distractors for ConvoTemplate-1.
  static ConvoQuestionData _parseConvoData(Map<String, dynamic> data) {
    final rawImageName = data['image_file_name'];
    final String? imageName = rawImageName is String && rawImageName.trim().isNotEmpty
        ? rawImageName.trim()
        : null;
    return ConvoQuestionData(
      character1: data['character1'] as String? ?? '',
      character2: data['character2'] as String? ?? '',
      line1: _stringMap(data['line1']),
      line2: _stringMap(data['line2']),
      answer: data['answer'] as String? ?? '',
      distractors: (data['distractors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      line1Translation: _stringMapOrNull(data['line1_translation']),
      line2Translation: _stringMapOrNull(data['line2_translation']),
      imageName: imageName,
    );
  }

  /// Parses optional hero image + cloze (localized sentence, three distractors).
  static ConvoTemplate2QuestionData _parseConvo2Data(Map<String, dynamic> data) {
    final rawName = data['imageName'];
    final String? imageName = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : null;
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

  /// Parses [ConvoTemplate-SentenceBuilder]: [correct_order] lists the sentence tokens in order (no distractors).
  static SentenceBuilderQuestionData _parseSentenceBuilder(
    Map<String, dynamic> data,
  ) {
    final correctOrder = _wordsFromArrayOrSentence(data['correct_order']);
    if (correctOrder.length < 2) {
      throw FormatException(
        'ConvoTemplate-SentenceBuilder: correct_order must have at least 2 tokens',
      );
    }
    return SentenceBuilderQuestionData(
      correctOrder: correctOrder,
      translation: _stringMapOrNull(data['translation']),
    );
  }

  /// Parses [ConvoTemplate-WordPairs] from:
  /// - english_words: ["Good Morning", ...]
  /// - translations: [{"tr":"Gunaydin","es":"..."}, ...]
  static WordPairsQuestionData _parseWordPairs(Map<String, dynamic> data) {
    final englishWords = _stringList(data['english_words']);
    final rawTranslations = data['translations'] as List<dynamic>? ?? const [];
    if (englishWords.length != rawTranslations.length) {
      throw FormatException(
        'ConvoTemplate-WordPairs: english_words.length (${englishWords.length}) '
        'must match translations.length (${rawTranslations.length})',
      );
    }
    final pairs = <WordPairItem>[];
    for (var i = 0; i < englishWords.length; i++) {
      final translationMap = _stringMapOrNull(rawTranslations[i]);
      if (translationMap == null || translationMap.isEmpty) {
        throw FormatException(
          'ConvoTemplate-WordPairs: translations[$i] must be a non-empty locale map',
        );
      }
      pairs.add(WordPairItem(left: englishWords[i], translations: translationMap));
    }

    if (pairs.length < 3 || pairs.length > 4) {
      throw FormatException(
        'ConvoTemplate-WordPairs expects 3–4 pairs, got ${pairs.length}',
      );
    }
    return WordPairsQuestionData(pairs: pairs);
  }

  /// Parses [ConvoTemplate-GrammarForm]: English sentence with blank + four options.
  static GrammarFormQuestionData _parseGrammarForm(Map<String, dynamic> data) {
    final rawSentence = data['sentence'];
    final String sentence = switch (rawSentence) {
      String s => s.trim(),
      Map m => (m['en']?.toString() ?? '').trim(),
      _ => '',
    };
    final distractors = (data['distractors'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    if (distractors.length != 3) {
      throw FormatException(
        'ConvoTemplate-GrammarForm must have exactly 3 distractors',
      );
    }
    if (!sentence.contains('___') && !sentence.contains('_____')) {
      throw FormatException(
        'ConvoTemplate-GrammarForm: sentence should contain a blank (___ or _____)',
      );
    }
    return GrammarFormQuestionData(
      sentence: sentence,
      answer: data['answer'] as String? ?? '',
      distractors: distractors,
      translation: _stringMapOrNull(data['translation']),
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
    final rawImageName = data['image_file_name'];
    final String? imageName = rawImageName is String && rawImageName.trim().isNotEmpty
        ? rawImageName.trim()
        : null;
    return DialogueCompletionQuestionData(
      character1: data['character1'] as String? ?? '',
      character2: data['character2'] as String? ?? '',
      line1: _stringMap(data['line1']),
      answer: data['answer'] as String? ?? '',
      distractors: distractors,
      line1Translation: _stringMapOrNull(data['line1_translation']),
      answerTranslation: _stringMapOrNull(data['answer_translation']),
      imageName: imageName,
    );
  }

  /// Dispatches one `levelQuestions[]` element to the correct parser based on `template`.
  static LevelQuestion _parseQuestion(Map<String, dynamic> json) {
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
        imageData = _parseImageData(qd);
        break;
      case 'ConvoTemplate-1':
        convoData = _parseConvoData(qd);
        break;
      case 'ConvoTemplate-2':
        // Adapter: convert to the unified ClozeSequence model.
        clozeSequenceData = _parseConvo2AsCloze(qd);
        break;
      case 'ConvoTemplate-AppearDisappear':
        appearDisappearData = _parseAppearDisappear(qd);
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
    final normalizedTemplate = switch (template) {
      'imageQuizTemplate-3' => 'imageQuizTemplate-1',
      'imageQuizTemplate-SentenceChoice' => 'imageQuizTemplate-1',
      'ConvoTemplate-2' => 'ConvoTemplate-ClozeSequence',
      _ => template,
    };
    final appearDisappearTranslation = template == 'ConvoTemplate-AppearDisappear'
        ? _stringMapOrNull(json['translation'])
        : null;
    return LevelQuestion(
      questionId: json['questionId'] as String?,
      audioFile: json['audio_file'] as String?,
      audioFile1: json['audio_file1'] as String?,
      audioFile2: json['audio_file2'] as String?,
      template: normalizedTemplate,
      imageData: imageData,
      imageQuiz2Data: imageQuiz2Data,
      convoData: convoData,
      convo2Data: convo2Data,
      appearDisappearData: appearDisappearData,
      clozeSequenceData: clozeSequenceData,
      sentenceBuilderData: sentenceBuilderData,
      wordPairsData: wordPairsData,
      grammarFormData: grammarFormData,
      dialogueCompletionData: dialogueCompletionData,
      appearDisappearTranslation: appearDisappearTranslation,
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
    return LevelConfig(
      questions: questions,
      timerSeconds: (json['timer_seconds'] as num?)?.toInt(),
    );
  }
}
