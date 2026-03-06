import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_quiz_game/screens/home_screen.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: child),
    );
  }

  group('HomeScreen Friends button', () {
    testWidgets('opens Friends panel when Friends nav is tapped', (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Friends'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Friends'), findsWidgets);
      expect(find.textContaining('Your diamonds'), findsOneWidget);
    });

    testWidgets('Friends panel opens with Friends title', (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Friends'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Friends'), findsWidgets);
    });
  });
}
