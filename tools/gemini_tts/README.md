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
| `GEMINI_TTS_MALE_VOICES` | Male voices. First entry is the default **speaker A** for multi-speaker when `--voice-a` is not passed. If unset, defaults to `Puck`. |
| `GEMINI_TTS_FEMALE_VOICES` | Female voices. First entry is the default **speaker B** for multi-speaker when `--voice-b` is not passed. If unset, defaults to `Leda`. |
| `GEMINI_TTS_VOICE_ROTATE` | If `1` / `true` / `yes`, **single-speaker** jobs that are not using a character-based override cycle through **male list + female list** in order (overrides random selection below). |

**Gender-based voices:** For `ConvoTemplate-1` and `ConvoTemplate-DialogueCompletion`, `character1` is used for **line 1**; `character2` is used for **line 2** (ConvoTemplate-1) or for the **answer** clip (DialogueCompletion). Character ids are matched (case-insensitively) to names in `characterNamePools` in `app/assets/data/config/conversation_characters.json` to decide male vs female. Each clip picks a **random** voice from `GEMINI_TTS_MALE_VOICES` or `GEMINI_TTS_FEMALE_VOICES` accordingly. If a character id does **not** match any pool name, that clip uses a **random** voice from **both** lists combined (male + female).

**Templates without character fields** (image templates, cloze, appear/disappear, etc.): each single-speaker clip gets a **random** voice from the combined male + female lists. Pass **`--voice NAME`** to pin one voice for all such clips instead. **`GEMINI_TTS_VOICE_ROTATE=1`** uses ordered cycling through the combined list instead of random.

Gender-routed jobs ignore `--voice` / `--voice-a` / `--voice-b` for those clips; other behavior follows the rules above.

**ElevenLabs** (`--provider elevenlabs`): `ELEVENLABS_VOICE_IDS` is a comma-separated list of voice IDs; the first is used when `ELEVENLABS_VOICE_ID` is unset. `ELEVENLABS_VOICE_ROTATE=1` rotates IDs for each single-speaker clip.

## Usage

From repo root:

```bash
python3 tools/gemini_tts/generate_level_audio.py --level-id waking-up --dry-run
python3 tools/gemini_tts/generate_level_audio.py --level-id waking-up
```

Optional flags:

- `--workspace-root /absolute/path/to/repo`
- `--voice NAME` / `--voice-a NAME` / `--voice-b NAME` (defaults from male/female voice lists — see above)
- `--bitrate 64` or `--bitrate 96`
- `--overwrite` (regenerate existing files)
- `--question 3` (only one question index)

## Output Naming

Generated files follow:

`{audio_file_value}.m4a`

Example:

`morning_sentence.m4a`

Notes:

- `audio_file_value` is read from the top-level question field `audio_file`.
- Keep each `audio_file` value unique within a level folder to avoid collisions.

## Template Mapping

Supported templates:

- `ConvoTemplate-1` (multi-speaker): `line1.en` + `line2.en`
  - blanks in `line1` and `line2` are replaced by `answer` when available
- `ConvoTemplate-AppearDisappear`: whitespace-split `words` (array or string), joined with `[long pause]` between tokens (no instructional prefix)
- `ConvoTemplate-ClozeSequence`: `sentence.en` with each gap filled from `answer` / `answers` in order (full sentence read aloud); if any gap is still empty, remaining gaps fall back to `[long pause]` handling
- `ConvoTemplate-DialogueCompletion`: two files — `audio_file1` → `line1.en`; `audio_file2` → `answer` (blanks normalized like other templates). Both stems are required.
- `ConvoTemplate-SentenceBuilder`: joined `correct_order`
- `imageQuizTemplate-2`: `answer` only (skipped if absent)

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
