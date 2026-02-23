# Issue-4: Image Quiz Page — Implementation Plan

This plan breaks down the active issue into ordered tasks and notes current codebase state.

---

## Current state (already in place)

- **Levels screen** opens a quiz via `_openQuiz()` → `Navigator.push(popFadeRoute(QuizPlaceholderScreen(...)))`.
- **SubLevel** has `levelNumber`, `iconImageName`, `title`, `mainLevel` — enough to identify a level and build folder name `<iconImageName>-<levelNumber>` (e.g. `plane-4`).
- **Transitions:** `popFadeRoute` and `scaleElasticRoute` exist in `custom_page_routes.dart`; spec asks for “fade and scale” → use `popFadeRoute` for Image Quiz.
- **Pubspec:** `assets/images/quiz/`, `assets/data/state/`, `assets/data/config/` are declared; no code yet that reads/writes game state or level image manifests.
- **Riverpod** is in use; no quiz-specific providers yet.

---

## Level images: runtime discovery (no JSON manifest needed)

The spec says “load all images from the assets subfolder named &lt;iconName&gt;-&lt;levelNumber&gt;”. **Flutter can do this at runtime** using the `AssetManifest` API:

1. **Load the manifest:** `AssetManifest.loadFromAssetBundle(rootBundle)` (from `package:flutter/services.dart`).
2. **List and filter:** `manifest.listAssets()` returns all asset paths; filter by prefix `assets/images/quiz/<levelKey>/` (e.g. `assets/images/quiz/plane-4/`).
3. **Derive answer words:** For each path, take the basename without extension (e.g. `pilot.png` → `pilot`). That list is your vocabulary for the level and the correct-answer labels.

**Pubspec requirement:** Flutter does **not** recursively include subdirectories. You must declare each level folder explicitly, e.g.:

```yaml
assets:
  - assets/images/quiz/plane-1/
  - assets/images/quiz/plane-4/
  # ... one entry per level folder
```

When you add a new level, add one line to `pubspec.yaml` for that folder. No separate JSON manifest is needed for image basenames.

**Guard:** If the filtered list has fewer than 4 images, do not start the level (per spec).

---

## Implementation tasks (order)

### 1. Config and asset setup

- Add **global config** (e.g. in `assets/data/config/`) for `autoAdvanceDelaySeconds` (used after correct answer before next question).
- **Level images:** No manifest JSON needed. At runtime, use `AssetManifest.loadFromAssetBundle(rootBundle)`, then `listAssets()` filtered by prefix `assets/images/quiz/<levelKey>/` to get image paths; strip to basenames without extension for the level vocabulary. Ensure each level folder has ≥4 images and is declared in `pubspec.yaml` (one entry per level folder, e.g. `assets/images/quiz/plane-4/`).

### 2. Progress / state service

- Implement **game progress persistence** (per quiz type):
  - Per level: `levelNumber`, `highestStars`, `highestDiamonds`, `completion` (or derived from stars ≥ 1).
  - Per quiz type: `totalDiamonds`, `unlockedLevelNumbers` (or equivalent).
- Use **writable storage** (e.g. `path_provider` + `File`) for a single JSON file per quiz type; do not write to `assets/data/state/` (bundle is read-only). Load on app/quiz-type entry; save only when a level is **completed** (after end-of-level screen).
- **Unlock rule:** next level unlocks only when current level is completed (≥1 star).

### 3. Image Quiz screen (UI and flow)

- Add **Image Quiz screen** (e.g. `image_quiz_screen.dart`) that:
  - Takes `SubLevel` (and quiz type slug).
  - Resolves level key = `${subLevel.iconImageName}-${subLevel.levelNumber}` and discovers image basenames at runtime via `AssetManifest` (filter assets by prefix `assets/images/quiz/<levelKey>/`).
  - **Guard:** if fewer than 4 images for that level → show a message and don’t start (or pop back); no progress change.
