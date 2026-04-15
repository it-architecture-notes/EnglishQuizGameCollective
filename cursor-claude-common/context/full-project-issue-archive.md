**Issue-24: Quiz template audio, translation, and TTS generation refactor.**

# Active Progress Context

## Active Issue

Description: Refactorings on audio, monster approach and translation on templates and quizzez.

Use Cases:
    General rules:
        - For all the audio enabled templates first check the audio tag in json object and second whether a audio file with the same name exists in the levels folder. if not don't enable the audio feature of the template.
        - If in any case user goes to next question when an audio is played, the audio will stop immediately and new page cycle will begin. 
    - Templates and corresponding objects will be refactored for the new requirements.
        - imageQuizTemplate-1: No translation or audio. remove both of them from the template and if provided ignore the given json object tags.
        - imageQuizTemplate-2: No translation. Audio file will be played once when the question appears after a pause (1 sec default), also there will be a button for audio, if the user presses this button while in the page it will play the audio for the question word again. while audio played, button will be disabled.
        - image template 3: No translation or audio. remove both of them from the template and if provided ignore the given json object tags.
        - image template spot difference: remove spot_difference_prompt from the template, only title_spot_difference is enough. no audio, no translation for this template.
        - convo template word pairs: No translation or audio. remove both of them from the template and if provided ignore the given json object tags.
        - convo template appear disappear:
            - this template will have translation however the translation will not be shown right away or auto. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation.
            - we will remove the initial follow the words intro screen and flashing. when entered the screen there will be a pause of 2 sec(configurable) then the words will start to appear in the box as it is now but on the main page not on a separate page. when completed, there will be another pause and then words will disappear. no flashing.
            - we will add a new feature. when user presses a title that's been already pressed the process will go back to the beginning to the time after the words disappear. That means user may restart the tapping to the tiles. however question page cycle will not begin from the beginning where words appear etc.
            - when the words appear in the boxes in the beginning, the audio file will play. without the audio file completed don't enable tapping to the tiles. audio file may finish before or after the word appearing cycle ends.
            - update to audio generation script: while generating the audio for this template put a pause between each word seperated by space so that they align with the words appearing one by one sequence.
        - convo template sentence builder:
            - this template will have translation however the translation will not be shown right away or auto. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation.     
            - Audio button will appear in the template. when tapped it will play the audio, when audio played button will be disabled.
        - convo template grammar:
            - this template will have translation however the translation will not be shown right away or auto. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation. translation will be the for the full sentence not with a blank.
            - no audio for this template.
        - convo dialog completion:
            - this template will have translation however the translation will not be shown right away or auto. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation. translation will be the for the full sentence not with a blank.
            - this template as a special template will support two audio file names: "audio_file1" and "audio_file2". First audio belongs to the question text. second audio belongs to the right answer.
            - first audio will be played in the beginning of the question, when question appers with a pause in the beginning.
            - second audio will be played when the user answers the questions. Whether answer is right or wrong the right answer audio will be played which is audio_file2.
            - if answer is correct the flow will go to next question after audio_file2 is completed. if answer is wrong the user next button will be avaialble only after audio_file2 playback is completed.
            - for audio_file1, which is question audio, a button will be placed in the template similar to sentence builder.
        - convo cloze sequence:
            - for this tempate there will not be an auto audio. however there will be an audio button similar to sentence builder playing the audio when pressed.
            - we will refactor the translation: we will not add the translation after the question sentence. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation. translation will be the for the full sentence not with a blank.
            - new feature for this template: when user presses a title that's been already pressed the process will go back to the beginning. That means user may restart the tapping to the tiles. this feature is available only if there are more than one cloze.
        - convo template 1:
            - this template will have translation however the translation will not be shown right away or auto. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation. translation will be the for the full sentence not with a blank.
            - for this template there will not be an auto audio. however there will be an audio button similar to sentence builder playing the audio when pressed.
        - convo template simon: remove this template completly I don't want to use this question template type.

## Audio Generation Script Improvements (tools/gemini_tts/generate_level_audio.py)

    - Voice selection by audio filename gender token:
        - If the audio file name contains "-male-" as a dash-separated token, pick a voice from the male voice pool (GEMINI_TTS_MALE_VOICES).
        - If the audio file name contains "-female-" as a dash-separated token, pick a voice from the female voice pool (GEMINI_TTS_FEMALE_VOICES).
        - "female" is checked before "male" to avoid misidentifying "-female-" as male (since "female" contains "male").
        - Applies to all single-speaker templates. For ConvoTemplate-DialogueCompletion, each clip (audio_file1, audio_file2) is checked independently and overrides the character-name-based voice selection when a gender token is present.

    - Optional TTS text override via top-level JSON fields:
        - For all audio-enabled templates (single audio file): add optional top-level "audio_file_text" field. When present and non-empty, its value is sent to TTS instead of the text derived from the question data (blanks-filling, word-joining, etc. are bypassed).
        - For ConvoTemplate-DialogueCompletion (two audio files): use "audio_file1_text" and "audio_file2_text" independently for each clip.
        - If the field is absent or empty, existing text derivation logic runs unchanged.

    - Gemini multi-speaker: replace single multi-speaker API call with two separate single-speaker calls + PCM concatenation:
        - Instead of using Gemini's multi_speaker_voice_config (which can hallucinate/swap dialogue), generate each line as a separate single-speaker call.
        - line1 uses the voice resolved for character1 (gender pool or filename token).
        - line2 uses the voice resolved for character2 (gender pool or filename token).
        - The two PCM clips are concatenated with a short silence (300ms default) between them, then converted to m4a as usual.
        - This matches how ElevenLabs already handles multi-speaker clips and eliminates hallucination risk.

---

**Issue-23: Adding audio capabilities to the game using TTS (Text-to-Speech).**

# Active Progress Context

## Active Issue

**Issue-23:** Adding audio capabilities to the game using TTS (Text-to-Speech).

---

## What Was Built

### Overview

Two development-time Python TTS generators (Gemini and ElevenLabs) that produce `.m4a` audio files for quiz questions, plus Flutter in-game playback wiring. No API calls happen at runtime — generated files are shipped as assets.

---

### 1. `audio_file` Key in `questions.json`

A new optional top-level key on question objects (sibling to `type`, `template`, `questionData`):

```json
{
  "type": "vocab",
  "template": "ConvoTemplate-DialogueCompletion",
  "audio_file": "how-are-you-convo",
  "questionData": { ... }
}
```

- Key name: `audio_file` (underscore)
- Value: a developer-authored label (e.g. `"how-are-you-convo"`)
- Audio is generated **only** for questions that have this key
- The label becomes the output filename (see below)

---

### 2. Gemini TTS Generator — `tools/gemini_tts/`

**Files:** `generate_level_audio.py`, `requirements.txt`, `.env.example`, `README.md`

**Output filename:** `{audio_file_value}.m4a` — the label directly, no prefix or suffix.

**Model:** `gemini-2.5-flash-preview-tts` via `google-genai` SDK.

**Voices (kid-friendly):**
- Puck — upbeat, friendly (default single-speaker)
- Leda — youthful, clear (default Voice B for conversations)
- Aoede — breezy, easy-going

**CLI:**
```
python3 tools/gemini_tts/generate_level_audio.py \
  --level-id greetings \
  [--voice Puck] [--voice-a Puck] [--voice-b Leda] \
  [--bitrate 96] [--dry-run] [--overwrite] [--question N]
```

**Audio pipeline:** Gemini PCM (24 kHz, 16-bit, mono) → WAV → M4A (AAC) via pydub/ffmpeg.

**`questions.json`:** read-only — never modified.

**`.gitignore`:** `tools/gemini_tts/.env`

---

### 3. ElevenLabs TTS Generator — `tools/eleven_labs_tts/`

**Files:** `generate_level_audio.py`, `requirements.txt`, `.env.example`, `README.md`

**Output filename:** `{audio_file_value}_elevenlabs.m4a` — same label with `_elevenlabs` suffix (configurable via `--output-suffix`).

**API:** ElevenLabs HTTP API. ConvoTemplate-1 uses two sequential calls (one per speaker) stitched with a short pause.

**CLI:**
```
python3 tools/eleven_labs_tts/generate_level_audio.py \
  --level-id greetings \
  [--voice-id <id>] [--voice-a-id <id>] [--voice-b-id <id>] \
  [--model-id eleven_flash_v2_5] [--bitrate 96] \
  [--output-suffix _elevenlabs] [--dry-run] [--overwrite] [--question N]
```

**`questions.json`:** read-only — never modified.

**`.gitignore`:** `tools/eleven_labs_tts/.env`

---

### 4. Template-to-Text Mapping (both generators)

| Template | Text extracted | Speaker mode |
|----------|---------------|--------------|
| `ConvoTemplate-1` | `line1.en` (blanks → substituted with `answer`) + `line2.en` | Multi-speaker |
| `ConvoTemplate-AppearDisappear` | Join `words` (string or array) | Single |
| `ConvoTemplate-Simon` | Join `words` (string or array) | Single |
| `ConvoTemplate-ClozeSequence` | `sentence.en` with blank tokens spoken as "blank" | Single |
| `ConvoTemplate-GrammarForm` | Same as ClozeSequence | Single |
| `ConvoTemplate-DialogueCompletion` | `line1.en` only | Single |
| `ConvoTemplate-SentenceBuilder` | Join `correct_order` (string or array) | Single |
| `imageQuizTemplate-2` | `answer` field — skip if absent | Single |
| `ConvoTemplate-WordPairs` | Skip | — |
| `imageQuizTemplate-1` | Skip | — |
| `imageQuizTemplate-3` | Skip | — |
| `imageQuizTemplate-SpotDifference` | Skip | — |

