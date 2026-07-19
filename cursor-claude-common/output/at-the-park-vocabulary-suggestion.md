# At the Park: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 504 entries from the flow levels before `at-the-park` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `at-the-park` (own images), `walking-in-the-city` (bench), `at-the-school` (playground), `school-items-2` (swing/fountain, homonym-adjacent), `farm-animals` (duck, dog), `going-to-sports` (ball), `waking-up` (blanket), `at-the-farmers-market` (basket), `family` (family), `hospital-pharmacy-items` (walker), `nature-objects` (bush, hill), `wild-animals-2` (squirrel, bird), `house-parts` (gate, fence, sprinkler), `household-equipment-3` (umbrella), `baby-care` (stroller), `colors-2` (green), `checking-the-weather` (sunny), `dressing-1` (watch — different sense), `insect-world` (fly — different sense)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

**Homonym/different-sense caution:** `watch` (verb) matches `dressing-1/watch.png` (wristwatch, not "to watch"), and `fly` (verb, "to fly a kite") matches `insect-world/fly.png` (the insect). Both listed as USED per the literal rule but flagged since neither PNG teaches the intended sense.

**Correction note:** the prior-words check initially missed `ride` and `wander` because those entries are stored in `translations.json` as full phrases (`"to ride a horse"` from `at-the-farm`, `"to wander around"` from `walking-in-the-city`) rather than the bare verb. Both are corrected below — `ride` moves to USED + HIGH PRIORITY, `wander` moves to USED + RECOMMENDED.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **seesaw** (A1) — Classic playground-equipment noun, currently absent (only `swing`/`slide` are taught)
- **sandbox** (A1) — Pairs with `seesaw`/`slide` as core playground vocabulary
- **bicycle** (A1) — Extremely common park noun, currently absent
- **kite** (A1) — Common park-activity noun
- **picnic** (A1) — Ties directly to the already-tracked "blanket"/family-outing theme (noun form also needed alongside the verb)
- **trash can** (A1) — Common park-infrastructure noun
- **trail** (A1) — Ties to the already-image-taught `path`/`hill`

### Verbs
- **jog** (A1) — Ties to the already-present family/exercise theme
- **kick** (A1) — Common ball-related park verb, pairs with tracked `throw`/`catch`
- **chase** (A2) — Ties to the already-present "The squirrel ran away from me" theme

### Adjectives
- **shady** (A2) — Natural antonym pairing with the already-tracked `sunny`
- **peaceful** (A1) — Common park-atmosphere descriptor
- **colorful** (A1) — Ties to the already-image-taught `flowers`
- **safe** (A1) — Common park-safety descriptor
- **lively** (A2) — Ties to the already-tracked `fun`/`crowded` theme

### Adverbs
- **happily** (A1) — Ties to the already-present "I am so happy!" line
- **freely** (A2) — Common park/outdoor-activity descriptor
- **peacefully** (A2) — Matches the `peaceful` adjective above
- **safely** (A1) — Matches the `safe` adjective above

---

## UNUSED + RECOMMENDED

### Nouns
- jogger, gardener, shade, sunlight, statue, gazebo, lawn, frisbee, skateboard

### Verbs
- picnic, explore

### Adjectives
- playful, relaxing, breezy, grassy, natural, family-friendly

### Adverbs
- playfully, actively, energetically, joyfully, outdoors, casually, leisurely, cheerfully

---

## USED + HIGH PRIORITY

### Nouns
- **bench** — PNG (`walking-in-the-city/bench.png`) + `questions.json` (Q4 distractor)
- **tree** — PNG (`at-the-park/tree.png`) + `questions.json`
- **grass** — PNG (`at-the-park/grass.png`) + `questions.json`
- **path** — `questions.json` (Q10 distractor)
- **playground** — PNG (`at-the-school/playground.png`)
- **swing** — PNG (`at-the-park/swing.png`) + `translations.json` + `questions.json` (Q7)
- **slide** — `questions.json` (Q8 distractor)
- **fountain** — PNG (`at-the-park/fountain.png`) + `questions.json`
- **pond** — `questions.json` (Q4 distractor)
- **duck** — PNG (`farm-animals/duck.png`)
- **dog** — PNG (`farm-animals/dog.png`) + `translations.json` (`what kind of dog`) + `questions.json` (Q15)
- **ball** — PNG (`going-to-sports/ball.png`) + `questions.json` (Q13)
- **family** — PNG (`family/family.png`)
- **children** — `questions.json` (Q7, Q14)
- **flower** — `questions.json` (`flowers` image)
- **bush** — PNG (`nature-objects/bush.png`) + `questions.json` (Q10 distractor)
- **squirrel** — PNG (`wild-animals-2/squirrel.png`) + `questions.json` (Q9 SentenceBuilder)
- **bird** — PNG (`wild-animals-2/bird.png`)
- **gate** — PNG (`house-parts/gate.png`)
- **fence** — PNG (`house-parts/fence.png`)

