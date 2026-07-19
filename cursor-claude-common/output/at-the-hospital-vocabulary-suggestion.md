# At the Hospital: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder), using the corrected prior-words matching (word-boundary against full phrases).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 570 entries from the flow levels before `at-the-hospital` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `at-the-hospital` (own images), `jobs-2` (nurse), `city-buildings-2` (hospital), `at-the-hotel` (reception), `waking-up` (bed), `hospital-pharmacy-items` (stretcher, thermometer), `dressing-2` (gloves), `emotions-1`/`emotions-2` (nervous, healthy)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

**Note:** several adjectives (`injured`, `strong`, `serious`) and the noun `prescription`/verb `explain` show up as USED via prior-words from `emergency-situations`/`going-to-sports`/`at-the-pharmacy` — those levels' content changed on disk after being audited earlier in this session, incorporating several of the suggested vocabulary words directly. This is expected and correctly reflected here since the prior-words script reads current on-disk state.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **clinic** (A1) — Common near-synonym of the already-image-taught `hospital`
- **appointment** (A2) — Core theme-defining noun, currently absent
- **medicine** (A1) — Extremely common, ties to the already-tracked `prescription`/`treatment`
- **injection** (A2) — Common hospital-procedure noun
- **x-ray** (A1) — Common hospital-procedure noun
- **symptom** (A2) — Ties to the already-present "does your arm hurt"/examination theme
- **illness** (A1) — Pairs with `symptom`, ties to `disease`
- **disease** (A2) — Pairs with `illness`
- **insurance** (A2) — Common modern hospital-administration noun

### Verbs
- **heal** (A2) — Ties to the already-tracked `recover`/`treat` theme
- **recover** (A2) — Ties to the already-tracked `treatment`/healing theme
- **diagnose** (A2) — Ties to the already-present examination theme
- **prescribe** (A2) — Ties directly to the already-tracked `prescription`
- **admit** (A2) — Core hospital-process verb
- **discharge** (A2) — Natural antonym of `admit`

### Adjectives
- **worried** (A2) — Ties to the already-tracked `nervous`/emotional-state theme
- **critical** (A2) — Ties to the already-tracked `stable`/`serious` theme
- **painful** (A2) — Ties directly to the already-tracked `pain` noun

### Adverbs
- **calmly** (A2) — Matches the already-tracked `calm`
- **safely** (A1) — Matches the already-tracked `safe`

---

## UNUSED + RECOMMENDED

### Nouns
- waiting room, receptionist, surgery, operation, bandage, blood pressure, checkup, recovery, ward, emergency room, chart, mask, stethoscope

### Verbs
- operate, measure, monitor, inject, bandage, comfort, register

### Adjectives
- mild, professional

### Adverbs
- professionally, thoroughly, kindly

---

## USED + HIGH PRIORITY

### Nouns
- **doctor** — `questions.json` (Q6 AppearDisappear)
- **nurse** — PNG (`jobs-2/nurse.png`) + `questions.json` (Q6 distractor)
- **patient** — PNG (`at-the-hospital/patient.png`) + `questions.json`
- **hospital** — PNG (`city-buildings-2/hospital.png`)
- **bed** — prior-words (`to make the bed`, `in-the-bedroom`) + PNG (`waking-up/bed.png`) + `questions.json` (Q6 "rest in bed")
- **wheelchair** — `questions.json` (Q7 distractor)
- **prescription** — prior-words (`prescription`, `at-the-pharmacy`)
- **examination** — `questions.json` (`examination-table` distractor)
- **treatment** — `questions.json` (Q13 DialogueCompletion)

### Verbs
- **examine** — `translations.json` + `questions.json` (Q11 answer)
- **treat** — `translations.json` + `questions.json` (Q10 answer)
- **check** — prior-words (`to check in`, `at-the-hotel`) + `translations.json` + `questions.json` (Q2 answer)
- **care** — `translations.json` + `questions.json` (Q5 ClozeSequence)

