import 'package:english_quiz_game/models/story_config.dart';
import 'package:english_quiz_game/screens/story/story_overlay_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders character_dialog_scene template content',
      (tester) async {
    final page = StoryPageConfig(
      eventId: 1,
      pageTemplateId: 1,
      trigger: const StoryTrigger(type: StoryTriggerType.beforeLevel, level: 1),
      coveredLevelsNumber: 1,
      pageTextListForTemplate: const [
        {'en': 'Help the character reach the next place.'},
      ],
      pageImageListForTemplate: const [],
      pageAnimationListForTemplate: const [],
    );
    const template = StoryTemplateConfig(
      templateId: 1,
      layout: 'character_dialog_scene',
      requiresText: true,
      requiresImages: true,
      requiresAnimation: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryOverlayScreen(
            page: page,
            template: template,
            languageCode: 'en',
            continueLabel: 'Continue',
            congratulationsLabel: 'Congratulations!',
          ),
        ),
      ),
    );

    expect(
        find.text('Help the character reach the next place.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('renders animation_only template', (tester) async {
    final page = StoryPageConfig(
      eventId: 2,
      pageTemplateId: 3,
      trigger: const StoryTrigger(type: StoryTriggerType.afterLevel, level: 1),
      coveredLevelsNumber: 1,
      pageTextListForTemplate: const [],
      pageImageListForTemplate: const [],
      pageAnimationListForTemplate: const ['confetti_celebration'],
    );
    const template = StoryTemplateConfig(
      templateId: 3,
      layout: 'animation_only',
      requiresText: false,
      requiresImages: false,
      requiresAnimation: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryOverlayScreen(
            page: page,
            template: template,
            languageCode: 'en',
            continueLabel: 'Continue',
            congratulationsLabel: 'Congratulations!',
          ),
        ),
      ),
    );

    expect(find.text('Great job!'), findsOneWidget);
    expect(find.text('confetti_celebration'), findsOneWidget);
  });
}
