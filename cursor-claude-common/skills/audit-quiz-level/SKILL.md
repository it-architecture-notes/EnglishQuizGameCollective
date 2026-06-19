---
name: audit-quiz-level
description: >-
  Audit and improve a quiz level's questions.json and translations.json: question
  quality, word selection, grammar progression, A1-first vocabulary from final-words
  CSVs and Oxford 3000 list, translation accuracy, translated-word inventory vs image
  and text questions, swap suggestions (verbs/adjectives/adverbs only — not object
  nouns), within-level duplicate answer-word checks, image quiz checks, distractors,
  punctuation, and question order. Runs
  tools/gather_prior_level_words.py for prior WordPairs and translation usage, and
  audio stem name alignment in questions.json (no .m4a files required). Use when the
  user asks to review, audit, check, or improve a level, questions.json, translations,
  WordPairs, distractors, audio file names, image questions, or vocabulary coverage
  for English Quiz Game Collective.
disable-model-invocation: true
---

# Audit Quiz Level

Audit one quiz level at a time. Read project rules in `cursor-claude-common/rules/rules.md` first (one issue at a time, plan before implement unless user says fix/apply).

## Scope

Target folder (typical):

```
app/assets/quiz-data/levels/implemented/{level-id}/
├── questions.json
└── translations.json   (when level has vocabulary translations)
```

Also consult:

| Resource | Path |
|----------|------|
| Level order / placement | `app/assets/data/flow/game-flow.json` |
| Template schemas | `cursor-claude-common/context/page-designs-and-templates.md` |
| Parsers | `app/lib/models/level_config.dart` |
| Final word CSVs (6 files) | `cursor-claude-common/references/final words/` |
| Oxford 3000 word list | `cursor-claude-common/references/remove-word-list-references/3000 words oxford.txt` |
| Word usage tracking script | `tools/update_final_word_counts_from_levels.py` |
| **Prior-level consumed words** | `tools/gather_prior_level_words.py` — **run this first** |

## Audit criteria

Check every question from these perspectives:

- Question quality, word selection, grammar quality keeping the level name and context in mind. Not repeating words from previous levels too much, using new words from the 6 csv (final words file) and 3000 oxford words text files so that game covers more words.
- **Prior-level word reuse limit:** 1–2 words from prior levels may appear as key teaching words in the current level's questions (e.g. in a sentence stem or dialogue line) when strongly relevant to the current context — but they must **not** be re-added to `translations.json` (already consumed). If a word has already appeared as a key teaching word in **2 prior levels**, do not use it in the current level. Global maximum: **2 total appearances** across all levels as a key teaching word. Using a word three times leaves no room for new vocabulary. **Phrasal verbs are independent entries:** a phrasal verb such as `get up` or `turn off` does not count as consuming its base verb — `get` and `turn` remain available for use in other levels' translations independently. The same applies in reverse: having `get` in translations does not block `get up` from being used in another level.
- if a word is in either wordpairs array or translations.json array it is used  previously, otherwise it's open to use again. any level later using it does not mean it cannot be used in this level.
- Mostly using verbs first, then adjectives and adverbs etc.
- Giving more basic words higher priority and trying to consume A1 words first so that learners learn common and necessary words first. Balancing the context words with common word e.g. not using B2 word that is appropriate for the context when there are many A1 words pending in the list to be consumed.
- We need to keep grammar difficulty increasing in levels, so the first levels must be easier and then sentences and grammar gets complex as the player advances. Keep the level place in mind.
- Translations must be correct in word pairs and translation files. There must not be more than 15 words in translations can be less approx 12.
- The word we translate can be counted as that can be dropped from the list of selection. Otherwise that word is still open to use. So the available words list is complete list in files minus the ones that are in the translation list (word pair or translations json file) in previous levels.
- Check distractors and provide better suggestions.
- **Always include image questions** (`imageQuizTemplate-1`, `imageQuizTemplate-2`) in the audit — image presence, on-theme distractors, and which nouns they already teach (see **Image questions** below).
- **Translated-word inventory:** cross-check every `english_word` in `translations.json` and every `english_words` entry in `WordPairs` against introduced vocabulary (answers **plus** AppearDisappear / SentenceBuilder sentences), image-taught labels, and prior-level consumption. Words in AppearDisappear or SentenceBuilder **do not need a blank answer** to justify a translation row. Flag wasted, redundant, or weak slots; suggest **replacements** from unused A1/context words (see **Vocabulary swap suggestions** below). Swap suggestions must **not** be object nouns — use verbs, adjectives, adverbs, prepositions, etc.
- **Within-level word repetition:** scan all questions in the level and flag when the same word (or same lemma / phrase, e.g. `brush` / `brushes` / `brush teeth`) appears in **more than one question**. Treat as **high priority** when the word is part of an **answer** — Convo `answer`, Cloze `answer`/`answers`, DialogueCompletion `answer`, SentenceBuilder `correct_order`, WordPairs `english_words`, or the main teaching focus of AppearDisappear `words`. Suggest a replacement question for the earlier or weaker duplicate (see **§2 Within-level repetition**).
- For every question that declares `audio_file`, `audio_file1`, or `audio_file2`, check that the **stem name in JSON** matches the question text (filled answers / spoken lines). Do **not** check whether `.m4a` files exist on disk — audio is recorded separately; only validate naming in `questions.json`. Flag mismatches and suggest renamed stems or question edits.
- You can change the order of questions if you see a need.
- Check capital words and punctuation for consistency too, e.g. closing periods and question marks.

