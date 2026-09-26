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
  // Q1: Video DialogueCompletion (Standard 4 options)
  (
    name: 'Q1 Video DialogueCompletion (4 Options)',
    data: const VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      choiceData: VideoChoiceAnswerData(
        answer: "I'm going to the supermarket.",
        distractors: [
          'Yes, I like coffee very much.',
          'It is three o’clock now.',
          'They are waiting outside.',
        ],
      ),
    ),
  ),
  // Q2: Video DialogueCompletion (5 Options Stress / Long Text)
  (
    name: 'Q2 Video DialogueCompletion (5 Options Long Text)',
    data: const VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      choiceData: VideoChoiceAnswerData(
        answer: 'We should definitely finalize the quarterly financial report before Friday afternoon.',
        distractors: [
          'I completely agree with the architectural direction proposed by the lead engineer.',
          'Please ensure all team members submit their weekly updates on time.',
          'The conference call has been rescheduled for tomorrow morning at nine.',
          'They decided to postpone the deployment until next Tuesday.',
        ],
      ),
    ),
  ),
  // Q3: Video SentenceBuilder (Standard 4 words + 3 distractors)
  (
    name: 'Q3 Video SentenceBuilder (4 words + 3 distractors)',
    data: const VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      sequenceData: VideoSequenceAnswerData(
        targetSentence: 'Whose coat is this',
        distractors: ['bag', 'shoe', 'hat'],
        isRecall: false,
      ),
    ),
  ),
  // Q4: Video AppearDisappear (Recall 6 words + 4 distractors)
  (
    name: 'Q4 Video AppearDisappear (6 words + 4 distractors)',
    data: const VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      sequenceData: VideoSequenceAnswerData(
        targetSentence: 'I still feel so sleepy today',
        distractors: ['very', 'tired', 'early', 'awake'],
        isRecall: true,
      ),
    ),
  ),
  // Q5: Video SentenceBuilder Near-Max (10 words + 5 distractors = 15 tiles)
  (
    name: 'Q5 Video SentenceBuilder Near-Max (10 words + 5 distractors)',
    data: const VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      sequenceData: VideoSequenceAnswerData(
        targetSentence: 'I have been feeling some sensitivity on the lower left',
        distractors: ['sharp', 'upper', 'right', 'noticed', 'yesterday'],
        isRecall: false,
      ),
    ),
  ),
  // Q6: Video ClozeSequence (2 blanks + 4 distractors)
  (
    name: 'Q6 Video ClozeSequence (2 blanks)',
    data: const VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      clozeData: VideoClozeAnswerData(
        sentence: 'I need to ___ my teeth and ___ my hair.',
        answers: ['brush', 'comb'],
        distractors: ['wash', 'cut', 'dry', 'style'],
      ),
    ),
  ),
  // Q7: Video ClozeSequence Long Sentence (3 blanks + 6 distractors)
  (
    name: 'Q7 Video ClozeSequence Long Sentence (3 blanks)',
    data: const VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      clozeData: VideoClozeAnswerData(
        sentence: 'Before going to ___ we must turn off the ___ and lock the front ___.',
        answers: ['sleep', 'lights', 'door'],
        distractors: ['bed', 'oven', 'windows', 'gate', 'water', 'switch'],
      ),
    ),
  ),
  // Q8: Deliberately Beyond-Cap Pathological Stress (20 words, 6 distractors)
  (
    name: 'Q8 Video Beyond-Cap Stress (20 words, 6 distractors)',
    data: const VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      sequenceData: VideoSequenceAnswerData(
        targetSentence: 'The quick brown fox jumps over the lazy dog while the cat watches quietly from a nearby sunny window today',
        distractors: ['yesterday', 'tomorrow', 'slowly', 'suddenly', 'carefully', 'happily'],
        isRecall: false,
      ),
    ),
  ),
  // Q9: 2 Options Minimum Bound + 4-line wrapped paragraph
  (
    name: 'Q9 Video 2-Options Multi-Line Paragraph',
    data: const VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      choiceData: VideoChoiceAnswerData(
        answer: 'This answer option spans multiple comprehensive sentences designed specifically to verify that multiline wrapping and expanded button heights function seamlessly together on compact displays.',
        distractors: [
          'No, this alternative is brief.',
        ],
      ),
    ),
  ),
  // Q10: 6 Options Extreme Stress Count
  (
    name: 'Q10 Video 6-Options Extreme Count',
    data: const VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      choiceData: VideoChoiceAnswerData(
        answer: 'First primary option.',
        distractors: [
          'Second possible choice.',
          'Third alternate response.',
          'Fourth candidate sentence.',
          'Fifth prospective answer.',
          'Sixth overflow selection.',
        ],
      ),
    ),
  ),
  // Q11: Unbroken compound words & asymmetric tokens in SentenceBuilder
  (
    name: 'Q11 Video Unbroken Compound Words',
    data: const VideoConversationQuestionData(
      videoFile: 'test.mp4',
      startAt: Duration(seconds: 0),
      pauseAt: Duration(seconds: 3),
      sequenceData: VideoSequenceAnswerData(
        targetSentence: 'Uncharacteristically counterproductive telecommunication infrastructure',
        distractors: ['intergovernmental', 'environmentalists'],
        isRecall: false,
      ),
    ),
  ),
];

Widget buildTestHarness({
  required VideoConversationQuestionData question,
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
          child: VideoConversationQuizBody(
            data: question,
            controller: null, // Headless test harness - mounts answer panel immediately
            onPlayCorrect: () {},
            onPlayWrong: () {},
            onOutcome: (_) {},
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

  for (final q in testQuestions) {
    for (final dev in devices) {
      testWidgets('VideoConversation ${q.name} on ${dev.name}', (tester) async {
        tester.view.physicalSize = dev.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestHarness(
            question: q.data,
            size: dev.size,
            safeArea: dev.safeArea,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Assert body presence
        expect(find.byType(VideoConversationQuizBody), findsOneWidget);

        // 2. Assert answer components presence
        if (q.data.choiceData != null) {
          expect(find.text(q.data.choiceData!.answer), findsOneWidget);
          for (final dist in q.data.choiceData!.distractors) {
            expect(find.text(dist), findsOneWidget);
          }
        } else if (q.data.sequenceData != null) {
          final words = q.data.sequenceData!.targetSentence.split(' ');
          for (final w in words.take(3)) {
            expect(find.text(w), findsAtLeastNWidgets(1));
          }
        } else if (q.data.clozeData != null) {
          for (final ans in q.data.clozeData!.answers) {
            expect(find.text(ans), findsOneWidget);
          }
        }

        // 3. Measure scroll extent on the SingleChildScrollView
        final scrollable = tester.widget<Scrollable>(find.byType(Scrollable).first);
        final maxScroll = scrollable.controller?.position.maxScrollExtent ?? 0.0;
        final isPathological = q.name.contains('Beyond-Cap');

        if (!isPathological) {
          expect(maxScroll, 0.0,
              reason: '${q.name} on ${dev.name} scrolled by ${maxScroll}px, expected 0.0');
          debugPrint('VISUAL_TEST: ${q.name} | ${dev.name.padRight(28)} | Scroll: NO');
        } else {
          debugPrint('VISUAL_TEST: ${q.name} | ${dev.name.padRight(28)} | Scroll: ${maxScroll.toStringAsFixed(1)}px');
        }
      });
    }
  }
}
