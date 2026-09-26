import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/app_flavor.dart';
import 'package:english_quiz_game/app_theme.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/screens/quiz_templates/dialogue_completion_quiz_body.dart';
import 'package:english_quiz_game/services/question_layout_budget.dart';
import 'package:english_quiz_game/widgets/mcq_pill_answer_button.dart';
import 'package:english_quiz_game/widgets/standard_question_media.dart';

Future<void> _loadInterFont() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes =
        File('assets/fonts/inter/Inter-$weight.ttf').readAsBytesSync();
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
  DeviceSpec('iPhone SE (375x667)', Size(375, 667),
      EdgeInsets.only(top: 20, bottom: 0)),
  DeviceSpec('iPhone 14/15/16 (390x844)', Size(390, 844),
      EdgeInsets.only(top: 47, bottom: 34)),
  DeviceSpec('Galaxy SuperTall (412x915)', Size(412, 915),
      EdgeInsets.only(top: 36, bottom: 24)),
  DeviceSpec('iPad 4:3 (768x1024)', Size(768, 1024),
      EdgeInsets.only(top: 24, bottom: 20)),
  DeviceSpec('Tablet 16:10 (800x1280)', Size(800, 1280),
      EdgeInsets.only(top: 24, bottom: 20)),
  DeviceSpec('iPad Pro 12.9 (1024x1366)', Size(1024, 1366),
      EdgeInsets.only(top: 24, bottom: 20)),
];

final questions = [
  // Q1: Long prompt, regular 1-line answers (4 options)
  (
    name: 'Q1 Long Prompt 1-Line Answers',
    data: DialogueCompletionQuestionData(
      character1: 'char1',
      character2: 'char2',
      line1:
          'Long Test line one for DialogueCompletion, is this long enough to wrap two lines on a narrow phone?',
      answer: 'Test correct answer',
      distractors: [
        'Test wrong answer one',
        'Test wrong answer two',
        'Test wrong answer three',
      ],
      imageName: 'test-placeholder-dialogue-completion',
    ),
  ),
  // Q2: Short prompt, ultra short answers (4 options)
  (
    name: 'Q2 Short Prompt Short Answers',
    data: DialogueCompletionQuestionData(
      character1: 'char1',
      character2: 'char2',
      line1: 'Hi!',
      answer: 'Hello!',
      distractors: [
        'Goodbye.',
        'Thanks.',
        'Sorry.',
      ],
      imageName: 'test-placeholder-dialogue-completion',
    ),
  ),
  // Q3: Short prompt, 2-line wrapped answers (4 options)
  (
    name: 'Q3 2-Line Long Answers',
    data: DialogueCompletionQuestionData(
      character1: 'char1',
      character2: 'char2',
      line1: 'Where are you going after the lesson?',
      answer:
          'I am going to the community library to return several books and study.',
      distractors: [
        'I am going to the large sports center near the train station to meet friends.',
        'I am staying at home because I need to finish a project before dinner.',
        'I am visiting the new neighborhood market to buy everything we need.',
      ],
      imageName: 'test-placeholder-dialogue-completion',
    ),
  ),
  // Q4: Ultra-long prompt (upward cascade), medium answers (4 options)
  (
    name: 'Q4 Cascade Prompt Upward Extension',
    data: DialogueCompletionQuestionData(
      character1: 'char1',
      character2: 'char2',
      line1:
          'Could you please explain which answer would be most appropriate here, considering the conversation, the speaker\'s intention, and the information given in the question?',
      answer: 'Yes, I can explain it clearly.',
      distractors: [
        'No, that is not the right response.',
        'Maybe we should listen to the question again.',
        'I am not sure which answer belongs here.',
      ],
      imageName: 'test-placeholder-dialogue-completion',
    ),
  ),
  // Q5: 3-Button Option Count ($N=3$)
  (
    name: 'Q5 3-Option Count',
    data: DialogueCompletionQuestionData(
      character1: 'char1',
      character2: 'char2',
      line1: 'Is this your new car?',
      answer: 'Yes, I just bought it yesterday.',
      distractors: [
        'No, it belongs to my neighbor.',
        'I think it is parked over there.',
      ],
      imageName: 'test-placeholder-dialogue-completion',
    ),
  ),
  // Q6: 2-Button Option Count ($N=2$)
  (
    name: 'Q6 2-Option Count',
    data: DialogueCompletionQuestionData(
      character1: 'char1',
      character2: 'char2',
      line1: 'Do you want to come with us to the cinema?',
      answer: 'Sure, I would love to join you!',
      distractors: [
        'Sorry, I have other plans tonight.',
      ],
      imageName: 'test-placeholder-dialogue-completion',
    ),
  ),
  // Q7: 5-Button Stress Option Count ($N=5$)
  (
    name: 'Q7 5-Option Stress Count',
    data: DialogueCompletionQuestionData(
      character1: 'char1',
      character2: 'char2',
      line1: 'What time is the meeting tomorrow?',
      answer: 'It starts at nine o\'clock in the morning.',
      distractors: [
        'We will meet at ten o\'clock.',
        'The meeting is at eleven.',
        'It is postponed until tomorrow afternoon.',
        'I have not received the schedule yet.',
      ],
      imageName: 'test-placeholder-dialogue-completion',
    ),
  ),
  // Q8: Extreme multi-line long options stress fixture (3+ lines per button)
  (
    name: 'Q8 Multi-Line Long Option Stress',
    data: DialogueCompletionQuestionData(
      character1: 'char1',
      character2: 'char2',
      line1: 'Could you give us a full summary of the conference?',
      answer:
          'The keynote speaker covered modern technological advancements across artificial intelligence, robotics, and cloud infrastructure for the upcoming decade.',
      distractors: [
        'Several presenters discussed the international economic climate, trade agreements between member nations, and global sustainability targets.',
        'The panel debated regulatory frameworks for distributed computing systems and ethical guidelines in modern autonomous machine learning research.',
        'A comprehensive workshop was held detailing enterprise data protection protocols, network security measures, and compliance strategies.',
      ],
      imageName: 'test-placeholder-dialogue-completion',
    ),
  ),
  // Q9: Dual Long Text Stress (3-Line Prompt + 2-Line Long Answers)
  (
    name: 'Q9 Dual Prompt & Options Long Text Stress',
    data: DialogueCompletionQuestionData(
      character1: 'char1',
      character2: 'char2',
      line1:
          'Before we make a final decision regarding the renovation of our community center, what was the most important point raised by the committee?',
      answer:
          'They strongly recommended prioritizing structural repairs and installing energy-efficient windows throughout the building.',
      distractors: [
        'They suggested postponing the entire project until next summer when additional municipal funds might become available.',
        'They proposed converting the adjacent outdoor garden into an extra parking facility for weekend visitors and staff members.',
        'They advised hiring an independent architectural consulting firm to re-evaluate the estimated construction timeline.',
      ],
      imageName: 'test-placeholder-dialogue-completion',
    ),
  ),
  // Q10: 5-Line Ultra-Long Dialogue Prompt with Short Answers
  (
    name: 'Q10 5-Line Ultra-Long Dialogue Prompt',
    data: DialogueCompletionQuestionData(
      character1: 'char1',
      character2: 'char2',
      line1:
          'When you look at all the available options presented in the lesson today, including both the grammar rules and vocabulary definitions we discussed earlier this morning, which one seems to be the most accurate explanation for the speaker\'s decision to decline the invitation?',
      answer: 'She had to finish an urgent assignment.',
      distractors: [
        'She felt too exhausted after work.',
        'She already had prior family dinner plans.',
        'She was waiting for an important delivery.',
      ],
      imageName: 'test-placeholder-dialogue-completion',
    ),
  ),
  // Q11: Real-World Academic Discourse (Complex multi-line options with audio)
  (
    name: 'Q11 Academic Discourse Long Text',
    data: DialogueCompletionQuestionData(
      character1: 'char1',
      character2: 'char2',
      line1: 'How did the research team interpret the experimental results?',
      answer:
          'The observed data strongly supported the initial hypothesis regarding neural plasticity under continuous cognitive stimulation.',
      distractors: [
        'The team concluded that environmental factors exerted a far greater influence than previously anticipated in literature.',
        'Statistical analysis revealed significant discrepancies between the control group and the actively monitored participants.',
        'Further longitudinal investigations will be required before any definitive conclusions can be formally published.',
      ],
      imageName: 'test-placeholder-dialogue-completion',
    ),
  ),
];

