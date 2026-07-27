# Bridge of Wobbling Wood — Image-to-Caption Mapping

## Quick Reference: Where Each Image Appears

```
ML4 PROGRESSION
═══════════════

In the Kitchen
    ↓
Kitchen Items 1
    ↓
Grocery Shopping                    ← 🖼️ IMAGE 2 (bridge-2.png)
    ↓
Kitchen Items 2
    ↓
Grocery List 1
    ↓
Grocery List 2
    ↓
Common Words - 3                    ← 🖼️ IMAGE 3 & 4 (bridge-3.png, bridge-4.png)
    ↓
Reminder 1                          ← 🖼️ IMAGE 5 & 6 (bridge-5.png, bridge-6.png)
    ↓
Reminder 2 (after completion)       ← 🖼️ IMAGE 7 (bridge-7.png)

🖼️ IMAGE 1 (bridge-1.png) → Before "In the Kitchen" (first level)
```

## Caption-to-Emotional-Journey Mapping

| # | Image | Event_ID | Trigger Level | Emotional Stage | Caption Theme | Player Action |
|---|-------|----------|---------------|-----------------|---------------|---------------|
| 1 | bridge-1.png | 1001 | In the Kitchen | Fear → Introduction | The Crisis (Mia stranded) | "Play the next level" |
| 2 | bridge-2.png | 1002 | Grocery Shopping | Determination | Finding Courage (first step) | "Play the next two levels" |
| 3 | bridge-3.png | 1003 (Part 1) | Common Words - 3 | Focus | Looking Carefully (reasoning) | (part of pair) |
| 4 | bridge-4.png | 1003 (Part 2) | Common Words - 3 | Calm | Staying Calm (wind challenge) | "Play the next two levels" |
| 5 | bridge-5.png | 1004 (Part 1) | Reminder 1 | Cleverness | Thinking Like a Helper (freeing foot) | (part of pair) |
| 6 | bridge-6.png | 1004 (Part 2) | Reminder 1 | Trust | Working Together (hand-in-hand) | "Play the next two levels" |
| 7 | bridge-7.png | 1005 | After Reminder 2 | Relief & Pride | Safe on Solid Ground (resolution) | Direct gratitude |

## Emotional Arc Verification

✅ **Complete Arc Achieved:**
- **Fear** (Image 1): Immediate crisis, emotional stakes introduced
- **Determination** (Image 2): Internal shift, Grandpa's wisdom, first action
- **Focus** (Image 3): Rational reasoning through danger (wet plank vs. rope-anchored)
- **Calm** (Image 4): Self-regulation despite adversity (wind challenge)
- **Cleverness** (Image 5): Problem-solving with purpose (shoelace untying)
- **Trust** (Image 6): Transition from solo courage to teamwork
- **Relief & Pride** (Image 7): Resolution, celebration, reflection

## Refactored Caption Features (ML3-Aligned)

Each caption has been deliberately crafted to:

1. **Avoid direct reader address initially**: Instead of "You help Ben," captions show Ben's agency ("Ben remembers," "Ben studies," etc.)
2. **Build reader participation naturally**: "With your help," "Play the next X levels" — indirect but clear invitation
3. **Use achievement language**: "Great," "Together," "Wisely," "Clever thinking," "Dusty and windblown but proud"
4. **Include micro-emotions**: "Ben's heart races," "grips tight," "steadies his breathing," "smiles"
5. **Focus on action over explanation**: Show what's happening, not why it matters (the why comes from player experience)

---

## JSON Structure Reminder

Each story event follows this pattern:

```json
{
  "event_id": 1001,
  "page_template_id": 4,           // or 5 for dual images
  "story_text": {                  // or "story_texts" for arrays
    "en": "Caption text here"      // only English for now
  },
  "scene_image": "bridge-1.png",  // or "scene_images" array for page_template_id: 5
  "trigger": {
    "type": "before_level",        // or "after_level"
    "level": "Level Name Here"
  }
}
```

---

## Next Steps for Implementation

1. ✅ **JSON Configuration**: Complete (this file)
2. ⏳ **Image Asset Creation**: 7 illustration files needed
   - bridge-1.png through bridge-7.png
   - Placement: `assets/images/story/`
3. ⏳ **Story Icon Asset**: 1 thumbnail icon
   - mainlevel4-story-icon-bridge.png
   - Placement: `assets/images/story/`
4. ⏳ **Testing**: Verify story triggers display correctly during ML4 playthrough

---

**Generated:** Bridge ML4 story structure ready for illustration phase
