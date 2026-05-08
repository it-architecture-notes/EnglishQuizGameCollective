# Page designs: screens and quiz templates

High-level reference for **what each screen is for**, **how it is laid out**, and **what the player does**. Implementation lives mainly under `app/lib/screens/`; question payloads are defined in `app/lib/models/level_config.dart` and level JSON.

**Template IDs vs runtime:** Some JSON `template` strings are **normalized** when parsed. `imageQuizTemplate-3` and `imageQuizTemplate-SentenceChoice` both normalize to `imageQuizTemplate-1` — they share the same data model (`ImageQuestionData`) and rendering path; the JSON difference is `distractors` instead of `wrongAnswers` (both accepted). Authoring can keep those legacy names; the app runs the unified branch.

---

## App shell and navigation

### Home (`home_screen.dart`)

- **Purpose:** Entry hub after launch; start the level map.
- **Design:** Light lavender background, purple primary; centered **Start Game** (phone: padded column; tablet: wider button). Bottom **navigation** strip for Me, Trophies, Friends, Settings — each opens a panel or screen with click SFX.
- **Player action:** Tap **Start Game** → navigates to the world map (`LevelsScreen`).

### Level map (`levels_screen.dart`)

- **Purpose:** Choose a sub-level (node on a path), see progress, and trigger story overlays when configured.
- **Design:** Scrollable list/world layout: **main-level banners** and **sub-level cells** (icons, lock/unlock, stars). Reminder levels may appear. Loads `QuizFlow` + progress services.
- **Player action:** Tap a playable sub-level → `QuizRunnerScreen` loads that level’s `questions.json` and opens `ImageQuizScreen`. Back returns to home/map context.

### Quiz runner (`quiz_runner_screen.dart`)

- **Purpose:** Thin loader/orchestrator — not a visible “page” by itself. Loads config, pushes the quiz, forwards `LevelCompletionResult` back to the map.
- **Design:** No custom chrome; may show an error if load fails.
- **Player action:** None directly; transition into quiz is automatic after picking a level.

### Panel overlay (`panel_overlay.dart`)

- **Purpose:** Modal **settings-style** surface over the current route (blur + dimmed backdrop).
- **Design:** Centered card with title, body widget, tap-outside or close to dismiss.
- **Player action:** Read/change content, dismiss.

---

## Quiz session: `ImageQuizScreen` (`image_quiz_screen.dart`)

Single scaffold for **image rounds**, **conversation rounds**, loading, **level complete**, and **game over**. Top **AppBar** shows the sub-level title and **close** (abandon run, no completion).

### Phases (states)

| Phase | Purpose | Design (typical) | Player action |
|--------|---------|------------------|----------------|
| **Loading** | Assets and questions resolving | Centered spinner; on error, message + **Back to Levels** | Wait, or exit on error |
| **Playing** | Active questions | Split into **image mode** vs **convo mode** (see below) | Answer per template |
| **End** | Run finished successfully | “Level complete!”, **stars**, **correct answers / total** (label from localized `correct_answers`), **diamonds**, **OK** (reminder variant: shorter copy, no score row) | Tap **OK** → progress save + pop |
| **Game over** | Failure condition (e.g. monster / timer narrative) | Illustrative layout, story copy, back without passing level | Exit per on-screen affordance |

Header shows **Question N / M · title** (localized title per template, keys in `localization.json` such as `title_image_quiz`, `click_in_order`, etc.). Optional **timer** and **monster lane** with speech bubbles appear in image-play flows where configured.

**Translations:** All translatable templates use two optional arrays inside `questionData`: `"english_to_translate"` and `"local_translation"`. On tap, up to 3 lines of `"english : local"` are revealed. Button hidden when either array is absent/empty or app language is `en`. Supported: `ConvoTemplate-1`, `ConvoTemplate-ClozeSequence`, `ConvoTemplate-AppearDisappear`, `ConvoTemplate-SentenceBuilder`, `ConvoTemplate-GrammarForm`, `ConvoTemplate-DialogueCompletion`. No translation: `imageQuizTemplate-*`, `ConvoTemplate-WordPairs`.

