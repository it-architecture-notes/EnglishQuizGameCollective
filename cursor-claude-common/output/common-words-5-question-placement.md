# common-words-5 — question placement (for approval)

**MainLevel:** 6 → **Part 3** grammar (Parts 1–2 review allowed)  
(Past Simple **was**/**were**, regular **-ed**, common irregulars, **Did** questions; **should**; **have to** / **need to**; **could** / **might** — no present perfect)

**Vocabulary:** Group 5 from `dist-optimized-19.txt`

| Pool | Words |
|------|-------|
| Verbs (9) | log out, sign out, sign up, log in, consider, allow, back, design, expect |
| WordPairs (4) | funny, worried, afraid, friendly |
| Other (6) | due, regarding, throughout, via, assistant, classical |

**Rules applied**
- WordPairs words **only** in Q2.
- **ClozeSequence:** exactly **2** words; **≥1 verb**.
- **Other templates:** **1–2** words each.
- Words may be taught in context without being the blank answer.
- No `translations.json` yet.

**Template order:** standard 12-question common-words layout

---

## Proposed questions

### Q1 — AppearDisappear · **expect**
`I expect a reply before the due date.`

### Q2 — WordPairs · **funny, worried, afraid, friendly**
Match the four adj/adv (translations deferred).

### Q3 — ConvoTemplate-1 · **sign up**
| Line 1 | `Did you _____ for the class yet?` |
| Line 2 | `Yes, I _____ online yesterday.` |
| Answer | `sign up` |

### Q4 — AppearDisappear · **log in**
`She logged in before breakfast.`

### Q5 — ConvoTemplate-1 · **consider**
| Line 1 | `Did you _____ my idea?` |
| Line 2 | `Yes, I _____ it carefully.` |
| Answer | `consider` |

### Q6 — ClozeSequence · **log out**, **due** (2 · 1 verb)
`Please _____ now; the report is _____ tomorrow.`  
**Answers:** `log out` · `due`

### Q7 — SentenceBuilder · **classical**, **via**
`Classical music traveled via river boats.`

### Q8 — AppearDisappear · **back**, **assistant**
`The assistant stepped back from the desk.`

### Q9 — ClozeSequence · **sign out**, **throughout** (2 · 1 verb)
`We _____ when rain fell _____ the afternoon.`  
**Answers:** `sign out` · `throughout`

### Q10 — ClozeSequence · **allow**, **regarding** (2 · 1 verb)
`The teacher did not _____ questions regarding homework.`  
**Answers:** `allow` · `regarding`

### Q11 — GrammarForm · **design**, **classical** (Part 3 · Past Simple)
| Sentence | `She _____ a classical poster for the club last week.` |
| Answer | `designed` |
| Distractors | `designs` · `designing` · `will design` |
| Teaches | `classical` in context; `design` → `designed` |

### Q12 — DialogueCompletion · **due**, **regarding** (review)
| Line 1 | `Is the homework due today?` |
| Answer | `Yes, the teacher sent a note regarding the date.` |

---

## Word coverage

| Word | Question | How taught |
|------|----------|------------|
| expect | Q1 | sentence |
| sign up | Q3 | blank |
| log in | Q4 | sentence |
| consider | Q5 | blank |
| log out | Q6 | blank |
| due | Q6, Q12 | blank / dialogue |
| afraid | Q2 | WordPairs only |
| via | Q7 | sentence |
| classical | Q7 | sentence |
| back | Q8 | sentence |
| assistant | Q8 | sentence |
| sign out | Q9 | blank |
| throughout | Q9 | blank |
| allow | Q10 | blank |
| regarding | Q10, Q12 | blank / reply |
| design | Q11 | blank → `designed` |

**WordPairs:** funny, worried, afraid, friendly → Q2 only

| Check | Status |
|-------|--------|
| All 9 verbs | ✓ |
| All 6 other | ✓ |
| Cloze = 2 words each | ✓ |
| GrammarForm = Part 3 | ✓ |