Widget buildTestHarness({
  required DialogueCompletionQuestionData question,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: DialogueCompletionQuizBody(
                        data: question,
                        userLanguage: 'en',
                        imagePath: 'assets/test.png',
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
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadInterFont();
  });

  for (var qIdx = 0; qIdx < questions.length; qIdx++) {
    final q = questions[qIdx];
    group('${q.name} (Q${qIdx + 1})', () {
      for (final device in devices) {
        testWidgets('on ${device.name}', (tester) async {
          tester.view.physicalSize = device.size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            buildTestHarness(
              question: q.data,
              size: device.size,
              safeArea: device.safeArea,
            ),
          );
          await tester.pumpAndSettle();

          final mediaFinder = find.byType(StandardQuestionMedia);
          final mediaSize = tester.getSize(mediaFinder);

          final buttonFinders = find.byType(McqPillAnswerButton);
          final totalExpectedOptions =
              1 + q.data.distractors.length;
          expect(buttonFinders, findsNWidgets(totalExpectedOptions));
          final button0Size = tester.getSize(buttonFinders.first);

          final promptTextFinder = find.text(q.data.line1);
          expect(promptTextFinder, findsOneWidget);
          final promptWidget = tester.widget<Text>(promptTextFinder);
          final promptFontSize = promptWidget.style?.fontSize;

          final firstBtn =
              tester.widget<McqPillAnswerButton>(buttonFinders.first);
          final btnFontSize = firstBtn.fontSize;

          // Check Scroll on buttons box
          final scrollableFinders = find.byType(Scrollable);
          double scrollExtent = 0.0;
          if (scrollableFinders.evaluate().isNotEmpty) {
            for (final scrollable in scrollableFinders.evaluate()) {
              final state = tester.state<ScrollableState>(
                  find.byWidget(scrollable.widget));
              if (state.position.maxScrollExtent > scrollExtent) {
                scrollExtent = state.position.maxScrollExtent;
              }
            }
          }

          expect(tester.takeException(), isNull);

          final scrollLabel =
              scrollExtent > 0 ? "${scrollExtent.toStringAsFixed(1)}px" : "NO";
          // ignore: avoid_print
          print(
              'VISUAL_TEST: Q${qIdx + 1} | ${device.name.padRight(28)} | Media: ${mediaSize.width.toStringAsFixed(0)}x${mediaSize.height.toStringAsFixed(0)} | PromptFont: ${promptFontSize?.toStringAsFixed(1)}sp | BtnFont: ${btnFontSize?.toStringAsFixed(1)}sp | BtnSize: ${button0Size.width.toStringAsFixed(0)}x${button0Size.height.toStringAsFixed(0)} | Scroll: $scrollLabel');
        });
      }
    });
  }
}
