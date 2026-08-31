import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/screens/quiz_templates/cloze_sequence_quiz_body.dart';

Widget buildHarness({
  required ClozeSequenceQuestionData question,
  required void Function(bool) onOutcome,
  required VoidCallback onPlayCorrect,
  required VoidCallback onPlayWrong,
}) {
  return MediaQuery(
    data: const MediaQueryData(
      size: Size(390, 844),
      textScaler: TextScaler.noScaling,
    ),
    child: MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Builder(
            builder: (context) {
              return Column(
                children: [
                  Expanded(
                    child: ClozeSequenceQuizBody(
                      data: question,
                      userLanguage: 'en',
                      imagePath: null,
                      resolveAudioExists: (_) async => false,
                      onPlayQuestionAudio: (_) async {},
                      onPlayCorrect: onPlayCorrect,
                      onPlayWrong: onPlayWrong,
                      onOutcome: onOutcome,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

String getSentencePlainText(WidgetTester tester) {
  final richTexts = tester.widgetList<RichText>(find.byType(RichText));
  for (final rt in richTexts) {
    final text = rt.text.toPlainText();
    if (text.contains('raining') || text.contains('walk') || text.contains('_____')) {
      return text;
    }
  }
  return '';
}

void main() {
  testWidgets('Multi-blank wrong tile tap fills all blanks with answers in italic', (tester) async {
    bool? outcomeResult;
    var wrongSoundPlayed = false;

    final question = ClozeSequenceQuestionData(
      line1: 'Where did they go?',
      sentence: 'Even though it was raining, _____ _____ decided _____ go for a walk.',
      answers: ['they', 'still', 'to'],
      distractors: ['those', 'from', 'with', 'about'],
      imageName: 'test-placeholder',
    );

    await tester.pumpWidget(
      buildHarness(
        question: question,
        onOutcome: (val) => outcomeResult = val,
        onPlayCorrect: () {},
        onPlayWrong: () => wrongSoundPlayed = true,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Initially, blanks (1), (2), (3) are unfilled in the RichText sentence
    var sentenceText = getSentencePlainText(tester);
    expect(sentenceText.contains('_____ (1)'), isTrue);
    expect(sentenceText.contains('_____ (2)'), isTrue);
    expect(sentenceText.contains('_____ (3)'), isTrue);

    // Tap a wrong distractor tile: 'those'
    await tester.tap(find.text('those'));
    await tester.pump();

    // Verify outcome & sound
    expect(wrongSoundPlayed, isTrue);
    expect(outcomeResult, isFalse);

    // Verify that all blanks in the sentence are now filled with the correct answers ('they', 'still', 'to')
    sentenceText = getSentencePlainText(tester);
    expect(sentenceText.contains('_____ (1)'), isFalse);
    expect(sentenceText.contains('_____ (2)'), isFalse);
    expect(sentenceText.contains('_____ (3)'), isFalse);
    expect(sentenceText.contains('they still decided to go for a walk'), isTrue);
  });

  testWidgets('Multi-blank correct sequence fills blanks step by step', (tester) async {
    bool? outcomeResult;
    var correctCount = 0;

    final question = ClozeSequenceQuestionData(
      line1: 'Where did they go?',
      sentence: 'Even though it was raining, _____ _____ decided _____ go for a walk.',
      answers: ['they', 'still', 'to'],
      distractors: ['those', 'from'],
      imageName: 'test-placeholder',
    );

    await tester.pumpWidget(
      buildHarness(
        question: question,
        onOutcome: (val) => outcomeResult = val,
        onPlayCorrect: () => correctCount++,
        onPlayWrong: () {},
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Step 1: tap 'they'
    await tester.tap(find.text('they'));
    await tester.pump();
    expect(correctCount, 1);
    expect(outcomeResult, isNull); // not completed yet
    var sentenceText = getSentencePlainText(tester);
    expect(sentenceText.contains('_____ (1)'), isFalse);
    expect(sentenceText.contains('they _____ (2)'), isTrue);

    // Step 2: tap 'still'
    await tester.tap(find.text('still'));
    await tester.pump();
    expect(correctCount, 2);
    expect(outcomeResult, isNull);
    sentenceText = getSentencePlainText(tester);
    expect(sentenceText.contains('_____ (2)'), isFalse);
    expect(sentenceText.contains('they still decided _____ (3)'), isTrue);

    // Step 3: tap 'to'
    await tester.tap(find.text('to'));
    await tester.pump();
    expect(correctCount, 3);
    expect(outcomeResult, isTrue); // completed successfully
    sentenceText = getSentencePlainText(tester);
    expect(sentenceText.contains('_____ (3)'), isFalse);
    expect(sentenceText.contains('they still decided to go for a walk'), isTrue);
  });
}
