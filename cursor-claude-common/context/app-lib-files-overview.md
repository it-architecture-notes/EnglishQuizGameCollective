# `app/lib` — file purposes (one–two lines each)

Scope: every file under **`app/lib`** only (the Flutter app library). **`app/test`** is not under `lib` and is omitted here.

Paths are relative to `app/lib/`.

---

## Root

| File | Purpose |
|------|---------|
| `main.dart` | App entry: portrait lock, `ProviderScope`, `MaterialApp` with `HomeScreen` as home. |

---

## `models/`

| File | Purpose |
|------|---------|
| `achievement_state.dart` | Data classes for achievement definitions and unlock/progress state (loaded from JSON / prefs). |
| `friends_state.dart` | Models friend entries and list state for the friends feature UI. |
| `guest_animal_conversations.dart` | Guest vs monster dialogue lines per language and step, for image-quiz banter. |
| `level_completion_result.dart` | Result object popped when a quiz closes: completion flag, ordinal index, reminder flag, correct count. |
| `level_config.dart` | Parsed `questions.json`: `LevelConfig`, `LevelQuestion`, template-specific `questionData` types and JSON parsing. |
| `profile_state.dart` | Profile-related state shape (display, stats) for the profile panel. |
| `quiz_flow.dart` | `SubLevel`, `MainLevelMeta`, `SubLevelItem`, and flow list types for the level map. |
| `reminder_progress.dart` | Reminder level state, question IDs, and helpers like `parseReminderQuestionId`. |
| `story_config.dart` | Story main levels, page configs, triggers, and template metadata from story JSON. |
| `story_progress.dart` | Which story events/pages the player has completed (persisted progress). |

---

## `providers/`

| File | Purpose |
|------|---------|
| `localization_provider.dart` | Riverpod async provider for current locale strings (loads `localization.json` via loader). |
| `settings_provider.dart` | Riverpod provider for language, music, and sound-FX toggles backed by `AppSettingsService`. |

---

## `screens/` (top level)

| File | Purpose |
|------|---------|
| `achievements_panel_content.dart` | Body of the achievements overlay: lists trophies / progress from achievement services. |
| `friends_panel_content.dart` | Body of the friends overlay: shows friend list / placeholders using `FriendsService` state. |
| `home_screen.dart` | Start screen: Start Game → levels, bottom nav to profile, trophies, friends, settings panels. |
| `image_quiz_screen.dart` | Main quiz UI: image + all convo templates, timer/monster, reminders, end/game-over, progress pop. |
| `levels_screen.dart` | Scrollable level map (banners + nodes), unlock rules, story hooks, opens `QuizRunnerScreen`. |
| `panel_overlay.dart` | Reusable full-screen/modal panel shell with title and scrollable body (settings, etc.). |
| `profile_panel_screen.dart` | Profile overlay route: avatar, stats, and related profile UI. |
| `quiz_runner_screen.dart` | Loads `questions.json` for a sub-level (or runs reminder passes) and pushes `ImageQuizScreen`. |
| `settings_panel_content.dart` | Settings form inside overlay: language, music, sound FX wired to settings provider. |

---

## `screens/placeholders/`

| File | Purpose |
|------|---------|
| `achievements_placeholder_screen.dart` | Stub screen when achievements flow is not fully wired (development / fallback). |
| `friends_placeholder_screen.dart` | Stub screen for friends feature placeholder navigation. |
| `level_selection_placeholder_screen.dart` | Stub for alternate level-selection experiments or legacy entry points. |
| `profile_placeholder_screen.dart` | Stub profile route for layouts or tests without full profile data. |
| `quiz_placeholder_screen.dart` | Stub quiz screen for navigation prototypes. |
| `settings_placeholder_screen.dart` | Stub settings screen for simple routing or tests. |

---

## `screens/quiz_templates/`

| File | Purpose |
|------|---------|
| `appear_disappear_quiz_body.dart` | `ConvoTemplate-AppearDisappear`: word sequence, ghost grid, ordered tap gameplay. |
| `cloze_sequence_quiz_body.dart` | `ConvoTemplate-ClozeSequence`: streaming sentence, numbered blanks, grid fill. |
| `simon_quiz_body.dart` | `ConvoTemplate-Simon`: demo sequence on 3×3 grid, player repeat, audio highlights. |

---

## `screens/story/`

| File | Purpose |
|------|---------|
| `story_overlay_screen.dart` | Full-screen story page host: picks template A/B/C, continue flow, static `show` entry. |

### `screens/story/story_templates/`

| File | Purpose |
|------|---------|
| `story_template_a.dart` | Layout variant “A” for story pages (illustration + text composition). |
| `story_template_b.dart` | Layout variant “B” for story pages. |
| `story_template_c.dart` | Layout variant “C” for story pages (e.g. different visual hierarchy or assets). |

---

## `screens/transitions/`

| File | Purpose |
|------|---------|
| `custom_page_routes.dart` | Shared `PageRouteBuilder`s: fade, scale, flip, slide-up, card-flip transitions between screens. |

---

## `services/`

| File | Purpose |
|------|---------|
| `achievement_config_loader.dart` | Loads achievement definitions from bundled JSON. |
| `achievement_progress_service.dart` | Persists and queries which achievements are unlocked / progress counters. |
| `achievement_service.dart` | Records per-answer and quiz-completion events used to drive achievement logic. |
| `app_settings_service.dart` | SharedPreferences access for language, music on/off, and sound FX on/off. |
| `audio_service.dart` | Central place to play UI clicks, correct/wrong SFX, and loop quiz background music. |
| `friends_config_loader.dart` | Loads friends-related JSON config for the friends feature. |
| `friends_service.dart` | Loads/saves friend list state and exposes it to the UI. |
| `game_config_loader.dart` | Loads global game JSON (timers, delays, etc.) into `GameConfig`. |
| `guest_animal_conversations_loader.dart` | Loads guest/monster conversation JSON and language selection helpers. |
| `image_asset_resolver.dart` | Resolves quiz image paths for a level key and image basename from assets. |
| `image_quiz_level_loader.dart` | Legacy discovery of image paths under a level folder when no unified `questions.json` exists. |
| `level_config_loader.dart` | Loads `assets/quiz-data/levels/{id}/questions.json` into `LevelConfig`. |
| `localization_loader.dart` | Loads `localization.json` maps for supported languages. |
| `profile_service.dart` | Persists profile fields and aggregates stats such as quiz completions. |
| `quiz_flow_loader.dart` | Loads `game-flow.json` + `game-flow-main-levels.json` into `QuizFlowData`. |
| `quiz_progress_service.dart` | Persists per-level stars/diamonds and total diamonds; exports `kQuizGameType` (`'game'`) for storage keys, story paths, and profile. |
| `reminder_progress_service.dart` | Persists reminder completion, wrong-answer tracking, and generates reminder question IDs. |
| `reminder_question_builder.dart` | Builds split question ID lists for reminder 1 vs 2 from wrong counters and per-level counts. |
| `resolution_service.dart` | Maps window `Size` to `ResolutionBucket` (phone/tablet variants) for responsive layout. |
| `story_config_loader.dart` | Loads story configuration JSON into `StoryConfigData`. |
| `story_progress_service.dart` | Saves and loads `StoryProgressState` (which story pages were seen/completed). |
| `story_trigger_service.dart` | Resolves which story page to show before/after levels from flow + progress. |
| `test_data_service.dart` | Debug/test flags stored in prefs (e.g. short quiz end) for development builds. |

---

## Maintenance

When you add or remove Dart files under `app/lib`, update this table so onboarding and tooling stay aligned with the codebase layout.
