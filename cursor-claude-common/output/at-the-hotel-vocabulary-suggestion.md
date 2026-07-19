# At the Hotel: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 431 entries from the flow levels before `at-the-hotel` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `at-the-hotel` (own images), `household-equipment-1` (key), `waking-up` (bed, pillow, alarm clock), `in-the-bathroom` (towel, shower), `at-the-school` (gym), `house-parts` (balcony), `clothes-shopping` (hanger), `at-the-library` (book)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **receptionist** (A1) — Core role-noun, pairs with the already-image-taught `reception`
- **reservation** (A2) — Ties directly to the already-tracked "check in"/"book a room" theme
- **guest** (A1) — Core hotel-role noun, currently absent
- **luggage** (A1) — Extremely common hotel noun, currently absent
- **bathroom** (A1) — Ties to the already-tracked `towel`/`shower`
- **wifi** (A1) — Extremely common modern hotel amenity
- **safe** (A1) — Common hotel-room security object
- **television** (A1) — Common hotel-room amenity
- **phone** (A1) — Common hotel-room amenity
- **service** (A1) — Ties to "room service" and general hospitality theme

### Verbs
- **arrive** (A1) — Natural antonym pairing with the already-tracked `to stay`/`check in`
- **depart** (A2) — Pairs with `arrive`, ties to `check out`
- **request** (A2) — Common hotel-service verb, distinct from tracked `ask`
- **cancel** (A2) — Ties to the already-present `reservation`/booking theme

### Adjectives
- **luxurious** (A2) — Core theme-defining adjective for a hotel, currently absent
- **affordable** (A2) — Natural antonym of the already-tracked `expensive`
- **friendly** (A1) — Common service-quality descriptor
- **booked** (A2) — Ties directly to the "is the room available" theme already present
- **private** (A2) — Common hotel-room/amenity descriptor

### Adverbs
- **comfortably** (A2) — Matches the already-tracked `comfortable`
- **promptly** (A2) — Fits the hotel-service-quality theme
- **politely** (A2) — Fits the guest-staff interaction theme already present
- **immediately** (A1) — Common in hotel-service instructions

---

## UNUSED + RECOMMENDED

### Nouns
- key card, suite, bellboy, minibar, buffet, housekeeping, view, air conditioner, closet, remote, invoice, amenities, parking, valet

### Verbs
- unpack, swim, exercise, dine, upgrade

### Adjectives
- modern, elegant, fully-booked, relaxing, convenient, welcoming

### Adverbs
- warmly, efficiently, smoothly, conveniently, professionally, kindly, patiently, generously

---

## USED + HIGH PRIORITY

### Nouns
- **reception** — PNG (`at-the-hotel/reception.png`) + `questions.json`
- **lobby** — `questions.json` (Q1/Q8 distractors)
- **room** — `questions.json` (Q6, Q9, Q15)
- **key** — PNG (`household-equipment-1/key.png`) + `questions.json` (Q2 distractor "get a key")
- **check-in** — `translations.json` + `questions.json` (Q3 answer)
- **check-out** — `translations.json` + `questions.json` (Q13 answer)
- **elevator** — PNG (`at-the-hotel/elevator.png`) + `questions.json`
- **hallway** — PNG (`at-the-hotel/hallway.png`) + `questions.json`
- **bed** — PNG (`waking-up/bed.png`)
- **towel** — PNG (`in-the-bathroom/towel.png`) + `questions.json` (Q7 distractor)
- **shower** — PNG (`in-the-bathroom/shower.png`) + `questions.json` (Q6)
- **breakfast** — prior-words
- **restaurant** — `questions.json` (Q8 distractor)
- **pool** — `questions.json` (Q2)
- **concierge** — `questions.json` (Q11)
- **manager** — prior-words

### Verbs
- **check in** — `translations.json` + `questions.json`
- **check out** — `translations.json` + `questions.json` (Q13 answer)
- **book** — prior-words + PNG (`at-the-library/book.png`) + `questions.json` (Q3 distractor)
- **reserve** — prior-words
- **stay** — `translations.json` + `questions.json` (Q14 answer)
- **order** — prior-words
- **complain** — `translations.json` + `questions.json` (Q9 SentenceBuilder)
- **confirm** — `translations.json` + `questions.json` (Q6 AppearDisappear)

### Adjectives
- **comfortable** — prior-words
- **clean** — prior-words
- **helpful** — `translations.json` + `questions.json` (Q14 answer)
- **available** — prior-words + `questions.json` (Q6)
- **noisy** — `questions.json` (WordPairs)

### Adverbs
*(none rated essential beyond what's already reinforced below)*

---

## USED + RECOMMENDED

### Nouns
- **pillow** — PNG (`waking-up/pillow.png`)
- **gym** — PNG (`at-the-school/gym.png`)
- **spa** — `questions.json` (Q13/Q14)
- **balcony** — PNG (`house-parts/balcony.png`)
- **hanger** — PNG (`clothes-shopping/hanger.png`) + `questions.json` (`door-hanger`)
- **alarm clock** — PNG (`waking-up/alarm-clock.png`)
- **tip** — prior-words
- **deposit** — prior-words

### Verbs
- **sleep** — prior-words
- **rest** — prior-words
- **pack** — prior-words
- **tip** — prior-words
- **clean** — prior-words
- **relax** — prior-words
- **ask** — `questions.json` (Q10 distractor)
- **wait** — prior-words + `questions.json` (Q10 distractor)
- **carry** — prior-words
- **deliver** — prior-words

### Adjectives
- **spacious** — prior-words
- **cozy** — prior-words
- **expensive** — prior-words
- **quiet** — prior-words

### Adverbs
- **quietly** — prior-words
- **quickly** — prior-words

---

## SUMMARY

- **Total words analyzed:** 109 (48 nouns, 27 verbs, 20 adjectives, 14 adverbs)
- **Unused:** 56 (51%) — 23 High Priority (41%) / 33 Recommended (59%)
- **Used:** 53 (49%) — 29 High Priority (55%) / 24 Recommended (45%)

**Source breakdown for USED words:** `translations.json` (7 words), `questions.json` (~24 words, several overlapping), PNG project-wide (13 words, spanning `at-the-hotel`, `household-equipment-1`, `waking-up`, `in-the-bathroom`, `at-the-school`, `house-parts`, `clothes-shopping`, `at-the-library`), prior-words-by-type.md equivalent (~16 words).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | guest / receptionist | noun | Core hotel-role nouns, both completely absent |
| 2 | luggage | noun | Extremely common hotel noun, surprisingly absent |
| 3 | arrive / depart | verb | Natural pair ties to already-tracked `check in`/`check out` |
| 4 | reservation | noun | Ties directly to the already-present booking/availability theme |
| 5 | luxurious | adjective | Core theme-defining word for a hotel, currently absent |
| 6 | affordable | adjective | Natural antonym of the already-tracked `expensive` |
| 7 | wifi / television / phone | noun | Modern hotel-room essentials, all absent |
| 8 | booked | adjective | Ties directly to the already-present "is the room available" theme |
