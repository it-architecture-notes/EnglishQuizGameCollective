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
      storyText: const {'en': 'Help the character reach the next place.'},
    );
    const template = StoryTemplateConfig(
      templateId: 1,
      layout: 'character_dialog_scene',
      requiresText: true,
      requiresImages: false,
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

  testWidgets('renders scene_story_text template', (tester) async {
    final page = StoryPageConfig(
      eventId: 2,
      pageTemplateId: 4,
      trigger: const StoryTrigger(type: StoryTriggerType.afterLevel, level: 1),
      storyText: const {'en': 'Great job!'},
    );
    const template = StoryTemplateConfig(
      templateId: 4,
      layout: 'scene_story_text',
      requiresText: true,
      requiresImages: false,
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

    expect(find.text('Great job!'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
