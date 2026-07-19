# At the Train Station: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 465 entries from the flow levels before `at-the-train-station` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `at-the-train-station` (own images), `vehicles` (train), `at-the-farmers-market` (kiosk), `walking-in-the-city` (bench), `school-items-2` (backpack), `city-buildings-2` (escalator), `at-the-hotel` (elevator), `house-parts` (gate)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **track** (A1) — Core train-station noun, ties to the already-image-taught `rail-road`
- **timetable** (A1) — Ties directly to the already-present "schedule"/departure theme
- **seat** (A1) — Extremely common, currently absent
- **carriage** (A2) — Ties to the already-image-taught `wagon`
- **departure** (A2) — Ties to the already-present arrival/delay theme
- **arrival** (A1) — Natural antonym pairing with `departure` (verb `to arrive` is already tracked)
- **map** (A1) — Common station-navigation object
- **staff** (A1) — Common role-noun, ties to `conductor`
- **route** (A2) — Ties to the already-tracked `to transfer`/`connection` theme

### Verbs
- **board** (A1) — Extremely common train-station verb, surprisingly absent
- **stand** (A1) — Natural antonym of the already-tracked `to sit`
- **queue** (A2) — Common station-behavior verb
- **ask** (A1) — Common station-interaction verb

### Adjectives
- **punctual** (A2) — Ties directly to the already-present "delayed"/"on time" theme
- **cancelled** (A2) — Adjective form of the already-tracked `to cancel`
- **direct** (A2) — Common train-service descriptor (as opposed to connecting/transfer trains)
- **safe** (A1) — Common travel-safety descriptor

### Adverbs
- **promptly** (A2) — Fits the punctuality theme
- **punctually** (A2) — Matches the `punctual` adjective above
- **safely** (A1) — Matches the `safe` adjective above
- **immediately** (A1) — Common in station announcements

---

## UNUSED + RECOMMENDED

### Nouns
- ticket machine, waiting room, suitcase, entrance, turnstile, information desk, ticket office, commuter, connection, express, first class, economy class, timetable board

### Verbs
- rush, scan, validate, commute

### Adjectives
- express, cramped, convenient

### Adverbs
- patiently, nervously, calmly, smoothly, hurriedly, frequently, anxiously

---

## USED + HIGH PRIORITY

### Nouns
- **ticket** — `questions.json` (Q6 distractor "I lost my ticket")
- **platform** — `questions.json` (Q7 AppearDisappear)
- **train** — PNG (`vehicles/train.png`) + `questions.json`
- **schedule** — prior-words
- **conductor** — PNG (`at-the-train-station/conductor.png`) + `questions.json`
- **passenger** — prior-words
- **station** — `questions.json` (Q7, Q15)
- **announcement** — `questions.json` (Q6 distractor)
- **exit** — `translations.json` + `questions.json` (Q7 AppearDisappear)
- **gate** — PNG (`house-parts/gate.png`)

### Verbs
- **depart** — prior-words
- **arrive** — `translations.json` + `questions.json` (Q7, Q15 answer)
- **wait** — prior-words
- **buy** — prior-words + `questions.json` (Q9 distractor)
- **check** — `questions.json` (`check-in-counter` distractor)
- **catch** — `translations.json` + `questions.json` (Q6 answer "catch the train")
- **exit** — `translations.json` + `questions.json`
- **travel** — `translations.json` + `questions.json` (Q2 answer)

### Adjectives
- **delayed** — `questions.json` (Q10 SentenceBuilder)
- **late** — prior-words
- **early** — prior-words
- **fast** — `translations.json` + `questions.json` (Q13 "Trains used to be fast")
- **crowded** — prior-words
- **busy** — prior-words

### Adverbs
*(none rated essential beyond what's reinforced below)*

---

## USED + RECOMMENDED

### Nouns
- **delay** — prior-words
- **kiosk** — PNG (`at-the-farmers-market/kiosk.png`)
- **bench** — PNG (`walking-in-the-city/bench.png`)
- **luggage** — `questions.json` (Q12 "her luggage")
- **backpack** — PNG (`school-items-2/backpack.png`)
- **sign** — prior-words
- **escalator** — PNG (`city-buildings-2/escalator.png`)
- **elevator** — PNG (`at-the-hotel/elevator.png`)
- **transfer** — prior-words
- **local** — prior-words

### Verbs
- **transfer** — prior-words
- **connect** — prior-words
- **sit** — prior-words
- **hurry** — `translations.json` (Q14 "were hurrying")
- **miss** — prior-words
- **announce** — prior-words
- **delay** — prior-words
- **cancel** — prior-words
- **enter** — prior-words
- **help** — prior-words

### Adjectives
- **local** — prior-words
- **comfortable** — prior-words
- **noisy** — prior-words
- **quiet** — prior-words
- **long** — prior-words
- **short** — prior-words
- **slow** — prior-words

### Adverbs
- **quickly** — prior-words
- **regularly** — prior-words
- **finally** — prior-words

---

## SUMMARY

- **Total words analyzed:** 102 (42 nouns, 26 verbs, 20 adjectives, 14 adverbs)
- **Unused:** 48 (47%) — 21 High Priority (44%) / 27 Recommended (56%)
- **Used:** 54 (53%) — 24 High Priority (44%) / 30 Recommended (56%)

**Source breakdown for USED words:** `translations.json` (7 words), `questions.json` (~22 words, several overlapping), PNG project-wide (8 words, spanning `at-the-train-station`, `vehicles`, `at-the-farmers-market`, `walking-in-the-city`, `school-items-2`, `city-buildings-2`, `at-the-hotel`, `house-parts`), prior-words-by-type.md equivalent (~20 words).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | board | verb | Extremely common train-station verb, surprisingly absent |
| 2 | track | noun | Ties directly to the already-image-taught `rail-road` |
| 3 | carriage | noun | Ties directly to the already-image-taught `wagon` |
| 4 | departure / arrival | noun | Noun forms tying to the already-tracked `to arrive`/delay theme |
| 5 | stand | verb | Natural antonym of the already-tracked `to sit` |
| 6 | punctual / cancelled | adjective | Both tie directly to the already-present delay/on-time theme |
| 7 | timetable | noun | Ties directly to the already-present "schedule" concept |
| 8 | seat | noun | Extremely common, currently absent |
