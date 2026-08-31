---
name: feedback-audit-prior-words
description: "For level audits, use the pre-generated prior-words file instead of running the Python script each time"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 52b5d9d2-d58d-4299-af5b-b82457e16168
---

For level audits, do NOT run `tools/gather_prior_level_words.py` to get the prior consumed word list. Instead read the pre-generated file:

`all-ai-common/output/prior-words-by-type.md`

This file is already organized by type (verbs, adjectives, adverbs, etc.) with source level noted per entry. It's faster and avoids script overhead.

**Why:** User pointed this out after noticing the script was being re-run on every audit session.

**How to apply:** At the start of every audit, read this file instead of running the gather script. Note the file is keyed to a specific target level (the header says which level it was generated for) — verify it matches the level being audited, or run the script once to regenerate if auditing a different level.
