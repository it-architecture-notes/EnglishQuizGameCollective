# common-words-1…12 — grammar progression audit

Against `cursor-claude-common/skills/audit-quiz-level/SKILL.md` (4 Parts by `mainLevel`).

**Sources audited**
| Level | ML | Part | Source |
|-------|-----|------|--------|
| common-words-1 | 2 | 1 | `questions.json` (12 Q) |
| common-words-2 | 3 | 1 | `questions.json` (12 Q) **and** placement md |
| common-words-3 | 4 | 2 | placement md only |
| common-words-4 | 5 | 2 | placement md only |
| common-words-5 | 6 | 3 | placement md only |
| common-words-6 | 7 | 3 | placement md only |
| common-words-7 | 8 | 3 | placement md only |
| common-words-8 | 9 | 4 | placement md only |
| common-words-9 | 10 | 4 | placement md only |
| common-words-10 | 11 | 4 | placement md only |
| common-words-11 | 12 | 4 | placement md only |
| common-words-12 | — | 4* | placement md only (*not in `game-flow.json`) |

---

## Executive summary

| Severity | Count | Meaning |
|----------|-------|---------|
| **High — Forbidden** | **9** | Later-Part grammar in stems, answers, or main sentences |
| **Medium — mismatch** | **2** | Implemented JSON ≠ approved placement; GrammarForm label ≠ sentence |
| **Low — distractor** | **3** | Past/future forms only in wrong options |
| **Gap** | **several** | In-band Part grammar under-represented (not blocking, but thin) |

**Clean levels (placement):** common-words-6, 7, 8, 9, 11, 12 — no forbidden structures found.

**Most conflicts:** Part 1–2 levels using **past simple**; Part 3 using **passive**; `common-words-2` **questions.json** out of band.

---

## High — Forbidden (fix before ship)

### common-words-1 · ML2 · Part 1

| Q | Location | Structure | Issue |
|---|----------|-----------|-------|
| 10 | DialogueCompletion distractor | `I forgot my homework.` | Past simple → Part 3 |

*Main questions are in-band (present simple, can, Could you, infinitives).*

---

### common-words-2 · ML3 · Part 1

**`questions.json` (implemented — takes precedence over placement md)**

| Q | Template | Text | Structure | Issue |
|---|----------|------|-----------|-------|
| 8 | ConvoTemplate-1 | `When should I call you?` | **should** (advice) | Part 3 |
| 11 | SentenceBuilder | `Everyone came, including my mom.` | Past simple `came` | Part 3 |
| 10 | DialogueCompletion distractor | `I forgot my keys.` | Past simple | Part 3 |

**`common-words-2-question-placement.md` (draft — not in JSON)**

| Q | Text | Structure | Issue |
|---|------|-----------|-------|
| 3 | `…what the house looked like?` | Past `looked` | Part 3 |
| 7 | `Everyone was there…` | Past `was` | Part 3 |
| 12 | `Was everyone at the meeting?` | Past question | Part 3 |

---

### common-words-3 · ML4 · Part 2

| Q | Text | Structure | Issue |
|---|------|-----------|-------|
| 12 | `Did you forget your notebook?` | Past question (`Did`) | Part 3 |
| 12 | `Yes, I left it within my desk.` | Past simple `left` | Part 3 |

*In-band: first conditional GF (Q11), `will` in convo answers elsewhere, present simple elsewhere.*

---

### common-words-4 · ML5 · Part 2

| Q | Text | Structure | Issue |
|---|------|-----------|-------|
| 7 | `Jealous rivals fought in ancient stories.` | Past simple `fought` | Part 3 |

*In-band: `will` convo answers (Q3, Q5), first conditional GF (Q11).*

---

### common-words-5 · ML6 · Part 3

| Q | Text | Structure | Issue |
|---|------|-----------|-------|
| 12 | `…a note regarding the date was sent.` | **Passive** `was sent` | Part 4 |

*Otherwise good Part 3 coverage: `Did` questions, `-ed` past (`logged`, `designed`), irregular past (`fell`).*

---

## Medium — inconsistencies

| Item | Detail |
|------|--------|
| **cw-2 JSON vs placement** | Implemented level differs entirely from placement doc (different questions, template order, and word map). Grammar audit must target **JSON** for shipping. |
| **cw-10 Q11 label** | Placement says “passive” but sentence is **active** past: `The frost naturally _____ the weeds` → `killed`. Not forbidden, but mis-tagged. |

---

## Low — distractors only (prefer allowed forms)

| Level | Q | Distractor | Note |
|-------|---|------------|------|
| cw-1 | 10 | `I forgot my homework.` | Replace with present-state wrong reply |
| cw-2 JSON | 10 | `I forgot my keys.` | Same |
| cw-2 placement | 11 | `ended` | Past form; acceptable as wrong GF option per skill (low) |

---

## Per-level band check

### Part 1 — ML2–3 (cw-1, cw-2)

