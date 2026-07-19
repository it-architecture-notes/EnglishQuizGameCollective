# Active Progress Context

## Active Issue

Description: Adding a translations page to the end of the level before final screen.

Use Cases: 
    - A translations page will be added to the end of each level if a translations.json file exists in the level folder.
    - In the page there will be a table and in the table there will be the english word and the local language translation of it in each row.
    - There will be a next button, and when pressed it goes to the final page.
    - If the table is too long a scroll will be provided so that user can scroll up and down.
    - The title of the page will be "Words Used in This Level" in it's local language. Localization will be done similar to other pages.
    - When a level is completed with stars of x>=1 a small button will appear beside it called "words". The button will be placed according to this logic on the right or left:
        - If space between the icon and left of screen is bigger it will appear on the right vice versa
    - When this button is pressed the same screen will appear with fade pop up and will be closed with an ok button. It will be exactly the same translations page appearing at the end of level.

FAQ Answers:
- If local language is english there is no need for the page, it can be skipped.
- It will not appear after reminder levels.

---

## Story overlays — configuration requirements (current)

Short spec for **`game-main-level-stories.json`** and **`story-templates.json`** after the latest simplification:

- **Single text source:** All visible copy for every story beat is in **`story_text`** only (locale map: `"en"`, `"fr"`, …). There is no `page_text_list_for_template`, `page_image_list_for_template`, or `page_animation_list_for_template`.
- **Templates:** Only **`page_template_id` 1** and **4** are valid. Registry in `story-templates.json` defines **`character_dialog_scene`** (1) and **`scene_story_text`** (4). Template **B** (`scene_animation_dialogues`) and **animation-only** (3) are removed from code and config.
- **Template 1 (`StoryTemplateA`):** Speech bubble shows **`localizedStoryText`** (current app language, fallback `en`). Optional JSON **`character_image`** (asset path) supplies the bottom-left sprite; scene stays a placeholder unless extended later.
- **Template 4 (`StoryTemplateC`):** Primary line = **`story_text["en"]`**; if the app language is not English, a second **italic** line uses **`story_text[languageCode]`**. Scene block is a **placeholder** only.
- **Completion:** Story **`event_id`** is marked complete when the sub-level at the **resolved trigger level** has **≥ 1 star** (no `covered_levels_number`; multi-level coverage was removed).
- **Trigger:** `trigger.type` is `before_level` or `after_level`; `trigger.level` is the flow **`title`** of the target level (e.g. `"Greetings"`, `"Reminder 2"`), or **`""`** = last regular sub-level in the flow. `after_level` uses the overlay “congratulations” header behavior.
- **Docs:** Full detail lives in **`cursor-claude-common/context/story-templates-and-design.md`**.

---

## Additional fixes on this branch (not part of Issue-27)

- **ClozeSequence multi-blank wrong-answer highlight** (`cloze_sequence_quiz_body.dart`): When a wrong tile is tapped, all remaining expected tiles (one per remaining blank) are now highlighted with their correct position number badge. Previously only the first blank's expected tile was shown.
- **DialogueCompletion button lock during line1 audio** (`dialogue_completion_quiz_body.dart`): Answer buttons are now disabled while `_audio1Playing` is true, in addition to `_audio2Playing`. Prevents tapping an answer while the question line is still playing.