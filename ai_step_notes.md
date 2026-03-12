** Notes if you are an AI Ignore this file **

1) First Step chat AIs to clarify:
For my game I want to include story pages, can you review this ticket, remove unnecessary wording and make it more explict and remove gaps by asking questions. I will ask AI to develop this so provide the context best for AI to understand. Here is the issue:
**Issue-11: Main Level Story Implemenation**

2) Ask Cursor to Plan for the active issue and and ask me questions if anything is not clear or there are conflicts. After examining issue plan, ask cursor agent to implement the plan on a different feature branch.

2a) Start the flutter run on chrome and examine the feature

3) Ask other cursor agents to review and create their analysis files (2 of them). Here is their command: 
use @.cursor/agents/active-issue-reviewer.md agent, execute the work, create analysis acording to agent instructions and place the analysis in a file under workspacepath/.claude/plans using the file name formatting in the agent desc. 

3a) Ask Cursor Agent to summarize the 'Implementation Decisions' into a temporary .md file.
4b) Ask cursor to commit changes to the feature branch it implemented.

5) Ask Claude : Create git worktree and an issue improvement branch by taking the changes in the workspace to the branch. Execute an initilal git commit -m "checkpoint before claude improvements". Run flutter clean or at least flutter pub get immediately after creating the worktree. This ensures the package resolution points to the correct relative paths for that specific folder. Review the cursor changes against the active context feature and create a plan to improve the developments by cursor if there are any major developments.

6) Ask Claude to make the improvements on the worktree branch, Only modify files related to the feature. Do not refactor unrelated modules.

7) cd to the worktree folder and run flutter run chrome on the worktree branch and examine the improvements

8) ask Claude maybe make some change

9) After changes are completed ask Claude to update md files and commit on the worktree branch.

10) Ask Claude to merge the worktree branch to feature branch and feature development cycle is completed.
10a: Claude deletes the worktree folder (git worktree remove ...).

11) Ask cursor main agent to merge the feature branch to main branch