**ConvoTemplate-1 blank handling:** blanks (`_____`) in `line1.en` are replaced with the `answer` value so dialogue sounds natural (not "blank").

---

### 5. Schema Changes — `level_config.dart`

- `LevelQuestion.audioFile` (`String?`) — parses `"audio_file"` from JSON
- `AppearDisappearQuestionData.words`: accepts both `["I", "love", "tea"]` (array) and `"I love tea"` (string, split on whitespace) — backward-compatible
- `SentenceBuilderQuestionData.correctOrder`: same dual-format support (array or space-separated string)

---

### 6. Flutter Playback — `audio_service.dart`

New functions added following the existing player pattern:

- `playQuestionAudio(String assetPath)` — plays via a dedicated `_ttsPlayer` instance
- `stopQuestionAudio()` — stops the TTS player

Asset path convention: `quiz-data/levels/{levelKey}/{audio_file_value}.m4a`

---

### 7. Flutter Playback Triggers — `image_quiz_screen.dart`

`_scheduleQuestionAudio(q, {delay})` — central dispatcher with token-based dedup guard (prevents double-trigger on rebuilds).

| Template | Trigger | Timing |
|----------|---------|--------|
| `ConvoTemplate-1` | Direct in screen | Immediately on question load |
| `ConvoTemplate-SentenceBuilder` | Direct in screen | Immediately on question load |
| `ConvoTemplate-AppearDisappear` | `onReadyForAudio` callback | When interaction phase starts (internally managed by widget) |
| `ConvoTemplate-ClozeSequence` (`words_all_together: true`) | `onReadyForAudio` callback | 1 second after load |
| `ConvoTemplate-ClozeSequence` (`words_all_together: false`) | `onReadyForAudio` callback | When streaming completes |
| `ConvoTemplate-GrammarForm` | Direct in screen | 1 second after load |
| `ConvoTemplate-DialogueCompletion` | Direct in screen | 1 second after load |
| `imageQuizTemplate-2` | Direct in screen | Immediately on question load |

Stop audio: on question advance (`_goNext`) and on `dispose`.

Callbacks added:
- `cloze_sequence_quiz_body.dart`: `VoidCallback? onReadyForAudio`
- `appear_disappear_quiz_body.dart`: `VoidCallback? onReadyForAudio`

---

### 8. Test Data

**`app/assets/quiz-data/levels/greetings/`** — new level with 9 questions that have `audio_file` entries, covering: `ConvoTemplate-1`, `ConvoTemplate-DialogueCompletion`, `ConvoTemplate-ClozeSequence`, `ConvoTemplate-AppearDisappear`, `ConvoTemplate-SentenceBuilder`, `ConvoTemplate-GrammarForm`, `imageQuizTemplate-2`.

Sample audio files generated and stored in `cursor-claude-common/output/` for reference.

---

### 9. Comparing Gemini vs ElevenLabs

To compare providers on the same question:
1. Generate Gemini: produces `audio_file.m4a`
2. Generate ElevenLabs: produces `audio_file_elevenlabs.m4a`
3. To test ElevenLabs in-game temporarily, change the question's `audio_file` value to `"audio_file_elevenlabs"` so Flutter resolves `audio_file_elevenlabs.m4a`.

---

## Files Changed / Created

| File | Change |
|------|--------|
| `tools/gemini_tts/generate_level_audio.py` | New — Gemini TTS generator |
| `tools/gemini_tts/requirements.txt` | New |
| `tools/gemini_tts/.env.example` | New |
| `tools/gemini_tts/README.md` | New |
| `tools/eleven_labs_tts/generate_level_audio.py` | New — ElevenLabs TTS generator |
| `tools/eleven_labs_tts/requirements.txt` | New |
| `tools/eleven_labs_tts/.env.example` | New |
| `tools/eleven_labs_tts/README.md` | New |
| `app/lib/models/level_config.dart` | `audioFile` on `LevelQuestion`; dual-format `words` and `correct_order` parsers |
| `app/lib/services/audio_service.dart` | `playQuestionAudio`, `stopQuestionAudio` |
| `app/lib/screens/image_quiz_screen.dart` | `_audioAssetPath`, `_scheduleQuestionAudio`, per-template triggers, stop on advance/dispose |
| `app/lib/screens/quiz_templates/cloze_sequence_quiz_body.dart` | `onReadyForAudio` callback |
| `app/lib/screens/quiz_templates/appear_disappear_quiz_body.dart` | `onReadyForAudio` callback |
| `app/assets/quiz-data/levels/greetings/` | New level with images and questions.json with `audio_file` entries |
| `app/pubspec.yaml` | greetings level registered as asset directory |
| `.gitignore` | `.env` entries for both TTS tool directories |

---

**Issue-22: Template refactor, JSON-driven translations, titles, SpotDifference layout, Grammar/Dialogue EN fixes, monster eligibility**

# Active Progress Context

## Active Issue

Description: Refactorings and fixes for tempalates.

Use Cases:

Considering the tests I made on the waking-up questions:

- Translate button appears for all type of questions for vocab, we will change this. Translate will be an option selected in the question json object. It will be optional. If selected we will not replace the existing text anymore. The line 1 and line 2 for ConvoTemplate-1 or a string from "translation" object will be presented before the answering buttons of the screen. So the objects will be like:
    - For ConvoTemplate-1:
    {
        "questionData": {
            "answer": "alarm",
            "character1": "mike",
            "character2": "sarah",
            "distractors": [
            "pillow",
            "blanket",
            "mattress"
            ],
            "line1": {
            "en": "Did you hear my _____ this morning?"
            },
            "line1_translation": {
            "es": "¿Oíste mi <es of alarm> esta mañana?",
            "tr": "Bu sabah calar saati duydun mu?"
            },
            "line2": {
            "en": "Yes, it was very loud!"
            },
            "line2_translation": {
            "es": "¡Sí, sonaba muy fuerte!",
            "tr": "Evet, çok sesliydi!"
            }
        },
        "template": "ConvoTemplate-1",
        "type": "vocab"
    }
    when translate button is pressed line 1 and line 2 will be presented below the conversations above the answering questions. If these keys don't exist or selected language is "en" nothing will be shown.
    For template ConvoTemplate-AppearDisappear:
    {
        "questionData": {
            "auto_next_delay": 1,
            "display_duration": 0.8,
            "distractors": [
            "you",
            "coffee",
            "milk",
            "red",
            "big",
            "and"
            ],
            "words": [
            "I",
            "love",
            "tea"
            ]
        },
        "template": "ConvoTemplate-AppearDisappear",
        "translation": {
            "es": "<translation es>",
            "tr": "<translation tr"
        },
        "type": "vocab"
    }      
    if exitsts translation will be presented below the question text and above the answering questions. If this key doesn't exist or selected language is "en" nothing will be shown.
    For template ConvoTemplate-SentenceBuilder:
    {
        "questionData": {
            "auto_next_delay": 1,
            "correct_order": [
            "I",
            "like",
            "mornings"
            ],
            "translation": {
            "es": "<translation es>",
            "tr": "<translation tr"
            }
        },
        "template": "ConvoTemplate-SentenceBuilder", ConvoTemplate-WordPairs no change is needed.
        "type": "vocab"
    }
    same rules as above.
    For the template ConvoTemplate-DialogueCompletion:
    {
      "type": "vocab",
      "template": "ConvoTemplate-DialogueCompletion",
      "questionData": {
        "character1": "mike",
        "character2": "sarah",
        "line1": {
          "en": "Are you awake?",
        },
        "line1_translation": {
            "es": "¿Oíste mi <es of alarm> esta mañana?",
            "tr": "Bu sabah calar saati duydun mu?"
            },
        "answer": "Yes, I am up now.",
        "answer_translation": {
            "es": "<es translation>",
            "tr": "Kalktim"
            },
        "distractors": [
          "No, I am still asleep.",
          "I am under the table.",
          "The sky is blue."
        ]
      }
    }
    in this case if provided both translations will be above answering questions.
    For template ConvoTemplate-GrammarForm:
        {
        "questionData": {
            "answer": "fold",
            "distractors": [
            "folds",
            "folding",
            "folded"
            ],
            "hintWord": "fold",
            "sentence": {
            "en": "I _____ the blanket every morning."
            },
            "translation": {
            "es": "<translation es>",
            "tr": "<translation tr"
            }
        },
        "template": "ConvoTemplate-GrammarForm",
        "type": "grammar"
        }
    in this case if provided translation text will be above answering questions.
    For templates: ConvoTemplate-ClozeSequence and ConvoTemplate-WordPairs and Simon don't add translation option.
- Also for all the image quiz types 
    - imageQuizTemplate-1: add a "translation" optional key and if it's provided show the translation string given in the question object under the image.
    - imageQuizTemplate-2: add a "translation" optional key and if it's provided show the translation string given in the question object under the question string.
    - imageQuizTemplate-3: add a "translation" optional key and if it's provided show the translation string given in the question object under the question image.
    - imageQuizTemplate-SpotDifference: no translation is needed.
- After these changes remove the translate button from all the page, we don't need it we will control translation by configuration.
- Titles for questions:
    - For all the quiz types (image or convo) a global json file will be used to identify the title of the question. For all question types at the top of th page there will be a title. e.g. currently appear disapper page has a click_in_order title. Similarly all templates will have it and also they will have a corresponding key in the localization table.
