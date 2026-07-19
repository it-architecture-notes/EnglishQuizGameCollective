# common-words-2 — question placement (for approval)

**MainLevel:** 3 → **Part 1** grammar only  
(Present Simple, `do`/`does`, 3rd person `-s`, `can` + base verb, `There is/are` — no past/future structures)

**Vocabulary:** Group 2 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | believe, remember, come back, end, go back, happen, seem, hear, imagine |
| WordPairs (4) | sure, only, real, true |
| Other (6) | among, beyond, despite, toward, upon, including |

**Rules applied**
- WordPairs words **only** in Q2 (not in other questions).
- Questions Q1, Q3–Q12 use the **9 verbs + 6 other** words.
- **ClozeSequence:** exactly **2** target words per question; **at least one verb**.
- **Other templates:** **1–2** target words each.
- A word counts as **taught** when it appears in the question text — it does **not** need to be a blank answer (e.g. GrammarForm may teach one word in context and test another in the blank).
- No `translations.json` yet.

**Template order**

| # | Template |
|---|----------|
| 1 | AppearDisappear |
| 2 | WordPairs |
| 3 | ConvoTemplate-1 |
| 4 | AppearDisappear |
| 5 | ConvoTemplate-1 |
| 6 | ClozeSequence |
| 7 | SentenceBuilder |
| 8 | AppearDisappear |
| 9 | ClozeSequence |
| 10 | ClozeSequence |
| 11 | GrammarForm |
| 12 | DialogueCompletion |

---

## Proposed questions

### Q1 — AppearDisappear · **happen**
`Strange things can happen on the first day of school.`

---

### Q2 — WordPairs · **sure, only, real, true**
Match the four adj/adv (translations deferred).

---

### Q3 — ConvoTemplate-1 · **imagine**
| | |
|---|---|
| Line 1 | `Can you _____ what the house looks like?` |
| Line 2 | `Yes, I can _____ it very clearly.` |
| Answer | `imagine` |

Part 1: `can` + base verb.

---

### Q4 — AppearDisappear · **hear**
`I hear birds singing every morning.`

---

### Q5 — ConvoTemplate-1 · **believe**
| | |
|---|---|
| Line 1 | `Do you _____ her story?` |
| Line 2 | `Yes, I _____ every word she says.` |
| Answer | `believe` |

---

### Q6 — ClozeSequence · **remember**, **despite** (2 · 1 verb)
`I _____ his face, _____ the poor lighting.`  
**Answers:** `remember` · `despite`

---

### Q7 — SentenceBuilder · **including**, **among**
`Everyone is here, including Anna among our friends.`

---

### Q8 — AppearDisappear · **come back**
`They come back home before dinner every day.`

---

### Q9 — ClozeSequence · **go back**, **toward** (2 · 1 verb)
`We _____ home late and walk _____ the park.`  
**Answers:** `go back` · `toward`

Present habitual framing (no `will`).

---

### Q10 — ClozeSequence · **seem**, **beyond** (2 · 1 verb)
`Things _____ different here, _____ the bridge.`  
**Answers:** `seem` · `beyond`

---

### Q11 — GrammarForm · **end**, **upon** (Part 1 · 3rd person **-s**)
| | |
|---|---|
| Sentence | `When the bus stops upon the hill, the movie _____ at nine every night.` |
| Answer | `ends` |
| Distractors | `end` · `ending` · `ended` |
| Teaches | `upon` in sentence text; `end` → `ends` in blank |

Tests Present Simple 3rd person — appropriate for ML3 / Part 1.

---

### Q12 — DialogueCompletion · **including**, **despite** (review)
| | |
|---|---|
| Line 1 | `Is everyone at the meeting?` |
| Answer | `Yes, including Tom, despite the bad weather.` |

Light **review** of preps from Q6–Q7; no new lemmas.

---

## Word coverage (15-word main pool)

| Word | Question | Template | How taught |
|------|----------|----------|------------|
| happen | Q1 | AppearDisappear | sentence |
| imagine | Q3 | ConvoTemplate-1 | blank answer |
| hear | Q4 | AppearDisappear | sentence |
| believe | Q5 | ConvoTemplate-1 | blank answer |
| remember | Q6 | ClozeSequence | blank answer |
| despite | Q6, Q12 | ClozeSequence, DialogueCompletion | blank / reply |
| including | Q7, Q12 | SentenceBuilder, DialogueCompletion | sentence / reply |
| among | Q7 | SentenceBuilder | sentence |
| come back | Q8 | AppearDisappear | sentence |
| go back | Q9 | ClozeSequence | blank answer |
| toward | Q9 | ClozeSequence | blank answer |
| seem | Q10 | ClozeSequence | blank answer |
| beyond | Q10 | ClozeSequence | blank answer |
| upon | Q11 | GrammarForm | sentence context |
| end | Q11 | GrammarForm | blank → `ends` |

**WordPairs (separate):** sure, only, real, true → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs used | ✓ |
| All 6 other words used | ✓ |
| Cloze Q6 / Q9 / Q10 = exactly 2 words each | ✓ |
| Cloze Q6 / Q9 / Q10 each have ≥1 verb | ✓ |
| WordPairs isolated | ✓ |
| GrammarForm = Part 1 | ✓ (`ends`) |
| `despite` / `including` in Q12 | intentional review |

---

## Notes / questions for you

1. **Q12 review** — `including` and `despite` repeat from Q6–Q7. OK for dialogue reinforcement, or use **hear** + **believe** verb review instead?

2. **Q11** — `upon` appears only as context (not the blank). OK, or prefer **upon** in a Cloze and move **end** to a solo GrammarForm sentence?

Once you approve (with any tweaks), I'll write `questions.json` without translations.
