## Tech Stack

- **Framework:** Flutter (Dart)
- **State management:** Riverpod (flutter_riverpod)
- **Platforms:** Android (Kotlin), iOS (Swift), portrait only
- **Min versions:** Android 21+ (API 21), iOS 12+
- **Data:** JSON files for state, configuration, and settings (see Asset and data layout below)

## Orientation

- App is portrait-only. Locked via:
  - Android: `android:screenOrientation="portrait"` in `AndroidManifest.xml`
  - iOS: portrait-only in `Info.plist` / Xcode project

## Resolution strategy

- Four aspect-ratio buckets for resolution-specific assets (e.g. backgrounds):

| Bucket ID   | Target ratio | Use case     |
| ----------- | ------------ | ------------ |
| phone_tall  | 19.5:9       | Tall phones  |
| phone_wide  | 16:9         | Wider phones |
| tablet_43   | 4:3          | iPad-style   |
| tablet_1610 | 16:10        | Android tabs |

- A resolution service (e.g. `lib/services/resolution_service.dart`) derives the bucket from logical size (width/height) and optionally short-edge length. Backgrounds are loaded from the folder for the current bucket; one background image per bucket.

## Asset Layout

app/assets/
├── images/                          ← ALL image assets
│   ├── backgrounds/
│   │   ├── phone_tall/              ← background.png (placeholder: steel blue)
│   │   ├── phone_wide/              ← background.png (placeholder: sea green)
│   │   ├── tablet_43/               ← background.png (placeholder: orange)
│   │   └── tablet_1610/             ← background.png (placeholder: purple)
│   ├── buttons/
│   ├── characters/
│   ├── avatars/
│   └── level-icons/                 ← [iconImageName].png per sub-level card
├── data/                            ← ALL JSON data
│   ├── state/
│   ├── config/                      ← quiz_config.json
│   ├── settings/
│   └── flow/                        ← [quizType]-quiz-flow.json + [quizType]-flow-main-levels.json
└── quiz-data/                       ← quiz content, split by type
    ├── image-quiz/
    │   └── quiz-images/             ← [images] one subfolder per level: {iconImageName}-{levelNumber}/
    │       └── airport-1/
    ├── vocabulary-quiz/             ← [json] one file per level: {iconImageName}-{levelNumber}.json
    │   ├── greetings-1.json
    │   └── ...
    └── grammar-quiz/                ← [json] one file per level (empty, future)

All asset paths are registered in `pubspec.yaml` under `flutter: assets:`.

## VideoConversation audio clips: extracted from the source video, not TTS

For the `VideoConversation` template (e.g. `greetings/adults-intermediate`), each question's `audio_file1`
(setup) / `audio_file2` (confirm) `.m4a` clips are **not** Gemini-TTS output — they are sliced
directly out of the level's own video file's embedded audio track (e.g. `greetings1.mp4`, which
has its own real AAC audio stream), at that question's own `start_at`/`pause_at`/`answer_until`
timestamps from `questions.json`. This was confirmed on 2026-08-12 by re-extracting the same time
range from the source `.mp4` with `ffmpeg` and comparing silence timing against the shipped
`.m4a` — they matched to the millisecond.

There is **no committed script** for this in `tools/` — `tools/gemini_tts/generate_level_audio.py`
has no `VideoConversation` case at all, and `tools/gather_adults_mixed_audio_texts.py` only dumps
text, not audio. The repo root has a `.venv` (untracked) with `pydub` + `google` (Gemini SDK) +
`deep_translator` installed, left over from whichever prior session built these clips — that's the
toolset to reach for, but the extraction itself doesn't need pydub; a plain `ffmpeg` cut works and
is what was used for the fix below. No script currently formalizes this per-level, so it's a
manual per-question `ffmpeg` step until one exists.

**Manual re-cut recipe** (used to fix `greetings/adults-intermediate` question 1, which had a
boundary artifact — see below; folder was `greetings/adults/` at the time of the original fix,
renamed to `adults-intermediate/` afterward):

```bash
SRC=app/assets/quiz-data/levels/greetings/adults-intermediate/greetings1.mp4
ffmpeg -y -i "$SRC" -vn -ss <start_at> -to <boundary> -c:a aac -b:a 132k -ar 44100 -ac 2 <out>-setup.m4a
ffmpeg -y -i "$SRC" -vn -ss <boundary> -to <answer_until> -c:a aac -b:a 132k -ar 44100 -ac 2 <out>-confirm.m4a
```

`<boundary>` starts as `pause_at` from `questions.json`, but the actual spoken line in the video
doesn't always end exactly at `pause_at` — the speaker's voice can trail a bit past it. Diagnose a
suspect clip with:

```bash
ffmpeg -i clip.m4a -af silencedetect=noise=-30dB:d=0.03 -f null - 2>&1 | grep -i silence
```

A clean clip is silent starting at `t=0`; if a confirm clip instead shows a short sound burst
*before* the first silence gap (e.g. `silence_start: 0.086`, not `0`), that's the previous
speaker's trailing audio bleeding across the cut — nudge `<boundary>` later (past where that burst
ends) and re-cut both files from the same source with the new boundary, which makes setup longer
and confirm shorter by the same amount. `greetings1-q1-setup.m4a`/`-confirm.m4a` were fixed this
way: boundary moved from `0.9s` to `0.99s` (setup 0.900s→0.990s, confirm 1.300s→1.210s), which
fully cleared an ~86ms artifact. Note `pause_at` in `questions.json` still says `00:00.90` for that
question — the video will still visually freeze there while the (now slightly longer) setup audio
finishes ~90ms after the freeze; only update `pause_at` too if tighter audio/frame sync matters.
