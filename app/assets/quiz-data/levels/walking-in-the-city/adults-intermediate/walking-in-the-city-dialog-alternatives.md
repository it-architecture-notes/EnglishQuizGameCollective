# Walking in the City — Adult Level Content Plan

## Current Topic

Adding `VideoConversation` content to the existing adult Walking in the City level, following the same process used for At the Farmers Market (`app/assets/quiz-data/levels/at-the-farmers-market/adults-intermediate/at-the-farmers-market-dialog-alternatives.md`).

## 1. Decisions

- Scope is adults only. Kids content (`walking-in-the-city/kids/`) will be planned separately.
- This document belongs exclusively to the Walking in the City level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- Existing level distributions must be checked before adding vocabulary so words already taught in earlier levels are not repeated without a clear teaching reason.
- Vocabulary taught primarily by image-only levels must be checked before selecting tangible nouns for this level.
- `questions.json` and `translations.json` currently define **13 approved vocabulary items** and **15 questions**, all non-video (no `VideoConversation` rows yet):
  - **Vocabulary (13):** to walk, to look at, to wander around, to come, to see, to turn left, to leave the house, in a rush, to live, to follow, to cross, corner, city.
  - **Current image assets:** `bench`, `building`, `streets`, `statue`, `tower` (used by the 5 `imageQuizTemplate-1` rows).
  - **Current non-image templates:** `ConvoTemplate-1` ×2, `WordPairs` ×1, `DialogueCompletion` ×2, `AppearDisappear` ×1, `SentenceBuilder` ×1, `ClozeSequence` ×3.