| In-band present? | Status |
|------------------|--------|
| Present simple / 3rd person `-s` | ✓ cw-1, cw-2 JSON GF `happens` |
| can / Could you | ✓ |
| Infinitives (`want to`, `like to`) | ✓ |
| Present continuous | Rare; distractor `is happening` in cw-2 JSON only |
| **Forbidden past / should / will** | ✗ see High table |

**Suggested fixes (cw-2 placement draft)**
- Q3: `Can you _____ what the house looks like?`
- Q7: `Everyone is here, including Anna among our friends.`
- Q12: `Is everyone at the meeting?` / `Yes, including Tom…`

**Suggested fixes (cw-2 JSON)**
- Q8 line1: `When can I call you?` or `What time can I call you?`
- Q11 SB: `Everyone is here, including my mom.`
- Distractor: `I do not have my keys.` (present)

---

### Part 2 — ML4–5 (cw-3, cw-4)

| In-band present? | Status |
|------------------|--------|
| **will** | ✓ cw-4 convo; thin in cw-3 |
| **be going to** | ✗ not used in either placement |
| **must** | ✗ not used |
| **comparatives / superlatives** | ✗ not used (WordPairs adj are base forms only) |
| **first conditional** | ✓ cw-3 Q11, cw-4 Q11 |
| **Forbidden past** | ✗ cw-3 Q12; cw-4 Q7 |

**Suggested fixes**
- cw-3 Q12: `Do you have your notebook?` / `Yes, it is within my desk.`
- cw-4 Q7: `Jealous rivals fight in ancient stories.` (present habitual)

**Gaps (optional enrichment)**
- Add one **going to** or **must** sentence in cw-3 or cw-4
- One comparative using WordPairs adj (e.g. `taller`, `kinder`) — only if teaching comparative *forms*, not just adjectives

---

### Part 3 — ML6–8 (cw-5, cw-6, cw-7)

| In-band present? | Status |
|------------------|--------|
| Past simple (regular / irregular) | ✓ all three |
| Did questions / negatives | ✓ |
| **should** | ✓ cw-5 GF distractor `will design` OK (Part 2 review); cw-6 GF |
| **could** | ✓ cw-7 GF |
| **will** review | ✓ cw-7 Q10 |
| **Forbidden present perfect / passive** | ✗ cw-5 Q12 passive only |

**Suggested fix**
- cw-5 Q12: `Yes, the teacher sent a note regarding the date.` (active past)

---

### Part 4 — ML9–12 (cw-8 … cw-12)

| In-band present? | Status |
|------------------|--------|
| Present Perfect | ✓ cw-8, 9, 11, 12 |
| Past simple review | ✓ widespread |
| **will** / **would** review | ✓ cw-9, 10, 11, 12 |
| Reported speech | ✓ cw-11, 12 GF |
| Passive voice | ✗ cw-10 claims passive but uses active; no true passive elsewhere |
| Past Continuous | ✗ not in placements |
| **used to** | ✗ not in placements |
| Second conditional | ✗ not in placements (cw-10 header mentions it but no `if + past, would`) |
| Present Perfect Continuous | ✗ not in placements |

*No forbidden (later-than-Part-4) structures — band is top.*

**Gaps (optional enrichment for Part 4 depth)**
- cw-10 Q11: rewrite as passive: `The weeds were _____ by the frost.` → `killed`
- Add one **Past Continuous** line in cw-9 or cw-10: `I was hiding the key when you called.`
- Add one **used to** line in cw-11 or cw-12

---

## GrammarForm vs Part — quick matrix

| Level | Part | GrammarForm focus | Band OK? |
|-------|------|-------------------|----------|
| cw-1 | 1 | `want` (base after I) | ✓ |
| cw-2 JSON | 1 | `happens` (3rd person) | ✓ |
| cw-2 placement | 1 | `ends` (3rd person) | ✓ |
| cw-3 | 2 | first conditional + `add` | ✓ |
| cw-4 | 2 | first conditional + `win` | ✓ |
| cw-5 | 3 | Past `designed` | ✓ |
| cw-6 | 3 | `should` + `provide` | ✓ |
| cw-7 | 3 | `could` + `mind` | ✓ |
| cw-8 | 4 | Present Perfect `drawn` | ✓ |
| cw-9 | 4 | Present Perfect `destroyed` | ✓ |
| cw-10 | 4 | Active past `killed` (not passive) | ✓ form; ✗ label |
| cw-11 | 4 | Reported speech + `marry` | ✓ |
| cw-12 | 4 | Reported speech + `shock` | ✓ |

Every level has a GrammarForm row; none test **forbidden** grammar in the blank answer.

---

## Recommended fix priority

1. **Ship blockers** — past / should / passive in High table (9 items across cw-1–5 + cw-2 JSON).
2. **Align cw-2** — decide whether JSON or placement md is canonical; they currently conflict on content and grammar.
3. **Part 2 gaps** — add `going to` or `must` when rewriting cw-3/cw-4 placements.
4. **Part 4 depth** — passive / past continuous / `used to` when writing cw-8–12 `questions.json`.

---

*Generated from placement docs + `common-words-1/2/questions.json`. Re-run after `questions.json` is written for cw-3…12.*
