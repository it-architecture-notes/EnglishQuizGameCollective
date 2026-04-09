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

Or copy `.env.example` to `.env` and set the key.

## Usage

From repo root:

```bash
python3 tools/gemini_tts/generate_level_audio.py --level-id waking-up --dry-run
python3 tools/gemini_tts/generate_level_audio.py --level-id waking-up
```

Optional flags:

- `--workspace-root /absolute/path/to/repo`
- `--voice Puck`
- `--voice-a Puck --voice-b Leda` (for ConvoTemplate-1 multi-speaker)
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
  - `line1` blanks (`_____`) are replaced by `answer` when available
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

## Reporting

Run summary includes:

- `generated`
- `skipped_no_audio_file`
- `skipped_unsupported_template`
- `skipped_existing`
- `failed`

Use `--dry-run` first to verify mappings and filenames before real generation.
