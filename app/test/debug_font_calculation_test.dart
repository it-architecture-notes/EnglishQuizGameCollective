import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const text =
    'Long Test line one for DialogueCompletion, is this long enough to wrap two lines on a narrow phone?';

double wrappedTextHeight({
  required String text,
  required double fontSize,
  required FontWeight fontWeight,
  required double maxWidth,
  required TextScaler textScaler,
  int? maxLines,
  String? fontFamily,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: fontFamily,
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: maxLines,
  )..layout(maxWidth: maxWidth);
  return painter.size.height;
}

double solveFontSizeForBox({
  required double Function(double fontSize) neededHeightAtFontSize,
  required double boxHeight,
  required double minFontSize,
  required double maxFontSize,
}) {
  print('--- solveFontSizeForBox START (boxHeight=$boxHeight, min=$minFontSize, max=$maxFontSize) ---');
  final atMax = neededHeightAtFontSize(maxFontSize);
  print('Check atMax ($maxFontSize): height=$atMax <= $boxHeight ? ${atMax <= boxHeight}');
  if (atMax <= boxHeight) return maxFontSize;
  
  final atMin = neededHeightAtFontSize(minFontSize);
  print('Check atMin ($minFontSize): height=$atMin > $boxHeight ? ${atMin > boxHeight}');
  if (atMin > boxHeight) return minFontSize;
  
  var lo = minFontSize, hi = maxFontSize;
  for (var i = 0; i < 16; i++) {
    final mid = (lo + hi) / 2;
    final atMid = neededHeightAtFontSize(mid);
    print('Step $i: lo=${lo.toStringAsFixed(2)}, hi=${hi.toStringAsFixed(2)}, mid=${mid.toStringAsFixed(2)} => height=${atMid.toStringAsFixed(1)} (fits: ${atMid <= boxHeight})');
    if (atMid <= boxHeight) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  print('--- solveFontSizeForBox RESULT: lo=${lo.toStringAsFixed(2)} ---');
  return lo;
}

void main() {
  testWidgets('debug solveFontSizeForBox for iPhone 12 Pro and iPhone 16 Pro Max', (tester) async {
    // 1. iPhone 12 Pro scenario from log:
    // maxWidth = 339.3 - 48.0 = 291.3 (audio=true) OR 339.3 (audio=false)
    // boxHeight = 101.3
    // min = 14, max = 23
    print('\n================ SCENARIO 1: iPhone 12 Pro (maxWidth=291.3, boxHeight=101.3) ================');
    solveFontSizeForBox(
      neededHeightAtFontSize: (fs) => wrappedTextHeight(
        text: text,
        fontSize: fs,
        fontWeight: FontWeight.w700,
        maxWidth: 291.3,
        textScaler: TextScaler.noScaling,
      ),
      boxHeight: 101.3,
      minFontSize: 14.0,
      maxFontSize: 23.0,
    );

    print('\n================ SCENARIO 2: iPhone 12 Pro with audio=false (maxWidth=339.3, boxHeight=101.3) ================');
    solveFontSizeForBox(
      neededHeightAtFontSize: (fs) => wrappedTextHeight(
        text: text,
        fontSize: fs,
        fontWeight: FontWeight.w700,
        maxWidth: 339.3,
        textScaler: TextScaler.noScaling,
      ),
      boxHeight: 101.3,
      minFontSize: 14.0,
      maxFontSize: 23.0,
    );

    print('\n================ SCENARIO 3: iPhone 16 Pro Max from log (maxWidth=382.8, boxHeight=140.2 - 22 = 118.2) ================');
    solveFontSizeForBox(
      neededHeightAtFontSize: (fs) => wrappedTextHeight(
        text: text,
        fontSize: fs,
        fontWeight: FontWeight.w700,
        maxWidth: 382.8,
        textScaler: TextScaler.noScaling,
      ),
      boxHeight: 118.2,
      minFontSize: 14.0,
      maxFontSize: 23.0,
    );
  });
}
