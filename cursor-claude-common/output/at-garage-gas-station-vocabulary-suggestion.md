# At Garage / Gas Station: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder). Word lists for both "Garage" and "Gas Station" prompts were merged and deduplicated (`car`, `receipt`, `hose`, `oil`, `cheap`, `expensive`, `quickly`, `carefully`, `safely`, `immediately`, `efficiently`, `patiently`, `promptly` appeared in both).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 486 entries from the flow levels before `at-garage-gas-station` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `at-garage-gas-station` (own images), `jobs-1` (mechanic), `vehicles` (car), `living-room-items` (mirror), `at-the-restaurant` (bill), `household-equipment-2` (screw), `at-the-farm` (hose), `at-the-cinema` (drink), `at-the-school` (restroom)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **technician** (A2) — Pairs with the already-image-taught `mechanic`
- **tool** (A1) — Extremely common garage noun, surprisingly absent
- **part** (A1) — Ties directly to the already-tracked `to replace`
- **oil** (A1) — Extremely common car-maintenance noun, currently absent
- **estimate** (A2) — Ties to the "how much will it cost" theme already present
- **damage** (A2) — Ties to the already-tracked "serious"/broken theme
- **service** (A1) — Core theme word for both garage and gas station
- **price** (A1) — Common gas-station noun
- **cashier** (A1) — Common role noun for the gas-station side
- **cash** (A1) — Ties to the payment theme
- **credit card** (A1) — Common modern payment method
- **windshield** (A1) — Common car-part noun

### Verbs
- **inspect** (A2) — Near-synonym reinforcement for the already-tracked `to check`
- **install** (A2) — Ties directly to the already-tracked `to replace`
- **test** (A1) — Common garage-service verb
- **tow** (A2) — Classic garage-service verb ("my car broke down" already sets this up)
- **service** (A1) — Verb form matching the noun above
- **park** (A1) — Extremely common gas-station-context verb

### Adjectives
- **damaged** (A2) — Ties to the already-tracked `broken`
- **faulty** (A2) — Near-synonym reinforcement for `broken`
- **safe** (A1) — Ties to the already-image-taught `fire-extinguisher` safety theme
- **used** (A1) — Common car-condition descriptor
- **reliable** (A2) — Common car/mechanic-quality descriptor
- **convenient** (A2) — Common gas-station descriptor

### Adverbs
- **safely** (A1) — Matches the `safe` adjective above
- **correctly** (A1) — Ties to the repair/inspection theme
- **promptly** (A2) — Common service-quality descriptor
- **conveniently** (A2) — Matches the `convenient` adjective above

---

## UNUSED + RECOMMENDED

### Nouns
- invoice, workshop, appointment, diagnosis, bolt, filter, spare part, inspection, mileage, waiting area, manual, license plate, dashboard, wiper, headlight, nozzle, driver, convenience store, attendant, gallon, liter, unleaded, air pump, car wash, tire pressure, snack, parking, membership card

### Verbs
- diagnose, tighten, loosen, drain, refill, estimate, polish, adjust, lower, swipe, wipe, refuel, top off

### Adjectives
- worn-out, unreliable, mechanical, electrical, smooth, unsafe, self-service, full-service, regular, premium, low, high

### Adverbs
- thoroughly, professionally, efficiently, smoothly, automatically, manually

---

## USED + HIGH PRIORITY

### Nouns
- **mechanic** — PNG (`jobs-1/mechanic.png`) + `questions.json`
- **car** — PNG (`vehicles/car.png`) + `questions.json` (Q2 "my car broke down")
- **engine** — `questions.json` (Q11 "the engine was started")
- **wrench** — PNG (`at-garage-gas-station/wrench.png`) + `questions.json`
- **repair** — `translations.json` + `questions.json` (Q2 answer)
- **tire** — `translations.json` (`flat tire`) + `questions.json` (Q6, Q10)
- **battery** — PNG (`at-garage-gas-station/battery.png`) + `questions.json`
- **brake** — prior-words
- **warranty** — `questions.json` (Q7 AppearDisappear)
- **garage** — `questions.json` (Q6 distractor)
- **lift** — PNG (`at-garage-gas-station/lift.png`) + `translations.json` + `questions.json`
- **gas** — `questions.json` (`gas-pump` image)
- **fuel** — `questions.json` (Q1 distractor "fuel-can")
- **pump** — `questions.json` (`gas-pump`)
- **tank** — `questions.json` (Q13 "fill up the tank")
- **diesel** — `questions.json` (Q1 distractor)

