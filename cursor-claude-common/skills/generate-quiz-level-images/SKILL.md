---
name: generate-quiz-level-images
description: >-
  Generate consistent quiz-level PNG assets (1:1) for English Quiz Game
  Collective kids and adults flavors. Kids art is playful cartoon clip-art on
  white; adults art is richer flat lifestyle illustration (professional scenes,
  time-of-day atmosphere). Use when creating or regenerating level images,
  imageQuizTemplate assets, optional convo/interactive hero images, or when the
  user asks for quiz icons / cartoon level art.
disable-model-invocation: true
---

# Generate Quiz Level Images

Use this skill whenever creating or regenerating **quiz level** images under
`app/assets/quiz-data/levels/{directoryName}/{flavor}/`.

Goal: **one coherent pack per flavor folder**. Kids and adults are **different
art systems** (not the same icon with a calmer palette). Scene content changes
per question; within a flavor, style stays fixed.

Do **not** use this skill for story-overlay illustrations (`app/assets/images/story/`)
unless the user explicitly asks — those follow a different watercolor storybook look.

## Flavor first (required)

Every level has **two** image sets — never a shared root pool:

```
app/assets/quiz-data/levels/{directoryName}/
  kids/{stem}.png
  adults/{stem}.png
```

| Flavor | Folder | Style |
|--------|--------|--------|
| **kids** | `{directoryName}/kids/` | Playful cartoon clip-art on **white** |
| **adults** | `{directoryName}/adults/` | Richer **flat lifestyle illustration** (adult scenes, atmosphere) |

- Always confirm which flavor(s) to generate (`kids`, `adults`, or both).
- Read stems from that flavor’s `questions.json`.
- Save PNGs **only** into the matching flavor subfolder — not the level root.
- Root files are legacy only; do not author new root quiz images.

## When to apply

- New `imageQuizTemplate-1` / `-2` correct-image assets
- Optional hero images for ClozeSequence, ConvoTemplate-1, DialogueCompletion,
  AppearDisappear, SentenceBuilder, GrammarForm (`imageName` / `image_file_name`)
- Regenerating a level’s icons for a consistent pack
- Producing a kids set and/or adults set for the same stems

## Universal rules (both flavors)

| Rule | Spec |
|------|------|
| Aspect | **1:1** square (`aspect_ratio: "1:1"`) |
| Cropping | Keep the **full primary subject / scene** inside the canvas — no accidental cropped heads, cut-off limbs, or clipped focal objects |
| Recognition | The time, place, object, or action should be **immediately recognizable** at small size |
| UI chrome | **No** logos, speech bubbles, buttons, watermarks, or quiz UI |
| Noise | **No** compression artifacts, random grain, or glitter noise |
| Dark details | Hair, outlines, and dark accents **stay dark** (never wash to white) |
| Camera | Prefer straight-on **eye-level**; avoid fisheye, extreme close-ups, bird’s-eye, or Dutch tilt unless content requires it |

### Text in images

Same for kids and adults.

**Never bake in** (even when used as authoring context):
- Question / prompt text, answers, distractors, dialogue lines
- Quiz or learning copy from `questions.json`
- Full sentences, captions, or labels meant to teach the word (e.g. do **not**
  stamp `GOOD MORNING` / `NIGHT` on the artwork)

**Environmental signage — optional, rare:**
- Default: **no readable text**
- Allow a short real-world sign **only when the scene is ambiguous without it**
  (e.g. `BUS STOP`, `EXIT`, a gate number)
- Short, simple, sign-like (often all-caps) — not a sentence
- Do **not** put the quiz answer / target phrase on the sign just to teach it

In `[CONTENT: …]`, describe the scene visually. Mention signage only when needed.
Never instruct the model to render question or answer text.

### Asset consistency (per flavor folder)

Within the same level’s `kids/` or `adults/` pack, images must look like they were
drawn by **the same artist**: consistent outline weight, saturation, shading
style, proportions, perspective, and rendering quality across all stems.

### Recurring characters

When a level names the same people across questions (e.g. Beth, Leo):
- Keep **hairstyle, clothing colors, age, and face design** consistent across
  stems **within that flavor folder**
- Kids and adults packs may differ from each other; do not force cross-flavor
  character matching unless the user asks

### No accidental character reuse (required)

For **unnamed** one-off figures (no shared character name across questions),
**do not** reuse the same person across different stems in the same flavor pack.

Each stem’s people must look like **different individuals**: change ethnicity /
skin tone, hair (color, length, style), age band, facial features, and
**outfit colors / clothing type**. Do not regenerate a near-clone of a prior
stem’s cast (same blazer + same haircut + same companion pair is a fail).

Before generating, skim already-accepted PNGs in that flavor folder and pick
contrasting casting so the new image does not echo an existing face/outfit
combo. Named recurring characters are the **only** intentional exception.

