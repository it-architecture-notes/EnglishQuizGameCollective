# At the Farm: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec — all checks performed via grep/direct file read for every word.

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 322 entries from the flow levels before `at-the-farm` (`gather_prior_level_words.py`)
2. PNG filenames in `app/assets/quiz-data/levels/at-the-farm/`: `barn`, `hose`, `rake`, `shovel`, `tractor`, `wheelbarrow`
3. Related-theme PNGs — `app/assets/quiz-data/levels/farm-animals/`: `bee`, `bull`, `cat`, `chicken`, `cow`, `dog`, `donkey`, `duck`, `goat`, `goose`, `horse`, `pig`, `rabbit`, `rooster`, `sheep`, `turkey`; plus a broader whole-project PNG search (corrected after an initial miss): `grocery-list-1/eggs.png`, `grocery-shopping/milk.png`, `vegetables-2/corn.png`, `house-parts/fence.png`
4. This level's own `translations.json`
5. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of sources 1–5. **UNUSED** = not found in any.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **field** (A1) — Core farm-location noun, currently absent
- **crop** (A2) — General term for what's grown, ties to tracked `to grow`
- **fence** (A1) — Essential farm-boundary object
- **hay** (A1) — Classic farm material, no current representation
- **soil** (A1) — Core "what you plant in" concept
- **seed** (A1) — Ties directly to the already-tracked `to plant something`
- **harvest** (A2) — Noun form matching the harvest/pick-apples theme already present
- **vegetable** (A1) — Directly referenced in Q2 ("They grow vegetables...") but never tracked as a standalone word
- **fruit** (A1) — Ties to the already-tracked "pick apples" concept
- **garden** (A1) — Common farm-adjacent location
- **wheat** (A2) — Common crop noun

### Verbs
- **harvest** (A2) — Ties to the "pick apples next week" theme already present
- **dig** (A1) — Common farm-labor verb
- **graze** (A2) — Directly ties to the already-tracked "fresh pasture" concept
- **collect** (A1) — Ties to the implied "keep chickens"/eggs concept
- **build** (A1) — Common farm-labor verb
- **wake** (A1) — Ties to the farm's "early rising" theme (many of your adverb candidates are about `early`)

### Adjectives
- **green** (A1) — Classic farm/field descriptor, currently absent
- **fertile** (A2) — Directly ties to soil/growing theme
- **healthy** (A1) — Fits animal/crop-condition theme
- **sunny** (A1) — Common weather descriptor for outdoor farm scenes
- **rainy** (A1) — Natural pairing with `sunny`
- **muddy** (A2) — Fits the farm setting well (fields, animal pens)

### Adverbs
- **carefully** (A1) — Fits animal-handling / tool-use themes already present
- **patiently** (A2) — Fits animal-care theme

---

## UNUSED + RECOMMENDED

### Nouns
- farmhouse, straw, orchard, pond, well, shed, silo, plow, wool, trough, gate, scarecrow, tool, wagon, greenhouse, stable, coop, bale, manure, irrigation

### Verbs
- plow, weed, herd, breed, shear, sow, till, fertilize, repair, care

### Adjectives
- rural, wide, hardworking, peaceful, organic, natural, hilly, flat, spacious, dusty, golden, seasonal, wild, tame

### Adverbs
- hardly, naturally, closely, steadily, peacefully, diligently, seasonally

---

## USED + HIGH PRIORITY

### Nouns
- **farmer** — source: `questions.json` (Q9 SentenceBuilder: "Farmers work hard...")
- **barn** — source: PNG (`barn.png`) + `questions.json`
- **tractor** — source: PNG (`tractor.png`) + `questions.json`
- **cow** — source: related-theme PNG (`farm-animals/cow.png`) + `questions.json` text
- **pig** — source: related-theme PNG
- **chicken** — source: related-theme PNG + `questions.json` ("keep chickens")
- **horse** — source: related-theme PNG + `translations.json` (`to ride a horse`)
- **sheep** — source: related-theme PNG
- **goat** — source: related-theme PNG + `questions.json` ("raise the baby goats")
- **duck** — source: related-theme PNG
- **rooster** — source: related-theme PNG
- **pasture** — source: `questions.json` (Q11: "fresh pasture")
- **egg** — source: PNG (`grocery-list-1/eggs.png`) — also implied by "keep chickens" (Q2)
- **milk** — source: PNG (`grocery-shopping/milk.png`)
- **corn** — source: PNG (`vegetables-2/corn.png`)

