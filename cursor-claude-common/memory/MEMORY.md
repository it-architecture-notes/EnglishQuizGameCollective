# Project Memory

## Project
Flutter mobile language learning quiz app (portrait-only, Android/iOS). Unified quiz screen handles all question types (image, vocab, grammar).

## Current State
- **Current branch:** feature/issue-27-level-translations-page (still active, up to date with origin, many commits past the original Issue-27 commit)
- **Issue-27 status:** Implemented (commit e07ac8d "Issue-27: level translations page, story config simplification, quiz fixes"). Files: `app/lib/models/level_translations.dart`, `app/lib/widgets/level_translations_view.dart`. Per-level `translations.json` drives the end-of-level word table + "Words" button on levels map, per original plan.
- **Latest commit (HEAD): e4f0344 "Big Commit Milestione 1 - After Questions and Images"** (2026-07-19, 534 files changed). Major changes:
  - **`game-flow.json` schema change:** non-reminder flow entries renamed `iconImageName` → `directoryName`. Reminder entries are now explicit flow-list items (`"iconImageName": "reminder", "kind": "reminder", "reminderIndex": N`) interleaved after each main level's regular sub-levels, rather than being implicit/derived.
  - Many `level-icons/*.png` renamed to `at-the-*.png` convention (e.g. `airport-2.png` → `at-the-airport.png`, `hospital.png` → `at-the-hospital.png`), several new icons added (bank, cinema, dentist, farm, farmers-market, garage, hotel, library, office, park, pharmacy, post-office).
  - New skill `cursor-claude-common/skills/redistribute-level-vocabulary/SKILL.md` — report-only workflow to move vocabulary words to their best-fit level and backfill displaced levels via a recursive replacement chain (default start `waking-up`; stops chain at medley levels or unused-word pool).
  - New tool `tools/generate_unused_word_groups.py`; `gather_prior_level_words.py`, `generate_single_level_questions_table.py`, `update_final_word_counts_from_levels.py` updated.
  - `game-main-level-stories.json` and `story-templates.json` expanded (+397/+7 lines) — added a **5th story template**, `multi_image_gallery` (`StoryTemplateD`, `page_template_id` 5): carousel of `scene_images` with parallel `story_texts` caption locale-maps, Previous/Next controls, OK on last slide dismisses overlay. This supersedes the earlier "only templates 1 and 4 are valid" note — **template 5 is now also valid**.
- **Uncommitted working-tree change:** `app/assets/data/story/game-main-level-stories.json` — all `story_text` locale maps are being stripped down to `"en"` only (removing fr/tr/es/de/it/pt/ru/zh/ja/ko/ar/hi translations from existing story beats). Not yet committed; unclear if finished or intentional final state — verify before assuming translations are gone for good.
- **In-progress content work (documented but not yet wired into JSON beyond the diff above):** `cursor-claude-common/output/BRIDGE-*.md` + `BRIDGE-VISUAL-FLOW.txt` + `INDEX.md` describe a new ML4 story "The Bridge of Wobbling Wood" (characters Ben & Mia, 7 story images `bridge-1.png`…`bridge-7.png` across ML4 sub-levels, watercolor storybook art style). Per `BRIDGE-QUICK-REFERENCE.md`: "JSON configuration already complete", next step is illustration creation + placing images in `app/assets/images/story/`. These `cursor-claude-common/output/*` files are untracked (`git status`).
- **Story overlays simplified on branch (bundled in e07ac8d, still true for templates 1/4):** Single text source `story_text` locale map; `page_template_id` 1 (`StoryTemplateA`/`character_dialog_scene`) and 4 (`StoryTemplateC`/`scene_story_text`) — plus now template 5 (`StoryTemplateD`, see above). Template B and animation-only (3) remain removed. Story completion is per sub-level (>=1 star), no `covered_levels_number`.
- **Other fixes bundled in e07ac8d:** ClozeSequence multi-blank wrong-answer highlight shows all remaining expected tiles; DialogueCompletion answer buttons now also locked during line1 audio.

## Tech Stack
- Flutter (Dart), Riverpod, portrait-only
- JSON files for config/state/settings
- SharedPreferences for persistence
- `app/` is the Flutter project root

## Key Context Files
- `cursor-claude-common/context/active-progress-context.md` — current issue (currently: Issue-27 translations page spec, story overlay config spec, and misc branch fixes — no cleared/new active issue since e07ac8d)
- `cursor-claude-common/context/progress-context-archive.md` — completed issues summary
- `cursor-claude-common/context/architecture-technical-context.md` — tech/asset layout
- `cursor-claude-common/context/story-templates-and-design.md` — story template registry (now 5 templates, see Current State)
- `cursor-claude-common/context/page-designs-and-templates.md` — per-quiz-template UX/JSON schema reference
- `cursor-claude-common/rules/rules.md` — project rules
- `app/codebase_signatures.md` — consult before reading full Dart files, to save tokens (per CLAUDE.md instruction)

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

## Audit Workflow
- Prior consumed words file: `cursor-claude-common/output/prior-words-by-type.md` — read this instead of running the gather script. Check the header to confirm it matches the target level; regenerate with the script only if auditing a different level.
- [Grammar-progression idiom exceptions](feedback_grammar_progression_idioms.md) — user accepts short fixed idiomatic phrases (greetings/farewells/courtesy chunks) at ML1 even if they use later-ML grammar (e.g. imperative); still flag but treat as low-priority.
- [Stem words OK in translations](feedback_stem_words_ok_in_translations.md) — ClozeSequence and ConvoTemplate-1 sentence-stem words now qualify for translations.json, not just blank answers; only distractors stay excluded. Saved into SKILL.md directly. Supersedes the older ConvoTemplate-1-only fix.
- [Grammar progression restructured into 4 Parts](feedback_grammar_progression_4parts.md) — audit-quiz-level's 12-ML grammar table replaced with 4 aggregated macro-bands (ML1-3/4-5/6-8/9-12); saved directly into SKILL.md and reference.md.
- [Scan all 8 reference CSVs](feedback_full_reference_file_scan.md) — vocabulary suggestions must check auxiliaries/common-verbs/conjunctions/prepositions/nouns too, not just verbs/adjectives/adverbs.

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
