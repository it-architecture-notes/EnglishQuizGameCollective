# At the Office: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (post-patch: full-project PNG search, not limited to a single related-theme folder).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 340 entries from the flow levels before `at-the-office` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, exact-stem matching (e.g. `desk` → `at-the-library/desk.png`, `pen`/`notebook` → `school-items-1/`, `stapler`/`whiteboard` → `school-items-2/`)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

**Homonym/different-sense caution:** two exact PNG matches are for a *different meaning* of the word than intended here — `mouse` matched `wild-animals-2/mouse.png` (the animal, not a computer mouse), and `train` (verb, "to train an employee") matched `vehicles/train.png` (the vehicle). Both are listed as USED per the literal word-match rule, but neither PNG would actually teach the intended office-context meaning — flagged below rather than silently included.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **colleague** (A2) — Core office-role noun, currently absent
- **boss** (A1) — Core office-role noun, pairs with tracked `manager`
- **employee** (A2) — Core office-role noun
- **email** (A1) — Extremely common modern office noun, currently absent as a noun (only tangentially implied)
- **document** (A1) — Core paperwork noun, ties to tracked `file`/`report`
- **deadline** (A2) — Core office-pressure concept
- **project** (A1) — Core work-unit noun
- **schedule** (A2) — Ties to the already-tracked "meeting for Friday" theme
- **laptop** (A1) — Modern equivalent of tracked `computer`
- **password** (A2) — Essential modern office/login concept

### Verbs
- **email** (A1) — Core modern communication verb
- **call** (A1) — Common office communication verb
- **meet** (A1) — Ties directly to the already-tracked `meeting` noun
- **schedule** (A2) — Ties to the already-present "plan the meeting" theme
- **present** (A2) — Ties directly to the already-tracked `presentation`
- **discuss** (A2) — Common meeting-context verb
- **review** (A2) — Ties to the already-present "report is ready" theme
- **hire** (A2) — Core office-management concept
- **fire** (A2) — Natural antonym of `hire` (note: PNG match for this word is the unrelated fire-extinguisher/train sense, so no real image exists for this meaning)
- **arrive** (A1) — Common workplace-routine verb
- **leave** (A1) — Pairs with `arrive`

### Adjectives
- **busy** (A1) — Fits the "away on business" theme already present
- **professional** (A2) — Core office-register adjective
- **organized** (A2) — Core office-quality adjective
- **productive** (A2) — Core office-quality adjective
- **efficient** (A2) — Pairs with `productive`
- **confidential** (B1) — Ties to office document/password themes

### Adverbs
- **efficiently** (A2) — Matches the `efficient` adjective above
- **professionally** (A2) — Matches `professional`
- **promptly** (A2) — Fits deadline/meeting-punctuality theme
- **carefully** (A1) — General office-diligence adverb

---

## UNUSED + RECOMMENDED

### Nouns
- printer, folder, calendar, coffee, break room, conference room, cubicle, screen, memo, spreadsheet, contract, teamwork, salary, promotion, task, agenda, badge, lobby, headset, network, appointment, supervisor, intern

### Verbs
- type, organize, print, submit, manage, supervise, assist, collaborate, negotiate, delegate, brainstorm, log in, log out, update, prepare, respond

### Adjectives
- formal, casual, noisy, stressful, collaborative, corporate, remote, flexible, punctual, reliable, responsible, digital, scheduled, overdue, completed, pending

### Adverbs
- calmly, patiently, formally, digitally, remotely, punctually, responsibly, collaboratively, diligently, immediately, thoroughly, accurately

---

## USED + HIGH PRIORITY

### Nouns
- **desk** — source: PNG (`at-the-library/desk.png`)
- **computer** — source: PNG (`at-the-office/computer.png`) + `questions.json`
- **chair** — source: PNG (`living-room/chair.png`)
- **meeting** — source: PNG (`at-the-office/meeting.png`) + `translations.json` + `questions.json`
- **manager** — source: `questions.json` (Q13 "connect you to the manager")
- **phone** — source: `questions.json` (Q10 distractor)
- **file** — source: PNG (`at-the-office/file.png`) + `questions.json`
- **report** — source: `questions.json` (Q11/Q12)
- **keyboard** — source: `questions.json` (Q10 distractor)
- **presentation** — source: `questions.json` (Q2 AppearDisappear)
- **client** — source: `questions.json` (Q2, Q11)

### Verbs
- **work** — source: `translations.json` + `questions.json` (Q2)
- **plan** — source: `translations.json` + `questions.json` (Q3)
- **file** — source: PNG + `questions.json`
- **complete** — source: prior-words
- **finish** — source: `translations.json` + `questions.json` (Q12 answer)
- **start** — source: prior-words
- **report** — source: `questions.json`
- **attend** — source: `translations.json` (`to attend a meeting`) + `questions.json` (Q9 SentenceBuilder)

### Adjectives
- **important** — source: prior-words
- **urgent** — source: prior-words + `questions.json` (Q2 distractor)

### Adverbs
- **quickly** — source: prior-words + `questions.json` (Q11/Q13/Q14 distractors)

---

## USED + RECOMMENDED

### Nouns
- **mouse** — PNG (`wild-animals-2/mouse.png`) — ⚠️ different sense (animal, not computer mouse)
- **notebook** — PNG (`school-items-1/notebook.png`)
- **pen** — PNG (`school-items-1/pen.png`)
- **whiteboard** — PNG (`school-items-2/whiteboard.png`)
- **stapler** — PNG (`school-items-2/stapler.png`)
- **elevator** — PNG (`at-the-hotel/elevator.png`)

### Verbs
- **sign** — prior-words
- **approve** — prior-words
- **deny** — prior-words
- **train** — PNG (`vehicles/train.png`) — ⚠️ different sense (the vehicle, not "to train an employee")
- **answer** — prior-words + `questions.json`

### Adjectives
- **quiet** — prior-words

### Adverbs
- **regularly** — prior-words

---

## SUMMARY

- **Total words analyzed:** 133 (50 nouns, 40 verbs, 25 adjectives, 18 adverbs)
- **Unused:** 98 (74%) — 31 High Priority (32%) / 67 Recommended (68%)
- **Used:** 35 (26%) — 22 High Priority (63%) / 13 Recommended (37%)

**Source breakdown for USED words:** `translations.json` (6 words), `questions.json` (17 words, several overlapping), PNG project-wide (11 words, 2 of which are different-sense homonyms), prior-words-by-type.md equivalent (10 words).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | colleague / boss / employee | noun | Core office-role nouns, all completely absent |
| 2 | email | noun/verb | Extremely common modern office concept, currently untaught |
| 3 | deadline | noun | Core office-pressure concept |
| 4 | meet / schedule | verb | Directly tie to the already-tracked `meeting`/"plan the meeting" |
| 5 | present / review | verb | Directly tie to the already-tracked `presentation`/"report is ready" |
| 6 | professional / organized / efficient | adjective | Core office-register adjectives, currently untaught |
| 7 | laptop / password | noun | Modern essentials, currently absent |
| 8 | hire / fire | verb | Natural antonym pair, core office-management concept |
