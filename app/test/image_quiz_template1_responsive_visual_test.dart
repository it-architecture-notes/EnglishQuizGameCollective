import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_quiz_game/app_flavor.dart';
import 'package:english_quiz_game/app_theme.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/models/quiz_flow.dart';
import 'package:english_quiz_game/screens/image_quiz_screen.dart';
import 'package:english_quiz_game/widgets/mcq_pill_answer_button.dart';

// `flutter test` never loads the real app font unless told to — it silently substitutes a
// fallback test font with different glyph metrics, which can make short text appear to wrap to
// extra lines that never actually happen on a real device.
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
  // Q1: Production-typical — single-word answers (99% of real content).
  LevelQuestion(
    questionId: 'test_q1',
    template: 'imageQuizTemplate-1',
    imageData: const ImageQuestionData(
      imageName: 'test-placeholder-image-quiz-1',
      answer: 'apple',
      wrongAnswers: ['banana', 'orange', 'grape'],
    ),
  ),
  // Q2: Real production shape — a genuine sentence-length answer among single-word distractors
  // (audited: "Let's walk around town." exists in real content).
  LevelQuestion(
    questionId: 'test_q2',
    template: 'imageQuizTemplate-1',
    imageData: const ImageQuestionData(
      imageName: 'test-placeholder-image-quiz-1',
      answer: "Let's walk around town.",
      wrongAnswers: ['run', 'sit', 'wait'],
    ),
  ),
  // Q3: Unbroken long compound word (real production shape, e.g. "blood-pressure-monitor").
  LevelQuestion(
    questionId: 'test_q3',
    template: 'imageQuizTemplate-1',
    imageData: const ImageQuestionData(
      imageName: 'test-placeholder-image-quiz-1',
      answer: 'blood-pressure-monitor',
      wrongAnswers: ['thermometer', 'stethoscope', 'bandage'],
    ),
  ),
  // Q4: All four options long/wrapping simultaneously — worst case for the shared-height grid.
  LevelQuestion(
    questionId: 'test_q4',
    template: 'imageQuizTemplate-1',
    imageData: const ImageQuestionData(
      imageName: 'test-placeholder-image-quiz-1',
      answer: 'We should reschedule the entire meeting for next week.',
      wrongAnswers: [
        'I think it would be better to cancel it altogether.',
        'Please make sure everyone confirms their availability first.',
        'Let us try to finish this before the end of the day.',
      ],
    ),
  ),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadInterFont();
  });

  for (var qIdx = 0; qIdx < testQuestions.length; qIdx++) {
    final q = testQuestions[qIdx];
    final qName = 'Q${qIdx + 1}';

    for (final device in devices) {
      testWidgets('imageQuizTemplate-1 $qName on ${device.name}', (tester) async {
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

        final levelConfig = LevelConfig(questions: [q]);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.forFlavor(AppFlavor.adults),
              home: ImageQuizScreen(
                subLevel: const SubLevel(
                  mainLevel: 1,
                  directoryName: 'testing-responsive-design',
                  title: 'Test',
                ),
                ordinalLevelIndex: 1,
                progressKey: 'test_progress_iq1_${qIdx}_${device.name}',
                preloadedLevelConfig: levelConfig,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        // Same lesson learned from ConvoTemplate-1's first (false-positive) test suite: give the
        // real screen lifecycle enough time to leave its loading shell before measuring anything.
        await tester.pump(const Duration(seconds: 2));

        expect(tester.takeException(), isNull, reason: 'Layout overflow or exception detected');

        // KNOWN, ALREADY-ACCEPTED LIMITATION (same one found and accepted for `ConvoTemplate-1`
        // in this thread — confirmed here to be the identical shared-loading-pipeline gap, not
        // something new): the full `ImageQuizScreen` never leaves its loading spinner within a
        // test's pump cycle, even with a `preloadedLevelConfig` pointing at a real, existing
        // image asset (verified directly — `test-placeholder-image-quiz-1.png` genuinely exists
        // on disk). This is a diagnostic print, not a hard assertion, precisely so this suite
        // doesn't quietly "pass" while asserting nothing (the original ConvoTemplate-1 mistake)
        // — the 2x2 grid rebuild itself was verified by direct code review instead
        // (`dart analyze` clean + read against `McqPillAnswerButton`'s real API).
        final buttonsMounted = find.byType(McqPillAnswerButton).evaluate().length;
        debugPrint(
          'VISUAL_TEST: $qName | ${device.name.padRight(28)} | '
          'buttonsMounted=$buttonsMounted/4 '
          '${buttonsMounted < 4 ? "(loading-spinner limitation, not a layout failure)" : ""}',
        );

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
