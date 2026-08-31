---
name: project-app-flavor-and-tutorial
description: Kids/adults app-flavor split and the new tutorial overlay system added since the last memory review (not yet reflected in active-progress-context.md)
metadata: 
  node_type: memory
  type: project
  originSessionId: e47ca0ed-4b16-4d6f-8e6d-da76112aded6
  modified: 2026-08-11T23:18:18.881Z
---

Discovered on a context review (2026-08-11) by reading recent commits/files directly — this architecture predates the current branch but was missing from memory and from `all-ai-common/context/active-progress-context.md`, which still only shows the older Issue-27 translations-page spec as "Active Issue."

**Kids vs. adults flavor** (`app/lib/app_flavor.dart`): `AppConfig.flavor` is an `AppFlavor.adults`/`AppFlavor.kids` enum set once at startup from `--dart-define=FLAVOR=kids` (default `adults`). `AppConfig.isKids`, `AppConfig.storiesEnabled` (stories are kids-only), and `AppConfig.flavorDir` (`'kids'`/`'adults'`, used to build subfolder paths for music/FX, avatars, achievements) are the read surface. Referenced from `app_theme.dart`, `levels_screen.dart`, `home_screen.dart`, `level_config_loader.dart`, `achievement_config_loader.dart`, `quiz_flow_loader.dart`, `image_asset_resolver.dart`, `image_quiz_level_loader.dart`. There are parallel flow/config files per flavor: `app/assets/data/flow/game-flow.json` + `game-flow-main-levels.json` (adults) vs. `game-flow-kids.json` + `game-flow-main-levels-kids.json` (kids), and `achievements.json` vs `achievements-kids.json`. Quiz content under `app/assets/quiz-data/levels/{activity}/` is now split into `adults/` and `kids/` subfolders per the current git status (e.g. `greetings/adults/questions.json`) — the flat `{activity}/questions.json` layout described in CLAUDE.md's Asset Layout section is stale.

**Tutorial overlay system** (new, not in any archived issue yet): `app/lib/services/tutorial_service.dart` persists per-tutorial-id completion flags via SharedPreferences (`isCompleted`/`markCompleted`/dev-only `reset`). Widgets live under `app/lib/widgets/tutorial/`: `tutorial_controller.dart`, `tutorial_overlay.dart`, `tutorial_target.dart`, `tutorial_message.dart`, `tutorial_hand.dart` (a pointing-glove hand graphic). Assets in `app/assets/images/tutorial/` (`pointing-glove-yellow.png`, `speech-bubble-option-1/2/3.png`).

**Policy change (commit 8e17249, 2026-08-02):** image-quiz templates (`imageQuizTemplate-1`/`-2`) are no longer used in mixed (vocab+grammar) levels — rows were removed from `greetings` and `basic-sentences` and redistributed to dedicated image-only levels (e.g. new `bedroom-bathroom-items` level combining rows from `waking-up`, `in-the-bedroom`, `in-the-bathroom`).

**How to apply:** Before editing flow/config/quiz-content JSON or asset paths, check whether the file is flavor-split (adults/kids) rather than assuming the flat CLAUDE.md-documented layout. When working on onboarding/first-run UX, check `tutorial_service.dart` and `widgets/tutorial/` first — a tutorial framework already exists. `active-progress-context.md` and `architecture-technical-context.md` in `all-ai-common/context/` are behind actual repo state on this (kids flavor, tutorial system, image-quiz-in-mixed-levels policy aren't documented there) — prefer reading code/git log over those docs for current asset-layout facts, and flag to the user that those context docs could use an update pass.
