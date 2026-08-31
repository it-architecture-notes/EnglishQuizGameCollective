# In the Bedroom — Adult Level Content Plan

## Current Topic

Review and refine the existing adult In the Bedroom level content package: audit the live `questions.json` / `translations.json` against the approved teaching vocabulary, resolve any gaps or issues, and extend the package only from agreed vocabulary. Unlike Waking Up, this level's content was not built from an empty plan — it already has 8 live questions and 12 translated vocabulary entries in production. Treat those as the starting draft for review, not as finished/approved content.

## 1. Decisions

- Scope is adults only. Kids content (`in-the-bedroom/kids/`) will be planned separately.
- This document belongs exclusively to the In the Bedroom level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- Existing level distributions must be checked before adding vocabulary so words already taught in earlier levels are not repeated without a clear teaching reason (note: `bedroom-bathroom-items` is a separate image-only level covering tangible bedroom nouns — check it before adding object vocabulary here).
- Vocabulary taught primarily by image-only levels must be checked before selecting tangible nouns for this level.
- This level currently has **no video content** — all live questions use image/audio-only templates (`AppearDisappear`, `ClozeSequence`, `ConvoTemplate-1`, `SentenceBuilder`, `WordPairs`). Sections 3–4 (Video Dialog / Video Scripts) stay reserved as placeholders and are only to be filled in if video content is explicitly approved for this level.
- Live `questions.json` and `translations.json` already contain real content (not `<TBD>` placeholders). Any change to them must be proposed and agreed here first — do not edit the live files directly ahead of agreement.
- Adults-only characters and settings should be used throughout the level.
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.

## 2. Actions

1. Audit the live English vocabulary and question package against the teaching scope.
   - Review earlier levels and `bedroom-bathroom-items` for vocabulary overlap.
   - Classify each existing question/word as keep-as-is, needs-revision, or remove.
   - Identify any gaps in the approved In the Bedroom teaching scope not yet covered.

2. Resolve issues found in the live package together.
   - Flag any weak distractors, ambiguous answers, or questions testing irrelevant memory.
   - Confirm every template field matches what its parser actually reads (see `codebase_signatures.md` / `level_config.dart`) before trusting a validator's clean run.

3. Propose and agree on any new or replacement questions.
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

Not applicable — this level currently has no video content. This section is reserved for future video content only if explicitly approved by the team; do not add a video plan here speculatively.

## 4. Video Scripts

Not applicable — see Section 3.

## 5. Image Dialogs

The following reflects the **live, already-produced** questions in `adults/questions.json`, restated here for review. Context/teaching-target descriptions below are inferred from the live JSON and existing asset filenames — they must be confirmed or corrected by the team, not assumed correct.

### Image Question 1 — `quietly`

- **Context:** Standalone recall sentence, adult setting.
- **Adult characters:** Single speaker (`genders: "m"`).
- **Dialogue:** Recall target: "She sleeps quietly in her room."
- **Teaching targets:** `quietly`
- **Template:** AppearDisappear
- **Audio file:** `she-sleeps-quietly-in-her-room-convo`
- **Image filename:** none currently set

### Image Question 2 — `too`

- **Context:** Standalone cloze sentence describing a dark room.
- **Adult characters:** Single speaker (`genders: "f"`).
- **Dialogue:** "It is ____ dark in the room." → answer `too`
- **Teaching targets:** `too` (intensifier); `dark` gets incidental exposure (already in `translations.json`)
- **Template:** ClozeSequence
- **Audio file:** `it-is-too-dark-in-the-room-convo`
- **Image filename:** none currently set

### Image Question 3 — `tired` / `lie down` / `rest`

- **Context:** Standalone multi-blank cloze sentence.
- **Adult characters:** Single speaker (`genders: "m"`).
- **Dialogue:** "I am very _____ , so I _____ to _____." → answers `tired`, `lie down`, `rest`
- **Teaching targets:** `tired`, `to lie down`, `to rest` (three blanks in one sentence)
- **Template:** ClozeSequence
- **Audio file:** `i-am-very-tired-so-i-lie-down-to-rest-convo`
- **Image filename:** none currently set

### Image Question 4 — `to make the bed`

