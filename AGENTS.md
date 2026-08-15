# Agent instructions

This repository uses a shared worktree that may be edited concurrently by the user, Claude,
Cursor, and Codex. Before making changes, read `cursor-claude-common/rules/rules.md` completely
and inspect `git status --short`.

## Non-destructive shared-worktree rules

- Treat every pre-existing tracked or untracked change as user/other-agent work.
- Never run `git checkout --`, `git restore`, any form of `git reset`, `git clean`, or broad file
  overwrites to undo work unless the user explicitly approves the exact files and stated loss.
- Never target a parent directory, wildcard, generated path list, or repository root with a
  destructive command.
- Re-read each file immediately before editing. Merge concurrent changes; never replace a file
  from `HEAD`, another branch, or a stale copy.
- Do not revert, reformat, delete, or "clean up" unrelated changes.
- Before a bulk transformation, preview exact targets/counts, protect dirty content, and create
  recoverable copies for tracked content or binary assets. Afterward, inspect scoped diffs and
  stop on any unexpected path or large rewrite.

The canonical detailed rules, including the 2026-08-15 data-loss incident and required recovery
precautions, are in `cursor-claude-common/rules/rules.md` and take precedence over this summary.
