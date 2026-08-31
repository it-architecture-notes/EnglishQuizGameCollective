---
name: project-current-state
description: "Active issue, current branch, and recent completed work for the EnglishQuizGame project"
metadata: 
  node_type: memory
  type: project
  originSessionId: 48f2c7c7-41db-4719-b691-f2c7cb8a3e72
---

Active issue is Issue-27: Adding a "Words Used in This Level" translations page at the end of each level (shown when `translations.json` exists in the level folder). Also adds a "Words" button on the levels screen for completed levels (≥1 star). If app language is English, the page is skipped. Does not appear after reminder levels.

**Why:** Feature request to help non-English users review vocabulary from each level.

**Current branch:** feature/issue-27-level-translations-page

**Branch also contains (not part of Issue-27):**
- ClozeSequence multi-blank wrong-answer highlight fix (`cloze_sequence_quiz_body.dart`)
- DialogueCompletion button lock during line1 audio (`dialogue_completion_quiz_body.dart`)

**Last completed:** Issue-26 — template audio gating, translation-reveal audio, AudioPlayButton visibility, post-answer audio sequencing.

**How to apply:** When implementing Issue-27, check `active-progress-context.md` for full spec including placement logic for the "Words" button (left/right based on icon position relative to screen center).