- **Context:** Two-character morning routine dialogue.
- **Adult characters:** `genders: "f-f"`.
- **Dialogue:** Line 1: "Do you _____ every morning?" / Line 2: "Yes, I _____ every day." → answer `make the bed`
- **Teaching targets:** `to make the bed`
- **Template:** ConvoTemplate-1
- **Audio files:** `do-you-make-the-bed-every-morning-convo` / `yes-i-make-the-bed-every-day-convo`
- **Image filename:** none currently set

### Image Question 5 — `turn on` / `turn off`

- **Context:** Standalone two-blank cloze sentence contrasting on/off.
- **Adult characters:** Single speaker (`genders: "f"`).
- **Dialogue:** "I ____ the light when it's dark. I _____ the light when it's bright." → answers `turn on`, `turn off`
- **Teaching targets:** `to turn on the light`, `to turn off the light`
- **Template:** ClozeSequence
- **Audio file:** `i-turn-on-the-light-when-its-dark-convo`
- **Image filename:** none currently set

### Image Question 6 — `comfortable`

- **Context:** Standalone recall/build sentence about the bed.
- **Adult characters:** Single speaker (`genders: "m"`).
- **Dialogue:** "This bed is very comfortable."
- **Teaching targets:** `comfortable`
- **Template:** SentenceBuilder
- **Audio file:** none currently set
- **Image filename:** none currently set

### Vocabulary Question 7 — pronoun objects (`to me` / `to you` / `to him/her` / `to us` / `to them`)

- **Context:** WordPairs vocabulary matching, not a dialogue.
- **Teaching targets:** indirect-object pronoun phrases
- **Template:** WordPairs
- **Note:** These 5 phrases are not currently present in `translations.json`'s top-level word list — WordPairs carries its own inline `translations` per pair, but this is a gap to confirm against Decision rules on vocabulary coverage tracking.

### Image Question 8 — `awake` / `asleep`

- **Context:** Standalone two-blank cloze sentence contrasting states.
- **Adult characters:** Single speaker (`genders: "m"`).
- **Dialogue:** "She lies down _____ for hours before finally falling _____." → answers `awake`, `asleep`
- **Teaching targets:** `awake`, `asleep`
- **Template:** ClozeSequence
- **Audio file:** `she-lies-down-awake-for-hours-before-finally-falling-asleep-convo`
- **Image filename:** none currently set

### Image Question 9 — `to dream`

- **Context:** Standalone single-blank cloze question.
- **Dialogue:** "Do you _____ a lot?" → answer `dream`
- **Teaching targets:** `to dream`
- **Template:** ClozeSequence
- **Audio file:** none currently set
- **Image filename:** none currently set
- **Open issue:** uses singular `"answer"` instead of the `"answers"` array style used by Questions 2/3/5/8 in this same level — confirm whether `ClozeSequence`'s parser accepts both forms, or whether this should be normalized to `"answers": ["dream"]` for consistency.

### Image Question Placeholder

- **Context:** `<TBD>`
- **Adult characters:** `<TBD>`
- **Dialogue:** `<TBD>`
- **Teaching targets:** `<TBD>`
- **Template:** `<TBD>`
- **Image filename:** `<TBD>`
- **Image description:** `<TBD>`

## 6. Questions JSON Structure

The following is imported directly from the live `adults/questions.json` for review. Do not copy questions from another level into this section; only agreed edits to this content should be applied back to the live file.

