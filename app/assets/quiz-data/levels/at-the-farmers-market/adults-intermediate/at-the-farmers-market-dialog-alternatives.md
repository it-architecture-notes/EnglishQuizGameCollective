# At the Farmers Market — Adult Level Content Plan

## Current Topic

`<TBD — describe what this planning round is for: e.g. adding a VideoConversation intro to the existing adult At the Farmers Market level, reworking specific questions, etc.>`

## 1. Decisions

- Scope is adults only. Kids content (`at-the-farmers-market/kids/`) will be planned separately.
- This document belongs exclusively to the At the Farmers Market level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- Existing level distributions must be checked before adding vocabulary so words already taught in earlier levels are not repeated without a clear teaching reason.
- Vocabulary taught primarily by image-only levels must be checked before selecting tangible nouns for this level.
- `questions.json` and `translations.json` currently define 13 approved vocabulary items and 15 questions, all non-video (no `VideoConversation` rows yet).
- Adult-oriented characters and settings should be used throughout the level. Any secondary characters must be older teenagers or adults, with mature proportions and styling; do not use young children in adult-level scenes (standing rule from the At the School level).
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.
- **Section 3 shows the dialogue with inline annotations** (developer preference): each line gets the approved word(s) it carries and, where graded, its question template in parentheses/suffix. Full mechanic detail (exact answer, distractors, audio1/audio2 mapping, timestamps) still lives in Section 6 — Section 3's tags are a quick-reference summary, not the source of truth for those specifics.
- **Video prompts must be fully self-contained** (see `all-ai-common/rules/rules.md` § Video Generator Prompt Authoring): every generation-relevant detail — room/character description, exact dialogue, per-line gestures, required silent beats, the held final frame, negative constraints — must live inside the prompt block itself. A prompt may instead rely on a separately-supplied starting/reference image (as with any clip after the first, or when the developer will attach a generated reference image at paste-time) — confirm which approach applies before assuming a prompt with no inline scene description is incomplete.
- **Section 3/6 sequencing**: Section 6 (and Section 4's clip prompts) only get drafted after Section 3's dialogue and question-type mapping are actually agreed — not before.
- **No back-to-back silent question boundaries**: when mapping consecutive lines to templates, every question-to-question boundary needs either an outgoing confirm clip (the preceding question has an `audio_file2`) or an incoming lead-in clip (the next question has its own `audio_file1`/lead-in). `AppearDisappear` has no confirm; `SentenceBuilder`/`DialogueCompletion` (blind pick/build of the character's own line) have no lead-in. Never place one of the no-confirm types immediately before one of the no-lead-in types, or the video goes silent between the two questions.
- **A single spoken line is never split across `audio_file1`/`audio_file2`** — one character's one sentence always plays as one whole clip, either entirely before the pause (`audio_file1`) or entirely after answering (`audio_file2`), never partly on each side. This applies to `ClozeSequence` too: the blanked sentence itself is one line. If a blanked line has no natural preceding setup line to serve as `audio_file1`, leave `audio_file1` unset and let `audio_file2` carry the complete blanked sentence as a single clip after the answer.
- **`question_enter_audio` is available for single-audio-slot questions** (`AppearDisappear`) whose target line needs a lead-in that isn't its own separate graded question: it plays once on first entry (the full lead-in + target line), while `audio_file1` stays the target-only clip used for every replay (wrong-answer repeat, "Listen Again"). Don't reach for this on `SentenceBuilder`/`ClozeSequence` — a prompt line is mandatory for those going forward, so they should get a real `line1`/`audio_file1` lead-in instead.
- **Media (image or video) is mandatory going forward in every template except `ImageQuizTemplate-2` and `WordPairs`.** No new question in this level may omit media.

## 2. Actions

1. Confirm the approved teaching scope from `translations.json`.
   - Review earlier levels for vocabulary overlap.
   - Classify each of the approved words as required, reinforcement, or remove.
   - Identify any gaps in the approved At the Farmers Market teaching scope not yet covered.

2. Design the question set together.
   - Flag any weak distractors, ambiguous answers, or questions testing irrelevant memory before they're added.
   - Confirm every template field matches what its parser actually reads (see `codebase_signatures.md` / `level_config.dart`) before trusting a validator's clean run.

3. Propose and agree on questions.
   - Use short one- or two-line adult situations with clear audio/text context.
   - Use an appropriate mix of approved templates, including DialogueCompletion, ClozeSequence, ConvoTemplate-1, SentenceBuilder, AppearDisappear, and WordPairs where appropriate.
   - Make every correct answer uniquely supported by the dialogue, image, or grammar.

4. Approve and lock the English package.
   - Review vocabulary, question types, distractors, WordPairs, and coverage together.
   - Resolve overlap, ambiguity, and missing coverage before production of any new assets.

5. Produce any new media assets after content approval.
   - Generate any new approved question images and audio assets.
   - Reuse existing convo `.m4a` clips already in the level folder where content is unchanged.

6. Finalize questions and translations JSON.
   - Apply only agreed changes to the live files.
   - Confirm question count, template distribution, answer uniqueness, asset filenames, and translations after each change.

7. Validate the complete At the Farmers Market level.
   - Parse JSON and verify every referenced asset.
   - Check vocabulary coverage and unintended repetition.
   - Play through every question at normal text scale and supported accessibility text scale.
   - Check audio timing, feedback, progression, and question totals.

## 3. Video Dialog

### Dialogs with Words

#### Clip 1 — At the Vegetable Stall

**C:** Good morning. The market is crowded today. (`none`)

**V:** Hello. We usually get many customers early in the morning. (`usually`,`customers`) — `ClozeSequence`

**C:** Do you grow all of these vegetables yourself? — `AppearDisappear`

**V:** Yes. They are all local and fresh. (`local`, `fresh`)

**V:** I can give you a sample. (`sample`) — `SentenceBuilder`

**C:** These tomatoes look ripe. Could you weigh out one kilogram for me, please? (`ripe`,`weigh`) — `ClozeSequence`

**V:** Here you are. The total cost is four dollars. (`none`)

**C:** What else do you sell? (`to sell`) — `DialogueCompletion`

**V:** I sell apples by weight, too. — `SentenceBuilder`(`none`)

*(Pause)*

**V:** I'll give you a discount if you buy in bulk. 

#### Clip 2 — At the Peach Stall

**B:** These peaches are popular this season.

**A:** I can smell them from here. - Cloze (smell)

**B:** They were probably harvested today. - Cloze (harvested)

**C:** Yes. I picked them before I came to the market. - AppearDisappear

**A:** Can we choose the big ones?

**C:** I’m sorry, but you have to buy the whole basket. - SentenceBuilder

**A:** Why are the peaches expensive this year?

**C:** Demand is high, but not enough peaches were grown. - Cloze  (demand, grown)

### Simple Dialogs

#### Clip 1

C: Good morning. The market is crowded today.

V: Hello. We usually get many customers early in the morning.

C: Do you grow all of these vegetables yourself?

V: Yes. They are all local and fresh. I can give you a sample.

C: These tomatoes look ripe. Could you weigh out one kilogram for me, please?

V: Here you are. The total cost is four dollars.

C: What else do you sell?

V: I sell apples by weight, too.

*(Pause)*

V: I’ll give you a discount if you buy in bulk.

#### Clip 2

B: These peaches are popular this season.

A: I can smell them from here.

B: They were probably harvested today.

C: Yes. I picked them before I came to the market.

A: Can we choose the big ones?

C: I’m sorry, but you have to buy a whole small basket.

A: Why are the peaches expensive this year?

B: Demand is high, but not enough peaches were grown.

## 4. Video Scripts

- Clip1.1

Create an approximately 13-second, 1:1 square animated video for adult English learners, beginning exactly from the supplied farmers’ market start frame.

Preserve the customer woman, farmer/vendor man, clothing, faces, proportions, produce stall, tomatoes, apples, scale, sample tray, background stalls, shoppers, colors, lighting, and camera framing throughout. Keep the same classic hand-drawn feature-animation look with flowing tapered cleanup lines, rounded adult anatomy, luminous cel color, and restrained painted shading.

Use one continuous fixed medium-wide shot with no cuts, zooms, pans, reframing, scene changes, or transition effects. Keep both main characters in their starting positions. Background shoppers may have only subtle natural motion; they must not cross in front of the main characters or noticeably alter the composition.

Only the active speaker should move their mouth. During the other character’s turn, the non-speaking character should remain attentive with very subtle natural idle motion only, such as occasional blinking, gentle breathing, and tiny head or eye reactions. Do not make either character look frozen, but avoid distracting movements. Keep gestures small and restrained, and return to a relaxed neutral pose between turns.

0.0–2.2s — Customer

She gives a small friendly greeting gesture and says:

“Good morning. The market is crowded today.”

2.2–5.4s — Vendor

He responds warmly with a small open-hand gesture toward the market and says:

“Hello. We usually get many customers early in the morning.”

5.4–7.9s — Customer

She looks over the produce and lightly gestures toward the vegetables as she asks:

“Do you grow all of these vegetables yourself?”

7.9–12.1s — Vendor

He gives a small proud gesture toward the produce, then lightly indicates the sample tray as he says:

“Yes. They are all local and fresh. I can give you a sample.”

Speak this final sentence clearly and completely at a calm learner-friendly pace. The final word “sample” must be fully spoken and clearly audible before the silent hold begins. Do not shorten, fade, or cut off the final word.

12.1–13.0s — Final hold

No more speech. Both characters return to relaxed neutral poses and hold naturally with only subtle blinking and breathing.

Do not move, replace, or rearrange the produce, scale, apples, stall, canopy, or background layout. Do not add new props, text, signs, logos, or labels. Keep the lighting, exposure, saturation, and overall color brightness identical to the supplied start frame throughout the clip.

- Clip 1.2

Create an approximately 15-second, 1:1 square animated video for adult English learners, beginning exactly from the supplied start frame for this clip.

Preserve the same customer woman, farmer/vendor man, clothing, faces, proportions, produce stall, tomatoes, apples, tabletop scale, sample tray, background stalls, shoppers, colors, lighting, and camera framing throughout. Keep the same classic hand-drawn feature-animation look with flowing tapered cleanup lines, rounded adult anatomy, luminous cel color, and restrained painted shading.

Use one continuous fixed medium-wide shot with no cuts, zooms, pans, reframing, scene changes, or transition effects. Keep both main characters in their starting positions. Background shoppers may have only subtle natural motion and must not cross in front of the main characters or noticeably change the composition.

Only the active speaker should move their mouth. During the other character’s turn, keep the non-speaking character attentive with very subtle idle motion only, such as occasional blinking, gentle breathing, and tiny eye or head reactions. Keep all gestures small, natural, and restrained.

0.0–3.8s — Customer
She looks toward the ripe tomatoes and lightly gestures toward them as she says:
“These tomatoes look ripe. Could you weigh out one kilogram for me, please?”

As she finishes the request, the vendor reaches naturally toward the tomatoes, preparing to weigh them.

3.8–6.6s — Vendor
He places a small amount of tomatoes onto the tabletop scale, briefly checks the scale, then looks back toward the customer and says:
“Here you are. The total cost is four dollars.”

Keep the weighing action simple, clear, and readable. Do not dramatically rearrange the produce.

6.6–8.3s — Customer
She glances toward the other produce and asks:
“What else do you sell?”

8.3–10.7s — Vendor
He gives a small gesture toward the visible apple crate and says:
“I sell apples by weight, too.”

10.7–11.4s — Pause
Brief natural pause. Both characters remain relaxed with subtle idle motion.

11.4–14.3s — Vendor
He makes a small friendly gesture specifically toward the apple crate and says:
“I’ll give you a discount if you buy in bulk.”

14.3–15.0s — Final hold
Both characters return to relaxed neutral poses and hold naturally.

Do not add new props, text, signs, logos, labels, or extra characters. Do not move or replace the scale, apples, tomatoes, baskets, stall, canopy, or background layout. Keep the lighting, exposure, saturation, and overall color brightness consistent with the supplied start frame throughout the clip.

This version should read more naturally and give the weighing action enough time to register clearly.

- Clip 2.1

image:
Here's the final prompt with this addition included:

---

Create a 1:1 square start frame at a lively outdoor farmers' market in the morning.

Use a classic hand-drawn feature animation style: flowing tapered cleanup lines, appealing rounded adult anatomy, readable posing, luminous cel color, and restrained painted shading. Keep the look warm, polished, and animation-ready.

Show a medium-wide fixed shot with three people at one produce stall. Place the produce stand on the left side of the frame and the customers on the right side.

**Characters**
- **Farmer/vendor**: friendly adult market seller standing behind the stall on the left, wearing a cap.
- **Wife/customer**: young adult with shoulder-length dark brown or chestnut hair worn down or in a low ponytail, a soft mustard or dusty rose blouse, a knee-length skirt or casual pants, and comfortable shoes. She stands nearest the stall, looking at the peaches with interest.
- **Husband/customer**: a young adult man, about the same age as his wife, clean-shaven, with short neat dark hair, a friendly face, and casual clothing such as a light shirt with an open overshirt or a simple fitted top with casual pants. He stands just beside and slightly behind his wife, looking at the stand.

**Scene setup**
- The main focus is several small individual baskets of ripe peaches displayed prominently on the stall, each basket sized so a customer could easily pick up and carry one basket at a time. Place the peach baskets in the front and center of the stall, with the supporting produce arranged around them.
- The vendor stands behind the stall, facing the couple with a pleasant, helpful expression.
- Include supporting produce in the stall area such as herbs, cucumbers, tomatoes, and extra wooden crates or baskets, but keep peaches as the main focal produce.
- The stall should feel rustic and fresh, with wooden crates, woven baskets, and a cloth-covered tabletop.
- In the background, show a few other market stalls and several shoppers so the market feels active and lively, but keep them secondary and softly simplified.
- Include trees, bright morning daylight, and a calm small-town market atmosphere.

**Mood and lighting**
Soft natural morning light, warm and welcoming atmosphere, colorful but not chaotic, realistic and clean.

**Important constraints**
Use one continuous fixed-camera composition suitable for the full dialog.
Do not include readable signs, labels, logos, or text.
Do not use exaggerated motion or dramatic poses.

Prompt:
Create an approximately 12-second, 1:1 square animated video for adult English learners, beginning exactly from the supplied farmers’ market peach-stall start frame.
Preserve the three characters exactly as shown: the farmer/vendor on the left behind the stall, the wife/customer on the right nearest the stall, and the husband/customer just beside and slightly behind her on the right. Preserve their faces, ages, hairstyles, clothing, proportions, positions, peach baskets, supporting produce, stall structure, background market, lighting, colors, and camera framing throughout.
Maintain the same classic hand-drawn feature animation style with flowing tapered cleanup lines, appealing rounded adult anatomy, luminous cel color, restrained painted shading, and natural adult expressions.
Use one continuous fixed medium-wide shot with no cuts, zooms, pans, reframing, scene changes, or transition effects. Keep all three main characters in their general starting positions. Background shoppers may have only subtle natural motion and must not cross in front of the main characters or noticeably change the composition.
Only the active speaker should move their mouth. During another person’s turn, the other two characters should remain attentive with only subtle blinking, breathing, and small eye or head reactions. Keep gestures natural, small, and restrained. Avoid exaggerated motion.
Timing
0.0–2.5s — Wife
She looks at the peach baskets on the stall and makes a small gesture toward them as she says:
“These peaches are popular this season.”
2.5–4.7s — Husband
He stays beside and slightly behind his wife, looking toward the peach display. He leans slightly forward and makes a small natural smelling reaction from where he is, without touching or holding any peach, and says:
“I can smell them from here.”
4.7–7.5s — Wife
She looks at the peaches, then briefly toward the vendor, and says:
“They were probably harvested today.”
7.5–11.1s — Vendor
The vendor gives a small friendly nod and lightly gestures toward the peach baskets as he says:
“Yes. I picked them before I came to the market.”
Speak the full line clearly and completely. The final word “market” must be fully spoken before the silent hold begins.
11.1–12.0s — Final hold
No more speech. All three characters settle into relaxed neutral poses with only subtle blinking and breathing.
Important constraints
Do not make the husband hold, pick up, or smell a peach in his hand. He should smell the peaches from a short distance while standing beside his wife.
Do not remove, add, or noticeably rearrange any peaches, baskets, crates, produce, or stall elements. Do not add text, labels, logos, or signs. Keep the lighting, exposure, saturation, and overall color brightness consistent with the supplied start frame throughout.



## 5. Image Dialogs

#### Dialog 3

**D:** What do the vendors do?

**E:** They unload bunches of herbs and display them in crates. - Cloze - unload, bunches, display

#### Dialog 4

**X:** Two dollars a kilogram is a good deal.

**Y:** Farmers are supplying a lot of produce this year. - Appear Disapper

#### Dialog 5

**F:** These strawberries look great. Are they locally grown?

**G:** Yes. They were locally grown and freshly picked this morning. - Cloze - grown, freshly, picked

### Image Question Placeholder

- **Context:** `<TBD>`
- **Adult characters:** `<TBD>`
- **Dialogue:** `<TBD>`
- **Teaching targets:** `<TBD>`
- **Template:** `<TBD>`
- **Image filename:** `<TBD>`
- **Image description:** `<TBD>`
