# Level image folder audit

Compares each level folder under `app/assets/quiz-data/levels/` with
`imageQuizTemplate-1` and `imageQuizTemplate-2` entries in `questions.json`.

- **imageQuizTemplate-1**: only `imageName` must exist as an image file.
- **imageQuizTemplate-2**: `imageName` plus all three `wrongAnswers` must exist as image files.

**Levels with mismatches:** 17
**Orphan images (in folder, not referenced):** 34
**Missing images (referenced, not in folder):** 12

## at-the-school

**In folder but not in questions (2):**
- `fire-alarm`
- `gym`

## basic-sentences

**In folder but not in questions (1):**
- `pencil`

## body-parts-1

**In folder but not in questions (2):**
- `arm`
- `fingernail`

**In questions but missing from folder (11):**
- `back`
- `chest`
- `elbow`
- `finger`
- `foot`
- `hand`
- `heart`
- `leg`
- `muscle`
- `nose`
- `stomach`

## body-parts-2

**Notes:**
- no questions.json

**In folder but not in questions (13):**
- `ankle`
- `back`
- `chest`
- `elbow`
- `face`
- `finger`
- `foot`
- `hand`
- `heart`
- `leg`
- `muscle`
- `nose`
- `stomach`

## city-buildings-1

**In folder but not in questions (1):**
- `house`

## dressing-1

**In folder but not in questions (1):**
- `button`

**In questions but missing from folder (1):**
- `bathrobe`

## going-to-sports

**In folder but not in questions (1):**
- `volleyball-net`

## greetings

**In folder but not in questions (1):**
- `smile`

## hospital-pharmacy-items

**In folder but not in questions (1):**
- `eyeglasses`

## house-parts

**In folder but not in questions (1):**
- `door`

## household-equipment-1

**In folder but not in questions (1):**
- `rope`

## in-the-bathroom

**In folder but not in questions (1):**
- `bathrobe`

## in-the-bedroom

**In folder but not in questions (1):**
- `pillow-case`

## in-the-kitchen

**In folder but not in questions (1):**
- `salt-pepper-shaker`

## jobs-1

**In folder but not in questions (1):**
- `waiter`

## living-room

**In folder but not in questions (2):**
- `coffee-table`
- `cushion-pillows`

## nature-objects

**In folder but not in questions (3):**
- `earth-world`
- `space`
- `stones`