### Character diversity (required across a pack)

Unless continuity requires otherwise (named recurring characters), vary
**skin tones, hair types, ethnic backgrounds, and ages** across unrelated
characters so packs don’t default to one look.

**Adults — age:** when people appear, mix clearly mature adults across roughly
**~20–60** (young adult, mid-career, older) within a level pack. Do **not**
default every face to the 25–35 band. Exception: content that implies another
age (e.g. “I am 10 years old”) may show a child with an adult.

**Adults — facial hair:** prefer **clean-shaven or light stubble**. Full beards
only occasionally (about **≤1 in 4** adult men in a pack), never default every
male to a beard.

### Casting depicted people (`genders` field — required signal)

Most conversational rows no longer carry `character1`/`character2` names in
`questionData` (they're resolved to a random locale-appropriate display name
at runtime, per `ConversationCharacterPool`). The **only** authoritative
source for who to depict when a scene includes a person is each row's
mandatory top-level `"genders"` field — read it, don't guess or infer a
gender from whatever name happens to still be in `questionData`:

- `ConvoTemplate-1` / `DialogueCompletion`: paired code `"m-m"` / `"f-m"` /
  `"m-f"` / `"f-f"`, order = character1-character2. A two-person scene should
  depict that exact gender pairing.
- `AppearDisappear` / `ClozeSequence` / `SentenceBuilder` / `GrammarForm`
  (and other non-convo / non-dialogue templates that carry `genders`):
  single code `"m"` or `"f"`.
  - This is the **gender of the speaking / focal person** (the voice of the
    line), **not** a hard cap of one person in the frame.
  - Scenes may still show **two or more people** when that helps the action
    (e.g. waving goodbye to someone, greeting a group). Extra people may be
    any gender.
  - Composition rule: the `"m"` / `"f"` person must be the **clear focal
    point**, or at least **equally focal** with a partner — looking at the
    image, it must be obvious who is saying the line (pose, facing camera /
    gesturing, relative size, center weight). Do **not** bury them as a
    tiny background figure or make a different-gender bystander read as the
    speaker.
  - Solo portraits are fine when a single figure is clearest; many of these
    rows are still object/place scenes with no person at all, which is fine.
  - Example: `see_you_later` (`genders: "f"`) can show two people at a door or
    gate, one waving goodbye and one being waved to — the `f` speaker should
    be mid-wave and facing camera/the viewer, while the other person can be
    partly turned away, walking off, or smaller in frame. Looking at the
    image alone, it must be clear which person is saying "see you later."
- If a row *does* still have an authored `character1`/`character2` (a handful
  of rows keep one when the name is baked into the spoken text, e.g. "Hello,
  I am Beth"), it will already agree with `genders` — the JSON validator
  enforces that consistency, so just trust `genders` either way.
- `imageQuizTemplate-1`/`-2` rows don't carry `genders` (out of scope for this
  field) — depict whatever the answer/scene calls for as usual.

---

## Kids flavor — style

Playful clip-art icons for children. **Not** a muted version of the adults pack.

| Rule | Spec |
|------|------|
| Look | Flat **2D cartoon / playful clip-art** mobile-game icon |
| Background | **Solid pure white `#FFFFFF`** — never black, gray, gradient, or transparent |
| Décor on bg | **No** floating stars, hearts, sparkles, confetti, abstract shapes, or colorful blobs |
| Outlines | Thick **uniform dark (near-black)** outlines; same weight across the pack |
| Fills | Flat solid colors; at most **one soft two-tone shade** on the subject |
| Shadows | Soft shade on the subject only — **no cast shadows** on the white background |
| Lighting | Bright, even daylight; no cinematic mood lighting |
| Composition | **One primary subject**, or **one simple interaction between at most two characters** — centered, white margin, ~60–80% fill |
| Simplicity | Prefer **one clear object or interaction**; drop competing background props |
| Proportions | Soft, simplified; **slightly oversized heads**; friendly/chubby object shapes |
| Pose / energy | Cheerful; **playful energy when content allows** |
| Faces | Rounded; **dot eyes**; simple smiles |
| Props | Simplified / toy-like where natural |
| Palette | Bright, saturated, kid-friendly (**not** neon) |
| Age / setting | Child-aged or kid-world — school, playground, home-kid, toys, pets |
| Avoid | Scary, violent, romantic, adult office/lifestyle scenes; photoreal; corporate stock |

### Kids background (critical)

Always generate **white background from the start**.

**Do not** post-process black backgrounds to white (flood-fill / color replace).

If an older kids asset still has a black background, **regenerate** it.

---

## Adults flavor — style

