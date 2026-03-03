Objective: Compare the feature implementation delta between two repositories to identify missing logic for the current development issue task.

Context Files:

Reference Diff: /Users/nsahin/Development/MobileDevelopment/EnglishQuizGameWClaude/temp-folder-ignore/total-diff.txt

Current Workspace Diff: ./temp-folder-ignore/total-diff.txt

The diff files are created by running in each repo:
git diff main -- '**.dart' '**.yaml' ':!**/*.g.dart' ':!**/*.freezed.dart' > ./temp-folder-ignore/total-diff.txt

If either file is missing: Tell the user to run the command above in the corresponding repository to generate it, then re-run this compare command.

Instructions:

Analyze the diffs in both files, focusing strictly on .dart logic and .yaml dependencies.

Compare the implementation of the "last issue" only — i.e. the single most recently implemented issue (e.g. from active-progress-context or the latest completed issue). If the changes in the diffs are completely irrelevant to that issue or clearly belong to another issue, ask the user what to do before proceeding.

Identify any code patterns, state management logic, or UI components present in the Reference Diff that are missing or incomplete in the Current Workspace, and vice versa.

Terminology: "Your implementation" = current workspace (Cursor). "Other implementation" = reference repo (Claude).

Output: Create a plan .md file (e.g. .cursor/plans/comparison-plan-cursor-vs-claude.md) containing (1) what is missing in your (Cursor) implementation, (2) what is missing in the other (Claude) implementation, and (3) your proposed plan (what to align or change). Let the user view the changes and the plan. Wait for user approval before making any code changes.

NEVER UPDATE THE CODE IN THE CLAUDE REFERENCE DIRECTORY.
