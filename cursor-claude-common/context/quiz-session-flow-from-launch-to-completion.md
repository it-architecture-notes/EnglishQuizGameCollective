# Quiz session flow: launch → level map → play → stars/diamonds → finish

This document lists **files** and **function / method names** (no bodies) for the main path from app start through completing a sub-level. Code lives under `app/lib/` unless noted; assets under `app/assets/`.

---

## 1. Game starts

| File | Symbol | Role |
|------|--------|------|
| `app/lib/main.dart` | `main()` | Flutter binding, portrait lock, `runApp(ProviderScope(MainApp))`. |
| `app/lib/main.dart` | `MainApp.build` | `MaterialApp` with `home: HomeScreen()`. |

---

## 2. Start button → level map

| File | Symbol | Role |
|------|--------|------|
| `app/lib/screens/home_screen.dart` | `HomeScreen.build` | Layout; phone vs tablet branches. |
| `app/lib/screens/home_screen.dart` | `_buildPhoneQuizButtons` / `_buildTabletQuizButtons` | Renders the primary **Start Game** action (localized `start_game`). |
| `app/lib/screens/home_screen.dart` | `_quizButton` | `ElevatedButton` that runs the tap callback. |
| `app/lib/screens/home_screen.dart` | (anonymous `onPressed`) | `audio.playClick`, then `Navigator.push(popFadeRoute(LevelsScreen()))`. |
| `app/lib/screens/transitions/custom_page_routes.dart` | `popFadeRoute` | Builds a fade `PageRoute` to the next screen. |
| `app/lib/services/audio_service.dart` | `playClick` | Plays UI click SFX when enabled in settings. |

---

## 3. Level map shown (data + UI)

| File | Symbol | Role |
|------|--------|------|
| `app/lib/screens/levels_screen.dart` | `LevelsScreen` / `_LevelsScreenState` | Stateful screen for the scrollable “map” of main-level banners and sub-level nodes. |
| `app/lib/screens/levels_screen.dart` | `initState` | Creates scroll controllers/listeners; calls `_loadData()`. |
| `app/lib/screens/levels_screen.dart` | `_loadData` | Loads flow JSON, saved quiz/reminder/story progress, builds items, filters, sets scroll window; toggles `_loading`. |
| `app/lib/services/quiz_flow_loader.dart` | `loadGameFlow` | Reads `assets/data/flow/game-flow.json` + `game-flow-main-levels.json` → `QuizFlowData`. |
| `app/lib/services/quiz_progress_service.dart` | `QuizProgressService.loadProgress` | Loads persisted stars/diamonds per `progressKey`. |
| `app/lib/services/reminder_progress_service.dart` | `ReminderProgressService.loadProgress` | Loads reminder-level state. |
| `app/lib/services/story_config_loader.dart` | `loadStoryConfig` | Loads story configuration (optional path in `_loadData`). |
| `app/lib/services/story_progress_service.dart` | `StoryProgressService.loadProgress` | Loads which story pages were seen. |
| `app/lib/screens/levels_screen.dart` | `buildLevelItems` (top-level) | Flattens `QuizFlowData` into `LevelListItem` list (banners + `SubLevelItem`). |
| `app/lib/screens/levels_screen.dart` | `_applyFilter` | Produces `_filtered` list (visibility/unlock rules). |
| `app/lib/screens/levels_screen.dart` | `_findScrollStartIndex` | Chooses initial scroll anchor from progress. |
| `app/lib/screens/levels_screen.dart` | `_syncCompletedStoryPages` | May mark story events completed from quiz progress; `StoryProgressService.saveProgress`. |
| `app/lib/screens/levels_screen.dart` | `build` (and helpers) | Renders loading/error or `ScrollablePositionedList` of rows; sub-level taps call `_openQuiz`. |

---

## 4. User selects a level

| File | Symbol | Role |
|------|--------|------|
| `app/lib/screens/levels_screen.dart` | `_openQuiz` | Optional `_showBeforeStoryIfNeeded`; reminder prep `_ensureReminderQuestionsGenerated`; builds route via `_buildQuizRoute`; `navigator.push`; handles `LevelCompletionResult` (story after level, `_freshLoadData`, scroll anchor). |
| `app/lib/screens/levels_screen.dart` | `_buildQuizRoute` | Returns `popFadeRoute(QuizRunnerScreen(...))` with `subLevel`, `progressKey`, reminder args when applicable. |
| `app/lib/screens/levels_screen.dart` | `_freshLoadData` | Sets loading and calls `_loadData(anchorOrdinal:)` to refresh map after a run. |