- Some templates do not have question numbers <question>/<total question> make sure all templates have it before the title string at the top.
- imageQuizTemplate-SpotDifference images should be square and centrally aligned. all these images are 256x256 but I see them covering a tall rectangle in the screen.
- ConvoTemplate-GrammarForm 12/13 question shows the translation of the text as the question instead of the english original text.
- ConvoTemplate-DialogueCompletion also shows the translation of the text as the question instead of the english original text.

---

ADDITIONAL REQUIREMENT:

Only some templates are available for monster attack animation:

- Image quiz 1
- Image quiz 2
- imageQuizTemplate-SpotDifference

- only show monster animation for these type of questions. If the number of questions of this type is less than or equal to 6 in the level advance the monster every 1 wrong question. If this type of questions is more than 6 then advance in the way of 1 wrong answer (advance), 2 wrong answers advance, 1 wrong answer advance, meaning 1,2,1,2.

---

**Issue-21: Additional Quiz Templates, Bug Fixes, Timer Override & ClozeSequence Merge**

# Active Progress Context

## Active Issue

Description: Additional templates for the quiz questions, plus bug fixes, a per-question timer parameter, and a refactor that merges ConvoTemplate-2 into ConvoTemplate-ClozeSequence.

### New Templates (all implemented)

- **ConvoTemplate-SentenceBuilder** (`sentence_builder_quiz_body.dart`): Words given → player taps in correct sentence order. Immediate grid (no streaming/flash). Wrong tap → red on wrong tile, remaining slots system-filled from correct order; correct tiles show numbered badges. Distinct styling for player-filled vs system-filled slots.

- **ConvoTemplate-WordPairs** (`word_pairs_quiz_body.dart`): Left column (e.g. English) vs scrambled right column (e.g. L2). Tap right to select (blue), tap left to pair. Correct pair → both tiles move to a matched section at the bottom (green, separated by divider). All pairs matched → auto-advance after `auto_next_delay`. Wrong match → wrong left red, selected right red, **correct left for the selected right turns green** (nothing moves to bottom). `pair_count`: 3–4.

- **imageQuizTemplate-3** (Choose the Correct Sentence, `image_quiz_screen.dart`): Hero image + 4 full-sentence ElevatedButtons (height 56). Same green/red/Next feedback as imageQuizTemplate-1. Parameter: `distractor_type` (grammar / meaning / tense, informational).

- **imageQuizTemplate-SpotDifference** (`spot_difference_quiz_body.dart`): Localized sentence prompt + two side-by-side images; correct side randomised each load. Correct → green border; wrong → red border, other image green border; Next button via parent. Parameter: `auto_next_delay`.

- **ConvoTemplate-GrammarForm** (`grammar_form_quiz_body.dart`): Localized cloze sentence + `(hintWord)` below + 4 shuffled word buttons. Correct → green button; wrong → red button + correct green. Parameters: `sentence` (localized map), `hintWord`, `answer`, `distractors` (exactly 3).

- **ConvoTemplate-DialogueCompletion** (`dialogue_completion_quiz_body.dart`): Character labels + first speaker line + 4 full-sentence reply buttons. Same green/red feedback. Parameters: `character1`, `character2`, `line1` (localized map), `answer`, `distractors` (exactly 3).

### Bug Fixes

- **WordPairs green hint direction**: On wrong match the green hint now appears on the **left** column (the correct left word for the selected right word), not on the right. Built a `_reverseMatch` map at init to enable this.

### New Feature: Per-question timer override (`timer_seconds`)

- Added optional `"timer_seconds": N` to `questionData` for all four image templates (`imageQuizTemplate-1`, `-2`, `-3`, `imageQuizTemplate-SpotDifference`).
- Field added to each data class (`ImageQuestionData`, `ImageQuizTemplate2Data`, `ImageQuizTemplate3Data`, `SpotDifferenceQuestionData`) and parsed from JSON.
- `LevelQuestion.timerSecondsOverride` getter checks all four data classes.
- `_timerSecondsForCurrentQuestion()` helper in `image_quiz_screen.dart` resolves the override (unified mode → legacy mode → reminder mode → global config fallback).
- All 5 timer duration assignment sites updated to use the helper.

### Refactor: ConvoTemplate-2 merged into ConvoTemplate-ClozeSequence

**Motivation:** Both templates fill blank(s) in a sentence; merging removes duplicate UX paths.

**New `ConvoTemplate-ClozeSequence` schema:**
```json
{
  "template": "ConvoTemplate-ClozeSequence",
  "questionData": {
    "imageName": "alarm-clock",
    "sentence": {
      "en": "My alarm _____ ______",
      "tr": "çaldı",
      "es": "sonó"
    },
    "answer": ["went", "off"],
    "distractors": ["bed", "asked", "out"],
    "words_all_together": false,
    "auto_next_delay": 1.0
  }
}
```

**Blank detection:** any space-delimited token matching `^_{2,}$` (2+ underscores). Displayed as `_____ (N)` at render time.

**Translation hint:** if `userLanguage ≠ 'en'` and a locale key exists, `(value)` is appended at the end of the sentence automatically. Non-English locale values should be just the translated word/phrase.

**Tile layout:** horizontal `Wrap` (train-style) — no more 2×2 / 3×3 grid constraint; any distractor count is valid.

**Streaming:** `words_all_together: false` → splits `sentence['en']` on spaces, reveals one token per 450 ms; blanks shown at their position as they stream. `words_all_together: true` → all tokens appear immediately.

**Image:** optional 72×72 thumbnail above the sentence.

**ConvoTemplate-2 backward compat:** existing JSON with `"template": "ConvoTemplate-2"` is parsed via an adapter in `_parseConvo2AsCloze` → stored as `clozeSequenceData` with `wordsAllTogether: true`. Template name normalised to `ConvoTemplate-ClozeSequence` in `LevelQuestion`. No JSON migration required across existing level folders.

**`waking-up/questions.json`:** ClozeSequence sample migrated from old token-array format to new localized-map format; former ConvoTemplate-2 sample converted to explicit `ConvoTemplate-ClozeSequence` entry.

**`page-designs-and-templates.md`:** WordPairs and image-template sections updated to reflect new behaviour and `timer_seconds` parameter.

---

**Issue-20: New Image and Vocab Question Templates**

# Active Progress Context

## Active Issue: New Image and Vocab Question Templates

Description: Additional question templates with design and animations will be added to the game.

Use Case:

1. Convo-Template-Appear-Disappear (Sequence Memory from Disappearing Words)
Description:
A sentence appears word-by-word at the top. Each word disappears after a short delay. Then the player must tap the words in the correct order from a 3×3 grid below.

Parameters:
display_duration (default: 1 sec) – how long each word is shown before disappearing.
auto_next_delay (default: 1 sec) – wait time after a correct full sequence before moving to next question.

Step-by-step:
An instructional message “Follow the words” is shown for 3 seconds.
Empty boxes appear at the top (one box per word in the sentence).
Words are placed into the boxes one by one with a delay between each (using display_duration).
When all boxes are filled, the sentence flashes twice (words briefly blink off and on).
The boxes are cleared (words removed), leaving empty boxes.
A prompt “Click in order” appears above the boxes.

Below, a 3×3 grid shows words (sentence words + distractors, shuffled).

Player taps words in the same order as the original sentence.

If correct tap:
Word tile turns green. Word is placed in the right place in the ghost preview.
A small number appears on the tile (1, 2, 3… for its position in the sentence).

If wrong tap (wrong word or wrong order):
All tile presses are disabled. The last pressed wrong tile turns to red. All right words will be placed in the ghost preview.
A “Next” button appears. Ensure there is a distinct visual difference between words the player correctly placed and the words the system auto-filled after a mistake. Suggestion: Use a solid background for player-correct words and a dashed border/semi-transparent look for the system-filled words.

If full sentence order completed correctly:
An “OK” sign appears. and auto to next.

2. Simon Game Template (Light & Repeat Word Order)
Description:
Words from a sentence are placed on: 3×3 grid. Like Simon, tiles light up (and optionally play a tone) in the order of the sentence. Player repeats the sequence by tapping tiles.

Parameters:
auto_next_delay (default: 1 sec)
tile_highlight_duration (default: 0.5 sec) – how long each tile lights up during demo.

Step-by-step:
Sentence is configured (e.g., “I like apples”) and also distractors are configured in the question.
Words are shuffled onto a 3×3 grid (extra empty or distractor tiles possible).

Game shows the sequence: each tile in sentence order lights up (and plays sound).

Player taps tiles in the same order.

Correct tap: tile turns green, shows its position number (1, 2, 3…).

Wrong tap (wrong tile or wrong order):
All tiles disabled. Last pressed tile is red. The expected tile is green and the full sentence is presented on the top of the tiles. To keep it clean, make sure the 3x3 grid dims slightly when the full sentence appears at the top so the player’s eye is drawn to the correct text for reading practice.

“Next” button appears.
If full sequence correct: all correct tiles green → OK sign → auto-next.

3. Cloze with One-by-One Appear (Fill-in-sequence)
Description:
A sentence appears word-by-word, but cloze positions (missing words) show _____ with a number. Player must select missing words in the correct order from a tile grid. Distractors is in the config of the question.

Parameters:
auto_next_delay (default: 1 sec)
grid_size: 2×2 for 1 cloze, 3×3 for 2+ clozes.

Step-by-step:
Sentence words appear one at a time in the top area and stay visible.
When a cloze word is reached, _____ (1) appears instead (incrementing for multiple clozes).