### Verbs
- **repair** — `translations.json` + `questions.json`
- **fix** — `questions.json` (Q14 "fixed it immediately")
- **replace** — `translations.json` + `questions.json` (Q12 answer)
- **check** — `questions.json` (Q2 "I need to check it first")
- **fill up** — `translations.json` + `questions.json` (Q13 answer)
- **pump** — `questions.json`
- **wash** — prior-words + `questions.json` (Q2 distractor)

### Adjectives
- **broken** — `translations.json` + `questions.json` (Q14 answer)
- **fixed** — `questions.json` (Q14 "fixed it immediately")
- **flat** — `translations.json` (`flat tire`) + `questions.json` (Q6)
- **full** — prior-words
- **empty** — prior-words

### Adverbs
- **immediately** — `translations.json` + `questions.json` (Q14 answer)

---

## USED + RECOMMENDED

### Nouns
- **mirror** — PNG (`living-room-items/mirror.png`)
- **bill** — PNG (`at-the-restaurant/bill.png`)
- **customer** — prior-words
- **screw** — PNG (`household-equipment-2/screw.png`)
- **hose** — PNG (`at-the-farm/hose.png`) + `questions.json` (Q1 distractor)
- **receipt** — prior-words
- **drink** — prior-words + PNG (`at-the-cinema/drink.png`)
- **restroom** — PNG (`at-the-school/restroom.png`)
- **sign** — prior-words
- **discount** — prior-words

### Verbs
- **remove** — prior-words
- **drive** — prior-words
- **wait** — prior-words
- **pay** — prior-words
- **recommend** — prior-words
- **order** — prior-words
- **schedule** — prior-words
- **clean** — prior-words
- **lift** — PNG + `translations.json` + `questions.json`
- **insert** — prior-words
- **open** — prior-words
- **close** — prior-words
- **select** — prior-words
- **choose** — prior-words
- **stop** — prior-words
- **leave** — `questions.json` (Q13 "before you leave")
- **buy** — prior-words + `questions.json` (Q2 distractor)

### Adjectives
- **expensive** — prior-words
- **cheap** — prior-words
- **urgent** — prior-words
- **new** — `questions.json` (Q3 distractor)
- **noisy** — prior-words
- **ready** — prior-words
- **quick** — prior-words
- **busy** — prior-words
- **clean** — prior-words
- **dirty** — prior-words

### Adverbs
- **carefully** — `questions.json` (Q14 distractor)
- **quickly** — prior-words
- **properly** — prior-words
- **patiently** — prior-words

---

## SUMMARY

- **Total words analyzed:** 157 (66 nouns, 43 verbs, 33 adjectives, 15 adverbs)
- **Unused:** 87 (55%) — 28 High Priority (32%) / 59 Recommended (68%)
- **Used:** 70 (45%) — 29 High Priority (41%) / 41 Recommended (59%)

**Source breakdown for USED words:** `translations.json` (7 words), `questions.json` (~30 words, several overlapping), PNG project-wide (13 words, spanning `at-garage-gas-station`, `jobs-1`, `vehicles`, `living-room-items`, `at-the-restaurant`, `household-equipment-2`, `at-the-farm`, `at-the-cinema`, `at-the-school`), prior-words-by-type.md equivalent (~20 words).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | tool / oil | noun | Extremely common garage nouns, both surprisingly absent |
| 2 | part | noun | Ties directly to the already-tracked `to replace` |
| 3 | technician | noun | Pairs with the already-image-taught `mechanic` |
| 4 | inspect / install | verb | Near-synonym/pairing reinforcement for already-tracked `check`/`replace` |
| 5 | damaged / faulty | adjective | Both reinforce the already-tracked `broken` |
| 6 | estimate | noun | Ties to the "how much will it cost" theme already present |
| 7 | cashier / cash / credit card | noun | Core gas-station payment vocabulary, all absent |
| 8 | safe / safely | adjective/adverb | Tie to the already-image-taught `fire-extinguisher` safety theme |
