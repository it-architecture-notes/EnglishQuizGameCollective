---
name: feedback-stem-words-ok-in-translations
description: audit-quiz-level rule change — ClozeSequence and ConvoTemplate-1 sentence-stem words now qualify for translations.json, not just blank answers
metadata:
  type: feedback
---

`ClozeSequence` and `ConvoTemplate-1` sentence-**stem** words (non-blank positions) now qualify for `translations.json`, same as blank answers. Only **distractors** remain permanently excluded from translations for every template (unchanged, universal rule).

This was saved directly into `cursor-claude-common/skills/audit-quiz-level/SKILL.md`:
- The "Answer–translation alignment" row in the per-question review table
- The "Introduced in level" template-qualification table (ClozeSequence / ConvoTemplate-1 rows)
- The "ClozeSequence / ConvoTemplate-1 rule" paragraph
- The "Wasted slot" flag definition (no longer lists stem-only words as a wasted-slot source)

**Why:** Multiple audits (`in-the-bedroom`'s `dark`/`bright`, `birthday-party`'s `together`/`to wish`) kept surfacing the same "wasted slot" flag for words that were clearly central to the sentence's meaning, just not literally inside the blank. The user first accepted these case-by-case as exceptions, then explicitly generalized it into a standing rule: stem words are fine in translations from now on. This also fully supersedes the earlier narrower fix in [[feedback_convotemplate1_translation_source]] (which only covered ConvoTemplate-1's non-blank line, not ClozeSequence stems).

**How to apply:** When auditing any level, do **not** flag ClozeSequence or ConvoTemplate-1 stem words as "wasted slots" or "invalid sourcing" for translations.json. Only flag a translation entry as wasted if the word is **completely absent** from every question (not even in a stem or a line) — i.e. only reachable via a distractor, or not present anywhere at all.