---

## Global config (`app/assets/data/config/game_config.json`)

| Key | Default | Description |
|-----|---------|-------------|
| `imageQuizTimerSeconds` | `5` | Monster timer duration (seconds) for image-template questions. |
| `autoAdvanceDelaySeconds` | `1.5` | Seconds to wait after a correct answer before auto-advancing. Applies to all templates. |
| `showCorrectOnWrong` | `false` | Whether to highlight the correct tile on a wrong tap (imageQuizTemplate-2). |

## Level-wide fields (`questions.json` root)

| Field | Description |
|-------|-------------|
| `timer_seconds` | Optional. Level-wide monster timer (seconds) applied to all image-template questions. Overrides `imageQuizTimerSeconds` from `game_config.json`. Omit to use the global default. |
| `levelQuestions` | Array of question objects. |

## Common top-level question fields

The `"template"` field is the only required discriminator. Image vs convo mode is inferred from the template name: any template starting with `imageQuizTemplate` is rendered in image mode; all others use the convo/interactive path. There is no `"type"` field.

Every question object (regardless of template) may carry these **top-level** audio fields:

| Field | Description |
|-------|-------------|
| `audio_file` | Basename (no extension) of the audio asset played when the question appears. Used by most templates. |
| `audio_file1` | **DialogueCompletion** — audio for the question line. **ConvoTemplate-1** — optional first clip (speaker 1 line, blanks filled in the asset); use with `audio_file2`. |
| `audio_file2` | **DialogueCompletion** — audio for the correct answer. **ConvoTemplate-1** — optional second clip (speaker 2 line, blanks filled); requires `audio_file1`. |

---

## Image-mode templates (picture-focused questions)

Rendered inside the **image playing** layout: hero or grid at top, then **four-tile MCQ row** or dedicated widget where noted.

> **Timer:** Set `”timer_seconds”: N` at the **root level** of `questions.json` (sibling to `levelQuestions`) to apply a level-wide monster timer to all image-template questions. Omitting the field falls back to `imageQuizTimerSeconds` in `game_config.json`.

### `imageQuizTemplate-1`

- **Purpose:** Vocabulary or comprehension from a **single image** — pick the correct **word, phrase, or full sentence** among four.
- **Design:** Constrained hero **image**; single column of **four answer buttons** (shuffled); after a wrong pick, UI locks with **green on correct** / **red on wrong**. Buttons support multi-line text for sentence-length answers.
- **Player action:** Tap the option that matches the image.
- **Monster-eligible:** yes
- **Audio:** `audio_file` (top-level).
- **Translation:** none.

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `imageName` | ✓ | Asset basename (no extension) for the hero image |
| `wrongAnswers` or `distractors` | ✓ | Array of exactly 3 wrong text options |
| `answer` | optional | Overrides the correct label (defaults to `imageName`) |

**Legacy aliases:** `imageQuizTemplate-3` and `imageQuizTemplate-SentenceChoice` both normalize to `imageQuizTemplate-1` at parse time. The only JSON difference is `distractors` instead of `wrongAnswers` — both are accepted.

### `imageQuizTemplate-2`

- **Purpose:** **Definition-first** — read a **noun prompt**, then pick the matching **picture** from four thumbnails.
- **Design:** Large **prompt text** on top; **2×2 grid** of images below (order shuffled).
- **Player action:** Tap the image that matches the prompt.
- **Monster-eligible:** yes
- **Audio:** `audio_file` (top-level).
- **Translation:** none.

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `imageName` | ✓ | Asset basename for the correct image tile |
| `wrongAnswers` | ✓ | Array of exactly 3 wrong image basenames |
| `answer` | optional | Overrides the text prompt (defaults to `imageName`) |

---

## Convo-mode templates (dialogue and interactive blocks)

Rendered in **convo playing** layout inside `ImageQuizScreen`: typically **dialogue area** (characters, bubbles) and/or a dedicated **quiz template** body below.

### `ConvoTemplate-1`

