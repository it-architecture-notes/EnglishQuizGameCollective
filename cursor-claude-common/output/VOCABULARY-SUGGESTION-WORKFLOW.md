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
   
2. **PNG filenames project-wide**
   - Check `app/assets/quiz-data/levels/{LEVEL_NAME}/*.png` first
   - Then check **every other level folder** under `app/assets/quiz-data/levels/*/*.png` (full-project search — a word's image can exist in an unrelated-sounding level folder, e.g. `egg` → `grocery-list-1/eggs.png`, `milk` → `grocery-shopping/milk.png`, `fence` → `house-parts/fence.png`)
   - Do NOT limit the search to a single guessed "related theme" folder — that misses real matches
   - Consider plural/singular variants (e.g., "car" ↔ "cars", "person" ↔ "people")

3. **Words already used in THIS level**
   - Check `app/assets/quiz-data/levels/{LEVEL_NAME}/translations.json` (tracked words)
   - Check `app/assets/quiz-data/levels/{LEVEL_NAME}/questions.json` (WordPairs, answers, dialogue)

---

## PROCESS

### Step 1: Combine word lists
- Merge unused reference words + user-provided words
- Remove duplicates
- Organize by part of speech (nouns, verbs, adjectives, adverbs)

### Step 2: Check each word for "used" status (SYSTEMATIC ALGORITHM)

**FOR EACH of the N words in your list:**

1. **Check prior-words-by-type.md (USING GREP)**
   ```bash
   grep -i "word_to_check" cursor-claude-common/output/prior-words-by-type.md
   ```
   - Check exact word match
   - Check with "to " prefix (for verbs: "to walk" vs "walk")
   - Check singular AND plural variants (car/cars, person/people, etc.)
   - If FOUND → Mark as USED (source: prior-words)

2. **Check PNG filenames in THIS level**
   ```bash
   ls app/assets/quiz-data/levels/{LEVEL_NAME}/*.png
   ```
   - Check exact filename match
   - Check singular AND plural variants
   - If FOUND → Mark as USED (source: PNG image)

3. **Check PNG filenames project-wide (ALL other level folders)**
   ```bash
   find app/assets/quiz-data/levels -iname "*word_to_check*.png"
   ```
   - Do NOT stop at a single guessed "related theme" folder — search every level folder
   - Check exact filename match
   - Check singular AND plural variants
   - If FOUND → Mark as USED (source: PNG image, note which level folder it's in)

4. **Check this level's translations.json (USING GREP)**
   ```bash
   grep -i "word_to_check" app/assets/quiz-data/levels/{LEVEL_NAME}/translations.json
   ```
   - Check exact word match
   - Check with "to " prefix for verbs
   - If FOUND → Mark as USED (source: translations.json)

5. **Check this level's questions.json (USING GREP)**
   ```bash
   grep -i "word_to_check" app/assets/quiz-data/levels/{LEVEL_NAME}/questions.json
   ```
   - Check for word in WordPairs
   - Check for word in dialogue/answers
   - Check as answer option
   - If FOUND → Mark as USED (source: questions.json)

**DECISION LOGIC:**
- If word found in ANY of the 5 checks above → **USED**
- If word NOT found in ANY of the 5 checks → **UNUSED**

**CRITICAL: Do NOT rely on memory or intuition. USE GREP FOR EVERY CHECK.**

### Step 3: Determine priority level
For each word, assign **HIGH PRIORITY** or **RECOMMENDED**:

- **HIGH PRIORITY**: Essential/core vocabulary for this specific level theme
- **RECOMMENDED**: Complements the level, adds depth but not essential

### Step 4: Categorize into 4 sections

| Section | Criteria |
|---------|----------|
| **UNUSED + HIGH PRIORITY** | Not in any source / Essential for level |
| **UNUSED + RECOMMENDED** | Not in any source / Complements level |
| **USED + HIGH PRIORITY** | Found in source(s) / Still useful for reinforcement |
| **USED + RECOMMENDED** | Found in source(s) / Optional reinforcement |

### Step 5: Generate output file

**Location:** `cursor-claude-common/output/{LEVEL_NAME}-vocabulary-suggestion.md`

**File naming convention:**
- If file does NOT exist: `{LEVEL_NAME}-vocabulary-suggestion.md`
- If file ALREADY exists: `{LEVEL_NAME}-vocabulary-suggestion_2.md`
- If `_2` also exists: `{LEVEL_NAME}-vocabulary-suggestion_3.md` (and so on)

**Check before creating:**
```bash
# Check if file exists
ls cursor-claude-common/output/{LEVEL_NAME}-vocabulary-suggestion.md

# If exists, create with _2 postfix
# If _2 also exists, create _3, etc.
```

**Structure:**
```markdown
# {Level Name}: Vocabulary Suggestions

## UNUSED + HIGH PRIORITY
[List words organized by POS with CEFR level and reasoning]

## UNUSED + RECOMMENDED
[List words organized by POS with CEFR level and reasoning]

## USED + HIGH PRIORITY
[List words with source(s) and reasoning for inclusion]

## USED + RECOMMENDED
[List words with source(s) and reasoning]

## SUMMARY
- Total words analyzed: X
- Unused: Y (A% High Priority / B% Recommended)
- Used: Z (C% High Priority / D% Recommended)
- Breakdown by source (prior-words, PNG, translations.json, questions.json)
```

---

## EXAMPLE EXECUTION

**For level: at-the-traffic**

### Input:
- User provides: car, truck, bus, driver, pedestrian, intersection, to drive, to stop, dangerous, safe, etc.
- Reference unused words: road, traffic light, crosswalk, etc.

### Check Step (against all 3 sources):
```
car → Found PNG in vehicles/ (project-wide search) → USED
truck → Found PNG in vehicles/ (project-wide search) → USED
road → Found PNG in at-the-traffic/ → USED
to drive → Found in translations.json (at-the-traffic) → USED
to honk → NOT found in any source → UNUSED
dangerous → Found in prior-words-by-type.md → USED
safe → NOT found in any source → UNUSED
intersection → Found in questions.json (SentenceBuilder) → USED
```

### Categorize:
```
UNUSED + HIGH PRIORITY:
- safe (adjective, A1, safety concept essential)
- to honk (verb, A1, core traffic action)

UNUSED + RECOMMENDED:
- [other unused words with weaker relevance]

USED + HIGH PRIORITY:
- to drive (verb, found in translations.json, reinforcement needed)
- dangerous (adjective, found in prior-words, safety reinforcement)
- intersection (noun, found in questions.json, location context)

USED + RECOMMENDED:
- [other used words with optional reinforcement value]
```

### Output:
Create: `cursor-claude-common/output/at-the-traffic-vocabulary-suggestion.md`

---

## CHECKLIST

- [ ] 1. Combine reference unused words + user-provided words (organize by POS)
- [ ] 2. FOR EACH word (129 total): systematically check all 5 sources with Grep
   - [ ] 2a. Search prior-words-by-type.md (grep -i exact match + "to " variants + plural/singular)
   - [ ] 2b. Search level PNG files (exact match + plural/singular)
   - [ ] 2c. Search PNG files project-wide across ALL other level folders (`find app/assets/quiz-data/levels -iname "*word*.png"` — exact match + plural/singular; do not stop at one guessed related-theme folder)
   - [ ] 2d. Search level translations.json (grep -i exact match + "to " variants)
   - [ ] 2e. Search level questions.json (grep -i in WordPairs/dialogue/answers)
- [ ] 3. Record USED or UNUSED status with source(s) for each word
- [ ] 4. Assign HIGH PRIORITY or RECOMMENDED to each word
- [ ] 5. Categorize all words into 4 sections (UNUSED+HP, UNUSED+REC, USED+HP, USED+REC)
- [ ] 6. Check if `{LEVEL_NAME}-vocabulary-suggestion.md` already exists
- [ ] 7. If exists, create with `_2` postfix (or `_3` if `_2` exists, etc.)
- [ ] 8. Write output file to cursor-claude-common/output/
- [ ] 9. Include SUMMARY with totals, percentages, and source breakdown
- [ ] 10. Verify file has exactly 4 main content sections

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

---

## SOURCE PRIORITY FOR MARKING "USED"

When a word is found in multiple sources, mark it as **USED** with primary source listed:
1. This level's translations.json (highest priority - directly tracked)
2. This level's questions.json (actively used)
3. PNG filename (visually taught)
4. prior-words-by-type.md (prior levels)
