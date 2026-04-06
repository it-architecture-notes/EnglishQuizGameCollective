# Page designs: screens and quiz templates

High-level reference for **what each screen is for**, **how it is laid out**, and **what the player does**. Implementation lives mainly under `app/lib/screens/`; question payloads are defined in `app/lib/models/level_config.dart` and level JSON.

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
| **End** | Run finished successfully | “Level complete!”, **stars**, **correct answers / total**, **diamonds**, **OK** (reminder variant: shorter copy) | Tap **OK** → progress save + pop |
| **Game over** | Failure condition (e.g. monster / timer narrative) | Illustrative layout, story copy, back without passing level | Exit per on-screen affordance |

Header may show **Question N / M** (and reminder-specific copy). Optional **timer** and **monster lane** with speech bubbles appear in image-play flows where configured.

---

## Image-mode templates (picture-focused questions)

Rendered inside the **image playing** layout: hero or grid at top, then **four-tile MCQ row** or dedicated widget where noted.

> **Per-question timer override:** Any image template can include `"timer_seconds": N` in its `questionData` JSON to override the global monster timer for that question only. Omitting the field falls back to `imageQuizTimerSeconds` in `game_config.json`.

### `imageQuizTemplate-1`

- **Purpose:** Vocabulary from a **single image** — pick the correct **word/phrase** among four.
- **Design:** Constrained hero **image**; single row of **four answer chips** (shuffled); after a wrong pick, UI can lock with **green on correct** / **red on wrong** per project rules.
- **Player action:** Tap the option that matches the image.

### `imageQuizTemplate-2`

- **Purpose:** **Definition-first** — read a **noun prompt** (from the image stem), then pick the matching **picture** from four thumbnails.
- **Design:** Large **prompt text** on top; **2×2 grid** of images below (order shuffled).
- **Player action:** Tap the image that matches the prompt.

### `imageQuizTemplate-3` (and alias `imageQuizTemplate-SentenceChoice`)

- **Purpose:** **Comprehension** — one **hero image** plus four **full-sentence** answers (one correct, three distractors).
- **Design:** Image area + **four sentence buttons** (same lock/feedback pattern as other MCQs when wrong).
- **Player action:** Tap the sentence that best matches the image (meaning/grammar per content).

### `imageQuizTemplate-SpotDifference`

- **Purpose:** **Visual discrimination** — two nearly identical images; choose the one that matches the prompt / is “correct.”
- **Design:** Implemented by `SpotDifferenceQuizBody`: **localized sentence line** + **two large tappable images** side by side (which side is correct is randomized each time).
- **Player action:** Tap the correct image; wrong side highlights error feedback.

---

## Convo-mode templates (dialogue and interactive blocks)

Rendered in **convo playing** layout inside `ImageQuizScreen`: typically **dialogue area** (characters, bubbles) and/or a dedicated **quiz template** body below.

### `ConvoTemplate-1`

- **Purpose:** Classic **two-speaker line** + **one MCQ** (correct word/phrase among four distractors) for vocab or grammar.
- **Design:** **Two columns** (characters / bubbles) with localized lines; **one shuffled row of four text options**; locked-state coloring after answer.
- **Player action:** Read the exchange, tap the correct option.

### `ConvoTemplate-2`

- **Purpose:** **Image + cloze** — hero image with a **sentence** containing a blank; pick the **word** that fills it (four choices), with optional cloze on a **second line** tied to the image.
- **Design:** Hero asset + sentence bubble(s) + **four MCQ options** (same interaction family as template-1).
- **Player action:** Choose the word that completes the sentence (and image context).

### `ConvoTemplate-AppearDisappear`

- **Purpose:** **Memory + recall** — see the sentence built piece by piece, then reproduce order from a **3×3** grid (sentence words + distractors).
- **Design:** `AppearDisappearQuizBody`: phases — **intro → word-by-word reveal → flash →** interaction: **slots** above, **nine tiles** below, step numbers on successful taps; failure fills remaining slots as feedback.
- **Player action:** After the memorization sequence, tap grid tiles **in sentence order**.

### `ConvoTemplate-Simon`

- **Purpose:** **Simon-style** — watch tiles light in **sentence order**, then **repeat** the sequence.
- **Design:** `SimonQuizBody`: **3×3 grid**; demo highlights cells in order; player taps to replay; clear wrong/correct tile feedback on failure.
- **Player action:** Repeat the demonstrated order on the grid.

### `ConvoTemplate-ClozeSequence`

- **Purpose:** **Cloze from context** — sentence streams in with **numbered blanks**; fill blanks **in order** from a grid of answers + distractors.
- **Design:** `ClozeSequenceQuizBody`: streaming text; **grid** sized to content rules (e.g. 2×2 or 3×3); tiles consumed as blanks fill.
- **Player action:** Tap tiles to fill blank 1, then 2, … in order.

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

When adding a **new template id**, append a subsection under the right category (image vs convo), name the **Dart widget file**, and describe **layout + user goal** in three lines (purpose / design / action). Link `level_config.dart` parsing if the JSON shape is non-obvious.
