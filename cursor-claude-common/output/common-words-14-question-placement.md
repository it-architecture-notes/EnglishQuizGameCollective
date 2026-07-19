# common-words-14 — question placement (for approval)

**MainLevel:** not yet in `game-flow.json` → **Part 4** grammar

**Vocabulary:** Group 14 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | sink, slide, spill, steal, head, link, peel, mark, polish |
| WordPairs (4) | crazy, excellent, strange, traditional |
| Other (6) | potentially, roughly, ultimately, widely, glad, illegal |

**Rules applied**
- WordPairs words **only** in Q2.
- **ClozeSequence:** exactly **2** words; **≥1 verb**.
- **Other templates:** **1–2** words each.
- Words may be taught in context without being the blank answer.
- No `translations.json` yet.

---

## Proposed questions

### Q1 — AppearDisappear · **polish**
`She has polished the wooden table carefully.`

### Q2 — WordPairs · **crazy, excellent, strange, traditional**
Match the four adj/adv (translations deferred).

### Q3 — ConvoTemplate-1 · **steal**
| Line 1 | `Did someone _____ your bike?` |
| Line 2 | `Yes, they did _____ it last night.` |
| Answer | `steal` |

### Q4 — AppearDisappear · **mark**
`Please mark the correct answers clearly.`

### Q5 — ConvoTemplate-1 · **link**
| Line 1 | `Can you _____ these two files?` |
| Line 2 | `Yes, I can _____ them now.` |
| Answer | `link` |

### Q6 — ClozeSequence · **sink**, **potentially** (2 · 1 verb)
`Heavy boxes can _____ and _____ damage the floor.`  
**Answers:** `sink` · `potentially`

### Q7 — SentenceBuilder · **glad**, **widely**
`Glad readers widely share the news.`

### Q8 — AppearDisappear · **spill**
`Be careful not to spill water on the papers.`

### Q9 — ClozeSequence · **slide**, **roughly** (2 · 1 verb)
`Ice can make cars _____ _____ on hills.`  
**Answers:** `slide` · `roughly`

### Q10 — ClozeSequence · **peel**, **ultimately** (2 · 1 verb)
`You must _____ the fruit and _____ wash it.`  
**Answers:** `peel` · `ultimately`

### Q11 — GrammarForm · **head**, **illegal** (Part 4 · reported speech)
| Sentence | `She said that the truck would _____ north on an illegal road.` |
| Answer | `head` |
| Distractors | `heads` · `headed` · `heading` |
| Teaches | `illegal` in context |

### Q12 — DialogueCompletion · **spill**, **glad** (review)
| Line 1 | `Did you spill the juice?` |
| Answer | `Yes, but I am glad it was only water.` |

---

## Word coverage

| Word | Question | How taught |
|------|----------|------------|
| polish | Q1 | sentence |
| steal | Q3 | blank |
| mark | Q4 | sentence |
| link | Q5 | blank |
| sink | Q6 | blank |
| potentially | Q6 | blank |
| glad | Q7, Q12 | sentence / reply |
| widely | Q7 | sentence |
| spill | Q8, Q12 | sentence / dialogue |
| slide | Q9 | blank |
| roughly | Q9 | blank |
| peel | Q10 | blank |
| ultimately | Q10 | blank |
| head | Q11 | blank |
| illegal | Q11 | context |

**WordPairs:** crazy, excellent, strange, traditional → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs | ✓ |
| All 6 other | ✓ |
| Cloze = 2 words each | ✓ |
| WordPairs isolated | ✓ |