### Adjectives
- **sick** — `translations.json` + `questions.json` (Q2 "you look sick")
- **healthy** — PNG (`emotions-2/healthy.png`)
- **injured** — prior-words (`injured`, `emergency-situations`)
- **weak** — `questions.json` (WordPairs)
- **careful** — `translations.json` + `questions.json` (Q5 answer)
- **serious** — prior-words (`serious`, `emergency-situations`)
- **stable** — prior-words (`stable`, `at-the-farm`)

### Adverbs
- **carefully** — `questions.json` (Q11 "examined the patient carefully")

---

## USED + RECOMMENDED

### Nouns
- **reception** — PNG (`at-the-hotel/reception.png`)
- **stretcher** — PNG (`hospital-pharmacy-items/stretcher.png`)
- **thermometer** — PNG (`hospital-pharmacy-items/thermometer.png`)
- **visitor** — `questions.json` (Q9 distractor)
- **form** — prior-words (`fill in a form`, `at-the-bank`)
- **gloves** — PNG (`dressing-2/gloves.png`)

### Verbs
- **ask** — prior-words (`to ask a question`, `at-the-school`)
- **answer** — prior-words (`to answer`, `at-the-school`) + `questions.json` (Q13)
- **wait** — prior-words (`to wait`, `grocery-shopping`) + `questions.json` (Q6 distractor)
- **visit** — `questions.json` (Q13 distractor)
- **rest** — prior-words (`to rest`, `in-the-bedroom`) + `questions.json` (Q6)
- **sleep** — prior-words (`to sleep`, `waking-up`)
- **help** — prior-words (`to help`, `at-the-library`)
- **explain** — prior-words (`to explain`, `at-the-pharmacy`)
- **sign** — prior-words (`to sign`, `at-the-bank`)

### Adjectives
- **strong** — prior-words (`strong`, `going-to-sports`) + `questions.json` (WordPairs)
- **gentle** — prior-words (`gentle`, `baby-care`)
- **calm** — prior-words (`calm`, `nature-walk`)
- **nervous** — PNG (`emotions-1/nervous.png`)
- **urgent** — prior-words (`urgent`, `at-the-post-office`)
- **clean** — prior-words (`to clean`, `in-the-bathroom`)
- **safe** — prior-words (`safe`, `at-the-pharmacy`) + `questions.json`
- **comfortable** — prior-words (`comfortable`, `in-the-bedroom`)

### Adverbs
- **gently** — prior-words (`gently`, `baby-care`)
- **quickly** — prior-words (`quickly`, `waking-up`) + `questions.json`
- **patiently** — prior-words (`patiently`, `at-the-train-station`)
- **immediately** — prior-words (`immediately`, `emergency-situations`)
- **regularly** — prior-words (`regularly`, `in-the-bathroom`)
- **quietly** — prior-words (`quietly`, `in-the-bedroom`)

---

## SUMMARY

- **Total words analyzed:** 95 (37 nouns, 26 verbs, 20 adjectives, 12 adverbs)
- **Unused:** 45 (47%) — 20 High Priority (44%) / 25 Recommended (56%)
- **Used:** 50 (53%) — 21 High Priority (42%) / 29 Recommended (58%)

**Source breakdown for USED words:** `translations.json` (5 words), `questions.json` (~17 words, several overlapping), PNG project-wide (9 words, spanning `at-the-hospital`, `jobs-2`, `city-buildings-2`, `at-the-hotel`, `waking-up`, `hospital-pharmacy-items`, `dressing-2`, `emotions-1`/`emotions-2`), prior-words-by-type.md equivalent (~19 words, using corrected phrase-matching).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | clinic | noun | Common near-synonym of the already-image-taught `hospital` |
| 2 | appointment | noun | Core theme-defining word, currently absent |
| 3 | medicine | noun | Extremely common, ties to the already-tracked `prescription`/`treatment` |
| 4 | heal / recover | verb | Tie directly to the already-tracked `treatment` theme |
| 5 | prescribe | verb | Ties directly to the already-tracked `prescription` |
| 6 | symptom / illness / disease | noun | Core theme nouns, tie to the already-present "does your arm hurt" examination theme |
| 7 | admit / discharge | verb | Core hospital-process antonym pair, currently absent |
| 8 | painful | adjective | Ties directly to the already-tracked `pain` noun |
