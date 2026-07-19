---
name: feedback-full-reference-file-scan
description: Vocabulary suggestions must scan all 8 reference word-list CSVs, not just verbs/adjectives/adverbs
metadata:
  type: feedback
---

When proposing vocabulary swaps or new-word candidates for a level (via `audit-quiz-level` or `improve-level-vocabulary`), cross-check candidates against **all 8** files in `cursor-claude-common/references/final words/`, not just `verbs-400.csv`, `adjectives-300.csv`, `adverbs-150.csv`:

- `auxiliaries.csv`
- `common-verbs.csv`
- `conjunctions.csv`
- `langeek-500-most-common-nouns.csv`
- `prepositions.csv`

**Why:** The user explicitly called this out after a `waking-up` vocabulary audit where only 3 of the 8 files were checked. Scanning `auxiliaries.csv` in particular caught a real bug that pure verb/adjective/adverb scanning missed: `must` (an auxiliary/modal, not a verb-list entry) appearing in a question at a mainLevel where it's forbidden grammar.

**How to apply:** Every vocabulary-suggestion pass should query `count`/`level` fields across all 8 CSVs against the prior-consumed-words set (`gather_prior_level_words.py`) and the current level's existing vocabulary, not a subset. This also surfaces cross-cutting issues (e.g. a candidate word actually being a grammar-band violation, like `must`) that narrower scans miss.
