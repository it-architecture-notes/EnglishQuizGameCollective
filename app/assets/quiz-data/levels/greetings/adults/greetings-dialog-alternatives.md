# Greetings — Adult Level Content Plan

## Current Topic

Drafting the adult Greetings planning document and recovering dialogue from `questions.json`.

## 1. Decisions

- Scope is adults only. Kids content (`greetings/kids/`) will be planned separately.
- This document belongs exclusively to the Greetings level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- `questions.json` and `translations.json` currently hold **live, already-shipped** content. Nothing has been cleared yet — no live file changes happen until new questions are proposed and agreed here first.
- Adult-oriented characters and settings should be used throughout the level. Any secondary characters must be older teenagers or adults, with mature proportions and styling.
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.
- **Section 3 shows the dialogue with inline annotations**: each line gets the approved word(s) it carries and, where graded, its question template in parentheses/suffix.
- **Video prompts must be fully self-contained**.
- **Section 3/6 sequencing**: Section 6 only gets drafted after Section 3's dialogue and question-type mapping are actually agreed.
- **No back-to-back silent question boundaries**.
- **A single spoken line is never split across `audio_file1`/`audio_file2`**.

## 2. Actions

1. Confirm the approved teaching scope from `translations.json`.
2. Design the question set together.
3. Propose and agree on questions.
4. Approve and lock the English package.
5. Produce any new media assets after content approval.
6. Finalize questions and JSON structure.
7. Validate the complete Greetings level.

## 3. Video Dialog

### Dialogs with Words

#### Clip 1

**Susan:** Good morning (`Good morning`)
**John:** Good morning (`Good morning`) — `DialogueCompletion`
**Susan:** What is your name? (`none`)
**John:** My name is John. (`My name is`) — `SentenceBuilder`
**Susan:** Nice to meet you, John. How are you? (`Nice to meet you`, `How are you?`)
**John:** I am fine, thank you. And you? (`thank you`) — `AppearDisappear`
**Susan:** I'm fine too. Where are you from? (`Where are you from?`)
**John:** I am from the United States. (`am`, `from`) — `ClozeSequence` (double blank)
**Susan:** What do you do? (`none`)
**John:** I am a student. (`none`) — `DialogueCompletion`
**Susan:** Oh nice. John, this is my friend Emma. (`none`)
**John:** Nice to meet you, Emma. (`Nice to meet you`) — `AppearDisappear`
**Emma:** Nice to meet you too, John! (`Nice to meet you`) — `AppearDisappear`
**Susan:** Have a great day, John. (`Have a great day`)
**John:** Thank you, Susan. You too! (`thank you`) — `DialogueCompletion`
**Susan:** See you later, John. (`see you later`)
**John:** See you later, Susan. (`see you later`) — `ClozeSequence` (double blank)

#### Clip 2

**Noah:** Hello. (`Hello`)
**Adam:** Hi. How's it going? (`Hi`, `How's it going?`) — `DialogueCompletion`
**Noah:** Not bad. (`Not bad`) 
**Adam:** Do you live around here? (`to live`) 
**Noah:** Yes, I live in this neighborhood. (`to live`, `neighborhood`) — `ClozeSequence`
**Adam:** Nice to meet you. How old are you? (`Nice to meet you`, `How old are you?`)
**Noah:** I am 17 years old. (`none`) — `DialogueCompletion`
**Noah:** How about you? (`How about you?`) 
**Adam:** I am also 17 years old. (`also`) — `AppearDisappear`
**Noah:** I need to go, take care. (`to need`, `to go`, `take care`) 
**Adam:** See you next time, bye. (`See you next time`, `bye`) — `DialogueCompletion`

### Simple Dialogs

#### Clip 1

Susan: Good morning
John: Good morning
Susan: What is your name?
John: My name is John.
Susan: Nice to meet you, John. How are you?
John: I am fine, thank you. And you?
Susan: I'm fine too. Where are you from?
John: I am from the United States.
Susan: What do you do?
John: I am a student.
Susan: Oh nice. John, this is my friend Emma.
John: Nice to meet you, Emma.
Emma: Nice to meet you too, John!
Susan: Have a great day, John.
John: Thank you, Susan. You too!
Susan: See you later, John.
John: See you later, Susan.

#### Clip 2

Noah: Hello.
Adam: Hi. How's it going?
Noah: Not bad. 
Adam: Do you live around here?
Noah: Yes, I live in this neighborhood.
Adam: Nice to meet you. How old are you?
Noah: I am 17 years old.
Noah: How about you?
Adam: I am also 17 years old.
Noah: I need to go, take care.
Adam: See you next time, bye.

## 4. Video Scripts

`<TBD>`

## 5. Image Dialogs

`<TBD>`

## 6. Questions JSON Structure

`<TBD>`

## 7. Translations JSON Structure

`<TBD>`

## 9. Message Pipeline

Maximum messages: 20.
Order: oldest to newest.
Each agent appends one named message using `Claude`, `Codex`, or `Antigravity`; the Developer (`d`/`Developer`) may also comment directly.
When appending message 21, remove the oldest message first (FIFO), then append the new one.
Only current Greetings discussion messages belong here.
Formatting rule: every agent's acceptance/agreement list must use `✅` green checkboxes; every issue, disagreement, or open item must use `❌` red crosses. Use these markers consistently in all new pipeline comments.

---

<!-- The Greetings discussion starts here. -->

**Antigravity:**
✅ Created the adult Greetings planning document using the established level-plan section structure.
✅ Extracted the dialogue lines for Clip 1 from `questions.json`, now including the previously blank setup lines that were just transcribed to capture missing vocabulary like 'How are you?'.
✅ Maintained speaker labels Susan, John, and Emma.
✅ Annotated responses with `answer_type` and vocabulary from `translations.json`.
✅ Added Simple Dialogs section.
✅ Validated that both subsections match and trace back to `questions.json`.

