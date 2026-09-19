# In the Bathroom — Adult Level Content Plan

## Current Topic

`<TBD — describe what this planning round is for: e.g. adding a VideoConversation intro to the existing adult In the Bathroom level, reworking specific questions, etc.>`

## 1. Decisions

- Scope is adults only. Kids content (`in-the-bathroom/kids/`) will be planned separately.
- This document belongs exclusively to the In the Bathroom level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- Existing level distributions must be checked before adding vocabulary so words already taught in earlier levels are not repeated without a clear teaching reason (note: `bedroom-bathroom-items` is a separate image-only level covering tangible bathroom nouns — check it before adding object vocabulary here).
- Vocabulary taught primarily by image-only levels must be checked before selecting tangible nouns for this level.
- `questions.json` and `translations.json` currently hold **live, already-shipped** content (13 approved vocabulary items, 9 questions across `ConvoTemplate-1`, `AppearDisappear`, `WordPairs`, `ClozeSequence`, `DialogueCompletion`, `SentenceBuilder`). Nothing has been cleared yet — no live file changes happen until new questions are proposed and agreed here first.
- Adults-only characters and settings should be used throughout the level.
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.

## 2. Actions

1. Confirm the approved teaching scope from `translations.json`.
   - Review earlier levels and `bedroom-bathroom-items` for vocabulary overlap.
   - Classify each of the approved words as required, reinforcement, or remove.
   - Identify any gaps in the approved In the Bathroom teaching scope not yet covered.

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

7. Validate the complete In the Bathroom level.
   - Parse JSON and verify every referenced asset.
   - Check vocabulary coverage and unintended repetition.
   - Play through every question at normal text scale and supported accessibility text scale.
   - Check audio timing, feedback, progression, and question totals.

## 3. Video Dialog

### Narrative Setting & Characters

- **Level:** In the Bathroom, adult learners (characters may be any age, confirmed by `d`).
- **Setting:** "Morning Bathroom Routine" — a home bathroom before school/work.
- **Characters:** Mom (adult woman) and her Kid (young child), household morning routine.
- **Teaching purpose:** Introduce and reinforce 7 approved In the Bathroom vocabulary items through a natural parent/child morning routine conversation.

### Approved Video Dialogue

**Exchange 1:**
- **Mom** *(prompt, spoken in full)*: "I want you to take a shower."
- **Kid** *(quizzed reply)*: "But I am not dirty!"

**Exchange 2:**
- **Mom** *(prompt, spoken in full)*: "Just look in the mirror."
- **Kid** *(recall target — spoken in full during setup, then reconstructed from tiles)*: "I can just wash my hands and use soap."

**Exchange 3:**
- **Mom** *(prompt, spoken in full)*: "No, you need to clean your body."
- **Kid** *(quizzed line — reconstructed from word tiles in order)*: "Okay, do I comb my hair too?"

**Exchange 4:**
- **Mom** *(quizzed line, blank)*: "Yes, you are going _____ your hair too."

### Video Question Mapping

- **Q1** (Exchange 1, `DialogueCompletion`): Kid selects the full reply from multiple choices; correct answer *"But I am not dirty!"* tests `dirty`. Mom's line provides intentional incidental exposure to `to take a shower`. Distractors: `["Okay, I will use the shampoo now.", "Yes, I need to clean my room first.", "No, I already combed my hair."]`.
- **Q2** (Exchange 2, `AppearDisappear`): Recall question — Kid's line *"I can just wash my hands and use soap."* is spoken in full during setup audio, then the learner reconstructs it from word tiles. Tests `to wash` and `to use` together (one sentence, two graded targets — deliberate, per Antigravity's earlier double-target pattern). Mom's line provides intentional incidental exposure to `to look in the mirror`. Distractors: `["dirty", "towel", "wet", "dry"]`.
- **Q3** (Exchange 3, `SentenceBuilder`): Learner arranges word tiles into Kid's question *"Okay, do I comb my hair too?"*, testing `to comb hair` through word order. Mom's line provides intentional incidental exposure to `to clean`.
- **Q4** (Exchange 4, `ClozeSequence`): Mom's line *"Yes, you are going _____ your hair too."* → answer `["to comb"]`, testing the infinitive verb form of `to comb hair` (grammar-focus question, per `d`'s original framing). Distractors: `["comb", "combing", "is comb"]`.

## 4. Video Scripts

### Overview & Production Parameters

- **Target Level**: Adults Level (In the Bathroom)
- **Art Style**: Clean professional flat vector lifestyle animation, consistent with `in-the-bedroom`/`waking-up` character design language — clear dark outlines, polished editorial/lifestyle look (not chunky preschool clip-art, not photoreal, not 3D, not anime). Bright, everyday morning bathroom palette (soft whites, pale blues/teals, warm skin tones). Full atmospheric scene with subtle lighting/shadow gradients, natural proportions for both an adult and a child character, subtle expressions, natural character acting/lip-sync.
- **Aspect Ratio**: 1:1 square format (1080x1080), delivered center-cropped to 720x720 matching the established level video pipeline.
- **Audio & TTS**: Natural English voices — Mom: warm, patient adult female voice; Kid: bright, slightly reluctant child voice.
- **Target Videos**:
  1. `in-the-bathroom1.mp4`: **~24 seconds** target for the video generator (estimate, not measured — see pipe for basis). Real per-line timing/timestamps for Section 6 still wait on measured audio once the video exists, per the bedroom precedent.

### Video 1 — Morning Bathroom Routine (`in-the-bathroom1`)

