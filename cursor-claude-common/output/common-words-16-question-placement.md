# common-words-16 — question placement (for approval)

**MainLevel:** not yet in `game-flow.json` → **Part 4** grammar

**Vocabulary:** Group 16 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | take away, tap, cough, disconnect, dust, fetch, find out, fold, iron |
| WordPairs (4) | anywhere, apart, everywhere, nearby |
| Other (6) | briefly, forever, largely, necessarily, purely, straight |

**Rules applied**
- WordPairs words **only** in Q2.
- **ClozeSequence:** exactly **2** words; **≥1 verb**.
- **Other templates:** **1–2** words each.
- Words may be taught in context without being the blank answer.
- No `translations.json` yet.

---

## Proposed questions

### Q1 — AppearDisappear · **fetch**
`Please fetch the clean towels from the shelf.`

### Q2 — WordPairs · **anywhere, apart, everywhere, nearby**
Match the four adj/adv (translations deferred).

### Q3 — ConvoTemplate-1 · **find out**
| Line 1 | `Did you _____ the answer yet?` |
| Line 2 | `Yes, I have _____ it online.` |
| Answer | `found out` |

### Q4 — AppearDisappear · **iron**
`She irons shirts straight on Sundays.`

### Q5 — ConvoTemplate-1 · **fold**
| Line 1 | `Can you _____ these shirts?` |
| Line 2 | `Yes, I can _____ them neatly.` |
| Answer | `fold` |

### Q6 — ClozeSequence · **cough**, **briefly** (2 · 1 verb)
`If you _____ , rest _____ and drink water.`  
**Answers:** `cough` · `briefly`

### Q7 — SentenceBuilder · **largely**, **purely**
`The team largely agrees purely on safety rules.`

### Q8 — AppearDisappear · **tap**
`Tap the screen to continue.`

### Q9 — ClozeSequence · **take away**, **necessarily** (2 · 1 verb)
`Please _____ the plates and _____ wash them.`  
**Answers:** `take away` · `necessarily`

### Q10 — ClozeSequence · **disconnect**, **forever** (2 · 1 verb)
`You can _____ the cable, but do not lose it _____ .`  
**Answers:** `disconnect` · `forever`

### Q11 — GrammarForm · **dust**, **straight** (Part 4 · Present Perfect)
| Sentence | `She has _____ the shelves straight since morning.` |
| Answer | `dusted` |
| Distractors | `dust` · `dusting` · `dusts` |
| Teaches | `straight` in context (also Q4) |

### Q12 — DialogueCompletion · **fetch**, **briefly** (review)
| Line 1 | `Can you fetch the first-aid kit?` |
| Answer | `Yes, I will check the box briefly upstairs.` |

---

## Word coverage

| Word | Question | How taught |
|------|----------|------------|
| fetch | Q1, Q12 | sentence / dialogue |
| find out | Q3 | blank → `found out` |
| iron | Q4 | sentence |
| fold | Q5 | blank |
| cough | Q6 | blank |
| briefly | Q6, Q12 | blank / reply |
| largely | Q7 | sentence |
| purely | Q7 | sentence |
| tap | Q8 | sentence |
| take away | Q9 | blank |
| necessarily | Q9 | blank |
| disconnect | Q10 | blank |
| forever | Q10 | blank |
| dust | Q11 | blank → `dusted` |
| straight | Q4, Q11 | sentence / context |

**WordPairs:** anywhere, apart, everywhere, nearby → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs | ✓ |
| All 6 other | ✓ |
| Cloze = 2 words each | ✓ |
| WordPairs isolated | ✓ |
