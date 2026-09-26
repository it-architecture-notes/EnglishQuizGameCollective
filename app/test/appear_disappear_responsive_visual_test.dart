import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/app_flavor.dart';
import 'package:english_quiz_game/app_theme.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/screens/quiz_templates/appear_disappear_quiz_body.dart';
import 'package:english_quiz_game/services/question_layout_budget.dart';

// `flutter test` never loads the real app font unless told to — it silently substitutes a
// fallback test font with different glyph metrics, which can make short text appear to wrap to
// extra lines that never actually happen on a real device. Load the real Inter font so every
// measurement in this suite matches what the app actually renders.
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
  // Q1: Short sentence, short prompt (within normal production range).
  (
    name: 'Q1 Short Sentence & Prompt',
    data: const AppearDisappearQuestionData(
      words: ['I', 'am', 'ready'],
      distractors: ['you', 'they', 'we'],
      line1: 'Listen and remember the words.',
      imageName: 'test-placeholder-appear-disappear-short',
    ),
    audio1: null,
    audio2: null,
  ),
  // Q2: No line1 (bare recall sentence).
  (
    name: 'Q2 Bare Sentence No Prompt',
    data: const AppearDisappearQuestionData(
      words: ['This', 'is', 'a', 'short', 'sentence'],
      distractors: ['that', 'was', 'long'],
      imageName: 'test-placeholder-appear-disappear-bare',
    ),
    audio1: null,
    audio2: null,
  ),
  // Q3: Unusually long unbroken words in both the sentence and distractors.
  (
    name: 'Q3 Unusually Long Words',
    data: const AppearDisappearQuestionData(
      words: ['antidisestablishmentarianism', 'is', 'a', 'word'],
      distractors: ['pneumonoultramicroscopicsilicovolcanoconiosis', 'floccinaucinihilipilification', 'supercalifragilisticexpialidocious'],
      line1: 'Can you remember these unusually long words?',
      imageName: 'test-placeholder-appear-disappear-long-words',
    ),
    audio1: null,
    audio2: null,
  ),
  // Q4: Near the audited production maximum (10 words, 5 distractors = 15 tiles).
  (
    name: 'Q4 Near Production Maximum (10 words, 5 distractors)',
    data: const AppearDisappearQuestionData(
      words: [
        'I',
        'have',
        'been',
        'feeling',
        'some',
        'sensitivity',
        'on',
        'the',
        'lower',
        'left'
      ],
      distractors: ['sharp', 'upper', 'right', 'noticed', 'yesterday'],
      line1: 'Listen carefully and remember every word in order.',
      imageName: 'test-placeholder-appear-disappear-max',
    ),
    audio1: 'test-audio-line-1',
    audio2: 'test-audio-line-2-or-answer',
  ),
  // Q5: Dual audio setup & confirm clip pair.
  (
    name: 'Q5 Dual Audio',
    data: const AppearDisappearQuestionData(
      words: ['We', 'are', 'going', 'to', 'the', 'park'],
      distractors: ['store', 'school', 'beach'],
      line1: 'Where are they going today?',
      imageName: 'test-placeholder-appear-disappear-audio',
    ),
    audio1: 'test-audio-setup',
    audio2: 'test-audio-confirm',
  ),
  // Q6: Baseline production-shaped question, no image.
  (
    name: 'Q6 No Image Baseline',
    data: const AppearDisappearQuestionData(
      words: ['Whose', 'coat', 'is', 'this'],
      distractors: ['bag', 'shoe', 'hat'],
      line1: 'A question about ownership.',
    ),
    audio1: null,
    audio2: null,
  ),
  // Q7: Deliberately beyond the audited cap (20 words, 6 distractors = 26 tiles, plus a long
  // prompt line simultaneously) to verify the cascade extension engages, and — if it's not
  // enough — that the last-resort scroll engages cleanly without a crash or clipped content.
  (
    name: 'Q7 Beyond Cap Stress (20 words, 6 distractors)',
    data: const AppearDisappearQuestionData(
      words: [
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
      distractors: [
        'yesterday',
        'tomorrow',
        'slowly',
        'suddenly',
        'carefully',
        'happily'
      ],
      line1: 'This prompt line is intentionally long and wordy on its own, even though the sentence below is already far beyond the normal supported range for this template.',
      imageName: 'test-placeholder-appear-disappear-beyond-cap',
    ),
    audio1: null,
    audio2: null,
  ),
];

Widget buildTestHarness({
  required AppearDisappearQuestionData question,
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
                  Container(
                    height: budget.headerHeight,
                    color: Colors.blue.shade100,
                    alignment: Alignment.center,
                    child: const Text('Header'),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: AppearDisappearQuizBody(
                        data: question,
                        userLanguage: 'en',
                        imagePath: question.imageName != null ? 'assets/test.png' : null,
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
      testWidgets('AppearDisappear $qName (${fixture.name}) on ${device.name}', (tester) async {
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

        // Reveal → clear → interaction phase timing: reveal holds for
        // `words.length * 400ms`, then 400ms clearing, before the tile bank becomes
        // interactive. Settle well past that so the real interaction-phase tree is measured.
        await tester.pump();
        await tester.pump(
          Duration(milliseconds: (fixture.data.words.length * 400) + 900),
        );

        expect(tester.takeException(), isNull, reason: 'Layout overflow or exception detected');

        // Confirm the tile bank actually rendered real content — not a loading/empty shell.
        for (final word in [...fixture.data.words, ...fixture.data.distractors]) {
          expect(find.text(word), findsWidgets,
              reason: 'Tile "$word" must be rendered on screen!');
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
        debugPrint('VISUAL_TEST: $qName | ${device.name.padRight(28)} | Scroll: $scrollStr');
      });
    }
  }
}
