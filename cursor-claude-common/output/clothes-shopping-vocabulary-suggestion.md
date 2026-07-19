# Clothes Shopping: Vocabulary Suggestions

Generated per the full `VOCABULARY-SUGGESTION-WORKFLOW.md` spec (full-project PNG search, not limited to a single related-theme folder).

**Sources checked:**
1. `prior-words-by-type.md` equivalent — 376 entries from the flow levels before `clothes-shopping` (`gather_prior_level_words.py`)
2. PNG filenames project-wide — searched all 809 PNGs across every level folder, turning up matches in `dressing-1`/`dressing-2` (shirt, coat, belt, sweater, jeans, scarf, hat, gloves), `living-room-items` (mirror), `at-the-bank` (wallet), `household-equipment-3` (iron), `birthday-party` (gift)
3. This level's own `translations.json`
4. This level's own `questions.json` (WordPairs, answers, dialogue, distractors, stems)

**USED** = found in any of the sources above. **UNUSED** = not found in any.

---

## UNUSED + HIGH PRIORITY

### Nouns
- **store** (A1) — Core shopping-location noun, currently absent
- **mall** (A1) — Common shopping-location noun
- **size** (A1) — Directly implied by the "these shoes are too loose" theme, never tracked as a standalone concept
- **fitting room** (A1) — Directly ties to the already-present "try on this coat" theme
- **bag** (A1) — Common shopping item, distinct from tracked `wallet`
- **fabric** (A2) — Core clothing-material concept
- **color** (A1) — Ties to the already-tracked `colorful`
- **button** (A1) — Common clothing-detail noun (as opposed to the verb sense)
- **credit card** (A1) — Ties to the already-present payment/discount theme
- **budget** (A2) — Ties to the "don't want to spend too much" theme already present

### Verbs
- **pick** (A1) — Near-synonym reinforcement for the already-tracked `choose`
- **exchange** (A2) — Natural pairing with the already-tracked `to return something`
- **browse** (A2) — Core shopping-behavior verb
- **afford** (A2) — Ties directly to the "don't want to spend too much"/budget theme

### Adjectives
- **fashionable** (A2) — Core theme-defining adjective, currently absent
- **tight** (A1) — Natural antonym of the already-tracked `loose`
- **uncomfortable** (A2) — Natural antonym of the already-tracked `comfortable`
- **formal** (A1) — Common clothing-style descriptor
- **casual** (A1) — Pairs with `formal`
- **warm** (A1) — Common clothing-quality descriptor
- **cool** (A1) — Pairs with `warm`
- **new** (A1) — Extremely common, currently absent
- **discounted** (A2) — Ties directly to the already-tracked `discount`

### Adverbs
- **carefully** (A1) — General shopping/handling-clothes adverb
- **comfortably** (A2) — Matches the already-tracked `comfortable`
- **affordably** (A2) — Matches the budget/afford theme
- **perfectly** (A1) — Fits the "the perfect gift" theme already present

---

## UNUSED + RECOMMENDED

### Nouns
- sale, rack, cotton, fashion, outfit, pattern, zipper, accessory, underwear, salesperson, coupon, trend, wardrobe

### Verbs
- match, fold, zip, button, unbutton, wrap

### Adjectives
- trendy, stylish, plain, rough, used, oversized, fitted, patterned, popular, unique, elegant, classic

### Adverbs
- casually, stylishly, neatly, nicely, loosely, tightly, happily, confidently

---

## USED + HIGH PRIORITY