- **Phases:**
  - **Loading:** Show loading until level manifest and assets are ready (and optionally precache question images for the level).
  - **Play:** One question at a time: question image at top, four answer buttons below, “Next” hidden by default.
  - **End:** End-of-level panel with star rating (0–3), diamonds earned, “OK” button that pops back to Levels.

### 4. Question generation and answer logic

- **Order:** Use each image exactly once per session; randomize order of questions (shuffle the list of image basenames).
- **Per question:**
  - Correct answer = image basename (e.g. `"pilot"`).
  - Three wrong answers = three other basenames from the same level, chosen at random, no duplicates.
  - Shuffle the four options before displaying.
- **On answer tap:**
  - Immediately disable all four buttons.
  - **Correct:** Selected button green; wait `autoAdvanceDelaySeconds`; then either go to next question or, if last question, show end-of-level panel; increment correct-answer count.
  - **Wrong:** Selected button red; show correct answer in green; show “Next” (or “Finish” on last question); wait for user tap to advance.

### 5. Scoring and replay rules

- **Stars:**  
  `successRate = (correctAnswers / totalQuestions) * 100`  
  - ≥85% → 3 stars  
  - ≥70% and &lt;85% → 2 stars  
  - ≥60% and &lt;70% → 1 star  
  - &lt;60% → 0 stars  
- **Completion:** Level is completed only if successRate ≥ 60% (≥1 star). Only then unlock next level and persist.
- **Diamonds:** `diamondsEarned = correctAnswers` for this run.  
  - **totalDiamonds** (per quiz type): add diamonds from each level; on **replay**, add only the **difference** if `diamondsEarned` &gt; previous `highestDiamonds` for that level; else add 0.
- **Stars:** Store per level the **highest** star count; update only if new result is higher.

### 6. Persistence details

- Save only **after** the user has seen the end-of-level screen and data is finalized (stars, diamonds, completion, totalDiamonds, unlocked).
- **No save** if user exits mid-level; on next open, level restarts from the beginning (no partial state).

### 7. Navigation and entry point

- In **Levels screen**, when `quizType == 'image'`: push the new Image Quiz screen with `popFadeRoute(ImageQuizScreen(subLevel: sub, quizType: quizType))` instead of `QuizPlaceholderScreen`.
- For vocabulary/grammar, keep opening `QuizPlaceholderScreen` until those issues are implemented.
- Image Quiz screen “OK” on end panel → `Navigator.pop(context)` back to Levels.

### 8. UX and accessibility

- **Precache** the level’s question images (e.g. in loading phase) to avoid flicker.
- **Touch targets:** at least 48×48 for answer and Next/OK buttons.
- **SafeArea** for the Image Quiz screen.

### 9. Testing and acceptance

- Re-check all **Acceptance Criteria** from `full-project-context.md` for Issue-4 (e.g. no start with &lt;4 images, each image once per session, 4 options, correct/wrong behavior, stars/diamonds/replay rules, persistence only on completion, no save on exit mid-level).

---

## Suggested file/feature map

| Area              | Suggested location / approach |
|-------------------|-------------------------------|
| Level images      | Discover at runtime via `AssetManifest.loadFromAssetBundle(rootBundle)` + `listAssets()` filtered by `assets/images/quiz/<levelKey>/`; each level folder declared in `pubspec.yaml`. |
| Global config     | `assets/data/config/` (e.g. `game_config.json`) with `autoAdvanceDelaySeconds` |
| Progress service  | `lib/services/quiz_progress_service.dart` (read/write JSON via path_provider) |
| Image Quiz screen | `lib/screens/image_quiz_screen.dart` (or under `lib/screens/quiz/`) |
| Routing change    | `levels_screen.dart` → `_openQuiz()`: if `quizType == 'image'` push `ImageQuizScreen`, else `QuizPlaceholderScreen` |

---

## Optional later improvements

- Loading screen before first question (spec mentions “loading screen may appear”).
- Sound/haptics on correct/wrong (if desired).
- Animation on star reveal or diamond count (polish).

Once config and pubspec level folders are in place, implement in order: config → progress service → Image Quiz screen (with guard, question flow, end panel) → scoring and replay rules → wire navigation from Levels.