## Workflow

### 1. Gather context

1. Read `questions.json` and `translations.json` (if present) for the target level.
2. Find the level's position in `game-flow.json`. Note the level index — earlier levels require simpler grammar and vocabulary.
3. **Run the prior-usage script** (do not hand-scan prior level JSON for consumed words):

   ```bash
   python3 tools/gather_prior_level_words.py {level-id} --format json
   ```

   Replace `{level-id}` with the target `iconImageName` (e.g. `bedroom`, `prepositions`).

   - Output is the **consumed words** set: every `english_word` from earlier levels' `translations.json` plus every `english_words` entry from earlier levels' `WordPairs` rows.
   - **Only these two sources count.** Words in sentences (ClozeSequence, AppearDisappear, ConvoTemplate, etc.) do **not** count as consumed unless they also appear in WordPairs or `translations.json`.
   - Optional: `--list-levels` to see which prior folders are included; `--include-target` to include the current level's WordPairs/translations in the export.
   - Save JSON to `cursor-claude-common/output/{level-id}-prior-words.json` when the audit will continue across turns.

4. Build **available words** = union of final-word CSVs + Oxford 3000 entries **minus** the consumed set from step 3.
5. Build **image-taught words**: every `questionData.imageName` from `imageQuizTemplate-1` and `imageQuizTemplate-2` (normalize stems to display labels, e.g. `hair-dryer` → “hair dryer”). These nouns are introduced visually — do **not** recommend spending a `translations.json` or WordPairs slot on them unless the user explicitly wants glosses for image labels.
6. Build **introduced vocabulary** from non-image templates:
   - **Answer words** — Convo blank, Cloze blank, DialogueCompletion answer, WordPairs list
   - **Sentence-introduced words** — key verbs, adjectives, adverbs, and phrases in **AppearDisappear** `words` and **SentenceBuilder** `correct_order` (these count as formally introduced even though there is no blank/answer field)
7. Cross-check tracked vs taught vocabulary (see **§3 Translated-word inventory**). Flag keywords from step 6 missing from translations/WordPairs, and translation slots that duplicate image coverage or are never tied to any question.
8. **Build a within-level word-repetition map** (see **§2 Within-level repetition**). Flag duplicate answer words and phrase overlaps before finishing the report.

### 2. Per-question review

Include **every** question, including all image templates.

For each question in `levelQuestions`:

| Check | Notes |
|-------|-------|
| Template fit | Sentence/content matches level theme and template type. For SentenceBuilder: `correct_order` must be ≤ 7 words — flag if longer. |
| Word choice | Prefer unused A1; verbs > adjectives > adverbs; avoid over-repeating prior levels |
| Grammar | Appropriate for level position; no early past-perfect in mainLevel 1, etc. |
| Distractors | Plausible-but-wrong, same topic; not completely irrelevant. See template rules and distractor rules below |
| Capitalization & punctuation | Consistent periods/question marks; MCQ labels match convention |
| Translations | WordPairs embedded maps + `translations.json` entries correct for context |
| Answer–translation alignment | Key vocabulary in **text** questions should have a matching entry in `translations.json` or WordPairs when it is an **answer** (Convo, Cloze, Dialogue) **or** appears in **AppearDisappear** `words` / **SentenceBuilder** `correct_order` — unless already covered by an **image question**. Flag missing tracking and redundant translation slots. **ClozeSequence and ConvoTemplate-1: only blank answer words qualify — words in the sentence stem and all distractors are excluded from translations.** |
| Within-level repetition | Word or phrase already tested as an answer (or main AppearDisappear focus) in another question in this level — see **Within-level repetition** |
| Image quiz (template-1/2) | Image file exists; distractors on-theme and plausible; template-2 stems exist in folder; record `imageName` for vocabulary inventory |
| Audio stem names | See **Audio alignment** below — compare JSON stems to filled question text; ignore file presence on disk |

