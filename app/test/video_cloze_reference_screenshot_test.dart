import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_quiz_game/app_flavor.dart';
import 'package:english_quiz_game/app_theme.dart';
import 'package:english_quiz_game/models/level_config.dart';
import 'package:english_quiz_game/models/quiz_flow.dart';
import 'package:english_quiz_game/screens/image_quiz_screen.dart';

/// Proof-of-concept rendering harness: captures an actual PNG screenshot of one
/// (permutation x reference viewport) combination so the render can be visually
/// inspected, not just asserted against overflow/scroll. One-off tool, not a
/// correctness/regression test — screenshots land in /tmp, not checked in.
Future<void> _loadInterFont() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes =
        File('assets/fonts/inter/Inter-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

const _referenceViewport = Size(390, 844); // "Mainstream modern iPhone"
const _safeArea = EdgeInsets.only(top: 47, bottom: 34);

const _clozeQuestion = VideoConversationQuestionData(
  videoFile: 'testing-responsive-design',
  startAt: Duration(seconds: 0),
  pauseAt: Duration(seconds: 3),
  clozeData: VideoClozeAnswerData(
    sentence: 'My name is _____.',
    answers: ['John'],
    distractors: ['Sara', 'Tom', 'Emma'],
  ),
);

Widget _harness({required Key boundaryKey}) {
  final question = LevelQuestion(
    questionId: 'video_cloze_reference',
    template: 'VideoConversation',
    videoConversationData: _clozeQuestion,
  );
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.forFlavor(AppFlavor.adults),
      home: RepaintBoundary(
        key: boundaryKey,
        child: ImageQuizScreen(
          subLevel: const SubLevel(
            mainLevel: 1,
            directoryName: 'testing-responsive-design',
            title: 'Test Video Cloze',
          ),
          ordinalLevelIndex: 1,
          progressKey: 'video_cloze_reference',
          preloadedLevelConfig: LevelConfig(questions: [question]),
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

  testWidgets('capture full Video ClozeSequence screen at 390x844',
      (tester) async {
    tester.view.physicalSize = _referenceViewport;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = FakeViewPadding(
      top: _safeArea.top,
      bottom: _safeArea.bottom,
      left: _safeArea.left,
      right: _safeArea.right,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(_harness(boundaryKey: boundaryKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('My name is _____.'), findsOneWidget);

    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final outFile = File('video_cloze_390x844_1line_1row.png');
    outFile.writeAsBytesSync(byteData!.buffer.asUint8List());
    print('Screenshot written to ${outFile.absolute.path}');
  });
}
