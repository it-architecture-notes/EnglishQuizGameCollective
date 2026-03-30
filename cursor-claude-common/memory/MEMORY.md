# Project Memory

## Project
Flutter mobile language learning quiz app (portrait-only, Android/iOS). Unified quiz screen handles all question types (image, vocab, grammar).

## Current State
- **Active issue:** None
- **Current branch:** main
- **Last completed:** Issue-17 (Unified Level Map & Single Quiz Screen)

## Tech Stack
- Flutter (Dart), Riverpod, portrait-only
- JSON files for config/state/settings
- SharedPreferences for persistence
- `app/` is the Flutter project root

## Key Context Files
- `cursor-claude-common/context/active-progress-context.md` — current issue
- `cursor-claude-common/context/progress-context-archive.md` — completed issues summary
- `cursor-claude-common/context/architecture-technical-context.md` — tech/asset layout
- `cursor-claude-common/rules/rules.md` — project rules

## Rules (Key)
- One issue at a time; plan first, wait for approval before implementing
- Never commit unless explicitly asked
- Never work on main branch; use feature branches
- No tests unless requested
- No over-engineering, no speculative features
- Context files live in `cursor-claude-common/` (shared with Cursor)

## Architecture
- Resolution buckets: phone_tall, phone_wide, tablet_43, tablet_1610
- Assets: `app/assets/images/`, `app/assets/data/`, `app/assets/quiz-data/`
- Story data: `app/assets/data/story/` (new in Issue-12)
- Story images: `app/assets/images/story/`

## Completed Issues (summary)
17 → Unified Level Map & Quiz Screen (single flow JSON, single QuizScreen handling image/vocab/grammar phases; vocab Dart files deleted; StoryTemplateC bilingual layout)
16 → progressKey refactor (removed levelNumber from flow JSON; progress keyed by "{mainLevel}_{iconImageName}"; vocab/grammar loaders simplified)
15 → Speech Bubbles (monster/animal conversation bubbles on each step; step1–4 choices per language; game-over overlay bubbles)
14 → Image Quiz Timer & Monster (pie-chart timer, monster advances on wrong answers, guest animal poses, idle animation, wind trail, game-over overlay, asset discovery)
13 → Reminder Levels (2 reminder quizzes per main level, wrong-answer weighted, scroll fixes)
12 → Main Level Story (Gardenscapes-style story overlays per main level)
10 → Settings (language, music, sound/FX, persistence)
9  → Friends page (animal grid, diamond cost)
8  → Achievements page
7  → Progression system (level unlocking, star history)
6  → Profile panel
5  → Vocabulary Quiz page
4  → Image Quiz page
1  → Project baseline

## Key Files
- `app/lib/screens/image_quiz_screen.dart` — unified quiz screen (image + convo modes, timer, monster, animal, animations)
- `app/lib/models/level_config.dart` — LevelConfig, LevelQuestion, ImageQuestionData, ConvoQuestionData
- `app/lib/services/level_config_loader.dart` — loads per-level quiz JSON
- `app/lib/screens/quiz_runner_screen.dart` — phase-splits questions by type, dispatches to ImageQuizScreen
- `app/lib/services/image_quiz_level_loader.dart` — asset discovery (animals, monsters)
- `app/lib/screens/levels_screen.dart` — level selection, scroll logic, reminder unlock
- `app/lib/models/reminder_progress.dart` — ReminderProgressData, ReminderLevelState
- `app/lib/services/reminder_progress_service.dart` — reminder state, question generation
- `app/lib/services/reminder_question_builder.dart` — question selection/split logic
- `app/lib/screens/story/story_overlay_screen.dart` — story overlay
- `app/lib/services/story_trigger_service.dart` — when to show story
- `app/lib/services/story_progress_service.dart` — story state
- `app/lib/screens/story/story_templates/story_template_c.dart` — bilingual scene+text layout (template 4)