### Verbs
- **play** — `translations.json` + `questions.json` (Q13 answer)
- **run** — `translations.json` (`to run away`) + `questions.json` (Q9)
- **jump** — `translations.json` + `questions.json` (Q6 answer)
- **swing** — PNG + `translations.json` + `questions.json`
- **slide** — `questions.json`
- **climb** — `translations.json` + `questions.json` (Q11 answer)
- **walk** — prior-words + `questions.json`
- **throw** — `translations.json` + `questions.json` (Q12 answer)
- **catch** — prior-words
- **feed** — prior-words
- **ride** — prior-words (`to ride a horse`, `at-the-farm`)

### Adjectives
- **green** — PNG (`colors-2/green.png`)
- **sunny** — PNG (`checking-the-weather/sunny.png`)
- **fun** — prior-words + `questions.json` (Q7 distractor)
- **open** — prior-words

### Adverbs
*(none rated essential beyond what's reinforced below)*

---

## USED + RECOMMENDED

### Nouns
- **blanket** — PNG (`waking-up/blanket.png`)
- **basket** — PNG (`at-the-farmers-market/basket.png`)
- **walker** — PNG (`hospital-pharmacy-items/walker.png`)
- **sign** — prior-words
- **hill** — PNG (`nature-objects/hill.png`)
- **sprinkler** — PNG (`house-parts/sprinkler.png`)
- **umbrella** — PNG (`household-equipment-3/umbrella.png`)
- **stroller** — PNG (`baby-care/stroller.png`)

### Verbs
- **sit** — prior-words
- **relax** — prior-words
- **fly** — prior-words + PNG (⚠️ different sense — insect)
- **laugh** — prior-words
- **shout** — prior-words
- **rest** — prior-words
- **stretch** — prior-words
- **exercise** — `questions.json` (GrammarForm "gets some exercise")
- **watch** — prior-words + PNG (⚠️ different sense — wristwatch)
- **enjoy** — prior-words
- **gather** — prior-words
- **wander** — prior-words (`to wander around`, `walking-in-the-city`)

### Adjectives
- **crowded** — prior-words
- **quiet** — prior-words
- **spacious** — prior-words
- **fresh** — prior-words
- **clean** — prior-words

### Adverbs
- **quietly** — prior-words
- **together** — prior-words

---

## SUMMARY

- **Total words analyzed:** 106 (44 nouns, 28 verbs, 20 adjectives, 14 adverbs)
- **Unused:** 44 (42%) — 19 High Priority (43%) / 25 Recommended (57%)
- **Used:** 62 (58%) — 36 High Priority (58%) / 26 Recommended (42%)

**Source breakdown for USED words:** `translations.json` (7 words), `questions.json` (~25 words, several overlapping), PNG project-wide (24 words, spanning 18 different level folders — the widest reuse seen in this batch), prior-words-by-type.md equivalent (~15 words, including the corrected `ride`/`wander`).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | seesaw / sandbox | noun | Classic playground equipment, both absent (only swing/slide taught) |
| 2 | bicycle | noun | Extremely common park word, surprisingly absent |
| 3 | kick | verb | Pairs naturally with the already-tracked `throw`/`catch` |
| 4 | chase | verb | Ties directly to the already-present "The squirrel ran away from me" |
| 5 | shady | adjective | Natural antonym of the already-tracked `sunny` |
| 6 | colorful | adjective | Ties to the already-image-taught `flowers` |
| 7 | picnic | noun | Ties to the already-tracked `blanket`, needed as its own word |
| 8 | happily | adverb | Ties to the already-present "I am so happy!" line |
