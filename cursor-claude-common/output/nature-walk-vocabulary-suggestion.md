# Nature Walk: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 395 entries from the flow levels before `nature-walk` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `nature-objects` (mountain, hill, lake, leaf), `at-the-park` (tree, grass, sun), `wild-animals-1`/`wild-animals-2` (animal, bird), `checking-the-weather` (wind, sunny), `school-items-2` (backpack), `dressing-1` (boots), `walking-in-the-city` (bench), `city-buildings-1` (bridge), `colors-2` (folder exists but no exact `colorful.png` — correctly not counted)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **trail** (A1) — Core theme-defining noun ("nature walk" implies a trail), currently absent
- **path** (A1) — Near-synonym of `trail`, equally core
- **sky** (A1) — Extremely common outdoor noun, surprisingly absent
- **cloud** (A1) — Pairs with `sky`
- **map** (A1) — Essential hiking-navigation object
- **nature** (A1) — The level's own theme word, never explicitly tracked
- **air** (A1) — Common outdoor-atmosphere noun
- **view** (A1) — Common hiking/scenic noun
- **hiker** (A2) — Core role-noun for this level's theme
- **flower** (A1) — Extremely common nature noun, surprisingly absent

### Verbs
- **hike** (A1) — The level's own theme verb, never tracked
- **climb** (A1) — Core nature-walk action
- **explore** (A2) — Core nature-walk action
- **breathe** (A1) — Ties to the "fresh air"/peaceful theme
- **listen** (A1) — Ties directly to the already-present "I can only hear the wind" theme
- **observe** (A2) — Ties to the "spot an animal" theme already implied
- **discover** (A2) — Common exploration verb

### Adjectives
- **peaceful** (A1) — Core theme-defining adjective, ties to already-tracked `quiet`/`calm`
- **natural** (A1) — Adjective form of the already-untracked `nature` noun above
- **beautiful** (A1) — Extremely common scenic descriptor
- **rocky** (A2) — Ties to the already-tracked `rock`
- **steep** (A2) — Common trail-terrain descriptor
- **cool** (A1) — Common weather descriptor for outdoor scenes
- **warm** (A1) — Pairs with `cool`

### Adverbs
- **peacefully** (A1) — Matches the `peaceful` adjective above
- **deeply** (A2) — Fits the "breathe deeply" nature-walk cliché
- **naturally** (A2) — Adjective-matching adverb
- **closely** (A2) — Fits the "observe closely" theme

---

## UNUSED + RECOMMENDED

### Nouns
- stream, insect, breeze, shade, sunlight, compass, water bottle, waterfall, meadow, wildlife, silence, nest, branch, root, pinecone, mud, dirt, horizon, campsite

### Verbs
- wander, sit, photograph, admire, spot, pause, camp, picnic, relax, escape

### Adjectives
- scenic, refreshing, muddy, shady, breezy, colorful, tiny, vast, remote, tranquil, wooded

### Adverbs
- freely, calmly, happily, mindfully, steadily, joyfully

---

## USED + HIGH PRIORITY

### Nouns
- **forest** — PNG (`nature-walk/forest.png`) + `questions.json` (Q1, Q9)
- **tree** — PNG (`at-the-park/tree.png`) + `questions.json` (Q6)
- **mountain** — PNG (`nature-objects/mountain.png`)
- **hill** — PNG (`nature-objects/hill.png`)
- **river** — PNG (`nature-walk/river.png`) + `questions.json` (Q9/Q10)
- **lake** — PNG (`nature-objects/lake.png`) + `questions.json` (Q8/Q9 distractors)
- **rock** — `questions.json` (Q11 distractor "stones")
- **leaf** — PNG (`nature-objects/leaf.png`)
- **animal** — PNG (`wild-animals-1/animal.png`) + `questions.json` (Q6, Q12)
- **sun** — PNG (`at-the-park/sun.png`)
- **wind** — PNG (`checking-the-weather/wind.png`) + `questions.json` (Q2)
- **valley** — `questions.json` (Q8 distractor)

### Verbs
- **walk** — prior-words + `questions.json`
- **touch** — `translations.json` + `questions.json` (Q7)
- **collect** — `translations.json` (Q3 answer "collecting")
- **smell** — prior-words + `questions.json` (Q7 distractor)

### Adjectives
- **quiet** — prior-words + `translations.json` + `questions.json` (Q2 answer)
- **green** — PNG (`colors-2/green.png`)
- **wild** — `translations.json` + `questions.json` (Q7 "wild plants")
- **calm** — `translations.json` + `questions.json` (Q12 answer)
- **sunny** — PNG (`checking-the-weather/sunny.png`)

### Adverbs
- **carefully** — `questions.json` (Q14 distractor)

---

## USED + RECOMMENDED

### Nouns
- **grass** — PNG (`at-the-park/grass.png`)
- **bird** — PNG (`wild-animals-2/bird.png`)
- **backpack** — PNG (`school-items-2/backpack.png`)
- **boots** — PNG (`dressing-1/boots.png`)
- **bench** — PNG (`walking-in-the-city/bench.png`)
- **bridge** — PNG (`city-buildings-1/bridge.png`)

### Verbs
- **rest** — prior-words
- **stretch** — prior-words
- **cross** — prior-words
- **follow** — prior-words
- **connect** — prior-words

### Adjectives
- **fresh** — prior-words
- **tall** — `questions.json` (Q6 distractor "too tall")

### Adverbs
- **quietly** — prior-words
- **slowly** — prior-words + `questions.json` (Q14 distractor)
- **gently** — prior-words

---

## SUMMARY

- **Total words analyzed:** 112 (47 nouns, 26 verbs, 25 adjectives, 14 adverbs)
- **Unused:** 74 (66%) — 28 High Priority (38%) / 46 Recommended (62%)
- **Used:** 38 (34%) — 22 High Priority (58%) / 16 Recommended (42%)

**Source breakdown for USED words:** `translations.json` (5 words), `questions.json` (~16 words, several overlapping), PNG project-wide (17 words, spanning `nature-objects`, `at-the-park`, `wild-animals-1`/`-2`, `checking-the-weather`, `school-items-2`, `dressing-1`, `walking-in-the-city`, `city-buildings-1`, `colors-2`), prior-words-by-type.md equivalent (~10 words).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | trail / path | noun | Core theme-defining nouns, surprisingly absent from a "nature walk" level |
| 2 | hike | verb | The level's own theme verb, never tracked |
| 3 | nature / natural | noun/adjective | The level's own theme word, never explicitly tracked |
| 4 | listen | verb | Directly ties to the already-present "I can only hear the wind" line |
| 5 | peaceful / peacefully | adjective/adverb | Ties to already-tracked `quiet`/`calm` |
| 6 | sky / cloud | noun | Extremely common outdoor nouns, both absent |
| 7 | climb / explore | verb | Core nature-walk actions, currently untaught |
| 8 | beautiful | adjective | Extremely common scenic descriptor, surprisingly absent |
