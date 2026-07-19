# common-words-12 — question placement (for approval)

**MainLevel:** not yet in `game-flow.json` (planned after `common-words-11` at ML12) → **Part 4** grammar  
(Present Perfect; Past Continuous; passive; second conditional; reported speech)

**Vocabulary:** Group 12 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | pronounce, attack, depend, organize, refer, reply, rise, shock, shut |
| WordPairs (4) | regular, creative, specific, attractive |
| Other (6) | constantly, deeply, relatively, equal, essential, responsible |

**Rules applied**
- WordPairs words **only** in Q2.
- **ClozeSequence:** exactly **2** words; **≥1 verb**.
- **Other templates:** **1–2** words each.
- Words may be taught in context without being the blank answer.
- No `translations.json` yet.

---

## Proposed questions

### Q1 — AppearDisappear · **reply**
`She replied to the message quickly.`

### Q2 — WordPairs · **regular, creative, specific, attractive**
Match the four adj/adv (translations deferred).

### Q3 — ConvoTemplate-1 · **pronounce**
| Line 1 | `Can you _____ this word clearly?` |
| Line 2 | `Yes, I can _____ it slowly.` |
| Answer | `pronounce` |

### Q4 — AppearDisappear · **organize**
`We organized the files before lunch.`

### Q5 — ConvoTemplate-1 · **depend**
| Line 1 | `Does the plan _____ on weather?` |
| Line 2 | `Yes, it will _____ on rain.` |
| Answer | `depend` |

### Q6 — ClozeSequence · **refer**, **essential** (2 · 1 verb)
`Please _____ to the _____ rules.`  
**Answers:** `refer` · `essential`

### Q7 — SentenceBuilder · **equal**, **responsible**
`Equal teams are responsible for cleanup.`

### Q8 — AppearDisappear · **shut**, **constantly**
`Please shut the door that constantly rattles.`

### Q9 — ClozeSequence · **attack**, **deeply** (2 · 1 verb)
`The critics did not _____ the idea _____ .`  
**Answers:** `attack` · `deeply`

### Q10 — ClozeSequence · **rise**, **relatively** (2 · 1 verb)
`Prices have _____ _____ fast this year.`  
**Answers:** `risen` · `relatively`

### Q11 — GrammarForm · **shock**, **essential** (Part 4 · reported speech)
| Sentence | `She said that the news would _____ her essential routine.` |
| Answer | `shock` |
| Distractors | `shocked` · `shocking` · `shocks` |
| Teaches | `essential` in context; `shock` in reported clause |

### Q12 — DialogueCompletion · **refer**, **essential** (review)
| Line 1 | `Did you refer to the guide?` |
| Answer | `Yes, it lists essential steps clearly.` |

---

## Word coverage

| Word | Question | How taught |
|------|----------|------------|
| reply | Q1 | sentence |
| pronounce | Q3 | blank |
| organize | Q4 | sentence |
| depend | Q5 | blank |
| refer | Q6, Q12 | blank / dialogue |
| essential | Q6, Q12 | blank / reply |
| equal | Q7 | sentence |
| responsible | Q7 | sentence |
| shut | Q8 | sentence |
| constantly | Q8 | sentence |
| attack | Q9 | blank |
| deeply | Q9 | blank |
| rise | Q10 | blank → `risen` |
| relatively | Q10 | blank |
| shock | Q11 | blank |
| essential | Q6, Q11, Q12 | blank / context / reply |

**WordPairs:** regular, creative, specific, attractive → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs | ✓ |
| All 6 other | ✓ |
| Cloze = 2 words each | ✓ |
| GrammarForm = Part 4 | ✓ |

**Note:** `common-words-12` is not yet listed in `game-flow.json`; add when the level is wired into the flow.
