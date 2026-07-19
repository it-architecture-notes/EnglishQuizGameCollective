# common-words-19 — question placement (for approval)

**MainLevel:** not yet in `game-flow.json` → **Part 4** grammar

**Vocabulary:** Group 19 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | determine, define, force, identify, ignore, prove, represent, result, state |
| WordPairs (4) | awful, confusing, actual, carefully |
| Other (6) | till, appropriate, limited, unique, connection, content |

**Rules applied**
- WordPairs words **only** in Q2.
- **ClozeSequence:** exactly **2** words; **≥1 verb**.
- **Other templates:** **1–2** words each.
- Words may be taught in context without being the blank answer.
- No `translations.json` yet.

---

## Proposed questions

### Q1 — AppearDisappear · **state**
`Please state your name at the desk.`

### Q2 — WordPairs · **awful, confusing, actual, carefully**
Match the four adj/adv (translations deferred).

### Q3 — ConvoTemplate-1 · **identify**
| Line 1 | `Can you _____ the correct file?` |
| Line 2 | `Yes, I can _____ it now.` |
| Answer | `identify` |

### Q4 — AppearDisappear · **prove**
`Scientists prove ideas with careful tests.`

### Q5 — ConvoTemplate-1 · **define**
| Line 1 | `Can you _____ this word?` |
| Line 2 | `Yes, I can _____ it clearly.` |
| Answer | `define` |

### Q6 — ClozeSequence · **determine**, **appropriate** (2 · 1 verb)
`Tests _____ the _____ level for each student.`  
**Answers:** `determine` · `appropriate`

### Q7 — SentenceBuilder · **unique**, **connection**
`A unique connection links the two systems.`

### Q8 — AppearDisappear · **ignore**
`Do not ignore important warning signs.`

### Q9 — ClozeSequence · **force**, **limited** (2 · 1 verb)
`Do not _____ the door; space is _____ here.`  
**Answers:** `force` · `limited`

### Q10 — ClozeSequence · **represent**, **till** (2 · 1 verb)
`These charts _____ sales _____ next month.`  
**Answers:** `represent` · `till`

### Q11 — GrammarForm · **result**, **content** (Part 4 · reported speech)
| Sentence | `She said that the change would _____ in better content quality.` |
| Answer | `result` |
| Distractors | `results` · `resulted` · `resulting` |
| Teaches | `content` in context |

### Q12 — DialogueCompletion · **determine**, **appropriate** (review)
| Line 1 | `Can tests determine the appropriate level?` |
| Answer | `Yes, they help identify each unique student.` |

---

## Word coverage

| Word | Question | How taught |
|------|----------|------------|
| state | Q1 | sentence |
| identify | Q3, Q12 | blank / reply |
| prove | Q4 | sentence |
| define | Q5 | blank |
| determine | Q6, Q12 | blank / dialogue |
| appropriate | Q6, Q12 | blank / dialogue |
| unique | Q7, Q12 | sentence / reply |
| connection | Q7 | sentence |
| ignore | Q8 | sentence |
| force | Q9 | blank |
| limited | Q9 | blank |
| represent | Q10 | blank |
| till | Q10 | blank |
| result | Q11 | blank |
| content | Q11 | context |

**WordPairs:** awful, confusing, actual, carefully → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs | ✓ |
| All 6 other | ✓ |
| Cloze = 2 words each | ✓ |
| WordPairs isolated | ✓ |
