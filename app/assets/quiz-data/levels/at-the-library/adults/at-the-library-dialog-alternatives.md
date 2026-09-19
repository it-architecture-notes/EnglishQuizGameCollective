# At the Library — Adult Level Content Plan

## Current Topic

`<TBD — describe what this planning round is for: e.g. adding a VideoConversation intro to the existing adult At the Library level, reworking specific questions, etc.>`

## 1. Decisions

- Scope is adults only. Kids content (`at-the-library/kids/`) will be planned separately.
- This document belongs exclusively to the At the Library level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- Existing level distributions must be checked before adding vocabulary so words already taught in earlier levels are not repeated without a clear teaching reason.
- Vocabulary taught primarily by image-only levels must be checked before selecting tangible nouns for this level.
- `questions.json` and `translations.json` currently hold **live, already-shipped** content (12 approved vocabulary items, 15 questions across `ClozeSequence`, `imageQuizTemplate-1`, `ConvoTemplate-1`, `imageQuizTemplate-2`, `WordPairs`, `DialogueCompletion`, `AppearDisappear`, `SentenceBuilder`). Nothing has been cleared yet — no live file changes happen until new questions are proposed and agreed here first.
- Adult-oriented characters and settings should be used throughout the level. Any Student/secondary characters must be older teenagers or adults, with mature proportions and styling; do not use young children in adult-level scenes (standing rule from the At the School level).
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.
- **Section 3 shows the dialogue with inline annotations** (developer preference, revised): each line gets the approved word(s) it carries and, where graded, its question template in parentheses/suffix. Full mechanic detail (exact answer, distractors, audio1/audio2 mapping, timestamps) still lives in Section 6 — Section 3's tags are a quick-reference summary, not the source of truth for those specifics.
- **Video prompts must be fully self-contained** (see `all-ai-common/rules/rules.md` § Video Generator Prompt Authoring): the developer can only paste the quoted prompt text into the video generator, nothing else from Section 4. Every generation-relevant detail — room/character description, exact dialogue, per-line gestures, required silent beats, the held final frame, negative constraints — must live inside the prompt block itself, not only in surrounding bullets.

## 2. Actions

1. Confirm the approved teaching scope from `translations.json`.
   - Review earlier levels for vocabulary overlap.
   - Classify each of the approved words as required, reinforcement, or remove.
   - Identify any gaps in the approved At the Library teaching scope not yet covered.

2. Design the question set together.
   - Flag any weak distractors, ambiguous answers, or questions testing irrelevant memory before they're added.
   - Confirm every template field matches what its parser actually reads (see `codebase_signatures.md` / `level_config.dart`) before trusting a validator's clean run.

3. Propose and agree on questions.
   - Use short one- or two-line adult situations with clear audio/text context.
   - Use an appropriate mix of approved templates, including DialogueCompletion, ClozeSequence, ConvoTemplate-1, SentenceBuilder, AppearDisappear, and WordPairs where appropriate.
   - Make every correct answer uniquely supported by the dialogue, image, or grammar.

4. Approve and lock the English package.
   - Review vocabulary, question types, distractors, WordPairs, and coverage together.
   - Resolve overlap, ambiguity, and missing coverage before production of any new assets.

5. Produce any new media assets after content approval.
   - Generate any new approved question images and audio assets.
   - Reuse the existing convo `.m4a` clips already in the level folder where content is unchanged.

6. Finalize questions and translations JSON.
   - Apply only agreed changes to the live files.
   - Confirm question count, template distribution, answer uniqueness, asset filenames, and translations after each change.

7. Validate the complete At the Library level.
   - Parse JSON and verify every referenced asset.
   - Check vocabulary coverage and unintended repetition.
   - Play through every question at normal text scale and supported accessibility text scale.
   - Check audio timing, feedback, progression, and question totals.

## 3. Video Dialog

**Librarian:** Hello! How can I help you today? (`to help`)
**Patron:** I want to return this book. (`to return something`) — `DialogueCompletion`
**Librarian:** Please show me your card, and I will check your account. (`to show`) — `ClozeSequence`
**Patron:** I also want to find a book about history. (`to find`)
**Librarian:** Let me search for one and see what is available. (`to search`, `available`) — `SentenceBuilder`
**Patron:** Great. Can I borrow it today? (`to borrow`) — `AppearDisappear`
**Librarian:** Yes. Enjoy your reading! (`none`)

## 4. Video Scripts

### Clip 1.1: Returning a Book (Lines 1–3, approximately 10.5s)

> **Prompt:** Create an approximately 12-second, 1:1 square, clean professional flat-vector lifestyle animation for adult English learners. Begin exactly from the supplied starting image. Preserve the character identities, faces, hairstyles, adult proportions, clothing, library layout, furniture, objects, lighting, colors, and fixed camera composition throughout. Use one continuous fixed wide shot with no cuts, zooms, pans, reframing, camera movement, scene changes, or transition effects.

