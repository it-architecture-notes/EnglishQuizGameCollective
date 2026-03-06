import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_quiz_game/screens/settings_panel_content.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpUntilLoaded(WidgetTester tester, {int maxAttempts = 60}) async {
    for (var i = 0; i < maxAttempts; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          (find.text('Music').evaluate().isNotEmpty ||
           find.text('Sound / FX').evaluate().isNotEmpty ||
           find.byType(Switch).evaluate().length >= 2)) {
        return;
      }
    }
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }

  group('SettingsPanelContent', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(wrap(const SettingsPanelContent()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows language dropdown and toggles after load', (tester) async {
      await tester.pumpWidget(wrap(const SettingsPanelContent()));
      await pumpUntilLoaded(tester);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Sound / FX'), findsOneWidget);
    });

    testWidgets('has language label', (tester) async {
      await tester.pumpWidget(wrap(const SettingsPanelContent()));
      await pumpUntilLoaded(tester);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });
  });
}
