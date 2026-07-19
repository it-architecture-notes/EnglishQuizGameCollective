# Going to Sports: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder). **Prior-words matching was corrected this run**: earlier levels store full phrases in `translations.json` (e.g. `"to play"`, `"to run away"`, `"fast"`) rather than bare words, so this check now uses word-boundary matching against the full phrase instead of exact/prefixed matching only (see the `at-the-park` correction from earlier this session).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 521 entries from the flow levels before `going-to-sports` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `going-to-sports` (own images), `city-buildings-2` (stadium), `at-the-school` (gym), `walking-in-the-city` (bench), `dressing-2` (tie — clothing item, different sense, see caution below), `vehicles` (train — different sense, see caution below)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

**Homonym/different-sense caution:** `tie` (noun, "a tied match") matches `dressing-2/tie.png` (the clothing accessory) — different sense, but the level's own `questions.json`/GrammarForm context ("the game ended in a draw") does teach the sports sense directly, so this is a non-issue in practice. Similarly `train` (verb, "to train") matches `vehicles/train.png` (the vehicle) — no PNG actually teaches the verb sense; listed as USED via that PNG match per the literal rule but flagged since it wouldn't really teach "to train."

---

## UNUSED + HIGH PRIORITY

### Nouns
- **team** (A1) — Core sports-theme noun, currently absent
- **player** (A1) — Extremely common sports-role noun
- **coach** (A1) — Common sports-role noun, pairs with `referee`
- **referee** (A2) — Common sports-role noun
- **field** (A1) — Core sports-location noun, pairs with the already-image-taught `swimming-pool`
- **court** (A1) — Common sports-location noun (tennis/basketball)
- **point** (A1) — Ties to the already-tracked `score`/`goal` theme
- **uniform** (A2) — Common sports noun, ties to `jersey`
- **fan** (A1) — Common sports-culture noun
- **opponent** (A2) — Ties to the already-present "he lost"/competition theme

