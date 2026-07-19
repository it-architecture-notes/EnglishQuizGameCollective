# common-words-4 — question placement (for approval)

**MainLevel:** 5 → **Part 2** grammar (Part 1 review also allowed)  
(`will` / **be going to**; **must**; comparatives / superlatives; **first conditional** — no past / present perfect)

**Vocabulary:** Group 4 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | come out, get out, go down, go up, sit down, agree, die, shut down, win |
| WordPairs (4) | tall, kind, quick, rich |
| Other (6) | weekly, yearly, ancient, jealous, male, worthless |

**Rules applied**
- WordPairs words **only** in Q2.
- Questions Q1, Q3–Q12 use the **9 verbs + 6 other** words.
- **ClozeSequence:** exactly **2** target words; **at least one verb**.
- **Other templates:** **1–2** target words each.
- A word counts as **taught** in question text — not only as a blank answer.
- No `translations.json` yet.

**Template order:** AppearDisappear → WordPairs → Convo → AppearDisappear → Convo → Cloze → SentenceBuilder → AppearDisappear → Cloze → Cloze → GrammarForm → DialogueCompletion

---

## Proposed questions

### Q1 — AppearDisappear · **win**
`Our team can win the game today.`

### Q2 — WordPairs · **tall, kind, quick, rich**
Match the four adj/adv (translations deferred).

### Q3 — ConvoTemplate-1 · **get out**
| Line 1 | `Can you _____ of the car now?` |
| Line 2 | `Yes, I will _____ right away.` |
| Answer | `get out` |

### Q4 — AppearDisappear · **go up**
`Ticket prices go up every year.`

### Q5 — ConvoTemplate-1 · **come out**
| Line 1 | `Can you _____ of your room?` |
| Line 2 | `Yes, I will _____ in a minute.` |
| Answer | `come out` |

### Q6 — ClozeSequence · **agree**, **yearly** (2 · 1 verb)
`They _____ to meet _____ for the school trip.`  
**Answers:** `agree` · `yearly`

### Q7 — SentenceBuilder · **jealous**, **ancient**
`Jealous rivals fought in ancient stories.`

### Q8 — AppearDisappear · **male**, **sit down**
`Male students sit down first in class.`

### Q9 — ClozeSequence · **go down**, **shut down** (2 · 2 verbs)
`The sun _____ and we _____ the laptop.`  
**Answers:** `go down` · `shut down`

### Q10 — ClozeSequence · **die**, **worthless** (2 · 1 verb)
`Heroes often _____ when plans seem _____ .`  
**Answers:** `die` · `worthless`

### Q11 — GrammarForm · **win**, **weekly** (Part 2 · first conditional)
| Sentence | `If we practice weekly, we will _____ the next game.` |
| Answer | `win` |
| Distractors | `wins` · `won` · `winning` |
| Teaches | `weekly` in context; `win` in blank |

### Q12 — DialogueCompletion · **agree**, **yearly** (review)
| Line 1 | `Do we all agree on the plan?` |
| Answer | `Yes, we meet yearly to review it.` |

---

## Word coverage

| Word | Question | How taught |
|------|----------|------------|
| win | Q1, Q11 | sentence / blank |
| get out | Q3 | blank |
| go up | Q4 | sentence |
| come out | Q5 | blank |
| agree | Q6, Q12 | blank / dialogue |
| yearly | Q6, Q12 | blank / reply |
| jealous | Q7 | sentence |
| ancient | Q7 | sentence |
| male | Q8 | sentence |
| sit down | Q8 | sentence |
| go down | Q9 | blank |
| shut down | Q9 | blank |
| die | Q10 | blank |
| worthless | Q10 | blank |
| weekly | Q11 | context |

**WordPairs:** tall, kind, quick, rich → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs | ✓ |
| All 6 other | ✓ |
| Cloze = 2 words each | ✓ |
| GrammarForm = Part 2 | ✓ |