Bottom grid shows possible answers (target words + distractors).
Player selects words in the correct cloze order (e.g., fill blank 1, then blank 2).

Correct selection: tile turns green and shows the cloze number at the corner and placed in the cloze location.

Wrong selection: tiles disabled → Next button appears. The last pressed tile turns to red, expected tile turns to green. On fail → show full correct sentence Highlight filled words

All clozes filled correctly: OK sign → auto-next.

4. Image Template – Find Correct Object from Noun
Description:
A noun is shown at the top. Below, 4 images are displayed. Player taps the image matching the noun.

Logic:
Same as existing image question template but reversed (noun first → pick image).
Correct: image background turns green → auto-next after delay.
Wrong: selected image background turns red, correct turns to green → Next button appears.

Parameters:
auto_next_delay (default: 1 sec)
show_correct_on_wrong (default: false)


FAQ: 
- For cloze template UX flow. If the sentence is: "The [1] jumped over the [2] dog," and the player taps the word for blank [2] first, what happens? - If they press word 2 first the question is wrong.
- If the sentence has 5 words but the grid has 9 tiles (4 distractors), should the player be allowed to tap distractors at all? Yes and it will be a wrong selection
- On wrong tap, do you want to replay the correct sequence once (to teach the player) before disabling tiles, or just fail immediately? - We show the correct order by showing the full sentence.
- After a cloze is filled correctly, does the _____ (1) in the sentence above get replaced by the selected word immediately, or only after all clozes are filled? - Immediately
- 

---

**Granular Activity Set Up with Algorithm**

Active Issue: Granular Activity Set Up with Algorithm

Description: Activity Level Quizziez Phase-1 will be completed using an algorithm.

Use Case: Activities to be followed:
    - Get the list of all the jpg, png images under the quiz-data/levels folder
    - Start with the activity waking-up as the first activity and create the first level of the game, main level:1 quiz:1
    - If not already there, create an activity folder under the quiz-data/levels with the activity name
    - From the images list that is already created in the beginning, find the ones that are relevant to the activity, for example bed, mattress are relevant to waking-up.
    - Copy 6 images of the list to the activity folder created for this activity
    - If you cannot find 6 relevant images then copy whathever you have
    - Under the same activity folder, create a question.json file if not already there.
    - Make sure that 6 or less images we added are included as image questions with right template.
    - When completed, from the activities.txt file find another activity that could come after the waking-up, like making-the-bed.
    - Complete all the steps given above for wakint-up for this activity as well.
    - In the same loop continue activity after activity until we have a full list of activities.
    - Make sure activities are not to high level. For example instead of one high level morning-preparations we can divide it into many activities such as waking-up, making-the-bed, shower and cleaning, having-a-breakfast etc.


---

**Issue-19: Activity-Based Quiz Restructuring**

Description: Transform to activity based quizzes and distribution of words.

Use Case:
- Currently in the images we have mostly location based and category based distribution, e.g hospital, jobs, household equipments. We need to distribute these images to an activity based grouping, since we will add other words to quizzes like verbs, adjectives etc.
- First gather all images under a single folder from which we will distribute to activity folders.
- Start creating the activity folders based on the lists provided in activities.txt. e.g. visiting-doctor, hiking-outdoors.
- Keep in mind that we will distribute images to these folders so don't create completely irrelevant activity folders
- Distribute images under the activities. Same image can appear under different activities but no more than thrice.
- In every activity folder include a questions folder having all the questions in the activity quiz.
- Questions will have 3 types: image, conversation and image with sentence templates.
- We will try to distribute the words in references folder files (verbs, adjectives etc) to the activities in a meaningful manner so we have equal distribution of different types.
- Some files in references folder have the words ordered with frequency. Try to repeat the higher frequency words in activities since the player needs to learn them more.
- Make sure the questions with template image-sentence will have words that can be easily represented with an image.

---

**Issue-18: Content completion for quizzes**

Description: The content will be completed for the game quizzes to be comlete.

Use Cases:

- For every quiz level folder (e.g. airport-1) make sure that there is a questions.json file so quiz will work without any error.
- In every questions.json make sure all the images under the folder is added as a question to the folder in an arbitatry order.
- Add a new vocabulary question template:
    - In this template there will not be a conversation, there will be an image and a sentence below the image. The sentence will have a cloze word and we will also add an image of the cloze word. For example: in the airport, or travel quiz, we will have sentence in the config as "Plane is ______". The answer will be taking of and we will show an image of a plane taking off.
    - The image name under the folder and the cloze (empty) word will be the same. For the example above the image name will be the same.
    - Template name can be: "template": "ConvoTemplate-2".
    - If the local language is different from english just after the cloze empty word there will be a "()" and inside it the translation of the answer will take place. For the same sentence above example if local language is spanish the sentence will look like "Plane is ______ (<spanish of taking off>)"


DEPRECATED
--
- To use as a reference for future implementations, as an example, user kitchen-1 folder
    - Add 5 conversation and grammar questions (3 vocab, 2 grammar) int the questions folder
    - Make vocabulary questions as existing vocab question format, a conversation piece talk that will be in the context of the folder (kitchen). That will require creatively generating a converation talk that will take place in kitchen. Make the answer and words relevant to the context. MAKE SURE that the question and answers are not one of the image items. For example don't create a conversation where the close word is can-opener since can-opener is in the images. The vocabulary can be mostly not an object, but a verb, like "cutting".
    - Make grammar question about the kitchen context but most the a grammar question as explained in the grammar quiz issue ticket previously.
--

---

**Issue-17: Refactor All the Levels to Single Level Map and Quiz with Question Template Structure**
Description: In the current implementation we have different quiz types with different templates for them. This structure will be changed and there will be a single level map and a quiz subLevel will have different type of questions (image, vocabulary or grammar) in it.

Use Case:

- When user selects a sub level a subLevel (with iconImageName) config file will be read to identify the questions in the quiz.
- Each question will have a template that identifies the view of the screen and the parameters needed to fill that template.
- Current vocabulary, grammar (with conversations) and image quiz templates (with guest animal and monster) will be kept the same and reused. For vocabulary questions there could be more than one template with different set of template parameters. e.g. instead of conversation a template that has a single sentence and an image of the cloze.
- Image quiz data will still come from the images under folders for the quiz, however the wrong answers will be read from the config file instead of randomly picked from all the image list under the folder. Therefore, for image questions there will be a config object.
- Questions config object will be like one of these:
{
  "levelQuestions": [
    {
      "type": "image",
      "template": "imageQuizTemplate-1",
      "questionData": {
        "imageName": "Apple",
        "wrongAnswers": [
          "Appricot",
          "Soap",
          "Bored"
        ]
      }
    },
    {
      "type": "vocab",
      "template": "ConvoTemplate-1",
      "questionData": {
        "character1": "mike",
        "character2": "sarah",
        "line1": {
          "en": "Excuse me, where is the _____?",
          "tr": "Affedersiniz, _____ nerede?",
          "es": "Perdona, ¿dónde está _____?"
        },
        "line2": {
          "en": "The departure gate is on the right.",
          "tr": "Kalkış kapısı sağda.",
          "es": "La puerta de embarque está a la derecha."
        },
        "answer": "gate",
        "distractors": [
          "ticket",
          "luggage",
          "passport"
        ]
      }
    }
  ]
}
- Level maps will be merged into a single map and 3 buttons in the home screen will merge into a "Start Game" button. Since we merged level maps that means we will have a longer map but the logic of how many unlocked levels are shown etc will all remain the same.
- Reminder levels will now be quiz type agnostic so in a reminder level unanswered questions should be stored in a storage array to be able to generate reminder levels later.

---

**Issue-15: Speech Bubbles between monster and animal**
Description: When monster approaches to animal there will be talk with them in every approach step in the selected local language.

Use Cases:
- In image quiz when user gives a wrong answer and in threshold monster is approaching the animal. In this step after monster's move is completed two speech bubbles will appear above both images and bubbles will present the text of a conversation. They will show an exchange between the animal and monster.
- Also at the end of the game when monster captures the animal, again two bubbles will be added to the failure overlay and when animal's cry image is presented, one random choice of step 4 choices will be presented.
- Bubbles will be dismissed when user pushes the next button after the wrong answer.
- Attacker (monster) and guest (animal) bubbles will appear at the same time.
- The conversation will be configured in JSON file and will structured as:
    - Language (same as app settings if not in json file default to en)
    - An array of possible step 1 conversations (one of the choices will be selected when monster moves from step stone 0 to step stone 1)
    - An array of possible step 2 conversation etc
    - Step 4

---

**Issue-14: Image Quiz Timer and Monster Action**
Description: Only for image quiz, a timer will be set for each question to answer and for each question a target closing monster action will be added. Applies to both normal and reminder mode.

Use Cases:
- The image quiz question image is smaller at the top of the screen to give room to the monster/animal row below it.
- A pie-chart countdown timer appears centered above the monster and moves with it. It starts full green and drains clockwise turning red as time runs out.
- Between the quiz image and the answer buttons there is a row showing: guest animal (left, fixed) | 4 step stones (spread across the width) | monster (right, moves left).
- Guest animal is randomly selected per quiz session by discovering subfolders under `assets/images/animals/`.
- Every guest animal has its own folder under `assets/images/animals/{name}/` with 5 pose images: `{name}-1.png` (happy) through `{name}-5.png` (crying).
- The monster is discovered from `assets/images/monsters/` — one PNG per monster, named `{name}.png`.
- For every "x" wrong answers the monster jumps one step closer to the guest animal, and the animal's pose changes. There are 4 steps of approach; step 4 is capture (game over).
- Step stones are individually positioned so the monster lands exactly above each stone. Stone colors left→right: red, orange, yellow, green (danger→safe). Consumed stones turn grey.
- When the monster reaches step 4, the quiz ends with a game-over overlay showing the guest animal (crying) and the monster face-to-face side by side. Quiz ends with zero stars and zero diamonds.
- The monster plays a looping idle attack animation while waiting for an answer (scales up 10% and lunges left 10% of its size, easeInOut, 700 ms loop). The idle pauses during the 500 ms stone-jump transition then resumes.
- A wind trail (light-blue horizontal lines) animates to the right of the monster each time it jumps to a new stone.

