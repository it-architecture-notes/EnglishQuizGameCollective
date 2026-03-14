Action: Create a git worktree for a new improvement branch named fix/claude-review-[issue-id] based on the current workspace changes.

Setup: > 1. Move all uncommitted workspace changes to this new branch.
2. Execute an initial git commit -m "checkpoint: cursor implementation for review".
3. Crucial: Immediately run flutter pub get within the worktree directory to re-link dependencies and ensure the package_config.json reflects the new relative paths.

Review Task: > 1. Compare the current state of this branch against main.
2. Evaluate the implementation against the active feature context and project rules (e.g., state management patterns, modularity).
3. Identify any logic gaps, missing edge cases, or violations of clean code principles.

Output: Generate a structured Action Plan for improvements. If major gaps exist, do not implement them yet—list the proposed changes for approval first.