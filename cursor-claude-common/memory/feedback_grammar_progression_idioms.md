---
name: feedback-grammar-progression-idioms
description: User accepts short imperative/idiomatic phrases at ML1 as exceptions to the strict grammar progression table in the audit-quiz-level skill
metadata:
  type: feedback
---

Short, fixed idiomatic phrases (greetings/farewells, polite chunks) are acceptable at ML1 even when they technically use grammar not yet introduced (e.g. imperative, first introduced at ML3) — as long as they're frozen expressions rather than a generalizable pattern being taught.

Confirmed examples in `at the greetings` level (mainLevel 1):
- "See you later" (imperative-form idiom)
- "Have a great day, Alex" (imperative)
- "Please say hello to Beth." (imperative) — explicitly kept over an ML1-compliant Yes/No alternative ("Are you from Canada, please?") because the user judged the idiom "better"

**Why:** The user directly overrode a grammar-progression flag raised per `cursor-claude-common/skills/audit-quiz-level/SKILL.md`, calling the idiomatic version better than the strictly-compliant rewrite.

**How to apply:** When auditing levels with `audit-quiz-level`, still flag imperative/other later-ML grammar per the skill's rules (don't silently skip the check), but note in the flag that short fixed social-idiom phrases (greetings, farewells, courtesy chunks) are a known accepted exception — treat these as low-priority/optional rather than must-fix, and defer to the user's judgment if they push back. Only apply this leniency to frozen idiomatic chunks, not to sentences that teach a reusable grammatical pattern (e.g. a full modal-request lesson like "Can you help me?" is NOT covered by this exception — that was still flagged and changed).
