** Notes if you are an AI Ignore this file **

1) Clarify your issue using Gemini, ChatGPT, DeepSeek, ask them to ask questions and fix wording in the main part.
Go and review this issue and ask questions if you see any gaps, also reword the sections for effective understading for an AI development agent.

2) In Main Cursor Agent ask for a plan to be created and placed under commons/plans folder.
Create a plan for the active issue, and place the plan in an md file following rules for naming and location.

2b) In parallel ask the same to Claude and ask it to generate another plan file and place in the common plans folder.

<Now we have two plan files under common folder>

2c) Ask Cursor to review the plan created by Claude and fix it's missing parts if it sees and aggrees.

3) Ask cursor agent to develop and build.

3a) Start the flutter run on chrome and examine the feature

4) commit the changes and md files to the branch.

5) Ask other cursor agents to review and create their analysis on files in the common plans directory with their model names. Here is their command: 

use @.cursor/agents/active-issue-reviewer.md agent, execute the work, create analysis acording to agent instructions and place in the output file. place the output file in the common plans folder. in the file name include a random 4 digits number and agent model name.

3a) Ask Cursor Agent to summarize the 'Implementation Details' into a temporary .md file under common plans folder with name cursor-implementation-details-<issue_name>

5) Ask Claude :

PLAN MODE: (Provide 2 agent review files and cursor implementation details) ask to review the changes against the feature and identify if any gaps exists.

6) Ask Claude to fix gaps and implement.

7) ask Claude maybe make some change

8) After changes are completed ask Claude to update context md files and commit on the feature branch.

10) Ask Claude to merge the feature branch to main branch and feature development cycle is completed.


