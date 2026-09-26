# Merged Basic Sentences + Verb to Be — Adult Level Content Plan

## Current Topic

Review Claude's revised two-dialogue proposal for naturalness, vocabulary coverage, timing, and question-count compliance. Resolve the remaining issues before synchronizing the JSON. Multilingual translations, final media scripts, and asset production remain outside the current topic.

## 1. Decisions

- Scope is adults only. This document defines the adult merged level; kids content will be planned separately.
- The existing Verb to Be and Basic Sentences adult levels will be consolidated into one Basic Sentences adult level.
- Approved question count is 12: eight VideoConversation questions from the two approved continuous dialogues, two independent image-based questions, and two separate WordPairs questions.
- There is exactly one video question per dialogue exchange.
- Teaching quality takes priority over preserving an earlier dialogue draft. Dialogue lines may be shortened or rewritten when that creates clearer, objectively gradable questions.
- Video scripts are intentionally deferred. The video dialogue, image dialogues, question JSON, and translation vocabulary must be approved first.
- Translation values remain "<TBD>" placeholders until the English content and vocabulary list are agreed.
- Existing verified translations may be reused during implementation, but they are not copied into this planning structure before content approval.
- The end-of-level translation proposal currently contains 23 entries after removing `about` and `good` as dispensable (low distinctive grammar value), restoring `what time is it?` now that it has a natural home in the two-dialogue video structure, restoring the approved contextual negation chunks `It is not` and `They are not`, adding `look at` (spoken in Video 1 Q3's setup line, "Take a look at this."), and setting aside `every day` (no natural home found yet; deferred, not dropped) for a later pass.
- The approved English vocabulary list is authoritative: video and image questions are created from that list. Vocabulary must never be added merely because it appears in a preliminary question draft.
- Legacy vocabulary may remain on the end-of-level translations page even when it is no longer directly assessed by one of the reduced merged-level questions; preserving the established level distribution takes priority over deleting those entries.
- The generator-supported clips will produce two continuous videos (`basic-sentences1` at ~23s and `basic-sentences2` at ~13s) before timestamps are measured.
- Video timestamps and extracted setup/confirmation audio are created only after the final video is approved.
- Questions must not require the learner to guess unknowable facts. Each correct answer must be uniquely supported by grammar, visible context, or previously presented dialogue.
- Distractors must not produce equally valid answers in the same sentence or scene.
- Two separate WordPairs questions preserve the source teaching sets: one for possessives and one for subject pronouns, each matched to selected-language translations.
- No automated test code will be created, per project rules. JSON syntax and content consistency will be validated before implementation.

## 2. Actions

1. Agree on the teaching scope and create the preliminary translation set.
   - Audit the source levels, Greetings, dedicated image-vocabulary levels, and relevant later scenario levels so vocabulary is not unintentionally repeated or taken from another level.
   - Lock the grammar objectives and classify each candidate word or phrase as required, reinforcement, or remove.
   - Build the English translation list first. Reuse verified existing translations where appropriate and keep genuinely new translations as `<TBD>` until the English content is approved.
   - Define both WordPairs sets at this stage because their vocabulary is part of the teaching scope, not an afterthought.
   - Do not derive translation entries from draft video or image questions. Once vocabulary is approved, derive the questions and dialogues from it.
   - Produce a coverage table mapping every retained teaching item to its planned question, dialogue, WordPairs entry, or end-of-level translation entry.

2. Create the continuous video dialogue and its questions together.
   - Select approximately 6–9 compatible teaching items that can occur naturally in one adult situation.
   - Write meaningful continuous dialogues across two videos (~23s for Video 1 and ~13s for Video 2) around those items; do not insert vocabulary merely to satisfy a list.
   - Draft 8 VideoConversation questions across the two dialogues (5 in Video 1, 3 in Video 2), one question per exchange or clearly bounded teaching moment.
   - Choose the best supported video answer type for each moment and keep answers short enough for the corresponding buttons, slots, or tiles.
   - Revise the dialogue immediately when a line produces an ambiguous correct answer, weak distractors, excessive answer length, or a question that tests memory without teaching value.
   - Confirm that each dialogue remains coherent when watched continuously without the quiz pauses.

3. Create independent image dialogues and questions for the remaining teaching items.
   - Use short, self-contained adult situations rather than forcing unrelated vocabulary into the video story.
   - For each item, define the dialogue, teaching target, question template, uniquely correct answer, plausible but invalid distractors, `image_file_name`, and a generation-ready image description.
   - Use an appropriate mix of ConvoTemplate-1, DialogueCompletion, SentenceBuilder, and other approved image-capable templates; do not make every image question the same type.
   - Prefer visible context for tangible nouns and observable actions. Do not ask learners to infer facts that the image or dialogue cannot establish.
   - Together with the video questions and two WordPairs questions, bring the final level to the approved total of 12 questions while ensuring every retained teaching item has a clear home.

4. Approve and lock the complete English content, then produce the video.
   - Review the video dialogue, all video and image questions, WordPairs content, translation vocabulary, distractors, image descriptions, filenames, and coverage table as one package.
   - Resolve all vocabulary duplication, answer ambiguity, and coverage gaps before spending time on production assets.
   - After approval, create paste-ready generator scripts with character continuity, camera direction, speech timing, visual style, and exact dialogue.
   - Split dialogues into generator-supported clips when necessary (e.g. Video 1 into Clips 1.1 and 1.2), using stable transition/start frames so each final joined video (`basic-sentences1` ~23s, `basic-sentences2` ~13s) remains continuous.
   - Generate, join, and visually approve both videos before measuring timestamps or deriving audio.

5. Produce the supporting image and audio assets.
   - Generate each approved image from its locked description and verify that the visual evidence supports the intended answer without revealing it through generated text.
   - Create the independent-dialogue audio with the approved voices and processing chain.
   - Measure final video boundaries, extract the required setup and confirmation audio, and preserve synchronization with the approved video.
   - Use final asset names consistently across the files and confirm every referenced asset exists.

6. Finalize the questions and translations JSON.
   - Replace timestamp, filename, and translation placeholders only after the corresponding content and assets are locked.
   - Populate the final multilingual translations, reusing verified source translations and reviewing newly created ones for meaning in context rather than literal wording alone.
   - Confirm question totals, template distribution, WordPairs behavior, answer/distractor counts, and the English-language WordPairs skip/count adjustment.
   - Validate both JSON structures without reserializing or rewriting unrelated level files.

7. Validate the complete level before implementation is considered finished.
   - Parse the JSON and verify every referenced video, image, and audio asset.
   - Check that every teaching item in the coverage table is taught exactly where intended and that removed vocabulary has not returned accidentally.
   - Play through every question at normal text scale, checking answer uniqueness, media/audio timing, correct and wrong feedback, question count, and progression.
   - Check the supported accessibility layout and selected non-English languages for wrapping and usability.
   - Record content or asset corrections in this plan; do not create automated test code under the current project rules.

## 3. Video Dialog

### Dialogs with Words

#### Clip 1 — Transit Information

**Sara:** Excuse me, what time is it? (`Excuse me`, `what time is it?`)

**Tom:** It is nine o'clock. — `DialogueCompletion`

**Sara:** Is there a bus station here? I go downtown. (`There is`, `here`, `to go`)

**Tom:** Yes, there is. And there are many taxis nearby. (`There is`, `There are`) — `ClozeSequence`

**Sara:** When is the next train to the city? (`When`)

**Tom:** Take a look at this. (`look at`)

**Sara:** What is this? (`What is this?`) — `DialogueCompletion`

**Tom:** This is the train schedule. (`This is`) — `AppearDisappear`

**Sara:** Thank you very much.

**Tom:** No problem. — `DialogueCompletion`

#### Clip 2 — Ready to Leave

Are you ready to go?

Yes, I am. - DialogCompletion

Do you need help with the bag? - Appear Disappear

No, I’m good.

Is Tom coming too? - Sentence Builder

I’m not sure.

I really like talking to him. I hope he comes. - Appear Disappear

### Simple Dialogs

#### Clip 1

Sara: Excuse me, what time is it?

Tom: It is nine o'clock.

Sara: Is there a bus station here? I go downtown.

Tom: Yes, there is. And there are many taxis nearby.

Sara: When is the next train to the city?

Tom: Take a look at this.

Sara: What is this?

Tom: This is the train schedule.

Sara: Thank you very much.

Tom: No problem.

#### Clip 2

Are you ready to go?

Yes, I am.

Do you need help with the bag?

No, I’m good.

Is Tom coming too?

I’m not sure.

I like talking to him. I hope he comes.

---

## 5. Image Dialogs

Whose coat is this?
I don't know. It is not mine.

Are these your tickets?
No, they are not. These are for our friends.