**Audio alignment** (name match only — no `.m4a` required):

1. For each question with `audio_file` / `audio_file1` / `audio_file2`, reconstruct the spoken line:
   - **AppearDisappear / ClozeSequence:** full sentence with blanks filled from `answer` / `answers`
   - **ConvoTemplate-1:** each line with blank filled from `answer` (`audio_file1` → line1, `audio_file2` → line2)
   - **DialogueCompletion / GrammarForm / SentenceBuilder:** sentence with answer inserted
2. Compare the JSON **stem** (no extension) to that text:
   - Stems are usually lowercase, hyphenated, often suffixed `-convo`
   - Example: “It is **too** dark in the room.” → `it-is-too-dark-in-the-room-convo`
3. Report:
   - **Match** — stem reflects the filled sentence (minor article/preposition differences OK if intent is clear)
   - **Partial mismatch** — e.g. stem says “turn-on-the-lamp” but Cloze also covers “turn off the light”
   - **Stale stem** — JSON references old wording after question edits (e.g. “sleepy” vs current “tired”)
4. Do **not** require audio for image-only questions, templates without audio fields, or physical audio files in the level folder.

**Distractor rules by template:**

- **ClozeSequence:** each distractor must not fit ANY blank in the sentence naturally. Test mentally: can this word replace any answer and still produce grammatically/contextually valid English? If yes, it's a bad distractor.
- **ConvoTemplate-1:** the answer fills the same blank in both lines — all distractors must fail for both lines simultaneously. Adverb/adjective distractors often accidentally work in both slots; test all of them.
- **AppearDisappear:** distractors should be words plausibly associated with the sentence topic but not present in it. Avoid using the same word as the answer to an adjacent question.
- **DialogueCompletion:** all distractor options must be grammatically incorrect OR contextually wrong in the exact dialogue context. "Technically correct but different meaning" is not a good distractor.
- **GrammarForm:** distractors must be real English forms (not invented constructions like "have dreaming"). Use actual conjugations that are wrong for the grammatical context.

**Image template distractor rules:**

- `imageQuizTemplate-1`: distractors are **text strings**; they do **not** need to exist in the level folder. Must be semantically related (e.g. other kitchen tools for a kitchen level).
- `imageQuizTemplate-2`: distractors are **image file stems**; each must exist as `.png` (etc.) in the level folder.

**ClozeSequence answer key:** accepts `"answer"` (string or array) or `"answers"` (array). Blank count must match answer count.

**Within-level repetition** (required check):

1. Extract **answer-bearing words** from every question in `levelQuestions`:

   | Template | Extract from |
   |----------|--------------|
   | ConvoTemplate-1 | `answer` (+ note verb/noun used in both lines) |
   | ClozeSequence | each entry in `answer` / `answers` |
   | DialogueCompletion | content words in `answer` (especially verbs, adjectives, adverbs) |
   | SentenceBuilder | tokens in `correct_order` (skip articles if only function-word overlap) |
   | WordPairs | each `english_words` entry |
   | AppearDisappear | main teaching words in `words` sentence (verbs, key adverbs, repeated phrases — not every stop word) |
   | GrammarForm | `answer` |
   | imageQuizTemplate-1/2 | `imageName` (same noun taught twice = flag) |

2. Normalize for comparison: lowercase; treat verb forms as same lemma when obvious (`brush` / `brushes` / `brushing`; `comb` / `combs`); treat multi-word phrases as units when identical (`brush teeth`, `wash hands`).

