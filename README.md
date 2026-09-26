# English Quiz Game

Portrait-only mobile app (Android + iOS) for language learning quizzes. See [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) for features and scope.

## Tech stack

- **Flutter** (Dart), Android and iOS, portrait only. Details: [.cursor/context/architecture-technical-context.md](.cursor/context/architecture-technical-context.md).

## Run the app

From the `app/` directory:

```bash
cd app
flutter pub get
flutter run
```

Use a connected device or an Android/iOS emulator. Orientation is locked to portrait.

### Run in Chrome as iPhone 12 Pro size

From the `app/` directory, run Flutter web with a fixed Chrome window size that matches iPhone 12 Pro CSS resolution (`390x844`) and open DevTools automatically:

```bash
flutter run -d chrome \
  --web-port=8080 \
  --web-browser-flag="--window-size=390,844" \
  --web-browser-flag="--auto-open-devtools-for-tabs"
```

- Change `--web-port=8080` to any port you want.
- If you prefer a custom port, for example `9010`, use `--web-port=9010`.

If the iOS or Android project is incomplete (e.g. you cloned without running Flutter yet), run from `app/`:

```bash
flutter create . --platforms=android,ios
```

Then re-apply portrait lock if needed: Android `android:screenOrientation="portrait"` in `app/android/app/src/main/AndroidManifest.xml`, iOS only `UIInterfaceOrientationPortrait` in `app/ios/Runner/Info.plist`.

## Scripts (`tools/`)

Python scripts for content authoring, auditing, and vocabulary/audio maintenance. Most take
`--flavor {kids,adults-intermediate,adults-beginner}` and/or `--dry-run`; run with `--help`
for the exact options. Newest / most-used ones first.

| Script | What it does |
|--------|--------------|
| `generate_level_script_md.py` | Generates a plain "script" markdown file per flavor — dialogue lines only (no answers/distractors), in game-flow order: video and standalone dialogue lines, image-quiz question→answer pairs, and WordPairs English words. A fast readthrough of a level's actual content. |
| `refresh_adults_beginner_vocab_references.py` | One-shot wrapper: refreshes the adults-beginner-scoped word counts/Oxford marks, then regenerates both adults-beginner vocabulary outputs (by-level and word-index) — the single command to run after editing adults-beginner level content. |
| `update_final_word_counts_from_levels.py` | Rescans level JSON (optionally scoped to one `--flavor`) and refreshes `all-ai-common/references/final words/*.csv`, plus marks matched headwords with `**` (and their level name(s)) in `remove-word-list-references/3000 words oxford.txt`. |
| `gemini_tts/generate_level_audio.py` | Generates a level's `.m4a` TTS audio clips (Gemini), with gender/voice routing from each row's `genders` field and loudness mastering against a reference file. |
| `gather_adults_beginner_level_words.py` | Gathers adults-beginner vocabulary per level (grouped by level or as an inverted word index), in game-flow order; used to produce `all-ai-common/output/adults-beginner-words-by-level.md` / `-word-index.md`. |
| `gather_adults_intermediate_level_words.py` | Same as above, for the adults-intermediate flavor. |
| `gather_prior_level_words.py` | Lists every word already taught (by flavor) before a given level — for checking new content doesn't reuse untaught vocabulary. |
| `gather_adults_mixed_audio_texts.py` | Dumps spoken/audio base text for every non-image question across adult levels. |
| `gather_all_kids_questions.py` | Consolidates every kids non-image question, across every level, into one file. |
| `generate_global_questions_table.py` | Builds a markdown table of questions across all levels. |
| `generate_single_level_questions_table.py` | Builds a markdown table of questions (and translations, when present) for one level. |
| `extract_wordpairs_english_words.py` | Collects every `english_words` entry from `WordPairs` questions across level JSON. |
| `global_game_word_frequency.py` | Scans every level's `questions.json`/`translations.json` and writes a word-frequency CSV. |
| `global_game_word_frequency_big_scope.py` | Broader companion to the above — same scanning, wider CSV scope. |
| `generate_unused_word_groups.py` | Builds frequency-ordered groups of reference vocabulary not yet used in any level, for planning new common-words levels. |
| `build_distr_optimized_19_groups.py` | Builds 19 vocabulary groups aligned to the distr-reference templates. |
| `mark_words_by_used_level_words.py` | Marks lines or CSV rows whose text matches level vocabulary. |
| `filter_oxford_wordlist_b2_and_object_nouns.py` | Filters an Oxford-style word list down to B2-and-below / object-noun entries. |
| `prune_oxford_wordlist_star_gaps.py` | Prunes tabbed filler lines from the Oxford 3000 word list between two given rows. |
| `audit_grammar_progression.py` | Scans all game-flow levels for grammar-progression violations (per the `audit-quiz-level` skill's rules). |
| `audit_level_images.py` | Audits level image folders against `imageQuizTemplate-1/2` references in `questions.json`. |
| `validate_quiz_level_json.py` | Validates JSON syntax and minimal schema for files under `app/assets/quiz-data/levels`. |
| `dedupe_to_be_examined_pngs.py` | Removes PNGs under `levels/to-be-examined/` that already exist elsewhere. |

## Folder Structure

| Folder | Purpose |
|--------|---------|
| **context/** | Categorized context files. Fill these first—see [context/CONTEXT_INDEX.md](context/CONTEXT_INDEX.md) for fill order. |
| **commands/** | Reusable prompts for common tasks (initiate, generate tests, review). |
| **rules/** | Project rules the AI should follow. |
| **plans/** | Plan template for task breakdown. |
| **decisions/** | ADR (Architecture Decision Record) template. |
| **reference-docs/** | Place API specs, Figma links, BRDs here. Linked from project-context. |

## Quick Start

1. Copy this template into your project root.
2. Follow the fill order in [context/CONTEXT_INDEX.md](context/CONTEXT_INDEX.md).
3. Update [context/progress-context.md](context/progress-context.md) at the start of each session.

## Context Files Overview

- **project-context.md** — Overview, stakeholders, features, business rules, project status
- **architecture-technical-context.md** — Tech stack, structure, patterns, security
- **coding-standards-context.md** — Naming, formatting, patterns, anti-patterns
- **domain-glossary-context.md** — Shared vocabulary (entities, terms, acronyms)
- **progress-context.md** — Feature progress, current task, relevant files, done-in-session (update per session)
- **non-functional-requirements-context.md** — Performance, scalability, compliance
- **deployment-cicd-infrastructure-context.md** — Testing, CI/CD, deployment, secrets
