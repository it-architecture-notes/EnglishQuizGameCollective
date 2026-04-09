# Project Context - What this app does

This is a portrait-only Flutter mobile app (Android/iOS) — a language-learning quiz game with multiple-choice questions across three categories:

**Image Quiz:** Player sees an image and picks the correct label from 4 options.

**Vocabulary Quiz:** Interactive or conversation-based templates where the player fills blanks or completes sequences.

**Grammar Quiz:** Same mechanics as vocabulary quiz but targets grammatical form selection.

Players progress through activity-based levels, earning stars and diamonds. The app includes profile/avatar management, achievements, a friends panel (animal unlocks via diamonds), and settings. Narrative-driven story overlays (Gardenscapes-style) unlock between main levels.

---

## Current Implementation Snapshot

- **Unified quiz screen** (`image_quiz_screen.dart`) handles all 12 question templates in a single flow — image templates, interactive convo bodies, monster/timer, and completion UI.
- **Activity-based levels**: 60 curated activity folders under `app/assets/quiz-data/levels/{activity}/`, each with a `questions.json` and images. Game flow defined in `game-flow.json` (60 sub-levels, 12 main levels).
- **Progression**: level unlock by performance, star/diamond rewards, saved best results, reminder levels (wrong-answer weighted).
- **Story overlays**: Gardenscapes-style overlays between main levels, driven by `game-main-level-stories.json`.
- **Profile**: editable name/avatar, lifetime stats.
- **Achievements**: config-driven with lock/progress states.
- **Friends**: diamond-based animal unlock, persistent.
- **Settings**: language (en/fr/es/tr), music, sound/FX, persisted via SharedPreferences.

---

## Quiz Templates

**Image templates** (rendered in `image_quiz_screen.dart`):

| Template | Behaviour |
|----------|-----------|
| `imageQuizTemplate-1` | Hero image + 4 word buttons. Optional `"answer"` overrides the correct label. Monster-eligible. |
| `imageQuizTemplate-2` | Noun label + 4 image tiles to pick from. Monster-eligible. |
| `imageQuizTemplate-3` | Hero image + 4 full-sentence buttons. |
| `imageQuizTemplate-SpotDifference` | Two side-by-side images; tap the correct one. Monster-eligible. |

**Convo/interactive templates** (each in `app/lib/screens/quiz_templates/`):

| Template | Description |
|----------|-------------|
| `ConvoTemplate-1` | Two-character dialogue with a blank; 4 MCQ buttons. |
| `ConvoTemplate-ClozeSequence` | Localized sentence with blank(s); word tiles in a horizontal train; optional streaming and image thumbnail. |
| `ConvoTemplate-AppearDisappear` | Words flash one-by-one, then player recalls order from a shuffled grid. |
| `ConvoTemplate-Simon` | Simon-says sequence: demo highlight → player repeats. |
| `ConvoTemplate-SentenceBuilder` | Tap shuffled word tiles in the correct sentence order. |
| `ConvoTemplate-WordPairs` | Match left-column words to scrambled right-column; correct pairs move to a bottom section. |
| `ConvoTemplate-GrammarForm` | Cloze sentence + lemma hint; 4 word-form buttons. |
| `ConvoTemplate-DialogueCompletion` | First speaker line shown; player picks the correct reply from 4 options. |

---

## Monster System

Monster attack animation applies to `imageQuizTemplate-1`, `imageQuizTemplate-2`, and `imageQuizTemplate-SpotDifference` only. The monster advances through 4 proximity steps toward game-over:
- ≤6 eligible questions in the level → advance every wrong answer (1-per-wrong)
- >6 eligible questions → 1,2,1,2 wrong-answer pattern (cumulative thresholds: 1, 3, 4, 6)

---

## Translation System

The global Translate toggle is removed. Translations are configured per-question in JSON and shown automatically for non-English users:
- Most templates: `"translation"` map inside `questionData`
- `ConvoTemplate-1`: `"line1_translation"` / `"line2_translation"` inside `questionData`
- `ConvoTemplate-DialogueCompletion`: `"line1_translation"` / `"answer_translation"` inside `questionData`
- `ConvoTemplate-AppearDisappear`: `"translation"` at the top level of the question object (sibling to `questionData`)
- No translation support: ClozeSequence, WordPairs, Simon, SpotDifference

---

## Key Files

| File | Role |
|------|------|
| `app/lib/screens/image_quiz_screen.dart` | Unified quiz screen |
| `app/lib/models/level_config.dart` | All question data classes and JSON parsers |
| `app/lib/screens/quiz_runner_screen.dart` | Phase-splits questions, dispatches to quiz screen |
| `app/lib/services/level_config_loader.dart` | Loads per-level `questions.json` |
| `app/assets/data/flow/game-flow.json` | 60 sub-levels, 12 main levels |
| `app/assets/data/settings/localization.json` | All UI strings (en/fr/es/tr) |
| `cursor-claude-common/context/active-progress-context.md` | Current active issue |
| `cursor-claude-common/context/page-designs-and-templates.md` | Per-template UX and JSON schema reference |
| `cursor-claude-common/rules/rules.md` | Project development rules |
| `app/codebase_signatures.md` | Class/method signatures — read before pulling full files |

---

## Asset Layout

```
app/assets/
├── images/
│   ├── backgrounds/{bucket}/   ← phone_tall / phone_wide / tablet_43 / tablet_1610
│   ├── characters/             ← {name}.png
│   ├── animals/{name}/         ← {name}-1..5.png (distress poses)
│   ├── monsters/{name}/
│   ├── level-icons/
│   └── story/
├── data/
│   ├── config/                 ← game_config.json
│   ├── settings/               ← localization.json
│   ├── flow/                   ← game-flow.json, game-flow-main-levels.json
│   └── story/                  ← game-main-level-stories.json
└── quiz-data/
    ├── _image-pool/            ← shared pool of 700+ images
    └── levels/{activity}/      ← questions.json + images per activity
```
