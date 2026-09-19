# Grocery Shopping — Adult Level Content Plan

## Current Topic

`<TBD — describe what this planning round is for: e.g. adding a VideoConversation intro to the existing adult Grocery Shopping level, reworking specific questions, etc.>`

## 1. Decisions

- Scope is adults only. Kids content (`grocery-shopping/kids/`) will be planned separately.
- This document belongs exclusively to the Grocery Shopping level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- Existing level distributions must be checked before adding vocabulary so words already taught in earlier levels are not repeated without a clear teaching reason (note: `grocery-list-1`/`grocery-list-2` are separate image-only levels covering tangible grocery-item nouns — check them before adding object vocabulary here).
- Vocabulary taught primarily by image-only levels must be checked before selecting tangible nouns for this level.
- `questions.json` and `translations.json` now define 20 approved vocabulary items and 21 questions: 15 `VideoConversation` questions plus 6 existing non-video questions.
- Adult-oriented characters and settings should be used throughout the level. Any secondary characters must be older teenagers or adults, with mature proportions and styling; do not use young children in adult-level scenes (standing rule from the At the School level).
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.
- **Section 3 shows the dialogue with inline annotations** (developer preference): each line gets the approved word(s) it carries and, where graded, its question template in parentheses/suffix. Full mechanic detail (exact answer, distractors, audio1/audio2 mapping, timestamps) still lives in Section 6 — Section 3's tags are a quick-reference summary, not the source of truth for those specifics.
- **Video prompts must be fully self-contained** (see `all-ai-common/rules/rules.md` § Video Generator Prompt Authoring): every generation-relevant detail — room/character description, exact dialogue, per-line gestures, required silent beats, the held final frame, negative constraints — must live inside the prompt block itself. A prompt may instead rely on a separately-supplied starting/reference image (as with any clip after the first, or when the developer will attach a generated reference image at paste-time) — confirm which approach applies before assuming a prompt with no inline scene description is incomplete.
- **Section 3/6 sequencing**: Section 6 (and Section 4's clip prompts) only get drafted after Section 3's dialogue and question-type mapping are actually agreed — not before.
- **No back-to-back silent question boundaries**: when mapping consecutive lines to templates, every question-to-question boundary needs either an outgoing confirm clip (the preceding question has an `audio_file2`) or an incoming lead-in clip (the next question has its own `audio_file1`/lead-in). `AppearDisappear` has no confirm; `SentenceBuilder`/`DialogueCompletion` (as used here — blind pick/build of the character's own line) have no lead-in. Never place one of the no-confirm types immediately before one of the no-lead-in types, or the video goes silent between the two questions.
- **A single spoken line is never split across `audio_file1`/`audio_file2`** — one character's one sentence always plays as one whole clip, either entirely before the pause (`audio_file1`) or entirely after answering (`audio_file2`), never partly on each side. This applies to `ClozeSequence` too: the blanked sentence itself is one line — do not slice it at the blank point into a "before the blank" `audio_file1` and an "after the blank" `audio_file2`. If the blanked line has no natural preceding setup line to serve as `audio_file1`, leave `audio_file1` unset entirely and let `audio_file2` carry the complete blanked sentence as a single clip after the answer, exactly like a blind `DialogueCompletion`/`SentenceBuilder`. (Found and fixed on this level: `grocery-shopping1` Q2/Q5 and `grocery-shopping2` Q2 originally split one sentence across setup+confirm — corrected to full-line confirm clips with no `audio_file1`.)

## 2. Actions

1. Confirm the approved teaching scope from `translations.json`.
   - Review earlier levels and `grocery-list-1`/`grocery-list-2` for vocabulary overlap.
   - Classify each of the approved words as required, reinforcement, or remove.
   - Identify any gaps in the approved Grocery Shopping teaching scope not yet covered.

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

7. Validate the complete Grocery Shopping level.
   - Parse JSON and verify every referenced asset.
   - Check vocabulary coverage and unintended repetition.
   - Play through every question at normal text scale and supported accessibility text scale.
   - Check audio timing, feedback, progression, and question totals.

## 3. Video Dialog

### Dialogs with Words

#### Clip 1 — Comparing Products and Carrying the Rice

**Sara:** Are you ready to shop for the week? (`to shop`) — `AppearDisappear`
**Tom:** Yes, I need to buy rice and pasta. (`to buy`) — `DialogueCompletion`
**Sara:** Let's compare the brands and prices first. (`to compare`, `brand`) — `ClozeSequence` (double blank)
**Tom:** Good idea. How much rice do we need? (`how much`) - `ClozeSequence`
**Sara:** We need two large bags. Each one weighs five kilograms. (`to weigh`) - `ClozeSequence`
**Tom:** I can't carry both bags. (`to carry`) — `SentenceBuilder`
**Sara:** I'll help you carry them, and I'll pay by credit card. (`to carry`, `to pay`) — `ClozeSequence` (double blank)

#### Clip 2 — Returning a Bag of Rice

**Customer:** I'd like to return this large bag of rice for a refund. (`AppearDisappear`)
**Clerk:** Please wait here at the checkout. (`to wait`, `checkout`) — `DialogueCompletion`
**Customer:** Can I choose another bag instead? (`to choose`) — `SentenceBuilder`
**Clerk:** Yes, but I need your receipt to calculate the price difference. (`receipt`, `to calculate`) — `ClozeSequence`
**Customer:** Do you also need to check the weight? (`weight`) - `SentenceBuilder`
**Clerk:** Yes. Please load the bag onto the scale. (`to load`) — `AppearDisappear`
**Customer:** How much does the new bag cost? (`how much`)
**Clerk:** Its quality is better. It costs two dollars more, but you save one dollar with the discount. (`quality`, `to cost`, `discount`) — `ClozeSequence`
**Customer:** I think I can afford it. I have enough money. (`to afford`, `enough`) — `ClozeSequence`

### Simple Dialogs

#### Clip 1

Sara: Are you ready to shop for the week?
Tom: Yes, I need to buy rice and pasta.
Sara: Let's compare the brands and prices first.
Tom: Good idea. How much rice do we need?
Sara: We need two large bags. Each one weighs five kilograms.
Tom: I can't carry both bags.
Sara: I'll help you carry them, and I'll pay by credit card.

#### Clip 2

Customer: I'd like to return this large bag of rice for a refund.
Clerk: Please wait here at the checkout.
Customer: Can I choose another bag instead?
Clerk: Yes, but I need your receipt to calculate the price difference.
Customer: Do you also need to check the weight?
Clerk: Yes. Please load the bag onto the scale.
Customer: How much does the new bag cost?
Clerk: Its quality is better. It costs two dollars more, but you save one dollar with the discount.
Customer: I think I can afford it. I have enough money.

## 4. Video Scripts

### Clip 1.1 Prompt: 

Create an approximately **11-second, 1:1 square animation. Use the style of the reference image.

Use one continuous fixed shot with no cuts, zooms, pans, reframing, or scene changes. Keep gestures natural and restrained. Only the active speaker’s mouth moves; the listener reacts silently with subtle eye movement, a small nod, or a mild change of expression. Return each character to a relaxed pose after speaking. Do not add subtitles, captions, speech bubbles, narration, or extra dialogue.

**0.0–0.4s:** Hold the supplied starting pose briefly.

**0.4–2.6s — Sara “Are you ready to shop for the week?”

**2.9–5.2s — Tom: “Yes, I need to buy rice and pasta.”

**5.5–7.8s — Sara: "Let’s compare the brands and prices first.”

**8.1–10.5s — Tom: “Good idea. How much rice do we need?”

**10.5–11.0s:** Hold silently with both characters looking naturally, creating a stable final frame for the next clip.


### Clip 1.2 prompt

Create an approximately 10-second, 1:1 square animation beginning exactly from the supplied starting image using the same style of the image. Treat the supplied starting image as the authoritative visual reference. Match its color palette, brightness, exposure, contrast, saturation, white balance, and lighting exactly from the first frame, and maintain them consistently throughout the entire clip. No color shifts, brightness changes, relighting, flickering, or gradual visual drift.  Preserve the characters’ identities, faces, hairstyles, proportions, clothing, positions, visual style, lighting, environment, objects, and camera composition throughout.

Use one continuous fixed shot with no cuts, zooms, pans, reframing, or scene changes. Only the active speaker’s mouth moves. Do not add subtitles, captions, speech bubbles, narration, or extra dialogue.

0.0–0.4s: Silent opening hold.

0.4–3.5s — Sara: “We need two large bags. Each one weighs five kilograms.”

3.5–3.9s: Brief pause.

3.9–5.8s — Tom: “I can’t carry both bags.”

5.8–6.2s: Brief pause.

6.2–9.5s — Sara: “I’ll help you carry them, and I’ll pay by credit card.”

9.5–10.0s: Silent final hold.

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
Only current Grocery Shopping discussion messages belong here.
Formatting rule: every agent's acceptance/agreement list must use `✅` green checkboxes; every issue, disagreement, or open item must use `❌` red crosses. Use these markers consistently in all new pipeline comments.

---

<!-- The Grocery Shopping discussion starts here. -->
