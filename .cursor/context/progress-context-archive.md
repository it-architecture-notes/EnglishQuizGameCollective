# Progress context archive

Completed items in reverse chronological order.

## Issue-9: Friends Page (completed)

- **Summary:** Friends panel (opened via Friends heart button on home) shows a grid of 12 animals from config. Animals are locked (greyed) until freed with diamonds. Config in `assets/data/config/friends.json` (id, image, diamondCost, name). First-time popup: "Diamonds are needed to free the animals." On free: confirm dialog, then happy/jump animation. Diamond balance = lifetime diamonds (from profile summary) minus cost of freed animals. State persisted in SharedPreferences (FriendsState: freedAnimalIds, hintDismissed).
- **Deliverables:** `lib/models/friends_state.dart`; `lib/services/friends_service.dart`, `lib/services/friends_config_loader.dart`; `lib/screens/friends_panel_content.dart` (grid, locked/unlocked tiles, hint dialog, free flow, animation); `app/assets/data/config/friends.json`; `app/assets/images/friends/`; home_screen Friends button opens panel; TestDataService seed for diamonds; unit and widget tests in `test/models/`, `test/services/`, `test/screens/`.
- **Verification:** Open Friends from home → panel with 12 animals; hint on first open; tap locked animal with enough diamonds → confirm → freed and animation; with 0 diamonds tap animal → "Not enough diamonds." snackbar.

## Issue-8: Achievements Page (completed)

- **Summary:** Achievements panel (opened via Trophies on home) shows config-driven achievements in a scrollable list. Locked achievements are greyed out; progress-type achievements show a progress bar. Config in `assets/data/config/achievements.json` (id, type, title, description, icon keys, goal_value, tracking_key, show_progress_bar). Progress computed on panel open from profile + achievement state; grants applied from existing stats so new achievements can be added later. State persisted in SharedPreferences (AchievementState: quiz times, correct streak; profile supplies streaks, totals, categories). Achievements are global across all quiz types.
- **Deliverables:** `lib/models/achievement_state.dart`; `lib/services/achievement_service.dart`, `lib/services/achievement_progress_service.dart`, `lib/services/achievement_config_loader.dart`; `lib/screens/achievements_panel_content.dart` (list UI, locked/unlocked icons, progress bars); `app/assets/data/config/achievements.json`; home_screen trophies opens achievements overlay; image/vocabulary quiz screens report completion time and correct streak to AchievementService.
- **Verification:** Open Trophies → achievements list with config order; locked greyed out, unlocked colored; progress achievements show bar. Complete a quiz, reopen panel to see updated progress. Add new achievement to config and existing stats grant if criteria met.

## Issue-7: Progression System – Level Unlocking & Star History (completed)

- **Summary:** Levels page refactored from fully unlocked to progression-based. Level N+1 unlocks only when level N is completed with ≥1 star. New users see only level 1 unlocked; next 10 levels visible but greyscale and non-interactable ("the horizon"); levels beyond lastCompleted+10 are hidden. Progression key is ordinal level index (1-based position in subLevels list). Cold boot: auto-scroll to furthest unlocked level; return from quiz: scroll to level just played. Uses `scrollable_positioned_list` for scroll-to-index. Locked cells use ColorFilter greyscale; banners with no visible sub-levels are omitted.
- **Deliverables:** `lib/models/level_completion_result.dart`; `lib/models/quiz_flow.dart` (SubLevelItem.ordinalLevelIndex); `lib/screens/levels_screen.dart` (progress load, horizon filter, lock/unlock UI, ItemScrollController); `lib/screens/image_quiz_screen.dart` and `lib/screens/vocabulary_quiz_screen.dart` (ordinalLevelIndex param, recordLevelCompletion with ordinal, Navigator.pop(LevelCompletionResult)); `lib/screens/placeholders/quiz_placeholder_screen.dart` (ordinalLevelIndex optional); `pubspec.yaml` (scrollable_positioned_list).
- **Verification:** New user: only level 1 colored and tappable, levels 2–11 greyscale. Complete level 1 (≥1 star): level 2 unlocks, level 12 appears; return from quiz scrolls to level 1. Cold boot scrolls to furthest unlocked. Replay and delta rewards unchanged (QuizProgressService).

## Issue-6: Profile Panel (completed)

