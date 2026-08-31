import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/screens/quiz_templates/cloze_sequence_quiz_body.dart';
import 'package:english_quiz_game/services/question_layout_budget.dart';

final q4 = ClozeSequenceQuestionData(
  line1: 'Test prompt line for standalone ClozeSequence, can you spot the extraordinarily long test words?',
  sentence: 'That was _____ but also _____, according to the _____ report.',
  answers: [
    'supercalifragilisticexpialidocious',
    'unbelievable',
    'pneumonoultramicroscopicsilicovolcanoconiosis',
  ],
  distractors: [
    'antidisestablishmentarianism',
    'floccinaucinihilipilification',
    'incomprehensibilities',
    'counterrevolutionaries',
  ],
  imageName: 'test-placeholder-cloze-sequence',
);

Future<void> loadInter() async {
  final loader = FontLoader('Inter');
  for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/inter/Inter-$f.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  testWidgets('real-font an check', (tester) async {
    await loadInter();

    tester.view.physicalSize = const Size(378, 701);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(378, 701), textScaler: TextScaler.noScaling),
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Inter', useMaterial3: true),
        home: Scaffold(
          body: SafeArea(
            child: Builder(builder: (context) {
              final budget = QuestionLayoutBudget.of(context);
              return Column(children: [
                Container(height: budget.headerHeight),
                Expanded(
                  child: ClozeSequenceQuizBody(
                    data: q4,
                    userLanguage: 'en',
                    imagePath: 'assets/test.png',
                    resolveAudioExists: (_) async => false,
                    onPlayQuestionAudio: (_) async {},
                    onPlayCorrect: () {},
                    onPlayWrong: () {},
                    onOutcome: (_) {},
                  ),
                ),
                Container(height: budget.footerHeight),
              ]);
            }),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final tileFinder = find.text('antidisestablishmentarianism');
    final tileWidget = tester.widget<Text>(tileFinder);
    final tileRP = tester.renderObject<RenderParagraph>(tileFinder);
    final tileBox = tileRP.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 2)).first;
    debugPrint('TILE style: fontSize=${tileWidget.style?.fontSize} fontWeight=${tileWidget.style?.fontWeight}');
    debugPrint('TILE "an" box (REAL Inter): width=${(tileBox.right-tileBox.left).toStringAsFixed(3)} height=${(tileBox.bottom-tileBox.top).toStringAsFixed(3)}');

    const line1Text = 'Test prompt line for standalone ClozeSequence, can you spot the extraordinarily long test words?';
    final canIndex = line1Text.indexOf('can');
    final dialogFinder = find.textContaining('can you spot');
    final dialogWidget = tester.widget<Text>(dialogFinder.first);
    final dialogRP = tester.renderObject<RenderParagraph>(dialogFinder.first);
    final dialogBox = dialogRP.getBoxesForSelection(
      TextSelection(baseOffset: canIndex + 1, extentOffset: canIndex + 3),
    ).first;
    debugPrint('DIALOG line1 style: fontSize=${dialogWidget.style?.fontSize} fontWeight=${dialogWidget.style?.fontWeight}');
    debugPrint('DIALOG "an" box (REAL Inter): width=${(dialogBox.right-dialogBox.left).toStringAsFixed(3)} height=${(dialogBox.bottom-dialogBox.top).toStringAsFixed(3)}');
  });
}
