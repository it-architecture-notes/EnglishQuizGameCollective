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

## Asset and data layout

- **Image assets** live under `assets/images/`:
  - `backgrounds/` — One subfolder per bucket: `phone_tall/`, `phone_wide/`, `tablet_43/`, `tablet_1610/`. Each contains the background image(s) for that aspect-ratio group.
  - `buttons/` — UI buttons (optional resolution subfolders later).
  - `characters/` — Character art (narrative/achievements).
  - `avatars/` — User avatar images.
  - `quiz/` — Images for quiz questions (optional resolution subfolders later).

- **JSON data** lives under `assets/data/`:
  - `state/` — App/play state (e.g. progress, unlocked levels). Mutable; read/written at runtime.
  - `config/` — Configuration and flow (e.g. level definitions, flow control). Loaded at startup; typically read-only.
  - `settings/` — App settings (e.g. sound, language). Loaded at startup; may be written when user changes settings.

All asset paths are registered in `pubspec.yaml` under `flutter: assets:`.
