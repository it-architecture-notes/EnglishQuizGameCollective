---
name: improve-level-vocabulary
description: >-
  For a given quiz level, find vocabulary improvements: (1) unused words from
  the reference CSVs that suit the level's context better than current entries,
  and (2) words consumed in later levels that would fit more naturally here.
  Checks translations.json and WordPairs entries against final-word CSVs, the
  gathered prior-word set, and later-level translation files. Produces ranked
  candidates with suggested question changes. Use when the user asks whether
  there are better words for a level, whether a word is misplaced, or wants to
  swap a translation entry for a more context-appropriate alternative.
disable-model-invocation: true
---

# Improve Level Vocabulary

Find vocabulary that belongs in a given level but is either unused anywhere or
is currently consumed in a later level. Read project rules in
`cursor-claude-common/rules/rules.md` first (plan before implement unless user
says fix/apply).

## When to use this skill vs audit-quiz-level

| Task | Skill |
|------|-------|
| Full quality pass (translations, distractors, audio, duplicates, images) | **audit-quiz-level** |
| Light “any better words?” ideas during an audit (1–5 bullets, no full rewrites) | **audit-quiz-level** §4b |
| **Focused vocabulary improvement** — ranked candidates, misplaced-later scan, full swap proposals with question JSON | **this skill** |

Run this skill when the user asks for better context words, misplaced vocabulary,
or a concrete swap (e.g. `today` → `to teach` with question edits). It does **not**
replace translation fixes, distractor audits, or audio alignment — use **audit-quiz-level**
for those.

## Scope

Target folder:

```
app/assets/quiz-data/levels/{level-id}/
├── questions.json
└── translations.json
```

Also consult:

| Resource | Path |
|----------|------|
| Level order | `app/assets/data/flow/game-flow.json` |
| Final word CSVs (6 files) | `cursor-claude-common/references/final words/` |
| Oxford 3000 (secondary) | `cursor-claude-common/references/remove-word-list-references/3000 words oxford.txt` |
| LanGeek common nouns (secondary) | `cursor-claude-common/references/remove-word-list-references/langeek-500-most-common-nouns.txt` |
| Prior-level consumed words | `tools/gather_prior_level_words.py` |
| Prior words by type (optional) | `cursor-claude-common/output/prior-words-by-type.md` |
| Distractor / template rules | `cursor-claude-common/skills/audit-quiz-level/SKILL.md` |
| All level folders | `app/assets/quiz-data/levels/` |

## Workflow

### 1. Orient

1. Read `questions.json` and `translations.json` for the target level.
2. Find the level's position in `game-flow.json` — note its index. Call it **N**.
3. Note the **current translation entries**: every `english_word` in
   `translations.json` plus every `english_words` item in WordPairs questions.
   These are already covered — do not suggest them as candidates.
4. Note the **current answer/introduced words**: blank answers, AppearDisappear
   `words` key verbs/adjectives, SentenceBuilder `correct_order` key words.
   These are in use in the level even if not in translations.json.
5. Flag **weak / wasted translation slots** — entries in `translations.json` or
   WordPairs where the word is **not** properly introduced:
   - **Stem-only** — word appears only in a Cloze/Convo **sentence stem**, not as
     a blank answer (e.g. `today` in *What do you want to learn **today**?* while
     the answer is `to learn`)
   - **Distractor-only** — word never appears as an answer or AppearDisappear /
     SentenceBuilder key teaching word
   - **Redundant** — duplicates an image-taught noun or another translation row
   These slots are **preferred swap targets** when introducing a new candidate.

### 2. Gather prior consumed words

Run:

```bash
python3 tools/gather_prior_level_words.py {level-id}
```

This lists every `english_word` from levels 1 … N-1 (translations + WordPairs).
Save as **prior set**. These words are already consumed and must **not** be
re-added to this level's translations.

### 3. Find unused reference candidates

1. Open each file in `cursor-claude-common/references/final words/`:
   - `verbs-400.csv`, `adjectives-300.csv`, `adverbs-150.csv`,
     `auxiliaries.csv`, `conjunctions.csv`, `prepositions.csv`
2. Optionally scan **Oxford 3000** for high-frequency words not in the CSVs
   (e.g. adverbs like `abroad`) — prefer A1/A2 entries.
3. Optionally scan **LanGeek 500 common nouns** for common noun candidates not in
   the CSVs or Oxford-derived candidate set. For standard themed levels, use
   noun suggestions carefully: concrete object nouns usually belong in image
   questions, not `translations.json`, unless the user explicitly asks for noun
   swaps or the level has no image coverage.
4. For each entry, check:
   - **Not in prior set** (not consumed by levels 1 … N-1)
   - **Not already in this level's translations/WordPairs**
   - **Not already in this level's introduced vocabulary** (answers, AppearDisappear, SentenceBuilder)
   - Thematically fits the level (use level name + context as the filter)
5. Prefer **A1** entries, then **A2**. Prefer entries with `count` 0 (never
   used anywhere yet). Verbs first, then adjectives/adverbs.
6. Also flag words **in level sentences but untracked** (e.g. `mistake` in a
   Cloze stem, `lesson` in SentenceBuilder) — strong candidates to **add** or
   swap in without inventing new context.