3. **Severity:**

   | Severity | Condition |
   |----------|-----------|
   | **High** | Same lemma or phrase is an **answer** (or AppearDisappear main focus) in **2+ questions** — e.g. Q1 AppearDisappear “brush my teeth” + Q7 Cloze answer `brushes` … `teeth` |
   | **Medium** | Same content word in one answer and prominently in another question’s sentence (not only a distractor) |
   | **Low** | Same word only in distractors/wrongAnswers across questions, or unavoidable function words (`I`, `the`, `my`) |

4. For each **high** duplicate, report both question numbers and suggest replacing **one** question’s sentence/answers with unused level vocabulary. Prefer keeping the question that **tests** the word (Cloze/Convo) and rewriting the AppearDisappear or duplicate dialogue.

5. Include a summary table in every audit report (see **Output**).

**Image questions** (always audit when present):

1. **Inventory:** List each `imageName` and whether the `.png` (or equivalent) exists in the level folder.
2. **`imageQuizTemplate-1`:** Hero `imageName` must exist. Three text `wrongAnswers` must be on-theme and plausible-but-wrong (any string OK — not required in folder). Note each taught noun for the vocabulary inventory.
3. **`imageQuizTemplate-2`:** Hero `imageName` and all three `wrongAnswers` must be **image file stems** that exist in the level folder.
4. **Vocabulary role:** Image questions formally introduce **nouns/objects** for the level. Do not suggest a `translations.json` / WordPairs entry for a word already taught this way (e.g. `towel` via template-2) — use translation slots for verbs, adjectives, adverbs, and phrases from **text** questions instead.
5. **Distractor-only words:** Words appearing only as image or dialogue **distractors** are not “introduced”; they may still be good **swap targets** if promoted into a text question + translation slot.

### 3. Translated-word inventory

After gathering prior words, image-taught words, and introduced vocabulary, produce a tracked-vocabulary table:

| Source | english_word | Introduced in level? | Covered by image quiz? | In prior levels? | Notes |
|--------|--------------|----------------------|------------------------|------------------|-------|
| translations / WordPairs | … | yes / no | yes / no | yes / no | … |

**”Introduced in level” = yes — per template:**

| Template | What qualifies for translations.json |
|----------|--------------------------------------|
| **ClozeSequence** | Blank answer word(s) only — no sentence stem words |
| **ConvoTemplate-1** | Blank answer word only — no sentence stem words |
| **GrammarForm** | Key teaching words from the question sentence (blank AND non-blank positions) — not distractors |
| **AppearDisappear** | Key teaching words from the `words` sentence (verbs, adjectives, adverbs, phrases — not every stop word) |
| **SentenceBuilder** | Key teaching words from `correct_order` (not articles/`the`/`a`/`an` alone). **Max 7 words** in `correct_order` — flag and suggest a shorter sentence if exceeded. |
| **DialogueCompletion** | Key teaching words from the `line1` question OR the `answer` — not distractors |
| **WordPairs** | Any entry in `english_words` |
| **imageQuizTemplate-1/2** | `imageName` noun (image-taught; use for image-taught words list, not translations) |
| **Any template** | **Distractors / wrongAnswers NEVER qualify — for any template, ever** |

**AppearDisappear / SentenceBuilder rule:** Key teaching words (verbs, adjectives, adverbs, phrases — not every stop word or article) from these sentences **may** appear in `translations.json` without being a blank answer. Do **not** flag them as wasted slots. Do flag as **missing tracking** when a key word in the sentence is worth glossing (e.g. AppearDisappear “I feel **clean** after a shower” → add **clean** to translations; SentenceBuilder “His hands are very **dirty**” → **dirty** in translations is valid).

**GrammarForm rule:** Key teaching words from the full question sentence (blank or non-blank) may appear in `translations.json`. Distractors never qualify. Example: GrammarForm “When do you ____ your homework?” — `homework` and the blank answer `do` qualify as key teaching words; distractors `was` / `doing` / `are doing` do not.

**DialogueCompletion rule:** Key teaching words from either the `line1` question or the `answer` field may appear in `translations.json`. Distractors never qualify. Example: DialogueCompletion line1 “How long can I keep this book?” / answer “You can **borrow** it for three weeks.” — `borrow` (from answer) and `keep` (key verb from line1) qualify; distractors do not.

