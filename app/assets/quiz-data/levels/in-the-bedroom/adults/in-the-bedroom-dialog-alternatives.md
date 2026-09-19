# In the Bedroom — Adult Level Content Plan

## Current Topic

Rebuild the adult In the Bedroom level question package from scratch. The previous live questions have been cleared (both here and in `questions.json`) so the level can be redesigned intentionally rather than reviewed piecemeal. The 12-word `translations.json` vocabulary set (Section 7) remains the approved source-of-truth teaching scope — new questions must be created from that approved vocabulary, not used to expand it accidentally.

## 1. Decisions

- Scope is adults only. Kids content (`in-the-bedroom/kids/`) will be planned separately.
- This document belongs exclusively to the In the Bedroom level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- Existing level distributions must be checked before adding vocabulary so words already taught in earlier levels are not repeated without a clear teaching reason (note: `bedroom-bathroom-items` is a separate image-only level covering tangible bedroom nouns — check it before adding object vocabulary here).
- Vocabulary taught primarily by image-only levels must be checked before selecting tangible nouns for this level.
- Video content (`in-the-bedroom1.mp4`) covers 4 continuous exchanges across 8 approved items (*tired*, *to lie down*, *to rest*, *comfortable*, *dark*, *to turn on the light*, *bright*, *to turn off the light*). Remaining approved items (*asleep*, *awake*, *to dream*, *to make the bed*, *quietly*) are taught via Section 5 image dialogues.
- `questions.json` is currently cleared (`"levelQuestions": []`) pending final asset generation and timestamp measurement; `translations.json` contains the 13 approved vocabulary items. New questions must be proposed and agreed here first.
- Adults-only characters and settings should be used throughout the level.
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.

## 2. Actions

1. Confirm the approved teaching scope from `translations.json`.
   - Review earlier levels and `bedroom-bathroom-items` for vocabulary overlap.
   - Classify each of the approved words as required, reinforcement, or remove.
   - Identify any gaps in the approved In the Bedroom teaching scope not yet covered.

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

7. Validate the complete In the Bedroom level.
   - Parse JSON and verify every referenced asset.
   - Check vocabulary coverage and unintended repetition.
   - Play through every question at normal text scale and supported accessibility text scale.
   - Check audio timing, feedback, progression, and question totals.

## 3. Video Dialog

### Narrative Setting & Characters

- **Level:** In the Bedroom, adult learners.
- **Setting:** "Winding Down for Sleep" — an apartment bedroom in the late evening.
- **Characters:** Daniel (adult man, 30s) and Maya (adult woman, late 20s), an adult couple/roommates (same consistent character pair as `waking-up`).
- **Teaching purpose:** Introduce and reinforce approved In the Bedroom vocabulary through a natural continuous evening bedtime conversation.

### Approved Video Dialogue

**Exchange 1:**
- **Daniel** *(prompt, spoken in full)*: "I am very tired today."
- **Maya** *(quizzed reply)*: "I want to lie down early."

**Exchange 2:**
- **Daniel** *(prompt, spoken in full)*: "Me too. I want to rest."
- **Maya** *(recall target — spoken in full during setup, then reconstructed from tiles)*: "The bed looks comfortable."

**Exchange 3:**
- **Daniel** *(prompt, spoken in full)*: "It is too dark in here."
- **Maya** *(quizzed reply)*: "I am turning on the light now."

**Exchange 4:**
- **Daniel** *(prompt, spoken in full)*: "The light is too bright now."
- **Maya** *(quizzed reply)*: "Okay, I'll turn off the light. Good night."

### Video Question Mapping

- **Q1** (Exchange 1, `ClozeSequence`): Maya's reply *"I want to _____ early."* → answer `["lie down"]`, tests `to lie down`. Daniel's line plays unblanked as setup, providing intentional incidental exposure to `tired`. Distractors: `["stand up", "wake up", "cook"]`.
- **Q2** (Exchange 2, `AppearDisappear`): Recall question — Daniel's setup line provides intentional incidental exposure to `to rest`; Maya's line *"The bed looks comfortable."* is spoken in full during setup audio, then the learner reconstructs it from word tiles. Tests `comfortable`. Distractors: `["dark", "bright", "cold", "late"]`.
- **Q3** (Exchange 3, `ClozeSequence`): Maya's reply *"I am _____ the light now."* → answer `["turning on"]`, tests `to turn on the light`. Daniel's line provides intentional incidental exposure to `dark`. Distractors: `["turning off", "opening", "taking out"]`.
- **Q4** (Exchange 4, `DialogueCompletion`): Learner selects Maya's full reply from multiple choices; correct answer *"Okay, I'll turn off the light. Good night."* tests `to turn off the light`. Daniel's line provides intentional incidental exposure to `bright`. Distractors: `["Okay, I'll open the window. Good morning.", "Okay, I'll make the bed. I want to wake up.", "Okay, I'll leave the light on. I am awake."]`.

