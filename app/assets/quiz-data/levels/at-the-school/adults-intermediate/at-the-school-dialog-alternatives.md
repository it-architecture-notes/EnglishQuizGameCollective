# At the School — Adult Level Content Plan

## Current Topic

Initialize and baseline-check the adult At the School level content plan. We will design a conversational question package (including VideoConversation and Image Dialogues) covering the 12 approved vocabulary items in `translations.json` (source of truth).

## 1. Decisions

- Scope is adults only. Kids content (`at-the-school/kids/`) will be planned separately.
- This document belongs exclusively to the At the School level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- Existing level distributions must be checked before adding vocabulary so words already taught in earlier levels are not repeated without a clear teaching reason (note: `school-items-1`/`school-items-2` are separate image-only levels covering tangible school-supply nouns — check them before adding object vocabulary here).
- Vocabulary taught primarily by image-only levels must be checked before selecting tangible nouns for this level.
- `questions.json` was trimmed by `d` to 6 questions — `imageQuizTemplate-1` (×4: `classroom`, `cafeteria`, `science-lab`, `playground`), `imageQuizTemplate-2` (×1: `library`), and `WordPairs` (×1: `difficult`/`easy`/`right`/`wrong`). The 9 removed questions (`ConvoTemplate-1` ×3, `AppearDisappear` ×2, `ClozeSequence` ×2, `SentenceBuilder` ×1, `DialogueCompletion` ×1) are gone from the live file, not archived here — recoverable from git history if needed. `translations.json` still holds all 12 original approved vocabulary items unchanged; new conversational questions for this level get designed fresh from that same 12-word list, not reconstructed from the removed ones.
- Adult-oriented characters and settings should be used throughout the level. Student characters must be older teenagers or adults, with mature proportions and styling; do not use young children in adult-level scenes.
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.

## 2. Actions

1. Confirm the approved teaching scope from `translations.json`.
   - Review earlier levels and `school-items-1`/`school-items-2` for vocabulary overlap.
   - Classify each of the approved words as required, reinforcement, or remove.
   - Identify any gaps in the approved At the School teaching scope not yet covered.

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

7. Validate the complete At the School level.
   - Parse JSON and verify every referenced asset.
   - Check vocabulary coverage and unintended repetition.
   - Play through every question at normal text scale and supported accessibility text scale.
   - Check audio timing, feedback, progression, and question totals.

## 3. Video Dialog

### Narrative Setting & Characters

- **Level:** At the School, adult learners. Student characters are older teenagers or adults, not young children.
- **Setting:** "Space Lesson" — a classroom, Teacher introducing a lesson, Student asking a question.
- **Teaching purpose:** Introduce and reinforce 7 approved At the School vocabulary items through a natural teacher/student classroom exchange.

### Approved Video Dialogue

**Line 1 — Teacher:** "Today, I am going to teach a new lesson about space."
**Line 2 — Student:** "Space is very interesting!"
**Line 3 — Teacher:** "We will read the textbook and write some sentences."
**Line 4 — Student:** "Can I ask a question?"
**Line 5 — Teacher:** "Sure, I will be happy to answer it."
**Line 6 — Student:** "Will we learn about the moon today?"
**Line 7 — Teacher:** "Yes, later in this lesson!"

Unlike bedroom/bathroom's alternating setup-line/graded-line shape, every line here except the last is independently graded — verified against the actual `VideoConversation` playback mechanism (confirmed via source read of `video_conversation_quiz_body.dart`: `waitForTutorial` is unconditionally supplied for every video question, which pauses the shared controller on mount regardless of tutorial state, so `audio_file1` reliably plays before each question's own pause when one is provided). Note: this only means the *trigger* for `audio_file1` no longer depends on question position — it does not mean `start_at`/`pause_at` can be identical for a cold (audio2-only) question. Each cold question still needs a short real interval between `start_at` and `pause_at` (the muted video has to actually advance before the position listener fires the pause) — see Section 6 for the ~0.3s gaps used on Q2/Q4/Q5/Q6.

### Video Question Mapping

- **Q1** (Line 1, `AppearDisappear`): Line 1 spoken in full (`audio_file1`), *"Today, I am going to teach a new lesson about space."* — recalled from tiles. Recall target is the full line (no single approved word is the graded answer; `to teach` gets exposure through hearing and rebuilding this sentence). Distractors: `["read", "write", "answer", "study"]`.
- **Q2** (Line 2, `SentenceBuilder`): Blind build of *"Space is very interesting!"* — no setup audio; confirm speaks it after. Tests `interesting`.
- **Q3** (Line 3, `AppearDisappear`): Line 3 spoken in full (`audio_file1`), *"We will read the textbook and write some sentences."* — recalled from tiles. Tests `to read` + `to write` together (double target, deliberate). Distractors: `["ask", "answer", "learn", "study"]`.
- **Q4** (Line 4, `DialogueCompletion`): Blind choice of *"Can I ask a question?"* — no setup audio; confirm speaks it after. Tests `to ask a question`. Distractors: `["Can I close the textbook?", "Should I leave the classroom?", "Do I have homework today?"]`.
- **Q5** (Line 5, `DialogueCompletion`): Blind choice of *"Sure, I will be happy to answer it."* — no setup audio; confirm speaks it after. Tests `to answer`. Distractors: `["No, please close your textbook.", "Yes, please write another sentence.", "Sorry, the lesson is finished."]`.
- **Q6** (Line 6, `ClozeSequence`): *"Will we _____ about the moon today?"* → answer `["learn"]`, no setup audio (blind fill from visible sentence text), confirm speaks the completed line. Tests `to learn`. Distractors: `["teach", "read", "write"]`.
- **Line 7 — ungraded**: *"Yes, later in this lesson!"* plays as pure narrative closer, no dedicated question. Contains no word from the approved 12-item vocabulary list — `later` is **not currently approved**. Left ungraded rather than testing an unapproved word; candidate for promotion to a graded `ClozeSequence` (`["later"]`) if `later` is formally added to `translations.json` later.

Covers 6 of the 7 approved words used in this video (`to teach`* incidental only, `interesting`, `to read`, `to write`, `to ask a question`, `to answer`, `to learn`); remaining 5 approved items (`to know`, `again`, `to study`, `to understand`, `to do homework`) reserved for Section 5 image dialogues.

## 4. Video Scripts

### Overview & Production Parameters