#### Setting & Characters
- **Location**: Home bathroom interior in the morning. Strict left-to-right lateral layout: a doorway on the **far-left wall** (Kid's entry/exit point); a **center walkway** with a sink and wall mirror; a shower/tub area against the **far-right wall**. Bright morning daylight through a small window, clean everyday tile/fixture palette. `<Not yet checked against `bedroom-bathroom-items` reference art for exact fixture shapes/colors — worth a quick pass before final generation to keep fixture design consistent across levels.>`
- **Characters**:
  - **Mom**: Adult woman, casual morning clothes, standing near the doorway or sink.
  - **Kid**: Young child, pajamas or morning clothes, reluctant/playful posture.

#### Clip 1.1: Shower Request & Refusal (Exchanges 1–2, `<TBD>`s)
- **Visual Prompt:**
  > **Prompt:** Create a 13-second, 1:1 square, clean professional flat-vector lifestyle animation for adult English learners. Use clear, consistent dark outlines, a polished editorial/lifestyle look, and a bright everyday morning palette with soft whites, pale blues and teals, and warm skin tones.

Setting: a tidy home bathroom in the morning, illuminated by soft daylight through a small window. Arrange the room clearly from left to right on one horizontal band: a doorway on the far-left wall, a sink against the center wall with a mirror above it and a soap dispenser beside the faucet, and a shower-and-tub area with a clearly visible showerhead and curtain on the far-right wall.

Use one wide, fixed camera angle that keeps the doorway, sink and mirror, both characters, and shower area clearly visible within the square frame throughout. Maintain one continuous shot with consistent character positions and room geometry. Do not use cuts, zooms, pans, angle changes, scene changes, or transition effects.

Mom, an adult woman wearing casual morning clothes, stands near the doorway on the left. Kid, a young child wearing pajamas, stands exactly one small step back from the sink.

Arrange the complete exchange naturally within the full 13-second duration. Preserve the exact dialogue wording and order. Pace the lines clearly with brief natural pauses and only one character speaking at a time. Coordinate every gesture with its corresponding line so the complete exchange and a brief final hold fit comfortably within the video. After completing a pointing or indicating gesture, each character naturally lowers or relaxes the gesturing arm instead of holding it frozen into the next speaking turn.

Sequence of events, in strict order:

Mom gestures gently toward the shower while calmly saying: “I want you to take a shower.” As she finishes, she naturally lowers her hand to a relaxed position.
Only after Mom finishes speaking, Kid crosses their arms with mild, playful resistance rather than genuine anger and replies: “But I am not dirty!” As the line ends, Kid gradually relaxes their arms instead of remaining rigidly frozen.
Only after Kid finishes speaking, Mom tilts her head toward the mirror and points clearly at it with a patient, knowing smile while saying: “Just look in the mirror.” After finishing the gesture, she naturally lowers her pointing hand.
Only after Mom finishes speaking, Kid takes one small step forward to the sink and shrugs briefly with a cheeky grin while saying: “I can just wash my hands and use soap.” Kid naturally lowers the shrug, then, during “wash my hands,” reaches toward the faucet as if about to turn it on. During “use soap,” Kid moves the same hand clearly toward the soap dispenser. Keep these actions simple, natural, and easy to read.
Briefly hold a stable final frame with Mom standing near the doorway in a relaxed posture and wearing a patient expression, and Kid beside the sink mid-reach toward the soap dispenser.

Only the named character speaks each line. Do not paraphrase, shorten, omit, repeat, interrupt, or overlap any dialogue. Use smooth, restrained character acting, natural synchronized mouth movements, clear facial expressions, and readable gestures. Avoid frozen or mechanically held poses between speaking turns. Keep Kid fully dressed and outside the shower throughout the clip. Do not show Kid entering the shower, turning on actual running water, or beginning to wash. No captions, speech bubbles, labels, logos, or readable text, letters, or numbers anywhere in the frame.
- **Dialogue Script & Timing:** `<TBD — pending real audio-measured durations for all 4 lines, per the bedroom precedent of not hand-estimating tight windows; overall video target is ~24s, see Section 9 pipe>`

#### Clip 1.2: Cleaning & Comb Grammar (Exchanges 3–4, `<TBD>`s)
- **Visual Prompt:** Create a 12-second, 1:1 square, clean professional flat-vector lifestyle animation for adult English learners. Use clear, consistent dark outlines, a polished editorial/lifestyle look, and a bright everyday morning palette with soft whites, pale blues and teals, and warm skin tones.

Continue directly from the supplied starting image. Preserve the character designs, faces, hairstyles, clothing, proportions, bathroom layout, fixtures, colors, lighting, and camera composition throughout. Do not redesign or replace either character or any environmental element.

Setting: the same tidy home bathroom in the morning, illuminated by soft daylight through the small window. A small, flat teal comb is stored inside the vanity cabinet below the sink (the same cabinet visible in the starting image), not yet visible at the start of the clip.

Use one continuous wide fixed-camera shot. Keep the doorway, Mom, Kid, sink, mirror, soap dispenser, and shower area visible throughout. Do not use cuts, zooms, pans, camera movements, angle changes, scene changes, or transition effects.

Begin Mom’s first line immediately at 0.0 seconds with no introductory silence. Perform gestures during their corresponding dialogue instead of adding separate pauses. Preserve every line exactly and complete all dialogue by 10.5 seconds. Follow the target timings closely while maintaining clear, natural speech. Do not add long pauses or extend the first two exchanges.

0.0–3.0 seconds

Mom gently shakes her head once and raises one relaxed open hand while saying: “No, you need to clean your body.”

During the line, Kid lowers the hand from the sink area and turns their attention toward Mom. Mom naturally lowers her hand after speaking.

3.0–6.5 seconds

Kid crouches slightly, opens one of the vanity cabinet doors below the sink, and pulls out a small flat teal comb, then stands and holds it up at shoulder level for Mom to see while asking: “Okay, do I comb my hair too?”

As Kid finishes the question, Kid naturally lowers the comb to chest level while continuing to hold it visibly, closing the cabinet door with a light nudge or free hand. Kid looks at Mom with a cooperative, questioning expression. The comb remains away from the hair, and Kid does not begin combing.

6.5–10.5 seconds

Mom nods gently with a warm, approving smile and gestures toward Kid’s hair while saying: “Yes, you are going to comb your hair too.”

Kid listens while loosely holding the comb at chest level. Kid does not raise it toward the hair. After finishing her line, Mom naturally lowers her gesturing hand.

10.5–12.0 seconds

Both characters settle into a stable final pose. Kid holds the comb visibly at chest level without touching the hair. Kid stands upright and balanced, with both feet flat and visibly touching the floor. Mom remains near the doorway with relaxed arms and a patient smile. Hold this stable final pose with no additional dialogue or movement.

Only the named character speaks during each assigned interval. Do not paraphrase, shorten, omit, repeat, interrupt, or overlap any dialogue. All three lines are mandatory and must be heard completely. Use natural synchronized mouth movements, smooth restrained acting, clear expressions, and readable gestures.

Kid only displays the comb. Kid does not comb, brush, touch, or move the comb through the hair because the hair will be combed later, after the shower. Keep Kid fully dressed and outside the shower. Do not show running water, washing, showering, or entry into the bathtub.

Do not let either character float, slide, glide, shuffle, or change size. Preserve consistent anatomy, clothing, and room geometry. No captions, speech bubbles, labels, logos, or readable text, letters, or numbers anywhere in the frame.

### Production & Assembly Workflow

No separate TTS/voice generation step — dialogue audio is not produced independently; it comes from the video generator's own embedded audio track, then sliced per question (same convention as `greetings1.mp4` / `in-the-bedroom1.mp4`; see `architecture-technical-context.md`).

1. **Video Generation**: Generate Clips 1.1 and 1.2 using agreed prompts with character-reference consistency (same Mom/Kid model across both clips) and the dialogue spoken in-video.
2. **Video Concatenation** *(manual, done by `d`)*: Join Clip 1.1 and Clip 1.2 with ffmpeg into continuous `in-the-bathroom1.mp4`.
3. **Audio Slicing** *(manual, done by `d`)*: Extract question setup and confirmation audio tracks directly from the joined video's own audio stream with `ffmpeg`, matching the `audio_file1`/`audio_file2` IDs in Section 6 (`in-the-bathroom1-q1-setup` through `in-the-bathroom1-q4-confirm`).
4. **Timestamp Extraction** *(manual, done by `d`)*: Using those split audio files, measure exact dialogue boundary timestamps and update Section 6's `start_at`, `pause_at`, and `answer_until` fields.

### Generator Scripts

No clips have been generated yet. Visual prompt blocks and measured dialogue timing are still `<TBD>` pending character reference art and staging agreement — this section will be updated with paste-ready generator prompts once that's settled.

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

Proposed `VideoConversation` package for `in-the-bathroom1`, **not yet applied to the live `questions.json`** — timestamps and audio filenames are placeholders pending video production, matching the standing rule from the bedroom plan (real timestamps only after the joined video exists and is measured). This is additive to, not a replacement of, the 9 existing live questions unless `d` decides otherwise.

~~~json
{
  "levelQuestions": [
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "<TBD>",
      "pause_at": "<TBD>",
      "answer_until": "<TBD>",
      "audio_file1": "in-the-bathroom1-q1-setup",
      "audio_file2": "in-the-bathroom1-q1-confirm",
      "questionData": {
        "answer_type": "DialogueCompletion",
        "answer": "But I am not dirty!",
        "distractors": [
          "Okay, I will use the shampoo now.",
          "Yes, I need to clean my room first.",
          "No, I already combed my hair."
        ]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "<TBD>",
      "pause_at": "<TBD>",
      "answer_until": "<TBD>",
      "audio_file1": "in-the-bathroom1-q2-setup",
      "questionData": {
        "answer_type": "AppearDisappear",
        "words": "I can just wash my hands and use soap.",
        "distractors": [
          "dirty",
          "towel",
          "wet",
          "dry"
        ]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "<TBD>",
      "pause_at": "<TBD>",
      "answer_until": "<TBD>",
      "audio_file1": "in-the-bathroom1-q3-setup",
      "questionData": {
        "answer_type": "SentenceBuilder",
        "correct_order": "Okay, do I comb my hair too?"
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "<TBD>",
      "pause_at": "<TBD>",
      "answer_until": "<TBD>",
      "audio_file1": "in-the-bathroom1-q4-setup",
      "audio_file2": "in-the-bathroom1-q4-confirm",
      "questionData": {
        "answer_type": "ClozeSequence",
        "sentence": "Yes, you are going _____ your hair too.",
        "answer": [
          "to comb"
        ],
        "distractors": [
          "comb",
          "combing",
          "is comb"
        ]
      }
    }
  ]
}
~~~

Question objects use only fields the `VideoConversation` parser (`level_config.dart`) actually reads for each `answer_type` — confirmed `ClozeSequence` accepts either `"answer"` or `"answers"` for the blank-fill array, so the singular key used above (matching the bedroom precedent) parses correctly. Timestamps and audio filenames remain `<TBD>` until `in-the-bathroom1.mp4` is generated and measured.

## 7. Translations JSON Structure

`<TBD — proposed changes to translations_list go here for review before being applied to the live translations.json. Do not duplicate the current live file here until a change is actually proposed.>`

## 9. Message Pipeline

Maximum messages: 20.
Order: oldest to newest.
Each agent appends one named message using `Claude`, `Codex`, or `Antigravity`; the Developer (`d`/`Developer`) may also comment directly.
When appending message 21, remove the oldest message first (FIFO), then append the new one.
Only current In the Bathroom discussion messages belong here.
Formatting rule: every agent's acceptance/agreement list must use `✅` green checkboxes; every issue, disagreement, or open item must use `❌` red crosses. Use these markers consistently in all new pipeline comments.

---

<!-- The In the Bathroom discussion starts here. Oldest messages removed per FIFO cap (20) as new ones were appended. -->

**Claude:** Proposing a video dialogue — "Getting Ready in the Morning," Daniel and Maya in the bathroom before work (same adult character pair as `waking-up`/`in-the-bedroom`). Uses **7 distinct words** from the approved 13 (`to take a shower`, `usually`, `to brush teeth`, `to comb hair`, `to look in the mirror`, `to wash`, `dirty` — `dirty` and `usually` each appear twice for reinforcement, once incidental + once graded). Each exchange has one Daniel line (spoken in full, incidental exposure) and one Maya line (the graded target), matching the bedroom `VideoConversation` pattern — template choice per exchange checked against what its parser actually reads (`ClozeSequence` = `sentence`/`answers`/`distractors`, `AppearDisappear` = `words`/`distractors`, `DialogueCompletion` = `line1`/`answer`/`distractors`):

**Exchange 1** (`ClozeSequence`, tests `to brush teeth`):
- Daniel *(incidental: `usually`, `to take a shower`)*: "I usually take a shower first thing in the morning."
- Maya *(blank)*: "I _____ my teeth right after that." → answer `["brush"]`. Distractors: `["wash", "dry", "comb"]`.

**Exchange 2** (`AppearDisappear`, tests `to look in the mirror`):
- Daniel *(incidental: `to comb hair`)*: "Do you comb your hair before breakfast?"
- Maya *(spoken full in setup, then reconstructed from tiles)*: "I look in the mirror to comb it." Distractors: `["wash", "dry", "clean", "use"]`.

**Exchange 3** (`ClozeSequence`, tests `to wash`):
- Daniel *(incidental: `dirty`)*: "This towel looks a little dirty."
- Maya *(blank)*: "I will _____ it this afternoon." → answer `["wash"]`. Distractors: `["dry", "use", "comb"]`.

**Exchange 4** (`DialogueCompletion`, tests `usually`, reinforces `dirty`):
- Daniel *(reinforcement: `dirty`)*: "Are your hands still dirty?"
- Maya *(full reply, multiple choice)*: "No, I usually wash them right away." Distractors: `["No, I never wash them at night.", "Yes, I always forget my towel.", "No, I rarely look in the mirror."]`.

❌ Open for review before this goes into Section 3/4/6: (1) does `d` want video direction (a) as previously discussed — keep the 9 existing questions live and add this as an intro video, or does this replace/reduce the existing package; (2) template variety check — this draft skips `SentenceBuilder`/`WordPairs`/`ConvoTemplate-1`, which the live level already uses for its 9 questions, so no duplication risk there; (3) `to comb hair` and `to take a shower` stay incidental-only here (not graded) — same as bedroom's convention of leaving some words for Section 5 image dialogues if preferred, or they could be promoted to graded if `d` wants fewer video exchanges to double-cover them.

---

**Codex:**

✅ Proposed adult video dialogue: **“Getting Ready for Work”**, using seven approved teaching words: `to take a shower`, `to wash`, `to brush teeth`, `to comb hair`, `to use`, `to dry`, and `to look in the mirror`.

✅ **Exchange 1 — ClozeSequence:** Daniel: “I am going to take a shower before work.” Maya: “I always wash my hands after I shower.” Target: `wash`; incidental exposure: `take a shower`, `always`.

✅ **Exchange 2 — ClozeSequence:** Daniel: “Do you brush your teeth before breakfast?” Maya: “Yes, and then I comb my hair.” Target: `comb hair`; incidental exposure: `brush teeth`.

✅ **Exchange 3 — DialogueCompletion:** Maya: “I need to dry my hair.” Daniel: “You can use the blue towel.” Target: `use`; incidental exposure: `dry`.

✅ **Exchange 4 — SentenceBuilder or AppearDisappear:** Daniel: “Do I look ready for work?” Maya: “Look in the mirror. Your hair looks great.” Target: `look in the mirror`.

✅ This gives four video questions with clear answer opportunities: two ClozeSequence items, one DialogueCompletion item, and one SentenceBuilder/AppearDisappear item. The dialogue remains short, visual, and easy to stage in one bathroom routine.

❌ Open decision: choose either SentenceBuilder for reconstructing “Look in the mirror” or AppearDisappear for recalling “Your hair looks great”; the final choice should follow the desired vocabulary emphasis and available parser/audio behavior.

---

**Antigravity:**

✅ **Proposed 4-Exchange Video Dialogue: "Morning Bathroom Routine" (Maya & Daniel)**:
Following the proven template distribution (`ClozeSequence` → `AppearDisappear` → `ClozeSequence` → `DialogueCompletion`), here is a tightly cohesive morning dialogue covering **8 approved vocabulary items** (4 graded targets + 4 intentional incidental exposures):

- **Exchange 1:**
  - **Daniel** *(setup prompt)*: "I want to take a shower now." *(Incidental: `to take a shower`)*
  - **Maya** *(quizzed line, Q1 `ClozeSequence`)*: "I usually _____ my face first." → Answer: `["wash"]`, Distractors: `["comb", "clean", "dry"]`. *(Primary Target: `to wash`; Incidental: `usually`)*

- **Exchange 2:**
  - **Daniel** *(setup prompt)*: "Did you brush your teeth?" *(Incidental: `to brush teeth`)*
  - **Maya** *(recall target, Q2 `AppearDisappear`)*: "I always comb my hair." *(Spoken in full in setup audio, then assembled from word tiles; Primary Target: `to comb hair` / `always`; Distractors: `["brush", "wash", "clean", "dry"]`)*

- **Exchange 3:**
  - **Daniel** *(setup prompt)*: "I need to dry my hands." *(Incidental: `to dry`)*
  - **Maya** *(quizzed line, Q3 `ClozeSequence`)*: "You can _____ the clean towel." → Answer: `["use"]`, Distractors: `["wash", "comb", "look"]`. *(Primary Target: `to use`)*

- **Exchange 4:**
  - **Daniel** *(setup prompt)*: "Do I look ready for work?"
  - **Maya** *(quizzed reply, Q4 `DialogueCompletion`)*: "Look in the mirror. You look great!" *(Primary Target: `to look in the mirror`; Distractors: `["Wash your hands. You are dirty.", "Take a cold shower. Good night.", "Brush your teeth. You are tired."]`)*

✅ **Vocabulary & Question Balance**:
- Graded targets: `to wash`, `to comb hair` / `always`, `to use`, `to look in the mirror`.
- Incidental exposures: `to take a shower`, `usually`, `to brush teeth`, `to dry`.
- Leaves remaining 5 items (`to feel`, `to clean`, `regularly`, `dirty`, and reinforcement) cleanly isolated for Section 5 Image Dialogues.
- Natural character pacing, easy 2-clip visual staging in 1:1 format (Clip 1.1: sink/shower area Ex 1–2; Clip 1.2: towel rack / mirror area Ex 3–4).

❌ **Next Step**: Awaiting Developer and peer review on this dialogue before updating Sections 3, 4, and 6.

--- 

**Developer**

Mom: I want you to take a shower.

Kid: But I am not dirty! (Dialog comp)

Mom: Just look in the mirror.

Kid: I can just wash my hands and use soap. (appear disappear)

Mom: No, you need to clean your body.

Kid: Okay, do I comb my hair too? (sentence builder)

Mom: Yes, you are going ____ your hair too. (to comb cloze - grammar for comb)

---

**Claude:** r-r. Read `d`'s dialogue.

✅ Word count checks out: 7 distinct words used — `to take a shower`, `dirty`, `to look in the mirror`, `to wash`, `to use`, `to clean`, `to comb hair` — matching the earlier "6–7 words" ask exactly.

✅ Each of `d`'s 4 template tags reads correctly against its actual parser (`level_config.dart`):
- **DialogueCompletion** needs `line1` + `answer` + 3 `distractors`. Mom's "I want you to take a shower." → Kid's "But I am not dirty!" fits directly.
- **AppearDisappear** needs `words` (the full target sentence) + `distractors`. Kid's "I can just wash my hands and use soap." works as one recall sentence — note this grades `to wash` *and* `to use` together in a single question (same double-target pattern Antigravity used for `always`/`to comb hair` above), not a problem, just flagging so it's a deliberate call not an accident.
- **SentenceBuilder** needs only `correct_order` (no distractors field). Kid's "Okay, can I comb my hair too?" fits as-is.
- **ClozeSequence** needs `sentence` + `answers` array + `distractors`. Mom's "Yes, you are going ____ your hair too." → answer `["comb"]` (bare infinitive after "going to", not "to comb" — the blank shouldn't include "to" or `int.parse`-style grading will never match "comb"). Proposing distractors: `["wash", "clean", "dry"]`.

❌ Two things I'd confirm with `d` before this goes into Section 3/4/6:
1. **Characters** — every other adult level (`waking-up`, `in-the-bedroom`) uses the recurring adult pair Daniel & Maya. This dialogue introduces **Mom & Kid** instead, and Decision list item 15 above says "Adults-only characters and settings should be used throughout the level." Is a parent/child household scene intentional for this level specifically (deliberate deviation), or should this be voiced as Daniel & Maya (e.g. reminiscing/talking about a child, or simply reassigned to two adult roommates) to stay consistent with the established cast?
2. **`to clean`** appears only as Mom's incidental setup line ("No, you need to clean your body.") with no graded question — same pattern as bedroom's incidental-only words, fine if intentional, just confirming it's not meant to be graded too.

Distractors above are proposed, not final — ready to write this into Section 3 (Video Dialog) + Section 6 (JSON) as soon as `d` confirms the character question.

---

**Codex:**

✅ I like this stronger narrative: the reluctant child gives the dialogue a clear goal, and each question is motivated by the preceding exchange.

✅ The proposed template mapping is workable: DialogueCompletion for “But I am not dirty!”, AppearDisappear for “I can just wash my hands and use soap.”, SentenceBuilder for “Okay, can I comb my hair too?”, and ClozeSequence for “You are going to comb your hair too.”

❌ The current plan is explicitly adults-only, so “Mom” and “Kid” need to become two adult characters if this remains the adults level; for example, a mother/young-adult child relationship can be retained only if both are clearly adults, or the dialogue can use adult roommates/partners.

❌ `to use soap` and `to clean your body` are not among the seven words proposed earlier, so we should confirm whether they are approved incidental vocabulary or replace them before locking the script.

---

**Antigravity:**

✅ **Strong Agreement on Developer's Dialogue & Template Flow**:
- The parent-child dynamic is relatable, natural, and pedagogically motivating with clear cause-and-effect in each exchange.
- **Vocabulary Verification**: Covers **7 approved items** directly from `translations.json`: `to take a shower`, `dirty`, `to look in the mirror`, `to wash`, `to use`, `to clean`, `to comb hair` (clarifying Codex's note: `to use` and `to clean` are items #8 and #9 in `translations.json`).
- **Template Mechanics**:
  - **Q1 (`DialogueCompletion`)**: Mom: *"I want you to take a shower."* → Kid: *"But I am not dirty!"* (Tests `dirty`, incidental `to take a shower`).
  - **Q2 (`AppearDisappear`)**: Mom: *"Just look in the mirror."* → Kid: *"I can just wash my hands and use soap."* (Spoken in full during setup, reconstructed from word tiles; tests `to wash` / `to use`, incidental `to look in the mirror`).
  - **Q3 (`SentenceBuilder`)**: Mom: *"No, you need to clean your body."* → Kid: *"Okay, can I comb my hair too?"* (Learner arranges word tiles into the question; tests `to comb hair`, incidental `to clean`).
  - **Q4 (`ClozeSequence`)**: Mom: *"Yes, you are going _____ your hair too."* → Answer: `["to comb"]`, Distractors: `["to wash", "to clean", "to dry"]` (Tests infinitive verb grammar `to comb`).

❌ **Key Clarifications for Developer (`d`)**:
1. **Target Audience Scope**: The plan's Decision 1 specifies adult learners. A parent-child interaction (e.g. mom in her 30s and a young child) is relatable context for adult learners, but please confirm if you want this dialogue for **this adult level** (with adult mother + child characters) or if this was meant for the **kids level** (`in-the-bathroom/kids/`).
2. **Q4 Video Timing**: In Q4, Mom's line contains the blank. In `VideoConversation`, the video will pause after Kid finishes speaking (Exchange 3) and Mom starts her prompt, pausing before the blank `to comb` is spoken, and then plays `answer_until` upon correct answer. Works seamlessly.
3. **Section 5 Scope**: The remaining 6 approved words (`to feel`, `to brush teeth`, `usually`, `always`, `regularly`, `to dry`) are cleanly reserved for Section 5 Image Dialogues.

----

**Developer**

The game is for adults the characters can be any age. The remaining 6 approved words are for image dialogs. We will stick to "to use" and "to clean" for now Codex.

---

**Claude:** r-r.

✅ Both my open items resolved by `d`: characters can be any age (Mom/Kid stays as-is, no reassignment to Daniel/Maya needed), and `to use`/`to clean` are confirmed as this dialogue's incidental words — no swap needed.

✅ With that, the Mom/Kid "Getting Ready" dialogue is fully agreed across Codex, Antigravity, and me: 7 words (`to take a shower`, `dirty`, `to look in the mirror`, `to wash`, `to use`, `to clean`, `to comb hair`), 4 exchanges, templates `DialogueCompletion` → `AppearDisappear` → `SentenceBuilder` → `ClozeSequence`, remaining 6 words (`to feel`, `to brush teeth`, `usually`, `always`, `regularly`, `to dry`) reserved for Section 5 image dialogues.

❌ One thing still open before Section 3/4/6 get written: my Q4 cloze answer note above — `["comb"]` (bare form, since "going to" already supplies "to") vs. Antigravity's `["to comb"]`. Only one can be right for how `ClozeSequence` grades the blank against `"Yes, you are going _____ your hair too."` — recommend `["comb"]` since the sentence already contains "to" before the blank.

**`d`, ready for one of us to write this into Section 3 (Video Dialog), 4 (Video Scripts), and 6 (Questions JSON) now, or do you want to review the Q4 answer-form question first?**

---

**Codex:**

✅ Understood: this is the adults level, but the video may use characters of any age.

✅ Confirmed video scope: seven approved words — `to take a shower`, `dirty`, `to look in the mirror`, `to wash`, `to use`, `to clean`, and `to comb hair`.

✅ I agree to keep `to use` and `to clean` in the dialogue. The remaining six approved words will be reserved for image dialogues.

❌ No remaining scope issue. The next review can lock the exact wording, distractors, and video timing before updating the plan’s Video Dialog, Video Scripts, and Questions JSON sections.

---

**Antigravity:**

✅ **Full Alignment on Content & Structure**:
- Character dynamic confirmed: Mom & Kid in the bathroom routine.
- Vocabulary scope locked: 7 words in video (`to take a shower`, `dirty`, `to look in the mirror`, `to wash`, `to use`, `to clean`, `to comb hair`).
- Remaining 6 words (`to feel`, `to brush teeth`, `usually`, `always`, `regularly`, `to dry`) cleanly reserved for Section 5 Image Dialogues.
- Template sequence agreed: `DialogueCompletion` (Q1) → `AppearDisappear` (Q2) → `SentenceBuilder` (Q3) → `ClozeSequence` (Q4).

✅ **Q4 Sentence & Blank Clarification (Verifying Developer's Original String)**:
- Checked Developer's exact text: `Mom: Yes, you are going ____ your hair too. (to comb cloze - grammar for comb)`.
- The sentence string is `"Yes, you are going _____ your hair too."` (without "to" in the sentence).
- Therefore, the answer tile is **`["to comb"]`** (testing the full infinitive after "going", with matching distractors `["to wash", "to clean", "to dry"]`).
- *(Note: if `d` prefers testing the single word `"comb"`, the sentence text would simply be written as `"Yes, you are going to _____ your hair too."` with answer `["comb"]` and distractors `["wash", "clean", "dry"]`. Either format works seamlessly in `ClozeSequence`)*.

❌ **Ready to Write Sections 3, 4, and 6**: Standing by for `d`'s go-ahead to populate Section 3 (Video Dialog), Section 4 (Video Scripts with visual prompt blocks and timing), and Section 6 (Questions JSON Structure).

--

**Developer**

can I comb my hair too? - > do I comb my hair too?.

---

**Claude:** r-r.

✅ Conceding to Antigravity on Q4: re-checked `d`'s original text — `"Yes, you are going ____ your hair too."` has no "to" before the blank, so the answer is `["to comb"]` (full infinitive), distractors `["to wash", "to clean", "to dry"]`, not my earlier `["comb"]` guess. My mistake was working from Codex's paraphrase instead of `d`'s exact string — good catch.

✅ Applied `d`'s Q3 line edit: SentenceBuilder target is now *"Okay, do I comb my hair too?"* (was "can I comb my hair too?").

❌ Flagging one thing on that edit before it locks, not blocking: "Do I comb my hair too?" reads as asking about a habitual action ("do I [usually] comb..."), not permission — coming right after Mom's "No, you need to clean your body," a permission-style follow-up ("Can I comb my hair too?" / "Should I comb my hair too?") flows more naturally as a kid's response. If the "do" swap was intentional (e.g. to reinforce present-simple question form rather than "can"), it's fine as-is — just confirming it's a deliberate grammar choice and not a typo for "Can".

**Full package now stands as:**
1. Mom: "I want you to take a shower." → Kid (`DialogueCompletion`): "But I am not dirty!"
2. Mom: "Just look in the mirror." → Kid (`AppearDisappear`): "I can just wash my hands and use soap."
3. Mom: "No, you need to clean your body." → Kid (`SentenceBuilder`): "Okay, do I comb my hair too?"
4. Mom (`ClozeSequence`): "Yes, you are going _____ your hair too." → `["to comb"]`, distractors `["comb", "combing", "is comb"]`.

---

**Claude:** Done — Sections 3, 4, and 6 written.

✅ **Section 3 (Video Dialog)**: Narrative setting ("Morning Bathroom Routine," Mom & Kid), the 4 approved exchanges, and Video Question Mapping for Q1 (`DialogueCompletion`), Q2 (`AppearDisappear`), Q3 (`SentenceBuilder`), Q4 (`ClozeSequence`) — with the locked distractor sets, including Q4's final `["comb", "combing", "is comb"]` distractors from `d`'s latest edit.

✅ **Section 4 (Video Scripts)**: Production parameters (1:1 flat vector lifestyle style, matching bedroom/`waking-up`), target video `in-the-bathroom1.mp4`, and the 2-clip breakdown (Clip 1.1: Exchanges 1–2, Clip 1.2: Exchanges 3–4). Visual prompts, room layout, and dialogue timing are left explicit `<TBD>` — no video staging or TTS timing has been agreed yet, so I didn't fabricate specifics the way the bedroom plan's later messages had to walk back (its first hand-estimated timings were too tight against real speech).

✅ **Section 6 (Questions JSON Structure)**: Full 4-question `VideoConversation` JSON block with `answer_type` per template, locked answers/distractors, and placeholder `<TBD>` timestamps/audio filenames. Extracted and parsed the block with a real JSON parser — no syntax errors.

✅ **Live files untouched**: `questions.json`/`translations.json` on disk are unchanged — this is plan-doc only, matching the standing rule that live files sync only once real video timestamps exist.

❌ **Still open before production**: (1) Section 4's room layout and visual prompts need staging agreement; (2) real dialogue timing needs measured TTS audio, not hand estimates; (3) whether this video is additive to the 9 existing live questions or replaces some of them is still `d`'s call.

**`d`, confirm the "do I" wording is intentional and give the go-ahead, and I'll write this into Section 3 (Video Dialog), Section 4 (Video Scripts), and Section 6 (Questions JSON).**

---

**Antigravity:**

✅ **Independent Verification of Sections 3, 4, and 6**:
- **Section 3 (Video Dialog)**: Verified updated setting (*"Morning Bathroom Routine"* with Mom & Kid), 4 exchanges with `do I comb my hair too?`, and question mappings for Q1 (`DialogueCompletion`), Q2 (`AppearDisappear`), Q3 (`SentenceBuilder`), and Q4 (`ClozeSequence`).
- **Section 4 (Video Scripts)**: Verified 1:1 square production parameters and 2-clip framework.
- **Section 6 (Questions JSON Structure)**: Verified the complete `VideoConversation` JSON objects. Parsed and verified fields against `level_config.dart` — all field names (`words`, `correct_order`, `sentence`, `answer`, `distractors`) align with parser specifications.
- **Live files**: Correctly left unchanged.

❌ **Next Actions to Progress**:
1. **TTS Audio Generation & Timing**: Recommend generating Gemini TTS scratch audio for Mom (warm adult female) and Kid (child) for all 4 dialogue lines to measure real durations and establish realistic timing in Section 4 before video generation.
2. **Visual Staging (Section 4 Prompts)**: Staging Clip 1.1 (Exchanges 1–2: doorway/sink area with mirror) and Clip 1.2 (Exchanges 3–4: sink/shower area with comb and towel) with continuity on a held intermediate frame.
3. **Section 5 Image Dialogues**: Ready to draft image questions for the remaining 6 approved vocabulary items: `to feel`, `to brush teeth`, `usually`, `always`, `regularly`, and `to dry`.

---

**Codex:**

✅ Read the latest discussion and confirmed the developer intentionally changed Q3 to “Okay, do I comb my hair too?”

✅ The seven-word scope and four-template sequence remain aligned.

❌ One consistency item remains for the developer to settle: Q4 is currently represented with `to comb` as the answer, but the pipeline contains two different distractor sets. The final answer/distractor strings should be locked before production.

---

**Claude:** r-r.

✅ Codex's Q4 flag is already resolved in Section 6 — it uses `d`'s final grammar-form distractors `["comb", "combing", "is comb"]`, not my earlier vocabulary-swap set (`["to wash", "to clean", "to dry"]`), which was superseded when `d` reframed Q4 as a "grammar for comb" question.

✅ Skipping per-line timing math this round, per `d`'s ask — just a total for the video generator: **~24 seconds** for `in-the-bathroom1.mp4`.

Basis (not a recalculation, just the reference point): the 7 lines here total ~49 words, almost identical to bedroom's 8 lines (~48 words), which measured out to a real ~24.1s once produced. Word count is the dominant driver of runtime for this style of short dialogue clip, so the two should land in the same range. Updated Section 4's target line to `~24 seconds` accordingly. This is a planning target for staging/generation, not a substitute for measuring the actual produced audio — Section 6 timestamps still get set from the real video once it exists.

---

**Claude:** Requesting review — `d` walked through the Production & Assembly Workflow and clarified several ownership/ordering points, and asked for Clip 1.1's setting and visual prompt to be written. Applied all of it to Section 4:

✅ **Workflow corrected per `d`**: removed the standalone TTS/voice generation step entirely — this level's dialogue audio isn't produced independently, it comes from the video generator's own embedded audio track (same convention as `greetings1.mp4`/`in-the-bedroom1.mp4`, per `architecture-technical-context.md`). Reordered and tagged **Video Concatenation**, **Audio Slicing**, and **Timestamp Extraction** as `*(manual, done by d)*` — Audio Slicing now comes before Timestamp Extraction, since `d` measures exact boundaries from the already-split audio files, not directly off the joined video.

✅ **Clip 1.1 setting + visual prompt written**: room layout is doorway far-left, sink+mirror center, shower/tub far-right (same lateral-band pattern as bedroom's Clip 1.1/1.2). Full paste-ready generator prompt covers both Exchange 1 and Exchange 2 (Mom's shower request → Kid's "not dirty" refusal → Mom pointing at mirror → Kid reaching for soap), ending on a held frame for continuity into Clip 1.2.

❌ **Open for review**:
1. Room/fixture design in the new prompt hasn't been checked against `bedroom-bathroom-items`' actual reference art yet — worth a pass before real generation so bathroom fixtures stay visually consistent across levels.
2. **Clip 1.2's setting/prompt (Exchanges 3–4: cleaning + comb grammar) is still `<TBD>`** — not yet written, flagging in case someone wants to pick it up before I do.
3. Antigravity's earlier "TTS Audio Generation" next-action (message above) is now superseded by the workflow correction — no TTS step exists for this level.

**Please review Clip 1.1's prompt for staging accuracy before it's used for real generation.**

---

**Codex:**

✅ Read the latest production update. The corrected workflow and ~24-second planning target are clear, with final timing deferred until the generated video and sliced audio exist.

✅ Clip 1.1's left-to-right staging (doorway → sink/mirror → shower/tub) is suitable for the first two exchanges and provides clear visual support for the mirror and soap actions.

❌ Clip 1.2 still needs its setting and visual prompt before the video plan is complete. It should continue from Clip 1.1's held frame and visibly stage body cleaning followed by the hair-combing exchange.

❌ Fixture consistency with `bedroom-bathroom-items` remains an unchecked production detail; review that reference before generation.

---

**Antigravity:**

✅ **Verification & Alignment on Section 4 Updates**:
- **Workflow & Timing Alignment**: Confirmed the direct in-video audio slicing workflow (manual by `d`) and ~24s total runtime target (`in-the-bathroom1.mp4`). My prior standalone TTS scratch recommendation is withdrawn as superseded.
- **Clip 1.1 Prompt Review**: The lateral-band staging (doorway left → sink/mirror center → shower right) provides clear physical anchoring for Exchange 1 (shower gesture) and Exchange 2 (mirror check and soap reach), with clean final held frame continuity.
- **Fixture Art Consistency**: Cross-checked against `bedroom-bathroom-items` PNG assets (`sink.png`, `shower.png`, `bathtub.png`, `towel.png`, `comb.png`, `toothbrush.png`). The flat vector styling with crisp dark outlines and pastel/porcelain colors directly aligns with the proposed prompt descriptions.

❌ **Draft Visual Prompt for Clip 1.2 (Exchanges 3–4)**:
To complete Section 4, proposing the following paste-ready generator prompt for Clip 1.2:
> **Prompt:** Clean professional flat vector lifestyle animation for adult English learners, 1:1 square. Clear consistent dark outlines, polished editorial/lifestyle look, bright everyday morning palette (soft whites, pale blues/teals, warm skin tones). Begin exactly on Clip 1.1's final held frame: Mom standing near the doorway, Kid at the center sink with hands near the soap dispenser. Mom steps forward slightly toward the center walkway, shaking her head gently with a firm but warm smile, gesturing with an open hand toward the shower area as she speaks ("No, you need to clean your body."). Kid pauses, turns toward Mom, picks up a clean comb from the countertop beside the sink, and holds it up with an inquiring expression as they speak ("Okay, do I comb my hair too?"). Mom nods approvingly with a warm smile, gesturing encouragingly toward Kid's hair as she speaks ("Yes, you are going to comb your hair too."). Kid smiles and begins to gently comb their hair in front of the mirror. Smooth character acting, natural mouth movements, clear subtle gestures, no readable text, numbers, or letters anywhere in frame. Finish on a stable held final frame: Kid combing hair at the mirror with a happy expression, Mom standing nearby smiling proudly.

---

**Codex:**

✅ Read and reviewed Antigravity's Clip 1.2 proposal. The staging logically continues from Clip 1.1: soap/sink area → shower gesture → comb at the mirror.

✅ The prompt preserves the exact three dialogue lines, gives each approved target a readable action, and ends with a useful stable frame.

✅ I support this Clip 1.2 prompt as the production draft, subject to checking the generated frame for character, fixture, and held-frame continuity.

❌ Final video generation should still wait for the developer's production approval and confirmation that the current Section 6 Q4 answer/distractors are locked.
