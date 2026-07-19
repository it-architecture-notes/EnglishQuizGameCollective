# common-words-17 — question placement (for approval)

**MainLevel:** not yet in `game-flow.json` → **Part 4** grammar

**Vocabulary:** Group 17 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | unpack, text, bore, bring back, excite, fade, grate, grill, knock |
| WordPairs (4) | anyway, worse, worst, secret |
| Other (6) | accurately, unlike, equally, somewhere, successfully, tightly |

**Rules applied**
- WordPairs words **only** in Q2.
- **ClozeSequence:** exactly **2** words; **≥1 verb**.
- **Other templates:** **1–2** words each.
- Words may be taught in context without being the blank answer.
- No `translations.json` yet.

---

## Proposed questions

### Q1 — AppearDisappear · **excite**
`Good news can excite the whole team.`

### Q2 — WordPairs · **anyway, worse, worst, secret**
Match the four adj/adv (translations deferred).

### Q3 — ConvoTemplate-1 · **bring back**
| Line 1 | `Can you _____ my book?` |
| Line 2 | `Yes, I will _____ it tomorrow.` |
| Answer | `bring back` |

### Q4 — AppearDisappear · **grill**
`We grill vegetables on summer evenings.`

### Q5 — ConvoTemplate-1 · **knock**
| Line 1 | `Did someone _____ on the door?` |
| Line 2 | `Yes, a friend did _____ twice.` |
| Answer | `knock` |

### Q6 — ClozeSequence · **fade**, **accurately** (2 · 1 verb)
`Bright colors can _____ when labels are not printed _____ .`  
**Answers:** `fade` · `accurately`

### Q7 — SentenceBuilder · **equally**, **somewhere**
`Store tools equally somewhere safe indoors.`

### Q8 — AppearDisappear · **unpack**
`Please unpack the box on the table.`

### Q9 — ClozeSequence · **bore**, **tightly** (2 · 1 verb)
`Long talks can _____ listeners who sit _____ .`  
**Answers:** `bore` · `tightly`

### Q10 — ClozeSequence · **grate**, **successfully** (2 · 1 verb)
`Chefs _____ cheese and _____ serve the dish.`  
**Answers:** `grate` · `successfully`

### Q11 — GrammarForm · **text**, **unlike** (Part 4 · reported speech)
| Sentence | `He said that he would _____ me later, unlike his brother.` |
| Answer | `text` |
| Distractors | `texts` · `texted` · `texting` |
| Teaches | `unlike` in context |

### Q12 — DialogueCompletion · **unpack**, **accurately** (review)
| Line 1 | `Did you unpack the delivery?` |
| Answer | `Yes, and I labeled each item accurately.` |

---

## Word coverage

| Word | Question | How taught |
|------|----------|------------|
| excite | Q1 | sentence |
| bring back | Q3 | blank |
| grill | Q4 | sentence |
| knock | Q5 | blank |
| fade | Q6 | blank |
| accurately | Q6, Q12 | blank / reply |
| equally | Q7 | sentence |
| somewhere | Q7 | sentence |
| unpack | Q8, Q12 | sentence / dialogue |
| bore | Q9 | blank |
| tightly | Q9 | blank |
| grate | Q10 | blank |
| successfully | Q10 | blank |
| text | Q11 | blank |
| unlike | Q11 | context |

**WordPairs:** anyway, worse, worst, secret → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs | ✓ |
| All 6 other | ✓ |
| Cloze = 2 words each | ✓ |
| WordPairs isolated | ✓ |
