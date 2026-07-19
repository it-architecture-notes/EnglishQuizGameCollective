# common-words-3 — question placement (for approval)

**MainLevel:** 4 → **Part 2** grammar (Part 1 review also allowed)  
(`will` / **be going to**; **must**; comparatives / superlatives; **first conditional** — no past / present perfect)

**Vocabulary:** Group 3 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | create, join, sound, visit, add, forget, guess, hope, put down |
| WordPairs (4) | poor, smart, fine, main |
| Other (6) | per, along, monthly, lucky, tasty, within |

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

### Q1 — AppearDisappear · **hope**
`I hope we can finish our work today.`

---

### Q2 — WordPairs · **poor, smart, fine, main**
Match the four adj/adv (translations deferred).

---

### Q3 — ConvoTemplate-1 · **visit**
| | |
|---|---|
| Line 1 | `Can we _____ Grandma this Sunday?` |
| Line 2 | `Yes, I want to _____ her too.` |
| Answer | `visit` |

Part 1 review: `want to` + base verb.

---

### Q4 — AppearDisappear · **create**
`Art students create colorful posters every week.`

---

### Q5 — ConvoTemplate-1 · **guess**
| | |
|---|---|
| Line 1 | `Can you _____ the right answer?` |
| Line 2 | `No, I cannot _____ it yet.` |
| Answer | `guess` |

---

### Q6 — ClozeSequence · **forget**, **within** (2 · 1 verb)
`Do not _____ your bag _____ the classroom.`  
**Answers:** `forget` · `within`

---

### Q7 — SentenceBuilder · **along**, **lucky**
`Lucky kids walk along the river after school.`

---

### Q8 — AppearDisappear · **tasty**
`Grandma cooks tasty soup every Friday.`

---

### Q9 — ClozeSequence · **join**, **put down** (2 · 2 verbs)
`Please _____ our team and _____ your phone now.`  
**Answers:** `join` · `put down`

Phrasal verb **put down** paired with **join** (dist-4 Group 3 cluster).

---

### Q10 — ClozeSequence · **sound**, **monthly** (2 · 1 verb)
`The band does _____ great at our _____ show.`  
**Answers:** `sound` · `monthly`

---

### Q11 — GrammarForm · **add**, **per** (Part 2 · first conditional)
| | |
|---|---|
| Sentence | `If you _____ one herb per bowl, the soup will taste better.` |
| Answer | `add` |
| Distractors | `adds` · `added` · `adding` |
| Teaches | `per` in sentence text; `add` in blank |

Tests **first conditional** (`if` + present, `will` in main clause) — appropriate for ML4 / Part 2.

---

### Q12 — DialogueCompletion · **forget**, **within** (review)
| | |
|---|---|
| Line 1 | `Do you have your notebook?` |
| Answer | `Yes, it is within my desk.` |

Light **review** of Q6; no new lemmas.

---

## Word coverage (15-word main pool)

| Word | Question | Template | How taught |
|------|----------|----------|------------|
| hope | Q1 | AppearDisappear | sentence |
| visit | Q3 | ConvoTemplate-1 | blank answer |
| create | Q4 | AppearDisappear | sentence |
| guess | Q5 | ConvoTemplate-1 | blank answer |
| forget | Q6, Q12 | ClozeSequence, DialogueCompletion | blank / dialogue |
| within | Q6, Q12 | ClozeSequence, DialogueCompletion | blank / reply |
| along | Q7 | SentenceBuilder | sentence |
| lucky | Q7 | SentenceBuilder | sentence |
| tasty | Q8 | AppearDisappear | sentence |
| join | Q9 | ClozeSequence | blank answer |
| put down | Q9 | ClozeSequence | blank answer |
| sound | Q10 | ClozeSequence | blank answer |
| monthly | Q10 | ClozeSequence | blank answer |
| per | Q11 | GrammarForm | sentence context |
| add | Q11 | GrammarForm | blank answer |

**WordPairs (separate):** poor, smart, fine, main → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs used | ✓ |
| All 6 other words used | ✓ |
| Cloze Q6 / Q9 / Q10 = exactly 2 words each | ✓ |
| Cloze Q6 / Q9 / Q10 each have ≥1 verb | ✓ |
| WordPairs isolated | ✓ |
| GrammarForm = Part 2 | ✓ (first conditional) |
| `forget` / `within` in Q12 | intentional review |

---

## Notes / questions for you

1. **GrammarForm** — first conditional with **add** + **per** in context. Alternatives: `She will visit her aunt next month.` (**will** + **visit**) or `We are going to join the club tomorrow.` (**be going to** + **join**).

2. **Q12 review** — `forget` / `within` repeat from Q6. OK for dialogue reinforcement, or use **hope** + **visit** review instead?

Once you approve (with any tweaks), I'll write `questions.json` without translations.
