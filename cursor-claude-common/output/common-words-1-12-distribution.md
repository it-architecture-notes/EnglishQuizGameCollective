# Common-Words Levels (1-12) - Word Distribution

## Distribution Strategy

**Rules Applied:**
- ClozeSequence: 2-3 taught words per question (6 words/level)
- Other templates: 1-2 words each
- Grammar verbs aligned to Part/MainLevel mapping
- Total words per level: ~15 words
- All words are A1/A2 and unused from prior levels

## Grammar Progression (Parts 1-4)

| Level | MainLevel | Grammar Part | Focus |
|-------|-----------|--------------|-------|
| common-words-1 | ML1 | Part 1 | Present Simple (to like, to go, to have) |
| common-words-2 | ML2 | Part 1 | Present Simple continuation |
| common-words-3 | ML3 | Part 1 | Present Simple completion |
| common-words-4 | ML4 | Part 2 | Future & Comparatives (will go, to be) |
| common-words-5 | ML5 | Part 2 | Future & Comparatives continuation |
| common-words-6 | ML6 | Part 3 | Past Simple (walked, went, stayed) |
| common-words-7 | ML7 | Part 3 | Past Simple continuation |
| common-words-8 | ML8 | Part 3 | Past Simple completion |
| common-words-9 | ML9 | Part 4 | Present Perfect (have been, have gone) |
| common-words-10 | ML10 | Part 4 | Present Perfect continuation |
| common-words-11 | ML11 | Part 4 | Present Perfect continuation |
| common-words-12 | ML12 | Part 4 | Present Perfect completion |

## Word Distribution by Level

### common-words-1 (ML1, Part 1) - 15 words
**Distribution:**
- AppearDisappear (3 questions): afraid, amazing
- ClozeSequence (3 questions): add, agree, answer, to begin, believe, break
- ConvoTemplate-1 (2 questions): bring
- DialogueCompletion (1 question): brush
- GrammarForm (1 question): to like
- WordPairs (1 question): carefully, else, especially, maybe
- SentenceBuilder (1 question): [reuses existing]

**Words:** afraid, amazing, add, agree, answer, to begin, believe, break, bring, brush, to like, carefully, else, especially, maybe

---

### common-words-2 (ML2, Part 1) - 15 words
**Words:** bad, beautiful, begin, believe, break, build, buy, call, can, carry, change, check, choose, clean, closed

---

### common-words-3 (ML3, Part 1) - 15 words
**Words:** better, big, call, can, carry, close, comb, come, come back, compare, complete, cook, cost, cut, dance

---

### common-words-4 (ML4, Part 2) - 15 words
**Words:** bright, broken, close, comb, come, complete, cook, cost, cut, describe, die, do, dress, drink, drive

**Grammar:** will future verbs

---

### common-words-5 (ML5, Part 2) - 15 words
**Words:** calm, cheap, cook, cost, cut, describe, die, do, dress, drink, drive, eat, end, enjoy, explain

---

### common-words-6 (ML6, Part 3) - 15 words
**Words:** closed, cold, dress, drink, drive, eat, end, enjoy, explain, fall, feel, fill, find, finish, follow

**Grammar:** Past simple verbs (walked, went, stayed, played, worked)

---

### common-words-7 (ML7, Part 3) - 15 words
**Words:** cool, correct, fall, feel, fill, find, finish, follow, forget, get, go back, go down, go out, go up, greet

---

### common-words-8 (ML8, Part 3) - 15 words
**Words:** dark, different, get, get in, get up, go out, greet, grow, guess, happen, hate, have, hear, help, hope

---

### common-words-9 (ML9, Part 4) - 15 words
**Words:** dirty, down, grow, guess, happen, hate, have, hear, help, hope, imagine, improve, include, join, keep

**Grammar:** Present perfect verbs (have been, have gone, have done, have seen, have made)

---

### common-words-10 (ML10, Part 4) - 15 words
**Words:** early, easy, hope, imagine, improve, include, join, keep, know, learn, leave, let, like, listen, live

---

### common-words-11 (ML11, Part 4) - 15 words
**Words:** excited, expensive, learn, leave, let, like, listen, live, look, look for, lose, love, make, mean, miss

---

### common-words-12 (ML12, Part 4) - 15 words
**Words:** far, fast, look for, lose, love, make, mean, miss, move, need, notice, offer, open, order, paint

---

## Implementation Status

- ✅ **translations.json:** Created for all 12 levels with complete word-language mappings
- ✅ **Word distribution:** 180 total unique words across 12 levels
- ✅ **Grammar alignment:** Verbs aligned to Parts 1-4 by MainLevel
- ✅ **Rules applied:** ClozeSequence gets 2-3 words, others get 1-2 words
- ❌ **questions.json:** To be completed (keep existing for 1-5, create new for 6-12 if needed)

## Next Steps

1. Verify word distribution doesn't conflict with mixed levels
2. If questions.json needed: ensure templates match common-words-1 structure
3. Validate all translations are correct (currently has placeholders for some words)
4. Test levels in app

