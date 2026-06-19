# Audit Quiz Level — Reference

## Prior-level consumed words (required)

**Always run** at the start of an audit:

```bash
python3 tools/gather_prior_level_words.py {level-id} --format json
```

| Flag | Purpose |
|------|---------|
| `--format json` | Structured `{ word, level, source }` list for the report |
| `--format csv` | Spreadsheet-friendly export |
| `-o path.json` | Save under `cursor-claude-common/output/` |
| `--list-levels` | Show prior level folders scanned (no vocabulary) |
| `--include-target` | Include current level WordPairs + translations |

Script: `tools/gather_prior_level_words.py`

**Consumed** (exclude when picking words for the level being audited):

- All entries from the script output (deduplicated, case-insensitive)
- Sources only: `translations.json` → `english_word`; `WordPairs` → `english_words`

**Still available:**

- Master-list words not in the script output for this `{level-id}`
- Words only in question sentences, distractors, or image labels (unless also in WordPairs/translations)
- Words used in **later** flow levels (script scans **prior** levels only)

**Image-taught words are still “available” for translation slots in the tracking sense**, but see **Image questions** below — do not recommend translation slots for nouns already introduced by image MCQ in the same level.

Refresh global CSV level counts after JSON edits:

```bash
python3 tools/update_final_word_counts_from_levels.py
```

## Final word CSV files (6)

Under `cursor-claude-common/references/final words/`:

| File | Typical POS |
|------|-------------|
| `verbs-400.csv` | verbs (prioritize) |
| `adjectives-300.csv` | adjectives |
| `adverbs-150.csv` | adverbs |
| `prepositions.csv` | prepositions |
| `conjunctions.csv` | conjunctions |
| `auxiliaries.csv` | auxiliaries |

## Oxford 3000

`cursor-claude-common/references/remove-word-list-references/3000 words oxford.txt`

Entries include CEFR tags (e.g. `A1`, `A2`, `B1`, `B2`). Prefer **A1** when context allows and the word is still unused.

## Example invocation

User: *"Audit the bedroom level using the quiz level audit skill"*

Agent:

1. Read this skill + project rules
2. `python3 tools/gather_prior_level_words.py bedroom --format json -o cursor-claude-common/output/bedroom-prior-words.json`
3. Load `bedroom/questions.json`, `bedroom/translations.json`, flow position
4. Build available words (CSVs + Oxford minus prior-words JSON)
5. List image-taught words from image templates; build translated-word inventory; **scan for within-level duplicate answer words**; suggest vocabulary swaps
6. Report inline (or `{level-id}-audit.md` if requested) → wait for approval to apply fixes

## Within-level word repetition

**Required** for every audit. Goal: each level should not drill the same answer word or phrase in multiple questions unless intentional (rare).

### What to extract

| Template | Answer-bearing content |
|----------|------------------------|
| ConvoTemplate-1 | `answer` |
| ClozeSequence | `answer` / `answers` |
| DialogueCompletion | `answer` (key verbs/adjectives/adverbs) |
| SentenceBuilder | `correct_order` |
| WordPairs | `english_words` |
| AppearDisappear | main teaching words in `words` (verbs, adverbs, key phrases) |
| GrammarForm | `answer` |
| imageQuizTemplate-1/2 | `imageName` |

### Normalization

- Lowercase; group obvious inflections (`brush` / `brushes`; `wash` / `washing`)
- Match multi-word phrases (`brush teeth`, `wash hands`, `take a shower`)
- Ignore pure function-word overlap alone (`I`, `the`, `my`, `a`) unless the whole phrase repeats

### Severity

| Level | When |
|-------|------|
| **High** | Same lemma or phrase is an answer / main AppearDisappear focus in **2+ questions** |
| Medium | Answer word also central in another question’s full sentence |
| Low | Word only in distractors, or shared function words |

### Fix strategy

- Keep the question that **tests** the word (Cloze, Convo blank, WordPairs)
- Rewrite the duplicate (often AppearDisappear or second dialogue) with unused level vocabulary
- Do not suggest object nouns for translation swaps — use verbs/adjectives/adverbs (see **Vocabulary swap suggestions**)

### Example (bathroom)

