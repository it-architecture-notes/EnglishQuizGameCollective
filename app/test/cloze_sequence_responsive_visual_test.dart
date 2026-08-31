import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/app_flavor.dart';
import 'package:english_quiz_game/app_theme.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/screens/quiz_templates/cloze_sequence_quiz_body.dart';
import 'package:english_quiz_game/services/question_layout_budget.dart';
import 'package:english_quiz_game/widgets/mcq_pill_answer_button.dart';

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
  // Q1: Conversational Long Lines 3-blank
  ClozeSequenceQuestionData(
    line1: 'Test prompt line for standalone ClozeSequence that is intentionally quite long and wordy, can you correctly fill in every single one of these blanks?',
    sentence: 'Even though it was raining, _____ _____ decided _____ go for a walk anyway because they wanted some fresh air.',
    answers: ['they', 'still', 'to'],
    distractors: ['those', 'from', 'with', 'about'],
    imageName: 'test-placeholder-cloze-sequence',
  ),
  // Q2: Conversational 5-option single blank (kids curriculum case)
  ClozeSequenceQuestionData(
    line1: 'Test prompt line for standalone ClozeSequence that is intentionally quite long and wordy, can you correctly fill in every single one of these blanks?',
    sentence: 'Even though it was raining, _____ decided go for a walk anyway because they wanted some fresh air.',
    answers: ['to'],
    distractors: ['those', 'from', 'with', 'about'],
    imageName: 'test-placeholder-cloze-sequence',
  ),
  // Q3: Conversational Long unbroken words 3-blank
  ClozeSequenceQuestionData(
    line1: 'Test prompt line for standalone ClozeSequence, can you spot the extraordinarily long test words?',
    sentence: 'That was _____ but also _____, according to the _____ report.',
    answers: [
      'supercalifragilisticexpialidocious',
      'unbelievable',
      'pneumonoultramicroscopicsilicovolcanoconiosis'
    ],
    distractors: [
      'antidisestablishmentarianism',
      'floccinaucinihilipilification',
      'incomprehensibilities',
      'counterrevolutionaries'
    ],
    imageName: 'test-placeholder-cloze-sequence',
  ),
  // Q4: Conversational Single blank 4 options (2x2 grid)
  ClozeSequenceQuestionData(
    line1: 'Test prompt line for standalone ClozeSequence, single blank with four answer tiles?',
    sentence: 'No, this is _____ correct.',
    answers: ['not'],
    distractors: ['very', 'quite', 'really'],
    imageName: 'test-placeholder-cloze-sequence',
  ),
  // Q5: Conversational Regular 3-blank
  ClozeSequenceQuestionData(
    line1: 'Test prompt line for standalone ClozeSequence, are these your test tiles?',
    sentence: 'No, _____ _____ not. These are _____ testing.',
    answers: ['they', 'are', 'for'],
    distractors: ['those', 'from', 'with', 'about'],
    imageName: 'test-placeholder-cloze-sequence',
  ),
  // Q6: Bare cloze (no line1) 2-blank multi-tile
  ClozeSequenceQuestionData(
    sentence: 'This is a bare cloze testing sentence without any introductory prompt line where we fill in _____ and _____ words.',
    answers: ['missing', 'correct'],
    distractors: ['wrong', 'extra', 'other'],
    imageName: 'test-placeholder-cloze-sequence',
  ),
  // Q7: Bare cloze (no line1) single blank 4 options (2x2 grid)
  ClozeSequenceQuestionData(
    sentence: 'This bare cloze sentence has _____ introductory line.',
    answers: ['no'],
    distractors: ['a', 'an', 'some'],
    imageName: 'test-placeholder-cloze-sequence',
  ),
  // Q8: Bare cloze (no line1) long multi-line sentence 3-blank
  ClozeSequenceQuestionData(
    sentence: 'Even though this bare cloze sentence has no introductory prompt line at all, it still needs to be _____ long enough that it _____ wraps across several lines and _____ the dialogue card to extend upward over the image.',
    answers: ['quite', 'genuinely', 'forces'],
    distractors: ['barely', 'rarely', 'avoids', 'shrinks'],
    imageName: 'test-placeholder-cloze-sequence',
  ),
  // Q9: Bare cloze (no line1) single blank extreme long word
  ClozeSequenceQuestionData(
    sentence: 'This bare cloze sentence has an extraordinarily long test word: _____.',
    answers: ['pseudopseudohypoparathyroidism'],
    distractors: [
      'hippopotomonstrosesquippedaliophobia',
      'floccinaucinihilipilification',
      'antidisestablishmentarianism'
    ],
    imageName: 'test-placeholder-cloze-sequence',
  ),
];

Widget buildTestHarness({
  required ClozeSequenceQuestionData question,
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
      // Real app theme, not a generic ThemeData(fontFamily: 'Inter') — the generic theme's
      // default Material 3 bodyMedium (14px) masked a real bug where tile text (16px in the
      // actual app_theme.dart) rendered bigger than the dialogue text on several tiers.
      theme: AppTheme.forFlavor(AppFlavor.adults),
      home: Scaffold(
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final budget = QuestionLayoutBudget.of(context);
              return Column(
                children: [
                  // App Bar / Header region
                  Container(
                    height: budget.headerHeight,
                    color: Colors.blue.shade100,
                    alignment: Alignment.center,
                    child: const Text('Header'),
                  ),
                  // Body region
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: ClozeSequenceQuizBody(
                        data: question,
                        userLanguage: 'en',
                        imagePath: 'assets/test.png', // has image
                        resolveAudioExists: (_) async => false,
                        onPlayQuestionAudio: (_) async {},
                        onPlayCorrect: () {},
                        onPlayWrong: () {},
                        onOutcome: (_) {},
                      ),
                    ),
                  ),
                  // Footer / Next region
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
    final q = testQuestions[qIdx];
    final qName = 'Q${qIdx + 1}';

    for (final device in devices) {
      testWidgets('ClozeSequence $qName on ${device.name}', (tester) async {
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
            question: q,
            size: device.size,
            safeArea: device.safeArea,
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull, reason: 'Layout overflow or exception detected');

        // Confirm that for single-blank questions, every option is rendered on screen
        if (q.answers.length == 1) {
          final expectedAnswer = q.answers.first;
          expect(find.text(expectedAnswer), findsWidgets, reason: 'Correct answer "$expectedAnswer" must be rendered on screen!');
          for (final d in q.distractors) {
            expect(find.text(d), findsWidgets, reason: 'Distractor "$d" must be rendered on screen!');
          }
          // Validate button touch target sizes >= 44px
          final buttons = find.byType(McqPillAnswerButton);
          for (final btn in buttons.evaluate()) {
            final renderBox = btn.renderObject as RenderBox;
            expect(renderBox.size.height, greaterThanOrEqualTo(44.0), reason: 'MCQ Button touch target must be >= 44px');
          }
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
