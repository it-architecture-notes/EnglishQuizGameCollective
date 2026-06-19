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

### Global config (`app/assets/data/config/game_config.json`)

| Key | Default | Description |
|-----|---------|-------------|
| `imageQuizTimerSeconds` | `5` | Monster timer duration (seconds) for image-template questions. |
| `autoAdvanceDelaySeconds` | `1.5` | Seconds to wait after a correct answer before auto-advancing to the next question. Applies to all templates. |
| `showCorrectOnWrong` | `false` | Whether to highlight the correct tile when the player taps the wrong one (imageQuizTemplate-2). |

### Level-wide fields (`questions.json` root)

| Field | Description |
|-------|-------------|
| `"timer_seconds"` | Optional. Level-wide monster timer (seconds). Overrides `imageQuizTimerSeconds` from `game_config.json`. Omit to use the global default. |
| `"levelQuestions"` | Array of question objects. |

### Per-question top-level fields

Every question object has these top-level fields:

| Field | Required | Description |
|-------|----------|-------------|
| `"template"` | ✓ | Template ID (see below); image vs convo mode is inferred from the name (`imageQuizTemplate-*` vs others) |
| `"questionData"` | ✓ | Template-specific fields (see per-template tables) |
| `"audio_file"` | optional | Audio basename (no extension) played when the question appears. Used by most templates. |
| `"audio_file1"` | optional | DialogueCompletion — question line. ConvoTemplate-1 — first line clip (use with `audio_file2`; blanks filled in asset). |
| `"audio_file2"` | optional | DialogueCompletion — correct answer. ConvoTemplate-1 — second line clip (requires `audio_file1`). |

---

### Image Templates (rendered in `image_quiz_screen.dart`)

#### `imageQuizTemplate-1` — hero image + text buttons
**Monster-eligible:** yes

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `imageName` | ✓ | Asset basename (no extension) for the hero image |
| `wrongAnswers` or `distractors` | ✓ | Array of exactly 3 wrong text options |
| `answer` | optional | Overrides the correct label (defaults to `imageName`) |

Answer options: 4 shuffled text buttons. Supports words, phrases, or full sentences.  
Translation: none.  
Legacy aliases: `imageQuizTemplate-3` and `imageQuizTemplate-SentenceChoice` both normalize to this template at parse time.

---

#### `imageQuizTemplate-2` — noun prompt + image grid
**Monster-eligible:** yes

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `imageName` | ✓ | Asset basename for the correct image tile |
| `wrongAnswers` | ✓ | Array of exactly 3 wrong image basenames |
| `answer` | optional | Overrides the text prompt shown (defaults to `imageName`) |

Answer options: 2×2 shuffled image grid.  
Translation: none.

---

### Convo/Interactive Templates (each in `app/lib/screens/quiz_templates/`)

#### `ConvoTemplate-1` — two-character dialogue + 4 MCQ buttons
**Monster-eligible:** no

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `character1` | ✓ | Name of speaker 1 |
| `character2` | ✓ | Name of speaker 2 |
| `line1` | ✓ | English string — speaker 1's line |
| `line2` | ✓ | English string — speaker 2's line (blank `___` in the active line) |
| `answer` | ✓ | Correct option (English string) |
| `distractors` | ✓ | Array of exactly 3 wrong options |
| `image_file_name` | optional | Asset basename for a 72×72 thumbnail above the dialogue |
| `english_to_translate` | optional | Array of English words/sentences to show in the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index with `english_to_translate` |

**Top-level audio:** `audio_file` (single combined clip), or **`audio_file1` + `audio_file2`** together for split clips (see root field table).

Answer options: 4 shuffled text buttons.

---

#### `ConvoTemplate-ClozeSequence` — sentence with blanks, fill by tapping tiles
**Monster-eligible:** no

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `sentence` | ✓ | Plain English string with `_____` blank markers (locale maps not accepted) |
| `answer` or `answers` | ✓ | Single string or array; count must equal number of blanks |
| `distractors` | ✓ | Array of extra wrong word tiles |
| `imageName` | optional | Asset basename for a 72×72 thumbnail (omit = no image) |
| `english_to_translate` | optional | Array of English words/sentences to show in the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index with `english_to_translate` |

