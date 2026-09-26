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
| `audio_file` | Basename (no extension) of the audio asset played when the question appears. Used by `imageQuizTemplate-1`/`imageQuizTemplate-2` and as a legacy single-clip option for `ConvoTemplate-1`. |
| `question_enter_audio` | Plays once, automatically, the first time the question is presented. Also what the audio icon plays (repeatable) before the learner answers. Absent → nothing auto-plays and the icon is disabled pre-answer. |
| `question_exit_correct_audio` | Plays automatically after a **correct** answer, before advancing. Absent or the literal string `"none"` → nothing plays, advances immediately. |
| `question_exit_wrong_audio` | Plays automatically after a **wrong** answer, before the Next button appears (Next waits for it) — and is what the audio icon replays post-wrong. **Absent** → falls back to `question_exit_correct_audio` (wrong answers hear the correct-answer line by default). Explicit `"none"` → suppresses that fallback entirely; nothing plays, icon disabled post-wrong. |

Each of the three `question_*_audio` fields accepts a **plain string** (one clip), an **array of strings** (clips played in sequence, each awaited before the next starts), or the literal string `"none"`. `_text` companions (`question_enter_audio_text`, etc., same string/array shape) exist only for the Gemini TTS generation tooling — the app never reads them.

This 3-field model is universal — every interactive template uses it (DialogueCompletion, ClozeSequence, SentenceBuilder, AppearDisappear, ConvoTemplate-1, and every `VideoConversation` `answer_type`) **except** `WordPairs`, which has no audio fields at all. See `VideoConversation` below for the one template-specific exception to the fallback rule (its AppearDisappear/recall sub-type's "Listen Again" control).

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
- **Audio:** `audio_file` (top-level) — one clip for the whole exchange (legacy). **Or** the standard `question_enter_audio` / `question_exit_correct_audio` / `question_exit_wrong_audio` fields: enter auto-plays once on appear and is icon-repeatable pre-answer; the outcome cue (correct or effective-wrong) plays after the MCQ tap and is icon-repeatable post-wrong. No more per-question "caseA" heuristics — if a question's exchange should be heard as two lines together, put both clips in one field's array (e.g. `question_exit_correct_audio: [line1Clip, line2Clip]`); the app just plays whatever's in the array, in order.
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
| `english_words` | ✓ | Array of 3–6 English words/phrases (left column) |
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
- **Audio:** standard `question_enter_audio` (question line, auto-plays on appear + icon-repeatable pre-answer) and `question_exit_correct_audio` (correct answer, plays after a correct tap). A wrong tap plays `question_exit_wrong_audio` if set, else falls back to `question_exit_correct_audio` (so by default the learner hears the correct line either way) — handled externally by `image_quiz_screen.dart`, not inside this widget.
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

### `VideoConversation`

- **Purpose:** An animated video clip pauses at a scripted beat and the learner answers one of four embedded mini-games — `DialogueCompletion` (MCQ), `ClozeSequence` (MCQ or tile-fill), `SentenceBuilder` (tile-build), or `AppearDisappear` (recall/tile-build) — then the video (muted) resumes while a separately-triggered audio clip plays the spoken line, before handing off to the next row.
- **Widget:** `VideoConversationQuizBody` (`video_conversation_quiz_body.dart`).
- **Shared controller:** one `VideoPlayerController` per `videoFile`, memoized by asset path (`_videoControllerFor` in `image_quiz_screen.dart`) — reused across every consecutive row that shares the same `videoFile`, disposed and recreated only when the asset path changes (e.g. moving from one video segment to the next within a level).

**Row fields** (in addition to the standard `question_enter_audio`/`question_exit_correct_audio`/`question_exit_wrong_audio` — see above):

| Field | Description |
|-------|-------------|
| `videoFile` | Asset basename (no extension) of the shared video, resolved per-level. |
| `start_at` / `pause_at` / `answer_until` | `MM:SS.ss` timestamps. Video plays `start_at → pause_at`, pauses, reveals the answer UI. After answering, video resumes and plays `pause_at → answer_until` (recall/`AppearDisappear` excepted — see below). |
| `questionData.answer_type` | One of `DialogueCompletion` / `ClozeSequence` / `SentenceBuilder` / `AppearDisappear` — selects which mini-game renders and which shape `questionData` needs (see that template's own section above for the field list; `AppearDisappear` sets `sequenceData.isRecall = true`, the others don't). |

**Sync rule — what plays together, and when it's actually guaranteed:**
- The **first** row of a level (or the first row after the shared video's `videoFile` changes) gets a **true synced start**: `startQuestionAudio()` resolves the instant the platform reports playback has begun (not when it ends — that's the whole reason a separate `startQuestionAudio` exists next to `playQuestionAudio`), and `controller.play()` fires immediately after. Video and `question_enter_audio` start within the same frame.
- Every **subsequent** row's entry sync depends entirely on what the **immediately preceding row** left the shared controller doing, not on template type:
  - If the preceding row was **not** `AppearDisappear`/recall: its correct-answer path (`_resumeVideo()`) calls `controller.play()` and never explicitly re-pauses — video keeps rolling continuously into the next row's mount. That next row then finds `controller.value.isPlaying == true`, skips the synced-start path, and instead fires its own `question_enter_audio` via the **unsynced**, fire-and-forget `_playSetupAudio()` — approximately timed (after a fixed 50ms delay plus mount overhead), not hard-synced to the video's position. In practice this stays imperceptibly close **only if** every prior row's real audio duration matches its declared `pause_at`→`answer_until` window; a mismatch (rare, but see `q4`/`greetings1` for a 90ms real-world example) compounds forward.
  - If the preceding row **was** `AppearDisappear`/recall: `_resumeVideo()` skips `controller.play()` entirely (see below), so the video is genuinely paused when the next row mounts → that row gets the **true synced start** again, same guarantee as the level's first row.
  - A wrong answer on a non-recall row explicitly re-pauses the video after its (fallback) exit-wrong audio finishes (`_waitForWrongAnswerAudio` in `image_quiz_screen.dart`), so the row *after* a wrong answer also gets a true synced start — unlike the row after a *correct* answer on the same template.
- **`AppearDisappear`/recall rows never resume the video at all**, regardless of answer outcome — there's nothing new to show past the pause point (the muted track has no fresh content), and letting it free-run would race unsupervised into the next row's territory before that row's own pause-position listener attaches. Content for these rows should set `pause_at == answer_until` (zero forward-play window) — `greetings1`/`greetings2`'s `q3`/`q6`/`q7`/`v2-q4` all do this. The video only starts moving again once the *following* row explicitly starts it.
- **Tutorial guide**: shows once per `"VideoConversation:<answer_type>"` step key per level entry (shared with the level's `"tutorial"` config — same step key format as the standalone templates use their own template name), triggered the moment the answer controls (buttons/tiles) actually render — i.e. after the video pauses, not before it starts. See "Tutorial guide overlay" below.
- **`AppearDisappear`'s "Listen Again" button** (shown once, pre-answer, while paused) is the one template-specific exception to the standard field semantics: it **only ever plays `question_exit_correct_audio`** — never `question_enter_audio`, no fallback, nothing if that field is unset. If a question has only one recorded line, point both `question_enter_audio` and `question_exit_correct_audio` at the same clip.

**Cross-file transitions:** when a level chains two video files back to back (e.g. `greetings1` → `greetings2`), the shared controller is disposed and a fresh one created for the new asset — the new file's first row always gets the true synced start, exactly like the level's very first row, regardless of what the previous file's last row did.

### `VideoConversation` — paused answer_types (`pausedDialogueCompletion` / `pausedSentenceBuilder` / `pausedClozeSequence`)

- **Purpose:** ask an extra question at a video pause point **without** any video motion for that question — `start_at == pause_at == answer_until` always (zero-length window; never played, never resumed by this row). The frozen video frame is used as the media in place of a static image, and the question otherwise looks and behaves exactly like its standalone counterpart (layout, audio autoplay/replay rules), not like the synced video answer_types above.
- **Widgets:** `PausedDialogueCompletionQuizBody` / `PausedSentenceBuilderQuizBody` / `PausedClozeSequenceQuizBody` (`paused_dialogue_completion_quiz_body.dart` / `paused_sentence_builder_quiz_body.dart` / `paused_cloze_sequence_quiz_body.dart`) — each a deliberately separate, self-contained file (not a shared variant of `VideoConversationQuizBody` or of the standalone widget), reusing the same shared `VideoPlayerController` as the level's other `VideoConversation` rows (seeked to `start_at` and left paused, never played).
- **Data shapes** (all fields live directly in `questionData`, alongside `answer_type`): deliberately isolated from both the standalone `*QuestionData` classes and the non-paused video answer_type classes — no `character1`/`character2`/`image_file_name`/`imageName` (the frozen frame is the only media), and `line1` (the on-screen prompt, since there's no video motion to carry it) is always **optional**, matching every standalone template's own `line1`.

| `answer_type` | Fields | Notes |
|---|---|---|
| `pausedDialogueCompletion` | `line1` (optional), `answer`, `distractors` | Mirrors standalone `DialogueCompletion` minus character/image fields. |
| `pausedSentenceBuilder` | `line1` (optional), `correct_order` | Mirrors standalone `SentenceBuilder` — unscramble only, no `distractors` field (matches standalone semantics; unlike the non-paused video `SentenceBuilder`, which does support optional decoy `distractors`). |
| `pausedClozeSequence` | `line1` (optional), `sentence`, `answer`/`answers`, `distractors` | Mirrors standalone `ClozeSequence`. |

- **Audio:** standard `question_enter_audio`/`question_exit_correct_audio`/`question_exit_wrong_audio` at the row's top level, same as every other row — but timed like a **standalone** question (simple ~500ms-delay autoplay + replayable icon), not synced to video playback (there's nothing to sync to).
- **No tutorial guide steps** for these three — the guide already shown for the non-paused `VideoConversation:<answer_type>` steps earlier in the level covers them.

---

## Tutorial guide overlay (`widgets/tutorial/`)

- **Purpose:** A one-time, blocking "here's how this works" character + speech-bubble overlay, shown the first time the player reaches each configured template/answer-type, driven by the level JSON's root `"tutorial"` block (`steps` keyed by template name or `"VideoConversation:<answer_type>"`).
- **Controller:** `TutorialController` (`tutorial_controller.dart`) — in-memory only (`_shownStepKeys`), rebuilt fresh every level entry (not persisted across playthroughs).
- **Trigger:** `maybeShowFor(stepKey)`, called from every template's "answer controls rendered" callback (`onChoiceButtonsRendered` / `onNextTileRendered` / `onNextChoiceRendered` / `onGuideTargetRendered` / `onOptionButtonsRendered` — wired in `image_quiz_screen.dart`'s `_buildConvoQuestionBody`). Shows once per step key per level entry; every later question of the same step key is a no-op. There is **no** "show before playback" path any more — a prior design that blocked video/audio before the question even started was removed; the guide always waits for the answer UI to actually be on screen, for every template including `VideoConversation`.
- **Blocking:** the overlay is a full-screen opaque `Material` painted above the whole Scaffold — swallows every tap except its own OK button.
- **Dismiss:** OK button (`TutorialController.confirmActive`) or `_goNext()` (`dismissActive`, when moving to the next question).
- **Footer guide hint:** a lighter, non-blocking companion — the same step's `messageKey` text also renders in the footer (`_buildQuestionActionRegion` in `image_quiz_screen.dart`, the same slot the Next button occupies) on **every** question of an applicable template, every time — not gated by "once per level" the way the overlay is. Applies to every template except `WordPairs`. Timing/lifecycle:
  - Appears only once `_answerControlsRendered` is true (same "controls rendered" signal as the overlay) — never before the question's own entry audio/video has actually presented its answer UI.
  - Disappears on the learner's **first interaction of any kind** — tile tap, MCQ button, translation reveal, audio icon, "Listen Again" — wired via an `onUserInteracted` callback added to every interactive template widget.
  - Suppressed entirely (not just "while overlay visible") on the **one specific question** where the blocking overlay actually fired for that step key — tracked via `_overlayShownForQuestionKey`, compared by `'${questionId}#${index}'` — so it doesn't reappear on that same question the instant OK is tapped. Later questions of the same step key (where the overlay won't show again) get the footer hint normally.

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
