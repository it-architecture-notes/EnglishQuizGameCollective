import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/app_flavor.dart';
import 'package:english_quiz_game/app_theme.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/screens/quiz_templates/video_conversation_quiz_body.dart';

Future<void> _loadInterFont() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/inter/Inter-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadInterFont();
  });

  Widget buildHarness({
    required VideoConversationQuestionData data,
    required VoidCallback onPlayCorrect,
    required VoidCallback onPlayWrong,
    required void Function(bool) onOutcome,
  }) {
    return MaterialApp(
      theme: AppTheme.forFlavor(AppFlavor.adultsIntermediate),
      home: Scaffold(
        body: VideoConversationQuizBody(
          data: data,
          controller: null, // Headless test harness
          onPlayCorrect: onPlayCorrect,
          onPlayWrong: onPlayWrong,
          onOutcome: onOutcome,
        ),
      ),
    );
  }

  Future<void> tapAvailableChoiceTile(WidgetTester tester, String word) async {
    final finder = find.descendant(
      of: find.byWidgetPredicate((w) => w is InkWell && w.onTap != null),
      matching: find.text(word),
    );
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  testWidgets('Video DialogueCompletion: correct pick triggers success', (tester) async {
    var playCorrectCalled = false;
    var playWrongCalled = false;
    bool? outcomeResult;

    const question = VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      choiceData: VideoChoiceAnswerData(
        answer: 'Yes, absolutely.',
        distractors: ['No way.', 'Maybe later.'],
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => playWrongCalled = true,
        onOutcome: (res) => outcomeResult = res,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yes, absolutely.'), findsOneWidget);
    await tester.tap(find.text('Yes, absolutely.'));
    await tester.pumpAndSettle();

    expect(playCorrectCalled, isTrue);
    expect(playWrongCalled, isFalse);
    expect(outcomeResult, isTrue);
  });

  testWidgets('Video DialogueCompletion: wrong pick triggers failure', (tester) async {
    var playCorrectCalled = false;
    var playWrongCalled = false;
    bool? outcomeResult;

    const question = VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      choiceData: VideoChoiceAnswerData(
        answer: 'Good morning.',
        distractors: ['Good night.', 'See you.'],
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => playWrongCalled = true,
        onOutcome: (res) => outcomeResult = res,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Good night.'));
    await tester.pumpAndSettle();

    expect(playWrongCalled, isTrue);
    expect(playCorrectCalled, isFalse);
    expect(outcomeResult, isFalse);
  });

  testWidgets('Video DialogueCompletion: 2-options minimum clamp boundary', (tester) async {
    var playCorrectCalled = false;
    bool? outcomeResult;

    const question = VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      choiceData: VideoChoiceAnswerData(
        answer: 'True.',
        distractors: ['False.'],
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => {},
        onOutcome: (res) => outcomeResult = res,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('True.'), findsOneWidget);
    expect(find.text('False.'), findsOneWidget);

    await tester.tap(find.text('True.'));
    await tester.pumpAndSettle();

    expect(playCorrectCalled, isTrue);
    expect(outcomeResult, isTrue);
  });

  testWidgets('Video DialogueCompletion: 5-options high count stress', (tester) async {
    var playCorrectCalled = false;
    bool? outcomeResult;

    const question = VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      choiceData: VideoChoiceAnswerData(
        answer: 'Option A is correct.',
        distractors: ['Option B', 'Option C', 'Option D', 'Option E'],
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => {},
        onOutcome: (res) => outcomeResult = res,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Option A is correct.'), findsOneWidget);
    expect(find.text('Option E'), findsOneWidget);

    await tester.tap(find.text('Option A is correct.'));
    await tester.pumpAndSettle();

    expect(playCorrectCalled, isTrue);
    expect(outcomeResult, isTrue);
  });

  testWidgets('Video SentenceBuilder: step-by-step taps complete successfully', (tester) async {
    var playCorrectCalled = false;
    bool? outcomeResult;

    const question = VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      sequenceData: VideoSequenceAnswerData(
        targetSentence: 'Where is my coat',
        distractors: ['bag', 'hat'],
        isRecall: false,
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => {},
        onOutcome: (res) => outcomeResult = res,
      ),
    );
    await tester.pumpAndSettle();

    for (final word in ['Where', 'is', 'my', 'coat']) {
      await tapAvailableChoiceTile(tester, word);
    }

    expect(playCorrectCalled, isTrue);
    expect(outcomeResult, isTrue);
  });

  testWidgets('Video SentenceBuilder: wrong tap triggers failure and auto-fills slots', (tester) async {
    var playWrongCalled = false;
    bool? outcomeResult;

    const question = VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      sequenceData: VideoSequenceAnswerData(
        targetSentence: 'Open the window please',
        distractors: ['door', 'close'],
        isRecall: false,
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => {},
        onPlayWrong: () => playWrongCalled = true,
        onOutcome: (res) => outcomeResult = res,
      ),
    );
    await tester.pumpAndSettle();

    // Tap wrong distractor "door" first
    await tapAvailableChoiceTile(tester, 'door');

    expect(playWrongCalled, isTrue);
    expect(outcomeResult, isFalse);
  });

  testWidgets('Video SentenceBuilder: single-word minimal boundary (1 word + 1 distractor)', (tester) async {
    var playCorrectCalled = false;
    bool? outcomeResult;

    const question = VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      sequenceData: VideoSequenceAnswerData(
        targetSentence: 'Stop!',
        distractors: ['Go!'],
        isRecall: false,
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => {},
        onOutcome: (res) => outcomeResult = res,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stop!'), findsOneWidget);
    expect(find.text('Go!'), findsOneWidget);

    await tapAvailableChoiceTile(tester, 'Stop!');

    expect(playCorrectCalled, isTrue);
    expect(outcomeResult, isTrue);
  });

  testWidgets('Video SentenceBuilder: duplicate identical words in sentence resolved in order', (tester) async {
    var playCorrectCalled = false;
    bool? outcomeResult;

    const question = VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      sequenceData: VideoSequenceAnswerData(
        targetSentence: 'that is that',
        distractors: ['this'],
        isRecall: false,
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => {},
        onOutcome: (res) => outcomeResult = res,
      ),
    );
    await tester.pumpAndSettle();

    await tapAvailableChoiceTile(tester, 'that');
    await tapAvailableChoiceTile(tester, 'is');
    await tapAvailableChoiceTile(tester, 'that');

    expect(playCorrectCalled, isTrue);
    expect(outcomeResult, isTrue);
  });

  testWidgets('Video AppearDisappear: recall sequence step-by-step taps', (tester) async {
    var playCorrectCalled = false;
    bool? outcomeResult;

    const question = VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      sequenceData: VideoSequenceAnswerData(
        targetSentence: 'I see a bird',
        distractors: ['dog', 'cat'],
        isRecall: true,
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => {},
        onOutcome: (res) => outcomeResult = res,
      ),
    );
    await tester.pumpAndSettle();

    for (final word in ['I', 'see', 'a', 'bird']) {
      await tapAvailableChoiceTile(tester, word);
    }

    expect(playCorrectCalled, isTrue);
    expect(outcomeResult, isTrue);
  });

  testWidgets('Video ClozeSequence: step-by-step blank completion', (tester) async {
    var playCorrectCalled = false;
    bool? outcomeResult;

    const question = VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      clozeData: VideoClozeAnswerData(
        sentence: 'I will ___ coffee and ___ tea.',
        answers: ['drink', 'pour'],
        distractors: ['eat', 'cook'],
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => {},
        onOutcome: (res) => outcomeResult = res,
      ),
    );
    await tester.pumpAndSettle();

    await tapAvailableChoiceTile(tester, 'drink');
    await tapAvailableChoiceTile(tester, 'pour');

    expect(playCorrectCalled, isTrue);
    expect(outcomeResult, isTrue);
  });

  testWidgets('Video ClozeSequence: wrong tile selection triggers error and auto-fills blanks', (tester) async {
    var playWrongCalled = false;
    bool? outcomeResult;

    const question = VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      clozeData: VideoClozeAnswerData(
        sentence: 'Please turn on the ___ and open the ___.',
        answers: ['lights', 'window'],
        distractors: ['music', 'curtain'],
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => {},
        onPlayWrong: () => playWrongCalled = true,
        onOutcome: (res) => outcomeResult = res,
      ),
    );
    await tester.pumpAndSettle();

    // Tap wrong distractor "music"
    await tapAvailableChoiceTile(tester, 'music');

    expect(playWrongCalled, isTrue);
    expect(outcomeResult, isFalse);
  });
}
