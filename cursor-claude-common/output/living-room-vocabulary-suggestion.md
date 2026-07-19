# Living Room: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 414 entries from the flow levels before `living-room` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `living-room-items` (table, fireplace, plant, vase, light switch, mirror), `house-parts` (window), `waking-up` (pillow, blanket), `school-items-1` (clock), `family` (family), `in-the-bedroom` (drawer), `at-the-office` (cabinet), `household-equipment-1` (vacuum), `dressing-1` (watch — different sense, see caution below)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

**Homonym/different-sense caution:** the verb `watch` (as in "watch TV") matched `dressing-1/watch.png`, which is the wristwatch item, not the verb. Listed as USED per the literal word-match rule, but flagged since that PNG wouldn't actually teach "to watch TV."

---

## UNUSED + HIGH PRIORITY

### Nouns
- **couch** (A1) — Near-synonym of the already-used `sofa`, but genuinely a distinct common word
- **lamp** (A1) — Core living-room object, currently absent
- **television** (A1) — Extremely common living-room noun, surprisingly absent (only `remote` is tracked)
- **rug** (A1) — Common living-room floor covering
- **shelf** (A1) — Ties to the already-image-taught `bookshelf`
- **wall** (A1) — Extremely common room-part noun
- **ceiling** (A1) — Pairs with `wall`/`floor`
- **floor** (A1) — Pairs with `wall`/`ceiling`
- **guest** (A1) — Directly ties to the already-tracked "He likes to greet guests"
- **fan** (A1) — Common living-room appliance

### Verbs
- **chat** (A1) — Near-synonym reinforcement for the already-tracked `to talk`
- **tidy** (A1) — Ties to the level's "great living room"/family-gathering theme
- **play** (A1) — Ties to the orphaned "Can we play chess here?" audio hint (a removed question) and general living-room activity
- **turn on** (A1) — Common appliance-control verb (TV/lamp), currently absent
- **turn off** (A1) — Pairs with `turn on`

### Adjectives
- **cozy** (A1) — Core theme-defining adjective for a living room, currently absent
- **spacious** (A2) — Common room-description adjective
- **warm** (A1) — Common atmosphere descriptor
- **messy** (A1) — Natural antonym pairing opportunity (no "tidy" state adjective currently either)
- **tidy** (A1) — Pairs with `messy`
- **noisy** (A1) — Natural antonym of the already-tracked `quiet`

### Adverbs
- **comfortably** (A2) — Adverb form of the already-tracked `comfortable`
- **neatly** (A1) — Matches the `tidy` theme
- **warmly** (A1) — Matches the `warm` adjective above

---

## UNUSED + RECOMMENDED

### Nouns
- carpet, bookcase, cushion, painting, photo frame, speaker, decoration, candle, magazine, air conditioner, sofa bed, storage box

### Verbs
- nap, arrange, dust, entertain, host, adjust, lounge, cuddle

### Adjectives
- dim, modern, stylish, elegant, homey, welcoming, colorful, cushioned, cluttered, organized

### Adverbs
- cozily, happily, calmly, casually, peacefully, leisurely

---

## USED + HIGH PRIORITY

### Nouns
- **sofa** — `questions.json` (Q2 answer "I sit on the sofa")
- **chair** — PNG (`living-room/chair.png`) + `questions.json` (Q1 distractor)
- **table** — PNG (`living-room-items/table.png`) + `questions.json` (Q1 distractor)
- **remote** — `questions.json` (Q3 "remote control")
- **curtain** — `questions.json` (Q7 distractor "curtain")
- **window** — PNG (`house-parts/window.png`) + `questions.json` (Q6)
- **pillow** — PNG (`waking-up/pillow.png`)
- **blanket** — PNG (`waking-up/blanket.png`)
- **fireplace** — PNG (`living-room-items/fireplace.png`)
- **coffee table** — PNG (`living-room/coffee-table.png`)
- **family** — PNG (`family/family.png`) + `questions.json` (Q9, Q11)
- **mirror** — PNG (`living-room-items/mirror.png`)
- **cabinet** — PNG (`at-the-office/cabinet.png`) + `questions.json` (Q6 distractor)

### Verbs
- **sit** — `translations.json` + `questions.json` (Q2 answer)
- **relax** — `translations.json`
- **watch** — prior-words + PNG (⚠️ different sense — wristwatch)
- **talk** — `translations.json` + `questions.json` (Q13 answer)
- **gather** — `translations.json` + `questions.json` (Q9 answer)
- **listen** — `translations.json` (`to listen to`) + `questions.json` (Q12 answer)

### Adjectives
- **comfortable** — prior-words + `questions.json` (WordPairs "more comfortable")
- **quiet** — prior-words

### Adverbs
- **together** — prior-words + `questions.json` (Q11 "relaxes together")

---

## USED + RECOMMENDED

### Nouns
- **plant** — prior-words + PNG (`living-room-items/plant.png`)
- **clock** — PNG (`school-items-1/clock.png`)
- **vase** — PNG (`living-room-items/vase.png`)
- **corner** — prior-words
- **light switch** — PNG (`living-room-items/light-switch.png`)
- **drawer** — PNG (`in-the-bedroom/drawer.png`)

### Verbs
- **read** — prior-words
- **rest** — prior-words
- **decorate** — prior-words
- **clean** — prior-words
- **vacuum** — PNG (`household-equipment-1/vacuum.png`)
- **welcome** — prior-words

### Adjectives
- **bright** — prior-words
- **soft** — prior-words

### Adverbs
- **quietly** — prior-words
- **gently** — prior-words

---

## SUMMARY

- **Total words analyzed:** 98 (41 nouns, 25 verbs, 20 adjectives, 12 adverbs)
- **Unused:** 60 (61%) — 24 High Priority (40%) / 36 Recommended (60%)
- **Used:** 38 (39%) — 22 High Priority (58%) / 16 Recommended (42%)

**Source breakdown for USED words:** `translations.json` (6 words), `questions.json` (~14 words, several overlapping), PNG project-wide (16 words, spanning `living-room-items`, `house-parts`, `waking-up`, `school-items-1`, `family`, `in-the-bedroom`, `at-the-office`, `household-equipment-1`, `dressing-1`), prior-words-by-type.md equivalent (~11 words).

**Note:** three orphaned audio files exist (`can-we-play-chess-here-convo.m4a`, `i-am-watching-tv-convo.m4a`, `the-family-watches-tv-together-convo.m4a`, `what-are-you-doing-convo.m4a`) that don't match any current question — these hint that earlier drafts of this level taught `play`, `watch` (TV sense), and other now-removed vocabulary. Worth knowing if you want to restore any of that content rather than starting from scratch.

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | television | noun | Extremely common living-room noun, currently absent (only `remote` tracked) |
| 2 | cozy | adjective | Core theme-defining word for a living room, currently absent |
| 3 | turn on / turn off | verb | Common appliance-control verbs, ties to `television`/`lamp` |
| 4 | wall / ceiling / floor | noun | Basic room-part nouns, all absent |
| 5 | guest | noun | Directly ties to the already-tracked "He likes to greet guests" |
| 6 | messy / tidy | adjective | Natural antonym pair, ties to the family-gathering theme |
| 7 | lamp / rug | noun | Core living-room objects, currently absent |
| 8 | chat | verb | Near-synonym reinforcement for the already-tracked `to talk` |
