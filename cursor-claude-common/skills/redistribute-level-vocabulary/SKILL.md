---
name: redistribute-level-vocabulary
description: >-
  Produce a report that recursively improves vocabulary distribution across mixed
  quiz levels by finding words that fit earlier themed levels better, then
  finding replacement words for displaced later levels. Use when the user asks to
  redistribute words, maximize level relevancy, move words between levels, or run
  a recursive vocabulary replacement chain starting from waking-up or another
  mixed level.
disable-model-invocation: true
---

# Redistribute Level Vocabulary

Report-only workflow for improving word-to-level relevance across standard mixed
levels. Do not edit JSON unless the user separately approves a concrete swap.

## Scope

Default start: `waking-up`.

Included levels:
- Standard mixed levels at or after the start level in `app/assets/data/flow/game-flow.json`
- Levels with text vocabulary in `translations.json` and/or `WordPairs`

Excluded levels:
- Levels before the start level
- Medley levels (`medley-*`) as recursion endpoints only
- Image-only levels
- Reminder/story/non-quiz flow entries

Reference inputs:
- `app/assets/data/flow/game-flow.json` — ordered flat list of all flow entries with `mainLevel`, `iconImageName`, and `title`
- `app/assets/quiz-data/levels/{level-id}/questions.json` — question templates and taught words per level
- `app/assets/quiz-data/levels/{level-id}/translations.json` — tracked vocabulary per level
- `cursor-claude-common/references/final words/` — CSV files with columns: word, POS, CEFR level, frequency count; use for A1/A2 classification and unused-word pool
- `cursor-claude-common/references/remove-word-list-references/3000 words oxford.txt` — Oxford 3000 flat word list; use as secondary CEFR source when final-word CSVs don't cover a word
- `cursor-claude-common/references/remove-word-list-references/langeek-500-most-common-nouns.txt` — secondary source for common noun candidates; use carefully for standard levels because concrete nouns usually belong in image questions
- `cursor-claude-common/output/prior-words-by-type.md` — pre-generated consumed word list grouped by POS with source level; use to bootstrap the ownership map (see Step 2)
- `tools/gather_prior_level_words.py` — regenerate `prior-words-by-type.md` only when the cached file predates the start level
- `cursor-claude-common/skills/audit-quiz-level/SKILL.md` — consult to validate that a proposed replacement word is grammar-compatible with the target level's `mainLevel` band
- `cursor-claude-common/skills/improve-level-vocabulary/SKILL.md` — consult when a level needs a new question designed around a replacement word (question structure and template rules)

Read project rules in `cursor-claude-common/rules/rules.md` before starting.

## Core Goal

Maximize vocabulary relevance by moving better-fit words to the levels where
they most naturally belong, while preserving coverage by replacing displaced
words elsewhere.

Example chain:

```text
A wants word x from B.
B needs a replacement for x, so inspect B.
B can use word y from C.
C needs a replacement for y, so inspect C.
If C can use an unused word or a medley word, the chain resolves.
If the next displaced owner would be a fourth non-medley level, stop the chain.
```

## Definitions

- **Target level A:** the level currently being improved.
- **Owner level B/C:** the level that currently teaches a candidate word.
- **Consumed word:** an `english_word` in `translations.json` or an item in
  `WordPairs.questionData.english_words`.
- **Unused word:** a word in reference files not consumed by any in-scope level.
- **Medley word:** a word currently consumed in a `medley-*` level. Treat as an
  endpoint: report it as available to move; do not recursively replace it.
- **Image-only level:** a level whose taught vocabulary is only image templates
  and has no text vocabulary tracking. Skip as a target and avoid using it as a
  displacement owner unless the user explicitly asks.
- **Shared A1 word:** an A1 word that can be taught in two levels when it is
  genuinely useful and context-fit in both. It should appear in `translations.json`
  or WordPairs for only one of the two levels; the second level may teach/review it
  in question text or as an answer without adding another translation row.
- **WordPairs group:** four words taught together as a matched set in a single
  WordPairs question. When a candidate word is part of a WordPairs group, all four
  words move or stay together — do not propose moving one word out of a group
  without also proposing what replaces the full group or restructuring it. A chain
  that requires splitting a WordPairs group counts as a question redesign and must
  be flagged as a candidate-only chain, not a recommended chain.

