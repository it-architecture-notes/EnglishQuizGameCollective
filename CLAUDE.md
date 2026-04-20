# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a portrait-only mobile app (Android/iOS) — a language learning quiz app with multiple-choice questions across three categories:

- **Image Quiz:** Shows an image; player picks the correct label from 4 options.
- **Vocabulary Quiz:** Conversation or interactive template with blanks; player fills missing vocabulary.
- **Grammar Quiz:** Like vocabulary quiz but targets grammatical form selection.

Players earn stars and diamonds per level. Narrative-driven achievements (Gardenscapes-style) unlock as they progress. All configuration and state is stored in JSON files.

## Tech Stack

- Flutter (Dart), Riverpod, portrait-only (Android + iOS)
- `app/` is the Flutter project root
- JSON for config / quiz content / state; SharedPreferences for persistence
- Four resolution buckets: `phone_tall`, `phone_wide`, `tablet_43`, `tablet_1610`

## Key Source Files

| File | Role |
|------|------|
| `app/lib/screens/image_quiz_screen.dart` | Unified quiz screen — handles all image + convo templates, monster/timer, animations |
| `app/lib/models/level_config.dart` | All question data classes and JSON parsers |
| `app/lib/screens/quiz_runner_screen.dart` | Splits questions by type, dispatches to ImageQuizScreen |
| `app/lib/services/level_config_loader.dart` | Loads per-level `questions.json` |
| `app/lib/services/image_quiz_level_loader.dart` | Asset discovery (animals, monsters) |
| `app/lib/screens/levels_screen.dart` | Level selection, scroll, reminder unlock |
| `app/lib/models/reminder_progress.dart` | Reminder level state |
| `app/lib/services/reminder_progress_service.dart` | Reminder state + question generation |
| `app/lib/screens/story/story_overlay_screen.dart` | Story overlay |

## Quiz Templates

All templates are dispatched from `image_quiz_screen.dart`. Each question row in `questions.json` carries a `"template"` key.

**Image templates** (rendered inline in `_buildImagePlaying`):
| Template | Description |
|----------|-------------|
| `imageQuizTemplate-1` | Hero image + 4 text buttons (words or sentences). Optional `"answer"` overrides correct label; optional `"timer_seconds"` overrides timer. JSON may use `wrongAnswers` or `distractors` for the three wrong options. |
| `imageQuizTemplate-2` | Noun label + 4 image tiles. |
Monster attack animation applies **only** to `imageQuizTemplate-1` and `imageQuizTemplate-2`. For levels with ≤6 such questions advance every wrong answer; >6 use a 1,2,1,2 wrong-answer pattern.

**Convo/interactive templates** (each has a dedicated widget in `app/lib/screens/quiz_templates/`):
| Template | Widget file |
|----------|-------------|
| `ConvoTemplate-1` | Built inline in `image_quiz_screen.dart` (`_buildCharactersRow`) |
| `ConvoTemplate-ClozeSequence` | `cloze_sequence_quiz_body.dart` |
| `ConvoTemplate-AppearDisappear` | `appear_disappear_quiz_body.dart` |
| `ConvoTemplate-Simon` | `simon_quiz_body.dart` |
| `ConvoTemplate-SentenceBuilder` | `sentence_builder_quiz_body.dart` |
| `ConvoTemplate-WordPairs` | `word_pairs_quiz_body.dart` |
| `ConvoTemplate-GrammarForm` | `grammar_form_quiz_body.dart` |
| `ConvoTemplate-DialogueCompletion` | `dialogue_completion_quiz_body.dart` |

**Translation:** The global Translate toggle is removed. Per-question `translation` / `line1_translation` / `line2_translation` / `answer_translation` maps in JSON show auxiliary text automatically when `userLanguage != 'en'`. `ConvoTemplate-AppearDisappear` keeps its `translation` at the top level of the question object (sibling to `questionData`). ClozeSequence, WordPairs, and Simon have no translation support.

## Asset Layout (current)

```
app/assets/
├── images/
│   ├── backgrounds/{bucket}/background.png
│   ├── characters/          ← {name}.png per character
│   ├── avatars/
│   ├── level-icons/
│   ├── animals/{name}/      ← {name}-1..5.png (distress poses)
│   ├── monsters/{name}/     ← monster sprites
│   └── story/               ← story scene images
├── data/
│   ├── config/              ← game_config.json
│   ├── settings/            ← localization.json
│   ├── flow/                ← game-flow.json, game-flow-main-levels.json
│   └── story/               ← game-main-level-stories.json
└── quiz-data/
    ├── _image-pool/         ← shared image pool (726 images)
    └── levels/{activity}/   ← questions.json + images per activity level
```

## Context Management Workflow

Development progress is tracked in `cursor-claude-common/context/` (shared with Cursor):

- `active-progress-context.md` — the **single** active issue; developer adds issues here directly
- `progress-context-archive.md` — summarized completed items (most recent first)
- `full-project-issue-archive.md` — verbatim copy of each completed issue (most recent first)
- `architecture-technical-context.md` — tech stack and asset layout decisions
- `page-designs-and-templates.md` — per-template UX and JSON schema reference

Plans live in `cursor-claude-common/plans/`. Rules live in `cursor-claude-common/rules/rules.md`.

When an issue is completed and accepted it is archived in both archive files above.

## Key Rules

For full rules refer to `cursor-claude-common/rules/rules.md`. Key points:

- One issue at a time. Present a plan first, wait for approval before implementing.
- Never work on `main` — always use a feature branch.
- Never commit unless explicitly asked.
- Consult `app/codebase_signatures.md` before reading full files to save context.
- No tests, no over-engineering, no speculative features.
