# Page designs: screens and quiz templates

High-level reference for **what each screen is for**, **how it is laid out**, and **what the player does**. Implementation lives mainly under `app/lib/screens/`; question payloads are defined in `app/lib/models/level_config.dart` and level JSON.

**Template IDs vs runtime:** Some JSON `template` strings are **normalized** when parsed. For example, `ConvoTemplate-2` is converted into `ConvoTemplate-ClozeSequence` data and the stored `LevelQuestion.template` becomes `ConvoTemplate-ClozeSequence` (see `LevelConfig._parseQuestion` and `normalizedTemplate` in `level_config.dart`). `imageQuizTemplate-SentenceChoice` normalizes to `imageQuizTemplate-3`. Authoring can keep the legacy names; the app runs the unified branch.

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

**Translations:** The global Translate toggle is removed. Optional per-question `translation` / `line1_translation` / `line2_translation` maps in JSON show auxiliary text below the English prompt when the app language is not `en`. **ConvoTemplate-AppearDisappear** may use a top-level `translation` on the question object (sibling to `questionData`). **ClozeSequence**, **WordPairs**, **Simon**, and **SpotDifference** do not use this optional translation layer.

---

## Image-mode templates (picture-focused questions)

Rendered inside the **image playing** layout: hero or grid at top, then **four-tile MCQ row** or dedicated widget where noted.

> **Per-question timer override:** Any image template can include `"timer_seconds": N` in its `questionData` JSON to override the global monster timer for that question only. Omitting the field falls back to `imageQuizTimerSeconds` in `game_config.json`.

### `imageQuizTemplate-1`

- **Purpose:** Vocabulary from a **single image** — pick the correct **word/phrase** among four.
- **Design:** Constrained hero **image**; single row of **four answer chips** (shuffled); after a wrong pick, UI can lock with **green on correct** / **red on wrong** per project rules.
- **Player action:** Tap the option that matches the image.

### `imageQuizTemplate-2`

- **Purpose:** **Definition-first** — read a **noun prompt** (from the correct stem), then pick the matching **picture** from four thumbnails.
- **Design:** Large **prompt text** on top; **2×2 grid** of images below (order shuffled).
- **Player action:** Tap the image that matches the prompt.
- **JSON:** `imageName` is always the asset stem for the **correct** image file; `wrongAnswers` are three other stems. Optional `answer` (same idea as `imageQuizTemplate-1`) overrides the **correct option key** and prompt formatting when non-empty — the correct tile still loads `imageName`’s file; taps match on `answer` when set, otherwise `imageName`.

### `imageQuizTemplate-3` (and alias `imageQuizTemplate-SentenceChoice`)

- **Purpose:** **Comprehension** — one **hero image** plus four **full-sentence** answers (one correct, three distractors).
- **Design:** Image area + **four sentence buttons** (same lock/feedback pattern as other MCQs when wrong).
- **Player action:** Tap the sentence that best matches the image (meaning/grammar per content).

### `imageQuizTemplate-SpotDifference`

- **Purpose:** **Visual discrimination** — two nearly identical images; choose the one that matches the prompt / is “correct.”
- **Design:** Implemented by `SpotDifferenceQuizBody`: **instruction line** from global `localization.json` key `spot_difference_prompt` (same for every question of this template) + **two square (1:1) image tiles** side by side, centered with `BoxFit.contain` (which side is correct is randomized each time).
- **Player action:** Tap the correct image; wrong side highlights error feedback.
- **JSON:** `questionData` has `correctImage`, `wrongImage`, optional `auto_next_delay`, optional `timer_seconds` — no per-question `sentence` map.

---

## Convo-mode templates (dialogue and interactive blocks)

Rendered in **convo playing** layout inside `ImageQuizScreen`: typically **dialogue area** (characters, bubbles) and/or a dedicated **quiz template** body below.

### `ConvoTemplate-1`

- **Purpose:** Classic **two-speaker line** + **one MCQ** (correct word/phrase among four distractors) for vocab or grammar.
- **Design:** **Two columns** (characters / bubbles) with localized lines; **one shuffled row of four text options**; locked-state coloring after answer.
- **Player action:** Read the exchange, tap the correct option.

### `ConvoTemplate-ClozeSequence`

