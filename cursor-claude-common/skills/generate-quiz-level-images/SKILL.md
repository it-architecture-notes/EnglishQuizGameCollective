---
name: generate-quiz-level-images
description: >-
  Generate consistent cartoon quiz-level PNG assets (1:1, white background, flat
  clip-art style) for English Quiz Game Collective. Use when creating or
  regenerating level images, imageQuizTemplate assets, optional convo/interactive
  hero images, or when the user asks for quiz icons / cartoon level art.
disable-model-invocation: true
---

# Generate Quiz Level Images

Use this skill whenever creating or regenerating **quiz level** images under
`app/assets/quiz-data/levels/{directoryName}/`.

Goal: **visual structure stays consistent across levels**. Scene *content* changes
per question; style, framing, coloring rules, and background do not.

Do **not** use this skill for story-overlay illustrations (`app/assets/images/story/`)
unless the user explicitly asks — those follow a different watercolor storybook look.

## When to apply

- New `imageQuizTemplate-1` / `-2` correct-image assets
- Optional hero images for ClozeSequence, ConvoTemplate-1, DialogueCompletion,
  AppearDisappear, SentenceBuilder, GrammarForm (`imageName` / `image_file_name`)
- Regenerating a level’s icons for a brighter / consistent pack

## Visual structure (required)

| Rule | Spec |
|------|------|
| Aspect | **1:1** square (`aspect_ratio: "1:1"`) |
| Background | **Solid pure white `#FFFFFF`** across the whole frame — never black, never gray, never gradient, never transparent checker |
| Style | Flat **2D cartoon / clip-art** mobile-game icon |
| Outlines | **Thick, uniform dark (near-black) outlines** on every shape |
| Fills | Flat solid colors; at most **one soft two-tone shade** for depth — no photorealism, no heavy gradients, no texture noise |
| Detail | Low–medium; readable at ~72–256 px |
| Composition | Single clear subject (or one tight scene), **centered**, comfortable white margin |
| Text / UI | **No** readable text, logos, speech bubbles, buttons, watermarks, or UI chrome |
| Noise | **No** dots, grain, sparkles, or compression artifacts in the prompt or output |
| Characters | Rounded simplified faces; **dot eyes**; soft proportions; **hair and dark details stay dark** (never wash to white) |
| Palette | Bright, kid-friendly, saturated but not neon; keep a cohesive set within a level |

### Background (critical)

Always generate **white background from the start**.

**Do not** post-process black backgrounds to white (flood-fill / color replace). That
destroys outlines, hair, shadows, and small dark details.

If an older asset still has a black background, **regenerate** it with this skill
instead of converting.

## Prompt boilerplate

Put **content** (what the picture shows) in the middle. Keep the **structure block**
the same every time:

```text
Flat 2D cartoon clip-art mobile game icon, thick uniform dark outlines, simple
shapes, flat solid colors with at most one soft two-tone shade, SOLID PURE WHITE
BACKGROUND (#FFFFFF) filling the entire square — never black, never gray, never
transparent. Kid-friendly English learning icon, single centered subject with
comfortable white margin, readable at small size. No text, no logos, no UI, no
speech bubbles, no dots, no grain, no noise. Keep dark hair and dark details dark.
[CONTENT: one clear scene or object for this question]
```

Generate with Cursor `GenerateImage`:

- `aspect_ratio`: `"1:1"`
- `filename`: `{stem}.png` matching `imageName` / asset basename (kebab-case)

## Delivery workflow

1. Confirm target level folder: `app/assets/quiz-data/levels/{directoryName}/`
2. List stems from `questions.json` (`imageName`, `wrongAnswers` for template-2 tiles,
   optional convo `imageName` / `image_file_name`)
3. Generate each missing/replaced stem with the boilerplate + content
4. Copy into the level folder (overwrite only when regenerating that stem)
5. Resize to **512×512** (e.g. `sips -z 512 512`) — keep PNG
6. Spot-check: corner pixels near white; dark hair/outlines still dark
7. Wire JSON if needed (`imageName` / `image_file_name`)
8. Tell the user to **full restart / hard refresh** so Flutter web drops cached assets

Do not place archive copies inside the level asset directory under a name Flutter
might pick up as quiz images. Prefer a sibling archive outside the level folder,
or a clearly non-asset path the user manages.

## Template-2 note

`imageQuizTemplate-2` needs **four** image stems in the same folder (correct + three
wrong). Generate all four with the same structure rules so the 2×2 grid matches.

## Anti-patterns

- Black or dark studio backgrounds
- Photoreal / 3D / anime-heavy styling
- Post-process “make background white” scripts
- Tiny unreadable scenes or busy multi-focus collages
- Text baked into the artwork
- Mixing this white clip-art pack with the story watercolor style in the same level folder
