# Project Rules

## How to Progress

The developer adds issues one by one to active-progress-context.md to indicate it is the current focus of implementation.
Only one use case—whether it is a new feature, an enhancement, or a bug fix—is actively worked on at any given time.
When the implementation of the active item is complete, and after it has been verified and accepted by the developer, it is moved from active-progress-context.md to progress-context-archive.md by summarizing.
Also the issue in active-progress-context.md when completed, moved to full-project-issue-archive.md exactly as it is without summarizing it.
Archived items should be listed in reverse chronological order (most recent first) to maintain a clear history of completed work.

## Signtatures file

Consult with codebase_signatures.md file first before pulling in full files, which is where the token savings actually accumulate. 

## Handling Ambiguity
In planning or implementation mode do not assume — ask focused questions for the major decisions to be made. For the minor code level decisions AI can go ahead and make the decision.

## Scope: One Use Case at a Time — No Overdelivery
One use case and feature at a time. Do not bundle multiple use cases or add “nice-to-haves” from other use cases without approval. You may suggest enrichments or new features in the plan (e.g. as “Out of scope” or “Optional / future”). Do not add them to the implementation without explicit user approval.

## Decision Making
A written plan is not required before implementing — go ahead and implement directly unless the developer specifically asks for a plan first. This does not relax the ambiguity rule above: for major decisions, ask a focused question rather than assuming, even when no plan is requested.
For architectural decisions (new library, pattern change, data model change), always ask.

