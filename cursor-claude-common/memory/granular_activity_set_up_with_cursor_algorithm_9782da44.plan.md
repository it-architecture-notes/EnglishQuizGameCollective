---
name: Granular Activity Set Up with Cursor Algorithm
overview: Automate the creation of granular activity level folders and questions.json using an image-matching algorithm.
todos:
  - id: keywords-definition
    content: Create keyword mapping for activities in Level 1 and 2.
    status: pending
  - id: script-creation
    content: Write tools/cursor_generate_granular_activities.py script.
    status: pending
  - id: generate-content
    content: Execute script to create folders and questions.json for Level 1 & 2.
    status: pending
  - id: update-configs
    content: Update game-flow.json and pubspec.yaml.
    status: pending
  - id: verification
    content: Validate and verify the results.
    status: pending
isProject: false
---

# Granular Activity Set Up with Cursor Algorithm

This plan outlines the automation for Phase-1 of creating granular activity levels for the English Quiz Game.

## 1. Image Discovery & Mapping

- Scan `app/assets/quiz-data/_image-pool/` for all available `.png` and `.jpg` images.
- Parse `cursor-claude-common/references/activities/activities.txt` for the sequence of activities (starting from `waking-up`).
- Define a keyword mapping for each activity to ensure high-relevance image matching (e.g., `waking-up` -> `bed`, `alarm`, `pillow`, `pajamas`, `morning`).

## 2. Activity Folder Automation (Python Script)

Create a Python script `tools/cursor_generate_granular_activities.py` that will:

- Iterate through the list of activities.
- For each activity (e.g., `brushing-teeth`):
  - Ensure the folder `app/assets/quiz-data/levels/brushing-teeth/` exists.
  - Select up to 6 images from `_image-pool/` that match the activity name or keywords.
  - Copy selected images into the activity folder (if not already present).
  - Generate a `questions.json` file:
    - Each image becomes an `imageQuizTemplate-1` question.
    - `wrongAnswers` are randomly picked from the other 5 images in the same folder.
  - Record the activity name and level info for later flow update.

## 3. Game Flow Update

- Update `app/assets/data/flow/game-flow.json` to reflect the new granular activities.
- Group activities into main levels (5 activities per main level).
- Update `app/pubspec.yaml` to register any new activity folders under `flutter: assets:`.

## 4. Verification

- Validate `questions.json` structure.
- Run `flutter analyze` to ensure no issues with asset registration.
- Verify that 1:1 is indeed `waking-up`.

---

**Citations:**

- Activity Source: `cursor-claude-common/references/activities/activities.txt`
- Image Pool: `app/assets/quiz-data/_image-pool/`
- Question Structure: `app/assets/quiz-data/levels/morning-routine/questions.json`
- Game Flow: `app/assets/data/flow/game-flow.json`