FAQ / Confirmed Decisions:
- Timer is per question. When it expires it counts as a wrong answer: correct answer button turns green, no red button shown, Next button appears. No auto-advance on expiry.
- Timer duration is configurable in `game_config.json`, default 5 seconds.
- X threshold formula: `x = max(1, min(4, (totalQuestions * 0.1).round()))`.
- Pose per step — 0: {name}-1.png, 1: {name}-2.png, 2: {name}-3.png, 3: {name}-4.png, 4: {name}-5.png (game over).
- Correct answers reset the timer; monster stays where it is.
- Monster and animal state is per quiz session, resets on every new image quiz game.
- Wrong answer due to timer expiry counts toward the monster wrong-answer count.
- Monster step transition is a smooth 500 ms AnimatedPositioned slide.
- Timer and monster apply in both normal and reminder mode. Monster/wrong-count persist across the mistake-review pass in reminder mode.
- The locked-levels preview in the levels screen shows the next 12 locked levels (raised from 10), and locked reminder levels now count against that budget.
- Animal and monster names are discovered at runtime from the asset manifest (no config list needed).

Asset Structure:
```
app/assets/images/
├── monsters/
│   └── {name}.png              ← one PNG per monster
└── animals/
    └── {name}/
        ├── {name}-1.png        ← happy
        ├── {name}-2.png        ← smile
        ├── {name}-3.png        ← normal
        ├── {name}-4.png        ← worried
        └── {name}-5.png        ← crying
```

Config (`game_config.json`):
```json
{
  "autoAdvanceDelaySeconds": 1.5,
  "imageQuizTimerSeconds": 5
}
```

Key Files Changed:
- `app/lib/screens/image_quiz_screen.dart` — main implementation
- `app/lib/services/image_quiz_level_loader.dart` — added `discoverGuestAnimalNames()`, `discoverMonsterNames()`
- `app/lib/services/game_config_loader.dart` — only `autoAdvanceDelaySeconds` and `imageQuizTimerSeconds`
- `app/assets/data/config/game_config.json` — removed guestAnimals/monsters fields
- `app/pubspec.yaml` — registered 10 animal folders + monsters folder
- `app/lib/screens/levels_screen.dart` — locked-preview limit raised to 12, reminder levels counted

Branch: `feature/issue-14-image-quiz-timer-monster`

---

**Issue-13: Reminder Quiz Levels at the end of Main Level**

Description: At the end of each main level we will include 2 reminder levels automatically which will ask a mix of questions from the level in the main level. The purpose is to remind the already compeleted items to the user. This is for every quiz type.

Use Cases:
- In the flow configuration, at the end of each level there will be two reminder quizzez. These quizzes will have common questions from the previous mainLevel levels. Their icon name will be iconImageName = "reminder.png"
- These levels will not have configured questions, they will pick the questions from the previous level based on this logic:
    - App will keep the wrongly answered each question from the levels of a main level in the gameplay state. e.g if users answers a question wrong in level 2 of main level this will be recorded so that question may be repeated in the reminder levels.
    - Some arbitatry questions from the previous levels some of the questions.
    - Don't make reminder level over 30 questions if wrong answers are over 60 (2 times 30) then remove starting from the least wrongly answered looking at the counter. If you need to decide between the wrongly answered with same wrong count then select randomly. Don't include any regular questions if wrong answers are more than than 60. If wrong questions is less then 60 then complete it to 60 by selecting random questions from the previous levels.
- Quizzez will be exactly same format of the quiz type (e.g. for image quiz reminder level quizzez, the page design etc will be the same as image quizzez)
- Quizzez will be included in the story flow as they are configured as part of the main level flow.

FAQ answers:
- User answered the same question wrong 3 times appear only once in the reminders.
- User played the same level and this time answered correctly, doesn't matter, still present in the reminders.
- User played the same level and this time answered wrong even previuous correct not in wrong list, include in the reminders.
- User played the same level and this time answered wrong and previuously in the wrong list, include in the reminders by increasing wrong counter.
- Random questions exclude wrong questions.
- The number of questions is dynamic since we don't know how many questions will be wrong.
- Questions distributed to reminder levels randomly, NOT first half to first reminder. shuffle(allReminderQuestions) split into two groups.
- Same question cannot appear in two levels
- If the user answers the same question wrong again, repeat it at the end of quiz until getting right. When you repeat the wrong questions in the reminder level ask them randomly at the end. so if there are 20 questions in total in the reminder level, user answers 5 wrong, ask this 5 with random order at the end, if still answers 3 wrong, ask after asking 5 questions this 3 in random order etc.
- There is no star and diamond earning in reminder levels
- Main level story is completed only after reminder levels
- Reminder levels will appear in the map UI with the same special icon picked from assets.
- question pool for reminders is all the levels in the same main level but not the reminder levels
- When are reminder questions generated is up to your decision.
- Wrong answer tracking is kept in the state json files.
- Reminder levels can be played only once and cannot be repeated. Since the user need to answer all questions right at some point. If user quits in the middle they can restart the reminder level again. User can play regular levels as much as they prefer.
- Reminder levels are locked and shown locked until the turn comes to them. Reminder levels are always at the end of main level.
- Main levels should not have less than 60 questions but in that case use all the questions in the main level as the regular questions and reminder levels will have less than 30 questions.
- If the user quits in the middle of the reminder level the same questions are repeated again, that means reminder level answers do not clear the wrong answer list.
- The scenario: 65 wrong answers, need to remove 5 to get down to 60. If the bottom 10 all have the same wrong count (e.g., all wrong once), randomly select which 5 to remove.
- No need to show users see how many times they've gotten a question wrong.
- For a reminder level to be considered "completed," the user needs to get ALL questions correct (due to the repetition of wrong questions at the end)
- The list is only cleared/updated once the entire Reminder Level is successfully completed, and we clear only the questions answered in that reminder level since there are more than one reminder levels.
- the 50 wrong answers and 10 randoms shuffled together first, then sliced
- the progress bar stays at 100% while they loop through. there be a visual indicator (like a header saying "Reviewing Mistakes")

---

**Issue-12: Main Level Story Implemenation**

* Description

Each main level contains a short story sequence (similar to Gardenscapes) where the player helps a character or situation improve.

The story progresses as the user completes quiz levels inside that main level.

Each main level has its own independent story.


* Functional Behavior

Story Start
When the user starts the first quiz level of a main level, the first story page is shown.

Story Progression
Story pages appear before specific quiz levels based on configuration.

Story Completion
After the last quiz of the main level is completed with ≥1 star, the final story page is shown.

Story Replay Rules

If a quiz is completed with 0 stars, the story page associated with that level will repeat when the user retries the level.

If a quiz is completed with ≥1 star, the associated story page is marked as completed and will not repeat during later replays of the same level.

Story progress is therefore tied to star completion status.

* Example Story Flow

Example main level with 5 quiz levels.

Flow:

Start Main Level 1 → Select Quiz 1
Show Story Page 0

Quiz 1 finished

if ≥1 star → Story Page 0 marked complete

Select Quiz 2
Show Story Page 1

Quiz 2 finished

if ≥1 star → Story Page 1 marked complete

Show Story Page 2
(This page instructs the player to complete the next two quizzes covered_levels_number = 2)

Quiz 3 finished

if ≥1 star → continue

Quiz 4 finished

if ≥1 star → Story Page 2 marked complete

Select Quiz 5

Quiz 5 finished

if ≥1 star → Show Final Story Page + congratulations animation

* Story Page Rules

Story pages are only displayed before a quiz starts.
One story page may cover multiple quiz levels.
Story pages belong to a specific main level.


* Story Configuration

Story content is defined in JSON configuration files.

Each story entry must specify:

main level ID
story pages
trigger quiz level
number of levels covered by the page
template type
text
images
animations

* Story Templates

Multiple story page templates can exist.

Each template may include different numbers of:

images

text blocks

animations

A template may omit certain elements.

Examples:

Template A

 character image
 speech bubble
 scene image

Template B

scene animation
multiple dialogue blocks

Template C

animation only
no dialogue

Templates are identified by page_template_id.

* Main Level Screen UI

On the level selection screen:

A round story icon is shown above the right side of the main level banner.

Rules:

If the first quiz of the main level is locked

→ show grey circle with question mark

If the first quiz is unlocked

→ show story icon image

* Transitions

When a story page opens or closes:

Use a fade-in / fade-out transition between the level map and the story overlay.

* Proposed Configuration Example - This schema can be improved during implementation.
{
  "main_levels": [
    {
      "main_level_id": 1,
      "story_sequences": [
        {
          "page_template_id": 1,
          "page_text_list_for_template": [
            {
              "en": "This puppy is injured! Help me take her to the vet.",
              "es": "¡Este cachorro está herido! Ayúdame a llevarla al veterinario."
            }
          ],

          "page_image_list_for_template": [
            "guide_puppy.png",
            "character_2.png"
          ],
          "page_animation_list_for_template": [
            "puppy_injury_animation"
          ],
          "event_id": 1,
          "trigger": {
        "type": "before_level or after_level",
        "level": 1
      },
          "covered_levels_number": 1
        }
      ]
    }
  ]
}

