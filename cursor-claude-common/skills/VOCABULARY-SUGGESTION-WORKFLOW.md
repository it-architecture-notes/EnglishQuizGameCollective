# Generic Vocabulary Suggestion File Creation Workflow

## WORKFLOW OVERVIEW

**Goal:** Create a vocabulary suggestion file for a specific level by categorizing words as used/unused and prioritizing them.

---

## INPUT

1. **Unused words from reference files** (identified as relevant to the level)
2. **Words provided by user** in their prompt for that level

---

## REFERENCE SOURCES (for checking if word is used/unused)

1. `@cursor-claude-common/output/prior-words-by-type.md` 
   - Contains all words used in earlier levels
   
2. **PNG filenames in level folders**
   - Check `app/assets/quiz-data/levels/{LEVEL_NAME}/*.png`
   - Check `app/assets/quiz-data/levels/{RELATED_THEME}/*.png` (if applicable)
   - Consider plural/singular variants (e.g., "car" ↔ "cars", "person" ↔ "people")

---

## PROCESS

### Step 1: Combine word lists
- Merge unused reference words + user-provided words
- Remove duplicates
- Organize by part of speech (nouns, verbs, adjectives, adverbs)

### Step 2: Check each word for "used" status
For each word, determine if it's **USED** or **UNUSED**:

- **USED** = Found in prior-words-by-type.md OR PNG filename (including plural/singular variants)
- **UNUSED** = NOT found in either source

### Step 3: Determine priority level
For each word, assign **HIGH PRIORITY** or **RECOMMENDED**:

- **HIGH PRIORITY**: Essential/core vocabulary for this specific level theme
- **RECOMMENDED**: Complements the level, adds depth but not essential

### Step 4: Categorize into 4 sections

| Section | Criteria |
|---------|----------|
| **UNUSED + HIGH PRIORITY** | Not in prior-words / Not PNG image / Essential for level |
| **UNUSED + RECOMMENDED** | Not in prior-words / Not PNG image / Nice to have |
| **USED + HIGH PRIORITY** | Found in prior-words or PNG / Still useful for reinforcement |
| **USED + RECOMMENDED** | Found in prior-words or PNG / Optional reinforcement |

### Step 5: Generate output file

**Location:** `cursor-claude-common/output/{LEVEL_NAME}-vocabulary-suggestion.md`

**Structure:**
```markdown
# {Level Name}: Vocabulary Suggestions

## UNUSED + HIGH PRIORITY
[List words organized by POS with CEFR level and reasoning]

## UNUSED + RECOMMENDED
[List words organized by POS with CEFR level and reasoning]

## USED + HIGH PRIORITY
[List words with source level and reasoning for inclusion]

## USED + RECOMMENDED
[List words with source level and reasoning]

## SUMMARY
- Total words analyzed: X
- Unused: Y (A%, B% High Priority / Recommended)
- Used: Z (C%, D% High Priority / Recommended)
```

---

## EXAMPLE EXECUTION

**For level: at-the-traffic**

### Input:
- User provides: car, truck, bus, driver, pedestrian, intersection, to drive, to stop, dangerous, safe, etc.
- Reference unused words: road, traffic light, crosswalk, etc.

### Check Step:
```
car → Found PNG in vehicles/ → USED
truck → Found PNG in vehicles/ → USED
road → Found PNG in at-the-traffic/ → USED
to drive → Found in prior-words-by-type.md → USED
to honk → NOT found anywhere → UNUSED
dangerous → Found in prior-words-by-type.md → USED
safe → NOT found → UNUSED
intersection → NOT found → UNUSED
```

### Categorize:
```
UNUSED + HIGH PRIORITY:
- safe (adjective, A1, safety concept essential)
- to honk (verb, A1, core traffic action)
- intersection (noun, A1, location context)

UNUSED + RECOMMENDED:
- [other unused words with weaker relevance]

USED + HIGH PRIORITY:
- to drive (verb, found in prior-words, reinforcement needed)
- dangerous (adjective, found in prior-words, safety reinforcement)

USED + RECOMMENDED:
- [other used words with optional reinforcement value]
```

### Output:
Create: `cursor-claude-common/output/at-the-traffic-vocabulary-suggestion.md`

---

## CHECKLIST

- [ ] 1. Combine reference unused words + user-provided words
- [ ] 2. Check each word against prior-words-by-type.md
- [ ] 3. Check each word against PNG filenames (with plural/singular matching)
- [ ] 4. Assign HIGH PRIORITY or RECOMMENDED to each
- [ ] 5. Create 4 categorized sections
- [ ] 6. Write output file to cursor-claude-common/output/
- [ ] 7. Include SUMMARY with totals and percentages
- [ ] 8. Verify file has exactly 4 main sections

---

## PLURAL/SINGULAR MATCHING EXAMPLES

| Singular | Plural | PNG Match | Consider Both |
|----------|--------|-----------|---------------|
| car | cars | car.png | ✓ Match |
| person | people | person.png | ✓ Match |
| bus | buses | bus.png | ✓ Match |
| child | children | child.png | ✓ Match |
| traffic light | traffic lights | traffic-light.png | ✓ Match |

When checking: if "cars" is in word list but "car.png" exists in level folder → Mark as USED (plural/singular match)
