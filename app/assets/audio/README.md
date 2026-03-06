# Audio assets for Issue-10

Add these files under `app/assets/audio/` (paths are referenced in code). The `assets/audio/` folder is already registered in `pubspec.yaml`.

- **quiz_music.mp3** – Background music during quiz play (short loop for demo).
- **click.mp3** – Button click SFX (short clip).
- **correct.mp3** – Sound for correct answer.
- **wrong.mp3** – Sound for wrong answer.

If any file is missing, the app will no-op on play (no crash). For quick testing you can use the same clip for all SFX (e.g. copy click.mp3 to correct.mp3 and wrong.mp3) until distinct sounds are available.