- **Summary:** Profile panel shown as centered overlay (blur backdrop, 88%×82% card), not full screen. Avatar (CircleAvatar with edit badge) + editable name TextField, joined date. Lifetime stars/diamonds. Per quiz type: current level, progress bar (completed/total), questions answered, daily streak (consecutive calendar days per quiz type). Streak and questions updated only when level is passed (stars ≥ 1). Uses ProfileState/ProfileService (SharedPreferences); ProfileService.registerQuizCompletion called from image and vocabulary quiz screens on pass.
- **Deliverables:** `lib/models/profile_state.dart`, `lib/services/profile_service.dart`, `lib/screens/profile_panel_screen.dart`, `showProfilePanelOverlay()`; Home "Me" button opens overlay; avatar picker 4×4 grid from `assets/images/avatars/` via AssetManifest.
- **Verification:** Run app, tap Me → profile overlay opens. Edit name, change avatar (if assets exist), close via X or backdrop; reopen to confirm persistence. Complete a quiz level (≥1 star), reopen profile to verify streak/questions update.

## Issue-5: Vocabulary Test Quiz Page (completed)

- **Summary:** Vocabulary quiz screen with 10-question cloze (fill-in-the-blank) conversations between two characters. Features: speech bubble UI with blank highlighted, 4 answer buttons (same correct/wrong feedback + auto-advance rules as Image Quiz), translate toggle (reads user language from `AppSettingsService`; hidden when language is 'en'), full conversation modal (enabled after all questions answered), end panel with stars/diamonds, full scoring and persistence via `QuizProgressService`. Character images load from `assets/vocabulary/characters/` with letter-avatar fallback. Levels screen routes 'vocabulary' quiz type to `VocabularyQuizScreen`.
- **Deliverables:** `lib/screens/vocabulary_quiz_screen.dart`, `lib/models/vocabulary_quiz.dart`, `lib/services/vocabulary_quiz_loader.dart`, `lib/services/app_settings_service.dart`, `assets/vocabulary/data/airport-1.json` (sample 10-question en/tr/es data), `assets/vocabulary/characters/` (placeholder folder); `pubspec.yaml` updated with new asset paths; `levels_screen.dart` routes 'vocabulary' to `VocabularyQuizScreen`.
- **Verification:** Run `flutter run`, navigate Vocabulary → Level 1 (airport). Complete all 10 questions; verify star/diamond end panel and Full Conversation modal. To test translate: call `AppSettingsService.setLanguage('tr')` once (e.g. from a debug button in settings placeholder), then re-enter the level — Translate button appears.

## Issue-4: Image Quiz Page (completed)

- **Summary:** Image Quiz screen with level selection from Levels page, AssetManifest-based level image discovery, question flow (image + 4 answers, correct/wrong feedback, Next button), scoring (stars 0–3, diamonds), progress persistence via SharedPreferences, end-of-level panel. Supports subfolder levels (e.g. assets/images/quiz/airport-1/) and flat naming; excludes .DS_Store.
- **Deliverables:** `lib/screens/image_quiz_screen.dart`, `lib/services/quiz_progress_service.dart`, `lib/services/image_quiz_level_loader.dart`, `lib/services/game_config_loader.dart`, `assets/data/config/game_config.json`; Levels screen routes Image Quiz to `ImageQuizScreen`.
- **Verification:** Run `flutter run -d chrome --web-port=8080`, complete a level (≥1 star), tap OK; progress persists. State stored in SharedPreferences (localStorage on web).

## Issue-1: Project Baseline Setup (completed)

- **Summary:** Tech stack documented (Flutter, Android/iOS, portrait only), Flutter project initialized under `app/`, resolution service and four aspect-ratio buckets in place, asset and data folder structure created, background integrated on home screen.
- **Deliverables:** [architecture-technical-context.md](architecture-technical-context.md) updated; [../../README.md](../../README.md) updated; `app/` with pubspec, lib (main + resolution_service), android (portrait lock), ios (portrait in Info.plist), assets (backgrounds/phone_tall|phone_wide|tablet_43|tablet_1610, buttons, characters, avatars, quiz, data/state|config|settings).
- **Verification:** Run from `app/`: `flutter pub get && flutter run`. If Flutter was not in PATH during setup, run `flutter create . --platforms=android,ios` from `app/` first. Baseline is ready for feature work.
