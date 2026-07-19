# common-words-18 — question placement (for approval)

**MainLevel:** not yet in `game-flow.json` → **Part 4** grammar

**Vocabulary:** Group 18 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | claim, yell, zoom, roast, sneeze, experience, express, face, require |
| WordPairs (4) | necessary, almost, already, also |
| Other (6) | alongside, amid, beneath, besides, concerning, prior |

**Rules applied**
- WordPairs words **only** in Q2.
- **ClozeSequence:** exactly **2** words; **≥1 verb**.
- **Other templates:** **1–2** words each.
- Words may be taught in context without being the blank answer.
- No `translations.json` yet.

---

## Proposed questions

### Q1 — AppearDisappear · **experience**
`Many students experience stress before exams.`

### Q2 — WordPairs · **necessary, almost, already, also**
Match the four adj/adv (translations deferred).

### Q3 — ConvoTemplate-1 · **express**
| Line 1 | `Can you _____ your ideas clearly?` |
| Line 2 | `Yes, I can _____ them well.` |
| Answer | `express` |

### Q4 — AppearDisappear · **face**
`We must face difficult problems together.`

### Q5 — ConvoTemplate-1 · **require**
| Line 1 | `Does this job _____ travel?` |
| Line 2 | `Yes, it will _____ long trips.` |
| Answer | `require` |

### Q6 — ClozeSequence · **claim**, **alongside** (2 · 1 verb)
`Witnesses _____ the facts recorded _____ the report.`  
**Answers:** `claim` · `alongside`

### Q7 — SentenceBuilder · **concerning**, **prior**
`Notes concerning prior meetings are on the desk.`

### Q8 — AppearDisappear · **sneeze**
`Dust can make people sneeze indoors.`

### Q9 — ClozeSequence · **yell**, **beneath** (2 · 1 verb)
`Do not _____ ; look _____ the bench for keys.`  
**Answers:** `yell` · `beneath`

### Q10 — ClozeSequence · **roast**, **amid** (2 · 1 verb)
`Chefs _____ vegetables _____ the busy kitchen.`  
**Answers:** `roast` · `amid`

### Q11 — GrammarForm · **zoom**, **besides** (Part 4 · Present Perfect)
| Sentence | `The class has _____ through three units besides the review packet.` |
| Answer | `zoomed` |
| Distractors | `zoom` · `zooming` · `zooms` |
| Teaches | `besides` in context |

### Q12 — DialogueCompletion · **claim**, **concerning** (review)
| Line 1 | `What do witnesses claim concerning the case?` |
| Answer | `They claim the facts listed alongside the report.` |

---

## Word coverage

| Word | Question | How taught |
|------|----------|------------|
| experience | Q1 | sentence |
| express | Q3 | blank |
| face | Q4 | sentence |
| require | Q5 | blank |
| claim | Q6, Q12 | blank / dialogue |
| alongside | Q6, Q12 | blank / reply |
| concerning | Q7, Q12 | sentence / dialogue |
| prior | Q7 | sentence |
| sneeze | Q8 | sentence |
| yell | Q9 | blank |
| beneath | Q9 | blank |
| roast | Q10 | blank |
| amid | Q10 | blank |
| zoom | Q11 | blank → `zoomed` |
| besides | Q11 | context |

**WordPairs:** necessary, almost, already, also → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs | ✓ |
| All 6 other | ✓ |
| Cloze = 2 words each | ✓ |
| WordPairs isolated | ✓ |