## Chain Limits

Limit recursion to **three non-medley owner levels after A**:

```text
A -> B -> C -> D is allowed
A -> B -> C -> D -> E is not allowed; stop and report unresolved at E
```

Stop immediately when the replacement candidate is unused or belongs to a medley
level. Track visited levels and words to prevent loops.

## A1 Shared-Word Exception

Do not force every word to be used in only one level. **Only A1 words** may be
repeated as taught words in two levels when both uses are strong and useful.

Rules:
- The word must be A1 in the final-word CSVs or Oxford 3000 reference.
- The word may be a taught word in at most two levels.
- Only one of those levels should track it in `translations.json` or WordPairs.
- The second level may use it as an answer, AppearDisappear key word,
  SentenceBuilder key word, or prominent taught phrase, but should not add a
  duplicate translation row.
- If a word is already taught in two levels, do not recommend a third taught use.
- Do not use this exception for A2+ words unless the user explicitly approves it.

When a later/other level owns an A1 word that is also very suitable for target
level A, consider reporting it as **shared A1** instead of starting a displacement
chain. Example: `to take` can remain tracked in one level and also be taught or
reviewed in another highly relevant level without requiring a replacement chain.

## Relevance Scoring

Score candidates qualitatively; do not pretend precision.

| Factor | Weight |
|--------|--------|
| Thematic fit to the target level | Highest |
| Everyday usefulness and CEFR simplicity (A1/A2 first) | High |
| Grammar compatibility with the target level's `mainLevel` | High |
| Currently unused or parked in medley | High |
| A1 word suitable as a two-level shared word | High |
| Current owner has weaker thematic claim | Medium |
| Replacement can be introduced with a small question edit | Medium |
| Avoids object nouns in standard text translation slots | Medium |

Use labels such as `strong`, `medium`, `weak`, or a 1–5 score. Always explain the
reason in plain language.

## Workflow

### 1. Build the ordered worklist

1. Read `game-flow.json`.
2. Find the start level, default `waking-up`. The start level itself is the first
   target — include it, do not skip it.
3. List every flow entry at or after the start level that is a standard mixed level.
4. Skip `medley-*`, image-only, story/reminder, and levels before the start.
5. Process levels one by one from start to last mixed level.

### 2. Build the global word ownership map

**Efficiency shortcut:** if `cursor-claude-common/output/prior-words-by-type.md`
exists and its header names a level at or before the start level, read it first.
It already lists every consumed word with source level and POS — use it to
bootstrap the ownership map for all levels before the start without reading
individual files. Then read only the levels at or after the start level directly.
If the file is absent or predates an earlier level than needed, run
`tools/gather_prior_level_words.py` to regenerate it.

For all quiz levels, record each consumed word:

| Field | Source |
|-------|--------|
| word | `translations.json` `english_word` or WordPairs `english_words` |
| owner level | level folder / flow id |
| owner kind | standard / medley / before-scope / later-scope |
| source | translations / WordPairs |
| flow index and mainLevel | `game-flow.json` |

Also build an unused reference pool from final-word CSVs and Oxford 3000 entries
minus all consumed words across all levels. Keep POS, CEFR level, and frequency
count metadata from the CSV when available; frequency count is the corpus
occurrence count and indicates how common the word is in everyday use.

### 3. Analyze one target level

For target level A:

1. Read `questions.json` and `translations.json`.
2. Gather taught words in A:
   - `translations.json` entries
   - WordPairs entries
   - answer words in Convo, Cloze, Dialogue, GrammarForm
   - key words from AppearDisappear and SentenceBuilder
   - image `imageName` nouns for context only
3. Summarize A's theme and likely vocabulary needs.
4. Identify weak or less relevant current slots in A.
5. Search for better-fit candidates from:
   - unused reference words
   - medley words
   - later standard levels
   - earlier in-scope levels only when the fit improvement is strong
6. For A1 candidates already used in exactly one other level, decide whether the
   better recommendation is a shared two-level use instead of a displacement
   chain. If yes, report it in the **Shared A1 word recommendations** section.
7. Do not suggest concrete object nouns as standard `translations.json` swaps
   unless the level has no image questions or the user explicitly allows it.

### 4. Resolve a recursive chain

When a candidate word is owned by a standard non-medley level B:

