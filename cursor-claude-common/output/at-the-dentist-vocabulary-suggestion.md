# At the Dentist: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder), using the corrected prior-words matching (word-boundary against full phrases).

**Re-run note:** the level's `questions.json`/`translations.json` changed on disk between the first run and this one — `to floss`, `to extract`, `to bite`, and `sensitivity` were added directly (several match the previous run's top picks), and the dialogue content shifted to a new "frozen from the anesthesia" / gauze-bite theme. This version reflects the current on-disk state.

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 588 entries from the flow levels before `at-the-dentist` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `at-the-dentist` (own images), `jobs-2` (dentist), `body-parts-1` (mouth), `living-room`/`living-room-items` (chair, mirror), `in-the-bathroom` (toothbrush), `grocery-list-2` (toothpaste), `household-equipment-2` (drill), `dressing-2` (gloves), `emotions-1`/`emotions-2` (nervous, scared, healthy), `colors-1` (white, yellow), `greetings` (smile), `at-the-restaurant` (bill)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

**Near-miss note:** `sensitive` (adjective) is marked UNUSED under strict word-boundary matching, but `translations.json` now has `sensitivity` (the noun form, from the new "I have been feeling some sensitivity" line) — the concept is present, just not as the adjective form. Also `numb` is UNUSED despite the thematically-close `frozen` ("it's just frozen from the anesthesia") — different word, correctly kept separate.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **checkup** (A1) — Ties directly to the already-present "appointment to clean my teeth" theme
- **cavity** (A2) — Core theme-defining noun, currently absent
- **x-ray** (A1) — Common dental-procedure noun
- **mouthwash** (A2) — Common dental-hygiene noun, pairs with the now-taught `floss`
- **receptionist** (A1) — Common role noun for a dental office

### Verbs
- **chew** (A1) — Pairs with the now-taught `to bite`

### Adjectives
- **painful** (A2) — Ties directly to the already-tracked `pain`
- **sensitive** (A2) — Adjective form of the now-present `sensitivity` noun — natural quick add
- **sore** (A2) — Ties to the already-present "gums are swollen" theme
- **straight** (A1) — Natural antonym pairing opportunity for teeth-alignment (braces already image-taught)

### Adverbs
- **calmly** (A2) — Matches the already-tracked `calm`
- **painfully** (A2) — Matches the already-tracked `pain`/`hurt`

---

## UNUSED + RECOMMENDED

### Nouns
- dental hygienist, mask, waiting room, brace, plaque, decay, bib, insurance

### Verbs
- numb, ache

### Adjectives
- unhealthy, crooked, numb

### Adverbs
- thoroughly, nervously

---

## USED + HIGH PRIORITY

### Nouns
- **dentist** — PNG (`jobs-2/dentist.png`) + `questions.json`
- **tooth** — PNG (`at-the-dentist/tooth.png`) + `questions.json`
- **teeth** — prior-words (`to brush teeth`, `in-the-bathroom`) + `questions.json`
- **gum** — `questions.json` (Q1 distractor, Q3, Q5)
- **mouth** — PNG (`body-parts-1/mouth.png`) + `questions.json` (Q2)
- **appointment** — `translations.json` + `questions.json` (Q9 GrammarForm)
- **filling** — PNG (`at-the-dentist/filling.png`) + `questions.json`
- **toothbrush** — PNG (`in-the-bathroom/toothbrush.png`)
- **toothpaste** — PNG (`grocery-list-2/toothpaste.png`)
- **floss** — `translations.json` (`to floss`) + `questions.json` (Q3 "when I do not floss")
- **braces** — PNG (`at-the-dentist/braces.png`) + `questions.json`
- **extraction** — PNG (`at-the-dentist/extraction.png`) + `questions.json`
- **root canal** — PNG (`at-the-dentist/root-canal.png`)
- **crown** — `questions.json` (Q5 distractor)
- **pain** — prior-words (`pain`, `at-the-hospital`)

### Verbs
- **brush** — prior-words (`to brush teeth`, `in-the-bathroom`) + `questions.json` (Q12)
- **floss** — `translations.json` + `questions.json` (Q3 answer)
- **rinse** — `questions.json` (Q2 distractor)
- **open** — prior-words (`to open`, `waking-up`) + `translations.json` (`open wide`) + `questions.json` (Q2, Q9)
- **examine** — prior-words (`to examine`, `at-the-hospital`)
- **check** — prior-words (`to check in`, `at-the-hotel`)
- **fill** — prior-words (`fill in a form`, `at-the-bank`) + `questions.json` (Q9 distractor)
- **extract** — `translations.json` + `questions.json` (Q9 answer)
- **treat** — prior-words (`to treat`, `at-the-hospital`)
- **hurt** — prior-words (`hurt`, `at-the-hospital`)
- **bite** — `translations.json` + `questions.json` (Q7 answer "bite firmly")

