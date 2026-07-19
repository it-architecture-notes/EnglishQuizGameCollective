---
name: audit-quiz-level
description: >-
  Audit and improve a quiz level's questions.json and translations.json: question
  quality, word selection, grammar progression, A1-first vocabulary from final-words
  CSVs and Oxford 3000 list, translation accuracy, translated-word inventory vs image
  and text questions,   swap suggestions (verbs/adjectives/adverbs only — not object
  nouns), unused reference-word opportunities for the level context, within-level duplicate
  answer-word checks, image quiz checks, distractors (mandatory validation — no distractor may be
  suitable as a correct answer; prefer prior-level consumed vocabulary only after validity passes),
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
| LanGeek common nouns | `cursor-claude-common/references/remove-word-list-references/langeek-500-most-common-nouns.txt` |
| Word usage tracking script | `tools/update_final_word_counts_from_levels.py` |
| **Prior-level consumed words** | `tools/gather_prior_level_words.py` — **run this first** |

## Audit criteria

Check every question from these perspectives:

- Question quality, word selection, grammar quality keeping the level name and context in mind. Not repeating words from previous levels too much, using new words from the 6 csv (final words file), Oxford 3000, and LanGeek common nouns reference files so that game covers more words.
- **Prior-level word reuse limit:** 1–2 words from prior levels may appear as key teaching words in the current level's questions (e.g. in a sentence stem or dialogue line) when strongly relevant to the current context — but they must **not** be re-added to `translations.json` (already consumed). If a word has already appeared as a key teaching word in **2 prior levels**, do not use it in the current level. Global maximum: **2 total appearances** across all levels as a key teaching word. Using a word three times leaves no room for new vocabulary. **Phrasal verbs are independent entries:** a phrasal verb such as `get up` or `turn off` does not count as consuming its base verb — `get` and `turn` remain available for use in other levels' translations independently. The same applies in reverse: having `get` in translations does not block `get up` from being used in another level.
- if a word is in either wordpairs array or translations.json array it is used  previously, otherwise it's open to use again. any level later using it does not mean it cannot be used in this level.
- Mostly using verbs first, then adjectives and adverbs etc.
- Giving more basic words higher priority and trying to consume A1 words first so that learners learn common and necessary words first. Balancing the context words with common word e.g. not using B2 word that is appropriate for the context when there are many A1 words pending in the list to be consumed.
- **Grammar progression:** grammar is aggregated into 4 macro-bands (Parts), each spanning several MLs (see table). Levels may use grammar from **the current Part and all earlier Parts**; they **must not** use grammar aggregated into a **later** Part. See **Grammar progression by mainLevel**.
- Translations must be correct in word pairs and translation files. There must not be more than 15 words in translations can be less approx 12.
- The word we translate can be counted as that can be dropped from the list of selection. Otherwise that word is still open to use. So the available words list is complete list in files minus the ones that are in the translation list (word pair or translations json file) in previous levels.
- Check distractors and provide better suggestions. **Every distractor in every question must be validated** — see **Distractor validity (mandatory)** below. **Prefer distractors drawn from previously used vocabulary** (prior levels' `translations.json` + WordPairs — see **Prior-vocabulary distractors** below) only when they still **fail** the validity test.
- **Always include image questions** (`imageQuizTemplate-1`, `imageQuizTemplate-2`) in the audit — image presence, on-theme distractors, and which nouns they already teach (see **Image questions** below).
- **Translated-word inventory:** cross-check every `english_word` in `translations.json` and every `english_words` entry in `WordPairs` against introduced vocabulary (answers **plus** AppearDisappear / SentenceBuilder sentences), image-taught labels, and prior-level consumption. Words in AppearDisappear or SentenceBuilder **do not need a blank answer** to justify a translation row. Flag wasted, redundant, or weak slots; suggest **replacements** from unused A1/context words (see **Vocabulary swap suggestions** below). Swap suggestions must **not** be object nouns — use verbs, adjectives, adverbs, prepositions, etc.
- **Unused reference-word opportunities:** if in your opinion there are better unused words in the references that suit the context, mention them in the audit review (see **§4b Unused reference-word opportunities** below). This is separate from fixing broken slots — proactive suggestions only.
- **Within-level word repetition:** scan all questions in the level and flag when the same word (or same lemma / phrase, e.g. `brush` / `brushes` / `brush teeth`) appears in **more than one question**. Treat as **high priority** when the word is part of an **answer** — Convo `answer`, Cloze `answer`/`answers`, DialogueCompletion `answer`, SentenceBuilder `correct_order`, WordPairs `english_words`, or the main teaching focus of AppearDisappear `words`. Suggest a replacement question for the earlier or weaker duplicate (see **§2 Within-level repetition**).
- For every question that declares `audio_file`, `audio_file1`, or `audio_file2`, check that the **stem name in JSON** matches the question text (filled answers / spoken lines). Do **not** check whether `.m4a` files exist on disk — audio is recorded separately; only validate naming in `questions.json`. Flag mismatches and suggest renamed stems or question edits.
- You can change the order of questions if you see a need.
- Check capital words and punctuation for consistency too, e.g. closing periods and question marks.

## Grammar progression by mainLevel

Use `game-flow.json` → `mainLevel` for the level under audit.

### Core rule

Grammar is organized into **4 macro-bands (Parts)**, each spanning several mainLevels. Within a Part, **all** grammar aggregated into that Part is usable at **any** ML inside that Part's range — there is no further level-by-level gating inside a Part.

| Rule | Meaning |
|------|---------|
| **Allowed** | Any structure aggregated into the **current Part or an earlier Part**. Levels should **reuse and review** earlier-Part grammar freely, and may use any current-Part grammar regardless of which ML within the Part first "introduces" it. |
| **Forbidden** | Any structure aggregated into a **later Part**. Do not use in question stems, blank answers, GrammarForm `answer`, AppearDisappear / SentenceBuilder main focus, or distractors. |

**How to audit ML *N*:** find which Part contains ML*N* (see table below). **Allowed** = union of all Parts up to and including that Part. **Forbidden** = union of Parts strictly after it.

Levels may mix themes; grammar must still obey the allowed / forbidden sets above.

### Enforcement rules

| Label | Meaning | Audit action |
|-------|---------|--------------|
| **OK — review** | Structure aggregated into an **earlier Part** | No flag — expected recycling |
| **OK — in band** | Structure aggregated into the **current Part** (regardless of which ML within the Part it's associated with) | No flag — fully allowed anywhere in this Part |
| **Forbidden — not yet** | Structure aggregated into a **later Part** | Flag **high** anywhere in the question (stem, answer, main sentence, distractor) |

**Medley levels** (`medley-1`, …): vocabulary is user-fixed; **grammar follows the same allowed / forbidden rule** for the flow slot's `mainLevel`'s Part. Medleys typically **review** grammar from Part 1…current Part.

**Do not confuse:**

- **Passive adjective / participle** (`Is the library closed?`, `fresh bread`) ≠ passive voice (`was built`, `is made from`) — latter is Part 4
- **Directional / fixed phrases** (`turn left`, `sold out`) ≠ past-tense verb teaching
- **GrammarForm distractors** that are clearly wrong forms (e.g. `was celebrating` in a Part 1 level) — flag **low** only; prefer distractors built from **allowed** grammar

### Progression table — 4 Parts (aggregated bands)

| Part | ML range | Aggregated grammar (usable anywhere within this Part) |
|------|----------|---|
| **Part 1** | ML1–ML3 | Present Simple: **to be** (`am`/`is`/`are`); base present in short fixed phrases (`I go`, `we like`); Yes/No questions; WH-questions (`what`, `where`, `who`) • 3rd person (`she goes`); negatives (`don't`/`doesn't`); questions (`Do you…?`/`Does she…?`); possessives; prepositions • Imperative; modal **can** (ability); infinitives (`want to`/`need to`/`try to`/`like to`); fixed polite chunk `Could you…?` • Present Continuous (`is`/`are` + -ing); `There is`/`There are`; infinitive of purpose (`to protect`, `to pay`); `some`/`any` |
| **Part 2** | ML4–ML5 | Future: **will** and **be going to**; modal **must** (obligation); **comparative and superlative** adjectives • **First conditional** (`if` + present, `will` — e.g. "If I go, you will come.") |
| **Part 3** | ML6–ML8 | Past Simple: **was**/**were**; **regular** verbs (`-ed` — `walked`, `moved`, `folded`) • Past Simple: common **irregular** verbs (`went`, `had`, `came`, `made`, `started`, …); past questions and negatives (`Did you…?`, `didn't`) • Modals: **should** (advice); **have to**/**need to** (obligation); **could**/**might**/**may** (possibility — full teaching) |
| **Part 4** | ML9–ML12 (end) | Present Perfect (`have`/`has` + past participle); `Have you ever…?`; **would like to** • Past Continuous (`was`/`were` + -ing); **used to**; simple **passive voice** (`is made from`, `it is called`, `was built`) • Second conditional (`if` + past, `would`) • Present Perfect Continuous; **reported speech** (`He said that…`); third conditional (`If I had known…, I would have…`) |

### Quick examples

| Band | OK (allowed) | Forbidden (not yet) |
|------|----------------|---------------------|
| Part 1 (ML1–3) | `She is watching TV.` (Present Continuous, in-band) · `There is a bus stop near here.` (in-band) · `She likes music.` (to-be/base-present review) | `I went home.` (past → Part 3) · `We are going to watch a film.` (future → Part 2) |
| Part 2 (ML4–5) | `We are going to watch a film.` (new) · `If I go, you will come.` (first conditional, new) · `There is a bus stop near here.` (Part 1 review) | `I went home.` (past → Part 3) |
| Part 3 (ML6–8) | `She moved here.` / `He was happy.` (new) · `Did you finish?` / `They came early.` (new) · `I will apply tomorrow.` (Part 2 review) | `I have finished.` (present perfect → Part 4) |
| Part 4 (ML9–12) | `Have you ever been there?` (new) · `I was working when you called.` (past continuous, new) · `I went yesterday.` (Part 3 review) | — (top band, nothing forbidden) |

When auditing, state the level's **Part** (ML range), list structures found, mark each **OK — review**, **OK — in band**, or **Forbidden — not yet**.

## Distractor validity (mandatory)

**Every audit must check every distractor / `wrongAnswer` in the level.** Do not skip this step on a “quick pass” or when other fixes dominate the report.

### Core rule

A distractor is **invalid** if it could reasonably be accepted as a **correct answer** for that question — even when it is not the keyed answer, even when it is grammatical, and even when it is a prior-level word.

**Invalid ≠ merely “different word”.** Fixing bad grammar (e.g. rewriting an ungrammatical distractor into fluent English) does **not** make it valid — fluent distractors that still answer the question remain **invalid**.

### Required test (apply to each distractor)

1. **Insert the distractor** into every blank it could fill (Cloze: each blank; Convo: **both** lines; DialogueCompletion: as the reply; GrammarForm / image MCQ: as the chosen option).
2. Read the resulting sentence or reply aloud (or mentally).
3. Ask: **“If the player picked only this option, would a native speaker treat it as a reasonable correct response?”**
   - **Yes** → **invalid distractor** — flag **high** and suggest a replacement.
   - **No** → valid — only then consider prior-vocabulary preference and on-theme fit.

### What “not suitable as an answer” means

| Fail type | Example |
|-----------|---------|
| **Same meaning / synonym** | Cloze: `fell` / `tripped` when answer is `slipped` |
| **Valid alternate action** | Convo flood: `call` / `talk to` when answer is `warn` |
| **Valid alternate reply** | DialogueCompletion: *“To enjoy swimming with friends”* when asked *“Why do you go to the pool every day?”* |
| **Fits any Cloze blank** | `game` / `match` when answer is `race` |
| **Fits both Convo lines** | Adverb or verb that works in line1 **and** line2 when only one keyed `answer` is shared |

Distractors must fail on **meaning**, **collocation**, **grammar**, or **relevance to the specific question** — not merely sound natural in isolation.

### Coverage (no exceptions)

Apply the test to **all** of the following in **every** question:

- `distractors` on ClozeSequence, ConvoTemplate-1, AppearDisappear, DialogueCompletion, GrammarForm
- `wrongAnswers` on `imageQuizTemplate-1` and `imageQuizTemplate-2`

### Report requirement

In **every** audit (including quick / final passes):

1. State explicitly that distractors were validated with the test above.
2. In **Question-by-question**, list any **invalid** distractors found and give **replacement suggestions** that fail the answer test.
3. In **Summary**, count invalid distractors under **high-priority fixes** when any exist.

**Prior-vocabulary preference comes second:** a prior word that passes as an answer is still a **bad** distractor. A fresh on-theme word that clearly fails as an answer is acceptable.

## Workflow

### 1. Gather context

1. Read `questions.json` and `translations.json` (if present) for the target level.
2. Find the level's position in `game-flow.json`. Note **level index** and **`mainLevel`**. Find which **Part** contains that `mainLevel`. Build **allowed grammar** = current Part + all earlier Parts; **forbidden** = later Parts (see **Grammar progression by mainLevel**).
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
5. Scan **available words** for **context-fit candidates** not yet used in this level: prefer A1/A2 from final-word CSVs with `count` 0 (or low), verbs/adjectives/adverbs first, post-office/bank/etc. theme match. Hold these for **§4b Unused reference-word opportunities** in the report — even when the level has no broken translation slots.
6. Build **image-taught words**: every `questionData.imageName` from `imageQuizTemplate-1` and `imageQuizTemplate-2` (normalize stems to display labels, e.g. `hair-dryer` → “hair dryer”). These nouns are introduced visually — do **not** recommend spending a `translations.json` or WordPairs slot on them unless the user explicitly wants glosses for image labels.
7. Build **introduced vocabulary** from non-image templates:
   - **Answer words** — Convo blank, Cloze blank, DialogueCompletion answer, WordPairs list
   - **Sentence-introduced words** — key verbs, adjectives, adverbs, and phrases in **AppearDisappear** `words` and **SentenceBuilder** `correct_order` (these count as formally introduced even though there is no blank/answer field)
8. Cross-check tracked vs taught vocabulary (see **§3 Translated-word inventory**). Flag keywords from step 7 missing from translations/WordPairs, and translation slots that duplicate image coverage or are never tied to any question.
9. **Build a within-level word-repetition map** (see **§2 Within-level repetition**). Flag duplicate answer words and phrase overlaps before finishing the report.

### 2. Per-question review

Include **every** question, including all image templates.

For each question in `levelQuestions`:

| Check | Notes |
|-------|-------|
| Template fit | Sentence/content matches level theme and template type. For SentenceBuilder: `correct_order` must be ≤ 7 words — flag if longer. |
| Word choice | Prefer unused A1; verbs > adjectives > adverbs; avoid over-repeating prior levels |
| Grammar | Allowed = current Part + earlier Parts; forbidden = later Parts only. Mark each structure **OK — review**, **OK — in band**, or **Forbidden — not yet** |
| Distractors | **Mandatory:** validate **every** distractor / `wrongAnswer` with **Distractor validity (mandatory)** — none may be suitable as an answer. Then check on-theme fit. **Prefer prior-level consumed words** only among distractors that pass the validity test. See template rules and **Prior-vocabulary distractors** below |
| Capitalization & punctuation | Consistent periods/question marks; MCQ labels match convention |
| Translations | WordPairs embedded maps + `translations.json` entries correct for context |
| Answer–translation alignment | Key vocabulary in **text** questions should have a matching entry in `translations.json` or WordPairs when it is an **answer** (Convo, Cloze, Dialogue) **or** appears in **AppearDisappear** `words` / **SentenceBuilder** `correct_order` — unless already covered by an **image question**. Flag missing tracking and redundant translation slots. **ClozeSequence and ConvoTemplate-1: sentence-stem words now qualify too, not just blank answers — only distractors are excluded from translations.** |
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

**Prior-vocabulary distractors** (applies to all text templates and `imageQuizTemplate-1` `wrongAnswers`):

1. Build the **prior words** set from `gather_prior_level_words.py` output (every `english_word` in earlier levels' `translations.json` plus every `english_words` entry in earlier levels' WordPairs).
2. **First** run **Distractor validity (mandatory)** on every distractor — reject any that could be accepted as a correct answer.
3. **Then**, among distractors that pass the validity test, **prefer choices from the prior words** set — distractors are a chance to **review vocabulary the player already learned**, not to introduce new words.
4. Each distractor must still pass the template fit rules below (must not fit any blank, must fail both Convo lines, etc.). A prior word that would be a valid answer is still a **bad** distractor.
5. When auditing, **flag distractors that are fresh/unused words** when a prior word in the same semantic field would work **and** still fail as an answer.
6. **Do not** use another **answer word from the current level** as a distractor when it would be plausible in that slot (e.g. `buy` as distractor when `shop` is the answer in the same level).
7. **Lemma matching:** use the form that fits the sentence (`wash` / `washes` / `to wash` from a prior `to wash` entry). Multi-word prior phrases (`to get up`, `I do it`) count as one prior entry.
8. **`imageQuizTemplate-2`:** distractors must remain **image file stems in the level folder**; choose on-theme stems first, prefer stems whose labels match prior nouns the player has seen when possible — each stem must still be a **wrong** label for the hero image (not a valid synonym).
9. If no prior word fits without breaking validity or fit rules, a fresh on-theme word that **clearly fails as an answer** is acceptable — note it in the audit.

**Distractor rules by template:**

All rules below assume **Distractor validity (mandatory)** has already been applied.

- **ClozeSequence:** each distractor must not fit ANY blank in the sentence naturally. Test mentally: insert the distractor into **each** blank — if it produces grammatically and contextually valid English for **any** blank, it is an **invalid** distractor. Prefer prior verbs/adjectives/adverbs that fail **all** blanks.
- **ConvoTemplate-1:** the answer fills the same blank in both lines — insert each distractor into **line1 and line2**; if it works in **either** line as a reasonable response, it is **invalid**. All distractors must fail for **both** lines simultaneously.
- **AppearDisappear:** distractors should be words plausibly associated with the sentence topic but not present in it and not usable as a substitute that preserves the sentence meaning. Prefer prior words from the sentence's semantic field that fail the validity test.
- **DialogueCompletion:** Each distractor must pass the validity test first: it must **not** be a reasonable answer to the specific `line1` question (including alternate valid branches). Then check: (1) **grammatically correct** English, (2) **related to the situation** in `line1` (same scene/topic — not a random off-topic line). Prefer replies that **miss the point while staying in context**. Flag: any distractor that could be accepted as a correct reply, opposite/direct valid answers, off-topic replies, and ungrammatical fragments.
- **GrammarForm:** distractors must be real English forms that are **wrong for the grammatical context** — not alternate forms that could be correct. Use actual conjugations that fail the validity test.
- **imageQuizTemplate-1 / -2:** each `wrongAnswer` must be a **clearly wrong** label for the hero image — not a valid synonym, near-synonym, or alternate correct name.

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
| **ClozeSequence** | Blank answer word(s) **and** key teaching words in the sentence stem — not distractors |
| **ConvoTemplate-1** | Blank answer word **and** key teaching words from either line — not distractors |
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

**ClozeSequence / ConvoTemplate-1 rule:** Both the **blank answer word(s)** and key teaching words in the **sentence stem** (non-blank positions, or either line for ConvoTemplate-1) qualify for `translations.json`. Distractors still **never** qualify. Example: ClozeSequence “It is ______ to _____ this book — another reader **reserved** it.” — `reserved` is a stem word and is now a valid candidate for `to reserve` in translations, same as the blank answer would be. Example: ConvoTemplate-1 “This book is **due** tomorrow. Can I _____ it?” — `due` is a stem word (line1) and may be added to translations, same as any blank answer.

**Universal distractor rule:** Distractors and `wrongAnswers` from **any** template — ClozeSequence, ConvoTemplate-1, GrammarForm, AppearDisappear, SentenceBuilder, DialogueCompletion, imageQuizTemplate-1/2 — **never** qualify for `translations.json`, regardless of how important or relevant the word seems.

**Flag:**

- **Missing tracking** — introduced keyword (answer, AppearDisappear, or SentenceBuilder) not in `translations.json` or WordPairs and not covered by an image question
- **Redundant slot** — translation/WordPairs entry duplicates a noun already taught by image MCQ
- **Wasted slot** — tracked word not introduced anywhere in the level at all (not an answer, not a stem word, not in AppearDisappear/SentenceBuilder sentence, not image answer — only in a distractor or genuinely absent from every question). **Remove these from translations.json without replacement** unless a question edit can promote them into the text, or the user explicitly accepts the word as a kept exception.
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

### 4b. Unused reference-word opportunities

**Required section** in every standard-level audit report (skip for medley levels).

If in your opinion there are better unused words in the references that suit the context, mention them in the audit review — even when the level is otherwise ship-ready and no translation slot is flagged weak.

**How to find candidates:**

1. Filter **available words** (final-word CSVs + Oxford 3000 minus prior consumed) for the level theme.
2. Prefer **A1** then **A2**; prefer entries with **`count` 0** in `verbs-400.csv` / `adjectives-300.csv` / `adverbs-150.csv`.
3. Exclude words already in this level’s answers, AppearDisappear/SentenceBuilder sentences, WordPairs, `translations.json`, or image `imageName` stems.
4. Exclude **object nouns** unless the level has no image questions (medley exception).
5. Exclude words **blocked as prior** in `translations.json` / WordPairs (may still appear in a question stem per prior-reuse rules, but do not suggest re-adding to `translations.json`).

**What to report:**

| Word | POS / level | Why it fits | Where it could go |
|------|-------------|-------------|-------------------|
| e.g. `express` | verb B1, count 0 | express mail at post office | Q15 Cloze blank 1 instead of prior `how much` |

- Give **1–5** suggestions when good candidates exist; say *“none noted”* when the level already covers the best available context words.
- Distinguish from **Vocabulary swap suggestions** (§4): swaps fix weak/wasted/redundant **existing** slots; this section is **additive** — optional improvements the user may adopt later.
- For **ranked candidates**, **misplaced later-level words**, or **full swap proposals with question JSON** (e.g. replacing a stem-only translation row), use the dedicated **`improve-level-vocabulary`** skill instead of expanding §4b.
- Do **not** auto-apply these unless the user approves.

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
| Arabic (ar) | Masdar (verbal noun) form or `لـ` prefix used for verb translations (e.g. `للبكاء`, `دعوة`) | Use **3rd-person present-tense verb** (يفعل) — e.g. `يبكي`, `يدعو`, `يرقص`. Never use masdar or `لـ` prefix for verb entries. |
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
- Grammar band: Part X (ML range) — mainLevel N falls in this Part

## Grammar progression
| Structure found | Q | Status (OK — review / OK — in band / Forbidden — not yet) |
|-----------------|---|--------------------------------------------------------------|
| … | … | … |

- Allowed: Part X and all earlier Parts
- Forbidden: any Part after Part X used in this level

## Summary
- Questions reviewed: N
- **Distractors validated:** yes — all checked with **Distractor validity (mandatory)**; invalid count: …
- High-priority fixes: …
- Translation fixes: …
- Translation slot / swap suggestions: …
- Unused reference-word opportunities: …
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

## Unused reference-word opportunities
| Word | POS / ref level | Why it fits this level | Suggested use (question / slot) |
|------|-----------------|------------------------|----------------------------------|
| … | … | … | … |

*(If none: “None noted — level already uses strong context-fit words from available list.”)*

## Question-by-question

### Q1 — {template}
- **Current:** …
- **Issues:** …
- **Suggestion:** …
- **Distractors:** current → validity result (valid / **invalid — suitable as answer**) → suggested replacement (note when suggested swaps use **prior consumed words**)

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
- Unused reference-word opportunities: see dedicated section above
- Suggested new A1 candidates from available list: …

When user says **fix**, **apply**, or **implement**, patch JSON only for approved items. Validate JSON after edits.

## Priority order for fixes

1. Wrong translations (high confidence)
2. **Invalid distractors** — any option suitable as a correct answer (**Distractor validity (mandatory)**)
3. **Within-level duplicate answer words** (same lemma/phrase tested in 2+ questions)
4. Invalid JSON / template constraint violations (e.g. template-2 missing images)
5. Grammar from a **later Part** used anywhere in the level (**Forbidden — not yet**)
6. Distractors that are off-topic or ambiguous (but not valid as answers)
7. Audio stem name mismatches (JSON vs question text)
8. Missing translation tracking for text-answer words
9. Vocabulary swap suggestions (weak/redundant translation slots)
10. Word selection / A1 coverage improvements
11. Image quiz issues (missing files, off-theme distractors)
12. Punctuation and capitalization
13. Question reordering

## Do not

- Check for `.m4a` / `.mp3` files on disk or generate audio assets
- Commit unless explicitly asked
- Work on `main` branch
- Add tests or speculative features
- Expand `translations_list` beyond 15 entries
- Suggest **object nouns** as vocabulary swap replacements (use image questions for concrete nouns)

## Medley levels

Medley levels (`medley-1`, `medley-2`, …) have different rules from standard themed levels:

| Rule | Standard levels | Medley levels |
|------|----------------|---------------|
| Vocabulary source | Auditor selects from available A1 words | **User provides the exact word list** — use it verbatim |
| Images | `imageQuizTemplate-1` and `imageQuizTemplate-2` present | **No image templates** — distribute only text-based templates |
| Object nouns in `translations.json` | Prohibited — taught via image questions | **Allowed** — nouns like `home`, `paper`, `life`, `family` can occupy translation slots since there are no image questions to introduce them visually |
| Context / theme | Single level theme (e.g. "at the kitchen") | **Free context** — questions can use any topic; distractors and sentences can span any scenario |
| WordPairs | Auditor chooses pairs from available words | **User specifies the exact WordPairs word set** |

**Medley level workflow:**

1. User provides: (a) translation words list, (b) WordPairs word list, and (c) any constraints.
2. Run `gather_prior_level_words.py` to verify all given words are available (none consumed in prior levels).
3. Assign each word to an appropriate template:
   - Verbs → ClozeSequence blank answer, ConvoTemplate-1 blank answer, GrammarForm answer
   - Adjectives/adverbs → ClozeSequence blank answer, GrammarForm answer
   - Abstract nouns → AppearDisappear key word, SentenceBuilder key word, DialogueCompletion line1/answer key word
   - Concrete nouns → SentenceBuilder key word or ClozeSequence blank answer (acceptable since no image questions exist)
4. All given translation words must appear as introduced vocabulary (answer, AppearDisappear key word, or SentenceBuilder key word) — never only as a distractor.
5. Skip the **Vocabulary swap suggestions** section — vocabulary is fixed by the user, not selectable by the auditor.
6. Distractor fit, within-level repetition, **prior-vocabulary distractors**, **grammar progression** (allowed = current Part + earlier Parts; forbidden = later Parts), audio stems, and all other standard checks still apply.

## Additional reference

See [reference.md](reference.md) for CSV filenames, template quick reference, word-list tooling, **within-level repetition**, **translated-word inventory**, **vocabulary swap rules**, **image question checks**, **audio stem checks**, and **`gather_prior_level_words.py` usage**.

For **focused vocabulary improvement** (unused reference words, misplaced later-level words, full swap proposals with question edits), see **`cursor-claude-common/skills/improve-level-vocabulary/SKILL.md`**.