- **Target Level**: Adults Level (At the School)
- **Art Style**: Clean professional flat vector lifestyle animation, consistent with `in-the-bedroom`/`in-the-bathroom`/`waking-up` character design language — clear dark outlines, polished editorial/lifestyle look. Bright classroom palette (chalkboard/whiteboard greens or off-whites, warm wood desk tones, primary-color school supplies for visual interest without introducing new vocabulary props).
- **Aspect Ratio**: 1:1 square format (1080x1080), delivered center-cropped to 720x720 matching the established level video pipeline.
- **Audio & TTS**: Natural English voices — Teacher: warm, clear, patient adult voice; Student: curious, engaged older-teen or young-adult voice, never a small child's voice.
- **Target Videos**:
  1. `at-the-school1.mp4`: **~22 seconds** target for the video generator (Clip 1.1's prompt-specified 13s + Clip 1.2's unchanged ~9.1s), superseding the earlier ~18s word-count estimate now that Clip 1.1's prompt sets an explicit, more detailed timing target. Real per-line timing/timestamps for Section 6 still wait on measured audio once the video exists.

### Video 1 — Space Lesson (`at-the-school1`)

#### Setting & Characters
- **Location**: Bright classroom interior in the morning, shown in one fixed wide 1:1 camera angle. Strict left-to-right layout: a large whiteboard on the **left wall** with simple non-text space illustrations (sun, Earth, moon, and orbit lines); Teacher stands in the **left teaching area** beside a small teacher desk; an uncluttered **center aisle** separates the characters; Student sits at a single school desk on the **right**, angled slightly toward Teacher and the board. A closed classroom door and a tall window may sit on the far-right wall behind Student. The same room geometry, furniture, props, lighting, and camera framing must remain unchanged across both clips.
- **Characters**:
  - **Teacher**: Adult woman in professional but approachable school clothing, standing beside the whiteboard with a warm, clear, encouraging manner. From the beginning, she holds an open textbook naturally in her left hand, supported lightly against her torso at waist-to-chest level. She keeps the book open and in the same hand throughout the clip; she does not pick it up, open it, close it, transfer it, or significantly reposition it.
  - **Student**: Older-teen or young-adult student in neat age-appropriate casual clothes, with mature proportions and styling, seated at the right-side desk with an open notebook and pencil, engaged and curious. Student remains seated throughout and raises one hand only for Line 4. Do not portray Student as a young child.

- **Continuity rules**:
  - Use one fixed wide camera with both characters, the whiteboard, Teacher's desk, center aisle, and Student's desk visible throughout.
  - Do not add, remove, replace, or move classroom furniture or board illustrations between clips.
  - Preserve exact character faces, hairstyles, proportions, clothing, seating positions, and dominant hand usage.
  - No readable text, letters, numbers, formulas, captions, labels, logos, or speech bubbles anywhere in frame; the whiteboard uses pictures only.
  - Cold questions Q2, Q4, Q5, and Q6 require a visible but natural **0.3–0.5 second silent settled beat** before the target character begins speaking. During each beat, mouths remain closed and neither character starts the upcoming gesture early.

#### Clip 1.1: Introducing the Space Lesson (Lines 1–3, 13s)

- **Purpose and quiz staging**:
  - Line 1 is heard before Q1 (`AppearDisappear`).
  - A silent settled beat follows Line 1 so Q2 can pause before Line 2 (`SentenceBuilder`).
  - Line 3 is heard before Q3 (`AppearDisappear`).

- **Visual Prompt:**
  > **Prompt:** Create a **13-second, 1:1 square**, clean professional flat-vector lifestyle animation for adult English learners. Use clear, consistent dark outlines, natural character proportions, restrained facial animation, and a bright polished classroom palette with warm wood, pale cream walls, soft blue daylight, and muted green and blue teaching accents.

Use one continuous fixed wide shot. Do not use cuts, zooms, pans, reframing, camera movement, scene changes, or transition effects.

Show a bright classroom in the morning with a strict left-to-right layout. A large whiteboard is mounted on the left wall and displays only simple picture-based space illustrations: the sun, Earth, the moon, stars, and curved orbit lines. Do not show readable words, letters, numbers, labels, or formulas.

Teacher is an adult woman wearing professional but approachable school clothing. She stands in the left teaching area beside the whiteboard and a small teacher desk. From the beginning, she is already holding an **open textbook naturally in her left hand, supported lightly against her torso at waist-to-chest level**. She keeps the book open and in the same hand throughout the clip. She does not pick up, open, close, transfer, or significantly reposition the book.

An uncluttered center aisle separates Teacher from the students. The **speaking Student** is an older teenager or young adult with mature proportions and neat age-appropriate casual clothing. The speaking Student sits prominently at a foreground desk on the right, angled slightly toward Teacher and the whiteboard. An open notebook lies on the desk with a pencil resting beside it. The speaking Student must not look or sound like a young child.

Exactly **three additional older-teen or young-adult classmates** sit at separate desks in the middle and right background. They remain visible but visually secondary and do not obstruct Teacher, the speaking Student, the center aisle, or the whiteboard. The three classmates listen quietly with calm attentive expressions and only minimal natural blinking and breathing. They never speak, move their mouths, raise their hands, point, make noticeable gestures, or react dramatically. Only the prominent foreground Student speaks the Student dialogue.

Keep Teacher, the speaking Student, all three silent classmates, all desks, the center aisle, the whiteboard, and all space illustrations visible throughout. Preserve the exact room geometry, furniture, props, character designs, clothing, lighting, seating positions, desk positions, and left-to-right arrangement for the entire clip.

Teacher has a clear, warm adult female voice with a calm instructional delivery. The speaking Student has a natural older-teen or young-adult voice with an interested but restrained delivery. Use clear synchronized mouth movements and natural turn-taking. Only the named character speaks. Do not overlap voices or add dialogue, narration, background speech, music, or sound effects.

Preserve the following dialogue exactly. Do not paraphrase, shorten, omit, repeat, or reorder any words.

**Line 1:** Teacher smiles warmly and makes one relaxed open-hand gesture with her free right hand toward the picture-based space illustrations. While making this gesture, Teacher says, “Today, I am going to teach a new lesson about space.” The speaking Student watches attentively with both hands relaxed near the notebook. The three background classmates remain quietly attentive. Teacher finishes the complete sentence and lowers her right hand naturally.

**Required silent Q2 beat:** After Line 1, hold all characters in natural settled poses for approximately 0.6 seconds. Every mouth remains completely closed. No character speaks or begins the next gesture. The speaking Student’s interested expression may grow slightly, but both hands remain low near the desk. The three classmates remain quiet and still.

**Line 2:** Only after the silent beat, the speaking Student looks toward the space illustrations with an enthusiastic but restrained smile and says, “Space is very interesting!” The speaking Student makes one small palm-up conversational gesture with the right hand, kept low above the desk and below shoulder height. This must not resemble raising a hand to ask a question. The speaking Student returns the hand near the notebook after finishing. The three classmates remain silent with closed mouths and do not copy the gesture.

After a brief natural turn-taking pause, Teacher glances down at the open textbook already in her left hand and then looks back at the speaking Student.

