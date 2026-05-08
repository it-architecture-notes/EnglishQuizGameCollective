# English Quiz Game

Portrait-only mobile app (Android + iOS) for language learning quizzes. See [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) for features and scope.

## Tech stack

- **Flutter** (Dart), Android and iOS, portrait only. Details: [.cursor/context/architecture-technical-context.md](.cursor/context/architecture-technical-context.md).

## Run the app

From the `app/` directory:

```bash
cd app
flutter pub get
flutter run
```

Use a connected device or an Android/iOS emulator. Orientation is locked to portrait.

### Run in Chrome as iPhone 12 Pro size

From the `app/` directory, run Flutter web with a fixed Chrome window size that matches iPhone 12 Pro CSS resolution (`390x844`) and open DevTools automatically:

```bash
flutter run -d chrome \
  --web-port=8080 \
  --web-browser-flag="--window-size=390,844" \
  --web-browser-flag="--auto-open-devtools-for-tabs"
```

- Change `--web-port=8080` to any port you want.
- If you prefer a custom port, for example `9010`, use `--web-port=9010`.

If the iOS or Android project is incomplete (e.g. you cloned without running Flutter yet), run from `app/`:

```bash
flutter create . --platforms=android,ios
```

Then re-apply portrait lock if needed: Android `android:screenOrientation="portrait"` in `app/android/app/src/main/AndroidManifest.xml`, iOS only `UIInterfaceOrientationPortrait` in `app/ios/Runner/Info.plist`.

## Folder Structure

| Folder | Purpose |
|--------|---------|
| **context/** | Categorized context files. Fill these first—see [context/CONTEXT_INDEX.md](context/CONTEXT_INDEX.md) for fill order. |
| **commands/** | Reusable prompts for common tasks (initiate, generate tests, review). |
| **rules/** | Project rules the AI should follow. |
| **plans/** | Plan template for task breakdown. |
| **decisions/** | ADR (Architecture Decision Record) template. |
| **reference-docs/** | Place API specs, Figma links, BRDs here. Linked from project-context. |

## Quick Start

1. Copy this template into your project root.
2. Follow the fill order in [context/CONTEXT_INDEX.md](context/CONTEXT_INDEX.md).
3. Update [context/progress-context.md](context/progress-context.md) at the start of each session.

## Context Files Overview

- **project-context.md** — Overview, stakeholders, features, business rules, project status
- **architecture-technical-context.md** — Tech stack, structure, patterns, security
- **coding-standards-context.md** — Naming, formatting, patterns, anti-patterns
- **domain-glossary-context.md** — Shared vocabulary (entities, terms, acronyms)
- **progress-context.md** — Feature progress, current task, relevant files, done-in-session (update per session)
- **non-functional-requirements-context.md** — Performance, scalability, compliance
- **deployment-cicd-infrastructure-context.md** — Testing, CI/CD, deployment, secrets
