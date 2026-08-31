import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/app_flavor.dart';
import 'package:english_quiz_game/app_theme.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/screens/quiz_templates/word_pairs_quiz_body.dart';
import 'package:english_quiz_game/services/question_layout_budget.dart';

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

WordPairItem _pair(String left, String right) =>
    WordPairItem(left: left, translations: {'es': right});

final testQuestions = [
  // Q1: Production baseline — exactly 4 pairs, short words.
  (
    name: 'Q1 4 Pairs Baseline',
    data: WordPairsQuestionData(pairs: [
      _pair('white', 'blanco'),
      _pair('yellow', 'amarillo'),
      _pair('clean', 'limpio'),
      _pair('sharp', 'afilado'),
    ]),
  ),
  // Q2: Production maximum seen today — 6 pairs.
  (
    name: 'Q2 6 Pairs Production Max',
    data: WordPairsQuestionData(pairs: [
      _pair('run', 'correr'),
      _pair('jump', 'saltar'),
      _pair('walk', 'caminar'),
      _pair('swim', 'nadar'),
      _pair('climb', 'escalar'),
      _pair('dance', 'bailar'),
    ]),
  ),
  // Q3: Top of the design range — 8 pairs, short words, no scroll expected.
  (
    name: 'Q3 8 Pairs Design Ceiling',
    data: WordPairsQuestionData(pairs: [
      _pair('one', 'uno'),
      _pair('two', 'dos'),
      _pair('three', 'tres'),
      _pair('four', 'cuatro'),
      _pair('five', 'cinco'),
      _pair('six', 'seis'),
      _pair('seven', 'siete'),
      _pair('eight', 'ocho'),
    ]),
  ),
  // Q4: 4 pairs but with real multi-word phrases from production content — exercises the
  // multi-line grow-not-shrink rule on the tightest phones.
  (
    name: 'Q4 4 Pairs Multi-Word Phrases',
    data: WordPairsQuestionData(pairs: [
      _pair('as soon as possible', 'lo antes posible'),
      _pair('once in a while', 'de vez en cuando'),
      _pair('two days before', 'dos días antes'),
      _pair('since yesterday', 'desde ayer'),
    ]),
  ),
  // Q5: 8 pairs (design ceiling) combined with long phrases — worst-case combination inside
  // the supported range: smallest preset *and* multi-line growth at the same time.
  (
    name: 'Q5 8 Pairs Multi-Word Phrases',
    data: WordPairsQuestionData(pairs: [
      _pair('as soon as possible', 'lo antes posible'),
      _pair('once in a while', 'de vez en cuando'),
      _pair('two days before', 'dos días antes'),
      _pair('since yesterday', 'desde ayer'),
      _pair('until next week', 'hasta la próxima semana'),
      _pair('right around the corner', 'a la vuelta de la esquina'),
      _pair('better late than never', 'más vale tarde que nunca'),
      _pair('out of the blue', 'de la nada'),
    ]),
  ),
  // Q6: Deliberately beyond the design range (10 pairs) — developer polices content authoring
  // to stay ≤8, so this fixture only verifies the last-resort scroll engages cleanly, not that
  // content like this should ever ship.
  (
    name: 'Q6 Beyond-Cap Stress (10 Pairs)',
    data: WordPairsQuestionData(pairs: [
      _pair('one', 'uno'),
      _pair('two', 'dos'),
      _pair('three', 'tres'),
      _pair('four', 'cuatro'),
      _pair('five', 'cinco'),
      _pair('six', 'seis'),
      _pair('seven', 'siete'),
      _pair('eight', 'ocho'),
      _pair('nine', 'nueve'),
      _pair('ten', 'diez'),
    ]),
  ),
];

Widget buildTestHarness({
  required WordPairsQuestionData question,
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
      theme: AppTheme.forFlavor(AppFlavor.adults),
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
                      child: WordPairsQuizBody(
                        data: question,
                        userLanguage: 'es',
                        strings: const {
                          'language_name_en': 'English',
                          'language_name_es': 'Spanish',
                        },
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
      testWidgets('WordPairs $qName (${fixture.name}) on ${device.name}', (tester) async {
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
            size: device.size,
            safeArea: device.safeArea,
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull, reason: 'Layout overflow or exception detected');

        // Confirm every word is actually rendered on screen, not a loading/empty shell.
        for (final pair in fixture.data.pairs) {
          expect(find.text(pair.left), findsOneWidget,
              reason: 'Left tile "${pair.left}" must be rendered on screen!');
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
