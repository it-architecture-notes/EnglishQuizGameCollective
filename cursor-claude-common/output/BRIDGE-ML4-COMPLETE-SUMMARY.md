# Bridge of Wobbling Wood — ML4 Story Integration: Complete Summary

## ✅ Task Completed

The Bridge of Wobbling Wood narrative has been successfully integrated into Main Level 4 (ML4) of the English Quiz Game. All story sequences, image placements, captions, and emotional progression have been configured and are ready for illustration asset creation.

---

## 📋 What Was Done

### 1. **Story Configuration Added to game-main-level-stories.json**
   - **File Modified:** `app/assets/data/story/game-main-level-stories.json`
   - **New Entry:** `main_levels[3]` (ML4 story structure)
   - **Story Icon:** `assets/images/story/bridge-1.png`
   - **Total Scenes:** 7 story images (5 story events)

### 2. **Image Placement Strategy**
   - **Placement Approach:** Distributed across ML4 level progression
   - **Total Images:** 7 unique story illustrations
   - **Template Types:** 
     - 3× page_template_id: 4 (single image, full caption)
     - 2× page_template_id: 5 (dual images, paired captions)

### 3. **Caption Refactoring**
   - **Style:** Aligned with emotional storytelling pattern from ML3 (Beach Heroes)
   - **Language:** Achievement-focused, emotionally grounded
   - **Player Engagement:** Progressively invites player participation
   - **Narrative Arc:** Follows complete emotional journey from Fear to Relief & Pride

### 4. **Distribution Documentation**
   - Created `BRIDGE-ML4-STORY-STRUCTURE.md` — Complete structure breakdown
   - Created `BRIDGE-IMAGE-CAPTION-MAPPING.md` — Visual reference and caption mapping

---

## 📍 Image Placement Timeline

| Position | Image | Level Trigger | Context |
|----------|-------|---|---------|
| Before Level 1 | bridge-1.png (Title/Setup) | In the Kitchen | Introduces crisis & Ben's challenge |
| Before Level 3 | bridge-2.png (Challenge 1) | Grocery Shopping | Finding Courage milestone |
| Before Level 7 | bridge-3.png & bridge-4.png (Challenge 2 & 3) | Common Words - 3 | Focus → Calm progression |
| Before Reminder 1 | bridge-5.png & bridge-6.png (Challenge 4 & 5) | Reminder 1 | Cleverness → Trust climax |
| After Reminder 2 | bridge-7.png (Final Scene) | Reminder 2 | Resolution & celebration |

---

## 💬 Caption Content

### Image 1 — Title/Setup (bridge-1.png)
**Type:** Single image intro
**Text:**
> "The Bridge of Wobbling Wood — Ben's little sister Mia is stranded halfway across an old, wobbly bridge when a plank breaks beneath her foot. Ben's heart races, but his love for Mia is stronger than his fear of heights. Play the next level to help Ben find the courage to rescue her."

---

### Image 2 — Challenge 1 (bridge-2.png)
**Type:** Single image, emotional turning point
**Text:**
> "Being brave doesn't mean you're never scared—it means you keep going even when you are. Ben remembers Grandpa's words and takes his very first step onto the bridge. Play the next two levels to help him move closer to Mia."

---

### Image 3 & 4 — Challenge 2 & 3 (Dual Template)
**Type:** page_template_id: 5 (paired)

**Part 1 (bridge-3.png) — Looking Carefully:**
> "Ben studies the boards carefully, reasoning through which path is safe. Some planks are slippery with moss, but others are anchored by tight, strong ropes. With your help, he chooses wisely."

**Part 2 (bridge-4.png) — Staying Calm:**
> "A strong wind rushes across the bridge, and the ropes begin to sway. Ben grips tight and steadies his breathing. 'In and out,' he whispers. Play the next two levels to help him stay calm and keep moving forward."

---

### Image 5 & 6 — Challenge 4 & 5 (Dual Template)
**Type:** page_template_id: 5 (paired)

**Part 1 (bridge-5.png) — Thinking Like a Helper:**
> "Ben reaches Mia and discovers her shoelace is caught on splintered wood. With clever thinking and gentle hands, he carefully unties the knot and helps her slip her foot free. Together, they are so much stronger."

**Part 2 (bridge-6.png) — Working Together:**
> "A board falls away behind them, but Ben and Mia don't look back in fear. Instead, they stand together, hand in hand, and face the last stretch of bridge ahead. Play the next two levels to help them cross the final distance together."

---

### Image 7 — Final Scene (bridge-7.png)
**Type:** Single image, resolution
**Text:**
> "Ben and Mia reach solid ground as the old bridge collapses behind them. The villagers gather in celebration, and Ben smiles—dusty and windblown but proud. 'I was scared,' he admits, 'but I wasn't alone.' Bravery means taking the next step anyway, with a little help from others. Thank you for helping them!"

---

## 🎨 Illustration Requirements

### Asset Files Needed (Total: 8 files)

#### Story Illustrations (7 images)
1. **bridge-1.png** — Title/Setup Slide
   - Focus: Full bridge, Mia stranded at gap, Ben tense at entrance
   - Mood: Worried but grounded, not frightening
   
2. **bridge-2.png** — Challenge 1 (Finding Courage)
   - Focus: Ben's foot lifted for first step, eyes focused, steadying breath
   - Mood: Quiet internal turning point
   
3. **bridge-3.png** — Challenge 2 (Looking Carefully)
   - Focus: Mossy plank vs. rope-anchored board, Ben studying carefully
   - Mood: Thoughtful reasoning over fear
   
4. **bridge-4.png** — Challenge 3 (Staying Calm)
   - Focus: Ben gripping ropes, wind visible, posture steadying
   - Mood: Tense but controlled
   