for templates:

{
  "story_templates": [
    {
      "template_id": 1,
      "layout": "character_left_dialogue_right",
      "requires_text": true,
      "requires_images": true,
      "requires_animation": false
    }
  ]
}

FAQ Answers: 

- If the player closes the story page the quiz start immediately since the story page is shown when the user already selects the level.
- players NOT be able to replay story pages later from a menu
- Not decided on type of animations, placeholder.
- story assets be bundled with the app
- main level story icon come from : defined in story JSON
- trigger->level = 3 covered_levels_number = 2 means page covers 3,4 
- If the user finishes Quiz 3 with 0 stars, then retries the story page before Quiz 3 reappear
- If A story page covers Level 3 and Level 4 and level 3 is completed, and level 4 failed. When the user replays level 4 don't show the story again.
- the "Animation" meant to an object contained inside the Frame not the full page.
- When Quiz 5 (the last level) is finished with $\ge 1$ star, wait until the user returns to the Map, then auto-pop the story.

**Issue-1: Project Baseline Setup**

-- Description:
Establish the foundational project structure and technical baseline for the portrait-mode mobile application. This includes selecting and agreeing on a technology stack with the developer, and setting up a scalable framework that supports multiple device resolutions—specifically targeting two mobile phone aspect ratios (e.g., 19.5:9 and 16:9) and two tablet aspect ratios (e.g., 4:3 and 16:10). The framework must also accommodate different background images optimized for each resolution group.

-- Goals

Define and document the tech stack in collaboration with the developer.
Set up the project structure to support future feature development.
Implement a resolution-aware system that can load appropriate background assets based on device type and aspect ratio.
Add folder structure for the assets as well: images (some images will be different for different resoutions), json files for configuration and state data.

-- Acceptance Criteria

Tech stack is selected, documented, and agreed upon by all stakeholders.
The project is initialized and configured for both Android and iOS portrait-mode development.
A resolution-handling mechanism is in place that detects device aspect ratios and serves corresponding background images.
Background image assets are organized and integrated for the four target aspect ratios.
The baseline is verified on representative devices or emulators for each target category.
The project is ready for the team to begin implementing user stories and features.

**Issue-2: Home screen with Buttons**

-- Description:
Generate a Flutter HomeScreen. Use a Stack to place a colorful background. In the center, create a Column with three large ElevatedButtons for 'Image Quiz', 'Vocabulary', and 'Grammar'. At the bottom of the screen, add a Container with 4 IconButtons representing Profile, Achievements, Friends, and Settings. Ensure the layout is responsive using MediaQuery."

- Image Quiz - When clicked opens a image quiz level screen. Level selection screen Will be explained in detail later.
 - Vocabulary - When clicked opens a vocabulary quiz level screen. Level selection screen Will be explained in detail later.
 - Grammar - When clicked opens a grammar quiz level screen. Level selection screen Will be explained in detail later.

Component,UI Strategy
Quiz Buttons,Use a Column for phones and a Grid (2 columns) for tablets to fill the width.
Navigation,Use a custom Container at the bottom with MainAxisAlignment.spaceEvenly.
Text Labels,"Keep labels short (e.g., ""Play,"" ""Me,"" ""Prizes"") or use icons only for younger kids."
Safe Area,"Wrap the entire Home Screen in a SafeArea to avoid the ""notch"" on iPhones."

Instead of a hidden menu, use a Bottom Navigation Bar or Action Row with these 4 high-visibility buttons:
Me (Profile): Displays the user's current avatar. Opens the Profile/Avatar customization screen. Opens profile settings panel where users can set their name and avatar.
Trophies (Achievements): A gold trophy icon. Opens a full-screen achievement panel.(placeholder UI for now)
Friends: An icon of a "Red heart" Opens the animal friend grid.(placeholder implementation)
Settings: A colorful gear icon. Opens the app settings.

Make Flutter automatically pick the right background.jpg for the device's screen density, create a folder structure accordingly for background image of home screen.

-- Goals

Create a vivid game entry page with user selections as explained

-- Acceptance Criteria

1. Visuals & Layout

Background: Use Stack with background.jpg set to BoxFit.cover.

Resolution: Asset folders (2.0x, 3.0x) must handle density automatically.

Safe Zone: Wrap all UI in a SafeArea to avoid notches/dynamic islands.

2. Main Quiz Buttons (Center)

Adaptive: Single Column on phones; 2-column Grid on tablets (MediaQuery).

Items: 3 Large buttons: Image Quiz, Vocabulary, Grammar.

Action: Tap navigates to placeholder level selection screens.

3. Dashboard Nav (Bottom)

Style: Fixed bottom container with spaceEvenly alignment.

4. Technical

Accessibility: Minimum 48x48 touch targets for kid-friendly use.

Performance: Precache background image to prevent flickering.

**Issue-3: Levels Page (Finite Batch Scroll) Objective**

Implement a vertically scrollable Levels page which opens when homescreen quiz is selected and that:

Loads data from local JSON files based on selected quiz type in home screen

Groups sub-levels under main-level ribbon banners

Renders sub-levels in batches of 10

Loads next batch when user scrolls within 300px of bottom

Opens correct quiz page on sub-level click

Data Sources
1. Sub-levels

File:

[quiz-type]-quiz-flow.json

Structure:

[
  { "mainLevel": 1, "iconImageName": "plane", "title": "Items in a Plane" },
  { "mainLevel": 1, "iconImageName": "hospital", "title": "Hospital Items" },
  { "mainLevel": 2, "iconImageName": "animals", "title": "Wild Animals" }
]

Rules:

Render in the order they appear.

No additional sorting.

2. Main Level Metadata

File:

[quiz-type]-flow-main-levels.json

Structure:

[
  { "mainLevel": 1, "title": "Transportation" },
  { "mainLevel": 2, "title": "Nature" }
]

Rules:

mainLevel must match sub-level file.

Banner title comes from this file.

If metadata missing for a mainLevel → skip rendering that group.

If metadata exists but no sub-levels → do not render banner.

Rendering Rules

Vertical scroll layout.

2-column responsive grid for sub-level icons.

Icon on top, title below.

Each main level banner appears once before its first sub-level.

Sub-level icons stored in:

/assets/flow-icons/[iconImageName].png

Missing image → show fallback placeholder.

Scroll Logic (Finite Batch Rendering)

Load entire JSON in memory at init.

Render first 10 sub-level items.

When scroll position is within 300px of bottom → render next 10.

Continue until all items rendered.

After last batch → stop loading (end-of-content behavior TBD).

Do not re-render previous items.

Batching is based on raw sub-level items (not grouped per main level).

Navigation

From Home:

Pass quiz-type string (e.g., image, text).

On Levels page:

Load:

[quiz-type]-quiz-flow.json

[quiz-type]-flow-main-levels.json

On sub-level click:

[quiz-type]-quiz.html

Example:

image → image-quiz-flow.json → image-flow-main-levels.json → image-quiz.html
Performance Constraints

Lazy load images.

Smooth scroll on mid-range mobile.

Expected total items < 300.

No virtualization required.

*Acceptance Criteria

Correct JSON files load per quiz type.

Sub-levels grouped under correct banners.

Initial render = 10 items.

Next batch loads at 300px threshold.

No duplicate banner rendering.

Images lazy load.

Clicking sub-level opens correct quiz page.

Responsive on mobile portrait.

No console errors when metadata and flow files align.

**Issue-4: Image Quiz Page**

* Description

This page is opened with a fade and scale animation when a level icon is selected from the Levels Page and the selected quiz type is Image Quiz.

The page contains:

A quiz question image displayed at the top of the page, loaded dynamically from the application assets.

Four answer buttons showing different words.

A Next button that is hidden by default and appears only when a wrong answer is selected.

An end-of-game panel that appears when all questions are answered. This panel contains:

Star rating (0–3 stars),

A diamond icon with text showing how many diamonds were earned in this level,

An “OK” button that navigates back to the Levels Page.

A loading screen may appear before the first question while assets are prepared.

* User Flow

When the user selects a level from the Levels Page, the selected level provides an iconName and levelNumber. The application loads all images from the assets subfolder named <iconName>-<levelNumber> (for example: plane-4). All image filenames inside that folder are collected. The filename without its extension becomes the correct answer text for that image. For example, from pilot.png the application extracts “pilot”.

The level folder must contain at least 4 images. If fewer than 4 images exist, the level must not start.

* Question Generation

For each question in the level:

A random unused image from the level folder is selected.

The filename (without extension) becomes the correct answer.

Three incorrect answers are randomly selected from the remaining vocabulary of the same level.

The four answers (one correct + three incorrect) are shuffled randomly.

No duplicate answers are allowed.

The same question image cannot appear more than once in the same level session.

The quiz continues until all images in the folder have been used exactly once.

* Answer Behavior

When the user selects an answer:

All answer buttons immediately become inactive to prevent multiple selections.

If the selected answer is correct:

The selected button turns green.

The application waits for a globally configured delay (autoAdvanceDelay seconds).

If it is not the last question, the next question loads automatically.

If it is the last question, the quiz proceeds directly to the end-of-level panel.

The correct answer counter is incremented.

If the selected answer is wrong:

The selected button turns red.

The correct answer button turns green.

The Next button appears below the answers.

The application waits for the user to press Next.