Answer options: horizontal tile row. The full sentence (with numbered blanks) is shown as soon as the question appears; player taps to fill blank 1, then 2, … in order.

---

#### `ConvoTemplate-AppearDisappear` — memorise words, then recall order
**Monster-eligible:** no

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `words` | ✓ | String (space-split) or array — the words to memorise |
| `distractors` | optional | Extra tiles to fill the grid (up to 9 total with target words) |
| `display_duration` | optional | Legacy timing param (default 1.0) |
| `english_to_translate` | optional | Array of English words/sentences to show in the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index with `english_to_translate` |

Answer options: 3×3 shuffled tile grid.  
Audio: `audio_file` (top-level) — plays while words are visible; words disappear 500 ms after audio ends.

---

#### `ConvoTemplate-SentenceBuilder` — unscramble the sentence
**Monster-eligible:** no

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `correct_order` | ✓ | Space-split string or array — sentence tokens in correct order |
| `english_to_translate` | optional | Array of English words/sentences to show in the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index with `english_to_translate` |

Answer options: all tokens from `correct_order` shuffled into a tile Wrap (no extra distractors).

---

#### `ConvoTemplate-WordPairs` — match English words to their translations
**Monster-eligible:** no

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `english_words` | ✓ | Array of 3–6 English words/phrases (left column) |
| `translations` | ✓ | Array of locale maps — same length as `english_words` |

Answer options: two columns; either side can be tapped first (selected = blue). Correct pairs move to a green matched section; wrong pairs show red/green feedback.  
Audio: not supported.  
Translation: embedded in `translations` per pair (no separate `translation` field).

---

#### `ConvoTemplate-GrammarForm` — cloze sentence, pick the correct word form
**Monster-eligible:** no

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `sentence` | ✓ | English string (or locale map — `en` used) with `___` blank |
| `answer` | ✓ | Correct word/form |
| `distractors` | ✓ | Array of exactly 3 wrong forms |
| `english_to_translate` | optional | Array of English words/sentences to show in the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index with `english_to_translate` |

Answer options: 4 shuffled text buttons.

---

#### `ConvoTemplate-DialogueCompletion` — read the question, pick the correct reply
**Monster-eligible:** no

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `character1` | ✓ | Name of the asking speaker |
| `character2` | ✓ | Name of the replying speaker |
| `line1` | ✓ | English string — question line shown to player |
| `answer` | ✓ | Correct reply (English string) |
| `distractors` | ✓ | Array of exactly 3 wrong reply options |
| `image_file_name` | optional | Asset basename for a 72×72 thumbnail above the dialogue |
| `english_to_translate` | optional | Array of English words/sentences to show in the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index with `english_to_translate` |

Answer options: 4 shuffled full-sentence buttons.  
Audio: `audio_file1` (question line) and `audio_file2` (correct answer) — both top-level.

---

## Monster System

Monster attack animation applies to `imageQuizTemplate-1` and `imageQuizTemplate-2` only. The monster advances through 4 proximity steps toward game-over:
- ≤6 eligible questions in the level → advance every wrong answer (1-per-wrong)
- >6 eligible questions → 1,2,1,2 wrong-answer pattern (cumulative thresholds: 1, 3, 4, 6)

---

## Translation System

Translations are shown via a globe button (tap to reveal) for non-English users. All translatable templates use the same two optional arrays inside `questionData`:

- `"english_to_translate"`: array of English words/sentences
- `"local_translation"`: array of translated strings (same length, aligned by index)

Display: up to `min(3, min(english_to_translate.length, local_translation.length))` lines of `"english : local"`. Button is hidden when either array is absent or empty, or when the app language is `en`.

**Supported templates:** `ConvoTemplate-1`, `ConvoTemplate-ClozeSequence`, `ConvoTemplate-AppearDisappear`, `ConvoTemplate-SentenceBuilder`, `ConvoTemplate-GrammarForm`, `ConvoTemplate-DialogueCompletion`.

**No translation support:** `imageQuizTemplate-*`, `ConvoTemplate-WordPairs`.

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