Show exactly two adult characters. Librarian is the adult woman with dark hair in a neat low bun, wearing a muted teal cardigan, cream blouse, and navy trousers. She stands behind the left-center side of the wooden circulation desk. Patron is the adult man with short brown hair, wearing an olive-green jacket, light-blue shirt, and dark trousers. He stands on the right side of the desk facing Librarian.

Keep the bookshelves, window, circulation desk, computer monitor, keyboard, scanner, and background book cart fixed. The distinct green hardcover history book remains visible on the cart throughout. Patron begins holding one closed blue hardcover return book. His plain library card is hidden at the start.

Use natural synchronized mouth movements and clear conversational turn-taking. Librarian has a warm, calm adult female voice. Patron has a polite adult male voice. Only the named character speaks. The listening character keeps their mouth completely closed. Do not overlap voices or add dialogue, narration, background speech, music, or sound effects. Preserve every line exactly without paraphrasing, shortening, omitting, repeating, or reordering words.

Begin with a quiet 0.4-second opening hold. Both mouths are closed. Librarian looks attentively at Patron with her hands relaxed near the desk. Patron holds the blue book naturally near waist level.

Line 1 — Librarian gives a small welcoming smile and one restrained open-hand gesture toward Patron. Librarian says, “Hello! How can I help you today?” Patron listens silently with his mouth closed.

After Librarian finishes, hold a natural silent settled beat for approximately 0.4 seconds. Both mouths remain closed. Patron may shift the blue book slightly toward the desk but must not speak early.

Line 2 — Patron looks at Librarian, lightly indicates the blue book, and says, “I want to return this book.” During the sentence, he places the blue book flat on the desk near him. Librarian watches attentively with her mouth closed.

After Patron finishes, hold another silent settled beat for approximately 0.4 seconds. Both mouths remain completely closed. Librarian briefly looks toward the returned book but does not speak or gesture early.

Line 3 — Librarian makes one small polite open-palm gesture toward Patron and says, “Please show me your card, and I will check your account.” Patron waits until Librarian says “show me your card,” then calmly takes out one plain library card and places it flat on the desk beside the blue return book. Patron remains silent with his mouth closed.

End on a stable silent continuity frame matching the supplied ending image. Librarian stands behind the desk with her hands relaxed near the keyboard, looking patiently toward Patron. Patron stands opposite her with both empty hands lowered. The blue return book and plain library card rest separately and clearly on the desk near Patron. The green history book remains visible on the background book cart. Both mouths are closed.

Timing targets—do not display them on screen: 0.0–0.4 opening hold; 0.4–3.0 Line 1; 3.0–3.4 silent pause; 3.4–5.8 Line 2; 5.8–6.2 silent pause; 6.2–10.8 Line 3; 10.8–12.0 final continuity hold.

Do not show readable words, letters, numbers, book titles, library signs, computer text, captions, labels, logos, watermarks, or speech bubbles. Do not add other patrons or staff. Avoid exaggerated gestures, premature actions, character sliding, camera drift, furniture movement, book or card duplication, objects appearing or disappearing unexpectedly, floating objects, malformed hands, distorted anatomy, clothing changes, or changes in character size.


### Clip 1.2: Finding and Borrowing a History Book (Lines 4–7, approximately 12.5s)

> **Prompt:** Create an approximately 12.5-second, 1:1 square, clean professional flat-vector lifestyle animation for adult English learners. Begin exactly from the supplied starting image. Treat the supplied image as the authoritative reference for the characters, faces, hairstyles, proportions, clothing, poses, camera framing, library layout, furniture, object positions, lighting, colors, and illustration style. Use one continuous fixed wide shot with no cuts, zooms, pans, reframing, camera movement, scene changes, or transition effects.

Show exactly two adults. Librarian is the woman on the left with dark hair in a neat low bun, wearing a muted teal cardigan over a cream blouse and navy trousers. She stands behind the short wooden circulation desk. Patron is the man on the right with short brown hair, wearing an olive-green jacket over a light-blue shirt, dark trousers, and brown shoes. He stands facing Librarian with both hands lowered.

Preserve the exact library arrangement shown in the starting image. Tall bookshelves fill the left and rear walls. A large window is centered behind the characters. The wooden circulation desk is left-center, with the computer monitor and keyboard in their existing positions. One closed blue return book rests on the desk, with the small plain library card resting on top of it exactly as shown. A small wooden book cart stands immediately to the right of the desk, between the desk and Patron. The cart contains several books, including one distinct green hardcover history book standing upright at the front. Do not move or redesign the cart before the green book is selected.