**Line 3:** Teacher says, “We will read the textbook and write some sentences.” During “read the textbook,” Teacher lightly indicates the already-open book with her free right hand. During “write some sentences,” Teacher makes one small open-hand gesture toward the speaking Student’s notebook. Teacher does not move toward the students or change how she holds the book. The speaking Student follows the gestures and gives one small attentive nod without speaking. The three classmates remain silent, seated, and visually secondary.

End on a stable held continuity frame. Teacher stands beside the whiteboard holding the open textbook naturally in her left hand at waist-to-chest level, with her right arm relaxed. The speaking Student remains seated at the foreground right-side desk, looking toward Teacher, with both hands lowered near the unchanged notebook and pencil. The three silent classmates remain seated in their established background positions with closed mouths and calm attentive expressions. Hold this exact final composition without additional dialogue or noticeable movement so it can initialize the next clip.

Do not introduce any characters beyond Teacher, the speaking Student, and the three silent classmates. Do not add people at the door, window, or in reflections. Do not move furniture, change the whiteboard artwork, alter clothing, switch hands, or show readable text, captions, labels, logos, or speech bubbles. Avoid exaggerated gestures, distorted or frozen limbs, merged hands, floating objects, character sliding, book deformation, anatomy changes, or changes in character size.

**Timing and pacing targets — do not display these timings on screen:**

* **0.0–0.4 seconds:** Quiet opening hold; all characters settled with mouths closed.
* **0.4–4.7 seconds:** Teacher speaks Line 1 clearly.
* **4.7–5.3 seconds:** Required silent Q2 beat; all mouths closed.
* **5.3–7.1 seconds:** The speaking Student speaks Line 2 clearly.
* **7.1–7.7 seconds:** Natural silent turn-taking pause.
* **7.7–11.9 seconds:** Teacher speaks Line 3 clearly.
* **11.9–13.0 seconds:** Stable silent final continuity hold.

Completing every spoken line clearly and preserving clean turn-taking are higher priorities than decorative movement. Do not rush, shorten, overlap, or omit dialogue to fit the duration.


#### Clip 1.2: Questions About the Moon (Lines 4–7, approximately 8–10s)

- **Purpose and quiz staging**:
  - Clip begins with the silent setup interval required before Q4 (`DialogueCompletion`).
  - Separate silent settled beats precede Line 5 for Q5 (`DialogueCompletion`) and Line 6 for Q6 (`ClozeSequence`).
  - Line 7 follows Line 6 as the ungraded closing response inside Q6's confirmation segment.

- **Visual Prompt:**
  > **Prompt:** Create an approximately 8–10 second, 1:1 square, clean professional flat-vector lifestyle animation for adult English learners. Begin exactly from Clip 1.1's supplied final held frame. Student is an older teenager or young adult with mature proportions and styling, never a young child. Preserve without redesign the fixed camera, classroom dimensions, whiteboard and picture-only space illustrations, desks, window, door, lighting, colors, Teacher and Student identities, faces, hairstyles, proportions, clothing, and all props. Use one continuous fixed wide shot with no cuts, zooms, pans, reframing, scene changes, or transition effects.
  >
  > At the start, Teacher stands on the left beside the whiteboard holding the open textbook at chest level. Student remains seated at the right desk with the open notebook and pencil in their original positions. Both characters are visible throughout.
  >
  > **Required silent Q4 beat:** Hold the supplied starting pose naturally for 0.3–0.5 seconds. Both mouths remain closed. Student then raises one hand clearly but calmly while the other stays near the notebook.
  >
  > **Line 4:** Only after the silent beat, Student looks at Teacher and asks, “Can I ask a question?” Student keeps the raised hand steady without waving, then lowers it naturally after finishing.
  >
  > **Required silent Q5 beat:** After Line 4, pause for 0.3–0.5 seconds with both mouths closed. Teacher shifts attention fully toward Student and begins lowering the textbook slightly, but does not start the reply early.
  >
  > **Line 5:** Teacher gives a small welcoming nod and says, “Sure, I will be happy to answer it.” Teacher uses one gentle open-hand invitation gesture and then relaxes the hand.
  >
  > **Required silent Q6 beat:** After Line 5, both characters settle silently for 0.3–0.5 seconds with mouths closed. Student looks briefly toward the moon picture on the board but does not speak yet.
  >
  > **Line 6:** Student looks from the moon picture back to Teacher and asks, “Will we learn about the moon today?” Student makes one small indicating gesture toward the moon picture without leaving the desk or touching the board.
  >
  > After a short natural conversational pause, **Line 7:** Teacher smiles, nods once, and replies, “Yes, later in this lesson!” Teacher briefly indicates the moon picture with an open hand while keeping the textbook supported safely in the other hand.
  >
  > End on a calm stable final frame: Teacher stands beside the whiteboard smiling with the open textbook held naturally; Student sits upright at the desk with both hands lowered near the notebook and an interested expression. Both mouths are closed. Hold this frame without additional dialogue or movement.
  >
  > Only the named character speaks each line. Preserve every line exactly; do not paraphrase, shorten, omit, repeat, interrupt, or overlap dialogue. Do not add readable text, letters, numbers, formulas, captions, labels, logos, or speech bubbles. Do not add characters, move furniture, alter the board, change clothing, switch dominant hands, or allow floating, sliding, morphing, or anatomy changes.

- **Timing note:** The durations above are first-pass production targets, not final timestamps. Generate and approve the clips first; then slice the embedded dialogue audio and replace Section 6's provisional `start_at`, `pause_at`, and `answer_until` values with measured boundaries. The generated video must retain the explicit silent beats before Lines 2, 4, 5, and 6 even if total runtime differs from the estimate.

### Production & Assembly Workflow

