# In the Kitchen — Adult Level Content Plan

## Current Topic

`<TBD — describe what this planning round is for: e.g. adding a VideoConversation intro to the existing adult In the Kitchen level, reworking specific questions, etc.>`

## 1. Decisions

- Scope is adults only. Kids content (`in-the-kitchen/kids/`) will be planned separately.
- This document belongs exclusively to the In the Kitchen level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- Existing level distributions must be checked before adding vocabulary so words already taught in earlier levels are not repeated without a clear teaching reason (note: `kitchen-items-1`/`kitchen-items-2` are separate image-only levels covering tangible kitchen-object nouns — check them before adding object vocabulary here).
- Vocabulary taught primarily by image-only levels must be checked before selecting tangible nouns for this level.
- `questions.json` and `translations.json` currently hold **live, already-shipped** content (14 approved vocabulary items, 15 questions across `imageQuizTemplate-1`, `ClozeSequence`, `ConvoTemplate-1`, `AppearDisappear`, `WordPairs`, `DialogueCompletion`). Nothing has been cleared yet — no live file changes happen until new questions are proposed and agreed here first.
- Adult-oriented characters and settings should be used throughout the level. Any secondary characters must be older teenagers or adults, with mature proportions and styling; do not use young children in adult-level scenes (standing rule from the At the School level).
- Sharp objects (knives, etc.) may appear as kitchen props consistent with the word `sharp`, but any cutting/slicing action must be depicted safely — no exaggerated risk, no blade-to-body contact, standard cooking-demo caution.
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.
- **Section 3 shows the dialogue with inline annotations** (developer preference): each line gets the approved word(s) it carries and, where graded, its question template in parentheses/suffix. Full mechanic detail (exact answer, distractors, audio1/audio2 mapping, timestamps) still lives in Section 6 — Section 3's tags are a quick-reference summary, not the source of truth for those specifics.
- **Video prompts must be fully self-contained** (see `all-ai-common/rules/rules.md` § Video Generator Prompt Authoring): every generation-relevant detail — room/character description, exact dialogue, per-line gestures, required silent beats, the held final frame, negative constraints — must live inside the prompt block itself. A prompt may instead rely on a separately-supplied starting/reference image (as with any clip after the first, or when the developer will attach a generated reference image at paste-time) — confirm which approach applies before assuming a prompt with no inline scene description is incomplete.
- **Section 3/6 sequencing**: Section 6 (and Section 4's clip prompts) only get drafted after Section 3's dialogue and question-type mapping are actually agreed — not before.

## 2. Actions

1. Confirm the approved teaching scope from `translations.json`.
   - Review earlier levels and `kitchen-items-1`/`kitchen-items-2` for vocabulary overlap.
   - Classify each of the approved words as required, reinforcement, or remove.
   - Identify any gaps in the approved In the Kitchen teaching scope not yet covered.

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

7. Validate the complete In the Kitchen level.
   - Parse JSON and verify every referenced asset.
   - Check vocabulary coverage and unintended repetition.
   - Play through every question at normal text scale and supported accessibility text scale.
   - Check audio timing, feedback, progression, and question totals.

## 3. Video Dialog

**Alex:** Can you help me cook breakfast? (`to cook`, incidental `breakfast`) — `ClozeSequence` (blank on `cook`; keeps a confirm clip so Q2's blind pick isn't preceded by silence)
**Sam:** Sure. I like eating breakfast with you. (`to eat`) — `DialogueCompletion`
**Alex:** I want to try a new potato recipe. (`recipe`) — `SentenceBuilder`
**Sam:** Great! I'll slice the potatoes. (`to slice`) — `ClozeSequence`
**Alex:** Be careful. The knife is very sharp. (`sharp`) — `AppearDisappear`
**Sam:** What are we going to drink? (`none`)
**Alex:** I'll drink tea, and you can have orange juice. (`to drink`) — `ClozeSequence`

Speaker names (`Alex`/`Sam`) are placeholders pending developer preference — the original draft used bare `A`/`B` labels, which every other level's dialogue avoids in favor of real names or role labels.

## 4. Video Scripts

### Clip1.1

Prompt: Create a 14-second, 1:1 square animation beginning exactly from the supplied starting image. Preserve the characters, clothing, faces, proportions, colors, lighting, camera composition, kitchen arrangement, and all props without redesign. Maintain the supplied style throughout; no 3D rendering, photorealism, or style drift.

Use one continuous fixed shot with no cuts, zooms, pans, reframing, or transitions. Begin with both characters silent and settled in their neutral starting poses. Use clear natural speech, accurate lip-sync, understated expressions, and restrained gestures. Only the speaking character moves their mouth. Do not overlap dialogue.

Timing and actions:

0.0–0.4s: Brief silent hold on the supplied starting frame.
0.4–2.7s — Mia: “Can you help me cook breakfast?”
Mia looks at Leo and makes a small open-hand gesture toward the ingredients.
2.7–3.0s: Brief silent beat. Mia relaxes her hand.
3.0–5.8s — Leo: “Sure. I like eating breakfast with you.”
Leo smiles gently and gives a small agreeable nod.
5.8–6.1s: Brief silent beat.
6.1–9.4s — Mia: “I want to try a new potato recipe.”
Mia briefly indicates the potatoes and the open cookbook, then calmly places one potato onto the cutting board.
9.4–9.7s: Brief silent beat. Mia moves her hands safely away from the cutting board.
9.7–11.8s — Leo: “Great! I’ll slice the potatoes.”
Leo looks at the potato and calmly grips the knife by its handle.
11.8–13.5s: Leo positions the knife over the potato and slowly begins the first slicing motion. Do not show a complete series of cuts. Mia watches from a safe distance with a relaxed expression.
13.5–14.0s: Hold a stable final frame as Leo begins the first slice.

No additional dialogue, narration, subtitles, captions, speech bubbles, background music, or prominent sound effects.

### Clip1.2

Prompt: Create a **12-second, 1:1 square animation** beginning exactly from the supplied starting image keeping the colors and the brightness exactly the same. Treat the image as the authoritative reference for the characters, clothing, faces, proportions, colors, lighting, camera composition, kitchen arrangement, object positions, and current poses. Preserve everything without redesign.

No anime styling, glossy 3D rendering, photorealism, or visual-style drift.

Use one continuous fixed shot with no cuts, zooms, pans, reframing, or transitions. Use clear natural speech, accurate lip-sync, subtle facial animation, and restrained gestures. Only the speaking character moves their mouth. Do not overlap dialogue.

**Timing and actions:**

* **0.0–0.3s:** Brief silent hold on the supplied starting frame in which Leo is cutting a potato.

* **0.3–2.8s — Mia:** “Be careful. The knife is very sharp.”
  Mia watches Leo’s hands and makes a small cautioning gesture, keeping her hand safely away from the cutting board.

* **2.8–3.4s:** Leo carefully completes only the first slow slice, then places the knife flat on the cutting board with the blade facing away from both characters.

* **3.4–5.9s — Leo:** “What are we going to drink?”
  With his hands safely away from the knife, Leo looks at Mia and makes a small questioning gesture.

* **5.9–6.3s:** Brief silent beat. Leo returns to a relaxed pose.

* **6.3–9.9s — Mia:** “I’ll drink tea, and you can have orange juice.”
  Mia responds with a gentle smile and a small conversational gesture. Do not make any beverages appear if they are not already visible in the supplied image.

* **9.9–11.4s:** Leo smiles and gives a small agreeable nod. Both characters settle into relaxed neutral poses.

* **11.4–12.0s:** Hold a stable final frame. Keep the sliced potato and knife resting safely on the cutting board.

No additional dialogue, narration, subtitles, captions, speech bubbles, background music, or prominent sound effects.

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
Only current In the Kitchen discussion messages belong here.
Formatting rule: every agent's acceptance/agreement list must use `✅` green checkboxes; every issue, disagreement, or open item must use `❌` red crosses. Use these markers consistently in all new pipeline comments.

---

<!-- The In the Kitchen discussion starts here. -->
