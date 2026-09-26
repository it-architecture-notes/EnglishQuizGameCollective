import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/app_flavor.dart';
import 'package:english_quiz_game/app_theme.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/screens/quiz_templates/appear_disappear_quiz_body.dart';

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
    required AppearDisappearQuestionData data,
    required VoidCallback onPlayCorrect,
    required VoidCallback onPlayWrong,
    required void Function(bool) onOutcome,
    String? audio1Path,
    String? audio2Path,
  }) {
    return MaterialApp(
      theme: AppTheme.forFlavor(AppFlavor.adultsIntermediate),
      home: Scaffold(
        body: AppearDisappearQuizBody(
          data: data,
          userLanguage: 'en',
          imagePath: 'assets/test.png',
          audio1Path: audio1Path,
          audio2Path: audio2Path,
          resolveAudioExists: (_) async => true,
          onPlayQuestionAudio: (_) async {},
          onPlayCorrect: onPlayCorrect,
          onPlayWrong: onPlayWrong,
          onOutcome: onOutcome,
        ),
      ),
    );
  }

  Future<void> transitionToInteraction(WidgetTester tester, int sentenceLength) async {
    final totalDuration = Duration(milliseconds: sentenceLength * 400 + 600);
    await tester.pump(totalDuration);
    await tester.pumpAndSettle();
  }

  Future<void> tapAvailableChoiceTile(WidgetTester tester, String word) async {
    final finder = find.descendant(
      of: find.byWidgetPredicate((w) => w is InkWell && w.onTap != null),
      matching: find.text(word),
    );
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  testWidgets('AppearDisappear: Phase transition from revealing to interaction', (tester) async {
    const question = AppearDisappearQuestionData(
      words: ['Good', 'morning'],
      distractors: ['night', 'evening'],
      line1: 'Say hello in the morning.',
    );

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () {},
        onPlayWrong: () {},
        onOutcome: (_) {},
      ),
    );

    // Initial frame: Revealing phase
    await tester.pump();
    expect(find.byType(AppearDisappearQuizBody), findsOneWidget);

    // Transition past reveal and clearing phases
    await transitionToInteraction(tester, question.words.length);

    // In interaction phase: choice tiles are visible in bank
    expect(find.descendant(of: find.byType(InkWell), matching: find.text('Good')), findsOneWidget);
    expect(find.descendant(of: find.byType(InkWell), matching: find.text('morning')), findsOneWidget);
    expect(find.descendant(of: find.byType(InkWell), matching: find.text('night')), findsOneWidget);
    expect(find.descendant(of: find.byType(InkWell), matching: find.text('evening')), findsOneWidget);
  });

  testWidgets('AppearDisappear: Correct step-by-step tile selection completes with success', (tester) async {
    const question = AppearDisappearQuestionData(
      words: ['I', 'am', 'here'],
      distractors: ['you', 'there'],
      line1: 'Where are you?',
    );

    var playCorrectCalled = false;
    var playWrongCalled = false;
    bool? outcomeResult;

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => playWrongCalled = true,
        onOutcome: (res) => outcomeResult = res,
      ),
    );

    await transitionToInteraction(tester, question.words.length);

    // Tap word 1: "I"
    await tapAvailableChoiceTile(tester, 'I');
    expect(playWrongCalled, isFalse);
    expect(outcomeResult, isNull);

    // Tap word 2: "am"
    await tapAvailableChoiceTile(tester, 'am');
    expect(playWrongCalled, isFalse);
    expect(outcomeResult, isNull);

    // Tap word 3: "here"
    await tapAvailableChoiceTile(tester, 'here');

    expect(playCorrectCalled, isTrue);
    expect(playWrongCalled, isFalse);
    expect(outcomeResult, isTrue);
  });

  testWidgets('AppearDisappear: Wrong tile selection triggers failure and auto-fills slots', (tester) async {
    const question = AppearDisappearQuestionData(
      words: ['She', 'likes', 'coffee'],
      distractors: ['tea', 'milk'],
      line1: 'What does she like?',
    );

    var playCorrectCalled = false;
    var playWrongCalled = false;
    bool? outcomeResult;

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => playWrongCalled = true,
        onOutcome: (res) => outcomeResult = res,
      ),
    );

    await transitionToInteraction(tester, question.words.length);

    // Tap wrong tile first: "tea" instead of "She"
    await tapAvailableChoiceTile(tester, 'tea');

    expect(playWrongCalled, isTrue);
    expect(playCorrectCalled, isFalse);
    expect(outcomeResult, isFalse);
  });

  testWidgets('AppearDisappear: Single-word sentence boundary condition (1 word + 1 distractor)', (tester) async {
    const question = AppearDisappearQuestionData(
      words: ['Stop!'],
      distractors: ['Go!'],
    );

    var playCorrectCalled = false;
    bool? outcomeResult;

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => {},
        onOutcome: (res) => outcomeResult = res,
      ),
    );

    await transitionToInteraction(tester, question.words.length);

    expect(find.descendant(of: find.byType(InkWell), matching: find.text('Stop!')), findsOneWidget);
    expect(find.descendant(of: find.byType(InkWell), matching: find.text('Go!')), findsOneWidget);

    await tapAvailableChoiceTile(tester, 'Stop!');

    expect(playCorrectCalled, isTrue);
    expect(outcomeResult, isTrue);
  });

  testWidgets('AppearDisappear: Duplicate identical words in sentence resolved in order', (tester) async {
    const question = AppearDisappearQuestionData(
      words: ['that', 'is', 'that'],
      distractors: ['this'],
    );

    var playCorrectCalled = false;
    var playWrongCalled = false;
    bool? outcomeResult;

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => playWrongCalled = true,
        onOutcome: (res) => outcomeResult = res,
      ),
    );

    await transitionToInteraction(tester, question.words.length);

    // Tap first "that"
    await tapAvailableChoiceTile(tester, 'that');
    expect(playWrongCalled, isFalse);

    // Tap "is"
    await tapAvailableChoiceTile(tester, 'is');
    expect(playWrongCalled, isFalse);

    // Tap remaining "that"
    await tapAvailableChoiceTile(tester, 'that');

    expect(playCorrectCalled, isTrue);
    expect(playWrongCalled, isFalse);
    expect(outcomeResult, isTrue);
  });

  testWidgets('AppearDisappear: Long complex sentence (10 words) step-by-step stress', (tester) async {
    const question = AppearDisappearQuestionData(
      words: ['We', 'must', 'protect', 'our', 'environment', 'for', 'the', 'future', 'of', 'humanity'],
      distractors: ['nature', 'planet', 'society'],
      line1: 'Remember the ecological statement.',
    );

    var playCorrectCalled = false;
    bool? outcomeResult;

    await tester.pumpWidget(
      buildHarness(
        data: question,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => {},
        onOutcome: (res) => outcomeResult = res,
      ),
    );

    await transitionToInteraction(tester, question.words.length);

    for (final word in question.words) {
      await tapAvailableChoiceTile(tester, word);
    }

    expect(playCorrectCalled, isTrue);
    expect(outcomeResult, isTrue);
  });
}