| Word / phrase | Questions | Severity |
|---------------|-----------|----------|
| brush / brushes + teeth | Q1 AppearDisappear “I brush my teeth…”, Q7 Cloze `brushes` … `teeth` | **High** |
| wash / hands | Q3 Convo `wash`, Q12 Cloze “wash my face” | Medium |
| shower | Q2 image, Q10/Q13 dialogue | Medium (image + text) |

**Q1 replacement example:** change AppearDisappear to a non-overlapping bathroom routine, e.g. “I dry my hands with a towel.” (introduces **dry** as a verb; Q7 keeps comb/brush teeth).

## Image questions

Always audit `imageQuizTemplate-1` and `imageQuizTemplate-2` when present — never skip because a level is “mostly vocabulary.”

| Check | template-1 | template-2 |
|-------|------------|------------|
| Hero image | `imageName` file exists in level folder | same |
| Distractors | 3 text strings; on-theme; plausible-but-wrong | 3 **image stems**; each file exists in folder |
| Vocabulary | Add `imageName` to **image-taught words** list | same |

**Image-taught words** = all `questionData.imageName` values from both templates (normalize hyphen stems to labels for the report).

**Translation slot rule:** Nouns introduced by image MCQ do not need a row in `translations.json` or WordPairs. Reserve translation slots for verbs, adjectives, adverbs, and function words taught in **text** templates (Convo, Cloze, Dialogue, SentenceBuilder, AppearDisappear, WordPairs). **Vocabulary swap suggestions must not be object nouns** — if a word is a concrete thing/object, add or use an image question instead.

Example (bathroom): `towel`, `shower`, `sink`, `comb`, `toothbrush`, `bathtub` are image-taught — do **not** suggest `towel` as a translation-slot replacement even though it appears in dialogue text.

Words only in **distractors** (image or dialogue) are not formally introduced — good candidates to **promote** via a text question + translation slot swap.

## Translated-word inventory

Build three lists for the target level:

1. **Tracked** — `translations.json` → `english_word`; WordPairs → `english_words`
2. **Image-taught** — image template `imageName` values (see above)
3. **Introduced vocabulary** — from non-image templates:
   - **Answer words** — Convo, Cloze, Dialogue, GrammarForm, WordPairs
   - **Sentence-introduced** — AppearDisappear `words`, SentenceBuilder `correct_order` (valid for `translations.json` **without** a blank answer)

### AppearDisappear & SentenceBuilder → translations

These templates have **no answer field**, but words in their sentences are formally taught. They **may** and often **should** have matching `translations.json` entries:

| Template | Example sentence | Valid translation entry |
|----------|------------------|---------------------------|
| AppearDisappear | “I feel **clean** after a long shower.” | `clean` (adjective) |
| AppearDisappear | “I feel **fresh** after my shower.” | `fresh` or `to feel` |
| SentenceBuilder | “His hands are very **dirty**.” | `dirty` |

Do **not** require a blank/answer to justify the translation row. Do **not** flag these entries as “wasted” for lacking an answer slot.

Cross-check:

| Issue | Meaning |
|-------|---------|
| Missing tracking | Introduced word (answer **or** AppearDisappear/SentenceBuilder sentence) not tracked and not image-taught |
| Redundant slot | Tracked word duplicates image-taught noun |
| Wasted slot | Tracked word not introduced anywhere (only in distractors / unused) |
| Weak slot | Generic tracked word; better context-fit word in same level sentences |
| Prior repeat | Tracked word already in prior levels’ translations/WordPairs |

Only **translations.json** and **WordPairs** count as “consumed” for prior levels and word-list tracking. Image labels and sentence-only words do not count until added to those files.

## Vocabulary swap suggestions

Required when auditing levels with `translations.json` and/or WordPairs.

**Goal:** Replace weak, wasted, or redundant **tracked** words with **unused**, **context-fit**, **A1-preferring** words from the available list.

**Selection rules:**

1. Not in `gather_prior_level_words.py` output for this level
2. Fits level theme and flow position (grammar + vocabulary)
3. Prefer A1 from final-word CSVs / Oxford 3000
4. **Not** already image-taught in this level
5. Tie to a **text question** — as an answer **or** in AppearDisappear / SentenceBuilder sentence; state question edits in the report
6. **Not an object noun** — only verbs, verb phrases, adjectives, adverbs, prepositions, conjunctions, or similar. Never suggest concrete object nouns for translation/WordPairs slots (introduce those via image questions instead)

**Typical swaps:**