---

## 5. Questions loaded (runner + JSON)

| File | Symbol | Role |
|------|--------|------|
| `app/lib/screens/quiz_runner_screen.dart` | `QuizRunnerScreen` / `_QuizRunnerScreenState` | Orchestrates one sub-level: load config, split phases, push quiz UI. |
| `app/lib/screens/quiz_runner_screen.dart` | `initState` | Schedules `_run()` on first frame. |
| `app/lib/screens/quiz_runner_screen.dart` | `_run` | Dispatches `_runRegular` vs `_runReminder`. |
| `app/lib/screens/quiz_runner_screen.dart` | `_runRegular` | `loadLevelConfig(subLevel.iconImageName)`; `_splitIntoPhases`; for each phase `_pushPhase`; then `Navigator.pop(LevelCompletionResult)` for the whole runner. |
| `app/lib/services/level_config_loader.dart` | `loadLevelConfig` | `rootBundle.loadString('assets/quiz-data/levels/{iconImageName}/questions.json')` → `LevelConfig.fromJson`. |
| `app/lib/models/level_config.dart` | `LevelConfig.fromJson` | Parses `levelQuestions` array. |
| `app/lib/models/level_config.dart` | `LevelQuestion._parseQuestion` | Reads `type`, `template`, `questionData`; fills template-specific data objects. |
| `app/lib/screens/quiz_runner_screen.dart` | `_splitIntoPhases` | Splits consecutive **image** vs **vocab/grammar** questions into separate `LevelConfig` slices (order preserved). |
| `app/lib/screens/quiz_runner_screen.dart` | `_pushPhase` | `Navigator.push(popFadeRoute(ImageQuizScreen(...)))` with `preloadedLevelConfig`, phase metadata, `isIntermediatePhase`, cumulative `previousCorrectCount`. |

---

## 6. Questions presented in order (per phase)

| File | Symbol | Role |
|------|--------|------|
| `app/lib/screens/image_quiz_screen.dart` | `ImageQuizScreen` / `_ImageQuizScreenState` | Single route that handles image quizzes and all convo templates for one phase. |
| `app/lib/screens/image_quiz_screen.dart` | `initState` | Timer/monster controllers; `_loadLevel()` or `_loadReminderLevel()`. |
| `app/lib/screens/image_quiz_screen.dart` | `_loadLevel` | Uses `preloadedLevelConfig` when provided; may fall back to `loadLevelConfig`; branches: legacy image manifest, **all-image** unified rows, or **convo-only** slice; resolves assets (`image_asset_resolver.resolveQuizImageAsset`), `precacheImage`, sets `_convoQuestions` or image lists; `setState` → `_Phase.playing`; `audio.startQuizMusic` where applicable; `_startTimer` for image mode. |
| `app/lib/services/game_config_loader.dart` | `GameConfig.load` | Global quiz timings/options used during play. |
| `app/lib/services/test_data_service.dart` | `TestDataService.isShortQuizEndAfter3With2Stars` | Optional debug short-circuit (read in `_loadLevel`). |
| `app/lib/screens/image_quiz_screen.dart` | `build` | `Scaffold` / AppBar; `_buildBody`. |
| `app/lib/screens/image_quiz_screen.dart` | `_buildBody` | Switches on `_Phase`: `_buildLoading`, `_buildImagePlaying` or `_buildConvoPlaying`, `_buildEnd`, `_buildGameOver`. |
| `app/lib/screens/image_quiz_screen.dart` | `_buildConvoPlaying` | Question label/progress; `_buildConvoQuestionBody` for template widgets + answer row where applicable. |
| `app/lib/screens/image_quiz_screen.dart` | `_buildConvoPlaying` / `_buildConvoQuestionBody` | ConvoTemplate-1 uses `_buildCharactersRow` + answer buttons inline; other templates use `_buildConvoQuestionBody` → `AppearDisappearQuizBody`, `ClozeSequenceQuizBody`, `SentenceBuilderQuizBody`, `WordPairsQuizBody`, `GrammarFormQuizBody`, or `DialogueCompletionQuizBody`. |
| `app/lib/screens/image_quiz_screen.dart` | `_buildImagePlaying` | Image or template-2 grid; monster/timer UI for image mode. |
| `app/lib/screens/quiz_templates/*.dart` | (widget `build` / internal state) | Template-specific UX (not enumerated line-by-line here). |
| `app/lib/screens/image_quiz_screen.dart` | `_goNext` | Advances `_currentIndex`; last question in phase either pops (intermediate phase) or `setState` → `_Phase.end`; reminder review branch when applicable. |
| `app/lib/screens/image_quiz_screen.dart` | `_displayQuestionIndexOneBased` / `_displayQuestionTotal` | Labels when `levelTotalQuestionCount` is set (cross-phase numbering). |