Richer **flat lifestyle illustration** for adult learners — the look used for
`greetings/adults/` time-of-day scenes (coffee/dawn skyline, office plaza at noon,
desk + autumn window, night canal with lamps). **Visually distinct from kids**
clip-art. Do not produce Disney teens, cute mascots, or bland single-object icons.

| Rule | Spec |
|------|------|
| Look | Clean **professional flat vector** illustration — bold/clear dark outlines, polished editorial/lifestyle icon feel |
| Background | **Full atmospheric scene is allowed and preferred** (sky, city, interior, landscape). Soft sky/lighting gradients OK. Do **not** force empty white clip-art backgrounds for adults |
| Detail | Medium — enough props to feel adult and specific, still readable at ~72–256 px |
| Composition | One clear **scene** that reads the concept (time of day, place, action). Foreground prop + environment is good. Avoid chaotic multi-focus collage |
| Lighting | **Time- and mood-aware**: peach/dawn, bright midday, warm golden afternoon, deep navy night — clear enough to tell scenes apart in a 2×2 grid |
| Outlines | Consistent dark outlines across the pack (slightly finer than kids chunky clip-art is OK) |
| Palette | Sophisticated muted-bright: soft peaches, sky blues, warm wood, autumn golds, navy night — **not** candy neon, **not** preschool pastels |
| Proportions | Natural adult scale — no big-head cartoon, no chubby-toy shapes |
| Characters | Clearly mature adults when people appear (~20–60 mix across a pack, not all 25–35); subtle expressions; soft eyes (**not** babyish dot eyes). Men: mostly clean-shaven or light stubble — full beards only rarely |
| Props / setting | Adult life markers: coffee/tea, alarm clocks, laptops, notebooks, offices, cafés, commute, travel, city landmarks, apartments — match the vocabulary |
| Continuity | Within a level, reuse landmarks/palette language where it helps (e.g. same skyline at morning vs night) |
| Avoid | Bland lone sun-on-white icons; cute mascots; oversized heads; toy props; child heroes (unless content requires); photoreal / 3D / heavy cinematic film stills; stamped title text; every male with a full beard; every adult looking 25–35 |

**Reference bar for adults:** aim for the richness of the greetings adults
time-of-day set (lifestyle scenes with atmosphere), not the kids white-bg sun/moon
pack.

---

## Prompt construction

**Kids:** shared kids block + kids modifiers + content.  
**Adults:** adults block + content (do **not** reuse the kids white-bg clip-art block).

Do not replace or substantially rewrite these blocks mid-pack.

### Kids prompt block

```text
Flat 2D cartoon clip-art mobile-game icon, thick uniform dark outlines (keep
outline thickness consistent across the pack), simple shapes, flat solid colors
with at most one soft two-tone shade on the subject — no cast shadows on the white
background. SOLID PURE WHITE BACKGROUND (#FFFFFF) filling the entire square —
never black, never gray, never transparent. No floating stars, hearts, sparkles,
confetti, abstract shapes, or colorful blobs on the background. Bright even
daylight lighting — no dramatic shadows, rim light, or cinematic mood. Straight-on
eye-level view — no fisheye, extreme close-up, bird's-eye, or dramatic perspective
unless the content requires it. Keep the full primary subject visible — no cropped
heads, cut-off limbs, or clipped objects unless intentionally required. One primary
subject or one simple interaction between at most two characters, centered, main
subject about 60–80% of the canvas, comfortable white margin. The primary object or
action must be immediately recognizable without background context. Prefer
simplicity — one clear object or interaction, no competing background props.
Readable at small size. No logos, no UI, no speech bubbles, no dots, no grain, no
noise. Do not render question text, answers, dialogue, or title captions. Prefer no
readable text; only a short real-world sign if the place would be unclear without
it. Keep dark hair and dark details dark.
Kids English-learning icon: slightly oversized heads, playful simplified shapes,
cheerful expressions, playful energy when content allows, rounded faces with dot
eyes, bright kid-friendly saturated palette (not neon), age-appropriate kids world
(school, play, home, pets) — no adult lifestyle or scary content. Unless continuity
requires otherwise, vary skin tones, hair types, and ethnic backgrounds across
unrelated characters.
```

### Adults prompt block

