# Project Memory

## Project
Flutter mobile language learning quiz app (portrait-only, Android/iOS). Unified quiz screen handles all question types (image, vocab, grammar).

## Current State
- **GrammarForm template removed entirely (2026-08-15)**: all `GrammarForm` question rows across ~65 level `questions.json` files converted to `ClozeSequence` (schema was already compatible — template-string swap only). `GrammarFormQuestionData`/`_parseGrammarForm`/`grammar_form_quiz_body.dart` deleted from code. Any older memory/doc references to a `GrammarForm` template are stale.
- **[Git checkout incident, 2026-08-15](feedback_git_checkout_scope.md)**: a directory-wide `git checkout -- assets/quiz-data/levels/` (run to undo an unrelated formatting mistake) discarded real uncommitted work in `greetings/adults`: 9 VideoConversation questions + 2 Chapter cards + 5-step tutorial config (recovered from VS Code Local History), a translations.json addition (not recovered — user's own backup turned out to be a pre-loss snapshot), and edits to two PNGs `how-old-are-you.png`/`where-is-she-from.png` (not recoverable, no local history for binary edits made outside an editor). Hard rule now in `cursor-claude-common/rules/rules.md`: never scope a revert wider than the exact file(s) known to be changed.
- **App now has a kids/adults flavor split and a tutorial overlay system** — not yet reflected in `cursor-claude-common/context/` docs. See [[project-app-flavor-and-tutorial]] for details (AppConfig.flavor, flavor-split flow/achievements/quiz-content JSON, `widgets/tutorial/`).
- **Current branch: feature/issue-29-video-questions** (uncommitted work as of 2026-08-08, reviewed again 2026-08-11 — still uncommitted, no new changes since). Implemented a new `VideoConversation` quiz template end-to-end for `greetings/adults` — see `app/lib/models/level_config.dart` (`VideoConversationQuestionData`, `VideoChoiceAnswerData`/`VideoSequenceAnswerData`/`VideoClozeAnswerData`, `_parseVideoConversation`), `app/lib/screens/quiz_templates/video_conversation_quiz_body.dart` (new widget), and `app/lib/screens/image_quiz_screen.dart` (`_videoControllerFor` — single `VideoPlayerController` persisted across all video rows in a level rather than recreated per-question; `_videoEndingDelaySeconds`; pauses the shared controller when advancing off video rows to avoid audio bleed into later non-video questions). `video_player: ^2.9.2` added to `pubspec.yaml`.
- **Also added a `Chapter` template**: passive non-quiz interstitial card (`{"template": "Chapter", "displayImage": "..."}`, no `questionData`) — image + Continue button, no quiz header/chrome. `ChapterQuestionData`/`LevelQuestion.isChapter` in `level_config.dart`; `chapter_card_body.dart` widget; `_advancePastChapter()` in `image_quiz_screen.dart` always increments `_correctCount` alongside advancing so it can never lower the end-of-level star rate. Chapter card title copy suggestions saved in [[chapter-card-title-suggestions]] — reuse for other sub-levels rather than re-deriving.
- **Known video_player pitfalls hit and fixed this session** (relevant if adding VideoConversation to other levels): (1) don't reseek backward just because playback position has "drifted" past a question's `startAt` — that's the *normal* case (controller keeps playing during the ~1.5s auto-advance delay) and reseeking mid-stream can leave some backends stuck; only seek when genuinely behind. (2) don't gate `play()` on `WidgetsBinding.instance.endOfFrame` — if nothing else in the convo phase is requesting a frame (true once initialized/no seek needed, i.e. every question after the first) it can hang forever with zero exceptions thrown; use a fixed short `Future.delayed` instead. (3) after auto-pausing at a question's `pause_at`, explicitly `seekTo` the exact target too — position-update polling isn't continuous, so by the time a pause is noticed, playback has usually overshot into the next line's audio. (4) `-d web-server` does not reliably relay browser console/debugPrint output to the terminal; use `-d chrome` for that, or check the browser's own DevTools console.
- **Story overlays (still true per last review):** Single text source `story_text` locale map; templates 1 (`StoryTemplateA`/`character_dialog_scene`), 4 (`StoryTemplateC`/`scene_story_text`), and 5 (`StoryTemplateD`/`multi_image_gallery`, carousel of `scene_images` + `story_texts`) are valid. Template B and animation-only (3) remain removed. Story completion is per sub-level (>=1 star), no `covered_levels_number`.

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

## Architecture Notes
- [Kids/adults flavor + tutorial system](project_app_flavor_and_tutorial.md) — AppConfig.flavor split, flavor-specific flow/achievements/quiz-content JSON, `widgets/tutorial/` overlay framework. Not yet documented in `cursor-claude-common/context/`.
- [VideoConversation audio = extracted from source video, not TTS](project_video_conversation_audio_extraction.md) — `audio_file1`/`audio_file2` clips are `ffmpeg`-cut from the level's `.mp4` at `start_at`/`pause_at`/`answer_until`; no committed script does this. Full recipe + diagnostic also in `architecture-technical-context.md`.

## Audit Workflow
- Prior consumed words file: `cursor-claude-common/output/prior-words-by-type.md` — read this instead of running the gather script. Check the header to confirm it matches the target level; regenerate with the script only if auditing a different level.
- [Grammar-progression idiom exceptions](feedback_grammar_progression_idioms.md) — user accepts short fixed idiomatic phrases (greetings/farewells/courtesy chunks) at ML1 even if they use later-ML grammar (e.g. imperative); still flag but treat as low-priority.
- [Stem words OK in translations](feedback_stem_words_ok_in_translations.md) — ClozeSequence and ConvoTemplate-1 sentence-stem words now qualify for translations.json, not just blank answers; only distractors stay excluded. Saved into SKILL.md directly. Supersedes the older ConvoTemplate-1-only fix.
- [Grammar progression restructured into 4 Parts](feedback_grammar_progression_4parts.md) — audit-quiz-level's 12-ML grammar table replaced with 4 aggregated macro-bands (ML1-3/4-5/6-8/9-12); saved directly into SKILL.md and reference.md.
- [Scan all 8 reference CSVs](feedback_full_reference_file_scan.md) — vocabulary suggestions must check auxiliaries/common-verbs/conjunctions/prepositions/nouns too, not just verbs/adjectives/adverbs.
- [Chapter card title suggestions](chapter-card-title-suggestions.md) — candidate/chosen copy for `Chapter` template cards; check before authoring new ones for other sub-levels.

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
