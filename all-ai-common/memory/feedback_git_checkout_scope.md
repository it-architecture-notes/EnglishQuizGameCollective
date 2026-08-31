---
name: feedback-git-checkout-scope
description: Never scope a git checkout/restore/reset/clean revert wider than the exact file(s) you know you changed
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 6e661512-2379-4245-ada8-fe022e48db8c
  modified: 2026-08-15T19:07:25.801Z
---

Never run `git checkout --`, `git restore`, `git reset --hard`, or `git clean` on a directory to undo a mistake — scope the revert to the exact file(s) you know you changed, never a parent directory or the whole repo, even when resetting the whole tree feels faster than reverting individually.

**Why:** On 2026-08-15, a bulk JSON-reformatting script accidentally reformatted one unrelated file (`common-words-2/kids/questions.json`) while doing a GrammarForm→ClozeSequence template migration across ~65 files. Instead of reverting just that one file, `git checkout -- assets/quiz-data/levels/` was run to reset the whole directory before redoing the change more safely. That directory also held real, unrelated, uncommitted work: 9 new VideoConversation questions, 2 Chapter cards, a 5-step tutorial config, translation.json additions, and edits to two PNGs (`how-old-are-you.png`, `where-is-she-from.png`) — none staged or committed. All of it was silently discarded in one shot. The questions.json was partially recoverable via VS Code Local History and leftover git loose objects (checkpoint blobs still in `.git/objects` despite never being committed); translations.json and the two PNGs were not recoverable — no local history, no loose-object trace found for the PNGs (binary edits made via an external script, never touched by an editor VS Code would snapshot).

This was compounded by having *already seen* — minutes earlier in the same investigation — that `greetings/adults/questions.json` (325-line diff) and `translations.json` (102-line diff) held large pre-existing uncommitted changes unrelated to the script. That fact was used to reassure that those files were "fine, not something I broke," then immediately invalidated by running a directory-wide checkout that doesn't distinguish "damage I just caused" from "uncommitted work that was already there."

**How to apply:** Before any command that can discard uncommitted work (`checkout --`, `restore`, `reset --hard`, `clean -f`, or even overwriting a file outright), run `git status`/`git diff` scoped to *exactly* the path about to be touched — not a wider ancestor directory — and read the output. To undo damage caused in file A, revert file A only by name. If other files were also touched by the same mistake, revert those individually by name too — never take the shortcut of reverting a shared parent directory. If unsure whether a directory holds other uncommitted work belonging to the user, assume it does and check first, every time, regardless of how large the resulting `git status` diff review feels.

Related: [[project-app-flavor-and-tutorial]], video question/tutorial JSON structure for `greetings/adults` (`app/assets/quiz-data/levels/greetings/adults/questions.json`) — 9 VideoConversation + 2 Chapter + 5-step tutorial config, recovered from VS Code Local History file `dX9D.json` after this incident.