---

## 7. User answers

| File | Symbol | Role |
|------|--------|------|
| `app/lib/screens/image_quiz_screen.dart` | `_onAnswerTap` | Validates option vs `_correctAnswer`; `audio.playCorrect` / `playWrong`; `AchievementService.recordAnswer`; wrong → reminder tracking; schedules `_goNext` on correct after `_autoAdvanceDelayForCurrentImageQuestion`. |
| `app/lib/screens/image_quiz_screen.dart` | `_handleInteractiveConvoOutcome` | Same idea for interactive convo templates (e.g. AppearDisappear, ClozeSequence): on success increments `_correctCount` and delayed `_goNext`; on fail sets locked + Next. |
| `app/lib/screens/image_quiz_screen.dart` | `_buildConvoAnswerButton` | ConvoTemplate-1 multiple-choice taps → `_onAnswerTap`. |
| `app/lib/services/audio_service.dart` | `playCorrect` / `playWrong` | Feedback SFX. |
| `app/lib/services/achievement_service.dart` | `AchievementService.recordAnswer` | Per-answer achievement bookkeeping. |
| `app/lib/services/reminder_progress_service.dart` | `ReminderProgressService.recordWrongAnswer` | Wrong answers on regular levels (non-reminder). |
| `app/lib/screens/image_quiz_screen.dart` | `_onTimerExpired` / monster path | Can drive `_Phase.gameOver` on image quizzes (see `_buildGameOver`). |

---

## 8. Stars and diamonds calculated

| File | Symbol | Role |
|------|--------|------|
| `app/lib/screens/image_quiz_screen.dart` | `_stars` | Uses `_correctCount` + `widget.previousCorrectCount` vs `widget.levelTotalQuestionCount ?? _questionCount`; percentage thresholds → 0–3 stars; debug short-quiz override. |
| `app/lib/screens/image_quiz_screen.dart` | `_diamondsEarned` | `widget.previousCorrectCount + _correctCount` (correct answers in the run used as diamond tally for this completion). |
| `app/lib/screens/image_quiz_screen.dart` | `_buildEnd` | UI shows star row and `+$diamonds`; OK → `_onEndOk`. |

---

## 9. Level finishes (persist + navigate)

| File | Symbol | Role |
|------|--------|------|
| `app/lib/screens/image_quiz_screen.dart` | `_onEndOk` | Reminder: `ReminderProgressService.markReminderCompleted` then pop. Regular: `AchievementService.recordQuizCompleted`; if `stars >= 1` → `QuizProgressService.recordLevelCompletion` (stars max, diamond delta) and `ProfileService.registerQuizCompletion`; `Navigator.pop(LevelCompletionResult)`. |
| `app/lib/services/quiz_progress_service.dart` | `QuizProgressService.recordLevelCompletion` | Merges `highestStars` / `highestDiamonds`, updates `totalDiamonds`, `saveProgress`. |
| `app/lib/services/achievement_service.dart` | `AchievementService.recordQuizCompleted` | Duration-based achievement hook. |
| `app/lib/services/profile_service.dart` | `ProfileService.registerQuizCompletion` | Profile stats registration. |
| `app/lib/models/level_completion_result.dart` | `LevelCompletionResult` | Payload: `ordinalLevelIndex`, `completed`, `correctCount`, `isReminder`. |
| `app/lib/screens/quiz_runner_screen.dart` | `_runRegular` (after phases) | Pops runner with aggregated `completed` once all phases return. |
| `app/lib/screens/levels_screen.dart` | `_openQuiz` (after `push`) | Consumes result: `_freshLoadData`, optional story page, scroll anchor. |

---

## Quick reference: main JSON assets

| Asset path | Loaded by | Purpose |
|------------|-----------|---------|
| `assets/data/flow/game-flow.json` | `loadGameFlow` | Sub-level list (`iconImageName`, titles, progress keys). |
| `assets/data/flow/game-flow-main-levels.json` | `loadGameFlow` | Main-level banners metadata. |
| `assets/quiz-data/levels/{iconImageName}/questions.json` | `loadLevelConfig` | Questions, templates, `questionData` for that sub-level. |

---

## Maintenance

When adding screens or services on this path, extend this file with new **file + symbol** rows so the flow doc stays a reliable map for onboarding and debugging.
