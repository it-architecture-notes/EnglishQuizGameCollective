---
name: simplify-kids-level-content
description: >-
  Simplify a level's kids/questions.json and kids/translations.json — currently
  identical copies of the adults content — down to simple, kid-appropriate
  vocabulary and a small fixed grammar set. Use when the user asks to simplify,
  de-duplicate, or child-ify kids content for one or more levels, or asks about
  kids vocabulary/grammar rules.
disable-model-invocation: true
---

# Simplify Kids Level Content

Unlike `redistribute-level-vocabulary`, this skill **edits** `kids/questions.json`
and `kids/translations.json` directly — it is not report-only. Every level's
`adults/` files stay untouched; this only ever touches the `kids/` copy.

## Scope

Every level under `app/assets/quiz-data/levels/{level}/kids/` that still has
`kids/questions.json` byte-identical (or near-identical) to `adults/questions.json`.
Process levels in `game-flow.json` order (`directoryName`, skipping `kind:
"reminder"` entries) so the "already taught to kids" word ledger builds up
correctly as you go — a later level must not reuse a word before an earlier
level has introduced it.

Reference inputs:
- `app/assets/data/flow/game-flow.json` — ordered level list (`directoryName`)
- `app/assets/quiz-data/levels/{level}/kids/questions.json` / `translations.json`
  — the files this skill edits
- `app/assets/quiz-data/levels/{level}/adults/questions.json` — original content;
  the starting point for each kids row, never edited by this skill
- `cursor-claude-common/references/final words/*.csv` — word, POS, CEFR level,
  frequency columns; **A1 entries are the primary simple-word source pool**
- `cursor-claude-common/references/remove-word-list-references/3000 words oxford.txt`
  — secondary CEFR source when the CSVs don't cover a word
- `tools/gather_prior_level_words.py --flavor kids` — lists every word already
  taught to kids in levels before the target (now flavor-aware; use this
  instead of re-scanning every prior `kids/translations.json` by hand)
- `app/assets/data/config/conversation_characters.json` — do not touch;
  character-name handling is unrelated to this skill
- `cursor-claude-common/skills/audit-quiz-level/SKILL.md` — the **adult**
  grammar-progression reference (4 Parts by ML). Useful for context on what
  the adult version is doing, but kids grammar (below) is its own smaller,
  ML-independent set — do not apply the Part table to kids content.

Read project rules in `cursor-claude-common/rules/rules.md` before starting.

## Kids grammar — allowed set (ML-independent)

Kids grammar does **not** progress with `mainLevel` the way adult grammar does
(4 Parts across ML1–12). Every kids level, regardless of which ML it sits in,
draws from the **same** fixed simple set below. For kids, **vocabulary and
theme are the progression axis, not grammar complexity.**

| Allowed | Notes |
|---|---|
| Present Simple | `to be` (am/is/are); base present (`I go`, `we like`); 3rd person `-s`; negatives (`don't`/`doesn't`); Yes/No and WH-questions (`what`, `where`, `who`, `Do you…?`) |
| Present Continuous | `is`/`are` + `-ing` |
| Future: `going to` | **only** this future form |
| Simple Past | regular (`-ed`) and **common irregulars only** — allowed list: `go/went`, `see/saw`, `eat/ate`, `have/had`, `is/was`, `do/did`, `make/made`, `take/took`, `come/came`. If a verb's irregular past isn't on this list (not a top-20-most-common English verb), rewrite the sentence to avoid the past tense rather than use it; questions/negatives with `did`/`didn't` |
| Modal: `can` | ability/permission only |
| Imperative | `Sit down.`, `Let's go.` |
| `There is` / `There are` | |
| Possessives, prepositions | |
| Simple comparative/superlative | `bigger`, `biggest` — concrete, kid-natural only |
| Fixed greeting/courtesy idioms | short fixed chunks (`Nice to meet you`, `See you later`) are OK even though not grammatically compositional — matches existing project precedent for idiom exceptions |

| Forbidden (do not use, regardless of ML) | |
|---|---|
| `will`-future | defer entirely — kids get `going to` only |
| Conditionals (all) | first/second/third |
| Modals beyond `can` | `must`, `should`, `have to`, `could`, `might`, `may` |
| Present Perfect, Past Continuous | and anything from adult Part 4 |
| Passive voice | |
| Reported speech | |
| Phrasal verbs | |
| Subordinate clauses | `because`, `although`, `which`, `that`-clauses |
| Compound sentences joining two full clauses | via `and`/`but` — keep one clause per line |

## Kids vocabulary rules

1. **Replace complicated words with simple, common, kid-world words.** Prefer
   words already in the running kids vocabulary ledger (see Workflow) over
   introducing a new word, so nothing new needs translating. When a new word
   really is needed, prefer **A1** entries from the reference CSVs, then A2,
   and prefer concrete/picturable words over abstract ones even at the same
   CEFR tier (`want` not `desire`, `get` not `obtain`, `see` not `notice`).
2. **Don't overuse the same substitute word.** Don't reuse the same
   simplification substitute in the same level or either of the 2 adjacent
   levels — spread reuse out so the pack doesn't feel monotonous. This is a
   local spacing rule, not a global one-use-only rule.
3. **A previously-taught word does not get a new `translations.json` row.**
   If a level's simplified content reuses a word already in the kids ledger,
   it can appear in the question/answer text freely, but do not add another
   `translations_list` entry for it — it's already taught.
4. **`WordPairs` is the explicit exception to rule 2.** Kids `WordPairs`
   groups may deliberately reuse a word set taught in `WordPairs` a few
   levels earlier — this is spaced-repetition review, not monotony, and is
   encouraged rather than avoided. Still don't add a duplicate translation
   row for a reused word (rule 3 still applies).