### Verbs
- **kick** (A1) — Extremely common sports verb, currently absent (image `ball` exists but the action isn't taught)
- **compete** (A2) — Core theme-defining verb for a "going to sports" level
- **cheer** (A1) — Ties to the already-present fan/crowd theme
- **exercise** (A1) — Extremely common, ties to the already-tracked `sweat`/`swim`
- **shoot** (A1) — Common sports verb (goal-scoring)

### Adjectives
- **competitive** (A2) — Core theme-defining adjective, currently absent
- **athletic** (A2) — Common sports-descriptor adjective
- **strong** (A1) — Extremely common sports-quality descriptor
- **skilled** (A2) — Ties to the already-present "improve my swimming skills" theme
- **exciting** (A1) — Common sports-atmosphere descriptor
- **fair** (A1) — Ties to the already-image-taught `referee`/`whistle` theme

### Adverbs
- **strongly** (A2) — Matches the `strong` adjective above
- **skillfully** (A2) — Matches the `skilled` adjective above
- **confidently** (A2) — Common sports-performance adverb
- **successfully** (A2) — Ties to the already-present win/score theme

---

## UNUSED + RECOMMENDED

### Nouns
- championship, tournament, jersey, crowd, cheer, trophy, training, equipment, racket, locker room, scoreboard, victory, defeat, season, league, captain

### Verbs
- coach, referee, support, warm up, tackle, dribble

### Adjectives
- exhausted, energetic, unfair, intense, professional, amateur, victorious, defeated, physical, active, disciplined, teamwork-oriented

### Adverbs
- energetically, competitively, fairly, actively, aggressively, calmly

---

## USED + HIGH PRIORITY

### Nouns
- **ball** — PNG (`going-to-sports/ball.png`) + `questions.json`
- **stadium** — PNG (`city-buildings-2/stadium.png`)
- **gym** — PNG (`at-the-school/gym.png`) + `questions.json` (Q7 distractor)
- **match** — prior-words (`to match`, `clothes-shopping`)
- **game** — `questions.json` (Q13, GrammarForm)
- **score** — `translations.json` (`to score`)
- **goal** — `questions.json` (`goal-post`)
- **whistle** — PNG (`going-to-sports/whistle.png`) + `questions.json`
- **practice** — `translations.json` + `questions.json` (Q2 answer)
- **net** — `questions.json` (Q10 distractor, `volleyball-net`)
- **helmet** — `questions.json` (Q4 distractor)

### Verbs
- **play** — prior-words (`to play`, `at-the-park`) + `questions.json` (Q2 distractor)
- **run** — prior-words (`to run away`, `at-the-park`) + `questions.json` (Q3 "did you win the race", Q7 "run fast")
- **jump** — prior-words (`to jump`, `at-the-park`)
- **throw** — prior-words (`to throw`, `at-the-park`)
- **catch** — prior-words (`to catch`, `at-the-train-station`)
- **score** — `translations.json`
- **win** — `questions.json` (Q3 "Did you win the race?")
- **lose** — prior-words (`to lose`, `at-the-post-office`) + `questions.json` (Q15 "he would lose the race")
- **practice** — `translations.json` + `questions.json`
- **hit** — `translations.json` + `questions.json` (Q9 SentenceBuilder)
- **swim** — `translations.json` + `questions.json` (Q6, Q11)

### Adjectives
- **fast** — prior-words (`fast`, `at-the-train-station`) + `questions.json` (Q7 "run fast")

### Adverbs
*(none rated essential beyond what's reinforced below)*

---

## USED + RECOMMENDED

### Nouns
- **bench** — PNG (`walking-in-the-city/bench.png`)
- **tie** — PNG (⚠️ different sense — clothing) + `questions.json` (Q14 "the game ended in a draw")

### Verbs
- **tie** — PNG (⚠️ different sense)
- **train** — PNG (⚠️ different sense — vehicle)
- **stretch** — prior-words (`to stretch`, `waking-up`)
- **pass** — prior-words (`to pass`, `at-the-traffic`) + `questions.json` (Q9 "the game ended... he scored")
- **serve** — prior-words (`to serve`, `at-the-restaurant`)
- **race** — `translations.json` + `questions.json` (Q3, Q15)
- **sweat** — `translations.json` + `questions.json` (Q6 AppearDisappear)
- **celebrate** — prior-words (`to celebrate`, `birthday-party`)

### Adjectives
- **tired** — prior-words (`tired`, `in-the-bedroom`)

### Adverbs
- **quickly** — prior-words (`quickly`, `waking-up`)
- **together** — prior-words (`together`, `birthday-party`)
- **hard** — prior-words (`hard`, `baby-care`)
- **well** — prior-words (`I am very well`, `greetings`)

---

## SUMMARY

- **Total words analyzed:** 103 (39 nouns, 30 verbs, 20 adjectives, 14 adverbs)
- **Unused:** 65 (63%) — 25 High Priority (38%) / 40 Recommended (62%)
- **Used:** 38 (37%) — 24 High Priority (63%) / 14 Recommended (37%)

**Source breakdown for USED words:** `translations.json` (11 words), `questions.json` (~16 words, several overlapping), PNG project-wide (7 words, spanning `going-to-sports`, `city-buildings-2`, `at-the-school`, `walking-in-the-city`, `dressing-2`, `vehicles`), prior-words-by-type.md equivalent (~14 words, using corrected phrase-matching).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | team / player | noun | Core sports-theme nouns, both completely absent |
| 2 | kick | verb | Extremely common sports verb; the `ball` image exists but this action doesn't |
| 3 | coach / referee | noun | Core sports-role nouns, currently absent |
| 4 | competitive | adjective | Core theme-defining word for a sports level, currently absent |
| 5 | field / court | noun | Core sports-location nouns, pair with the already-taught `swimming-pool` |
| 6 | compete | verb | Core theme-defining verb, currently absent |
| 7 | fair | adjective | Ties directly to the already-image-taught `referee`/`whistle` |
| 8 | cheer | verb | Ties to the already-present fan/crowd/celebration theme |