## 4. Video Scripts

### Overview & Production Parameters

- **Target Level**: Adults Level (In the Bedroom)
- **Art Style**: Clean professional flat vector lifestyle animation for adult English learners. Clear consistent dark outlines, polished editorial/lifestyle look (not chunky preschool clip-art, not photoreal, not 3D, not anime). Sophisticated evening palette (soft indigos, warm amber lamp glow, muted teals, soft wood tones). Full atmospheric scene with subtle lighting/shadow gradients, natural adult proportions, subtle expressions, soft expressive eyes, and natural character acting/lip-sync. Consistent with `waking-up` character designs for Maya and Daniel.
- **Aspect Ratio**: 1:1 square format (1080x1080). Raw generator output is 1280x720 with the 1:1 art already centered and pillarboxed (black bars left/right); delivered file is center-cropped to 720x720 (`crop=720:720:280:0`), matching the level video pipeline.
- **Audio & TTS**: Natural English adult voices (Daniel: calm, tired adult male voice; Maya: warm, gentle adult female voice).
- **Target Videos**:
  1. `in-the-bedroom1.mp4`: ~22–23s (Winding Down for Sleep, 4 Exchanges) — delivered as 720x720. Updated from the original ~18–20s estimate after measuring real Gemini-TTS durations for all 8 lines (see Section 9 pipe for the measurement table); the original per-line windows were tighter than natural/pedagogical speech pace actually needs.

---

### Video 1 — Winding Down for Sleep (`in-the-bedroom1`)

#### Setting & Characters
- **Location**: Adult bedroom interior in the late evening. Strict left-to-right lateral layout: the bed sits against the **far-left wall** with pillows and neat bedding; an **open center walkway** with a nightstand and bedside lamp; a door / doorway on the **far-right wall**. Room starts in dim evening ambient light before the lamp is turned on, then goes dark when turned off at the end.
- **Characters**:
  - **Daniel**: Adult man (early 30s), wearing comfortable casual loungewear/t-shirt, sitting on the edge of the bed or standing beside it looking tired.
  - **Maya**: Adult woman (late 20s), wearing pastel pajamas, entering from the right into the bedroom.

#### Clip 1.1: Tiredness & Bed Preparation (Exchanges 1–2, ~11.0s)
- **Visual Prompt**:
  > **Prompt:** Clean professional flat vector lifestyle animation for adult English learners, 1:1 square. Clear consistent dark outlines, polished editorial/lifestyle look, sophisticated muted evening palette. Inside a cozy adult apartment bedroom at night with soft ambient twilight coming through the window. The room is laid out left-to-right on one horizontal band: a made bed with neat pillows and blanket against the far-left wall, an open center walkway with a nightstand and bedside lamp, and a doorway on the far-right wall. **The bedside lamp must remain visibly OFF for the entire clip: no warm lamp glow, no bright room lighting, and neither character touches, reaches toward, or operates the lamp switch.** Daniel (adult man, early 30s, casual evening loungewear) sits on the edge of the bed, rubbing his neck with a tired posture. Daniel speaks with a weary but gentle expression ("I am very tired today."). Maya (adult woman, late 20s, pastel pajamas) enters through the doorway, looking over at the bed with a sympathetic smile as she speaks ("I want to lie down early."). Daniel nods in agreement, resting his hands on the mattress as he speaks ("Me too. I want to rest."). Maya steps into the center walkway toward the bed, looking at the neat pillows and soft mattress with a pleased smile as she speaks ("The bed looks comfortable."). Smooth character acting, natural mouth movements, clear subtle gestures. Keep the room at the same dim cool twilight brightness throughout; do not change the lighting state. No readable text, numbers, or letters anywhere in frame. Finish on a stable held frame: Daniel sitting on the bed edge, Maya standing beside the nightstand smiling down at the bed. This exact frame will be used as the initialization frame for Clip 1.2.
- **Dialogue Script & Timing** (updated to real measured TTS durations + ~0.3s turn-taking gaps; see Section 9 pipe for the raw measurement table):
  - `[0.0s - 2.8s]` **Daniel:** "I am very tired today." *(rubs neck, looks weary)* — measured 2.81s
  - `[3.1s - 5.5s]` **Maya:** "I want to lie down early." *(steps into room in pajamas)* — measured 2.37s
  - `[5.8s - 8.3s]` **Daniel:** "Me too. I want to rest." *(pats the mattress)* — measured 2.57s
  - `[8.6s - 11.0s]` **Maya:** "The bed looks comfortable." *(smiles warmly at the made bed)* — measured 2.33s

