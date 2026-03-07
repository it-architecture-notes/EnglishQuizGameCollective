# Issue-11 Grammar Quiz: Gap Analysis (Cursor implementation vs Claude plan)

Comparison of the current Cursor implementation against the Claude implementation described in `issue-11-implementations-claude.md` (diff format).

---

## 1. Gaps to fix (recommended) — all implemented

### 1.1 Yes/No: optional `correction` field — DONE

**Claude:** For yes_no questions when the sentence is wrong (`answer: "no"`), the JSON can include an optional `correction` field with the corrected sentence (e.g. `"correction": "She doesn't have a passport."`). The UI shows this in a dedicated green “correction” field when the user answers wrong, instead of only “Correct answer: No”.

**Current:** We only show “Correct answer: No” (or “Yes”) in the correct-answer box. We do not have a `correction` field in the model or JSON, and we do not show the actual corrected sentence.

**Implemented:** Optional `correction` on model and JSON; yes/no wrong-answer box shows correction or “Correct answer: No/Yes”.

---

### 1.2 Localization for grammar UI strings — DONE

**Claude:** Uses localized strings for:
- Bubble prompts: `grammar_find_correct_order`, `grammar_is_correct`, `grammar_which_correct`, `grammar_fill_blanks`
- Yes/No buttons: `grammar_yes`, `grammar_no`

Added in `localization.json` for en, es, fr, tr.

**Current:** All these strings are hardcoded in English in `grammar_quiz_screen.dart` (“Which sentence is correct?”, “Fill in the blanks:”, “Is this sentence correct?”, “Which is correct?”, “Yes”, “No”). We use `currentLocalizedStringsProvider` for other screens but not for these grammar strings.

**Implemented:** Grammar keys added to localization.json (en, fr, es, tr); grammar screen uses `strings['grammar_*']` with fallbacks.

---

### 1.3 Grammar character images: discovery vs hardcoded list — DONE

**Claude:** Loader has `loadGrammarCharacterImages()` which uses `AssetManifest` to discover all assets under `assets/images/grammar-characters/` (e.g. coach.png, professor.png, teacher.png, tutor.png). Character for non-conversation questions is chosen from this list; no hardcoded names.

**Current:** We use a hardcoded list `['host', 'guide', 'narrator']` and only have `.gitkeep` in `grammar-characters/`. No discovery; if you add new PNGs they are not used unless we change the code.

**Implemented:** `loadGrammarCharacterImages()` in grammar_quiz_loader discovers assets; fallback list when empty; one character per non-conversation question.

---

## 2. Intentional / acceptable differences

### 2.1 JSON schema and type names

**Claude:** Uses `"type"` with values `conversation_blank`, `sentence_ordering`, `banked_cloze`, `yes_no`, `which_is_correct`; banked_cloze uses `sentence` for the sentence with blanks; which_is_correct uses `prompt`, `answer`, `distractors`.

**Current:** We use `"questionType"` with `conversation`, `word_order`, `banked_cloze`, `yes_no`, `which_correct`; banked_cloze uses `sentenceWithBlanks`; which_correct uses `context`, `options`, `correctIndex`.

**Verdict:** Functionally equivalent. Our JSON and model are already used; no change required unless you want to align names with Claude’s for consistency.

---

### 2.2 Level number for progress

**Claude (diff):** Calls `recordLevelCompletion(..., levelNumber: widget.subLevel.levelNumber, ...)` and passes extra params such as `questionsAnswered`, `elapsedMs`, `iconImageName`.

**Current:** We call `recordLevelCompletion(..., levelNumber: widget.ordinalLevelIndex, ...)` and only pass `quizType`, `levelNumber`, `stars`, `diamondsEarned` — matching the existing `QuizProgressService` API and how vocabulary/image quizzes and the levels screen use `ordinalLevelIndex` for unlocking.

**Verdict:** Our usage is correct for this codebase. Extra params in Claude’s diff are from a different API shape; no change unless we extend the service.

---

### 2.3 ProfileService / AchievementService vs GlobalStatsService

**Claude (diff):** Uses `GlobalStatsService.instance.incrementCorrectStreak()` / `resetCorrectStreak()`.

**Current:** We use `AchievementService.instance.recordAnswer(isCorrect)` and `ProfileService.instance.registerQuizCompletion(...)` and do not use GlobalStatsService.

**Verdict:** This repo uses AchievementService and ProfileService; GlobalStatsService may not exist here. No change unless we introduce a streak service and wire it.

---

## 3. Summary table

| Item | Claude spec | Current Cursor | Action |
|------|-------------|----------------|--------|
| Yes/No `correction` field | Optional corrected sentence in JSON; show in UI when wrong | Not present; only “Correct answer: No” | Add `correction` to model + JSON; show in green box when wrong |
| Grammar bubble / Yes-No labels | Localized (grammar_* keys, 4 languages) | Hardcoded English | Add keys to localization.json; use in grammar screen |
| Grammar character images | Discover from bundle; real PNGs (coach, professor, etc.) | Hardcoded names; only .gitkeep | Add discovery and/or real assets |
| JSON type names / structure | `type`, sentence_ordering, etc. | `questionType`, word_order, etc. | Optional alignment only |
| recordLevelCompletion params | levelNumber + extra | ordinalLevelIndex, existing API | Keep current |
| GlobalStatsService streak | Used | Not used | Optional if we add streak |

---

## 4. Recommended next steps

1. **Implement 1.1** – Add `correction` for yes_no and show it when the user is wrong.
2. **Implement 1.2** – Add grammar localization keys and use them in the grammar screen.
3. **Implement 1.3** – Either add asset discovery for grammar-characters or add a few real PNGs and document the convention.

After that, the Cursor implementation will match the Claude plan for behavior and localization; schema and service differences can stay as intentional.
