import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/app_flavor.dart';
import 'package:english_quiz_game/app_theme.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/screens/quiz_templates/sentence_builder_quiz_body.dart';
import 'package:english_quiz_game/services/question_layout_budget.dart';

// `flutter test` never loads the real app font unless told to — it silently substitutes a
// fallback test font with different glyph metrics, which previously made short prompts appear
// to wrap to extra lines that never actually happen on a real device. Load the real Inter font
// so every measurement in this suite matches what the app actually renders.
Future<void> _loadInterFont() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/inter/Inter-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

class DeviceSpec {
  final String name;
  final Size size;
  final EdgeInsets safeArea;
  const DeviceSpec(this.name, this.size, this.safeArea);
}

const devices = [
  DeviceSpec('iPhone SE (375x667)', Size(375, 667), EdgeInsets.only(top: 20, bottom: 0)),
  DeviceSpec('iPhone 14/15/16 (390x844)', Size(390, 844), EdgeInsets.only(top: 47, bottom: 34)),
  DeviceSpec('Galaxy SuperTall (412x915)', Size(412, 915), EdgeInsets.only(top: 36, bottom: 24)),
  DeviceSpec('iPad 4:3 (768x1024)', Size(768, 1024), EdgeInsets.only(top: 24, bottom: 20)),
  DeviceSpec('Tablet 16:10 (800x1280)', Size(800, 1280), EdgeInsets.only(top: 24, bottom: 20)),
  DeviceSpec('iPad Pro 12.9 (1024x1366)', Size(1024, 1366), EdgeInsets.only(top: 24, bottom: 20)),
];

final testQuestions = [
  // Q1: Short prompt & short sentence (3 words)
  (
    name: 'Q1 Short Prompt & Short Sentence',
    data: const SentenceBuilderQuestionData(
      line1: 'Short prompt.',
      correctOrder: ['I', 'am', 'ready'],
      imageName: 'test-placeholder-sentence-builder-short',
    ),
    audio1: null,
    audio2: null,
  ),
  // Q2: Bare sentence without line1 (5 words)
  (
    name: 'Q2 Bare Sentence',
    data: const SentenceBuilderQuestionData(
      line1: null,
      correctOrder: ['This', 'is', 'a', 'short', 'sentence'],
      imageName: 'test-placeholder-sentence-builder-bare',
    ),
    audio1: null,
    audio2: null,
  ),
  // Q3: Long prompt & long sentence (11 words)
  (
    name: 'Q3 Long Prompt & Long Sentence',
    data: const SentenceBuilderQuestionData(
      line1:
          'Test prompt line for standalone SentenceBuilder that is intentionally quite long and wordy, can you correctly assemble this sentence in order?',
      correctOrder: [
        'This',
        'is',
        'a',
        'long',
        'test',
        'sentence',
        'for',
        'the',
        'sentence',
        'builder',
        'tile',
        'layout'
      ],
      imageName: 'test-placeholder-sentence-builder-long-prompt',
    ),
    audio1: null,
    audio2: null,
  ),
  // Q4: Bare sentence with many words (11 words, tests tile wrapping)
  (
    name: 'Q4 Bare Many Words',
    data: const SentenceBuilderQuestionData(
      line1: null,
      correctOrder: [
        'This',
        'is',
        'a',
        'long',
        'sentence',
        'for',
        'testing',
        'tile',
        'layout',
        'on',
        'small',
        'screens'
      ],
      imageName: 'test-placeholder-sentence-builder-many-words',
    ),
    audio1: null,
    audio2: null,
  ),
  // Q5: Unusually long unbroken words (28 and 45 characters)
  (
    name: 'Q5 Unusually Long Words',
    data: const SentenceBuilderQuestionData(
      line1: 'Can you assemble the sentence with these unusually long words?',
      correctOrder: [
        'antidisestablishmentarianism',
        'pneumonoultramicroscopicsilicovolcanoconiosis'
      ],
      imageName: 'test-placeholder-sentence-builder-long-words',
    ),
    audio1: null,
    audio2: null,
  ),
  // Q6: Dual audio setup & confirm clip pair
  (
    name: 'Q6 Dual Audio',
    data: const SentenceBuilderQuestionData(
      line1:
          'Test prompt line for standalone SentenceBuilder, what does this test sentence say?',
      correctOrder: [
        'This',
        'is',
        'a',
        'long',
        'test',
        'sentence',
        'for',
        'the',
        'sentence',
        'builder',
        'tile',
        'layout'
      ],
      imageName: 'test-placeholder-sentence-builder',
    ),
    audio1: 'test-audio-line-1',
    audio2: 'test-audio-line-2-or-answer',
  ),
  // Q7: Extreme long prompt upward extension
  (
    name: 'Q7 Extreme Prompt Upward Extension',
    data: const SentenceBuilderQuestionData(
      line1:
          'Test prompt line for standalone SentenceBuilder that is intentionally quite long and wordy on its own, even though the sentence to assemble below stays short, does the prompt box extend upward correctly?',
      correctOrder: ['We', 'are', 'going', 'to', 'the', 'park', 'today'],
      imageName: 'test-placeholder-sentence-builder-long-prompt-only',
    ),
    audio1: null,
    audio2: null,
  ),
  // Q8: Baseline production question ("Whose coat is this?")
  (
    name: 'Q8 Baseline Production Whose Coat',
    data: const SentenceBuilderQuestionData(
      line1: 'Whose coat is this?',
      correctOrder: ['I', "don't", 'know.', 'It', 'is', 'not', 'mine.'],
      imageName: 'test-placeholder-sentence-builder-baseline',
    ),
    audio1: 'whose-coat-is-this-convo',
    audio2: 'i-dont-know-it-is-not-mine-convo',
  ),
  // Q9: Deliberately beyond the row cap (20 words — forces well past 3 tile rows and 2 slot
  // rows on every phone tier) to verify the cascade extension engages instead of scroll, not
  // just the ordinary within-cap cases every other fixture above exercises.
  (
    name: 'Q9 Beyond Cap Stress (20 words)',
    data: const SentenceBuilderQuestionData(
      line1: 'This sentence is intentionally far too long for any normal question.',
      correctOrder: [
        'The',
        'quick',
        'brown',
        'fox',
        'jumps',
        'over',
        'the',
        'lazy',
        'dog',
        'while',
        'the',
        'cat',
        'watches',
        'quietly',
        'from',
        'a',
        'nearby',
        'sunny',
        'window',
        'today'
      ],
      imageName: 'test-placeholder-sentence-builder-beyond-cap',
    ),
    audio1: null,
    audio2: null,
  ),
];

