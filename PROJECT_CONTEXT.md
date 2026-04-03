# Project Context - What this app does
This is a portrait-orientation Flutter mobile app for Android and iOS. It is a language-learning quiz game with three main quiz categories:

**Image Quiz:** Users identify the correct word for a shown image.

**Vocabulary Quiz:** Users complete conversation-based cloze questions.

**Grammar Quiz:** Users solve mixed grammar-focused multiple-choice question types.

Users progress through levels and earn stars and diamonds. The app includes profile/avatar management, achievements, friends (animal unlocks using diamonds), and settings.

## Current Implementation Snapshot
- Progression-based levels are implemented (unlock by performance, replay support, saved best stars/diamonds).
- All three quiz types are implemented and wired to shared reward/progress persistence.
- Profile panel is implemented with editable name/avatar and lifetime progress stats.
- Achievements are config-driven and shown in a dedicated panel with lock/progress states.
- Friends panel is implemented with diamond-based unlock flow and persistent state.
- Settings panel is implemented with language, music, and sound/FX toggles, including persistence.

Configuration and game content are driven by local JSON assets (`questions.json` per level under `assets/quiz-data/levels/{iconImageName}/`, including image rows and templates such as `ConvoTemplate-1` and `ConvoTemplate-2`), and user state is persisted locally on device storage. The app supports multiple phone/tablet aspect-ratio buckets with resolution-aware asset loading.