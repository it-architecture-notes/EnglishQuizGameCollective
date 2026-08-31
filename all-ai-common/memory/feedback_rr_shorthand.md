---
name: feedback-rr-shorthand
description: "User shorthand \"r-r\" means \"read the pipe and respond in it\" — recognize and act on this abbreviation"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f26cf7c5-6daa-46ff-ae05-25817b31c967
  modified: 2026-08-25T03:55:41.301Z
---

When the user types "r-r" (or "r r"), treat it as the instruction "read and respond in pipe" — read the latest content of the Message Pipeline (Section 9 of `app/assets/quiz-data/levels/basic-sentences/basic-sentences-dialog-alternatives.md`, or whichever file currently hosts the active multi-agent pipe) and post a response there, following the established pipe conventions ([[feedback_pipe_checkbox_convention]] if it exists — ✅/❌ formatting, FIFO 10-message cap, etc.).

**Why:** User introduced this as a deliberate shorthand ("r-r = read and respond in pipe = remember it") to save typing during the ongoing multi-agent (Claude/Codex/Antigravity) collaboration on this project.

**How to apply:** Any time the user's message is just "r-r" or "r r" (possibly with no other content), interpret it as a full instruction to check the pipe file for new messages from Codex/Antigravity and respond there — not to be confused with a request to explain what r-r means.
