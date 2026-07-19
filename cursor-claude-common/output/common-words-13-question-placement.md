# common-words-13 — question placement (for approval)

**MainLevel:** not yet in `game-flow.json` (planned after `common-words-12`) → **Part 4** grammar  
(Present Perfect; Past Continuous; passive; reported speech)

**Vocabulary:** Group 13 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | fire, freeze, frighten, give up, behave, collect, confuse, earn, hang |
| WordPairs (4) | daily, successful, fair, brilliant |
| Other (6) | automatically, personally, specifically, historical, involved, scientific |

**Rules applied**
- WordPairs words **only** in Q2.
- **ClozeSequence:** exactly **2** words; **≥1 verb**.
- **Other templates:** **1–2** words each.
- Words may be taught in context without being the blank answer.
- No `translations.json` yet.

---

## Proposed questions

### Q1 — AppearDisappear · **behave**
`Students behave well during scientific lessons.`

### Q2 — WordPairs · **daily, successful, fair, brilliant**
Match the four adj/adv (translations deferred).

### Q3 — ConvoTemplate-1 · **earn**
| Line 1 | `Have you _____ enough points this term?` |
| Line 2 | `Yes, I have _____ many already.` |
| Answer | `earned` |

### Q4 — AppearDisappear · **collect**
`Volunteers collect historical items for the museum.`

### Q5 — ConvoTemplate-1 · **frighten**
| Line 1 | `Can loud thunder _____ young children?` |
| Line 2 | `Yes, it can _____ them easily.` |
| Answer | `frighten` |

### Q6 — ClozeSequence · **freeze**, **automatically** (2 · 1 verb)
`Pipes can _____ when doors close _____ .`  
**Answers:** `freeze` · `automatically`

### Q7 — SentenceBuilder · **involved**, **specifically**
`Teams involved specifically in research meet today.`

### Q8 — AppearDisappear · **hang**
`Please hang your bag on the hook.`

### Q9 — ClozeSequence · **give up**, **personally** (2 · 1 verb)
`Do not _____ ; check the list _____ .`  
**Answers:** `give up` · `personally`

### Q10 — ClozeSequence · **confuse**, **historical** (2 · 1 verb)
`Old labels often _____ buyers studying _____ records.`  
**Answers:** `confuse` · `historical`

### Q11 — GrammarForm · **fire**, **scientific** (Part 4 · Present Perfect)
| Sentence | `The museum has _____ three guides since the scientific review began.` |
| Answer | `fired` |
| Distractors | `fire` · `firing` · `fires` |
| Teaches | `scientific` in context (also Q1) |

### Q12 — DialogueCompletion · **earn**, **personally** (review)
| Line 1 | `Did you earn enough points?` |
| Answer | `Yes, I collected them personally this week.` |

---

## Word coverage

| Word | Question | How taught |
|------|----------|------------|
| behave | Q1 | sentence |
| earn | Q3, Q12 | blank / dialogue |
| collect | Q4, Q12 | sentence / reply |
| frighten | Q5 | blank |
| freeze | Q6 | blank |
| automatically | Q6 | blank |
| involved | Q7 | sentence |
| specifically | Q7 | sentence |
| hang | Q8 | sentence |
| give up | Q9 | blank |
| personally | Q9, Q12 | blank / reply |
| confuse | Q10 | blank |
| historical | Q4, Q10 | sentence / blank |
| fire | Q11 | blank → `fired` |
| scientific | Q1, Q11 | sentence / context |

**WordPairs:** daily, successful, fair, brilliant → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs | ✓ |
| All 6 other | ✓ |
| Cloze = 2 words each | ✓ |
| WordPairs isolated | ✓ |