- Adult-oriented characters and settings should be used throughout the level. Any secondary characters must be older teenagers or adults, with mature proportions and styling; do not use young children in adult-level scenes (standing rule from the At the School level).
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.
- **Section 3 shows the dialogue with inline annotations** (developer preference): each line gets the approved word(s) it carries and, where graded, its question template in parentheses/suffix. Full mechanic detail (exact answer, distractors, audio1/audio2 mapping, timestamps) still lives in Section 6 (via Section 4 video scripts here) — Section 3's tags are a quick-reference summary, not the source of truth for those specifics.
- **Video prompts must be fully self-contained** (see `all-ai-common/rules/rules.md` § Video Generator Prompt Authoring): every generation-relevant detail — room/character description, exact dialogue, per-line gestures, required silent beats, the held final frame, negative constraints — must live inside the prompt block itself. A prompt may instead rely on a separately-supplied starting/reference image (as with any clip after the first, or when the developer will attach a generated reference image at paste-time) — confirm which approach applies before assuming a prompt with no inline scene description is incomplete.
- **Section 3/4 sequencing**: Section 4's clip prompts only get drafted after Section 3's dialogue and question-type mapping are actually agreed — not before.
- **No back-to-back silent question boundaries**: when mapping consecutive lines to templates, every question-to-question boundary needs either an outgoing confirm clip (the preceding question has an `audio_file2`) or an incoming lead-in clip (the next question has its own `audio_file1`/lead-in). `AppearDisappear` has no confirm; `SentenceBuilder`/`DialogueCompletion` (blind pick/build of the character's own line) have no lead-in. Never place one of the no-confirm types immediately before one of the no-lead-in types, or the video goes silent between the two questions.
- **A single spoken line is never split across `audio_file1`/`audio_file2`** — one character's one sentence always plays as one whole clip, either entirely before the pause (`audio_file1`) or entirely after answering (`audio_file2`), never partly on each side. This applies to `ClozeSequence` too: the blanked sentence itself is one line. If a blanked line has no natural preceding setup line to serve as `audio_file1`, leave `audio_file1` unset and let `audio_file2` carry the complete blanked sentence as a single clip after the answer.
- **`question_enter_audio` is available for single-audio-slot questions** (`AppearDisappear`) whose target line needs a lead-in that isn't its own separate graded question: it plays once on first entry (the full lead-in + target line), while `audio_file1` stays the target-only clip used for every replay (wrong-answer repeat, "Listen Again"). Don't reach for this on `SentenceBuilder`/`ClozeSequence` — a prompt line is mandatory for those going forward, so they should get a real `line1`/`audio_file1` lead-in instead.
- **Media (image or video) is mandatory going forward in every template except `ImageQuizTemplate-2` and `WordPairs`.** No new question in this level may omit media.

## 2. Actions

1. Confirm the approved teaching scope from `translations.json`.
   - Review earlier levels for vocabulary overlap.
   - Classify each of the 13 approved words as required, reinforcement, or remove.
   - Identify any gaps in the approved Walking in the City teaching scope not yet covered.

2. Design the question set together.
   - Decide which of the current 15 questions convert to `VideoConversation` rows vs. stay as-is (image or standalone convo templates).
   - Flag any weak distractors, ambiguous answers, or questions testing irrelevant memory before they're added.
   - Confirm every template field matches what its parser actually reads (see `codebase_signatures.md` / `level_config.dart`) before trusting a validator's clean run.

3. Propose and agree on questions.
   - Use short one- or two-line adult situations with clear audio/text context (street/city setting: walking, directions, sightseeing, city life).
   - Use an appropriate mix of approved templates, including DialogueCompletion, ClozeSequence, ConvoTemplate-1, SentenceBuilder, AppearDisappear, and WordPairs where appropriate.
   - Make every correct answer uniquely supported by the dialogue, image, or grammar.

4. Approve and lock the English package.
   - Review vocabulary, question types, distractors, WordPairs, and coverage together.
   - Resolve overlap, ambiguity, and missing coverage before production of any new assets.

5. Produce any new media assets after content approval.
   - Generate any new approved question images and audio assets.
   - Reuse existing assets (`bench`, `building`, `streets`, `statue`, `tower`) where content is unchanged.

6. Finalize questions and translations JSON.
   - Apply only agreed changes to the live files.
   - Confirm question count, template distribution, answer uniqueness, asset filenames, and translations after each change.

7. Validate the complete Walking in the City level.
   - Parse JSON and verify every referenced asset.
   - Check vocabulary coverage and unintended repetition.
   - Play through every question at normal text scale and supported accessibility text scale.
   - Check audio timing, feedback, progression, and question totals.

## 3. Video Dialog

### Dialogs with Words

#### Clip 1

Sara: It's good that we left the house early. (`to leave the house`) — `AppearDisappear`

Tom: Yes, now we won't be in a rush. (`in a rush`) — `ClozeSequence`

Mia: Are you both walking downtown? (`to walk`)

Sara: Yes. We will cross the bridge. (`to cross`) — `SentenceBuilder`

Mia: Can I come with you? (`to come`)

Sara: Sure, but stay close. — `DialogueCompletion`

Tom: First, we go straight for two blocks. — `AppearDisappear`

Mia: Do we turn left at the corner? (`to turn left`, `corner`) — `ClozeSequence`

Sara: No, we wait at the intersection, then turn right.

#### Clip 2

Anna: Wandering around the city is great. (`to wander around`, `city`) — `AppearDisappear`

Tom: Look at that alley. Do you recognize it? (`to look at`)

Anna: Not really, but I notice a nice house there. (`really`, `notice`) — `ClozeSequence`

Tom: It’s where my grandparents lived for a while. (`to live`)

Anna: Let’s stop and check the entrance. — `AppearDisappear`

Tom: We can ask for directions to city hall too. (`city`, `ask`, `for`, `directions`) — `ClozeSequence`

Anna: I think I can easily find the way from here. (`find the way`) — `ClozeSequence`

### Simple Dialogs

#### Dialogue 1
Sara: It's good that we left the house early.
Tom: Yes, now we won't be in a rush.
Mia: Are you both walking downtown?
Sara: Yes. We will cross the bridge.
Mia: Can I come with you?
Sara: Sure, but stay close.
Tom: First, we go straight for two blocks.
Mia: Do we turn left at the corner?
Sara: No, we wait at the intersection, then turn right.

#### Dialogue 2
Anna: Wandering around the city is great.
Tom: Look at that alley. Do you recognize it?
Anna: Not really, but I notice a nice house there.
Tom: It’s where my grandparents lived for a while.
Anna: Let’s stop and check the entrance.
Tom: We can ask for directions to city hall too.
Anna: I think I can easily find the way from here.

## 4. Video Scripts

`<TBD — full self-contained generator prompts per clip, drafted only after Section 3 dialogue and question-type mapping are agreed. Must include: scene/character description (or reference to a supplied start frame), exact dialogue lines and order, per-line gestures/actions, required silent beats, the held final frame, and negative constraints, per the Video Generator Prompt Authoring rule.>`

## 5. Image Dialogs

### Dialogs with Words

#### Dialogue 3

A: I can see the café; it’s around the corner.

B: Let’s take a shortcut from here. (`take a shortcut`) — `ClozeSequence`

#### Dialogue 4

A: What if we get lost in the busy city centre?

B: We won’t get lost if we walk along this route. (`get lost`) — `ConvoTemplate-1`

#### Dialogue 5

A: We came on foot through the crowded avenue. (`come on foot`) — `ConvoTemplate-1`

B: Let’s continue until we reach the flea market.

#### Dialogue 6

A: Should I walk past the coffee shop?

B: No, turn around and go straight ahead in the opposite direction. (`turn around`, `straight ahead`) — `ClozeSequence`

### Simple Dialogs

#### Dialogue 3

A: I can see the café; it’s around the corner.

B: Let’s take a shortcut from here.

#### Dialogue 4

A: What if we get lost in the busy city centre?

B: We won’t get lost if we walk along this route.

#### Dialogue 5

A: We came on foot through the crowded avenue.

B: Let’s continue until we reach the flea market.

#### Dialogue 6

A: Should I walk past the coffee shop?

B: No, turn around and go straight ahead in the opposite direction.

### Image Question Placeholder

- **Context:** `<TBD>`
- **Adult characters:** `<TBD>`
- **Dialogue:** `<TBD>`
- **Teaching targets:** `<TBD>`
- **Template:** `<TBD>`
- **Image filename:** `<TBD>`
- **Image description:** `<TBD>`
