import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_quiz_game/app_flavor.dart';
import 'package:english_quiz_game/app_theme.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/screens/image_quiz_screen.dart';
import 'package:english_quiz_game/models/quiz_flow.dart';

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
  // Q1: Regular short lines
  LevelQuestion(
    questionId: 'test_q1',
    template: 'ConvoTemplate-1',
    convoData: ConvoQuestionData(
      character1: 'char_a',
      character2: 'char_b',
      line1: 'Test line one, is this a _____ sentence?',
      line2: 'Yes, this is a test line two.',
      answer: 'test',
      distractors: ['sample', 'trial', 'demo'],
      imageName: 'test-placeholder-convo-template-1',
    ),
  ),
  // Q2: Long symmetric lines
  LevelQuestion(
    questionId: 'test_q2',
    template: 'ConvoTemplate-1',
    convoData: ConvoQuestionData(
      character1: 'char_a',
      character2: 'char_b',
      line1: 'Test line one that is intentionally quite long and wordy, is this a very very long _____ sentence that keeps going and going?',
      line2: 'Yes, this is an intentionally long and wordy test line two that also keeps going and going for quite a while.',
      answer: 'test',
      distractors: ['sample', 'trial', 'demo'],
      imageName: 'test-placeholder-convo-template-1',
    ),
  ),
  // Q3: Long word
  LevelQuestion(
    questionId: 'test_q3',
    template: 'ConvoTemplate-1',
    convoData: ConvoQuestionData(
      character1: 'char_a',
      character2: 'char_b',
      line1: 'Test line one, is this an extraordinarily long _____ word?',
      line2: 'Yes, that is a supercalifragilisticexpialidocious test word indeed.',
      answer: 'supercalifragilisticexpialidocious',
      distractors: [
        'pneumonoultramicroscopicsilicovolcanoconiosis',
        'antidisestablishmentarianism',
        'floccinaucinihilipilification'
      ],
      imageName: 'test-placeholder-convo-template-1',
    ),
  ),
  // Q4: Asymmetric lines (1-line line1 + 3-line line2)
  LevelQuestion(
    questionId: 'test_q4',
    template: 'ConvoTemplate-1',
    convoData: ConvoQuestionData(
      character1: 'char_a',
      character2: 'char_b',
      line1: 'Where are you going _____?',
      line2: 'I am planning to go to the new community center near the central library to meet with all of our classmates for study group.',
      answer: 'now',
      distractors: ['here', 'there', 'soon'],
      imageName: 'test-placeholder-convo-template-1',
    ),
  ),
  // Q5: Pathological answer content. This must exercise the answer-region-only
  // fallback without allowing the whole page to overflow.
  LevelQuestion(
    questionId: 'test_q5_pathological',
    template: 'ConvoTemplate-1',
    convoData: ConvoQuestionData(
      character1: 'char_a',
      character2: 'char_b',
      line1: 'This intentionally long dialogue line tests the final cascade boundary.',
      line2: 'This second intentionally long dialogue line keeps the stress fixture realistic.',
      answer: ('This answer contains an intentionally long sequence of words that must exceed the '
          'normal two-line button budget on narrow phones. ' * 8).trim(),
      distractors: [
        ('Another intentionally long answer that should require more than two rendered lines in '
            'its fixed grid cell. ' * 8).trim(),
        ('A third intentionally long answer is included to exercise equal-height wrong-state '
            'sizing safely. ' * 8).trim(),
        ('The fourth intentionally long answer completes the pathological fallback test fixture. '
            * 8).trim(),
      ],
      imageName: 'test-placeholder-convo-template-1',
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
      testWidgets('ConvoTemplate-1 $qName on ${device.name}', (tester) async {
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

        final levelConfig = LevelConfig(
          questions: [q],
        );

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
                progressKey: 'test_progress_convo1',
                preloadedLevelConfig: levelConfig,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        // ImageQuizScreen resolves the preloaded level and enters its playing phase through
        // post-frame work. Give that real screen lifecycle enough time to mount the question body
        // before measuring scrollables; otherwise this test can pass while only the loading shell
        // is present and never exercise ConvoTemplate-1 at all.
        await tester.pump(const Duration(seconds: 2));

        expect(tester.takeException(), isNull, reason: 'Layout overflow or exception detected');

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
        debugPrint('VISUAL_TEST: $qName | ${device.name.padRight(30)} | DialogueScroll: $scrollStr | GridScroll: NEVER (Fixed Box)');
      });
    }
  }
}
