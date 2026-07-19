# common-words-15 — question placement (for approval)

**MainLevel:** not yet in `game-flow.json` → **Part 4** grammar

**Vocabulary:** Group 15 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | steer, stir, suppose, tie, train, unlock, come along, water, wrap |
| WordPairs (4) | eventually, forward, valuable, middle |
| Other (6) | effectively, primarily, slightly, virtually, academic, tiny |

**Rules applied**
- WordPairs words **only** in Q2.
- **ClozeSequence:** exactly **2** words; **≥1 verb**.
- **Other templates:** **1–2** words each.
- Words may be taught in context without being the blank answer.
- No `translations.json` yet.

---

## Proposed questions

### Q1 — AppearDisappear · **stir**
`She stirs the soup slowly every evening.`

### Q2 — WordPairs · **eventually, forward, valuable, middle**
Match the four adj/adv (translations deferred).

### Q3 — ConvoTemplate-1 · **train**
| Line 1 | `Have you _____ the new staff yet?` |
| Line 2 | `Yes, we have _____ them this week.` |
| Answer | `trained` |

### Q4 — AppearDisappear · **water**
`Please water the tiny plants on the balcony.`

### Q5 — ConvoTemplate-1 · **unlock**
| Line 1 | `Can you _____ the side door?` |
| Line 2 | `Yes, I can _____ it now.` |
| Answer | `unlock` |

### Q6 — ClozeSequence · **tie**, **effectively** (2 · 1 verb)
`Please _____ the box shut _____ .`  
**Answers:** `tie` · `effectively`

### Q7 — SentenceBuilder · **academic**, **virtually**
`Academic teams meet virtually on Mondays.`

### Q8 — AppearDisappear · **wrap**
`Wrap the gift before you leave.`

### Q9 — ClozeSequence · **come along**, **primarily** (2 · 2 verbs)
`Friends can _____ and help, _____ with cleaning.`  
**Answers:** `come along` · `primarily`

### Q10 — ClozeSequence · **suppose**, **slightly** (2 · 1 verb)
`I _____ the plan will change _____ next month.`  
**Answers:** `suppose` · `slightly`

### Q11 — GrammarForm · **steer**, **tiny** (Part 4 · passive)
| Sentence | `The boat was _____ toward the tiny dock.` |
| Answer | `steered` |
| Distractors | `steer` · `steering` · `steers` |
| Teaches | `tiny` in context (also Q4) |

### Q12 — DialogueCompletion · **unlock**, **effectively** (review)
| Line 1 | `Can you unlock the storage room?` |
| Answer | `Yes, and we can organize it effectively today.` |

---

## Word coverage

| Word | Question | How taught |
|------|----------|------------|
| stir | Q1 | sentence |
| train | Q3 | blank → `trained` |
| water | Q4 | sentence |
| unlock | Q5, Q12 | blank / dialogue |
| tie | Q6 | blank |
| effectively | Q6, Q12 | blank / reply |
| academic | Q7 | sentence |
| virtually | Q7 | sentence |
| wrap | Q8 | sentence |
| come along | Q9 | blank |
| primarily | Q9 | blank |
| suppose | Q10 | blank |
| slightly | Q10 | blank |
| steer | Q11 | blank → `steered` |
| tiny | Q4, Q11 | sentence / context |

**WordPairs:** eventually, forward, valuable, middle → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs | ✓ |
| All 6 other | ✓ |
| Cloze = 2 words each | ✓ |
| WordPairs isolated | ✓ |
