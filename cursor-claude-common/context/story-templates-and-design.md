# Story templates and overlay design

Reference for **main-level story pages**: full-screen narrative overlays on the level map (not part of `ImageQuizScreen`).

- **Implementation:** `app/lib/screens/story/story_overlay_screen.dart`, `story_templates/story_template_a.dart`, `story_templates/story_template_c.dart`
- **Models / load:** `app/lib/models/story_config.dart`, `app/lib/services/story_config_loader.dart`
- **Quiz templates** (questions) are documented in **`page-designs-and-templates.md`**.

---

## Story content shape

All copy lives in **`story_text`**: a locale map `{ "en": "...", "fr": "...", ... }` on each object in `main_levels[].story_sequences[]`.

There are **no** `page_text_list_for_template`, `page_image_list_for_template`, or `page_animation_list_for_template` fields.

**Template 1 only:** optional **`character_image`** — Flutter asset path (e.g. `assets/images/story/foo.png`) for the bottom-left character sprite. If omitted or invalid, a placeholder is used. The **scene** behind the bubble remains a **placeholder** (no JSON field yet).

---

## Template registry (`app/assets/data/story/story-templates.json`)

| `template_id` | `layout` | Widget | Role |
|---------------|----------|--------|------|
| **1** | `character_dialog_scene` | `StoryTemplateA` | Stack: **scene** placeholder, **character** = `character_image` or placeholder, **speech bubble** = `localizedStoryText` from `story_text`. |
| **4** | `scene_story_text` | `StoryTemplateC` | Placeholder “scene” block; **primary** line = `story_text["en"]`; if app language ≠ `en`, **italic** second line = `story_text[languageCode]`. |

Unknown `layout` falls through to **template A**.

Authoring hints (`requires_text` / `requires_images` / `requires_animation`) are **not** enforced at runtime.

---

## Main level JSON (`game-main-level-stories.json`)

Each **main level** has:

- `main_level_id`, optional `story_icon_asset_path`, `story_sequences[]`.

Each **story page** has:

- `event_id` — progress key with `main_level_id`
- `page_template_id` — **1** or **4**
- `trigger` — `{ "type": "before_level" | "after_level", "level": <int> }`  
  - `level` is 1-based within that main level; **`0`** resolves to the **last** regular sub-level in the flow (`StoryTriggerService`).
- `story_text` — locale map for all visible copy
- `character_image` — optional; **template 1** only, pub asset path for the bottom-left character

**Completion:** `StoryTriggerService.pagesReadyToMarkCompleted` marks an event completable when the sub-level at the **resolved trigger level** has **≥ 1 star**. `after_level` also sets the overlay’s **congratulations** header (`isFinalPage`).

---

## Summaries (two sentences each)

- **1 — `character_dialog_scene`:** A fixed-height comic-style stack with a gray scene placeholder, an optional **character** image from `character_image`, otherwise a gray placeholder, and a white speech bubble; the bubble shows the current app language from `story_text` (fallback `en`).
- **4 — `scene_story_text`:** A centered column with a placeholder image block, then English from `story_text["en"]`, then an italic translated line when the player’s language is not English.

---

## Overlay chrome

Warm background `#F5F0E8`, scrollable body, full-width **Continue** (pops route). **Final** (`after_level`) pages can show an animated congratulations title above the template.

---

## Related paths

| | |
|--|--|
| Overlay | `app/lib/screens/story/story_overlay_screen.dart` |
| Trigger / completion | `app/lib/services/story_trigger_service.dart` |
| Progress | `app/lib/services/story_progress_service.dart` |