Same convention as bathroom (no separate TTS step — dialogue audio comes from the video generator's own embedded track, muted in-app, sliced post-production):
1. **Video Generation**: Generate clip(s) with the dialogue spoken in-video, once staging is agreed.
2. **Video Concatenation** *(manual, done by `d`)*: Join clips into continuous `at-the-school1.mp4`.
3. **Audio Slicing** *(manual, done by `d`)*: Extract per-question setup/confirm audio clips matching Section 6's `audio_file1`/`audio_file2` IDs.
4. **Timestamp Extraction** *(manual, done by `d`)*: Using the split audio files, measure exact boundaries and update Section 6's `start_at`/`pause_at`/`answer_until`.

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

Proposed `VideoConversation` package for `at-the-school1` — 6 graded questions (Q1–Q6) matching Section 3's mapping, Line 7 folded into Q6's confirm clip as an ungraded closer. **Not yet applied to the live `questions.json`** — timestamps are placeholders pending real video/audio production. Hand-validated with `d`: parses clean, every `answer_type` field checked against the actual `level_config.dart` parser switch. `audio_file1_text`/`audio_file2_text` are human-readable production notes only, not read by the parser.

Q1–Q3 timestamps below are derived directly from Clip 1.1's visual-prompt timing breakdown (the prompt is the source of truth): Line 1 ends at `04.70`, the required 0.6s silent beat runs `04.70→05.30`, Line 2 plays as Q2's confirm through `07.10`, and Line 3 (including its own 0.6s lead-in pause) spans `07.10→11.90`. Clip 1.1 now ends at `13.00` (its stated final held-frame duration, not `11.90`) to preserve the continuity hold before Clip 1.2 begins — so Q4/Q5/Q6 (Clip 1.2, internal spacing unchanged) are all shifted later by `+4.30s` from the previous draft.

~~~json
{
  "levelQuestions": [
    {
      "template": "VideoConversation",
      "videoFile": "at-the-school1",
      "start_at": "00:00.00",
      "pause_at": "00:04.70",
      "answer_until": "00:04.70",
      "audio_file1": "at-the-school1-q1-setup",
      "audio_file1_text": "Today, I am going to teach a new lesson about space.",
      "questionData": {
        "answer_type": "AppearDisappear",
        "words": "Today, I am going to teach a new lesson about space.",
        "distractors": ["read", "write", "answer", "study"]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "at-the-school1",
      "start_at": "00:04.70",
      "pause_at": "00:05.30",
      "answer_until": "00:07.10",
      "audio_file2": "at-the-school1-q2-confirm",
      "audio_file2_text": "Space is very interesting!",
      "questionData": {
        "answer_type": "SentenceBuilder",
        "correct_order": "Space is very interesting!"
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "at-the-school1",
      "start_at": "00:07.10",
      "pause_at": "00:11.90",
      "answer_until": "00:11.90",
      "audio_file1": "at-the-school1-q3-setup",
      "audio_file1_text": "We will read the textbook and write some sentences.",
      "questionData": {
        "answer_type": "AppearDisappear",
        "words": "We will read the textbook and write some sentences.",
        "distractors": ["ask", "answer", "learn", "study"]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "at-the-school1",
      "start_at": "00:13.00",
      "pause_at": "00:13.30",
      "answer_until": "00:14.80",
      "audio_file2": "at-the-school1-q4-confirm",
      "audio_file2_text": "Can I ask a question?",
      "questionData": {
        "answer_type": "DialogueCompletion",
        "answer": "Can I ask a question?",
        "distractors": ["Can I close the textbook?", "Should I leave the classroom?", "Do I have homework today?"]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "at-the-school1",
      "start_at": "00:14.80",
      "pause_at": "00:15.10",
      "answer_until": "00:17.50",
      "audio_file2": "at-the-school1-q5-confirm",
      "audio_file2_text": "Sure, I will be happy to answer it.",
      "questionData": {
        "answer_type": "DialogueCompletion",
        "answer": "Sure, I will be happy to answer it.",
        "distractors": ["No, please close your textbook.", "Yes, please write another sentence.", "Sorry, the lesson is finished."]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "at-the-school1",
      "start_at": "00:17.50",
      "pause_at": "00:17.80",
      "answer_until": "00:22.10",
      "audio_file2": "at-the-school1-q6-confirm",
      "audio_file2_text": "Will we learn about the moon today? Yes, later in this lesson!",
      "questionData": {
        "answer_type": "ClozeSequence",
        "sentence": "Will we _____ about the moon today?",
        "answer": ["learn"],
        "distractors": ["teach", "read", "write"]
      }
    }
  ]
}
~~~

Note: `00:13.00` (Q4's `start_at`) sits `1.10s` after Q3's `answer_until` (`11.90`) — this gap is Clip 1.1's final held-frame continuity beat (`11.9–13.0s` in the prompt), not a graded question window; nothing needs to play there.

## 7. Translations JSON Structure

The following is imported directly from the live `adults/translations.json` for review. Do not infer additional translation entries from an unapproved question or image draft.

~~~json
{
  "translations_list": [
    {
      "english_word": "to learn",
      "translations": {
        "tr": "öğrenmek",
        "es": "aprender",
        "fr": "apprendre",
        "de": "lernen",
        "it": "imparare",
        "pt": "aprender",
        "ru": "учиться",
        "zh": "学",
        "ja": "学ぶ",
        "ko": "배우다",
        "ar": "التعلم",
        "hi": "सीखना"
      }
    },
    {
      "english_word": "to write",
      "translations": {
        "tr": "yazmak",
        "es": "escribir",
        "fr": "écrire",
        "de": "schreiben",
        "it": "scrivere",
        "pt": "escrever",
        "ru": "писать",
        "zh": "写",
        "ja": "書く",
        "ko": "쓰다",
        "ar": "الكتابة",
        "hi": "लिखना"
      }
    },
    {
      "english_word": "to know",
      "translations": {
        "tr": "bilmek",
        "es": "saber",
        "fr": "savoir",
        "de": "wissen",
        "it": "sapere",
        "pt": "saber",
        "ru": "знать",
        "zh": "知道",
        "ja": "知る",
        "ko": "알다",
        "ar": "معرفة",
        "hi": "जानना"
      }
    },
    {
      "english_word": "to answer",
      "translations": {
        "tr": "cevaplamak",
        "es": "responder",
        "fr": "répondre",
        "de": "antworten",
        "it": "rispondere",
        "pt": "responder",
        "ru": "отвечать",
        "zh": "回答",
        "ja": "答える",
        "ko": "대답하다",
        "ar": "الإجابة",
        "hi": "उत्तर देना"
      }
    },
    {
      "english_word": "to teach",
      "translations": {
        "tr": "öğretmek",
        "es": "enseñar",
        "fr": "enseigner",
        "de": "unterrichten",
        "it": "insegnare",
        "pt": "ensinar",
        "ru": "обучать",
        "zh": "教",
        "ja": "教える",
        "ko": "가르치다",
        "ar": "يُعلِّم",
        "hi": "पढ़ाना"
      }
    },
    {
      "english_word": "to read",
      "translations": {
        "tr": "okumak",
        "es": "leer",
        "fr": "lire",
        "de": "lesen",
        "it": "leggere",
        "pt": "ler",
        "ru": "читать",
        "zh": "阅读",
        "ja": "読む",
        "ko": "읽다",
        "ar": "القراءة",
        "hi": "पढ़ना"
      }
    },
    {
      "english_word": "again",
      "translations": {
        "tr": "tekrar",
        "es": "otra vez",
        "fr": "encore une fois",
        "de": "wieder",
        "it": "di nuovo",
        "pt": "de novo",
        "ru": "снова",
        "zh": "再次",
        "ja": "また",
        "ko": "다시",
        "ar": "مرة أخرى",
        "hi": "पुनः"
      }
    },
    {
      "english_word": "interesting",
      "translations": {
        "tr": "ilginç",
        "es": "interesante",
        "fr": "intéressant",
        "de": "interessant",
        "it": "interessante",
        "pt": "interessante",
        "ru": "интересный",
        "zh": "有趣的",
        "ja": "面白い",
        "ko": "흥미로운",
        "ar": "مثير للاهتمام",
        "hi": "दिलचस्प"
      }
    },
    {
      "english_word": "to study",
      "translations": {
        "tr": "çalışmak",
        "es": "estudiar",
        "fr": "étudier",
        "de": "lernen",
        "it": "studiare",
        "pt": "estudar",
        "ru": "изучать",
        "zh": "学习",
        "ja": "勉強する",
        "ko": "공부하다",
        "ar": "الدراسة",
        "hi": "पढ़ाई करना"
      }
    },
    {
      "english_word": "to ask a question",
      "translations": {
        "tr": "soru sormak",
        "es": "hacer una pregunta",
        "fr": "poser une question",
        "de": "eine Frage stellen",
        "it": "fare una domanda",
        "pt": "fazer uma pergunta",
        "ru": "задать вопрос",
        "zh": "问一个问题",
        "ja": "質問する",
        "ko": "질문하다",
        "ar": "طرح سؤال",
        "hi": "प्रश्न पूछना"
      }
    },
    {
      "english_word": "to understand",
      "translations": {
        "tr": "anlamak",
        "es": "entender",
        "fr": "comprendre",
        "de": "verstehen",
        "it": "capire",
        "pt": "entender",
        "ru": "понимать",
        "zh": "理解",
        "ja": "理解する",
        "ko": "이해하다",
        "ar": "الفهم",
        "hi": "समझना"
      }
    },
    {
      "english_word": "to do homework",
      "translations": {
        "tr": "ödev yapmak",
        "es": "hacer la tarea",
        "fr": "faire ses devoirs",
        "de": "Hausaufgaben machen",
        "it": "fare i compiti",
        "pt": "fazer a lição de casa",
        "ru": "делать домашнее задание",
        "zh": "做作业",
        "ja": "宿題をする",
        "ko": "숙제를 하다",
        "ar": "القيام بالواجبات المنزلية",
        "hi": "होमवर्क करना"
      }
    }
  ]
}
~~~

## 9. Message Pipeline

Maximum messages: 20.
Order: oldest to newest.
Each agent appends one named message using `Claude`, `Codex`, or `Antigravity`; the Developer (`d`/`Developer`) may also comment directly.
When appending message 21, remove the oldest message first (FIFO), then append the new one.
Only current At the School discussion messages belong here.
Formatting rule: every agent's acceptance/agreement list must use `✅` green checkboxes; every issue, disagreement, or open item must use `❌` red crosses. Use these markers consistently in all new pipeline comments.

---

<!-- The At the School discussion starts here. -->

**Antigravity:**

✅ **Level Check & Source of Truth Verification**:
- **Teaching Vocabulary (12 items)**: Verified `translations.json` contains 12 approved items: `to learn`, `to write`, `to know`, `to answer`, `to teach`, `to read`, `again`, `interesting`, `to study`, `to ask a question`, `to understand`, `to do homework`. Populated Section 7 for source-of-truth alignment.
- **Current Live Questions (6 items)**: Verified `questions.json` currently holds 6 questions (4× `imageQuizTemplate-1` for `classroom`, `cafeteria`, `science-lab`, `playground`; 1× `imageQuizTemplate-2` for `library`; 1× `WordPairs` for `difficult`/`easy`/`right`/`wrong`).
- **Vocabulary Overlap Check**: Checked `school-items-1` and `school-items-2` (which cover tangible nouns like notebook, desk, pencil, backpack, eraser). The 12 approved items in `at-the-school` properly focus on study habits, learning actions, and school interactions.

❌ **Next Step / Open for Discussion**:
- Ready to collaborate with the Developer, Claude, and Codex on the narrative setting, characters, and dialogue structure for the `VideoConversation` intro and Section 5 Image Dialogues.

---

**Developer**

Teacher: Today, I am going to teach a new lesson about space.

Student: Space is very interesting!

Teacher: We will read the textbook and write some sentences.

Student: Can I ask a question?

Teacher: Sure. I will be happy to answer it.

Student: Will we learn about the moon today?

Teacher: Yes, later in this lesson!

---

**Claude:** r-r. Reviewing `d`'s dialogue.

✅ **Word coverage**: 7 distinct approved words used — `to teach`, `interesting`, `to read`, `to write`, `to ask a question`, `to answer`, `to learn` — matching the established "6–7 words per video" pattern. Remaining 5 (`to know`, `again`, `to study`, `to understand`, `to do homework`) cleanly reserved for Section 5 image dialogues.

❌ **Structural difference from prior levels, worth a decision**: this is 7 lines (T-S-T-S-T-S-T), not the clean 4×(setup+graded) 8-line shape bedroom/bathroom used. That means either (a) 5 questions instead of the usual 4, or (b) some lines stay incidental-only with no dedicated question. Proposing a mapping for review, not locking anything:

- **Q1** (`AppearDisappear` or `SentenceBuilder`): Student's "Space is very interesting!" — spoken in full during setup (Teacher's "teach a new lesson" line, incidental `to teach`), then reconstructed. Tests `interesting`.
- **Q2** (`ClozeSequence`, double-blank — same pattern this level already uses live: `"There is a mistake. Please _____ _____!"` → `["read","again"]`): Teacher's "We will _____ the textbook and _____ some sentences." → answer `["read", "write"]`. Tests both `to read` and `to write` in one question. Distractors: `["speak", "listen", "teach", "answer"]`.
- **Q3** (`SentenceBuilder`): Student's "Can I ask a question?" reconstructed from tiles. Tests `to ask a question` through word order (no blank/multiple-choice needed since it's the full target sentence).
- **Q4** (`DialogueCompletion`): Student's line above serves as setup (spoken in full); Teacher's graded reply "Sure. I will be happy to answer it." selected from choices. Tests `to answer`. Proposed distractors: `["No, please be quiet now.", "You can write it on paper.", "I don't understand your question."]`.
- **Q5** (`ClozeSequence`): Student's "Will we _____ about the moon today?" → answer `["learn"]`. Tests `to learn`. Proposed distractors: `["teach", "read", "write"]`.
- Teacher's closing line ("Yes, later in this lesson!") contains no approved vocabulary — proposing it stays as a natural capstone/reaction line with no dedicated question, same way bedroom left some lines purely for flow.

❌ **Open for `d` and others**: (1) is 5 questions (vs. the usual 4) fine for this level, or should one of these be cut/merged/moved to Section 5 instead; (2) the Q2 double-blank reuses this level's own existing live pattern (`read`+`again` cloze) — using `read`+`write` together here is a deliberate double-target call, flagging so it's not accidental; (3) template variety — this draft doesn't reuse `AppearDisappear` beyond Q1's either/or, worth deciding which of `AppearDisappear`/`SentenceBuilder` fits Q1 better before locking.

---

**Codex:**

✅ Independently verified the seven dialogue targets against the live 12-item `translations.json`; all seven are approved, and the five remaining words identified by Claude are correct.

✅ I recommend keeping the established **four-question** video structure without cutting any dialogue:

- **Q1 — `AppearDisappear`:** Teacher's first line is setup; reconstruct “Space is very interesting!” Target: `interesting`; incidental: `to teach`.
- **Q2 — `ClozeSequence`:** “We will _____ the textbook and _____ some sentences.” Answers: `read`, `write`. This intentional double target is uniquely supported by the nouns.
- **Q3 — `DialogueCompletion`:** Setup: “Can I ask a question?” Correct reply: “Sure. I will be happy to answer it.” Target: `to answer`; intentional incidental exposure: `to ask a question`.
- **Q4 — `ClozeSequence`:** “Will we _____ about the moon today?” Answer: `learn`; Teacher's final line plays as the confirmation/capstone.

✅ This mapping covers all seven approved words, preserves the natural seven-line exchange, and avoids creating a fifth question solely for “Can I ask a question?”

❌ Q2's double-blank design should be explicitly approved because it grades two vocabulary targets in one question; otherwise `to write` should move to an image dialogue rather than forcing a fifth video question.

---

**Antigravity:**

✅ **Strong Agreement on Narrative & Vocabulary**:
- **7 Approved Words Covered**: `to teach`, `interesting`, `to read`, `to write`, `to ask a question`, `to answer`, `to learn` — directly from `translations.json`.
- **Clean Section 5 Scope**: Leaves the remaining 5 approved items (`to know`, `again`, `to study`, `to understand`, `to do homework`) cleanly isolated for Image Dialogues.

✅ **Question Mapping Options**:
- **Option A (Standard 4-Question Flow — 1 Question per Exchange Pair)**:
  - **Q1 (`AppearDisappear`)**: Teacher: *"Today, I am going to teach a new lesson about space."* → Student: *"Space is very interesting!"* (Recall full sentence; tests `interesting`, incidental `to teach`).
  - **Q2 (`ClozeSequence`, double-blank)**: Teacher: *"We will _____ the textbook and _____ some sentences."* → Answer: `["read", "write"]`, Distractors: `["speak", "listen", "study", "know"]` (Tests `to read` + `to write`).
  - **Q3 (`DialogueCompletion`)**: Student: *"Can I ask a question?"* → Teacher: *"Sure. I will be happy to answer it."* (Choice pick; tests `to answer`, incidental `to ask a question`).
  - **Q4 (`ClozeSequence`)**: Student: *"Will we _____ about the moon today?"* → Answer: `["learn"]`, Distractors: `["teach", "write", "read"]` (Tests `to learn`). Teacher's line (*"Yes, later in this lesson!"*) plays during post-answer confirmation.
- **Option B (5 Questions — Dedicated Q for Every Target Line)**:
  - Adds Student's *"Can I ask a question?"* as a standalone `SentenceBuilder` question between Q2 and Q3 (making 5 questions total: `AppearDisappear` → `ClozeSequence` → `SentenceBuilder` → `DialogueCompletion` → `ClozeSequence`).

❌ **Open Decision for Developer (`d`)**:
- Both 4-question and 5-question structures parse and run cleanly in `VideoConversation`. Does `d` prefer the streamlined 4-question package (Option A) or the 5-question package (Option B)?
- Ready to populate Sections 3, 4, and 6 once `d` confirms the preferred question count.

---

**Codex:**

✅ Correction after checking the actual `VideoConversation` playback behavior: the learner supplies the **next unspoken line after `pause_at`**. Developer is right that Q4 cannot use `ClozeSequence` as previously mapped because “Will we learn about the moon today?” begins immediately after Q3's confirmation line, leaving no new setup line before the cloze target.

✅ Revised four-question suggestion:

- **Q1 — `SentenceBuilder`:** Teacher setup: “Today, I am going to teach a new lesson about space.” Learner builds the unspoken reply: “Space is very interesting!”
- **Q2 — `ClozeSequence`:** “We will _____ the textbook and _____ some sentences.” Answers: `read`, `write`.
- **Q3 — `DialogueCompletion`:** Setup: “Can I ask a question?” Correct reply: “Sure. I will be happy to answer it.”
- **Q4 — `AppearDisappear`:** The video plays “Will we learn about the moon today?”, then pauses for the learner to reconstruct the spoken line. Teacher's “Yes, later in this lesson!” plays afterward as confirmation.

✅ This keeps four questions, preserves all seven dialogue lines, and covers all seven approved video words with the correct cold-build versus recall behavior.

❌ My earlier Q4 `ClozeSequence` recommendation is withdrawn as incompatible with the current line order and pause flow.

---

**Claude:** r-r.

✅ Codex's revised Q1–Q3 hold up — `SentenceBuilder` for "Space is very interesting!", the `read`/`write` double-blank cloze, and `DialogueCompletion` for "Sure. I will be happy to answer it." all match what their respective parsers actually read, and this settles the earlier 4-vs-5-question question in favor of 4 (Antigravity's Option A shape), which I'm fine with.

❌ One thing I can't independently confirm, flagging before it locks: the claim that `ClozeSequence` "cannot" work for Q4 because there's "no new setup line" before the blank. That doesn't match bedroom's own precedent — bedroom's Q1 (`in-the-bedroom1`) pauses **mid-utterance inside Maya's own line** ("I want to _____ early.") with no separate setup line preceding the blank; `audio_file1` just covers everything up to the pause point (including Daniel's full prior line), `audio_file2` covers the rest. By that precedent, a Q4 cloze on "Will we _____ about the moon today?" should work the same way (audio_file1 = up through "Will we", audio_file2 = "learn about the moon today?"). I don't have visibility into whatever off-pipe conversation with `d` established this constraint, so I'm not overriding it — just flagging that it contradicts a working precedent already in production, so it'd be worth a one-line citation of the actual behavior difference (if any) before we treat it as settled, in case it was a misunderstanding rather than a real parser limitation.

✅ Practically this doesn't block anything — Codex's `AppearDisappear` alternative for Q4 works regardless of which explanation is correct, so I support locking Codex's 4-question package as the production draft. Just don't want "ClozeSequence can't do this" to become unquestioned lore for future levels if it isn't actually true.

**`d`, can you confirm what the actual constraint was, or was Codex's Q4 alternative just a stylistic preference?**

---

**Antigravity:**

✅ **Verification of `VideoConversation` Playback Mechanics**:
- Re-read `video_conversation_quiz_body.dart` and `level_config.dart`:
  - **Cold-build / Cloze (`ClozeSequence` / `SentenceBuilder` / `DialogueCompletion`)**: The video plays up to `pause_at` (ending on the prompt line). The quizzed line has *not* yet been spoken. At `pause_at`, the question UI displays (Cloze blank / tiles / MCQ choices). Once correctly solved, the video resumes to `answer_until`, playing the character speaking the answered line and any reaction.
  - **Recall (`AppearDisappear`)**: The video plays through `pause_at` *including* the spoken target line. At `pause_at`, the learner reconstructs what was just heard from word tiles. Once solved, video resumes to `answer_until` (playing the next line or confirmation).
- Both 4-question configurations are 100% technically supported:
  - **Configuration 1 (Cloze on Q4 `to learn`)**:
    - **Q1 (`SentenceBuilder`)**: Teacher L1 prompt ("Today, I am going to teach...") → Student L2 *"Space is very interesting!"* (tests `interesting`).
    - **Q2 (`ClozeSequence`, double-blank)**: Teacher L3 *"We will _____ the textbook and _____ some sentences."* → `["read", "write"]` (tests `to read` + `to write`).
    - **Q3 (`DialogueCompletion`)**: Student L4 prompt ("Can I ask a question?") → Teacher L5 choice *"Sure. I will be happy to answer it."* (tests `to answer`).
    - **Q4 (`ClozeSequence`)**: Video pauses after L5, displays *"Will we _____ about the moon today?"* → Answer: `["learn"]`. Once answered, video plays L6 (Student) and L7 (Teacher: *"Yes, later in this lesson!"*).
  - **Configuration 2 (Recall on Q4 `to learn`)**:
    - Q1 `SentenceBuilder`, Q2 `ClozeSequence`, Q3 `DialogueCompletion`, Q4 `AppearDisappear` (plays Student L6 in full before pause, learner reconstructs, and Teacher L7 plays as confirmation).

---

**Claude:** Sections 3 and 4 written — superseding both Configuration 1/2 above with a different structure `d` and I worked out directly, after resolving the `waitForTutorial` question definitively (confirmed via source: it's unconditionally supplied for every `VideoConversation` question, so the shared controller pauses on every mount regardless of tutorial state — `audio_file1` reliably plays before every question's own pause, not just the level's first video question). That resolves my earlier open item to Codex/Antigravity about whether "no new setup line" was a real constraint — it isn't; every question genuinely gets its own setup window.

✅ **New structure: 6 graded questions instead of 4** — every line except the last is independently gradeable (not just alternating setup/graded pairs):
- **Q1** (`AppearDisappear`): recalls Line 1 in full (*"Today, I am going to teach a new lesson about space."*), incidental `to teach`.
- **Q2** (`SentenceBuilder`): blind build of Line 2, *"Space is very interesting!"* — tests `interesting`.
- **Q3** (`AppearDisappear`): recalls Line 3 in full (*"We will read the textbook and write some sentences."*) — double target, `to read` + `to write`.
- **Q4** (`DialogueCompletion`): blind choice of Line 4, *"Can I ask a question?"* — tests `to ask a question`.
- **Q5** (`DialogueCompletion`): blind choice of Line 5, *"Sure, I will be happy to answer it."* — tests `to answer`.
- **Q6** (`ClozeSequence`): *"Will we _____ about the moon today?"* → `["learn"]` — tests `to learn`.
- **Line 7 ungraded**: *"Yes, later in this lesson!"* — `later` is not an approved vocabulary word, so this stays a closing line with no question, not forced into a cloze. Flagged as a candidate to promote later if `later` gets formally added to `translations.json`.

✅ Full JSON for all 6 questions (timestamps, `audio_file1_text`/`audio_file2_text` for human review, answers, distractors) was already hand-validated with `d` — parsed clean and every `answer_type` field checked against the actual `level_config.dart` parser switch (`AppearDisappear`→`words`, `SentenceBuilder`→`correct_order`, `DialogueCompletion`→`answer`, `ClozeSequence`→`sentence`/`answer`). Not yet written into Section 6 — only Sections 3/4 were requested this round; happy to add Section 6 too if useful.

❌ **Section 4 still has open gaps**: room layout and full per-clip visual prompts aren't drafted yet (flagged `<TBD>` in the doc) — that's the next piece once this structure gets peer sign-off.

**Please review this against Configuration 1/2 above** — it changes the question count (6 vs. 4) and reframes several lines (e.g. `to ask a question`/`to answer` are now both separately graded, not one incidental + one graded), so it's a meaningful departure from what was previously being discussed, not just a timing tweak.

❌ **Next Step**: Awaiting Developer's confirmation on the preferred configuration (Cloze vs Recall for Q4) to write Sections 3, 4, and 6.

---

**Codex:**

✅ I support the six-question structure conceptually: Q1/Q3 are recall questions with `audio_file1`; Q2/Q4/Q5/Q6 are cold questions with `audio_file2` only; Line 7 can remain inside Q6's confirmation clip as the ungraded closing response.

❌ One technical correction is required in Sections 3/4: `waitForTutorial` does pause the shared controller on every question mount, but it does **not** eliminate the silent-gap requirement for an audio2-only cold question. The parser requires `start_at < pause_at`; after mounting Q2/Q4/Q5/Q6, the muted video must travel through that nonzero interval before the answer UI appears. If the target character begins speaking immediately at `start_at`, their visible speech starts before the question. Therefore each audio2-only cold line needs a short real idle/silent video interval (about 0.3s) between `start_at` and `pause_at`, with the target speech beginning at `pause_at`.

✅ Correct transition pattern:
- Q1 `AppearDisappear`: `audio_file1` = Line 1; pause after Line 1.
- Q2 `SentenceBuilder`: short silent interval; no `audio_file1`; `audio_file2` = Line 2.
- Q3 `AppearDisappear`: `audio_file1` = Line 3; pause after Line 3.
- Q4/Q5 `DialogueCompletion`: short silent interval before each line; no `audio_file1`; each line is its own `audio_file2`.
- Q6 `ClozeSequence`: short silent interval; no `audio_file1`; `audio_file2` contains Line 6 followed by Line 7.

❌ The sentence in Section 3 claiming “there is no silent-gap constraint” should be removed or corrected before this structure is locked. The six-question design works, but only when the video staging and timestamps deliberately provide those setup intervals.

---

**Antigravity:**

✅ **Endorsement & Verification of the 6-Question Package**:
- **Pedagogical Balance**: All 7 dialogue lines are meaningfully utilized:
  - **Q1 (`AppearDisappear`)**: Line 1 (*"Today, I am going to teach a new lesson about space."*) — spoken setup & recall; exposure to `to teach`.
  - **Q2 (`SentenceBuilder`)**: Line 2 (*"Space is very interesting!"*) — cold build from tiles; tests `interesting`.
  - **Q3 (`AppearDisappear`)**: Line 3 (*"We will read the textbook and write some sentences."*) — spoken setup & recall; tests `to read` + `to write` (double target).
  - **Q4 (`DialogueCompletion`)**: Line 4 (*"Can I ask a question?"*) — cold MCQ choice; tests `to ask a question`.
  - **Q5 (`DialogueCompletion`)**: Line 5 (*"Sure, I will be happy to answer it."*) — cold MCQ choice; tests `to answer`.
  - **Q6 (`ClozeSequence`)**: Line 6 (*"Will we _____ about the moon today?"*) → `["learn"]` — cloze blank; tests `to learn`. Line 7 (*"Yes, later in this lesson!"*) plays during confirmation.
- **Section 5 Scope**: Leaves the remaining 5 approved vocabulary items (`to know`, `again`, `to study`, `to understand`, `to do homework`) cleanly scoped for Image Dialogues.

✅ **Timestamp Transitions**:
- Agree with Codex on turn-taking intervals: each cold-build question (Q2, Q4, Q5, Q6) will utilize the standard ~0.3s video gap between `start_at` and `pause_at` before speech begins, with `answer_until` playing the full character response.

❌ **Next Steps**:
1. **Section 6 (Questions JSON)**: Populate Section 6 with the complete 6-question `VideoConversation` JSON structure.
2. **Section 4 (Visual Staging & Prompts)**: Draft the spatial layout (Teacher at desk/blackboard, Student at desk) and the 2-clip visual prompts for `at-the-school1.mp4`.

---

**Claude:** r-r.

✅ Codex's technical correction is right, and I've fixed Section 3's wording — my earlier phrasing ("no silent-gap constraint") was overclaiming. It only meant `audio_file1`'s *trigger* no longer depends on question position, not that `start_at`/`pause_at` can be identical. Reworded to say each cold question still needs a real (non-zero) interval for the position listener to fire the pause.

✅ Checked: this was never actually violated in the JSON I validated with `d` earlier — every cold question (Q2, Q4, Q5, Q6) already used a ~0.3s gap, matching what Codex and Antigravity both independently landed on. Nothing to change numerically, just the prose explaining why.

✅ **Section 6 written** — the full 6-question `VideoConversation` JSON block, matching Section 3 exactly. One change from the original hand-validated draft: per Codex's Q6 recommendation, Line 7 ("Yes, later in this lesson!") is now folded into Q6's `audio_file2` confirm clip (`answer_until` extended from `15.80` to `17.80`) instead of being a separate untracked tail — keeps it audible without a 7th question or a dangling word-not-in-vocab problem. Parsed clean.

❌ **Still open**: Section 4's room layout and per-clip visual prompts — not yet drafted. That's the next piece; flagging in case Codex or Antigravity wants to take a first pass before I do.

---

**Codex:**

✅ Completed the first pass of Section 4's room layout and per-clip visual prompts.

✅ Locked a fixed wide classroom composition: picture-only space whiteboard and Teacher area on the left, open center aisle, and seated Student desk on the right. Added cross-clip continuity rules for camera, furniture, board illustrations, characters, clothing, props, lighting, and dominant hands.

✅ Split production into two clips: Clip 1.1 covers Lines 1–3 and ends with Teacher holding the open textbook; Clip 1.2 begins from that exact held frame and covers Lines 4–7.

✅ Added paste-ready prompts with line-specific gestures and explicit 0.3–0.5s silent settled beats before cold Q2, Q4, Q5, and Q6. Line 7 remains the natural ungraded closing response inside Q6's confirmation segment.

❌ Durations remain first-pass estimates. Exact line boundaries and Section 6 timestamps must still be replaced after generated video approval and audio slicing.

❌ The existing `at-the-school/classroom.png` is a small simplified location icon rather than a usable character/room reference frame, so the production design still needs visual approval before generating continuity frames.

---

**Claude:** r-r. Reviewed Section 4.

✅ **Verified Codex's `classroom.png` flag directly rather than taking it on faith** — checked the actual file: 256×256, flat-icon sticker style (thick black outlines, no characters, blackboard + two chairs only). Same art-style family as `bedroom-bathroom-items`' icon set I found earlier for bathroom — built for image-quiz tile buttons, not scene/character reference. Confirmed: not usable as a staging reference, Codex is right.

✅ **Timestamps cross-checked against Section 6** — Clip 1.1's ~9–10s estimate and Clip 1.2's ~8–10s estimate both line up with the actual JSON: Clip 1.1 spans `00.00→08.70` (Q1 pause at `03.20`, Q2's 0.3s gap `03.20→03.50`, Q3 pause at `08.70`); Clip 1.2 spans `08.70→17.80`, with all three silent beats (`08.70→09.00`, `10.50→10.80`, `13.20→13.50`) matching Section 6's Q4/Q5/Q6 gaps exactly. No drift between the prose and the JSON.

✅ Nice detail worth calling out: the Q4 distractor *"Can I close the textbook?"* directly plays off Teacher opening the textbook during Line 3's staging — distractor is plausible specifically because of what's visible on screen, not just generically wrong.

❌ **One unflagged assumption, not blocking**: Teacher is specified as "adult woman" — that wasn't decided anywhere in Sections 1–3, it's a call Codex made while drafting. Not a problem (the standing rule is "any age," gender was never pinned down either way), just noting it as a production choice made without an explicit developer sign-off, in case `d` has a preference.

No corrections needed otherwise — Section 4 is internally consistent with Sections 3 and 6.

---

**Antigravity:**

✅ **Independent Verification of Sections 4 and 6**:
- **Section 6 (`VideoConversation` JSON Structure)**:
  - Validated the 6-question block against `level_config.dart` parser fields:
    - Q1 (`AppearDisappear`): `words`, `distractors`
    - Q2 (`SentenceBuilder`): `correct_order`
    - Q3 (`AppearDisappear`): `words`, `distractors`
    - Q4 (`DialogueCompletion`): `answer`, `distractors`
    - Q5 (`DialogueCompletion`): `answer`, `distractors`
    - Q6 (`ClozeSequence`): `sentence`, `answer`, `distractors`
  - Validated that Line 7 (*"Yes, later in this lesson!"*) is cleanly bundled into Q6's confirmation clip (`at-the-school1-q6-confirm`), providing natural closure without testing unapproved vocabulary.
- **Section 4 (Visual Staging & Prompts)**:
  - Validated lateral layout: Left (Whiteboard with picture-only space illustrations + Teacher area) → Center (Aisle) → Right (Seated Student desk).
  - Validated Clip 1.1 (Lines 1–3) and Clip 1.2 (Lines 4–7) continuity on the held open-textbook pose.
  - Explicit 0.3–0.5s silent settled beats before cold lines (Lines 2, 4, 5, 6) guarantee no premature mouth movement or gestures before `pause_at`.
  - Picture-only constraint on the whiteboard prevents AI generator text gibberish.

❌ **Next Actions**:
1. **Developer Approval**: Awaiting `d`'s sign-off on the Section 4 visual prompts and Section 6 question package.
2. **Section 5 (Image Dialogues)**: Once Section 4/6 are locked, ready to plan Section 5 image dialogues for the 5 remaining approved vocabulary items: `to know`, `again`, `to study`, `to understand`, and `to do homework`.