If it is the last question, the Next button becomes “Finish”.

* Scoring and Completion Rules

At the end of the level, the success rate is calculated as:

successRate = (correctAnswers / totalQuestions) × 100

Stars are awarded according to the following rules:

successRate ≥ 85% → 3 stars

successRate ≥ 70% and < 85% → 2 stars

successRate ≥ 60% and < 70% → 1 star

successRate < 60% → 0 stars

A level is considered completed only if the player earns at least 1 star (successRate ≥ 60%). The next level is unlocked only if the current level is completed.

If the player earns 0 stars, the level is not marked complete and the next level remains locked.

After the result panel is shown, pressing “OK” returns the player to the Levels Page.

* Diamonds and Replay Rules

Diamonds earned in a level are calculated as:

diamondsEarned = correctAnswers

Diamonds are accumulated globally across all levels within the same quiz type.

If the level is replayed:

If the new diamondsEarned is less than or equal to the previously recorded diamonds for that level, no additional diamonds are added to the total.

If the new diamondsEarned is greater than the previously recorded value, only the difference is added to totalDiamonds.

Example:

First play: 6 diamonds

Second play: 9 diamonds

Additional diamonds awarded: 3

Star ratings are stored as the highest star achieved. A new star value overwrites the previous value only if it is higher.

* Persistence

Game state is stored in a JSON file in the local storage of the mobile device, accessible by the application for reading and writing.

Data is saved only when a level is completed (after the end-of-level screen appears).

Stored data includes, per quiz type:

levelNumber

highestStars

highestDiamonds

completion status

totalDiamonds (global for that quiz type)

unlocked levels

Each quiz type maintains separate progress. Completing Level 1 in Image Quiz does not complete or unlock Level 1 in other quiz types.

If the user exits the application during a level, no progress is saved and the level restarts from the beginning when reopened.

* Acceptance Criteria

A level must not start if its folder contains fewer than 4 images.

Each image in a level is used exactly once per level session.

Each question displays exactly 4 answer buttons.

Answer options contain exactly one correct answer and no duplicates.

After selecting an answer, all answer buttons become inactive.

If the answer is correct, the next question loads automatically after the configured delay.

If the answer is wrong, the correct answer is highlighted and a Next button appears.

On the final question, the flow proceeds to the end-of-level screen.

Star rating follows the defined percentage thresholds.

A level is marked complete only if at least 1 star is earned.

Diamonds are awarded equal to the number of correct answers.

Replay does not allow diamond farming; only improvement differences are added.

Only the highest star value is stored.

Progress is saved only after level completion.

Exiting mid-level results in a full restart of that level.


**Issue-5: Vocabulary Test Quiz Page**

Description:
Implement a vocabulary test quiz page that tests users' vocabulary through cloze (fill-in-the-blank) questions within a conversational context. The page presents a step-by-step conversation between two characters across 10 questions, where users must identify the correct word to complete the blank space.

User Flow:

User selects a vocabulary quiz level from the Levels Page (e.g., "airport" theme, level 4)

System loads the corresponding JSON data file and character images

User progresses through 10 conversation steps, each with one fill-in-the-blank question

User selects answers from 4 multiple-choice buttons

After completing all questions, user can view the full conversation

Users can toggle translations at any time to see the conversation in other languages

Data Structure & Assets:

JSON File Format:

Location: /assets/vocabulary/data/

Naming convention: [theme-name]-[level-number].json (e.g., airport-4.json)

Schema:

json
[
  {
    "character1": "mike",  // icon name for first character
    "character2": "sarah", // icon name for second character
    "line1": {
      "en": "Can you help me find the _____?",  // English with blank
      "tr": "_____ bulmama yardım eder misin?",  // Turkish translation
      "es": "¿Puedes ayudarme a encontrar _____?" // Spanish translation
      // Additional languages as needed
    },
    "line2": {
      "en": "The departure gate is on the right.",
      "tr": "Kalkış kapısı sağda.",
      "es": "La puerta de embarque está a la derecha."
    },
    "answer": "gate",  // correct word for the blank
    "distractors": ["ticket", "luggage", "passport"] // wrong answer options
  },
  // 9 more objects for the full conversation
]
Character Images:

Location: /assets/vocabulary/characters/

Format: PNG files named after character identifiers (e.g., mike.png, sarah.png)

Page Design & UI Components:

Header Section:

Two character images displayed side by side

Character name labels under each image (e.g., "Mike", "Sarah")

Conversation bubbles pointing to each character containing their dialogue line

Current question indicator (e.g., "Question 3/10")

Conversation Display:

Character 1 image with bubble showing line1 text (with blank)

Character 2 image with bubble showing line2 text (may or may not contain blank)

Blank represented as "_____" in the text

One blank per question, located in either line1 or line2 based on answer field

Answer Selection:

4 multiple-choice buttons below the conversation bubbles

Options include correct answer + 3 distractors from JSON

Styling consistent with Image Quiz buttons

Immediate visual feedback on answer selection

Selected answer highlights

Next question appears automatically after selection (or with "Next" button - TBD)

Action Buttons:

Translate Button:

Tap to toggle functionality

When active, replaces all conversation text with translations in selected language

Tapping again reverts to English

Translates both conversation bubbles simultaneously

Language selection (if multiple languages) to be determined

Show Full Conversation Button:

Grayed out/disabled until all 10 questions are completed

After completion, tap to open scrollable panel

Panel displays complete conversation with line owner labels

Shows original English text only

Format: "Mike: Can you help me find the gate?" (with actual word, not blank)

Technical Requirements:

Data Loading:

On page load, parse theme and level from URL/state

Construct JSON file path: /assets/vocabulary/data/[theme]-[level].json

Load character images from /assets/vocabulary/characters/

Handle missing files gracefully with error message

Question Logic:

Track current question index (0-9)

Parse JSON to determine which line contains the blank (line with answer in its English text)

Display correct line with "_____" placeholder

Shuffle answer options (correct + distractors) for each question

Validate user selection against answer field

Track correct/incorrect answers for reporting

Translation Feature:

Store current language state (default: 'en')

On translate toggle, switch all visible text to selected language

Maintain blank placeholder in translations where answer should be

Ensure smooth transition between languages

Full Conversation Panel:

Enable button only after question 10 is answered

Generate ordered list of all 10 exchanges

Replace blanks with actual answers

Display in scrollable modal/drawer

State Management:

Current question index

User answers for each question

Translation language state

Quiz completion status

Acceptance Criteria:

Loads correct JSON data based on selected theme and level

Displays 2 character images with name labels and conversation bubbles

Shows current question progress (e.g., "3/10")

Correctly identifies which line contains the blank

Displays blank as "_____" in appropriate line

Presents 4 shuffled answer options including correct answer

Provides immediate visual feedback on answer selection

Translate button toggles all text between English and selected language

Full conversation button disabled until quiz completion

After completion, full conversation panel shows all 10 exchanges with answers filled in

Character images load correctly from assets folder

Graceful error handling for missing JSON files or images

Responsive design works on mobile and tablet

Dependencies:

Level selection passes correct theme and level parameters

Vocabulary JSON files created for all themes/levels

Character icon images available in assets folder

Translation strings available in JSON files

Future Considerations:

Add support for multiple translation languages

Implement scoring and progress saving

Add sound effects for correct/incorrect answers

Consider animation for conversation flow


**Issue-6: Profile Panel**

Description:
Defines scope and strcuture of the user profile panel that can be opened on the home screen.

- Profile button opens the panel
- On the panel there are these fields:
- Avatar Name
- Avatar Picture, Avatar Change Button, A panel opens when avatar change button is pressed (pop up) and a grid of avatar pictures are offered 4x4 for now. Avatar pictures will be read from avatars folder. When an avatar is selected panel is closed and avatar is accepted as user avatar and saved when profile panel is closed. In the beginning an avatar picture with ? mark will be assigned to each new user.
- Profile Panel Close Button on top right. This button saves the state to the game play json state file where stars and diamonds are kept.
- The main achievements like how many stars, diamonds are collected until to date is shown.
- When the user opens the profile panel the first time a unique id or uuid (timestamp uniqueness nonce) is assigned to the user and saved in the state json. Also the date joined is created and saved. 
- Current Level, completed levels, level progress. total number of questions answered, streak also presented for each quiz type are shown. All of these parameters are calculated when a quiz ends (any type of quiz) and saved in the state json. Level progress will be calculated with maximum level is calculated according to the flow json

1. Access & Navigation

Trigger: Tapping the Profile button on the Home Screen opens the panel.

Dismissal: A Close Button (X) is located in the top-right corner.

Persistence: Closing the panel triggers a save operation to the game_play_state.json file.

2. Identity & Avatar Management

User Info: Display Avatar Name, generate but do not show Unique ID (UUID), and Date Joined.

Logic: If a UUID/Date Joined does not exist (first-time open), generate them using a timestamp or any other method to avoid collision.

Avatar Selection: * Initial State: New users are assigned a default "?" placeholder image.

Change Workflow: Tapping the "Change" button opens a 4x4 grid popup.

Source: Images are dynamically loaded from the /avatars folder.

Selection: Selecting an image updates the preview and closes the popup immediately. The change is committed to the state file when the main Profile Panel is closed.

3. Statistics & Achievement Display

Economy: Show lifetime totals for Stars and Diamonds.

Progression: * Current Level & Completed Levels.

Level Progress Bar per quiz type: Calculated based on the flow json number of levels, or instead of calculating again everytime you can store the number of levels in a persisted data parameter.

Activity Metrics: * Total questions answered.

