** Notes if you are AI Ignore **

1) First Step chat AIs to clarify:
For my game I want to include a new issue ticket, can you review this ticket, remove unnecessary wording and make it more explict and remove gaps by asking questions. I will ask AI to develop this so provide the context best for AI to understand. Here is the is:
**Issue-11: Main Level Story Implemenation**

2) Command To main agent after initialize
Plan for the active issue and and ask me questions if anything is not clear or there are conflicts.


3) Ask sub agents to review one by one (cheaper models)
- Sub agents comment:
use @.cursor/agents/active-issue-reviewer.md agent, execute the work, create analysis acording to agent instructions and place the analysis in a file under Users/nsahin/Development/MobileDevelopment/EnglishQuizGameWCursor/.cursor/plans using the file name formatting in the agent desc. 

4) Ask the main agent to examine the analysis
<files here> examine these files and tell me if you agree with the comments in them and make updates if you agree with the gaps in the analysis.

5) delete the plan files after main thread is completed.

6) Generate diff files and place them in the claude plans directory for comparison
- Generate diff:
git add app/ && git diff --staged main -- app/ > .cursor/plans/issue-12-implementations-cursor.md && cp .cursor/plans/issue-12-implementations-cursor.md /Users/nsahin/Development/MobileDevelopment/EnglishQuizGameWClaude/.claude/plans

7) Ask main agent to review

check this implementation by cursor made for issue-12 and see if there are any differences.

When finished

do a focused follow-up patch to bring over the best parts from Claude
