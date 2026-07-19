# At the Restaurant: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 358 entries from the flow levels before `at-the-restaurant` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder (exact-stem matching), turning up matches in `jobs-1`/`jobs-2` (waiter/hostess), `kitchen-items-1`/`kitchen-items-2` (spoon/glass/fork), `restaurant-items` (napkin), `grocery-list-1`/`grocery-list-2` (bread/water), `living-room`/`living-room-items` (chair/table), `in-the-kitchen` (plate), `at-the-cinema` (drink), `at-the-school` (restroom)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **waitress** (A1) — Gender-pair of the already-image-taught `waiter`, currently absent
- **kitchen** (A1) — Core restaurant-location noun, ties to the already-tracked `chef`
- **food** (A1) — Extremely common general noun, surprisingly absent as a standalone word
- **tip** (A1) — Core restaurant-payment concept, distinct from tracked `bill`
- **reservation** (A2) — Ties to the already-present "ready for dessert"/service-flow theme
- **host** (A1) — Pairs with the already-image-taught `hostess`
- **knife** (A1) — Completes the cutlery set (fork/spoon are already image-taught, knife is the gap)
- **cup** (A1) — Common tableware noun, distinct from tracked `glass`
- **wine** (A2) — Classic restaurant-order noun
- **cashier** (A2) — Ties to the payment/bill theme already present

### Verbs
- **tip** (A1) — Pairs with the noun `tip` above
- **seat** ("to seat someone") (A2) — Core restaurant-service verb
- **request** (A2) — Common polite-order verb
- **complain** (A2) — Natural service-quality concept
- **clear** ("clear the table") (A1) — Common restaurant-service action
- **thank** (A1) — Ties to the level's polite-service theme

### Adjectives
- **tasty** (A1) — Near-synonym reinforcement for the already-tracked `delicious`
- **affordable** (A2) — Pairs with the already-tracked `expensive`
- **friendly** (A1) — Common service-quality descriptor
- **polite** (A2) — Ties to the level's courteous-service theme
- **fast** (A1) — Natural antonym of the already-tracked `slow`
- **satisfied** (A2) — Ties to the "ready for dessert"/customer-experience theme

### Adverbs
- **politely** (A2) — Matches the `polite` adjective above
- **patiently** (A2) — Fits the waiting-for-food theme
- **carefully** (A1) — General service-quality adverb
- **promptly** (A2) — Fits the "I will serve it right away" theme already present

---

## UNUSED + RECOMMENDED

### Nouns
- appetizer, main course, booth, tablecloth, candle, seasoning, sauce, buffet, portion, cuisine, register, takeout, delivery, ambiance, music

### Verbs
- split, refill, prepare, garnish, season, chew, swallow, sip

### Adjectives
- bitter, cozy, elegant, casual, fancy, romantic, family-friendly, popular, reserved, disappointed

### Adverbs
- happily, generously, warmly, kindly, calmly, gratefully, comfortably

---

## USED + HIGH PRIORITY

### Nouns
- **table** — PNG (`living-room-items/table.png`)
- **menu** — PNG (`at-the-restaurant/menu.png`) + `questions.json`
- **waiter** — PNG (`jobs-1/waiter.png`)
- **chef** — `questions.json` (Q10 SentenceBuilder)
- **order** — `translations.json` + `questions.json` (Q2 answer)
- **drink** — prior-words + PNG (`at-the-cinema/drink.png`) + `questions.json`
- **dish** — `questions.json` (Q11/Q14)
- **meal** — PNG (`at-the-restaurant/meal.png`) + `questions.json`
- **dessert** — `questions.json` (Q3, Q6)
- **bill** — PNG (`at-the-restaurant/bill.png`) + `questions.json`
- **hostess** — PNG (`jobs-2/hostess.png`)
- **napkin** — PNG (`restaurant-items/napkin.png`)
- **plate** — PNG (`in-the-kitchen/plate.png`) + `questions.json`
- **fork** — PNG (`kitchen-items-2/fork.png`)
- **spoon** — PNG (`kitchen-items-1/spoon.png`)
- **glass** — PNG (`kitchen-items-1/glass.png`)
- **water** — PNG (`grocery-list-2/water.png`)
- **bread** — PNG (`grocery-list-1/bread.png`)

### Verbs
- **order** — `translations.json` + `questions.json`
- **serve** — `translations.json` + `questions.json` (Q6 answer)
- **eat** — prior-words + `questions.json` (Q7)
- **drink** — prior-words + PNG + `questions.json`
- **cook** — prior-words
- **taste** — `translations.json` + `questions.json` (Q14 answer)
- **share** — `translations.json` + `questions.json` (Q3 answer)
- **bring** — `questions.json` (Q6 distractor)

### Adjectives
- **delicious** — `translations.json` + `questions.json` (Q11 answer)
- **spicy** — `questions.json` (WordPairs)
- **sweet** — `questions.json` (WordPairs)
- **sour** — `questions.json` (WordPairs)
- **hot** — prior-words
- **cold** — prior-words + `questions.json` (Q13 distractor)

### Adverbs
- **slowly** — prior-words + `questions.json` (Q14 distractor)

---

## USED + RECOMMENDED

### Nouns
- **receipt** — prior-words
- **chair** — PNG (`living-room/chair.png`)
- **restroom** — PNG (`at-the-school/restroom.png`)
- **customer** — prior-words
- **review** — prior-words

### Verbs
- **pay** — prior-words
- **reserve** — prior-words
- **wait** — prior-words + `questions.json` (Q6 distractor)
- **recommend** — prior-words
- **choose** — prior-words
- **decide** — prior-words + `questions.json` (Q2)
- **enjoy** — prior-words
- **deliver** — prior-words
- **greet** — prior-words
- **welcome** — prior-words

### Adjectives
- **fresh** — prior-words
- **crowded** — prior-words
- **quiet** — prior-words
- **expensive** — prior-words
- **slow** — prior-words
- **busy** — prior-words + `questions.json` (Q6 distractor)
- **available** — prior-words

### Adverbs
- **quickly** — prior-words
- **quietly** — prior-words

---

## SUMMARY

- **Total words analyzed:** 123 (48 nouns, 32 verbs, 29 adjectives, 14 adverbs)
- **Unused:** 66 (54%) — 26 High Priority (39%) / 40 Recommended (61%)
- **Used:** 57 (46%) — 33 High Priority (58%) / 24 Recommended (42%)

**Source breakdown for USED words:** `translations.json` (7 words), `questions.json` (~25 words, several overlapping), PNG project-wide (18 words, spanning 10 different level folders), prior-words-by-type.md equivalent (~20 words).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | food | noun | Extremely common word, surprisingly absent |
| 2 | knife | noun | Completes the fork/spoon cutlery set (both already image-taught) |
| 3 | tip | noun/verb | Core restaurant payment concept, distinct from tracked `bill` |
| 4 | waitress / host | noun | Gender-pair completion for already-taught `waiter`/`hostess` |
| 5 | tasty | adjective | Reinforces the already-tracked `delicious` with a near-synonym |
| 6 | fast / affordable | adjective | Natural antonym pairs for tracked `slow`/`expensive` |
| 7 | seat / clear | verb | Core restaurant-service actions, currently absent |
| 8 | kitchen | noun | Ties to the already-tracked `chef`, currently absent as a location |
