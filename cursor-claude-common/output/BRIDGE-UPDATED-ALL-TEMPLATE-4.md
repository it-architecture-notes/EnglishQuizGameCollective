# Bridge of Wobbling Wood — ML4 Story: Updated Configuration (All Template 4)

## ✅ Configuration Update: Single-Image Distribution

The ML4 Bridge story has been restructured to use **only page_template_id: 4** (single image per event), distributing one image per story checkpoint.

---

## 📸 New Image Distribution (7 Events, All Single Template)

| Event # | Image | Level Trigger | Emotional Stage | Template |
|---------|-------|---|---|---|
| 1001 | bridge-1.png | In the Kitchen | Fear | 4 |
| 1002 | bridge-2.png | Grocery Shopping | Determination | 4 |
| 1003 | bridge-3.png | Kitchen Items 2 - Image only | Focus | 4 |
| 1004 | bridge-4.png | Grocery List 1 - Image only | Calm | 4 |
| 1005 | bridge-5.png | Common Words - 3 | Cleverness | 4 |
| 1006 | bridge-6.png | Reminder 1 | Trust | 4 |
| 1007 | bridge-7.png | After Reminder 2 | Relief & Pride | 4 |

---

## 💬 Updated Captions (One Per Image)

### Event 1001 — Setup Slide
**Image:** bridge-1.png | **Trigger:** Before "In the Kitchen"
> "The Bridge of Wobbling Wood — Ben's little sister Mia is stranded halfway across an old, wobbly bridge when a plank breaks beneath her foot. Ben's heart races, but his love for Mia is stronger than his fear of heights. Play the next level to help Ben find the courage to rescue her."

### Event 1002 — Challenge 1
**Image:** bridge-2.png | **Trigger:** Before "Grocery Shopping"
> "Being brave doesn't mean you're never scared—it means you keep going even when you are. Ben remembers Grandpa's words and takes his very first step onto the bridge. Play the next two levels to help him move closer to Mia."

### Event 1003 — Challenge 2
**Image:** bridge-3.png | **Trigger:** Before "Kitchen Items 2 - Image only"
> "Ben studies the boards carefully, reasoning through which path is safe. Some planks are slippery with moss, but others are anchored by tight, strong ropes. With your help, he chooses wisely."

### Event 1004 — Challenge 3
**Image:** bridge-4.png | **Trigger:** Before "Grocery List 1 - Image only"
> "A strong wind rushes across the bridge, and the ropes begin to sway. Ben grips tight and steadies his breathing. 'In and out,' he whispers. Play the next level to help him stay calm and keep moving forward."

### Event 1005 — Challenge 4
**Image:** bridge-5.png | **Trigger:** Before "Common Words - 3"
> "Ben reaches Mia and discovers her shoelace is caught on splintered wood. With clever thinking and gentle hands, he carefully unties the knot and helps her slip her foot free. Together, they are so much stronger."

### Event 1006 — Challenge 5
**Image:** bridge-6.png | **Trigger:** Before "Reminder 1"
> "A board falls away behind them, but Ben and Mia don't look back in fear. Instead, they stand together, hand in hand, and face the last stretch of bridge ahead. Play the next level to help them cross the final distance together."

### Event 1007 — Final Scene
**Image:** bridge-7.png | **Trigger:** After "Reminder 2"
> "Ben and Mia reach solid ground as the old bridge collapses behind them. The villagers gather in celebration, and Ben smiles—dusty and windblown but proud. 'I was scared,' he admits, 'but I wasn't alone.' Bravery means taking the next step anyway, with a little help from others. Thank you for helping them!"

---

## 📊 Configuration Summary

**Before:** 5 events (3 single + 2 dual templates)  
**After:** 7 events (all single template)

| Metric | Value |
|--------|-------|
| Total Story Events | 7 |
| Total Story Images | 7 |
| Template Type | All page_template_id: 4 |
| Images Per Event | 1 |
| Emotional Progression | 7 stages ✓ |
| JSON Validation | ✅ Passed |

---

## 🔗 ML4 Level Sequence (Updated)

```
1. In the Kitchen ..................... ← EVENT 1001 (bridge-1.png)
2. Kitchen Items 1 (Image only)
3. Grocery Shopping ................... ← EVENT 1002 (bridge-2.png)
4. Kitchen Items 2 (Image only) ...... ← EVENT 1003 (bridge-3.png)
5. Grocery List 1 (Image only) ....... ← EVENT 1004 (bridge-4.png)
6. Grocery List 2 (Image only)
7. Common Words - 3 .................. ← EVENT 1005 (bridge-5.png)
8. Reminder 1 ....................... ← EVENT 1006 (bridge-6.png)
9. Reminder 2 ....................... → EVENT 1007 (bridge-7.png)
```

---

## ✨ Benefits of All-Template-4 Structure

✓ **Cleaner distribution:** One image per checkpoint, one message per event  
✓ **Consistent experience:** Same template type throughout  
✓ **Flexibility:** Easy to adjust trigger points  
✓ **Simplicity:** No dual-template parsing needed  
✓ **Player pacing:** Story beats sync naturally with level progression  

---

## 🎨 Illustration Requirements (Unchanged)

- **8 total assets:** 7 illustrations + 1 icon
- **Asset names:** bridge-1.png through bridge-7.png
- **Destination:** app/assets/images/story/
- **Style:** Soft watercolor storybook
- **Specifications:** See BRIDGE-ML4-COMPLETE-SUMMARY.md

---

## 📁 File Modified

✅ `app/assets/data/story/game-main-level-stories.json`
   - Updated to 7 story events
   - All events use page_template_id: 4
   - Proper trigger placement maintained
   - JSON validation: PASSED ✓

---

**Status:** ✅ Configuration updated and validated  
**Ready for:** Illustration asset creation  
**Last Updated:** July 21, 2026