5. **Prefer kids'-world vocabulary** — school, playground, home, family, pets,
   toys, food, simple everyday actions — over adult-register vocabulary
   (office/finance/admin/travel-logistics words), even when the adult word
   is otherwise "simple" (e.g. prefer `job` context words like *teacher,
   doctor, firefighter* over *employee, manager, colleague*).
6. **Sentence/line length**: cap `line1`/`line2`/`answer`/`correct_order`/
   `sentence` at roughly 4–6 words for conversational templates. One clause
   per sentence — see grammar table for banned subordinators/compounds.
7. **Common irregular verbs only** (see grammar table's explicit allowed list)
   even where the past tense itself is allowed.
8. **Image template answer words drive `imageName` — keep them in sync.** If
   simplifying an `imageQuizTemplate-1`/`-2` row changes the primary `answer`
   noun, the `imageName` (and any `wrongAnswers` tile names for template-2)
   must be updated to match the new word, and the new image name must be
   flagged in the output summary (see Output) — a new image asset needs to be
   generated/copied before that row works in-app, same as any other
   text-driving-audio change needing regeneration.

## Workflow

### 1. Build/refresh the kids vocabulary ledger

For the target level, run:

```
python3 tools/gather_prior_level_words.py {target-level} --flavor kids --format json
```

This lists every word already taught to kids in levels before the target
(flow order). Use it to decide, for each simplification, whether a candidate
substitute word is already known (no new translation row) or genuinely new
(needs one, prefer A1).

### 2. Read the level's current kids content

Read `kids/questions.json` and `kids/translations.json` (at this point,
identical or near-identical to `adults/`). For each row:

- Flag vocabulary outside the kids-simple band (uncommon words, adult-register
  words, low-frequency irregulars).
- Flag grammar outside the **Kids grammar — allowed set** table above.
- Flag lines longer than ~4–6 words or with a subordinate/compound clause.
- Note `WordPairs` groups as reuse candidates per rule 4.

### 3. Rewrite flagged rows

- Prefer a **word swap** that keeps the template/answer shape and `genders`
  field intact — this is the lowest-risk edit.
- Ensure every word in `distractors`/`wrongAnswers` arrays is also simplified
  to kid-friendly vocabulary — a hard word smuggled into a wrong-answer
  option is just as displayed/readable to the player as one in the answer,
  and it still counts as vocabulary complexity even though it's never correct.
- For `imageQuizTemplate-1`/`-2` rows, if the `answer` noun changes, update
  `imageName` (and `wrongAnswers` tile names for template-2) to match, and
  record the new image name(s) in the output summary — see vocabulary rule 8.
- If the grammar itself is out of band (e.g. `will`-future, present perfect),
  **rewrite the sentence using an allowed structure**, keeping the row's
  teaching intent as close as possible (e.g. `will`-future → `going to`-future
  covering the same idea).
- If a row cannot be simplified without changing its fundamental purpose,
  **flag it as a structural exception** in the summary (see Output) instead
  of forcing an awkward edit — don't silently ship a broken or nonsensical
  question.
- Never change `template` or the `genders` field as part of a vocabulary/
  grammar simplification pass — those are independent systems (casting /
  UI dispatch), out of scope here.
- If a row's spoken text changes, its `audio_file`/`audio_file1`/`audio_file2`
  stem name should be updated to still describe the new text (matching the
  project's existing "filename reflects content" convention) — but do not
  attempt to regenerate the actual `.m4a` here; flag it for TTS regeneration
  in the summary instead, same as any other content-driving-audio change.

### 4. Update `kids/translations.json`

- Remove rows for words the simplified content no longer teaches.
- Add rows only for genuinely new words (rule 3) — check the ledger first.
- Keep the existing all-locale translation format; translate the new word
  into all locales already covered by the file.

### 5. Validate

```
python3 tools/validate_quiz_level_json.py
```

Must pass (mandatory `genders` field, JSON schema) before moving to the next
level.

## Output

After a batch of levels (not one level per message), report:

```markdown
## Kids simplification — {level range}

| Level | Words simplified | New kids words added | Reused-ledger words | Grammar rewrites | New image assets | Structural exceptions |
|-------|-------------------|------------------------|----------------------|-------------------|-------------------|------------------------|

### Structural exceptions needing judgment
- `{level}` Qn: {why it couldn't be cleanly simplified, options}

### Audio stems needing regeneration
- `{level}`: {old stem} -> {new stem} ({old text} -> {new text})

### New image assets needed
- `{level}` Qn (`imageQuizTemplate-N`): {old imageName} -> {new imageName}
  ({old answer} -> {new answer})
```

## Do Not

- Do not touch `adults/questions.json` or `adults/translations.json`.
- Do not touch `template` or `genders` on any row.
- Do not add a `translations.json` row for a word already in the kids ledger.
- Do not use `WordPairs` reuse (rule 4) as license to reuse non-WordPairs
  words too — the spacing rule (rule 2) still applies everywhere else.
- Do not use any grammar outside the **Kids grammar — allowed set** table,
  even if the adult content at that level's `mainLevel`/Part would allow it.
- Do not regenerate `.m4a` audio as part of this skill — flag it instead.
- Do not change an `imageQuizTemplate-1`/`-2` `answer` word without also
  updating `imageName`/`wrongAnswers` to match and flagging the new asset in
  the summary — do not leave `imageName` pointing at a stale word.
- Do not commit unless explicitly asked; do not work on `main`.
