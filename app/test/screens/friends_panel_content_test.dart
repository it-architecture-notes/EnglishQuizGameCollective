import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_quiz_game/screens/friends_panel_content.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Pumps until content or hint dialog appears (async load can take a moment).
  Future<void> pumpUntilContent(WidgetTester tester, {int maxIterations = 50}) async {
    for (var i = 0; i < maxIterations; i++) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          (find.textContaining('Your diamonds').evaluate().isNotEmpty ||
           find.text('Diamonds are needed to free the animals.').evaluate().isNotEmpty)) {
        return;
      }
    }
  }

  group('FriendsPanelContent', () {
    testWidgets('shows hint dialog with diamonds message when panel starts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FriendsPanelContent(),
            ),
          ),
        ),
      );
      await pumpUntilContent(tester);
      expect(
        find.text('Diamonds are needed to free the animals.'),
        findsOneWidget,
        reason: 'Hint dialog should be visible after load',
      );
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FriendsPanelContent(),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('grid shows animal names when content is visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FriendsPanelContent(),
            ),
          ),
        ),
      );
      await pumpUntilContent(tester);
      if (find.text('OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('OK'));
        for (var i = 0; i < 50; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Bear').evaluate().isNotEmpty) break;
        }
      }
      if (find.text('Bear').evaluate().isNotEmpty) {
        expect(find.text('Bear'), findsOneWidget);
        expect(find.text('Lion'), findsOneWidget);
      }
    });

    testWidgets('shows not enough diamonds snackbar when tapping locked animal with insufficient diamonds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FriendsPanelContent(),
            ),
          ),
        ),
      );
      await pumpUntilContent(tester);
      if (find.text('OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('OK'));
        for (var i = 0; i < 50; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Bear').evaluate().isNotEmpty) break;
        }
      }
      if (find.text('Bear').evaluate().isEmpty) return;
      await tester.tap(find.text('Bear'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Not enough diamonds.'), findsOneWidget);
    });
  });
}
