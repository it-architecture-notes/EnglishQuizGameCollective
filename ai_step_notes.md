** Notes if you are an AI Ignore this file **

1) Clarify your issue using Gemini, ChatGPT, DeepSeek, ask them to ask questions and fix wording in the main part.
Go and review this issue and ask questions if you see any gaps, also reword the sections for effective understading for an AI development agent.

2) In Main Cursor Agent ask for a plan to be created and placed under commons/plans folder.
Create a plan for the active issue, and place the plan in an md file following rules for naming and location.

2b) In parallel ask the same to Claude and ask it to generate another plan file.

<Now we have two plan files under common folder>

3) Ask cursor agent to develop and build.

3a) Start the flutter run on chrome and examine the feature

4) commit the changes and md files to the branch.

3) Ask other cursor agents to review and create their analysis files (2 of them). Here is their command: 

use @.cursor/agents/active-issue-reviewer.md agent, execute the work, create analysis acording to agent instructions and place in the output file. 


3a) Ask Cursor Agent to summarize the 'Implementation Decisions' into a temporary .md file.
4b) Ask cursor to commit changes to the feature branch it implemented.

5) Ask Claude :

command: review-cursor-changes

6) Ask Claude to make the improvements on the worktree branch, Only modify files related to the feature. Do not refactor unrelated modules.

7) cd to the worktree folder and run flutter run chrome on the worktree branch and examine the improvements

8) ask Claude maybe make some change

9) After changes are completed ask Claude to update md files and commit on the worktree branch.

10) Ask Claude to merge the worktree branch to feature branch and feature development cycle is completed.
10a: Claude deletes the worktree folder (git worktree remove ...).

11) Ask cursor main agent to merge the feature branch to main branch


