# Question generation (level `questions.json`)

Use this when authoring or extending **`app/assets/quiz-data/levels/{level-id}/questions.json`** for a specific level.

## Inputs (user or context will specify)

- **Level folder name** (`level-id`) and path to **`questions.json`**.
- **Target size** if needed (e.g. number of questions, or “fill to 15”).
- Any **theme constraints** (e.g. elementary only, no audio yet).

## Goals

1. **Template mix** — Prefer a **variety** of supported templates (image quizzes, convo templates, cloze, dialogue completion, etc.). Do **not** use only one template unless the user explicitly asks for an image-only or single-template level. Consult `CLAUDE.md` / `cursor-claude-common/context/page-designs-and-templates.md` for valid `template` strings and JSON shapes.

2. **Thematic fit** — Questions should match the **level name and setting** (e.g. a **library** level: borrowing, reading, quiet rules, book-related vocabulary; a **grocery** level: food, prices, carts). Prefer domain-relevant wording over generic fillers.

3. **Vocabulary source** — Prefer words from **`cursor-claude-common/references/final words/*.csv`**. Treat **earlier curriculum / lower-numbered or “beginner” levels** in the flow as **simpler vocabulary**; harder levels can use a wider range from the same CSVs when appropriate.

4. **Word reuse vs relevance** — Prefer **less‑repeated** words from the lists when several choices fit equally well. If a **more common** word is **clearly better** for the theme, choose it (e.g. in a library level, **read** beats **purchase**).

## Assets and wiring

- **`imageName` / images** — Only reference image basenames that **exist** under `app/assets/quiz-data/levels/{level-id}/` (or will be added there). Same for **`wrongAnswers`** / distractor image stems on image templates.
- **`audio_file` / `audio_file1` / `audio_file2`** — Only if the user wants audio; use placeholder stems consistent with existing naming, or omit per project rules.
- **`pubspec.yaml`** — If the level folder is new, ensure **`assets/quiz-data/levels/{level-id}/`** is listed so assets bundle.
- **`game-flow.json`** — Register the level if it should appear in the map (only when the user asks).

## Output

- Valid **JSON** matching **`LevelQuestion` / template** parsers in `app/lib/models/level_config.dart`.
- After edits, **validate JSON** (e.g. `python3 -m json.tool` on the file) and, when touching Dart-visible shapes, run **`dart analyze`** on touched Dart files if you changed code.

## Do not

- Invent unsupported `template` names or skip required fields (`questionData`, distractor counts, etc.).
- Bulk-edit unrelated levels unless the user requests it.