5. **bridge-5.png** — Challenge 4 (Thinking Like a Helper)
   - Focus: Ben's hands untying shoelace, Mia's foot beginning to slip free
   - Mood: Tender, focused, problem-solving
   - Camera: Medium close-up (exception to standard framing)
   
6. **bridge-6.png** — Challenge 5 (Working Together)
   - Focus: Ben and Mia hand-in-hand, board fallen behind, facing final stretch
   - Mood: Determined, quietly triumphant
   
7. **bridge-7.png** — Final Scene (Safe on Solid Ground)
   - Focus: Ben kneeling, Mia hugging him, villagers gathered, bridge collapsed
   - Mood: Joyful relief, celebration, transformation complete

#### Story Icon (1 thumbnail)
8. **mainlevel4-story-icon-bridge.png** (or referenced as bridge-1.png)
   - Size: Suitable for ML4 story icon in game UI
   - Content: Key visual element from the bridge story (suggestion: Ben and Mia with bridge in background)

### Asset Location
**Directory:** `app/assets/images/story/`
**Naming Convention:** `bridge-1.png` through `bridge-7.png`

### Illustration Style Specifications
- **Medium:** Soft children's storybook watercolor
- **Line Style:** Dark brown/charcoal outlines (never pure black), loose hand-painted ink
- **Texture:** Visible brush texture, soft watercolor blending
- **Color Palette:** 
  - Primary: Cream, weathered wood brown, misty sage green, soft river blue, muted moss green
  - Accents: Soft pink cheeks, red ribbons on Mia, warm golden light (end)
  - Progression: Cool morning mist → warm golden afternoon light
- **Framing:** 1:1 square aspect ratio, medium-wide view (except Challenge 4 close-up)
- **Characters:**
  - Ben: 11 years old, tousled sandy-brown hair, green sweater, brown trousers, worn boots
  - Mia: 7 years old, braids with red ribbons, yellow dress, brown boots
  - Recurring motif: Small robin in every scene (quiet companion, never part of plot)
- **Avoid:** Speech bubbles, UI elements, photorealism, heavy black lines, exaggerated poses, visible falls, terrified expressions, blood/injury, violent river

### Consistency Rules
- **Character appearance:** Identical throughout all scenes (clothing color, hairstyle, proportions)
- **Bridge landmark:** Original broken plank visible in all scenes (except Setup & first step), showing progress
- **Environmental continuity:** Same bridge and valley viewed from different points along the crossing
- **Physical wear progression:** Gradual dustiness, windblown hair, loosened ribbons (showing journey completion without distress)
- **Lighting progression:** Cool morning mist → Clear morning light → Grey/windy light → Softening light → Warm golden afternoon

---

## 📊 Story Structure Metrics

| Metric | Value |
|--------|-------|
| Total Story Events | 5 |
| Total Story Images | 7 |
| Single-Image Templates | 3 (page_template_id: 4) |
| Dual-Image Templates | 2 (page_template_id: 5) |
| Emotional Stages | 7 (Fear → Determination → Focus → Calm → Cleverness → Trust → Relief & Pride) |
| Player Action Cues | 5 ("Play next level," "Play next two levels," direct gratitude) |
| Triggers Before Levels | 4 |
| Triggers After Levels | 1 |

---

## ✨ Emotional Arc Verification

The Bridge story follows the complete emotional progression specified in the story guide:

✅ **Fear** → Ben's heart races, Mia stranded, crisis introduced  
✅ **Determination** → Ben chooses courage over fear, takes first step  
✅ **Focus** → Careful reasoning through plank choices  
✅ **Calm** → Self-regulation during wind challenge  
✅ **Cleverness** → Clever problem-solving with shoelace  
✅ **Trust** → Transition to teamwork and shared strength  
✅ **Relief & Pride** → Safe on solid ground, celebration, transformation complete

---

## 🔗 ML4 Level Sequence Reference

The story is integrated into this ML4 progression:

1. In the Kitchen ← **IMAGE 1** trigger
2. Kitchen Items 1 - Image only
3. Grocery Shopping ← **IMAGE 2** trigger
4. Kitchen Items 2 - Image only
5. Grocery List 1 - Image only
6. Grocery List 2 - Image only
7. Common Words - 3 ← **IMAGE 3 & 4** trigger
8. Reminder 1 ← **IMAGE 5 & 6** trigger
9. Reminder 2 ← **IMAGE 7** trigger (after)

---

## 📝 Files Modified/Created

### Modified
- `app/assets/data/story/game-main-level-stories.json` — Added ML4 story configuration

### Created (Documentation)
- `cursor-claude-common/output/BRIDGE-ML4-STORY-STRUCTURE.md` — Complete structure & distribution guide
- `cursor-claude-common/output/BRIDGE-IMAGE-CAPTION-MAPPING.md` — Visual reference and caption mapping

---

## 🎯 Next Steps

1. **Illustration Creation:** Generate 7 story illustrations following the specifications above
2. **Asset Placement:** Place finished images in `app/assets/images/story/`
3. **Testing:** 
   - Verify story triggers display at correct level boundaries
   - Check caption text formatting and readability
   - Confirm emotional arc flows naturally during gameplay
4. **Localization:** (Optional) Translate captions to match game's language support (ML3 example shows 11 languages)

---

## 📌 Status

✅ **Configuration:** Complete  
⏳ **Illustration:** Pending  
⏳ **Asset Integration:** Pending  
⏳ **Testing:** Pending  
⏳ **Localization:** Optional

---

**Generated:** July 21, 2026  
**Story Title:** The Bridge of Wobbling Wood  
**Main Level:** 4 (ML4)  
**Total Images:** 7  
**Ready for:** Illustration phase
