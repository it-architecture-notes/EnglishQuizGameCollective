---
name: generate-image-level-images
description: Generate or regenerate image-only quiz-level assets as coherent 2x2 sheets, then crop and resize each requested panel to an exact 512x512 PNG. Use for image quiz levels, especially color or vocabulary packs; do not use for levels whose main assets are video scenes.
---

# Generate Image-Level Images

Use this skill for image-only quiz levels under:

```text
app/assets/quiz-data/levels/{level-directory}/{flavor}/
```

The deliverable is one 512×512 PNG for every requested image stem. The generation
source is a 2×2 sheet containing up to four assets; the sheet itself is not the
quiz asset and must not be installed as one.

## Style must be decided first

Before generating, determine the style for the whole pack:

1. If the user specifies a style, use it exactly.
2. If the flavor folder already contains accepted images, inspect them and match
   their style unless the user asks for a redesign.
3. If neither exists, ask one focused style question before generating. Offer a
   concise recommendation appropriate to the flavor, for example:
   - adults: clean professional flat-vector lifestyle illustration with clear
     dark outlines, restrained shading, neutral or lightly contextual backgrounds;
   - kids: playful flat 2D cartoon clip-art with thick dark outlines and a clean
     white background.

Once chosen, keep the same outline weight, rendering method, background treatment,
lighting, palette logic, object scale, and margin language across every sheet in
the pack. Do not silently mix styles between sheets.

## Source and target scope

- Confirm the flavor (`kids` or `adults`) and read that flavor's `questions.json`.
- Treat the `imageName` values in `questions.json` as the authoritative target
  stems. Inspect the exact target files and current Git status before replacing
  anything.
- Save assets only in the matching flavor folder. Do not create new root-level
  legacy assets.
- If a JSON stem and filename disagree, report it and ask whether the content or
  filename should change; do not silently broaden the task.
- Replace only the explicitly requested stems. Do not edit `questions.json`,
  translations, or other levels as part of image generation unless requested.

## Build 2×2 sheets

- Group requested stems in batches of four and state the panel order explicitly
  in every generation prompt: top-left, top-right, bottom-left, bottom-right.
- Generate multiple sheets for more than four assets.
- If the final batch has fewer than four assets, instruct the generator to leave
  the unused panels completely blank with the same background. Never install a
  blank panel as a quiz asset.
- Use a square sheet and generate all panels in one consistent visual system.
- Put one clear primary object or scene in each used panel. Keep the subject
  large, centered, fully visible, and immediately recognizable at small size.
- Do not add labels, answer text, captions, logos, watermarks, quiz UI, or
  decorative symbols. Use neutral backgrounds unless the selected style requires
  a restrained contextual setting.

### Color-level guidance

For color vocabulary, prefer one familiar everyday object strongly dominated by
the target color, with enough neutral background to make the color obvious. Avoid
flags, abstract symbols, and adjacent panels that use nearly identical object
silhouettes (for example, two raincoats in different colors). Different object
types make the visual distinction clearer. If the user rejects a particular
object category, preserve the color and replace only that object.

## Inspect before slicing

Inspect every generated sheet before installing assets. Reject or regenerate a
sheet if any used panel has an ambiguous subject, the wrong target color, extra
objects, a cropped focal subject, inconsistent style, or an unwanted object in an
unused panel.

Do not assume the generator's output resolution. Read the actual width and height
from the generated file. Locate the two panel boundaries, account for any visible
divider lines, and crop the interior of each used panel. Do not leave white
divider strips in the resulting assets and do not cut into the subject.

## Crop, resize, and replace safely

For each used panel:

1. Crop a square interior region from the correct quadrant.
2. Resize it to exactly 512×512 using a high-quality filter.
3. Encode it as a PNG and verify its dimensions and format.
4. Inspect the final crops individually before replacement.

Before overwriting any existing asset, make an explicit recoverable copy of every
target file outside the target folder, for example under `/private/tmp/`. Use an
explicit target list—never a wildcard or broad directory. Verify the backup
exists, then copy only the approved 512×512 outputs to their exact existing
filenames.

If a target is new or untracked, preserve it just as carefully; untracked does not
mean disposable. Do not delete old files or rename stems without explicit
approval.

## Final verification

After replacement:

- Run a scoped file check and confirm every requested asset is exactly 512×512
  PNG.
- Inspect representative and, where practical, all final assets for correct
  panel-to-stem mapping, target color/object, margins, and style consistency.
- Check scoped `git status` and confirm that only the requested image files
  changed. Report any pre-existing JSON/content mismatch separately.
- Report the installed paths, the backup path, the sheet-to-panel mapping, and
  any unused panel that was intentionally discarded.

Use the built-in image-generation tool by default. Use another generation path
only when the user explicitly requests it. This skill covers bitmap generation
and deterministic slicing/replacement; it does not cover video generation,
audio extraction, or quiz-template code changes.
