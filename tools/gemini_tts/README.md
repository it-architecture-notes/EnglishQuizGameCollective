# Gemini TTS Level Audio Generator

Development-time utility to generate quiz audio assets with Gemini TTS.

## Scope

- Reads one level's `questions.json`
- Generates `.m4a` only for questions with top-level `audio_file`
- Writes files into the same level folder under `app/assets/quiz-data/levels/{level_id}/`
- Does **not** modify `questions.json`
- No runtime API calls in the Flutter app

## Requirements

- Python 3.10+
- `ffmpeg` installed and available on PATH
- Gemini API key in environment (`GOOGLE_API_KEY`)

Install Python deps:

```bash
pip install -r tools/gemini_tts/requirements.txt
```

Set API key:

```bash
export GOOGLE_API_KEY="your_key_here"
```

Or copy `tools/gemini_tts/.env.example` to `tools/gemini_tts/.env` and set the key.

## Voice configuration (environment)

Gemini TTS uses **prebuilt voice names** (see Google’s Gemini TTS docs). Configure **two comma-separated lists**:

| Variable | Role |
|----------|------|
| `GEMINI_TTS_FLAVOR` | `kids` or `adults` (CLI `--flavor` overrides). Kids mode changes style prompt, default voice pools, output suffix, and questions file preference. |
| `GEMINI_TTS_MALE_VOICES` | **Adults** male voices. First entry is default speaker A when `--voice-a` is not passed. If unset → `Puck`. |
| `GEMINI_TTS_FEMALE_VOICES` | **Adults** female voices. First entry is default speaker B when `--voice-b` is not passed. If unset → `Leda`. |
| `GEMINI_TTS_KIDS_MALE_VOICES` | **Kids** male voices (ignored for adults). If unset → `Puck,Fenrir,Sadachbia,Achird`. |
| `GEMINI_TTS_KIDS_FEMALE_VOICES` | **Kids** female voices (ignored for adults). If unset → `Leda,Laomedeia,Aoede,Zephyr,Autonoe`. |
| `GEMINI_TTS_STYLE_PROMPT` | Optional full prompt template; must include `{text}`. Overrides the flavor default style line. |
| `GEMINI_TTS_VOICE_ROTATE` | If `1` / `true` / `yes`, **single-speaker** jobs that are not using a character-based override cycle through **male list + female list** in order (overrides random selection below). |

### Kids flavor voices (Gemini 2.5 Flash / Pro Preview TTS)

Gemini 2.5 and 3.1 TTS share the same 30 prebuilt voices. There is no dedicated “child” voice ID — kid-friendly results come from **youthful/playful voice picks + a style prompt** (same approach as Google’s 3.1 examples with `Puck`).

**Best kids picks (by Google’s descriptors):**

| Voice | Descriptor | Why for kids |
|-------|------------|--------------|
| **Puck** | Upbeat | Strong default; matches Google’s playful-child examples |
| **Leda** | Youthful | Best female “young” default |
| **Fenrir** | Excitable | Energetic boy-ish energy |
| **Laomedeia** | Upbeat | Bright, lively female |
| **Aoede** | Breezy | Light, friendly |
| **Zephyr** / **Autonoe** | Bright | Clear, cheerful |
| **Sadachbia** | Lively | Fun variety in male pool |
| **Achird** | Friendly | Warm, approachable |

**Also usable:** Achernar (Soft), Vindemiatrix (Gentle), Sulafat (Warm), Callirrhoe / Umbriel (Easy-going).

**Usually avoid for kids clips:** Gacrux (Mature), Algenib (Gravelly), Kore / Orus / Alnilam (Firm), Charon / Rasalgethi (Informative), Sadaltager (Knowledgeable).

Kids style prompt (built-in when `--flavor kids`):

```text
Say in a young child's high-pitched, playful, clear voice: "{text}"
```

Adults keep: `Say in a clear, friendly tone for a young learner: "{text}"`.

**Gender-based voices:** For `ConvoTemplate-1` and `DialogueCompletion`, `character1` is used for **line 1**; `character2` is used for **line 2** (ConvoTemplate-1) or for the **answer** clip (DialogueCompletion). Character ids are matched (case-insensitively) to names in `characterNamePools` in `app/assets/data/config/conversation_characters.json` to decide male vs female. Each clip picks a **random** voice from the active flavor’s male/female lists accordingly. If a character id does **not** match any pool name, that clip uses a **random** voice from **both** lists combined.