~~~json
{
  "levelQuestions": [
    {
      "template": "AppearDisappear",
      "genders": "m",
      "questionData": {
        "words": "She sleeps quietly in her room.",
        "distractors": [
          "night",
          "day",
          "well",
          "morning"
        ]
      },
      "audio_file": "she-sleeps-quietly-in-her-room-convo"
    },
    {
      "template": "ClozeSequence",
      "genders": "f",
      "questionData": {
        "sentence": "It is ____ dark in the room.",
        "answers": [
          "too"
        ],
        "distractors": [
          "only",
          "other",
          "much"
        ]
      },
      "audio_file": "it-is-too-dark-in-the-room-convo"
    },
    {
      "template": "ClozeSequence",
      "genders": "m",
      "questionData": {
        "sentence": "I am very _____ , so I _____ to _____.",
        "answers": [
          "tired",
          "lie down",
          "rest"
        ],
        "distractors": [
          "only",
          "much",
          "stand up",
          "get up",
          "cook"
        ]
      },
      "audio_file": "i-am-very-tired-so-i-lie-down-to-rest-convo"
    },
    {
      "template": "ConvoTemplate-1",
      "genders": "f-f",
      "questionData": {
        "line1": "Do you _____ every morning?",
        "line2": "Yes, I _____ every day.",
        "answer": "make the bed",
        "distractors": [
          "read the book",
          "cook the lunch",
          "drive the car"
        ]
      },
      "audio_file1": "do-you-make-the-bed-every-morning-convo",
      "audio_file2": "yes-i-make-the-bed-every-day-convo"
    },
    {
      "template": "ClozeSequence",
      "genders": "f",
      "questionData": {
        "sentence": "I ____ the light when it's dark. I _____ the light when it's bright.",
        "answers": [
          "turn on",
          "turn off"
        ],
        "distractors": [
          "take out",
          "shut down",
          "turn in"
        ]
      },
      "audio_file": "i-turn-on-the-light-when-its-dark-convo"
    },
    {
      "template": "SentenceBuilder",
      "genders": "m",
      "questionData": {
        "correct_order": "This bed is very comfortable."
      }
    },
    {
      "template": "WordPairs",
      "questionData": {
        "english_words": [
          "to me",
          "to you",
          "to him/her",
          "to us",
          "to them"
        ],
        "translations": [
          {
            "tr": "bana",
            "es": "a mí",
            "fr": "à moi",
            "de": "mir",
            "it": "a me",
            "pt": "a mim",
            "ru": "мне",
            "zh": "给我",
            "ja": "私に",
            "ko": "나에게",
            "ar": "لي",
            "hi": "मुझे"
          },
          {
            "tr": "sana",
            "es": "a ti",
            "fr": "à toi",
            "de": "dir",
            "it": "a te",
            "pt": "a você",
            "ru": "тебе",
            "zh": "给你",
            "ja": "あなたに",
            "ko": "너에게",
            "ar": "لك",
            "hi": "तुम्हें"
          },
          {
            "tr": "ona",
            "es": "a él / a ella",
            "fr": "à lui / à elle",
            "de": "ihm / ihr",
            "it": "a lui / lei",
            "pt": "a ele / a ela",
            "ru": "ему / ей",
            "zh": "给他/她",
            "ja": "彼/彼女に",
            "ko": "그/그녀에게",
            "ar": "له / لها",
            "hi": "उसे"
          },
          {
            "tr": "bize",
            "es": "a nosotros",
            "fr": "à nous",
            "de": "uns",
            "it": "a noi",
            "pt": "a nós",
            "ru": "нам",
            "zh": "给我们",
            "ja": "私たちに",
            "ko": "우리에게",
            "ar": "لنا",
            "hi": "हमें"
          },
          {
            "tr": "onlara",
            "es": "a ellos",
            "fr": "à eux",
            "de": "ihnen",
            "it": "a loro",
            "pt": "a eles",
            "ru": "им",
            "zh": "给他们",
            "ja": "彼らに",
            "ko": "그들에게",
            "ar": "لهم",
            "hi": "उन्हें"
          }
        ]
      }
    },
    {
      "template": "ClozeSequence",
      "genders": "m",
      "questionData": {
        "sentence": "She lies down _____ for hours before finally falling _____.",
        "answers": [
          "awake",
          "asleep"
        ],
        "distractors": [
          "tired",
          "up",
          "early",
          "late"
        ]
      },
      "audio_file": "she-lies-down-awake-for-hours-before-finally-falling-asleep-convo"
    },
    {
      "template": "ClozeSequence",
      "genders": "f",
      "questionData": {
        "sentence": "Do you _____ a lot?",
        "answer": "dream",
        "distractors": [
          "dreams",
          "dreamed",
          "dreaming"
        ]
      }
    }
  ]
}
~~~

Question objects must use only fields supported by the selected template. Any change to timestamps, media filenames, audio filenames, image filenames, answers, distractors, or teaching targets must be agreed here before being applied to the live file.

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
      "english_word": "turn on the light",
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
      "english_word": "turn off the light",
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

Maximum messages: 10.
Order: oldest to newest.
Each agent appends one named message using `Claude`, `Codex`, or `Antigravity`.
When appending message 11, remove the oldest message first (FIFO), then append the new one.
Only current In the Bedroom discussion messages belong here.
Formatting rule: every agent's acceptance/agreement list must use `✅` green checkboxes; every issue, disagreement, or open item must use `❌` red crosses. Use these markers consistently in all new pipeline comments.

---

<!-- The In the Bedroom discussion starts here. No inherited messages. -->