### Adjectives
- **healthy** — PNG (`emotions-2/healthy.png`)
- **sharp** — prior-words (`sharp`, `in-the-kitchen`) + `questions.json` (WordPairs, Q8 distractor)
- **white** — PNG (`colors-1/white.png`) + `questions.json` (WordPairs)
- **yellow** — PNG (`colors-1/yellow.png`) + `questions.json` (WordPairs)

### Adverbs
- **carefully** — `questions.json` (Q12 "brush my teeth carefully")

---

## USED + RECOMMENDED

### Nouns
- **chair** — PNG (`living-room/chair.png`)
- **drill** — PNG (`household-equipment-2/drill.png`)
- **gloves** — PNG (`dressing-2/gloves.png`)
- **light** — prior-words (`turn on the light`, `in-the-bedroom`)
- **mirror** — prior-words (`to look in the mirror`, `in-the-bathroom`) + PNG (`living-room-items/mirror.png`)
- **cleaning** — `questions.json` (Q5 distractor)
- **bill** — prior-words (`split the bill`, `at-the-restaurant`) + PNG (`at-the-restaurant/bill.png`)

### Verbs
- **clean** — prior-words (`to clean`, `in-the-bathroom`) + `questions.json` (Q9 distractor)
- **drill** — PNG
- **smile** — prior-words (`to smile`, `baby-care`) + PNG (`greetings/smile.png`)
- **schedule** — prior-words (`to schedule`, `at-the-office`)
- **cancel** — prior-words (`to cancel`, `at-the-airport`)
- **ask** — prior-words (`to ask a question`, `at-the-school`)
- **explain** — prior-words (`to explain`, `at-the-pharmacy`)
- **recommend** — prior-words (`to recommend`, `at-the-cinema`)
- **advise** — prior-words (`to advise`, `at-the-pharmacy`)

### Adjectives
- **clean** — prior-words (`to clean`, `in-the-bathroom`) + `questions.json` (WordPairs)
- **dirty** — prior-words (`dirty`, `in-the-bathroom`)
- **gentle** — prior-words (`gentle`, `baby-care`)
- **careful** — prior-words (`careful`, `at-the-hospital`)
- **nervous** — PNG (`emotions-1/nervous.png`)
- **scared** — PNG (`emotions-2/scared.png`)
- **calm** — prior-words (`calm`, `nature-walk`)

### Adverbs
- **gently** — prior-words (`gently`, `baby-care`)
- **quickly** — prior-words (`quickly`, `waking-up`)
- **regularly** — prior-words (`regularly`, `in-the-bathroom`)
- **twice** — prior-words (`twice a week`, `at-the-park`)
- **patiently** — prior-words (`patiently`, `at-the-train-station`)
- **slowly** — prior-words (`slowly`, `in-the-kitchen`)

---

## SUMMARY

- **Total words analyzed:** 87 (35 nouns, 23 verbs, 18 adjectives, 11 adverbs)
- **Unused:** 27 (31%) — 12 High Priority (44%) / 15 Recommended (56%)
- **Used:** 60 (69%) — 31 High Priority (52%) / 29 Recommended (48%)

**Source breakdown for USED words:** `translations.json` (5 words), `questions.json` (~24 words, several overlapping), PNG project-wide (14 words, spanning `at-the-dentist`, `jobs-2`, `body-parts-1`, `living-room`/`living-room-items`, `in-the-bathroom`, `grocery-list-2`, `household-equipment-2`, `dressing-2`, `emotions-1`/`emotions-2`, `colors-1`, `greetings`, `at-the-restaurant`), prior-words-by-type.md equivalent (~22 words, using corrected phrase-matching).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | cavity | noun | Core theme-defining word for a dentist level, still absent |
| 2 | sensitive | adjective | Adjective form of the now-present `sensitivity` noun — natural quick add |
| 3 | checkup | noun | Ties directly to the already-present "appointment to clean my teeth" line |
| 4 | painful / sore | adjective | Both tie directly to the already-tracked `pain`/"gums are swollen" |
| 5 | mouthwash | noun | Common dental-hygiene noun, pairs with the now-taught `floss` |
| 6 | chew | verb | Pairs naturally with the now-taught `to bite` |
| 7 | x-ray | noun | Common dental-procedure noun, still absent |
| 8 | straight | adjective | Natural antonym pairing opportunity, ties to the already-image-taught `braces` |