Current Streak.

Performance breakdown per Quiz Type.

Note: These values are pre-calculated and updated in the JSON state at the end of each quiz session.


**Issue-7: Progression System – Level Unlocking & Star History**

Description

Refactor the Levels Page from a fully unlocked state to a progression-based system. Users must earn stars to advance, and visibility of future levels is restricted to a dynamic "10-level window."

Functional Requirements & Core Logic
- Initial State: New users (no progress) see only the first level of all quiz types as unlocked. All other levels are initially disabled.
- Unlock Criteria: Level $N+1$ unlocks only if Level $N$ is completed with $\ge 1$ star. A score of 0 stars indicates the level is not yet completed.
- Replayability: Users can replay any unlocked level (including those with 3 stars) at any time.

Rewards & Persistence
- Performance Tracking: Maintain a history in the state JSON of the best_stars and best_diamonds earned for every level.
- Delta-Based Rewards: Users only earn the improvement over their previous best.Calculation: $Earned = \max(0, Current\_Play - Previous\_Best)$.
  If the current run is lower than the previous high score, 0 additional diamonds/stars are awarded.
- Wallet Integration: The Total Wallet (Global Stars/Diamonds) must be updated immediately upon level completion.

Navigation & UX
- Cold Boot Behavior: When the app is launched fresh, the Levels Page should auto-scroll to the furthest unlocked level.
- Session Persistence: During an active app session, after completing a level and returning to the menu, the scroll view must focus (center) on the level just played, rather than jumping to the furthest progress point.

UI States & Visibility ("The Horizon")
- Active State: Levels with $\ge 1$ star and the first currently available locked level are fully colored and interactable.
- Locked State (The Window): The 10 levels immediately following the last completed level are visible but desaturated (greyscale) and non-interactable.
- Hidden State: Any level index $> (Last\_Completed\_Index + 10)$ must not be rendered in the DOM/UI list.
- Dynamic Update: Upon successful completion of a level, the UI must append the next available "Hidden" level to the list to maintain the 10-level visibility buffer.Issue-7: Progression System – Level Unlocking & Star History


**Issue-8: Achievements Page**

Description: Adding the achievements to the existing achievements panel which is opened by thropies button from homescreen.

Use Cases:
- User will be able to see the current achievements locked or unlocked in the achievements panel. Locked are greyed out.
- Use a list style ui since column grid might get very cramped
- Which image icon belongs to which achievement will be identified with a config json file, it can be in game_config or a separata file.
- For progress icons also show a progress bar showing the progress (e.g. how many days streak currently, how many perfect scores etc)
- Sorting is according to the order of the list below
- Panel will have a scrollable grid with icons and icon labels for achievements
- If I add achievements later, grant achievements based on existing stats, the tracking does not start only once the feature is live.
- Achievements are not per Quiz Type, they are global covering all quiz types
- Progress is stored locally in a local data store, similar to profile data
- New achievements could be added later, be flexible while creating the data structure
- Achivements are as follows:
  EARLY GAME
    First Quiz Completed
    First Perfect Score
    3-Day Streak
  MID GAME
    Lightning Round (Complete a quiz in under 30 seconds)
    Jack of All Trades (Play quizzes from 5 different categories)
    10 Quizzes with 3 Stars
    50 Quizzes Completed
    Brainiac (Get 50 consecutive correct answers spanning quizzez)

  LATE GAME
    30-Day Streak
    50 Perfect Scores
    Flash (Complete a quiz in under 15 seconds)
    World Explorer (Play quizzes from 15 different categories)

    ULTIMATE CHALLENGES
    All Quizzes with 3 Stars
    100-Day Streak
    Get a perfect score in 10 different levels in each quiz type

    As a sample this config can be used or enhanced:
    "achievements": [
    {
      "id": "first_quiz_complete",
      "type": "milestone",
      "title": "First Quiz Completed",
      "description": "Finish your very first quiz!",
      "icon_locked": "icon_first_quiz_grey",
      "icon_unlocked": "icon_first_quiz_color",
      "goal_value": 1,
      "tracking_key": "total_quizzes_completed"
    },
    {
      "id": "brainiac_streak",
      "type": "progress",
      "title": "Brainiac",
      "description": "50 consecutive correct answers.",
      "icon_locked": "icon_brainiac_grey",
      "icon_unlocked": "icon_brainiac_color",
      "goal_value": 50,
      "tracking_key": "current_correct_streak",
      "show_progress_bar": true
    }
    ]

**Issue-9: Friends Page**

Description:
There will be a friends page as a panel and user will be able to free some animals using their diamonds.

Use Case:
- A friends page will be opened from the home screen using the relevant button.
- On the panel there will be a grid of 12 animals. Animal icons will be locked (greyed) in the beginning.
- Animal images (square) will be placed under the assets in the a well named and placed directory.
- The user will be able to free these animals using the collected diamonds.
- Grid animals will be sorted in the grid based on a game configuration in the json. How many diamonds are needed per animal will be added in the same config.
- There will be a popup message when the panel started stating that diamonds are needed to free the animals.
- When an animal is freed there will be an animation of that animal being happy and jumping.

**Issue-10: Settings Page Test Driven Requirements**

FEATURE: Setting Panel Page for Game Settings

AS A user
I WANT TO configure my game preferences (language, music, sound effects)
SO THAT the game experience matches my preferences and persists across sessions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ACCEPTANCE CRITERIA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

** TEST 1 — Happy Path
  GIVEN the user is on the home screen
  WHEN the user presses the settings button
  THEN the settings panel opens showing:
    - Language selection dropdown
    - Music on/off toggle
    - Sound/FX on/off toggle

** TEST 2 — Music Toggle Behavior

GIVEN music is currently ON
WHEN the user turns the Music toggle OFF
THEN background music should stop immediately (if playing)
AND background music should not play during quiz sessions

GIVEN music is currently OFF
WHEN the user turns the Music toggle ON
THEN background music should play during quiz sessions
AND in both cases
    The application state is updated
    The new value is stored in settings state
** TEST 3 — Sound/FX Toggle Behavior

GIVEN Sound/FX is ON
WHEN the user turns the Sound/FX toggle OFF
THEN no sound effects should be played during:
 Correct answer
 Wrong answer
 Button clicks (if applicable)

GIVEN Sound/FX is OFF
WHEN the user turns the Sound/FX toggle ON
THEN sound effects should be played during supported game events
AND
The application state is updated accordingly
Note:
"(what sounds will be played for which activities will be added)"

TEST 4 — Language Selection & Localization

GIVEN the user selects a language from the dropdown
AND the dropdown values are loaded from a configuration JSON file
WHEN a new language is selected
THEN:
 All visible UI labels update to the selected language immediately
 Settings page labels update
 Menu labels update
 Popup messages update
AND:
Localization values are read from configuration (e.g.:
{
"en": { "settings_title": "Settings" },
"fr": { "settings_title": "Paramètres" }
})
AND:
Non-visible resource identifiers (e.g., image file names) are not required to support localization. language change apply immediately

TEST 5 — Settings Persistence

GIVEN the user has modified one or more settings
WHEN the application is fully closed
AND reopened
THEN:
 The previously selected Language is restored
 The previously selected Music state is restored
 The previously selected Sound/FX state is restored
 Settings must be stored in local persistent storage on the device

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ARCHITECTURAL CONSTRAINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Single source of truth (e.g., SettingsState / SettingsProvider)
Settings must be reactive (UI updates instantly)
Localization must be driven from config JSON, not hardcoded
Acceptance criteria = externally observable behavior
Architectural constraints = internal design rules

**Issue-11: Grammar Quiz Page**

Description: There will be a grammar quiz page with multiple choice selections.

Use Cases:

* Grammar Quiz Question Types are as follows, all of them are multi choice:
    - Similar to Vocabulary Page a conversation between two parties will be presented with one verb is empty and the user will try to find the right tense for the verb, or the right auxillary
    - There will be 4 selections with different orders of the words and only one of them is a correct sentence and user will try to find which one.
    - Banked close: where there will be many empty places in the sentence on the middle top of the screen and user will try to find the right choice with all the words in sequence are correct. so the answer will be like (e.g.was/have/asked)
    - (Yes/No): Is the given sentence gramatically correct or not.
    - Which of them are correct: one of the selections is correct for a given context. e.g.
        A) Me and John are going.
        B) John and I are going.
        C) John and me are going.
        D) Me and him are going.
* A quiz can have these questions mixed, so not necessarily only one type. We have to have an object identifying question type and necessary fields for the question. You decide on the ojbect structure but obviously there will be a question type.
* No drag drop questions
* For every question except first one which is similar to vocab quiz and has to chararacters talking, there will be a character on the screen and a speech bubble and the question will be in the bubble. character images will be read from a folder (your choice but don't share with vocabulary folder) under assets and will be randomly selected every time. Images will be not full body length but from hip or chest up.
* Right wrong behaviour is same as vocab or image quiz
* No translation or toggling is needed for grammar
* Rewards and final screen structure is same as other quizzez.
* grammar quiz data follow the same pattern as vocabulary (one JSON file per level)
* except yes/no all questions have have 4 answer options
* Grammar quiz progress be tracked and persisted like other quizzes.
* For yes/no there will be only 2 buttons not 4 buttons with 2 empty.
* Banked cloze: one choice fills ALL blanks at once (not one blank at a time). Each option shows a sequence like "was/have/asked".
* All 5 question types to be built in this issue.
* AI creates sample quiz data JSON files for the existing 2 levels (airport-1, airport-2) with mixed question types.