- **Purpose:** Classic **two-speaker dialogue** + **4 MCQ buttons** for vocab or grammar.
- **Design:** Two-column character layout with localized speech bubbles; one shuffled row of four text buttons below; locked-state coloring after answer.
- **Player action:** Read the exchange, tap the correct option.
- **Audio:** `audio_file` (top-level) — one clip for the whole exchange (legacy). **Or** `audio_file1` + `audio_file2` (both required together): clip 1 = speaker 1 line, clip 2 = speaker 2 line, each recorded with blanks **filled** using the correct `answer` (matches Gemini script). App auto-plays clip 1 on appear, plays clip 2 after a **correct** MCQ tap; replay icons when assets exist (line 2 replay only after correct).
- **Translation:** `english_to_translate` / `local_translation` arrays inside `questionData`.

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `character1` | ✓ | Name of speaker 1 |
| `character2` | ✓ | Name of speaker 2 |
| `line1` | ✓ | English string — speaker 1’s line |
| `line2` | ✓ | English string — speaker 2’s line (put the `___` blank in the line that should stay active) |
| `answer` | ✓ | Correct option (English string) |
| `distractors` | ✓ | Array of exactly 3 wrong options |
| `image_file_name` | optional | Asset basename for a 72×72 thumbnail above the dialogue |
| `english_to_translate` | optional | Array of English words/sentences for the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index |

### `ConvoTemplate-ClozeSequence`

- **Purpose:** **Cloze from context** — English sentence with `_____` blank(s); player fills them in order by tapping word tiles.
- **Design:** `ClozeSequenceQuizBody`: optional 72×72 thumbnail; full sentence in a rounded container as soon as the question loads; horizontal tile “train” with step badges on correct tiles.
- **Player action:** Tap tiles to fill blank 1, then 2, … in order.
- **Audio:** `audio_file` (top-level).
- **Translation:** `english_to_translate` / `local_translation` arrays inside `questionData`.

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `sentence` | ✓ | Plain English string with `_____` blank markers (locale maps not accepted) |
| `answer` or `answers` | ✓ | Single string or array; count must equal number of blanks |
| `distractors` | ✓ | Array of extra wrong word tiles |
| `imageName` | optional | Asset basename for a 72×72 thumbnail (omit = no image) |
| `english_to_translate` | optional | Array of English words/sentences for the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index |

### `ConvoTemplate-AppearDisappear`

- **Purpose:** **Memory + recall** — words appear all at once in boxes, audio plays, words disappear 500 ms after audio ends, then player recalls the order from a shuffled grid.
- **Design:** `AppearDisappearQuizBody`: slots above + 3×3 tile grid below (always visible layout); step badges on correct taps; failure fills remaining slots.
- **Player action:** After words disappear, tap grid tiles in the original order.
- **Audio:** `audio_file` (top-level) — played while words are visible; hide triggers 500 ms after audio finishes.
- **Translation:** `english_to_translate` / `local_translation` arrays inside `questionData`.

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `words` | ✓ | String (space-split) or array — the words to memorise |
| `distractors` | optional | Extra tiles added to fill the 3×3 grid |
| `display_duration` | optional | Legacy timing param (default 1.0) |
| `english_to_translate` | optional | Array of English words/sentences for the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index |

### `ConvoTemplate-SentenceBuilder`

- **Purpose:** **Unscramble** — only the words of the target sentence appear (no extra distractors); player taps them in the correct order.
- **Design:** `SentenceBuilderQuizBody`: target slots on top; Wrap of shuffled word tiles; duplicate words distinguished internally.
- **Player action:** Tap tiles in the order given by `correct_order`.
- **Audio:** `audio_file` (top-level).
- **Translation:** `english_to_translate` / `local_translation` arrays inside `questionData`.

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `correct_order` | ✓ | Space-split string or array — sentence tokens in correct order |
| `english_to_translate` | optional | Array of English words/sentences for the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index |

### `ConvoTemplate-WordPairs`

