# At the Pharmacy: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder), using the corrected prior-words matching (word-boundary against full phrases).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 539 entries from the flow levels before `at-the-pharmacy` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `at-the-pharmacy` (own images), `jobs-1` (pharmacist), `hospital-pharmacy-items` (ointment, thermometer)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

**Note:** the `going-to-sports` level's content has changed on disk since it was audited earlier in this session (now includes `team`, `coach`, `compete`, `strong`, `swimming-pool` image) — the prior-words gather script correctly picked up this current state, so `strong` is counted as already-taught via `going-to-sports` below.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **prescription** (A2) — Core theme-defining noun, currently absent
- **pill** (A1) — Extremely common medicine noun, currently absent (only `syrup`/`ointment`/`bandage` are taught)
- **tablet** (A2) — Pairs with `pill`
- **dose** (A2) — Ties to the already-present "should I shake the syrup" instructions theme
- **bottle** (A1) — Common pharmacy-item noun
- **symptom** (A2) — Core theme-defining noun, ties to the already-present "my cold was bad" line
- **illness** (A1) — Pairs with `symptom`
- **vitamin** (A1) — Common pharmacy-shelf noun
- **painkiller** (A2) — Ties to the already-present "pain reliever" line in Q5
- **instructions** (A1) — Ties directly to the already-tracked "read the label" theme

### Verbs
- **prescribe** (A2) — Core theme-defining verb, ties to `prescription`
- **explain** (A2) — Ties to the already-present pharmacist-advice dialogue
- **treat** (A2) — Core pharmacy-theme verb
- **warn** (A2) — Ties to the already-present "is it safe for children" caution theme
- **swallow** (A2) — Common medicine-taking verb, ties to `syrup`/`pill`

### Adjectives
- **sick** (A1) — Extremely common, ties to the already-tracked "my cold was bad"
- **effective** (A2) — Common medicine-quality descriptor
- **mild** (A2) — Common symptom/medicine-strength descriptor
- **allergic** (A2) — Ties to the already-present "is it safe for children" caution theme
- **careful** (A1) — Ties to the safety-instructions theme

### Adverbs
- **carefully** (A1) — Matches the `careful` adjective above
- **safely** (A1) — Matches the already-tracked `safe`
- **immediately** (A1) — Common in medical-instruction contexts
- **daily** (A1) — Common dosage-instruction adverb

---

## UNUSED + RECOMMENDED

### Nouns
- medication, capsule, dosage, counter, insurance, refill, allergy, mask, cash register, shelf, drugstore, cough drop, antibiotic, side effect, waiting area, health card

### Verbs
- refill, consult, drop off, advise, cure, relieve, measure, store, expire

### Adjectives
- prescribed, over-the-counter, dizzy, nauseous, confidential, out-of-stock, generic, branded

### Adverbs
- thoroughly, confidentially, exactly

---

## USED + HIGH PRIORITY

### Nouns
- **pharmacist** — PNG (`jobs-1/pharmacist.png`) + `questions.json` (Q9 AppearDisappear)
- **medicine** — `questions.json` (Q2 "this medicine will kill the germs")
- **syrup** — `questions.json` (Q4, Q14)
- **label** — `questions.json` (Q8 distractor "don't read the label")
- **doctor** — `questions.json` (Q9 distractor)
- **ointment** — PNG (`hospital-pharmacy-items/ointment.png`) + `questions.json` (Q12 distractor)
- **bandage** — `questions.json` (`adhesive-bandage`, `elastic-bandage` images)
- **thermometer** — PNG (`hospital-pharmacy-items/thermometer.png`)

### Verbs
- **fill** — prior-words (`fill in a form`, `at-the-bank`)
- **take** — prior-words (`to take a shower`, `in-the-bathroom`) + `questions.json` (Q14 "if I also take this syrup")
- **read** — prior-words (`to read`, `at-the-school`) + `questions.json` (Q8 distractor)
- **apply** — prior-words (`to apply for a loan`, `at-the-bank`)

### Adjectives
- **safe** — `translations.json` + `questions.json` (Q8 "Is it safe for children?")
- **dangerous** — prior-words (`dangerous`, `at-the-traffic`)

### Adverbs
- **correctly** — prior-words (`correctly`, `at-garage-gas-station`)

---

## USED + RECOMMENDED

### Nouns
- **customer** — prior-words (`customer`, `at-the-farmers-market`)
- **receipt** — prior-words (`receipt`, `grocery-shopping`)
- **aisle** — `questions.json` (Q5 "It is on aisle three")

### Verbs
- **buy** — prior-words (`to buy`, `grocery-shopping`)
- **sell** — prior-words (`to sell`, `at-the-farmers-market`) + `questions.json` (Q4 distractor)
- **ask** — prior-words (`to ask a question`, `at-the-school`) + `questions.json` (Q5 "Can you tell me")
- **recommend** — prior-words (`to recommend`, `at-the-cinema`)
- **pay** — prior-words (`to pay`, `grocery-shopping`)
- **pick up** — prior-words (`to pick up`, `at-the-post-office`)
- **check** — prior-words (`to check in`, `at-the-hotel`)

### Adjectives
- **healthy** — PNG (`emotions-2/healthy.png`)
- **expired** — prior-words (`expired`, `at-the-library`)
- **strong** — prior-words (`strong`, `going-to-sports`)
- **available** — prior-words (`available`, `at-the-library`)

### Adverbs
- **regularly** — prior-words (`regularly`, `in-the-bathroom`)
- **properly** — prior-words (`properly`, `at-the-restaurant`)
- **twice** — prior-words (`twice a week`, `at-the-park`)
- **gently** — prior-words (`gently`, `baby-care`)
- **quickly** — prior-words (`quickly`, `waking-up`)
- **patiently** — prior-words (`patiently`, `at-the-train-station`)

---

## SUMMARY

- **Total words analyzed:** 95 (37 nouns, 25 verbs, 19 adjectives, 14 adverbs)
- **Unused:** 60 (63%) — 24 High Priority (40%) / 36 Recommended (60%)
- **Used:** 35 (37%) — 15 High Priority (43%) / 20 Recommended (57%)

**Source breakdown for USED words:** `translations.json` (1 word), `questions.json` (~14 words, several overlapping), PNG project-wide (4 words, spanning `at-the-pharmacy`, `jobs-1`, `hospital-pharmacy-items`, `emotions-2`), prior-words-by-type.md equivalent (~17 words, using corrected phrase-matching).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | prescription | noun | Core theme-defining word for a pharmacy level, currently absent |
| 2 | pill / tablet | noun | Extremely common medicine nouns, both absent (only syrup/ointment/bandage taught) |
| 3 | symptom / illness | noun | Core theme nouns, tie to the already-present "my cold was bad" |
| 4 | prescribe | verb | Verb form of the already-suggested `prescription` |
| 5 | painkiller | noun | Ties directly to the already-present "pain reliever" line |
| 6 | sick | adjective | Extremely common, ties to the already-tracked "my cold was bad" |
| 7 | allergic | adjective | Ties directly to the already-present "is it safe for children" caution theme |
| 8 | instructions | noun | Ties directly to the already-tracked "read the label" theme |
