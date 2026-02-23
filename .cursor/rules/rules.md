# Project Rules

## How to Progress

The full-project-context.md file serves as a master issue list of all high-level project use cases and user stories. 
The developer selects a single item from this list and adds it to active-progress-context.md to indicate it is the current focus of implementation.
Only one use case—whether it is a new feature, an enhancement, or a bug fix—is actively worked on at any given time.
When the implementation of the active item is complete, and after it has been verified and accepted by the developer, it is moved from active-progress-context.md to progress-context-archive.md.
Archived items should be listed in reverse chronological order (most recent first) to maintain a clear history of completed work.

## Handling Ambiguity
In planning or implementation mode do not assume — ask focused questions for the major decisions to be made. For the minor code level decisions AI can go ahead and make the decision.

## Scope: One Use Case at a Time — No Overdelivery
One use case and feature at a time. Do not bundle multiple use cases or add “nice-to-haves” from other use cases without approval. You may suggest enrichments or new features in the plan (e.g. as “Out of scope” or “Optional / future”). Do not add them to the implementation without explicit user approval.

## Decision Making
For any feature request to be implemented, present a plan first and wait for approval.
For architectural decisions (new library, pattern change, data model change), always ask.

## Scope Control
Do not add comments, types, or docstrings to code you did not change.

## Commit & Git
Never commit unless explicitly asked.
Never force-push or amend published commits without explicit instruction.

## Output Format
When writing a plan, use numbered steps with file paths.
When modifying files, show only the relevant changed section with enough context, not the whole file.
When multiple approaches exist, list them with trade-offs before recommending one.

## Context Update
When major decision are made update the context files under the .cursor/context folder.

## Anti-patterns to Avoid
No over-engineering: do not add abstraction layers for one-time use.
No speculative features: do not build what was not explicitly asked for.
No silent assumptions: surface all assumptions before acting on them.
> Example: Do not add retry logic to a function unless failure handling was requested.

## Prefer Existing Utilities
Before adding a helper or utility, check if the codebase already has one that serves the same purpose.

## Shared Types
When modifying shared types or interfaces, consider the impact on all usages across the codebase.

## Boundaries
Do not refactor code outside the scope of the current task.
Do not add logging, error handling, or tests unless requested. If required these will be asked as feature enhancements.
Do not suggest architectural improvements mid-task — note them in a comment at the end instead.
Do not push to remote, open PRs, or send messages to external systems without explicit instruction.