| Weak / redundant tracked | Better replacement | Why |
|--------------------------|-------------------|-----|
| Generic verb (`to forget`) | `always`, `before` | Already in Convo sentences, unused prior, adverb/preposition |
| Generic linker (`then`) | `before`, `always` | Same Convo; rewrite Cloze to test new word |
| Distractor-only noun (`soap`) | `carefully`, `warm` | Never answered; promote adverb/adjective — not another noun |
| Generic WordPairs adj (`hot`) | `warm` | Shower/water context; pair with `cold` |
| Image-taught noun (`towel`) | *(do not swap in)* | Already covered by image MCQ |
| Any unused object noun | *(do not swap in)* | Object nouns → image questions, not translation slots |

Report column **Question change** when the swap requires editing Cloze, Convo, WordPairs, or `translations.json` together.

## Audio file stems

Audio fields on each question (see `page-designs-and-templates.md`):

| Field | Used by |
|-------|---------|
| `audio_file` | Most templates — one clip when question appears |
| `audio_file1` | ConvoTemplate-1 line 1; DialogueCompletion question line |
| `audio_file2` | ConvoTemplate-1 line 2; DialogueCompletion answer line |

**Audit rule:** For every `audio_file` / `audio_file1` / `audio_file2` in `questions.json`, verify the stem matches the spoken content (answers filled in). **Do not** look for audio files on disk — only validate names in JSON. Audio clips are recorded outside the audit workflow.

**How to derive expected stem (heuristic):**

1. Build the full English sentence (punctuation as in JSON).
2. Lowercase, replace spaces and punctuation with hyphens, drop apostrophes.
3. Often append `-convo` for conversation templates.

Examples:

| Question snippet | Filled text | Typical stem |
|------------------|-------------|--------------|
| Cloze Q3 | It is too dark in the room. | `it-is-too-dark-in-the-room-convo` |
| Convo line1 + answer `very` | I am very tired! | `i-am-very-tired-convo` |
| Convo line2 + answer `very` | Yes, it is very late! Go to sleep! | `yes-it-is-very-late-go-to-sleep-convo` |

Flag when:

- Stem words disagree with current answer (question changed, stem not updated)
- Stem covers only part of a multi-blank Cloze sentence
- Question has no audio field but spoken text would benefit from one (optional note only)

## Template quick reference

| Template | Distractor rules |
|----------|------------------|
| `imageQuizTemplate-1` | 3 text `wrongAnswers` (or `distractors`); any string OK if on-theme |
| `imageQuizTemplate-2` | 3 `wrongAnswers` = image stems in level folder |
| `ConvoTemplate-1` | `answer` + 3 `distractors` |
| `ClozeSequence` | `sentence` with `____` blanks; `answer` or `answers`; `distractors` pool |
| `WordPairs` | `english_words` + embedded `local_translation` per language |
| `GrammarForm` | `sentence` with blank; `answer` + `distractors` |
| `DialogueCompletion` | line + `answer` + distractors |
| `AppearDisappear` | `words` sentence; top-level `translation` map (sibling to `questionData`) |
| `SentenceBuilder` | `correct_order` word sequence |

Full schema: `cursor-claude-common/context/page-designs-and-templates.md`

## Distractor quality (template-1 and convo)

Good:

- Same semantic field as the question (other fruits for a fruit image; other buildings for a bank image)
- Plausible but clearly wrong for the shown image/sentence
- Similar length/register when possible

Bad:

- Random household filler unrelated to theme (`soap`, `fork`, `napkin` on animal/bird questions)
- Misspellings used as traps (unless explicitly teaching spelling)
- Distractor equals correct answer
- For template-2: image stem not in folder

## Capitalization & punctuation conventions

- **Dialogue / full sentences:** ending `.` or `?` as appropriate
- **GrammarForm / ClozeSequence:** match sentence punctuation in `sentence` field
- **Image MCQ labels:** app title-cases option text in UI; stems often lowercase in JSON (`imageName` basenames)
- **WordPairs:** consistent casing per language (e.g. German nouns capitalized)

## Supported translation languages

`tr`, `es`, `fr`, `de`, `it`, `pt`, `ru`, `zh`, `ja`, `ko`, `ar`, `hi`

Per-question inline maps (`translation`, `line1_translation`, etc.) show when `userLanguage != 'en'`. `WordPairs` and `ClozeSequence` have no per-question translation toggle support beyond embedded WordPairs maps.