7. These are **unused candidates** — words available that could serve this
   level well but are not yet assigned anywhere.

### 4. Find misplaced later-level words

1. List level ids at flow positions **N+1 … end** from `game-flow.json`.
2. For each later level, read `translations.json` (`english_word` entries) and
   `english_words` from WordPairs in `questions.json`. Quick scan:

   ```bash
   # Example: grep translation keys for levels after target in flow order
   grep -h '"english_word"' app/assets/quiz-data/levels/{later-level-id}/translations.json
   ```

   Or use `cursor-claude-common/output/prior-words-by-type.md` to see which
   level consumed each word (generated from flow order).
3. For each word found in a later level, ask: **does this word fit the target
   level's theme/context as naturally or more naturally than the later level?**
3. A word qualifies as "misplaced" when:
   - Its primary everyday context matches the target level better than the
     level it is currently in (e.g. `to repeat` in baby-care vs at-the-school)
   - It is a simpler (A1/A2) word sitting in a later, more advanced level
   - It would have been a natural teaching word at the target level and there
     was no clear reason to defer it
4. Note the later level where each misplaced word currently lives. Do **not**
   suggest removing it from the later level — only flag it as an opportunity
   the target level missed.

### 5. Score and rank candidates

For each candidate (unused or misplaced), assign a score:

| Factor | Weight |
|--------|--------|
| Thematic fit to target level (strong / partial / weak) | High |
| CEFR level (A1 > A2 > B1) | High |
| Currently unused anywhere (count 0) | Medium |
| Misplaced from later level (vs just unused) | Medium |
| Replaces a weak/wasted translation slot | Medium |
| Verb over adjective/adverb | Low |

Report the top candidates (cap at ~10 total). Do not pad with weak fits.

### 6. For each top candidate, suggest a question change

Every candidate needs a home. For each one, show:

- **Which existing translation entry it could replace** (if a swap is needed
  to stay within the 12–15 entry limit), **or** that it could be added if the
  level is under the limit.
- **Which existing question** could be edited to introduce it (Convo blank,
  Cloze blank, AppearDisappear sentence, SentenceBuilder sentence), **or** a
  sketch of a new question if no existing one fits.
- **What would be removed** if an existing entry/question is displaced — and
  why the displaced item is the weaker choice.

Keep suggestions concrete: quote the proposed new question sentence, answer,
and distractors where applicable. Distractors should prefer prior-consumed
vocabulary per the distractor rules in the **audit-quiz-level** skill.

When any question sentence changes, update matching **`audio_file` / `audio_file1` /
`audio_file2` stems** in `questions.json` (name match only — no `.m4a` required).
See **audit-quiz-level** → Audio alignment.

**Swap constraints** (same as audit-quiz-level):

- Swap replacements must **not** be object nouns — use verbs, adjectives,
  adverbs, prepositions, conjunctions only.
- **Phrasal verbs are independent entries:** `to open` (waking-up) does not block
  `to open an account` (bank); `get` does not block `get up`. Match the exact
  phrase taught in the question.
- Do not suggest removing a word that is the **sole answer** to a question
  without also proposing the replacement question.
- Do not exceed 15 translation entries after the swap.
- The displaced entry should not have more thematic claim on this level than
  the proposed replacement.
- After swaps, **reorder `translations_list`** to match question appearance order.

### 7. Output

Report inline in chat. Wait for approval before editing any JSON.

```markdown
# Vocabulary improvement — {level-id}

## Level context
- Flow position: N of M
- Theme: …
- Current translations: N entries (list)
- Weak / wasted translation slots: …
- Current introduced words (non-translation): …

## Prior consumed words
- Source: gather_prior_level_words.py output
- Total: N words consumed in levels 1 … N-1

## Unused reference candidates

| Word | POS / CEFR | Count | Why it fits | Suggested home |
|------|-----------|-------|-------------|----------------|
| … | verb / A1 | 0 | … | Replace Q3 Cloze blank, swap out "X" |

## Misplaced later-level words

| Word | Currently in | Level | Why it fits here better | Suggested home |
|------|-------------|-------|------------------------|----------------|
| … | baby-care | 18 | … | New ConvoTemplate-1 after Q2 |

## Recommended swaps

For each recommended swap, show the full proposed change:

### Swap N: {current entry} → {proposed entry}
- **Remove from translations:** …
- **Add to translations:** … (with all language translations)
- **Question change:** … (template, sentence, answer, distractors)
- **Audio stems:** … (updated stem names if sentence changed)
- **Reason:** …

## What stays

Briefly note why the remaining translation entries are well-placed and do not
need replacement — confirms the analysis is complete.
```

Wait for user approval before applying. When user says **yes**, **apply**, or
**go ahead**, apply the approved swaps to `questions.json` and
`translations.json`. Reorder `translations_list` to match question flow.
Validate JSON structure after edits.

## Do not

- Remove an entry without proposing a concrete replacement question
- Suggest object nouns as translation-slot replacements
- Add words already in the prior consumed set back into translations.json
- Expand translations beyond 15 entries
- Commit unless explicitly asked
- Work on `main` branch
