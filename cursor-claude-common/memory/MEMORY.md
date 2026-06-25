# Project Memory

## Project
Flutter mobile language learning quiz app (portrait-only, Android/iOS). Unified quiz screen handles all question types (image, vocab, grammar).

## Current State
- **Active issue:** Issue-27 — Level translations page (end-of-level word table + "Words" button on levels map). Plan consolidated at `cursor-claude-common/plans/consolidated-issue-27-level-translations-plans.md`; per-level `translations.json` (`translations_list` of `{english_word, translations:{locale:...}}`) drives a scrollable English|local table shown before final results screen (skipped if `userLanguage=='en'`, list empty, or reminder run), plus a "Words" button on levels map for completed levels (stars>=1) opening the same table in a fade dialog with OK.
- **Current branch:** feature/issue-27-level-translations-page
- **Last completed:** Issue-26 (audio play rules refactor — answer audio gating, AudioPlayButton visibility, TranslationRevealButton disabled-during-audio, post-answer sequencing)
- **Issue-27 status:** Plan written, not yet implemented (no translations screen file exists yet as of last check)
- **Story overlays simplified on this branch (not part of Issue-27):** Single text source `story_text` locale map only; only `page_template_id` 1 (`StoryTemplateA`/`character_dialog_scene`) and 4 (`StoryTemplateC`/`scene_story_text`) remain valid — template B and animation-only removed. Story completion is per sub-level (>=1 star), no `covered_levels_number`.
- **Other branch fixes (not part of Issue-27):** ClozeSequence multi-blank wrong-answer highlight shows all remaining expected tiles; DialogueCompletion answer buttons now also locked during line1 audio.

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
26 → Audio play rules refactor: answer-bearing clips no longer play before the user answers; Next/auto-advance gated on required post-answer playback. ConvoTemplate-1 dual audio_file1/audio_file2, Case A/B present-time playback split by which line is cloze; DialogueCompletion/ClozeSequence/SentenceBuilder aligned to same present-vs-outcome audio spec; missing audio on disk/data hides the audio feature entirely for that question; AudioPlayButton stays visible whenever audioAssetPath is non-null; TranslationRevealButton globe-tap plays outcome audio like a wrong answer then applies tr_ok penalty, disabled during playback
25 → Translation field restructure: english_to_translate/local_translation arrays, locale-keyed map {"tr":[...]}, tr_ok penalty (globe tap = wrong, reveals in blue), TranslationRevealButton onRevealed callback, greetings questions.json cleanup
24 → Audio/translation/monster refactoring: per-template audio wiring, TranslationRevealButton, Simon template removed, Gemini TTS dual single-speaker calls, gender voice tokens
23 → Dev-time TTS generation (Gemini script in `tools/gemini_tts/`), in-game audio playback wiring via `audio_file` JSON tag, AppearDisappear words as string-or-array, SentenceBuilder correct_order as string-or-array, WordPairs locale-map refactor, GrammarForm hintWord removal, AudioService helpers
22 → Template refactor: removed global Translate toggle; JSON translation maps drive auxiliary copy for non-en; unified question header; GrammarForm/DialogueCompletion EN-primary; monster eligibility limited to imageQuizTemplate-1/2 (SpotDifference later removed)
21 → Additional Quiz Templates batch2: SentenceBuilder, WordPairs (with matched-section layout), imageQuizTemplate-3, GrammarForm, DialogueCompletion; WordPairs green-hint bug fix; per-question `timer_seconds` override for all image templates; ConvoTemplate-2 merged into ClozeSequence (localized map, train tiles, streaming, translation hint, backward-compat adapter)
20 → New Image and Vocab Templates: AppearDisappear, Simon, ClozeSequence (old), imageQuizTemplate-2; localization keys; quiz session flow docs
19 → Activity-Based Quiz Restructuring (58 activity folders, image pool, game-flow.json)
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
