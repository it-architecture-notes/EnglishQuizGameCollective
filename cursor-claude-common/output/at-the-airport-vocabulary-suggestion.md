# At the Airport: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 448 entries from the flow levels before `at-the-airport` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `at-the-airport` (own images), `travel-items` (passport, overhead bin, visa), `house-parts` (gate), `jobs-2` (pilot), `city-buildings-2` (escalator), `emotions-1` (nervous), `insect-world` (fly — different sense, see caution below)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

**Homonym/different-sense caution:** the verb `fly` (as in "the plane flies") matched `insect-world/fly.png` (the insect). Listed as USED per the literal word-match rule, but that image wouldn't actually teach the aviation sense — the level already teaches `to fly` properly via `translations.json` and `questions.json`, so this is a non-issue in practice, just flagged for completeness.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **ticket** (A1) — Extremely common travel noun, currently absent
- **boarding pass** (A1) — Ties directly to the already-tracked `to board`/boarding theme
- **luggage** (A1) — Core airport noun, currently absent (only compound "baggage-claim"/"baggage-carousel" images exist)
- **suitcase** (A1) — Pairs with `luggage`
- **terminal** (A1) — Core airport-location noun
- **passenger** (A1) — Core role noun, pairs with the already-image-taught `pilot`
- **departure** (A1) — Noun form of the already-tracked `to depart`
- **arrival** (A1) — Natural antonym pairing with `departure`
- **seat** (A1) — Extremely common, currently absent
- **ID** (A1) — Ties to the already-image-taught `passport`/`visa`

### Verbs
- **take off** (A1) — Natural antonym of the already-tracked `to land`
- **arrive** (A1) — Natural antonym of the already-tracked `to depart`
- **present** ("present a passport") (A2) — Ties directly to the already-image-taught `passport`
- **announce** (A2) — Ties to the "departures board" theme already present
- **transfer** (A2) — Common airport-connection concept
- **queue** (A2) — Ties to the already-present "How long will we wait?" theme

### Adjectives
- **cancelled** (A2) — Adjective form of the already-tracked `to cancel`
- **international** (A1) — Ties to the already-image-taught `customs`/`immigration` theme
- **secure** (A2) — Ties to the already-image-taught `security-check`
- **safe** (A1) — Pairs with `secure`

### Adverbs
- **patiently** (A2) — Fits the "we can play a game together" waiting theme already present
- **carefully** (A1) — General airport-procedure adverb
- **safely** (A1) — Ties to the `secure`/`safe` cluster above
- **immediately** (A1) — Common in airport announcements

---

## UNUSED + RECOMMENDED

### Nouns
- airline, crew, immigration, baggage claim, cancellation, lounge, duty-free, conveyor belt, metal detector, scanner, aisle, window seat, announcement, screen, monitor, connection, layover, runway, tarmac, taxi, shuttle, parking, currency exchange, information desk

### Verbs
- scan, screen, unpack, rush, hug, exchange

### Adjectives
- direct, connecting, cramped

### Adverbs
- nervously, excitedly, promptly, smoothly, calmly, anxiously, efficiently

---

## USED + HIGH PRIORITY

### Nouns
- **passport** — PNG (`travel-items/passport.png`) + `questions.json` (Q9 distractor)
- **check-in** — `questions.json` (`check-in-counter` image)
- **security** — `questions.json` (`security-check` image, Q10 distractor)
- **gate** — PNG (`house-parts/gate.png`) + `questions.json` (Q3 "gate C4")
- **flight** — `questions.json` (Q3, Q4, Q6, Q13)
- **pilot** — PNG (`jobs-2/pilot.png`) + `questions.json` (Q5 distractor)
- **customs** — `questions.json` (`customs-officer` image)
- **visa** — PNG (`travel-items/visa.png`)

### Verbs
- **check in** — prior-words + `questions.json` (Q7 distractor, AppearDisappear)
- **board** — `questions.json` (`boarding-pass`)
- **fly** — PNG (⚠️ different sense) + `translations.json` + `questions.json` (Q2 answer)
- **land** — `translations.json` + `questions.json` (Q3 answer)
- **depart** — `translations.json` + `questions.json` (Q3 answer)
- **cancel** — `translations.json` + `questions.json` (Q6 answer)

### Adjectives
- **delayed** — `questions.json` (Q9 SentenceBuilder)
- **on-time** — `questions.json` (Q8 line1 "on time")
- **domestic** — prior-words
- **excited** — `questions.json` (WordPairs)
- **nervous** — PNG (`emotions-1/nervous.png`)
- **early** — prior-words + `questions.json` (Q3 distractor)
- **late** — prior-words + `translations.json` + `questions.json` (Q3 answer)

### Adverbs
*(none rated essential beyond what's reinforced below)*

---

## USED + RECOMMENDED

### Nouns
- **delay** — `translations.json` (`to delay`)
- **escalator** — PNG (`city-buildings-2/escalator.png`)
- **boarding** — `questions.json` (`boarding-pass`)
- **overhead bin** — PNG (`travel-items/overhead-bin.png`)

### Verbs
- **wait** — prior-words + `questions.json` (Q5 answer)
- **pack** — prior-words
- **carry** — prior-words + `questions.json` (Q2 distractor)
- **weigh** — prior-words
- **delay** — `translations.json`
- **connect** — prior-words
- **relax** — prior-words
- **sleep** — prior-words
- **greet** — prior-words
- **wave** — prior-words
- **buy** — prior-words

### Adjectives
- **busy** — prior-words
- **crowded** — prior-words
- **long** — prior-words + `translations.json` (`how long`) + `questions.json`
- **short** — prior-words
- **tired** — prior-words
- **spacious** — prior-words

### Adverbs
- **quickly** — prior-words + `questions.json` (Q2 distractor)
- **slowly** — prior-words
- **finally** — prior-words

---

## SUMMARY

- **Total words analyzed:** 109 (46 nouns, 29 verbs, 20 adjectives, 14 adverbs)
- **Unused:** 64 (59%) — 24 High Priority (38%) / 40 Recommended (62%)
- **Used:** 45 (41%) — 21 High Priority (47%) / 24 Recommended (53%)

**Source breakdown for USED words:** `translations.json` (7 words), `questions.json` (~25 words, several overlapping), PNG project-wide (8 words, spanning `at-the-airport`, `travel-items`, `house-parts`, `jobs-2`, `city-buildings-2`, `emotions-1`, `insect-world`), prior-words-by-type.md equivalent (~16 words).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | ticket | noun | Extremely common travel noun, surprisingly absent |
| 2 | luggage / suitcase | noun | Core airport nouns, only compound baggage-claim/carousel images exist |
| 3 | passenger | noun | Core role noun, pairs with the already-image-taught `pilot` |
| 4 | arrive / take off | verb | Natural antonym pairs for already-tracked `depart`/`land` |
| 5 | departure / arrival | noun | Noun forms of already-tracked `depart`, natural antonym pair |
| 6 | seat | noun | Extremely common, currently absent |
| 7 | cancelled | adjective | Adjective form of the already-tracked `to cancel` |
| 8 | international | adjective | Ties to the already-image-taught `customs`/`immigration` theme |
