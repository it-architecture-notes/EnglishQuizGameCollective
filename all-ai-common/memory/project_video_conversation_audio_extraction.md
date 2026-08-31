---
name: project-video-conversation-audio-extraction
description: "VideoConversation template audio clips are cut from the source video's own audio track via ffmpeg, not TTS-generated — how to diagnose and re-cut a boundary artifact"
metadata: 
  node_type: memory
  type: project
  originSessionId: e47ca0ed-4b16-4d6f-8e6d-da76112aded6
  modified: 2026-08-13T02:01:31.127Z
---

`VideoConversation` question clips (`audio_file1` setup / `audio_file2` confirm, e.g. in
`greetings/adults/questions.json`) are sliced directly out of the level's video file's own AAC
audio track (e.g. `greetings1.mp4`) at that question's `start_at`/`pause_at`/`answer_until`
timestamps — confirmed 2026-08-12 by re-extracting the same range from the `.mp4` and matching
silence timing to the shipped `.m4a` down to the millisecond. They are **not** Gemini TTS output,
even though the level also has TTS-generated clips for other templates.

No committed script does this extraction (`tools/gemini_tts/generate_level_audio.py` has no
`VideoConversation` case). The repo root has an untracked `.venv` with `pydub`+`google`+
`deep_translator` left over from whichever prior session built these — a signal of the intended
toolset, but a plain `ffmpeg -ss <start> -to <end>` cut works fine and is what's documented.

Full recipe, the diagnostic (`ffmpeg -af silencedetect`) for spotting a boundary artifact (speaker's
voice trailing past `pause_at` into the next clip), and the worked example (`greetings1-q1-setup`/
`-confirm.m4a`, boundary moved 0.9s→0.99s) are written up in full in
`all-ai-common/context/architecture-technical-context.md` (bottom section, "VideoConversation
audio clips: extracted from the source video, not TTS").

**Why:** the user asked how these files were made; there was no repo tooling or memory of it, so it
had to be reverse-engineered by comparing extracted-vs-shipped audio.
**How to apply:** if a `VideoConversation` clip sounds truncated/has a stray blip at the start,
suspect a `pause_at`/`answer_until` boundary that doesn't land in real silence in the source video —
don't assume it's a runtime playback race or a TTS artifact. Re-derive via the recipe above rather
than regenerating through the TTS tool (which can't produce these at all).
