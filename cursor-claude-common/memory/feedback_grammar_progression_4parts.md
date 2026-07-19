---
name: feedback-grammar-progression-4parts
description: Grammar progression rule in audit-quiz-level was restructured from 12 per-ML rows into 4 aggregated macro-bands (Parts)
metadata:
  type: feedback
---

The `audit-quiz-level` skill's grammar-progression table (`cursor-claude-common/skills/audit-quiz-level/SKILL.md`) no longer gates grammar level-by-level across all 12 mainLevels. It's now 4 macro-bands ("Parts"), and everything aggregated into a Part is usable at **any** ML within that Part's range, not just from the ML that originally "introduced" it.

- **Part 1 (ML1–3):** to-be, 3rd person/negatives/do-support questions, possessives, prepositions, imperative, `can`, infinitives, `Could you…?`, **plus** Present Continuous, `there is/are`, infinitive of purpose, `some/any` (all moved down from the old ML4).
- **Part 2 (ML4–5):** future (`will`/`be going to`), `must`, comparatives/superlatives, **plus first conditional** (`if` + present, `will` — moved down from the old ML11, since it only needs present+future which are both available by Part 2).
- **Part 3 (ML6–8):** all past simple (regular + irregular), past questions/negatives, `should`/`have to`/`could`/`might`/`may`.
- **Part 4 (ML9–12, end):** present perfect, past continuous, `used to`, passive voice, second conditional, present perfect continuous, reported speech, third conditional.

**Why:** The user found the old strict level-by-level gating "too restrictive" — e.g. wanted Present Continuous and `there is/are` usable as early as ML1, and first conditional usable starting ML4-5 since it only needs grammar already unlocked by then. This was an explicit, deliberate loosening, not a one-off exception.

**How to apply:** When running `audit-quiz-level` (or any grammar-progression check), look up which Part a `mainLevel` falls into and check allowed/forbidden by Part, not by individual ML. Use the enforcement labels **OK — review** / **OK — in band** / **Forbidden — not yet** (not the old "OK — new intro"). This also **retroactively resolves** several earlier findings that were treated as exceptions under the old rule (e.g. "there is/are" and Present Continuous in ML1 levels like `verb-to-be`/`basic-sentences` are now fully compliant, not exceptions) — see [[feedback_grammar_progression_idioms]] for the separate idiom-exception precedent, which still applies independently for things like imperative farewells at Part 1.