- **Purpose:** **Translation matching** — English words (left) vs their L2 translations (right, scrambled).
- **Design:** `WordPairsQuizBody`: two-column active area; either side can be tapped first (selected = blue). Correct match → both tiles move to green matched section. Wrong match → both tapped tiles red, correct partner green.
- **Player action:** Select a tile on either side, then tap its match; all pairs must be matched.
- **Audio:** not supported.
- **Translation:** none.

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `english_words` | ✓ | Array of 3–4 English words/phrases (left column) |
| `translations` | ✓ | Array of locale maps — same length as `english_words` |

### `ConvoTemplate-GrammarForm`

- **Purpose:** **Grammar form selection** — cloze sentence with a blank; player picks the correct word form from 4 options.
- **Design:** `GrammarFormQuizBody`: sentence with blank + 4 shuffled word buttons.
- **Player action:** Tap the grammatically correct word.
- **Audio:** `audio_file` (top-level).
- **Translation:** `english_to_translate` / `local_translation` arrays inside `questionData`.

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `sentence` | ✓ | English string (or locale map — `en` used) containing `___` blank |
| `answer` | ✓ | Correct word/form |
| `distractors` | ✓ | Array of exactly 3 wrong forms |
| `english_to_translate` | optional | Array of English words/sentences for the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index |

### `ConvoTemplate-DialogueCompletion`

- **Purpose:** **Choose the reply** — first speaker’s line is shown; player picks the correct response from 4 full-sentence options.
- **Design:** `DialogueCompletionQuizBody`: character header + optional thumbnail + question line + 4 shuffled sentence buttons; auto-plays question-line audio after 500 ms.
- **Player action:** Tap the best continuation.
- **Audio:** `audio_file1` (question line) and `audio_file2` (correct answer) — both top-level on the question object.
- **Translation:** `english_to_translate` / `local_translation` arrays inside `questionData`.

| questionData field | Required | Description |
|--------------------|----------|-------------|
| `character1` | ✓ | Name of the asking speaker |
| `character2` | ✓ | Name of the replying speaker |
| `line1` | ✓ | English string — question line shown to player |
| `answer` | ✓ | Correct reply (English string) |
| `distractors` | ✓ | Array of exactly 3 wrong reply options |
| `image_file_name` | optional | Asset basename for a 72×72 thumbnail above the dialogue |
| `english_to_translate` | optional | Array of English words/sentences for the translation panel |
| `local_translation` | optional | Array of translated strings aligned by index |

---

## Story overlays (`story_overlay_screen.dart` + `story_templates/`)

- **Purpose:** **Narrative beats** between or after levels (congratulations, instructions), driven by story config.
- **Design:** Warm paper-like background; optional **celebration** animation on final page; body from template **A or C** (placeholders + **`story_text`** + **Continue**).
- **Player action:** Read, tap **Continue** to proceed/dismiss.

For **template ids**, **`layout` strings**, JSON file paths, and per-template image/text slots, see **`story-templates-and-design.md`**.

---

## Panels and secondary screens

| Screen / content | Purpose | Design (high level) | Player action |
|------------------|---------|---------------------|---------------|
| **Profile** (`profile_panel_screen.dart`) | Avatar, stats, quiz history | Panel-friendly layout | View, navigate subviews if any |
| **Settings** (`settings_panel_content.dart`) | Language, music, SFX | Form-like controls | Toggle settings |
| **Achievements** (`achievements_panel_content.dart`) | Trophy / achievement list | List or grid of items | Browse |
| **Friends** (`friends_panel_content.dart`) | Social placeholder / list | As implemented | As implemented |
| **Placeholders** (`placeholders/*.dart`) | Stubs for unfinished areas | Simple message | Back / dismiss |

---

## How to extend this doc

When adding a **new template id**, append a subsection under the right category (image vs convo), name the **Dart widget file**, and describe **layout + user goal** in three lines (purpose / design / action). Link `level_config.dart` parsing if the JSON shape is non-obvious. If the parser **renames** the template string (normalization), document both the **JSON id** and the **runtime `LevelQuestion.template`** value so authors and implementers stay aligned.