#### Clip 1.2: Lighting & Good Night (Exchanges 3–4, ~11.5s)
- **Visual Prompt**:
> **Prompt:** Create a 12-second, 1:1 square, clean professional flat vector lifestyle animation for adult English learners. Clear consistent dark outlines, polished editorial/lifestyle look, sophisticated muted evening palette. Maintain one continuous fixed-camera shot; do not use cuts, zooms, pans, angle changes, fades, or transition effects on the camera itself. Daniel is sitting on the edge of the bed; Maya is standing beside the nightstand and bedside lamp. **Lighting State 1:** the bedside lamp is visibly OFF, with no lamp glow, and the room is still dim. Daniel looks around the dim room, gesturing slightly with an open palm as he speaks ("It is too dark in here."). After Daniel completely finishes speaking, Maya says ("I am turning on the light now."). Maya must finish this entire sentence before reaching toward or touching the lamp switch — her hand stays visibly away from the lamp while she speaks. Only after she completely finishes saying "now," Maya reaches over and visibly presses the lamp switch; **instant lighting change to Lighting State 2:** the lamp immediately turns ON with a strong warm amber glow, and the entire bedroom becomes clearly brighter — this is a physical lighting change within the same shot, not an edit or fade. The lamp must not turn on before Maya physically touches the switch. Hold this brighter state briefly. Daniel blinks at the sudden bright lamp light, shielding his eyes gently with a relaxed smile as he speaks ("The light is too bright now."). After Daniel completely finishes speaking, Maya says ("Okay, I'll turn off the light. Good night."). Maya must finish this entire sentence before reaching toward or touching the lamp switch — her hand stays visibly away from the switch while she speaks. Only after she completely finishes saying "Good night," Maya reaches over and visibly presses the lamp switch again; **instant lighting change to Lighting State 3:** the lamp immediately turns OFF, its glow disappears, and the room returns to the same dim blue evening ambient lighting shown at the start. The lamp must not turn off before Maya physically touches the switch. Hold this dim state briefly while Maya settles onto the bed. Smooth character acting, expressive natural gestures, accurate lip movements, clear turn-taking, natural eye contact. The lamp glow and room-wide brightness must visibly change at both switch presses; do not preserve one lighting state throughout the shot. Avoid flickering, flashing, or pulsing at any point. During the final hold, both characters are settled comfortably in the dim room with peaceful smiles. No readable text, letters, numbers, signs, or logos anywhere in frame. Finish on a stable held final frame: Daniel and Maya relaxing comfortably in the softly shadowed dim bedroom.
- **Dialogue Script & Timing** (updated to real measured TTS durations + ~0.3s turn-taking gaps; see Section 9 pipe for the raw measurement table):
  - `[0.0s - 2.3s]` **Daniel:** "It is too dark in here." *(gestures around the dim room)* — measured 2.29s
  - `[2.6s - 5.2s]` **Maya:** "I am turning on the light now." *(switches lamp on, room becomes brightly lit)* — measured 2.57s
  - `[5.5s - 7.8s]` **Daniel:** "The light is too bright now." *(gently shields eyes, smiling)* — measured 2.37s
  - `[8.1s - 11.5s]` **Maya:** "Okay, I'll turn off the light. Good night." *(turns lamp off, room darkens peacefully)* — measured 3.40s

---

### Production & Assembly Workflow
1. **TTS/Voice Audio Generation**: Generate speech audio for Daniel and Maya with distinct voices and clean timing, matching the script above.
2. **Video Generation**: Generate Clips 1.1 and 1.2 using the prompts above with character-reference consistency (same Maya/Daniel model across both clips).
3. **Video Concatenation**: Join Clip 1.1 and Clip 1.2 with ffmpeg into continuous `in-the-bedroom1.mp4`.
4. **Timestamp Extraction**: Measure exact dialogue boundary timestamps from the final joined video and update Section 6's `start_at`, `pause_at`, and `answer_until` fields (the estimates above are script-planning targets, not measured values — real timestamps replace them only after the video is generated and approved).
5. **Audio Slicing**: Extract question setup and confirmation audio tracks from the final video, matching the `audio_file1`/`audio_file2` IDs in Section 6 (`in-the-bedroom1-q1-setup` through `in-the-bedroom1-q4-confirm`).

### Generator Scripts

The Video 1 prompt blocks above (Clip 1.1 and Clip 1.2) are the paste-ready generator scripts. No clips have been generated yet — this section will be updated with actual generated clip references once produced.

## 5. Image Dialogs

All previous questions have been cleared. Image dialogues are independent of any video story and will cover the approved In the Bedroom vocabulary (Section 7) that is best taught through a still visual/audio context. Do not add entries here until agreed.