Use natural synchronized mouth movements and clear conversational turn-taking. Librarian has a warm, calm adult female voice. Patron has a polite adult male voice. Only the named character speaks. The listening character keeps their mouth completely closed. Do not overlap voices or add dialogue, narration, background speech, music, or sound effects. Preserve every line exactly without paraphrasing, shortening, omitting, repeating, or reordering words.

Begin with a quiet 0.4-second opening hold matching the supplied image. Both mouths are closed. Librarian’s hands rest near the keyboard. Patron’s hands are lowered. The green history book remains upright in the cart. The library card remains on top of the blue return book.

Line 1 — Patron briefly looks toward the bookshelves on the left and makes one small open-hand gesture toward them while saying, “I also want to find a book about history.” Librarian watches him silently with her mouth closed. Patron lowers his hand after finishing.

After Patron finishes, hold a natural silent pause for approximately 0.4 seconds. Both mouths remain closed. Librarian turns her attention toward the computer but must not type or speak before the pause ends.

Line 2 — Librarian briefly types on the keyboard while saying, “Let me search for one and see what is available.” Near the end of the sentence, she stops typing, looks toward the small cart beside the desk, and makes one restrained open-hand indication toward the upright green history book. Patron follows her gaze without speaking or moving his mouth. Keep the monitor screen unreadable.

After Librarian finishes, hold a brief silent turn-taking pause for approximately 0.3 seconds. Both mouths are closed. Librarian relaxes her hand. Patron looks toward the green book but does not touch it yet.

Line 3 — Patron makes one small low gesture toward the green history book and says, “Great. Can I borrow it today?” Librarian looks attentively at Patron without speaking or moving her mouth.

After Patron completes the full sentence, hold approximately 0.4 seconds of silence. Both mouths remain completely closed. Patron lowers his hand and waits. The green book remains in the cart during this pause. Librarian must not begin her reply early.

Line 4 — Librarian smiles, gives one small confirming nod, and makes a restrained open-hand gesture toward the green history book while saying, “Yes. Enjoy your reading!” Only after Librarian begins this reply, Patron reaches down naturally, lifts the single green history book from the nearby cart, and brings it to waist level with both hands. Patron remains silent with his mouth closed. Librarian does not reach across the desk or take the book herself.

End on a calm stable frame held for approximately 0.9 seconds. Librarian remains behind the desk with a friendly expression and hands relaxed near the keyboard. Patron stands on the right holding the single green history book naturally with both hands at waist level. The green book is no longer in the cart and must not be duplicated. The other books remain in the cart. The blue return book remains on the desk with the plain library card still resting on top of it. Both mouths are completely closed.

Timing targets—do not display them on screen: 0.0–0.4 opening hold; 0.4–3.1 Line 1; 3.1–3.5 silent pause; 3.5–6.8 Line 2; 6.8–7.1 silent pause; 7.1–8.9 Line 3; 8.9–9.3 silent pause; 9.3–11.6 Line 4 and Patron takes the green book; 11.6–12.5 final hold.

Do not show readable words, letters, numbers, book titles, library signs, computer text, captions, labels, logos, watermarks, or speech bubbles. Do not add other patrons or staff. Do not separate or reposition the card and blue book. Avoid premature book retrieval, Librarian reaching for the cart, duplicated books, disappearing objects, exaggerated gestures, character sliding, camera drift, furniture movement, malformed hands, merged fingers, floating objects, distorted anatomy, clothing changes, character redesign, or changes in character size.

## 5. Image Dialogs

`<TBD — image dialogue placeholders for approved vocabulary best taught through a still visual/audio context. Do not add entries here until agreed.>`

### Image Question Placeholder

- **Context:** `<TBD>`
- **Adult characters:** `<TBD>`
- **Dialogue:** `<TBD>`
- **Teaching targets:** `<TBD>`
- **Template:** `<TBD>`
- **Image filename:** `<TBD>`
- **Image description:** `<TBD>`

## 6. Questions JSON Structure

`<TBD — questions.json content goes here once Section 3's dialogue and question-type mapping are agreed. Not filled in yet.>`

## 7. Translations JSON Structure

`<TBD — proposed changes to translations_list go here for review before being applied to the live translations.json. Do not duplicate the current live file here until a change is actually proposed.>`

## 9. Message Pipeline

Maximum messages: 20.
Order: oldest to newest.
Each agent appends one named message using `Claude`, `Codex`, or `Antigravity`; the Developer (`d`/`Developer`) may also comment directly.
When appending message 21, remove the oldest message first (FIFO), then append the new one.
Only current At the Library discussion messages belong here.
Formatting rule: every agent's acceptance/agreement list must use `✅` green checkboxes; every issue, disagreement, or open item must use `❌` red crosses. Use these markers consistently in all new pipeline comments.

---

<!-- The At the Library discussion starts here. -->
