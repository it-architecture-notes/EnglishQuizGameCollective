# Bridge of Wobbling Wood — ML4 Story Structure

## Overview
The Bridge of Wobbling Wood story has been integrated into Main Level 4 with 7 story images distributed across the level's quiz progression. The emotional narrative follows Ben's journey from fear to courage as he rescues his sister Mia from a stranded position on a wobbly bridge.

## Story Distribution & Image Placement

### Image 1: Title/Setup Slide — "bridge-1.png"
**Trigger:** Before "In the Kitchen" (first ML4 level)
**Template:** page_template_id: 4 (single image)
**Caption:** 
> "The Bridge of Wobbling Wood — Ben's little sister Mia is stranded halfway across an old, wobbly bridge when a plank breaks beneath her foot. Ben's heart races, but his love for Mia is stronger than his fear of heights. Play the next level to help Ben find the courage to rescue her."

**Narrative Focus:** Introduction to the problem and emotional stakes. Sets up Ben's internal conflict (fear vs. love).
**Player Action:** "Play next level" — Single level sprint to set up the beginning.

---

### Image 2: Challenge 1 — "bridge-2.png"
**Trigger:** Before "Grocery Shopping" (ML4, level 3)
**Template:** page_template_id: 4 (single image)
**Caption:**
> "Being brave doesn't mean you're never scared—it means you keep going even when you are. Ben remembers Grandpa's words and takes his very first step onto the bridge. Play the next two levels to help him move closer to Mia."

**Narrative Focus:** Ben's internal turning point (Determination emotional stage). Reframes bravery as action despite fear.
**Player Action:** "Play next two levels" — Bridge the early-to-mid section of the level.

---

### Image 3 & 4: Challenge 2 & 3 (Dual Template) — "bridge-3.png" & "bridge-4.png"
**Trigger:** Before "Common Words - 3" (ML4, middle section)
**Template:** page_template_id: 5 (dual image/text pairs)

**Part 1 Caption:**
> "Ben studies the boards carefully, reasoning through which path is safe. Some planks are slippery with moss, but others are anchored by tight, strong ropes. With your help, he chooses wisely."

**Part 2 Caption:**
> "A strong wind rushes across the bridge, and the ropes begin to sway. Ben grips tight and steadies his breathing. 'In and out,' he whispers. Play the next two levels to help him stay calm and keep moving forward."

**Narrative Focus:** 
- Part 1 (Challenge 2 - Looking Carefully): Focus on reasoning and careful decision-making.
- Part 2 (Challenge 3 - Staying Calm): Wind adversity test; emotional progression to Calm through self-control.

**Player Action:** "Play next two levels" — Navigates through a problem-solving paired sequence.

---

### Image 5 & 6: Challenge 4 & 5 (Dual Template) — "bridge-5.png" & "bridge-6.png"
**Trigger:** Before "Reminder 1" (end of active ML4 levels)
**Template:** page_template_id: 5 (dual image/text pairs)

**Part 1 Caption:**
> "Ben reaches Mia and discovers her shoelace is caught on splintered wood. With clever thinking and gentle hands, he carefully unties the knot and helps her slip her foot free. Together, they are so much stronger."

**Part 2 Caption:**
> "A board falls away behind them, but Ben and Mia don't look back in fear. Instead, they stand together, hand in hand, and face the last stretch of bridge ahead. Play the next two levels to help them cross the final distance together."

**Narrative Focus:**
- Part 1 (Challenge 4 - Thinking Like a Helper): Clever problem-solving; shift from solo courage to helping another (Cleverness).
- Part 2 (Challenge 5 - Working Together): Emotional crescendo to Trust and teamwork as they face the final stretch.

**Player Action:** "Play next two levels" — Final active challenges before the reminders.

---

### Image 7: Final Scene — "bridge-7.png"
**Trigger:** After "Reminder 2" (completion of ML4)
**Template:** page_template_id: 4 (single image)
**Caption:**
> "Ben and Mia reach solid ground as the old bridge collapses behind them. The villagers gather in celebration, and Ben smiles—dusty and windblown but proud. 'I was scared,' he admits, 'but I wasn't alone.' Bravery means taking the next step anyway, with a little help from others. Thank you for helping them!"

**Narrative Focus:** Resolution and emotional payoff. Ben's transformation from tense/afraid to open/proud. Reinforces the story's core message about shared courage.
**Player Action:** Direct gratitude to the player for completing the level.

---

## Caption Refinement Summary

The captions have been refactored to match the emotional storytelling style of ML3 (Beach Heroes):

✅ **Emotionally grounded language**: Words like "smart," "clever," "together," "stay calm," "brave"
✅ **Narrative progression**: Each caption builds on the previous, showing transformation
✅ **Player agency**: Captions directly invite player participation ("With your help," "Play the next X levels")
✅ **"Next level" vs. "Next two levels"** decisions:
  - Single level for high-impact emotional moments (Setup, Final)
  - Two levels for problem-solving sequences and action progression
  - Paired approach balances pacing and level density

✅ **No direct dialogue rendered in captions**: Story remains accessible to young learners without overwhelming text
✅ **Consistency with story guide**: Emotional progression follows the specified arc: Fear → Determination → Focus → Calm → Cleverness → Trust → Relief and Pride

## Image Asset Requirements

The following images must be created/placed in `assets/images/story/`:

1. **bridge-1.png** — Title/Setup Slide (full bridge, Mia stranded, Ben tense at entrance)
2. **bridge-2.png** — Challenge 1 (Ben's first step, close focus)
3. **bridge-3.png** — Challenge 2 (Ben choosing safe plank path)
4. **bridge-4.png** — Challenge 3 (Ben gripping ropes in wind)
5. **bridge-5.png** — Challenge 4 (Ben freeing Mia's shoelace)
6. **bridge-6.png** — Challenge 5 (Ben and Mia hand-in-hand moving forward)
7. **bridge-7.png** — Final Scene (solid ground, villagers, celebration)

**Icon Image:** `mainlevel4-story-icon-bridge.png` (referenced as `assets/images/story/bridge-1.png` in the story_icon_asset_path)

## Story Continuity Notes

- The visual journey moves along a single continuous bridge crossing: entrance → reasoning point → midpoint (wind) → Mia's position → final stretch → solid ground
- Character wear progression: Ben and Mia gradually become dustier and more windblown as the journey continues
- The original broken plank (Mia's initial hazard) remains visible as a landmark throughout the journey
- Environmental lighting progresses from cool/misty morning tones to warm golden afternoon light by the Final Scene
- A recurring robin motif appears in each illustration as a quiet companion (visible but never part of the plot)

## ML4 Level Sequence (for reference)

1. In the Kitchen
2. Kitchen Items 1 - Image only
3. Grocery Shopping ← Image 2 trigger
4. Kitchen Items 2 - Image only
5. Grocery List 1 - Image only
6. Grocery List 2 - Image only
7. Common Words - 3 ← Image 3 & 4 trigger
8. **Reminder 1** ← Image 5 & 6 trigger
9. **Reminder 2** ← Image 7 trigger (after)

## File Location

**Updated file:** `/app/assets/data/story/game-main-level-stories.json`

The ML4 story entry (main_levels[3]) has been successfully added to the story configuration with all 5 story events (7 images total) properly distributed.

---

**Status:** ✅ Complete and ready for image asset creation and integration.