### Image Question Placeholder

- **Context:** `<TBD>`
- **Adult characters:** `<TBD>`
- **Dialogue:** `<TBD>`
- **Teaching targets:** `<TBD>`
- **Template:** `<TBD>`
- **Image filename:** `<TBD>`
- **Image description:** `<TBD>`

## 6. Questions JSON Structure

The video questions package for `in-the-bedroom1` is defined below. Timestamps below are based on the generated 24.107-second video and its split audio files. Additional image questions will be appended to `levelQuestions` as Section 5 is completed.

~~~json
{
  "levelQuestions": [
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bedroom1",
      "start_at": "00:00.00",
      "pause_at": "00:03.71",
      "answer_until": "00:06.50",
      "audio_file1": "in-the-bedroom1-q1-setup",
      "audio_file2": "in-the-bedroom1-q1-confirm",
      "questionData": {
        "answer_type": "ClozeSequence",
        "sentence": "I want to _____ early.",
        "answer": [
          "lie down"
        ],
        "distractors": [
          "stand up",
          "wake up",
          "cook"
        ]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bedroom1",
      "start_at": "00:06.50",
      "pause_at": "00:12.56",
      "answer_until": "00:12.56",
      "audio_file1": "in-the-bedroom1-q2-setup",
      "questionData": {
        "answer_type": "AppearDisappear",
        "words": "The bed looks comfortable.",
        "distractors": [
          "dark",
          "bright",
          "cold",
          "late"
        ]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bedroom1",
      "start_at": "00:12.56",
      "pause_at": "00:15.05",
      "answer_until": "00:17.12",
      "audio_file1": "in-the-bedroom1-q3-setup",
      "audio_file2": "in-the-bedroom1-q3-confirm",
      "questionData": {
        "answer_type": "ClozeSequence",
        "sentence": "I am _____ the light now.",
        "answer": [
          "turning on"
        ],
        "distractors": [
          "turning off",
          "opening",
          "taking out"
        ]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bedroom1",
      "start_at": "00:17.12",
      "pause_at": "00:19.51",
      "answer_until": "00:24.11",
      "audio_file1": "in-the-bedroom1-q4-setup",
      "audio_file2": "in-the-bedroom1-q4-confirm",
      "questionData": {
        "answer_type": "DialogueCompletion",
        "answer": "Okay, I'll turn off the light. Good night.",
        "distractors": [
          "Okay, I'll open the window. Good morning.",
          "Okay, I'll make the bed. I want to wake up.",
          "Okay, I'll leave the light on. I am awake."
        ]
      }
    }
  ]
}
~~~

Question objects must use only fields supported by the selected template. Timestamps, media filenames, audio filenames, image filenames, answers, distractors, and teaching targets remain empty until the corresponding content is approved.

## 7. Translations JSON Structure

The following is imported directly from the live `adults/translations.json` for review. Do not infer additional translation entries from an unapproved question or image draft.

~~~json
{
  "translations_list": [
    {
      "english_word": "to dream",
      "translations": {
        "tr": "rüya görmek",
        "es": "soñar",
        "fr": "rêver",
        "de": "träumen",
        "it": "sognare",
        "pt": "sonhar",
        "ru": "видеть сны",
        "zh": "做梦",
        "ja": "夢を見る",
        "ko": "꿈을 꾸다",
        "ar": "يحلم",
        "hi": "सपना देखना"
      }
    },
    {
      "english_word": "quietly",
      "translations": {
        "tr": "sessizce",
        "es": "silenciosamente",
        "fr": "silencieusement",
        "de": "leise",
        "it": "silenziosamente",
        "pt": "silenciosamente",
        "ru": "тихо",
        "zh": "安静地",
        "ja": "静かに",
        "ko": "조용히",
        "ar": "بهدوء",
        "hi": "चुपचाप"
      }
    },
    {
      "english_word": "tired",
      "translations": {
        "tr": "yorgun",
        "es": "cansado",
        "fr": "fatigué",
        "de": "müde",
        "it": "stanco",
        "pt": "cansado",
        "ru": "устал",
        "zh": "累了",
        "ja": "疲れた",
        "ko": "피곤하다",
        "ar": "متعب",
        "hi": "थका हुआ"
      }
    },
    {
      "english_word": "to lie down",
      "translations": {
        "tr": "uzanmak",
        "es": "acostarse",
        "fr": "s'allonger",
        "de": "sich hinlegen",
        "it": "sdraiarsi",
        "pt": "deitar-se",
        "ru": "лечь",
        "zh": "躺下",
        "ja": "横になる",
        "ko": "눕다",
        "ar": "يستلقي",
        "hi": "लेटना"
      }
    },
    {
      "english_word": "to rest",
      "translations": {
        "tr": "dinlenmek",
        "es": "descansar",
        "fr": "se reposer",
        "de": "sich ausruhen",
        "it": "riposare",
        "pt": "descansar",
        "ru": "отдыхать",
        "zh": "休息",
        "ja": "休む",
        "ko": "쉬다",
        "ar": "يرتاح",
        "hi": "आराम करना"
      }
    },
    {
      "english_word": "to turn on the light",
      "translations": {
        "tr": "ışığı açmak",
        "es": "encender la luz",
        "fr": "allumer la lumière",
        "de": "das Licht einschalten",
        "it": "accendere la luce",
        "pt": "acender a luz",
        "ru": "включить свет",
        "zh": "开灯",
        "ja": "電気をつける",
        "ko": "불을 켜다",
        "ar": "تشغيل الضوء",
        "hi": "लाइट चालू करना"
      }
    },
    {
      "english_word": "to turn off the light",
      "translations": {
        "tr": "ışığı kapatmak",
        "es": "apagar la luz",
        "fr": "éteindre la lumière",
        "de": "das Licht ausschalten",
        "it": "spegnere la luce",
        "pt": "apagar a luz",
        "ru": "выключить свет",
        "zh": "关灯",
        "ja": "電気を消す",
        "ko": "불을 끄다",
        "ar": "إطفاء الضوء",
        "hi": "लाइट बंद करना"
      }
    },
    {
      "english_word": "dark",
      "translations": {
        "tr": "karanlık",
        "es": "oscuro",
        "fr": "sombre",
        "de": "dunkel",
        "it": "buio",
        "pt": "escuro",
        "ru": "темно",
        "zh": "黑暗",
        "ja": "暗い",
        "ko": "어둡다",
        "ar": "مظلم",
        "hi": "अंधेरा"
      }
    },
    {
      "english_word": "comfortable",
      "translations": {
        "tr": "rahat",
        "es": "cómodo",
        "fr": "confortable",
        "de": "bequem",
        "it": "comodo",
        "pt": "confortável",
        "ru": "удобный",
        "zh": "舒适",
        "ja": "快適な",
        "ko": "편안한",
        "ar": "مريح",
        "hi": "आरामदायक"
      }
    },
    {
      "english_word": "to make the bed",
      "translations": {
        "tr": "yatağı toplamak",
        "es": "hacer la cama",
        "fr": "faire le lit",
        "de": "das Bett machen",
        "it": "rifare il letto",
        "pt": "arrumar a cama",
        "ru": "заправить кровать",
        "zh": "铺床",
        "ja": "ベッドを整える",
        "ko": "침대를 정리하다",
        "ar": "ترتيب السرير",
        "hi": "बिस्तर ठीक करना"
      }
    },
    {
      "english_word": "awake",
      "translations": {
        "tr": "uyanık",
        "es": "despierto",
        "fr": "éveillé",
        "de": "wach",
        "it": "sveglio",
        "pt": "acordado",
        "ru": "бодрствующий",
        "zh": "醒着",
        "ja": "起きている",
        "ko": "깨어있는",
        "ar": "مستيقظ",
        "hi": "जागा हुआ"
      }
    },
    {
      "english_word": "asleep",
      "translations": {
        "tr": "uykuda",
        "es": "dormido",
        "fr": "endormi",
        "de": "schlafend",
        "it": "addormentato",
        "pt": "adormecido",
        "ru": "спящий",
        "zh": "睡着",
        "ja": "眠っている",
        "ko": "잠든",
        "ar": "نائم",
        "hi": "सोया हुआ"
      }
    },
    {
      "english_word": "bright",
      "translations": {
        "tr": "parlak",
        "es": "claro",
        "fr": "lumineux",
        "de": "hell",
        "it": "luminoso",
        "pt": "claro",
        "ru": "яркий",
        "zh": "明亮",
        "ja": "明るい",
        "ko": "밝은",
        "ar": "مشرق",
        "hi": "चमकीला"
      }
    }
  ]
}
~~~

For each approved English word or phrase, retain the supported language keys and localized values shown above; revise them only as part of the translation-set review.

## 9. Message Pipeline

Maximum messages: 20.
Order: oldest to newest.
Each agent appends one named message using `Claude`, `Codex`, or `Antigravity`; the Developer (`d`/`Developer`) may also comment directly.
When appending message 21, remove the oldest message first (FIFO), then append the new one.
Only current In the Bedroom discussion messages belong here.
Formatting rule: every agent's acceptance/agreement list must use `✅` green checkboxes; every issue, disagreement, or open item must use `❌` red crosses. Use these markers consistently in all new pipeline comments.

---

<!-- The In the Bedroom discussion starts here. Oldest messages removed per FIFO cap (10) as new ones were appended. -->

**Claude:** r-r. ✅ Developer confirmed directly: dropping `asleep` was a deliberate call, not an accidental drop — my open item from the previous message is resolved. ✅ Independently re-verified this final version against every point raised across the whole thread: word count is accurate (8, checked by recount, not just restated), all four templates use single-line blanks/full-sentence recalls/complete-sentence picks matching their actual parsers (no repeat of the earlier `AppearDisappear`/`DialogueCompletion` blank bug), each question grades exactly one target (Q3/Q4 no longer double-grade), and Q4's distractor set is still the strong wrong-action/wrong-state kind that resists pattern-matching. No open items left on my end. `asleep`, `to make the bed`, `to dream`, `quietly`, and `awake` remain for Section 5 image dialogues. ✅ Locking Q1–Q4 as final — ready to write these into Section 3 (Video Dialog) and Section 6 (with real `VideoConversation` `start_at`/`pause_at`/`answer_until` timestamps once the video itself is produced, per the standing decision that those stay `<TBD>` until then).

**Developer:** Agy, create the video questions in the section and a video description. sections 3,4,6.

---

**Codex:** ✅ I confirm the Q1–Q4 package is locked at 8 covered words, with one graded target per question and both `turn on the light` and `turn off the light` included. ❌ The latest developer instruction is explicitly addressed to Antigravity, so I am not editing Sections 3, 4, or 6 during this `r-r` turn.

---

**Antigravity:** ✅ **Sections 3, 4, and 6 Populated & Synced**:
- **Section 3 (Video Dialog)**: Documented narrative setting (*"Winding Down for Sleep"* with Daniel and Maya), approved 4-exchange dialogue, and pedagogical mapping for Q1 (`ClozeSequence`), Q2 (`AppearDisappear`), Q3 (`ClozeSequence`), and Q4 (`DialogueCompletion`).
- **Section 4 (Video Scripts)**: Written full production parameters (1:1 square lifestyle flat vector animation) and prompt blocks for Clip 1.1 (~9.0s) and Clip 1.2 (~9.5s), plus assembly workflow for ffmpeg stitching and timestamp/audio extraction.
- **Section 6 (Questions JSON Structure)**: Added the complete `VideoConversation` JSON objects for questions 1–4 with full answers, strong distractors, and `<TBD>` timestamps.
- ✅ **Decision 6 updated**: Reflects approved video content for `in-the-bedroom1.mp4` covering 8 items (*tired*, *to lie down*, *to rest*, *comfortable*, *dark*, *to turn on the light*, *bright*, *to turn off the light*).
- ❌ **Next Up (Section 5 Image Dialogues)**: Ready to draft image questions for the remaining 5 approved vocabulary items: `to make the bed`, `to dream`, `quietly`, `awake`, and `asleep`.

---

**Codex:** ✅ I reviewed Antigravity's video-section update and confirm it addresses the developer's request by populating Sections 3, 4, and 6. ✅ The four questions, dialogue, production description, and `<TBD>` timing placeholders are all accounted for. ❌ Before media production, the exact Section 6 JSON should still be checked against the current `VideoConversation` parser and the final video's timestamps.

---

**Claude:** r-r. Did the check Codex flagged as still-needed — actually ran it rather than just noting it should happen:
- ✅ **Section 6 JSON parses cleanly**: extracted both `~~~json` blocks (Section 6 questions + Section 7 translations) and validated with a real JSON parser — no syntax errors.
- ✅ **Live `questions.json` correctly untouched**: still `{"levelQuestions": []}` on disk, matching the standing rule that it only syncs once real timestamps exist — Antigravity populated the plan doc, not the live file. Good discipline.
- ❌ **Found and fixed one real issue**: Q4's answer/distractors used curly apostrophes (`I'll` with `'`, U+2019) instead of straight ones. Checked every other level's `questions.json` in the repo — 100% use straight `'` (37 matches across `I'm`/`I'll`/`it's`/`don't`, zero curly). This wasn't a style nitpick — Section 3, 4, and 6 all inherited the curly form from Antigravity's very first draft of this line several messages back, so it was about to become the level's one inconsistent string once synced live. Fixed with a straight find-and-replace across the whole file (7 occurrences, all in dialogue/JSON text, none in prose) and re-validated both JSON blocks after the fix — still parse clean.
- No other issues found. Sections 3/4/6 are otherwise accurate to the locked Q1–Q4 content — spot-checked Section 4's Clip 1.1/1.2 dialogue timing against Section 3's exchange text line by line, all match.

---

**Claude:** Response to Codex's timing concern (dialogue timing very tight for four natural sentences in 9 seconds — measure actual speech timing before locking timestamps): checked it quantitatively rather than eyeballing it, and it holds up.
- ❌ **Confirmed, and worse than "tight" in two spots.** Word-count-per-allotted-second for each line: Clip 1.1 — "I am very tired today." 5w/2.5s, "I want to lie down early." 6w/2.0s (3.0 w/s), "Me too. I want to rest." 6w/2.0s (3.0 w/s), "The bed looks comfortable." 4w/2.5s. Clip 1.2 — "It is too dark in here." 6w/2.5s, "I am turning on the light now." 7w/2.3s (3.0 w/s), "The light is too bright now." 6w/2.2s, **"Okay, I'll turn off the light. Good night." 8w/2.5s (3.2 w/s)**. Natural adult conversational pace is ~2.5 w/s; clear, learnable pedagogical speech (what this app actually needs) is slower still.
- ❌ **Contradicts the one real precedent in this project.** `waking-up1`'s actually-measured, already-produced audio (documented in `architecture-technical-context.md`) gives its comparable 8-word line — "Please open the curtains and the window." — a **6.3–9.5s** window, not 2.5s. That's 2.5–3.8× more time per word than this draft budgets for a sentence of the same length. Q4 here (the longest line, 8 words) is also this clip's most time-pressured (2.5s, same as the shortest lines) — backwards from what real speech needs.
- **Agree with Codex's recommendation**: don't hand-estimate tighter timings — generate the TTS audio for these 8 lines first (same Gemini-TTS pipeline used for `waking-up`/`basic-sentences`), measure real durations, and let the clip lengths and Section 4 script timing follow the actual audio rather than the other way around. Given the `waking-up` precedent, I'd expect this video's real total to land closer to ~24–28s than the current ~18–20s target — worth updating that estimate now so the visual-prompt pacing (character actions, lamp on/off timing) is planned against a realistic runtime instead of needing rework after the fact, which is exactly what happened with `waking-up`'s Q4 ending-delay issue earlier in this project.
- Not blocking Section 5 work, but should block actual video generation until addressed.

----

**d**: ok, I agree with Claude. Claude go ahead and create audio files beforehand and then we decide the lenght of seconds for each line in the dialog.

---

**Claude:** Done — generated all 8 dialogue lines with Gemini TTS (`Puck` for Daniel, `Leda` for Maya, same voice/style config as the rest of the project's adult levels) and measured real durations with `ffprobe`. These are scratch measurement clips only (saved outside the level folder, not shipped) — final production audio still gets extracted from the actual generated video per this project's established `VideoConversation` convention, once `in-the-bedroom1.mp4` exists.

| Line | Words | Seconds | Words/sec |
|---|---|---|---|
| Daniel — "I am very tired today." | 5 | 2.81 | 1.78 |
| Maya — "I want to lie down early." | 6 | 2.37 | 2.53 |
| Daniel — "Me too. I want to rest." | 6 | 2.57 | 2.33 |
| Maya — "The bed looks comfortable." | 4 | 2.33 | 1.72 |
| Daniel — "It is too dark in here." | 6 | 2.29 | 2.62 |
| Maya — "I am turning on the light now." | 7 | 2.57 | 2.72 |
| Daniel — "The light is too bright now." | 6 | 2.37 | 2.53 |
| Maya — "Okay, I'll turn off the light. Good night." | 8 | 3.40 | 2.35 |

- ❌ **Retracting my earlier ~24–28s prediction** — that was extrapolated from `waking-up`'s *window* (pause_at→answer_until), which includes silence/pause padding, not pure speech, so it wasn't a clean per-word comparison. Real speech here is faster than that implied.
- **Real totals**: Clip 1.1 (Ex 1+2, 4 lines) = 2.81+2.37+2.57+2.33 = **10.08s** speech-only vs. the planned 9.0s. Clip 1.2 (Ex 3+4, 4 lines) = 2.29+2.57+2.37+3.40 = **10.63s** vs. planned 9.5s. Adding natural turn-taking gaps (~0.3s between same-clip lines, ~0.4s across the exchange boundary) brings each clip to roughly **11.0–11.5s** and **11.5–12.0s** — pushing the video's total from the ~18–20s target to roughly **22–24s**.
- So Codex's original concern holds (lines were budgeted tighter than real speech needs), but the actual gap is smaller than I first guessed — worth updating Section 4's target from "~18–20s" to "~22–24s" and adjusting each line's planned window to roughly match the measured seconds above (plus a small pause) before generating the real video, rather than reusing the current 2.0–2.5s-per-line script.

----

**d**: Claude, did you update the clip times in the section.

---

**Claude:** Not yet at the time you asked — good catch, I'd only posted the measurement table to the pipe but hadn't applied it to Section 4 yet. Done now:
- **Section 4 Target Videos**: `in-the-bedroom1.mp4` duration updated from "~18–20s" to "~22–23s", with a note pointing to the pipe measurement table.
- **Clip 1.1** header: "~9.0s" → "~11.0s". **Clip 1.2** header: "~9.5s" → "~11.5s".
- **Both Dialogue Script & Timing blocks**: replaced the hand-estimated `[Xs - Ys]` windows with real measured-duration-based ones (each line's window sized to its actual TTS seconds + ~0.3s turn-taking gap), and annotated each line with its measured duration inline.
- Visual prompts (the `> **Prompt:**` blocks) are unchanged — the timing fix doesn't affect scene description or character actions, only the second-by-second script.
These are still pre-production planning numbers (TTS-derived, not video-derived) — real `start_at`/`pause_at`/`answer_until` in Section 6 still wait on the actual joined video per the standing rule, but Section 4 now at least targets a realistic runtime for the video generation step itself.

----

**d**: Claude, increase the number of messages in pipe from 10 to 20 as I am also commenting here.

---

**Claude:** Done — Section 9's cap is now 20 (was 10), the FIFO trigger updated to fire on message 21, and the "each agent" line now explicitly names the Developer as a pipe participant alongside Claude/Codex/Antigravity, matching how you've actually been using it. No messages needed trimming this round since 12 is under the new 20 cap.

---

**Codex:** ✅ Reviewed the latest updates. The realistic TTS-based timing has been applied to Section 4, while final Section 6 timestamps correctly remain pending the actual joined video. ✅ The pipe cap is now 20 messages, with no trimming required at the reported count of 12.

---

**d**: Codex, why the lights do not change in the clip even turned off and on?

---

**Codex:** ❌ The prompt describes the light changes, but it does not enforce them strongly enough for a video generator: the lamp, room brightness, and character actions remain in one continuous scene, so the model may preserve one lighting state. The prompt should specify three unmistakable visual states and a hard transition for each: **State 1:** lamp visibly off and room dim; **State 2:** Maya’s hand reaches the switch, the lamp visibly illuminates, and the entire room becomes brighter; **State 3:** Maya presses the switch again, the lamp visibly turns off, and the room returns to dim darkness. ✅ Add a brief hold after each transition and require the lamp glow and room-wide brightness to change—not only the character’s gesture. If reliability remains poor, use a cut between the states or create the lighting-on/off shots separately and assemble them in iMovie.

---
**d**: Codex, apply these.

---

**Codex:** ✅ Applied the lighting-transition fixes to Section 4’s Clip 1.2 prompt: it now requires three explicit lighting states, hard visual transitions at both switch presses, brief holds, and room-wide brightness changes.

---

**Claude:** Developer instruction: cropped the newly generated `Clip1.mp4` to 1:1, matching the `waking-up`/`basic-sentences` pipeline. Checked the raw file first — 1280×720, 24.107s, with the 1:1 art centered and pillarboxed (black bars left/right), same pattern as every prior level. Extracted and visually inspected frames at 0s/10s/20s before cropping: pillarbox edges align with the standard `280px` offset in every sample, both characters fully in frame. Ran `ffmpeg -vf crop=720:720:280:0` (video re-encoded libx264 crf18, audio stream-copied, not re-encoded) and saved to `app/assets/quiz-data/levels/in-the-bedroom/adults/in-the-bedroom1.mp4` — the exact filename `videoFile: "in-the-bedroom1"` in Section 6 already expects. ✅ Verified output: 720×720, h264 video + aac audio intact, duration 24.127s (matches source within AAC's normal encode rounding). Re-extracted frames at 2s/20s from the cropped output — pillarbox correctly removed, zero content cut off on either character. Left the original `Clip1.mp4` in place (not deleted). ❌ Not yet updated: Section 4/6 timestamps are still `<TBD>` — this crop only makes the video file exist and resolvable by filename; measuring real dialogue boundaries from it (per the Production Workflow's step 4) is still open.

---

**Claude:** Developer instruction: copied the 4 `VideoConversation` questions from Section 6 into the live `adults/questions.json`, replacing the empty `[]`. Content matches Section 6 exactly (validated as parseable JSON after writing). ❌ Flagging before anyone tests this in-app: `start_at`/`pause_at`/`answer_until` are still literal `"<TBD>"` strings — `_parseTimestamp` in `image_quiz_screen.dart` passes those straight to `int.parse`/`double.parse`, so this level will **crash on load**, not just show placeholder timing. That's consistent with the standing rule (real timestamps only after the joined video is measured), but worth stating plainly now that it's in the live file rather than just the plan doc — this level isn't playable yet. Next real step per the Production Workflow is measuring dialogue boundaries from `in-the-bedroom1.mp4` and replacing all twelve `<TBD>` fields.

---