1. If `word x` is A1, currently taught in only B, and has a strong claim in both
   A and B, consider the A1 shared-word exception first. Report it as shared
   instead of displacing it when both levels benefit.
2. Otherwise record proposed move: `word x` from B to A.
3. Treat B as the new target and find a replacement for `x`.
4. Prefer unused or medley candidates to terminate the chain.
5. If the best replacement is owned by standard level C, recurse.
6. Stop at the chain limit, repeated level, repeated word, or weak relevance.
7. Report unresolved chains instead of forcing a poor replacement.

At each step, compare:
- Does the candidate fit the new target better than its current owner?
- Can the owner still work well after replacement?
- Is the replacement compatible with grammar at the owner level?
- Does the swap require a feasible question edit and audio stem update?

**Feasibility of a question edit:** an edit is feasible when the change is
self-contained — a single sentence swap, a new answer word in an existing
template, or an audio stem rename. An edit is not feasible (mark as
candidate-only) when it requires rebuilding a multi-word dialogue, rewriting a
sentence that introduces unrelated grammar, splitting a WordPairs group without
a coherent replacement set, or when the audio stem change would cascade into
unrelated recordings.

### 5. Keep the report conservative

Only recommend swaps that improve the overall distribution, not just one level.
If moving a word creates a worse downstream level, mark it as rejected.

Classify outcomes:
- **Recommended chain:** improves every affected standard level and terminates.
- **Shared A1 recommendation:** A1 word should appear in two levels, with only one
  translation/WordPairs tracking row.
- **Candidate only:** promising but needs user judgment or question redesign.
- **Rejected:** better for A, but hurts B/C too much or cannot resolve.
- **Unresolved:** chain hit max depth or loop risk before reaching unused/medley.

## Output

Write the report to:

```text
cursor-claude-common/output/vocabulary-redistribution-{start-level}.md
```

Also summarize the top findings in chat.

Use this structure:

```markdown
# Vocabulary redistribution report - {start-level} to end

## Scope
- Start level: `{start-level}`
- Included levels: …
- Skipped levels: …
- Chain limit: A -> B -> C -> D, then stop

## Executive summary
- Recommended chains: N
- Shared A1 recommendations: N
- Candidate-only chains: N
- Rejected chains: N
- Highest-impact levels: …

## Ordered level pass

Only include levels where at least one opportunity was found. Add a single
summary line before the table: "N levels scanned, M had opportunities."

| Level | Theme | Current tracked words | Best opportunities | Status |
|-------|-------|-----------------------|--------------------|--------|

## Recommended recursive chains

### Chain 1 - {short title}
| Step | Move | From | To | Replacement for owner | Termination |
|------|------|------|----|-----------------------|-------------|

**Why this improves relevance:** …

**Required question changes:**
- `{level}` Qn: …

**Translations needed:**
- `{word}`: provide all supported languages when high confidence, or mark `needs translation review`.

**Audio stems:**
- List stems that would need renaming if the question text changes.

## Shared A1 word recommendations
| Word | Current tracked level | Suggested second level | Why both levels need it | Translation tracking rule |
|------|-----------------------|------------------------|-------------------------|---------------------------|

For each row, state whether the word should stay in the current tracked level's
`translations.json` / WordPairs or move tracking to the suggested level. The
other level can still teach/review the word in questions, but should not add a
duplicate translation row.

## Candidate-only chains
Same format, with blocker / decision needed.

## Rejected chains
| Candidate | Proposed target | Current owner | Why rejected |
|-----------|-----------------|---------------|--------------|

## Unused and medley endpoint pool
| Word | Source | Best-fit level | Reason |
|------|--------|----------------|--------|

## Notes for implementation
- Do not apply automatically.
- Apply one approved chain at a time.
- After edits, validate JSON and reorder translations by question appearance.
```

## Do Not

- Do not edit `questions.json`, `translations.json`, or flow files during the
  report pass.
- Do not commit unless explicitly asked.
- Do not work on `main`.
- Do not include levels before `waking-up` unless the user changes the start.
- Do not recursively replace medley words; medley is an endpoint.
- Do not continue beyond `A -> B -> C -> D`.
- Do not force a chain when relevance decreases downstream.
- Do not treat A2+ words as repeatable shared words unless the user explicitly
  approves it.
