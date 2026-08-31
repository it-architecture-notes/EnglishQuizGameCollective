import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/app_flavor.dart';
import 'package:english_quiz_game/app_theme.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/screens/quiz_templates/sentence_builder_quiz_body.dart';

void main() {
  const testQuestion = SentenceBuilderQuestionData(
    line1: 'Whose coat is this?',
    correctOrder: ['I', "don't", 'know.'],
    imageName: 'test-image',
  );

  Widget buildHarness({
    required SentenceBuilderQuestionData data,
    required VoidCallback onPlayCorrect,
    required VoidCallback onPlayWrong,
    required void Function(bool) onOutcome,
    String? audio1Path,
    String? audio2Path,
  }) {
    return MaterialApp(
      theme: AppTheme.forFlavor(AppFlavor.adults),
      home: Scaffold(
        body: SentenceBuilderQuizBody(
          data: data,
          strings: const {},
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

  testWidgets('SentenceBuilder: correct step-by-step sequence completes successfully', (tester) async {
    var playCorrectCalled = false;
    var playWrongCalled = false;
    bool? finalOutcome;

    await tester.pumpWidget(
      buildHarness(
        data: testQuestion,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => playWrongCalled = true,
        onOutcome: (outcome) => finalOutcome = outcome,
      ),
    );
    await tester.pumpAndSettle();

    // Tap word 1: "I"
    await tester.tap(find.text('I'));
    await tester.pumpAndSettle();
    expect(playWrongCalled, isFalse);
    expect(finalOutcome, isNull);

    // Tap word 2: "don't"
    await tester.tap(find.text("don't"));
    await tester.pumpAndSettle();
    expect(playWrongCalled, isFalse);
    expect(finalOutcome, isNull);

    // Tap word 3: "know."
    await tester.tap(find.text('know.'));
    await tester.pumpAndSettle();

    expect(playCorrectCalled, isTrue);
    expect(playWrongCalled, isFalse);
    expect(finalOutcome, isTrue);
  });

  testWidgets('SentenceBuilder: wrong tile selection auto-fills slots and reports failure', (tester) async {
    var playCorrectCalled = false;
    var playWrongCalled = false;
    bool? finalOutcome;

    await tester.pumpWidget(
      buildHarness(
        data: testQuestion,
        onPlayCorrect: () => playCorrectCalled = true,
        onPlayWrong: () => playWrongCalled = true,
        onOutcome: (outcome) => finalOutcome = outcome,
      ),
    );
    await tester.pumpAndSettle();

    // Wrong tap: tap "know." first instead of "I"
    await tester.tap(find.text('know.'));
    await tester.pumpAndSettle();

    expect(playWrongCalled, isTrue);
    expect(playCorrectCalled, isFalse);
    expect(finalOutcome, isFalse);

    // All 3 words should now be visible in slots
    expect(find.text('I'), findsWidgets);
    expect(find.text("don't"), findsWidgets);
    expect(find.text('know.'), findsWidgets);
  });
}