**Templates without character fields** (image templates, cloze, appear/disappear, etc.): each single-speaker clip gets a **random** voice from the combined male + female lists. Pass **`--voice NAME`** to pin one voice for all such clips instead. **`GEMINI_TTS_VOICE_ROTATE=1`** uses ordered cycling through the combined list instead of random.

Gender-routed jobs ignore `--voice` / `--voice-a` / `--voice-b` for those clips; other behavior follows the rules above.

## Usage

From repo root:

```bash
python3 tools/gemini_tts/generate_level_audio.py --level-id waking-up --dry-run
python3 tools/gemini_tts/generate_level_audio.py --level-id waking-up

# Kids flavor: playful child style + youthful voices → levels/{level}/kids/*.m4a
# Prefers kids/questions.json (or adults/questions.json) when present
python3 tools/gemini_tts/generate_level_audio.py --level-id greetings --flavor kids --dry-run
python3 tools/gemini_tts/generate_level_audio.py --level-id greetings --flavor kids
```

Optional flags:

- `--flavor kids|adults` (default: `GEMINI_TTS_FLAVOR` or `adults`)
- `--workspace-root /absolute/path/to/repo`
- `--output-suffix TEXT` (inserted before `.m4a`; default empty — flavor is the folder)
- `--voice NAME` / `--voice-a NAME` / `--voice-b NAME` (defaults from male/female voice lists — see above)
- `--bitrate 64` or `--bitrate 96`
- `--overwrite` (regenerate existing files)
- `--question 3` (only one question index)

## Output Naming

Generated files go into the flavor subfolder under the level (same place Flutter loads):

| Flavor | Path |
|--------|------|
| adults | `app/assets/quiz-data/levels/{level_id}/adults/{audio_file}.m4a` |
| kids | `app/assets/quiz-data/levels/{level_id}/kids/{audio_file}.m4a` |

If `kids/` or `adults/` is missing, the script creates it. Questions are read from `{flavor}/questions.json` when present, else the level-root `questions.json`.

`{audio_file}` comes from the question’s `audio_file` / `audio_file1` / `audio_file2` stem (no `.m4a` in JSON). Keep stems unique within a flavor folder.

Override with `--output-suffix TEXT` if needed (inserted before `.m4a`; default empty).

Example:

`greetings/adults/morning_sentence.m4a`  
`greetings/kids/morning_sentence.m4a`

## Template Mapping

Supported templates:

- `ConvoTemplate-1` (multi-speaker): `questionData.line1` + `line2` as **plain English strings**
  - Legacy `{"en": "..."}` objects are still accepted (same as the Flutter parser’s `_englishLineField`).
  - Underscore blanks in either line are replaced by `answer` when available (`___` / `_____`, etc.).
  - **Split clips (agentic TTS):** if the question has **both** top-level `audio_file1` and `audio_file2`, the script generates **two** single-speaker `.m4a` files (same voice routing as DialogueCompletion). Spoken text is each line **after** blanks are filled with `answer` (not the `SpeakerA: …` combined prompt). Optional overrides: `audio_file1_text`, `audio_file2_text`. Top-level `audio_file` is **not** used for that row when the pair is present.
- `ConvoTemplate-AppearDisappear`: `words` as array or space-separated string; tokens joined with spaces for one clip
- `ConvoTemplate-ClozeSequence`: `questionData.sentence` as a **plain English string** with gaps; each gap filled from `answer` / `answers` in order. Legacy `sentence` locale maps still work (`en` used). If gaps remain, they fall back to `[long pause]` handling.
- `ConvoTemplate-DialogueCompletion`: two files — `audio_file1` → `questionData.line1` (plain English string; legacy `{"en": ...}` still accepted by the script); `audio_file2` → `answer` (blanks normalized). Both stems are required.
- `ConvoTemplate-SentenceBuilder`: joined `correct_order`
- `imageQuizTemplate-2`: `answer` only (skipped if absent)

Per-question `english_to_translate` / `local_translation` (and old `line1_translation` keys) are **not** used for TTS; only English dialogue/sentence fields above are spoken.

Skipped templates:

- `ConvoTemplate-GrammarForm` (no level audio; gameplay has no question-audio for grammar)
- `ConvoTemplate-WordPairs`
- `imageQuizTemplate-1`
- `imageQuizTemplate-3`

## Reporting

Run summary includes:

- `generated`
- `skipped_no_audio_file`
- `skipped_unsupported_template`
- `skipped_existing`
- `failed`

Use `--dry-run` first to verify mappings and filenames before real generation.