### Nouns
- **shirt** — PNG (`dressing-1/shirt.png`) + `questions.json`
- **pants** — PNG (`clothes-shopping/pants.png`) + `questions.json`
- **dress** — PNG (`dressing-2/dress.png`) + `translations.json` + `questions.json`
- **skirt** — `questions.json` (Q9 distractor)
- **jacket** — PNG (`clothes-shopping/jacket.png`) + `questions.json`
- **coat** — PNG (`dressing-1/coat.png`) + `questions.json` (Q2)
- **shoes** — PNG (`clothes-shopping/shoes.png`) + `questions.json`
- **price tag** — `questions.json` (Q6 line1)
- **discount** — `translations.json` + `questions.json` (Q3)
- **hanger** — PNG (`clothes-shopping/hanger.png`) + `questions.json`
- **jeans** — PNG (`dressing-2/jeans.png`)
- **sweater** — PNG (`dressing-1/sweater.png`)
- **scarf** — PNG (`dressing-2/scarf.png`) + `questions.json` (Q14)
- **hat** — PNG (`dressing-2/hat.png`)
- **gloves** — PNG (`dressing-2/gloves.png`)
- **socks** — PNG (`clothes-shopping/socks.png`) + `questions.json`
- **closet** — `questions.json` (Q1 distractor)

### Verbs
- **shop** — prior-words
- **buy** — prior-words
- **try on** — `translations.json`
- **wear** — `translations.json` + `questions.json` (Q13 answer)
- **fit** — `translations.json` + `questions.json` (Q10 SentenceBuilder)
- **return** — `translations.json` (`to return something`) + `questions.json` (Q11 answer)
- **pay** — prior-words + `questions.json`
- **save** — prior-words + `questions.json` (Q3 distractor)
- **spend** — `translations.json` + `questions.json` (Q3 answer)

### Adjectives
- **cheap** — prior-words
- **expensive** — prior-words
- **loose** — `translations.json` + `questions.json` (Q11 answer)
- **comfortable** — prior-words

---

## USED + RECOMMENDED

### Nouns
- **mirror** — PNG (`living-room-items/mirror.png`)
- **cashier** — `questions.json` (Q6 distractor)
- **receipt** — prior-words
- **brand** — prior-words
- **style** — `questions.json` (Q12 GrammarForm: "this style")
- **belt** — PNG (`dressing-1/belt.png`)
- **checkout** — prior-words
- **customer** — prior-words
- **wallet** — PNG (`at-the-bank/wallet.png`)

### Verbs
- **choose** — prior-words
- **compare** — prior-words
- **search** — prior-words
- **style** — `questions.json`
- **hang** — `questions.json` (Q2 distractor)
- **wash** — prior-words
- **iron** — PNG (`household-equipment-3/iron.png`)
- **gift** — PNG (`birthday-party/gift.png`) + `questions.json` (Q14 "gift for my mom")

### Adjectives
- **colorful** — `questions.json` (Q13)
- **soft** — prior-words

### Adverbs
- **quickly** — prior-words
- **easily** — prior-words

---

## SUMMARY

- **Total words analyzed:** 117 (49 nouns, 27 verbs, 27 adjectives, 14 adverbs)
- **Unused:** 66 (56%) — 27 High Priority (41%) / 39 Recommended (59%)
- **Used:** 51 (44%) — 30 High Priority (59%) / 21 Recommended (41%)

**Source breakdown for USED words:** `translations.json` (9 words), `questions.json` (~20 words, several overlapping), PNG project-wide (16 words, spanning `dressing-1`, `dressing-2`, `clothes-shopping`, `living-room-items`, `at-the-bank`, `household-equipment-3`, `birthday-party`), prior-words-by-type.md equivalent (~15 words).

### Top picks to add next
| Priority | Word | POS | Why |
|---|---|---|---|
| 1 | size | noun | Directly implied by "these shoes are too loose" but never tracked |
| 2 | fitting room | noun | Ties directly to the already-present "try on this coat" theme |
| 3 | tight | adjective | Natural antonym of the already-tracked `loose` |
| 4 | uncomfortable | adjective | Natural antonym of the already-tracked `comfortable` |
| 5 | discounted | adjective | Adjective form of the already-tracked `discount` |
| 6 | afford / budget | verb/noun | Direct tie to "don't want to spend too much" theme |
| 7 | exchange | verb | Natural pairing with the already-tracked `to return something` |
| 8 | fashionable | adjective | Core theme-defining word, surprisingly absent |