## Plans Location
Always create and store plans under **all-ai-common/plans/** (e.g. `all-ai-common/plans/issue-14-image-quiz-timer-monster-cursor.md`). Use claude or cursor in the file name depending on the AI. Do not create plans under `.cursor/plans/` or other locations. Use descriptive filenames that include the issue or feature (e.g. `issue-N-short-name.md` or `game-level-fix.md`). When creating a plan in Cursor that may have a counterpart created by Claude, use a distinct name so both can coexist: e.g. suffix Cursor-authored plans with **-cursor** (e.g. `issue-14-image-quiz-timer-monster-cursor.md`); the Claude version may be `issue-14-image-quiz-timer-monster.md` without the suffix.

## Scope Control
Do not add comments, types, or docstrings to code you did not change.

## Commit & Git
Never implement or build on the main branch. Always checkout to a feature branch (e.g. `feature/issue-10-settings`) before starting implementation of an issue.
Never commit unless explicitly asked.
Never force-push or amend published commits without explicit instruction.

### Never use destructive Git cleanup to undo your own mistake
Do not run `git checkout --`, `git restore`, `git reset`, `git clean`, or an equivalent broad overwrite as a cleanup shortcut. Repair only the exact lines you changed, preserving every other byte; never target a parent directory or the whole repo.
**Why:** on 2026-08-15, a bulk JSON-reformatting script accidentally reformatted one unrelated file (`common-words-2/kids/questions.json`). Instead of reverting just that file, `git checkout -- assets/quiz-data/levels/` was run to reset the whole directory before redoing the change safely. That directory also held unrelated, real, uncommitted work — 9 new VideoConversation questions, 2 Chapter cards, a 5-step tutorial config, translation additions, and edits to two PNGs — none of it staged or committed. All of it was silently discarded in one shot. The JSON was partially recoverable via VS Code Local History and leftover git loose objects; the two PNGs were not recoverable at all.
**How to apply:** inspect `git status` and the scoped diff, then reverse only your own exact hunks with a targeted patch. A whole-file Git restore can still erase concurrent edits and therefore requires explicit user approval identifying that file and the known loss. If ownership of any hunk is uncertain, assume it belongs to the user or another agent and stop for direction.

### Shared-worktree safety — mandatory for every agent
- Treat every tracked or untracked change as belonging to the user or another active agent unless you can prove that the exact change was created by your current operation. A dirty Git diff does not establish ownership.
- Do not run `git checkout --`, `git restore`, any form of `git reset`, `git clean`, or an equivalent overwrite against a dirty path without explicit user approval naming the exact files and explaining what will be discarded. This applies even to one file: another agent may have edited that file after you read it.
- Never use a parent directory, wildcard, glob, generated file list, or repository root as the target of a destructive Git/file command. Destructive targets must be explicit individual paths verified immediately beforehand.
- Before editing a file, refresh it from disk. If its content or modification time changed since it was inspected, assume concurrent work, re-read it, and merge rather than overwriting it.
- Do not "clean up," revert, reformat, or delete unrelated changes discovered while working. Report them and leave them intact.
- If a requested recovery would discard unknown work, stop and ask the user. Speed or convenience is never sufficient reason to reset shared state.

### Bulk transformations and generated-content safety
- Before any multi-file transformation, run and retain a scoped `git status --short`, preview the complete explicit target-file list, and report the expected file and occurrence counts. Do not write until the target set is understood.
- Dirty target files require special handling: preserve their existing content and make only the intended semantic edit. Never regenerate them from `HEAD`, another branch, a stale in-memory copy, or a canonical template.
- For JSON/YAML/content migrations, prefer targeted patches or byte-preserving textual replacements. Do not deserialize and serialize whole files merely to change one field; that can rewrite formatting and obscure collateral changes.
- Before overwriting tracked content or binary assets, create a recoverable copy outside the target path and verify it exists. A Git diff is not a backup for uncommitted binary data.
- After a bulk operation, inspect `git diff --stat`, `git diff --numstat`, and representative/full scoped diffs. If any unexpected path or large rewrite appears, stop. Repair only the exact lines your operation changed; never reset the containing directory.
- Do not delete recovery copies until the user has verified and accepted the result.

## Output Format
When writing a plan, use numbered steps with file paths.
When modifying files, show only the relevant changed section with enough context, not the whole file.
When multiple approaches exist, list them with trade-offs before recommending one.

## Context Update
When major decisions are made update the context files under the all-ai-common/context folder.

## Anti-patterns to Avoid
No over-engineering: do not add abstraction layers for one-time use.
No speculative features: do not build what was not explicitly asked for.
No silent assumptions: surface all assumptions before acting on them.
> Example: Do not add retry logic to a function unless failure handling was requested.

## Prefer Existing Utilities
Before adding a helper or utility, check if the codebase already has one that serves the same purpose.

## Shared Types
When modifying shared types or interfaces, consider the impact on all usages across the codebase.

## Testing
Do not generate test code (unit tests, widget tests, integration tests). The developer will test manually.

## Message Pipeline Protocol (Multi-AI Collaboration)
When the developer says "the pipe" / "pipe" / "comment in pipe" / "check pipe," they mean the **Message Pipeline** section (numbered "## 9. Message Pipeline" as of this writing, but the number can shift if sections are added/removed — find it by heading text, not number) inside whichever plan document is under active discussion, currently `app/assets/quiz-data/levels/basic-sentences/basic-sentences-dialog-alternatives.md` (relocated from `all-ai-common/plans/` on 2026-08-22 — the developer deleted the original and this level-folder copy is now the sole canonical document). It is a shared, append-only collaboration log between the developer and three AI agents — Claude, Codex, and Antigravity — working concurrently on the same file.

**Mechanics:**
- Each entry starts with the agent's bolded name and a colon: `**Claude:**`, `**Codex:**`, `**Antigravity:**`, or `**Developer (me):**` for the human.
- Entries are separated by a `---` line.
- The section states its own current max-message count and FIFO rule inline (developer-adjustable — was 6, raised to 10) — read those two lines at the top of the section before touching it, don't assume a fixed number. When appending would exceed the stated max, remove the oldest message first, then append.
- Only current discussion belongs in the pipeline. A "Section 10 Agreement on Current Discussion" used to hold durable conclusions separately but was removed by explicit developer instruction — do not recreate it unless asked; durable decisions now live directly in the plan's own Decisions/Actions sections.

**Behavioral rules, established through repeated developer correction this session:**
- **"comment in pipe" means comment only — do not edit any other part of the file in the same turn.** If you find a real issue while reviewing, describe it and propose the fix in your pipe message; do not apply it. Only apply a fix when asked to make the change (with or without also being asked to log it in the pipe).
- When you *are* asked to make a change, apply it to the actual document content first, then log what you did in the pipe as a new entry (not the other way around).
- **Never trust another agent's self-reported summary at face value — verify directly against the file before agreeing, building on it, or endorsing it.** This was the single most consistently valuable behavior across this collaboration: multiple times another agent claimed something was "fixed," "synced," or "100% verified" when a direct read of the file showed it wasn't, or was only partly done, or had a fresh bug (e.g. a blank-count mismatch, copy-pasted distractors, a stale prose reference to old content). State plainly what you checked and what you found, whether or not it agrees with the claim.
- If a prior finding turns out to be superseded or wrong once new information arrives (e.g. a simpler fix than the one you proposed), say so explicitly and withdraw it rather than leaving two contradictory recommendations standing.
- Keep each entry focused on one topic/exchange; don't dump multiple unrelated findings into one giant message across separate requests — match the granularity of what the developer actually asked about.

## Video Generator Prompt Authoring
The developer can only paste the quoted prompt text itself into the video generator — nothing else from a plan document's Section 4 (surrounding "Setting & Characters" bullets, "Purpose and quiz staging" notes, continuity rules, timing tables, etc.) ever reaches the generator. Therefore **every detail the clip actually needs must be written inside the prompt block itself** — self-contained, not "see the section above" or "matches Section 3." This includes: full room/character description, exact dialogue lines and order, per-line gestures/actions, required silent beats and their durations, the held final continuity frame, and any negative constraints (no readable text, no extra characters, etc.). Bullets outside the prompt block are for human review only and must not be the only place a generation-relevant detail is stated — if it matters for the video, put it in the prompt text, and it is fine (often necessary) for surrounding bullets to repeat it for humans skimming the doc.

## VideoConversation Audio Splicing
**Audio field naming and behavior (every interactive template, VideoConversation included):** three optional top-level fields — `question_enter_audio`, `question_exit_correct_audio`, `question_exit_wrong_audio`. Each accepts a plain string (one clip), an array of strings (clips played in sequence), or the literal string `"none"` (explicitly nothing — distinct from the field being absent). `_text` companions (`question_enter_audio_text`, etc., matching the string/array shape) exist only for the TTS generation tool, not the app.

- `question_enter_audio` plays once, automatically, the first time the question is presented, and is what the audio icon plays (repeatable) before the learner answers. If absent, nothing auto-plays and the icon is disabled pre-answer.
- `question_exit_correct_audio` plays automatically after a correct answer, before advancing. Absent or `"none"`: nothing plays, advances immediately.
- `question_exit_wrong_audio` plays automatically after a wrong answer, before the Next button appears (Next waits for it), and is what the audio icon plays (repeatable) post-wrong. If the field is **absent**, this falls back to `question_exit_correct_audio` (so wrong answers hear the correct-answer line by default — set both fields to the same value/array to reproduce that explicitly). If the field is explicitly `"none"`, the fallback is suppressed entirely: nothing plays and the icon is disabled post-wrong.
- Exception: the AppearDisappear/recall sub-type's "Listen Again" button inside `VideoConversation` only ever plays `question_exit_correct_audio` — no enter/wrong involvement, no fallback.

A single spoken line is never split across two of these fields — one character's one sentence always plays as one whole clip, either entirely before the pause (`question_enter_audio`) or entirely after answering (`question_exit_correct_audio`), never partly on each side. This applies to `ClozeSequence` too: the blanked sentence itself is one line — do not slice it at the blank point into a "before the blank" enter clip and an "after the blank" exit-correct clip. If a blanked line has no natural preceding setup line, leave `question_enter_audio` unset entirely and let `question_exit_correct_audio` carry the complete blanked sentence as a single clip after the answer, exactly like a blind `DialogueCompletion`/`SentenceBuilder`. (Discovered via the grocery-shopping level, where three cloze questions originally split one sentence across setup+confirm — corrected to full-line confirm clips with no enter clip.)

**Video/audio sync depends on the *previous* row, not the current template.** A `VideoConversation` row only gets a true simultaneous video+`question_enter_audio` start (`startQuestionAudio` + immediate `controller.play()`) when the shared video controller was actually paused when it mounted — i.e. the level's first row, the first row of a new `videoFile`, or any row immediately following an `AppearDisappear`/recall row (which never resumes the video, see below) or a wrong answer (which explicitly re-pauses after its audio finishes). Every other row mounts with the video *already rolling* from the previous row's unpaused correct-answer resume, so it falls back to an unsynced, fire-and-forget entry-audio play — approximately timed, not guaranteed, and only stays close in practice if every prior row's real audio duration matches its declared `pause_at`→`answer_until` window exactly. Author `AppearDisappear` rows with `pause_at == answer_until` (zero forward-play window) — the video must never resume for those regardless of outcome, since there's nothing new to show past the pause and letting it free-run races unsupervised into the next row before that row's own position listener attaches. See `page-designs-and-templates.md`'s `VideoConversation` section for the full mechanism and a worked walkthrough (verified question-by-question against `greetings1`/`greetings2` in `app/assets/quiz-data/levels/greetings/adults-intermediate/questions.json`).

## Boundaries
Do not refactor code outside the scope of the current task.
Do not add logging, error handling, or tests unless requested. If required these will be asked as feature enhancements.
Do not suggest architectural improvements mid-task — note them in a comment at the end instead.
Do not push to remote, open PRs, or send messages to external systems without explicit instruction.
Do not automatically start the app when implementation is done, I will start it manually using the terminal.
