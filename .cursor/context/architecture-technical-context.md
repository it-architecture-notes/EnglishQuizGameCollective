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