Widget buildTestHarness({
  required SentenceBuilderQuestionData question,
  String? audio1,
  String? audio2,
  required Size size,
  required EdgeInsets safeArea,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      padding: safeArea,
      textScaler: TextScaler.noScaling,
    ),
    child: MaterialApp(
      theme: AppTheme.forFlavor(AppFlavor.adultsIntermediate),
      home: Scaffold(
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final budget = QuestionLayoutBudget.of(context);
              return Column(
                children: [
                  // Header
                  Container(
                    height: budget.headerHeight,
                    color: Colors.blue.shade100,
                    alignment: Alignment.center,
                    child: const Text('Header'),
                  ),
                  // Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: SentenceBuilderQuizBody(
                        data: question,
                        strings: const {},
                        userLanguage: 'en',
                        imagePath: 'assets/test.png',
                        audio1Path: audio1,
                        audio2Path: audio2,
                        resolveAudioExists: (_) async => false,
                        onPlayQuestionAudio: (_) async {},
                        onPlayCorrect: () {},
                        onPlayWrong: () {},
                        onOutcome: (_) {},
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    height: budget.footerHeight,
                    color: Colors.green.shade100,
                    alignment: Alignment.center,
                    child: const Text('Next'),
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

void main() {
  for (var qIdx = 0; qIdx < testQuestions.length; qIdx++) {
    final fixture = testQuestions[qIdx];
    final qName = 'Q${qIdx + 1}';

    for (final device in devices) {
      testWidgets('SentenceBuilder $qName (${fixture.name}) on ${device.name}', (tester) async {
        await _loadInterFont();
        tester.view.physicalSize = device.size;
        tester.view.devicePixelRatio = 1.0;
        tester.view.padding = FakeViewPadding(
          top: device.safeArea.top,
          bottom: device.safeArea.bottom,
          left: device.safeArea.left,
          right: device.safeArea.right,
        );
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetPadding();
        });

        await tester.pumpWidget(
          buildTestHarness(
            question: fixture.data,
            audio1: fixture.audio1,
            audio2: fixture.audio2,
            size: device.size,
            safeArea: device.safeArea,
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull, reason: 'Layout overflow or exception detected');

        // Confirm every tile word exists on screen
        for (final word in fixture.data.correctOrder) {
          expect(find.text(word), findsWidgets, reason: 'Tile word "$word" must be rendered on screen!');
        }

        final scrollables = find.byType(Scrollable);
        double maxScrollExtent = 0.0;
        for (final scrollable in scrollables.evaluate()) {
          final element = scrollable as StatefulElement;
          final state = element.state;
          if (state is ScrollableState) {
            final maxScroll = state.position.maxScrollExtent;
            if (maxScroll > maxScrollExtent) {
              maxScrollExtent = maxScroll;
            }
          }
        }

        final scrollStr = maxScrollExtent > 0.0 ? '${maxScrollExtent.toStringAsFixed(1)}px' : 'NO';
        debugPrint('VISUAL_TEST: $qName | ${device.name.padRight(30)} | Scroll: $scrollStr');
      });
    }
  }
}