**ClozeSequence / ConvoTemplate-1 rule:** Only the **blank answer word(s)** qualify for `translations.json`. Words in the sentence stem (non-blank positions) and all distractors are **never** added to translations, even if they are important vocabulary. Example: ClozeSequence “It is ______ to _____ this book — another reader **reserved** it.” — `reserved` is in the sentence stem, not a blank, so `to reserve` must **not** be added to translations. Example: ConvoTemplate-1 “This book is **due** tomorrow. Can I _____ it?” — `due` is in the sentence stem, not the blank, so `due` must **not** be added to translations.

**Universal distractor rule:** Distractors and `wrongAnswers` from **any** template — ClozeSequence, ConvoTemplate-1, GrammarForm, AppearDisappear, SentenceBuilder, DialogueCompletion, imageQuizTemplate-1/2 — **never** qualify for `translations.json`, regardless of how important or relevant the word seems.

**Flag:**

- **Missing tracking** — introduced keyword (answer, AppearDisappear, or SentenceBuilder) not in `translations.json` or WordPairs and not covered by an image question
- **Redundant slot** — translation/WordPairs entry duplicates a noun already taught by image MCQ
- **Wasted slot** — tracked word not introduced anywhere in the level (not an answer, not in AppearDisappear/SentenceBuilder sentence, not image answer — only in a distractor or unused). Common sources: words only in ClozeSequence/ConvoTemplate sentence stems, words only in distractors, words never appearing in any question at all. **Remove these from translations.json without replacement unless a question edit can promote them to a blank answer.**
- **Weak slot** — generic tracked word while unused, context-fit words appear in the same level’s sentences
- **Prior repeat** — tracked word already consumed in an earlier level’s translations/WordPairs (prefer fresh A1 from available list)
- **Over-reused word** — a word that has appeared as a key teaching word in 2 or more prior levels should not be used again in any question (sentence stem, answer, or otherwise). Flag and suggest replacement with unused vocabulary.

### 4. Vocabulary swap suggestions

**Required output section** when the level has `translations.json` and/or WordPairs. For each weak, wasted, or redundant tracked word, suggest a **replacement** from the **available words** list that:

1. Was **not** consumed in prior levels (per `gather_prior_level_words.py`)
2. Is **more suitable** to the level theme and grammar position
3. Prefer **A1** from final-word CSVs / Oxford 3000 when possible
4. Is **not** already taught by an image question in this level
5. Appears (or can appear) in a **text question** — as an answer **or** in AppearDisappear / SentenceBuilder sentence text; include question edits if the swap requires them
6. Is **not an object noun** — swap suggestions must be verbs, verb phrases, adjectives, adverbs, prepositions, conjunctions, or other non-noun vocabulary. Do **not** suggest concrete object nouns (e.g. `towel`, `soap`, `mirror`, `bathrobe`) even if unused and context-fit; those belong in **image questions**, not translation slots

**Prefer replacing:**

- Generic verbs/adverbs (`to forget`, `then`) → words already in sentence answers but untracked (`always`, `before`, `carefully`)
- Distractor-only tracked nouns (`soap` never answered) → adjectives/adverbs from the level’s sentences (e.g. `carefully`, `warm`) — **not** another object noun
- Generic WordPairs adjectives (`hot`) → context-fit pairs (`warm` / `cold` for water/shower)

**Do not suggest as translation-slot replacements:**

- Nouns already covered by `imageQuizTemplate-1` or `imageQuizTemplate-2` in the same level
- **Any object noun** — concrete things/objects (tools, furniture, body-care items, places, etc.). Object nouns are introduced via image quizzes; translation slots are for verbs, adjectives, adverbs, and function words only

Report format:

| Remove / replace | Suggest | Reason | Question change (if any) |
|------------------|---------|--------|--------------------------|

Wait for user approval before applying swaps (unless user says fix/apply).

### 5. Translations file

- Target **~12 entries**, **max 15** in `translations_list`.
- Each `english_word` should map correctly across all supported languages (`tr`, `es`, `fr`, `de`, `it`, `pt`, `ru`, `zh`, `ja`, `ko`, `ar`, `hi`).
- Prefer phrase-level translations where the question uses a phrase (not bare dictionary gloss when context differs).

**Common per-language errors to check:**

