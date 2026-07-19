# Emergency Situations: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder), using the corrected prior-words matching (word-boundary against full phrases).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 556 entries from the flow levels before `emergency-situations` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `emergency-situations` (own images), `at-the-hospital` (ambulance, patient), `vehicles` (fire truck), `city-buildings-2` (hospital), `jobs-2` (nurse), `at-garage-gas-station` (fire extinguisher), `checking-the-weather` (storm), `hospital-pharmacy-items` (stretcher), `emotions-1`/`emotions-2` (brave, scared)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **emergency** (A1) — The level's own theme word, never explicitly tracked
- **police car** (A1) — Pairs with the already-image-taught `ambulance`/`fire truck`
- **doctor** (A1) — Common role noun, ties to the already-image-taught `nurse`/`patient`
- **firefighter** (A1) — Common role noun, ties to the already-image-taught `fire truck`/`fire extinguisher`
- **police officer** (A1) — Common role noun, pairs with `police car`
- **danger** (A1) — Noun form of the already-tracked `dangerous`
- **first aid** (A2) — Ties directly to the already-present bandage/injury theme
- **phone** (A1) — Ties directly to the already-tracked `call`/`ambulance` theme
- **safety** (A1) — Ties to the already-present warning/danger theme

### Verbs
- **evacuate** (A2) — Core theme-defining verb, ties to the already-present flood/fire theme
- **hide** (A1) — Common emergency-response verb
- **escape** (A2) — Common emergency-response verb, ties to `evacuate`
- **protect** (A2) — Ties to the already-tracked `rescue`/`save` theme
- **report** (A2) — Ties to the already-present "call the ambulance" theme

### Adjectives
- **unsafe** (A2) — Natural antonym of the already-tracked `safe`
- **hurt** (A1) — Near-synonym reinforcement for the already-tracked `injured`
- **serious** (A2) — Ties to the already-present "terrible injury" theme
- **careful** (A1) — Ties to the safety/danger theme already present
- **prepared** (A2) — Ties to the emergency-readiness theme

### Adverbs
- **immediately** (A1) — Ties to the already-tracked `urgent` theme
- **carefully** (A1) — Matches the `careful` adjective above
- **calmly** (A2) — Matches the already-tracked `calm`
- **safely** (A1) — Matches the already-tracked `safe`

---

## UNUSED + RECOMMENDED

### Nouns
- alarm, victim, bandage, flood, earthquake, shelter, instructions, emergency number

### Verbs
- alert, scream, treat, bandage, respond, assist, guide, comfort

### Adjectives
- immediate, alert, panicked, worried

### Adverbs
- urgently, bravely, promptly, nervously

---

## USED + HIGH PRIORITY

### Nouns
- **ambulance** — PNG (`at-the-hospital/ambulance.png`) + `questions.json` (Q6 "call the ambulance")
- **fire truck** — PNG (`vehicles/fire-truck.png`)
- **hospital** — PNG (`city-buildings-2/hospital.png`) + `questions.json` (Q6 distractor)
- **siren** — PNG (`emergency-situations/siren.png`) + `questions.json`
- **accident** — prior-words (`accident`, `at-the-traffic`)
- **injury** — `questions.json` (Q11, Q13)
- **help** — prior-words (`to help`, `at-the-library`) + `questions.json` (Q9 SentenceBuilder)
- **rescue** — `translations.json` + `questions.json` (Q7 AppearDisappear, Q15)
- **call** — `questions.json` (Q6 "call the ambulance")
- **fire extinguisher** — PNG (`at-garage-gas-station/fire-extinguisher.png`)
- **smoke** — PNG (`emergency-situations/smoke.png`) + `questions.json`
- **warning** — `questions.json` (Q10 distractor)

### Verbs
- **call** — `questions.json`
- **help** — prior-words + `questions.json`
- **rescue** — `translations.json` + `questions.json` (Q15 answer)
- **save** — prior-words (`to save`, `at-the-bank`) + `translations.json` + `questions.json` (Q3 answer)
- **warn** — `translations.json` + `questions.json` (Q2 answer)

### Adjectives
- **urgent** — prior-words (`urgent`, `at-the-post-office`) + `translations.json` + `questions.json` (Q9)
- **dangerous** — prior-words (`dangerous`, `at-the-traffic`)
- **safe** — prior-words (`safe`, `at-the-pharmacy`)
- **scared** — PNG (`emotions-2/scared.png`)
- **injured** — `translations.json` + `questions.json` (Q6, DialogueCompletion)

### Adverbs
- **quickly** — prior-words (`quickly`, `waking-up`)

---

## USED + RECOMMENDED

### Nouns
- **nurse** — PNG (`jobs-2/nurse.png`)
- **patient** — PNG (`at-the-hospital/patient.png`)
- **exit** — prior-words (`to exit`, `at-the-train-station`)
- **storm** — PNG (`checking-the-weather/storm.png`)
- **stretcher** — PNG (`hospital-pharmacy-items/stretcher.png`)

### Verbs
- **run** — prior-words (`to run away`, `at-the-park`)
- **shout** — prior-words (`to shout`, `nature-walk`)
- **stay** — prior-words (`to stay`, `at-the-hotel`)
- **stop** — prior-words (`to stop`, `at-the-traffic`)
- **wait** — prior-words (`to wait`, `grocery-shopping`)
- **carry** — prior-words (`to carry`, `grocery-shopping`)
- **follow** — prior-words (`to follow`, `walking-in-the-city`)
- **arrive** — prior-words (`to arrive`, `at-the-train-station`)

### Adjectives
- **calm** — prior-words (`calm`, `nature-walk`)
- **quick** — prior-words (`quick`, `common-words-1`)
- **ready** — prior-words (`Are you ready?`, `verb-to-be`)
- **brave** — PNG (`emotions-1/brave.png`)

### Adverbs
- **quietly** — prior-words (`quietly`, `in-the-bedroom`)
- **suddenly** — prior-words (`suddenly`, `nature-walk`)
- **together** — prior-words (`together`, `birthday-party`)

---

## SUMMARY

- **Total words analyzed:** 90 (34 nouns, 26 verbs, 18 adjectives, 12 adverbs)
- **Unused:** 47 (52%) — 23 High Priority (49%) / 24 Recommended (51%)
- **Used:** 43 (48%) — 23 High Priority (53%) / 20 Recommended (47%)

**Source breakdown for USED words:** `translations.json` (5 words), `questions.json` (~13 words, several overlapping), PNG project-wide (12 words, spanning `emergency-situations`, `at-the-hospital`, `vehicles`, `city-buildings-2`, `jobs-2`, `at-garage-gas-station`, `checking-the-weather`, `hospital-pharmacy-items`, `emotions-1`/`emotions-2`), prior-words-by-type.md equivalent (~16 words, using corrected phrase-matching).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | emergency | noun | The level's own theme word, never explicitly tracked |
| 2 | doctor / firefighter / police officer | noun | Core emergency-role nouns, all absent (though ambulance/fire truck/nurse are taught) |
| 3 | evacuate / escape | verb | Core emergency-response verbs, currently absent |
| 4 | unsafe | adjective | Natural antonym of the already-tracked `safe` |
| 5 | hurt | adjective | Near-synonym reinforcement for the already-tracked `injured` |
| 6 | first aid | noun | Ties directly to the already-present bandage/injury theme |
| 7 | danger | noun | Noun form of the already-tracked `dangerous` |
| 8 | careful / carefully | adjective/adverb | Tie to the already-present safety/danger theme |
