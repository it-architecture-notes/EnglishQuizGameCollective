# common-words-10 — question placement (for approval)

**MainLevel:** 11 → **Part 4** grammar (Parts 1–3 review allowed)  
(Present Perfect; Past Continuous; **used to**; simple passive; **would like to**; second conditional)

**Vocabulary:** Group 10 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | kill, last, hide, point, escape, own, place, predict, prefer |
| WordPairs (4) | generally, mostly, impossible, independent |
| Other (6) | closely, naturally, somehow, strongly, primary, proper |

**Rules applied**
- WordPairs words **only** in Q2.
- **ClozeSequence:** exactly **2** words; **≥1 verb**.
- **Other templates:** **1–2** words each.
- Words may be taught in context without being the blank answer.
- No `translations.json` yet.

---

## Proposed questions

### Q1 — AppearDisappear · **prefer**
`I would prefer to walk home today.`

### Q2 — WordPairs · **generally, mostly, impossible, independent**
Match the four adj/adv (translations deferred).

### Q3 — ConvoTemplate-1 · **predict**
| Line 1 | `Can you _____ the weather tomorrow?` |
| Line 2 | `Yes, I can _____ rain.` |
| Answer | `predict` |

### Q4 — AppearDisappear · **own**
`They own a small shop near the park.`

### Q5 — ConvoTemplate-1 · **hide**
| Line 1 | `Where did you _____ the key?` |
| Line 2 | `I _____ it under the mat.` |
| Answer | `hide` |

### Q6 — ClozeSequence · **escape**, **closely** (2 · 1 verb)
`The cat tried to _____ , watched _____ by the guard.`  
**Answers:** `escape` · `closely`

### Q7 — SentenceBuilder · **naturally**, **proper**
`Trees grow naturally in proper soil.`

### Q8 — AppearDisappear · **place**, **primary**
`Please place the primary key on the desk.`

### Q9 — ClozeSequence · **point**, **strongly** (2 · 1 verb)
`She will _____ _____ to the safe door.`  
**Answers:** `point` · `strongly`

### Q10 — ClozeSequence · **last**, **somehow** (2 · 1 verb)
`The meeting did not _____ long, but it ended _____ .`  
**Answers:** `last` · `somehow`

### Q11 — GrammarForm · **kill**, **naturally** (Part 4 · passive)
| Sentence | `The frost naturally _____ the weeds in the field.` |
| Answer | `killed` |
| Distractors | `kill` · `killing` · `kills` |
| Teaches | `naturally` in context; passive `killed` |

### Q12 — DialogueCompletion · **escape**, **closely** (review)
| Line 1 | `Did the rabbit escape the cage?` |
| Answer | `Yes, we watched it closely afterward.` |

---

## Word coverage

| Word | Question | How taught |
|------|----------|------------|
| prefer | Q1 | sentence |
| predict | Q3 | blank |
| own | Q4 | sentence |
| hide | Q5 | blank |
| escape | Q6, Q12 | blank / dialogue |
| closely | Q6, Q12 | blank / reply |
| naturally | Q7 | sentence |
| proper | Q7 | sentence |
| place | Q8 | sentence |
| primary | Q8 | sentence |
| point | Q9 | blank |
| strongly | Q9 | blank |
| last | Q10 | blank |
| somehow | Q10 | blank |
| kill | Q11 | blank → `killed` |
| naturally | Q7, Q11 | sentence / context |

**WordPairs:** generally, mostly, impossible, independent → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs | ✓ |
| All 6 other | ✓ |
| Cloze = 2 words each | ✓ |
| GrammarForm = Part 4 | ✓ |
