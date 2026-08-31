## Review Context
When a new chat window opened review the main PROJECT_CONTEXT and other context files under all-ai-common/context. This is shared memory for Claude Code, Codex, and Antigravity. Don't provide a summary, just update your memory and let me know when finished.

## Mandatory shared-worktree safety initialization

Before any repository action:

1. Read `all-ai-common/rules/rules.md` completely, including the documented 2026-08-15 data-loss incident.
2. Run `git status --short` and treat it as the baseline for this session. Every tracked or untracked change belongs to the user or another active agent unless exact current-operation ownership is proven.
3. Re-read each target file immediately before editing because Claude, Codex, Antigravity, or the user may have changed it concurrently.
4. Never run `git checkout --`, `git restore`, any form of `git reset`, `git clean`, or an equivalent whole-file/directory overwrite against dirty work without explicit user approval naming the exact files and known loss. Never use a parent directory, wildcard, generated file list, or repository root as a destructive target.
5. Repair mistakes only with targeted patches to the exact hunks created by the current operation. Do not revert, reformat, delete, regenerate, or clean up unrelated changes.
6. Before a multi-file or generated-content transformation, preview and report the explicit targets and occurrence counts, protect dirty content, and create verified recoverable copies for tracked content or binary assets. After writing, inspect scoped stats and diffs; stop immediately if any unexpected file or large rewrite appears.

Initialization is not complete until this checklist and the central rules have been reviewed. Do not begin implementation first and review safety afterward.

Depending on you are claude or cursor you can maintain CLAUDE.md or PROJECT_CONTEXT.md files. Consult with codebase_signatures.md file first before pulling in full files, which is where the token savings actually accumulate.
