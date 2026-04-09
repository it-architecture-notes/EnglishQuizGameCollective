# ElevenLabs TTS Level Audio Generator

Development-time utility to generate quiz audio assets with ElevenLabs.

## Scope

- Reads one level's `questions.json`
- Generates `.m4a` only for questions with top-level `audio_file`
- Writes files into the same level folder under `app/assets/quiz-data/levels/{level_id}/`
- Does **not** modify `questions.json`

## Requirements

- Python 3.10+
- `ffmpeg` installed and available on PATH
- ElevenLabs API key (`ELEVENLABS_API_KEY`)

Install Python deps:

```bash
pip install -r tools/eleven_labs_tts/requirements.txt
```

Set environment:

```bash
export ELEVENLABS_API_KEY="your_key_here"
export ELEVENLABS_VOICE_ID="your_default_voice_id"
```

Or copy `.env.example` to `.env`.

## Usage

From repo root:

```bash
python3 tools/eleven_labs_tts/generate_level_audio.py --level-id waking-up --dry-run
python3 tools/eleven_labs_tts/generate_level_audio.py --level-id waking-up
```

Optional flags:

- `--voice-id` (single-speaker voice id)
- `--voice-a-id` / `--voice-b-id` (ConvoTemplate-1)
- `--model-id eleven_flash_v2_5`
- `--bitrate 64|96`
- `--question N`
- `--overwrite`
- `--output-suffix _elevenlabs` (default)

## Output Naming

Default output filename:

`{audio_file_value}_elevenlabs.m4a`

You can change/remove the suffix with `--output-suffix`.

## Template Mapping

Supported templates:

- `ConvoTemplate-1` (two calls stitched with small pause):
  - `line1.en` + `line2.en`
  - blanks in `line1` replaced by `answer` when available
- `ConvoTemplate-AppearDisappear`: joined `words` (supports array or space-separated string)
- `ConvoTemplate-Simon`: joined `words`
- `ConvoTemplate-ClozeSequence`: `sentence.en` with blanks spoken as `Blank`, with a short pause before/after
- `ConvoTemplate-GrammarForm`: same as cloze sequence
- `ConvoTemplate-DialogueCompletion`: `line1.en` only
- `ConvoTemplate-SentenceBuilder`: joined `correct_order`
- `imageQuizTemplate-2`: `answer` only (skipped if absent)

Skipped templates:

- `ConvoTemplate-WordPairs`
- `imageQuizTemplate-1`
- `imageQuizTemplate-3`
- `imageQuizTemplate-SpotDifference`

## Compare Gemini vs ElevenLabs

Recommended flow:

1. Generate Gemini audio first (`tools/gemini_tts/...`) -> `audio_file.m4a`
2. Generate ElevenLabs with default suffix -> `audio_file_elevenlabs.m4a`
3. To test ElevenLabs in-game for one question, temporarily change that question's
   `audio_file` value to include `_elevenlabs` (so Flutter resolves `..._elevenlabs.m4a`).

