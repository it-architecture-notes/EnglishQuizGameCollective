# All flow levels — grammar progression audit

Scan of `questions.json` against audit-skill Part bands.
Excludes audio stems; reduces false positives (`Let's`, base-form `read`, adjective `closed`).
Includes distractors (low severity when clearly wrong options).

## Summary by mainLevel

| ML | Part | Levels w/ Q | High flags | Low flags (mostly distractors) |
|----|------|-------------|------------|--------------------------------|
| 1 | 1 | 6 | 0 | 0 |
| 2 | 1 | 7 | 0 | 0 |
| 3 | 1 | 7 | 1 | 2 |
| 4 | 2 | 6 | 0 | 0 |
| 5 | 2 | 8 | 3 | 2 |
| 6 | 3 | 7 | 0 | 0 |
| 7 | 3 | 7 | 0 | 0 |
| 8 | 3 | 8 | 0 | 0 |
| 9 | 4 | 7 | 0 | 0 |
| 10 | 4 | 7 | 0 | 0 |
| 11 | 4 | 7 | 0 | 0 |
| 12 | 4 | 7 | 0 | 0 |

**Levels with high-severity flags:** 3

---

## ML3 · Part 1 — high-severity

*Part 1 (ML1–3): Present Simple, can, continuous, There is/are*

### at-the-library — At the Library (1 high)

| Q | Template | Location | Issue | Snippet |
|---|----------|----------|-------|---------|
| 7 | AppearDisappear | questionData.words | past simple `closed` (Part 3) | `Is the library closed on Sundays?` |

## ML5 · Part 2 — high-severity

*Part 2 (ML4–5): will/going to, must, comparatives, 1st conditional*

### at-the-traffic — At the Traffic (2 high)

| Q | Template | Location | Issue | Snippet |
|---|----------|----------|-------|---------|
| 6 | DialogueCompletion | questionData.answer | irregular past `left` (Part 3) | `Stay in the left lane, please.` |
| 13 | GrammarForm | questionData.sentence | irregular past `left` (Part 3) | `____ left at the traffic light.` |

### common-words-4 — Common Words - 4 (1 high)

| Q | Template | Location | Issue | Snippet |
|---|----------|----------|-------|---------|
| 10 | DialogueCompletion | questionData.line1 | past simple `closed` (Part 3) | `Why is the shop closed today?` |

## Levels with low-severity flags only (mostly distractors)

**ML3:** at-the-school (1 low), common-words-2 (1 low)

## No flags

greetings (ML1)
verb-to-be (ML1)
basic-sentences (ML1)
colors-1 (ML1)
numbers (ML1)
geometric-shapes (ML1)
waking-up (ML2)
in-the-bedroom (ML2)
in-the-bathroom (ML2)
prepositions (ML2)
colors-2 (ML2)
family (ML2)
common-words-1 (ML2)
school-items-1 (ML3)
birthday-party (ML3)
school-items-2 (ML3)
baby-care (ML3)
in-the-kitchen (ML4)
kitchen-items-1 (ML4)
grocery-shopping (ML4)
kitchen-items-2 (ML4)
grocery-list-1 (ML4)
grocery-list-2 (ML4)
at-the-farmers-market (ML5)
fruits-1 (ML5)
walking-in-the-city (ML5)
city-buildings-1 (ML5)
at-the-cinema (ML5)
city-buildings-2 (ML5)
at-the-bank (ML6)
at-the-post-office (ML6)
vegetables-1 (ML6)
farm-animals (ML6)
at-the-farm (ML6)
vegetables-2 (ML6)
common-words-5 (ML6)
fruits-2 (ML7)
at-the-office (ML7)
jobs-1 (ML7)
at-the-restaurant (ML7)
restaurant-items (ML7)
clothes-shopping (ML7)
common-words-6 (ML7)
dressing-1 (ML8)
dressing-2 (ML8)
jobs-2 (ML8)
wild-animals-1 (ML8)
nature-walk (ML8)
wild-animals-2 (ML8)
bird-watching (ML8)
common-words-7 (ML8)
living-room (ML9)
living-room-items (ML9)
house-parts (ML9)
household-equipment-1 (ML9)
household-equipment-2 (ML9)
household-equipment-3 (ML9)
common-words-8 (ML9)
at-the-hotel (ML10)
at-the-airport (ML10)
travel-items (ML10)
at-the-train-station (ML10)
vehicles (ML10)
at-the-garage (ML10)
common-words-9 (ML10)
insect-world (ML11)
at-the-park (ML11)
nature-objects (ML11)
going-to-sports (ML11)
checking-the-weather (ML11)
emotions-1 (ML11)
common-words-10 (ML11)
at-the-pharmacy (ML12)
hospital-pharmacy-items (ML12)
emergency-situations (ML12)
at-the-hospital (ML12)
at-the-dentist (ML12)
emotions-2 (ML12)
common-words-11 (ML12)