### Verbs
- **plant** — source: `translations.json` (`to plant something`) + `questions.json` (Q14 answer)
- **grow** — source: `translations.json` + `questions.json` (Q2 answer)
- **water** — source: `questions.json` (Q3 "water-tap"/"water-pipe"/"water-mill")
- **feed** — source: prior-words
- **ride** — source: `translations.json` (`to ride a horse`) + `questions.json` (Q6 answer)
- **raise** — source: `translations.json` (`to raise something`) + `questions.json` (Q13 answer)
- **gather** — source: `questions.json` (Q3 distractor)
- **work** — source: `questions.json` (Q9 SentenceBuilder)
- **milk** (verb sense) — source: PNG (`grocery-shopping/milk.png`, same lemma)

### Adjectives
- **dry** — source: prior-words
- **fresh** — source: prior-words + `questions.json` (Q11 "fresh pasture")
- **ripe** — source: prior-words

### Adverbs
- **daily** — source: `translations.json` + `questions.json` (Q11 answer)

---

## USED + RECOMMENDED

### Nouns
- **feed** (as noun) — prior-words
- **dog** — related-theme PNG
- **cat** — related-theme PNG
- **fence** — source: PNG (`house-parts/fence.png`)

### Verbs
- **drive** — prior-words + `questions.json` (Q6 distractor "drive the horses")
- **clean** — prior-words
- **rest** — prior-words
- **load** — prior-words
- **unload** — prior-words
- **deliver** — prior-words + `questions.json` (Q2 distractor)

### Adjectives
- **wet** — prior-words
- **early** — prior-words
- **quiet** — prior-words

### Adverbs
- **early** — prior-words
- **gently** — prior-words
- **quietly** — prior-words
- **quickly** — prior-words
- **slowly** — prior-words + `questions.json` (Q13 distractor)
- **regularly** — prior-words

---

## SUMMARY

- **Total words analyzed:** 122 (49 nouns, 31 verbs, 26 adjectives, 16 adverbs)
- **Unused:** 75 (61%) — 24 High Priority (32%) / 51 Recommended (68%)
- **Used:** 47 (39%) — 28 High Priority (60%) / 19 Recommended (40%)

**Source breakdown for USED words:** `translations.json` (7 words), `questions.json` (21 words, several overlapping), related-theme PNG (`farm-animals/`) (9 words), level PNG (2 words: `barn`, `tractor`), other-level PNG matches found on a broader search (5 words: `egg`, `milk` ×2, `corn`, `fence`), prior-words-by-type.md equivalent (17 words).

**Correction note:** an initial pass only checked the `farm-animals/` related-theme folder for images and missed several PNGs that exist in *other* unrelated level folders (`egg` → `grocery-list-1/eggs.png`, `milk` → `grocery-shopping/milk.png`, `corn` → `vegetables-2/corn.png`, `fence` → `house-parts/fence.png`). These four have been moved from UNUSED to USED accordingly. `vegetable`, `wheat`, `hay`, `soil`, `seed`, `garden`, `field`, `crop`, and `harvest` were re-checked and confirmed to have no PNG anywhere in the project.

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | seed | noun | Direct pair with tracked `to plant something` |
| 2 | vegetable | noun | Literally in the level's own text (Q2) but never tracked |
| 3 | harvest | noun/verb | Ties to the already-present "pick apples" theme |
| 4 | graze | verb | Directly ties to the already-tracked "fresh pasture" |
| 5 | fertile / soil | adjective/noun | Core growing-theme vocabulary, currently untaught |
| 6 | sunny / rainy | adjective | Natural weather pairing for outdoor farm scenes |
| 7 | field / crop | noun | Core farm-location/output nouns, still genuinely absent |
| 8 | wheat / garden | noun | Common farm nouns, still genuinely absent |