- **Purpose:** **Cloze from context** — localized sentence with **numbered blanks** (`_____` markers in `sentence` maps, especially `en`); player fills blanks **in order** by tapping word tiles (answers + distractors).
- **Design:** `ClozeSequenceQuizBody`: optional **72×72 thumbnail** when `imageName` is set in JSON (resolved per level folder); **sentence** in a rounded container with streaming or full text; answer tiles in a **horizontal “train”** (`Wrap`) with step badges on correct tiles; wrong tap highlights expected/correct tiles per rules.
- **JSON:** `answers` (array) or single `answer`; `distractors`; optional `imageName` (omit = no image); `words_all_together` (default false) — when **true**, the full sentence shows immediately instead of streaming word-by-word.
- **Player action:** After blanks are visible, tap tiles to fill blank 1, then 2, … in order.

### `ConvoTemplate-2` (authoring alias only)

- **Purpose:** Backward-compatible **JSON label** for the old “image + single-blank sentence + four word options” question.
- **Runtime:** **Not** a separate widget. Parsed via adapter into **`ClozeSequenceQuestionData`**: one answer, three distractors, `wordsAllTogether: true`, optional `imageName`. `LevelQuestion.template` after parse is **`ConvoTemplate-ClozeSequence`**; UI is **`ClozeSequenceQuizBody`** like any other cloze row.
- **Player action:** Same as `ConvoTemplate-ClozeSequence` for that shape (pick the word for the blank from the tile row).
- **Note:** Prefer new content to use `ConvoTemplate-ClozeSequence` explicitly with `words_all_together: true` when you want the non-streaming cloze; the adapter exists so existing `questions.json` files keep working.

### `ConvoTemplate-AppearDisappear`

- **Purpose:** **Memory + recall** — see the sentence built piece by piece, then reproduce order from a **3×3** grid (sentence words + distractors).
- **Design:** `AppearDisappearQuizBody`: phases — **intro → word-by-word reveal → flash →** interaction: **slots** above, **nine tiles** below, step numbers on successful taps; failure fills remaining slots as feedback.
- **Player action:** After the memorization sequence, tap grid tiles **in sentence order**.

### `ConvoTemplate-Simon`

- **Purpose:** **Simon-style** — watch tiles light in **sentence order**, then **repeat** the sequence.
- **Design:** `SimonQuizBody`: **3×3 grid**; demo highlights cells in order; player taps to replay; clear wrong/correct tile feedback on failure.
- **Player action:** Repeat the demonstrated order on the grid.

### `ConvoTemplate-SentenceBuilder`

- **Purpose:** **Unscramble** — only the **words of the target sentence** appear, shuffled; **no extra distractor words**.
- **Design:** `SentenceBuilderQuizBody`: **target slots** on top; **Wrap** of word tiles; duplicate words distinguished by position via internal permutation.
- **Player action:** Tap tiles **in the order given by `correct_order`** in data.

### `ConvoTemplate-WordPairs`

- **Purpose:** **Translation matching** — left column (e.g. English) vs **scrambled** right column (e.g. L2).
- **Design:** `WordPairsQuizBody`: **active area** (top) shows only unmatched pairs as two columns. **Right** = reference: tap to select (**blue**). **Left** = answer: tap to pair. On **correct match** both tiles move to a **matched section** at the bottom (green, separated by a divider). On **wrong match**: selected right → red, tapped left → red, **correct left for that right selection → green** (nothing moves to matched section). Remaining active pairs stay at top.
- **Player action:** Select a word on the right (blue), then tap its match on the left; matched pairs accumulate at the bottom until all are paired.

### `ConvoTemplate-GrammarForm`

- **Purpose:** **Grammar form** — sentence with a blank, **lemma hint**, four **word** options.
- **Design:** `GrammarFormQuizBody`: cloze line + hint + **four shuffled buttons**.
- **Player action:** Tap the grammatically correct word.

### `ConvoTemplate-DialogueCompletion`

- **Purpose:** **Choose the reply** — first speaker’s line + four **full-sentence** responses.
- **Design:** `DialogueCompletionQuizBody`: dialogue header + **four options** (shuffled).
- **Player action:** Tap the best continuation.

---

## Story overlays (`story_overlay_screen.dart` + `story_templates/`)

- **Purpose:** **Narrative beats** between or after levels (congratulations, instructions), driven by story config.
- **Design:** Warm paper-like background; optional **celebration** animation on final page; body from template **A / B / C** (illustration + text blocks + **Continue**).
- **Player action:** Read, tap **Continue** to proceed/dismiss.

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
