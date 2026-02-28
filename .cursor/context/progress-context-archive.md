# Progress context archive

Completed items in reverse chronological order.

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