```text
Clean professional flat vector lifestyle illustration for adult English learners,
1:1 square. Clear consistent dark outlines, polished editorial/lifestyle look —
not chunky preschool clip-art, not photoreal, not 3D, not anime. Sophisticated
muted-bright palette (soft peaches, sky blues, warm woods, autumn golds, navy
nights — not candy neon). Full atmospheric scene preferred: foreground props plus
environment, with time-of-day lighting that reads clearly (dawn peach, bright noon,
golden afternoon, deep navy night). Soft sky or lighting gradients OK. Adult world
props and settings — coffee, tea, desks, laptops, offices, cafés, commute, travel,
city landmarks, apartments. Natural adult proportions when people appear; subtle
expressions; soft expressive eyes not babyish dot eyes; clearly mature adults
with visible age diversity across a pack (~20–60 — not every face 25–35) unless
content specifies another age. Men mostly clean-shaven or light stubble — do not
default every man to a full beard (at most occasional). Keep the full scene
readable and fully visible — no accidental crops. Immediately recognizable
concept at small size. Straight-on eye-level preferred. No logos, no UI, no
speech bubbles, no question text, no answer text, no title captions stamped on
the image (never write GOOD MORNING / NOON / AFTERNOON / NIGHT as labels). Prefer
no readable text; only a short real-world sign if the place would be unclear
without it. Keep dark hair and dark details dark. Same-artist consistency across
the level pack. No cute mascot, preschool toy aesthetic, or Disney teenager look.
Unless continuity requires otherwise, vary skin tones, hair types, ethnic
backgrounds, and ages across unrelated characters.
```

### Content (append last)

```text
[CONTENT: one clear scene, object, or interaction for this question — for adults,
prefer a specific lifestyle vignette with atmosphere, not a lone symbol on white]
```

Use quiz wording only as authoring context — describe what to **show**, do not
ask the model to paint that text onto the image.

Generate with Cursor `GenerateImage`:

- `aspect_ratio`: `"1:1"`
- `filename`: `{stem}.png` matching `imageName` / asset basename (kebab-case)
- Optional: pass a strong prior adults pack image as `reference_image_paths` when
  regenerating to lock style

---

## Delivery workflow

1. Confirm flavor(s): `kids`, `adults`, or both
2. Confirm target folder(s):
   `app/assets/quiz-data/levels/{directoryName}/kids/` and/or `…/adults/`
3. List stems from that flavor’s `questions.json` (`imageName`, `wrongAnswers` for
   template-2 tiles, optional convo `imageName` / `image_file_name`)
4. Note any **named recurring characters** for identity consistency in this pack
5. Generate each stem with the **correct flavor prompt block** + content
6. Copy into the flavor folder (overwrite only when regenerating that stem)
7. Resize to **512×512** (e.g. `sips -z 512 512`) — keep PNG
8. Spot-check:
   - **Kids:** corner pixels near white; no floating décor or cast shadows on bg
   - **Adults:** richer lifestyle scene (not bland lone icon); no stamped titles;
     pack looks same-artist; time/place reads instantly
   - Full subject/scene visible; eye-level framing
   - Kids vs adults clearly distinct if both were generated
   - No quiz/answer text; signage only if necessary
   - Recurring named characters match earlier stems in this flavor folder
   - Unnamed people do **not** reuse the same face/outfit (or same duo)
     across stems — each stem’s cast looks like different individuals
9. Wire JSON if needed (`imageName` / `image_file_name` in that flavor’s questions file)
10. Tell the user to **full restart / hard refresh** so Flutter web drops cached assets

Do not place archive copies inside the level asset directory under a name Flutter
might pick up as quiz images. Prefer a sibling archive outside the level folder,
or a clearly non-asset path the user manages.

If generating **both** flavors for the same stem, run two generations (kids block
→ `kids/`, adults block → `adults/`). Do not duplicate one file into both folders
unless the user explicitly wants identical art temporarily.

## Template-2 note

`imageQuizTemplate-2` needs **four** image stems in the **same flavor folder**
(correct + three wrong). Generate all four with that flavor’s style so the 2×2
grid matches. When authoring kids and adults, verify all four stems exist under
**each** flavor folder. Adults template-2 tiles should still feel like one
lifestyle pack (related lighting/outline language), not four unrelated styles.

## Anti-patterns

- Photoreal / 3D / anime-heavy / heavy cinematic film stills
- Post-process “make background white” scripts (kids)
- Cropped heads, cut-off limbs, or clipped primary subjects
- Quiz question / answer / distractor / dialogue / title captions painted into art
- Decorative teaching captions; full sentences on signs
- Environmental text when the scene is already clear without it
- Adults that look like kids white-bg clip-art (bland sun/moon alone, candy mascots)
- Kids that look like muted corporate lifestyle scenes
- Mixing either pack with the story watercolor style in the same folder
- Saving new quiz images at the **level root** instead of `kids/` / `adults/`
- Reusing the kids white-bg prompt for adults (or vice versa)
- Copying one flavor’s PNG into the other folder as a permanent stand-in without noting it
- Changing a named recurring character’s look mid-level without reason
- Treating single-letter `genders` `"m"` / `"f"` as “only one person allowed”
  (extras are OK; the gendered speaker must stay clearly focal)
- Multi-person scenes where the `genders` speaker is ambiguous or
  backgrounded so another figure reads as the voice
- Reusing the same unnamed face/outfit (or the same duo) across different
  stems — each stem needs distinct individuals unless they are named
  recurring characters