| Language | Common mistake | Correct approach |
|---|---|---|
| French (fr) | `"pour"` (= for) used instead of `"à"` (= to) in indirect object phrases | Use `"à moi"`, `"à toi"`, `"à nous"`, `"à eux"` |
| Spanish (es) | Capital mid-phrase (`"A usted"`); missing accent (`"a el"` vs `"a él"`); formal/informal mismatch (`"usted"` vs `"tú"`) | Use informal to match other languages; always accent `él` |
| Hindi (hi) | Gender-neutral words duplicated (`"उसे/उसे"`); overly wordy forms (`"हम लोगो को"` instead of `"हमें"`) | Use the simpler natural form; Hindi him/her is gender-neutral |
| German (de) | Conjunctions capitalized mid-phrase (`"Und"` should be `"und"`) | Only capitalize sentence-initial words |
| Arabic (ar) | Verb conjugated in 3rd person singular when a neutral infinitive form is needed | Prefer verbal noun / masdar form for infinitive translations |
| Chinese (zh) | Inconsistent use of `"从"` vs `"给"` for directional/recipient phrases | Be consistent within a WordPairs set |

### 6. Question order

Reorder when grammar or vocabulary progression within the level would improve (simple → complex, concrete → abstract). Document any reorder in the report.

### 7. Output

Default: **report inline in chat**, wait for approval before editing JSON (per project rules). Write to `cursor-claude-common/output/{level-id}-audit.md` only if explicitly requested.

Use this structure:

```markdown
# {Level title} audit

## Level context
- Flow position: mainLevel N, index …
- Theme: …

## Summary
- Questions reviewed: N
- High-priority fixes: …
- Translation fixes: …
- Translation slot / swap suggestions: …
- Within-level duplicate answer words: …
- Image questions reviewed: N

## Within-level word repetition
| Word / phrase | Questions | Severity | Suggestion |
|---------------|-----------|----------|------------|
| … | Q1, Q7 | high | Replace Q1 sentence with … |

## Image questions
| Q | template | imageName | image exists | distractor issues |
|---|----------|-----------|--------------|-------------------|
| … | … | … | yes / no | … |

**Image-taught words (nouns):** …

## Translated-word inventory
| Source | english_word | Introduced? | Image covered? | Issue |
|--------|--------------|-------------|----------------|-------|
| … | … | yes / no | … | … |

*(Introduced = answer, AppearDisappear `words`, or SentenceBuilder `correct_order`)*

## Vocabulary swap suggestions
| Remove / replace | Suggest | Reason | Question change |
|------------------|---------|--------|-----------------|
| … | … | … | … |

## Question-by-question

### Q1 — {template}
- **Current:** …
- **Issues:** …
- **Suggestion:** …
- **Distractors:** current → suggested

(repeat)

## Translations
| english_word | Issue | Suggested fix |
|--------------|-------|---------------|

## Audio stem alignment
| Q | JSON stem | Filled line / issue |
|---|-----------|---------------------|
| … | … | match / partial / stale |

## Recommended question order
(only if change suggested)

## Words consumed / suggested from available list
- Prior words source: output of `gather_prior_level_words.py` for this level
- Suggested new A1 candidates from available list: …

When user says **fix**, **apply**, or **implement**, patch JSON only for approved items. Validate JSON after edits.

## Priority order for fixes

1. Wrong translations (high confidence)
2. **Within-level duplicate answer words** (same lemma/phrase tested in 2+ questions)
3. Invalid JSON / template constraint violations (e.g. template-2 missing images)
4. Grammar too hard for level position
5. Bad distractors (irrelevant or ambiguous)
6. Audio stem name mismatches (JSON vs question text)
7. Missing translation tracking for text-answer words
8. Vocabulary swap suggestions (weak/redundant translation slots)
9. Word selection / A1 coverage improvements
10. Image quiz issues (missing files, off-theme distractors)
11. Punctuation and capitalization
12. Question reordering

## Do not

- Check for `.m4a` / `.mp3` files on disk or generate audio assets
- Commit unless explicitly asked
- Work on `main` branch
- Add tests or speculative features
- Expand `translations_list` beyond 15 entries
- Suggest **object nouns** as vocabulary swap replacements (use image questions for concrete nouns)

## Additional reference

See [reference.md](reference.md) for CSV filenames, template quick reference, word-list tooling, **within-level repetition**, **translated-word inventory**, **vocabulary swap rules**, **image question checks**, **audio stem checks**, and **`gather_prior_level_words.py` usage**.
