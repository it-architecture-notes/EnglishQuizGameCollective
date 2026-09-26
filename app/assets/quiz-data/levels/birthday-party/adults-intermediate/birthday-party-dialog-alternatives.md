# Birthday Party — Adult Level Content Plan

## Current Topic

`<TBD — describe what this planning round is for: e.g. adding a VideoConversation intro to the existing adult Birthday Party level, reworking specific questions, etc.>`

## 1. Decisions

- Scope is adults only. Kids content (`birthday-party/kids/`) will be planned separately.
- This document belongs exclusively to the Birthday Party level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- Existing level distributions must be checked before adding vocabulary so words already taught in earlier levels are not repeated without a clear teaching reason.
- Vocabulary taught primarily by image-only levels must be checked before selecting tangible nouns for this level.
- `questions.json` and `translations.json` currently hold **live, already-shipped** content (12 approved vocabulary items, 15 questions across `imageQuizTemplate-1`, `ClozeSequence`, `ConvoTemplate-1`, `DialogueCompletion`, `imageQuizTemplate-2`, `WordPairs`, `AppearDisappear`, `SentenceBuilder`). Nothing has been cleared yet — no live file changes happen until new questions are proposed and agreed here first.
- Adult-oriented characters and settings should be used throughout the level. Any secondary characters must be older teenagers or adults, with mature proportions and styling; do not use young children in adult-level scenes (standing rule from the At the School level).
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.
- **Section 3 shows the dialogue with inline annotations** (developer preference): each line gets the approved word(s) it carries and, where graded, its question template in parentheses/suffix. Full mechanic detail (exact answer, distractors, audio1/audio2 mapping, timestamps) still lives in Section 6 — Section 3's tags are a quick-reference summary, not the source of truth for those specifics.
- **Video prompts must be fully self-contained** (see `all-ai-common/rules/rules.md` § Video Generator Prompt Authoring): the developer can only paste the quoted prompt text into the video generator, nothing else from Section 4. Every generation-relevant detail — room/character description, exact dialogue, per-line gestures, required silent beats, the held final frame, negative constraints — must live inside the prompt block itself, not only in surrounding bullets.
- **Section 3/6 sequencing**: Section 6 (and Section 4's clip prompts) only get drafted after Section 3's dialogue and question-type mapping are actually agreed — not before.

## 2. Actions

1. Confirm the approved teaching scope from `translations.json`.
   - Review earlier levels for vocabulary overlap.
   - Classify each of the approved words as required, reinforcement, or remove.
   - Identify any gaps in the approved Birthday Party teaching scope not yet covered.

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
   - Reuse the existing convo `.m4a` clips already in the level folder where content is unchanged.

6. Finalize questions and translations JSON.
   - Apply only agreed changes to the live files.
   - Confirm question count, template distribution, answer uniqueness, asset filenames, and translations after each change.

7. Validate the complete Birthday Party level.
   - Parse JSON and verify every referenced asset.
   - Check vocabulary coverage and unintended repetition.
   - Play through every question at normal text scale and supported accessibility text scale.
   - Check audio timing, feedback, progression, and question totals.

## 3. Video Dialogs

### Video 1 — Leo's Birthday

**Mia:** Happy birthday, Leo! (`happy`)
**Leo:** Wow! What a big surprise! (`surprise`) — `DialogueCompletion`
**Adam:** We are happy to celebrate together. (`happy`, `to celebrate`, `together`) — `ClozeSequence`
**Mia:** We decorated the room for you. (`to decorate`) — `AppearDisappear`
**Leo:** It looks wonderful. Thank you! (`none`)
**Mia:** Now make a wish and blow out the candles. (`to wish`, `to blow`) — `SentenceBuilder`
**Leo:** Okay. Then let's sing and dance! (`to sing`, `to dance`) — `AppearDisappear`

### Video 2 — Preparing for Noah's Party

**Mia:** Did Noah invite you to the party? (`to invite`)
**Adam:** Yes, and he will be surprised when he unwraps the gifts. (`surprise`, `to unwrap gifts`) — `DialogueCompletion`
**Mia:** Really? What did you buy for him? (`none`)
**Adam:** I cannot say, but we will enjoy the party. (`to enjoy`) — `SentenceBuilder`
**Mia:** Great. Let's prepare the cake too. (`none`)

## 4. Video Scripts

### Clip 1.1: The Birthday Surprise (Lines 1–4, approximately 10.7s)

> **Prompt:** Create an approximately **11-second, 1:1 square**, clean professional flat-vector lifestyle animation for adult English learners. Use clear, consistent dark outlines, natural adult body proportions, restrained facial animation, and a polished editorial look. Use a warm, cheerful birthday palette with muted teal, navy, coral, cream, and gold accents. Keep the scene sophisticated and suitable for adults, not childish or overly colorful.

**Setting:** A cozy, tastefully decorated apartment living room during an adult birthday party. A small birthday table stands near the center with a frosted cake, plates, cups, and several small lit candles. The room has balloons, paper garlands, wrapped gifts, and simple festive decorations. Decorations must already be present when the clip begins; they must not suddenly appear. Include a sofa, a side table, a floor lamp, and a doorway on the far right. Use soft late-afternoon daylight mixed with warm indoor lighting.

**Characters:**

* **Mia:** Woman in her late 20s, medium-brown skin, shoulder-length wavy dark hair, wearing a muted coral blouse, navy trousers, and simple flats.
* **Leo:** Man in his early 30s, light-brown skin, short dark hair, clean-shaven, wearing a teal button-up shirt, beige trousers, and casual shoes.
* **Adam:** Man in his early 30s, medium skin tone, short slightly curly black hair, wearing a cream sweater, dark trousers, and casual shoes.

Preserve each character’s face, hairstyle, clothing, colors, height, and proportions throughout. All three characters are adults.

Use **one continuous fixed wide shot** with no cuts, zooms, pans, reframing, camera movement, scene changes, or transition effects. Keep all three characters, the decorated room, and the birthday cake visible throughout.

At the beginning, Leo has just entered through the doorway on the right and has stopped near the birthday table. Mia stands to the left of the cake, facing Leo. Adam stands slightly behind and to the left of Mia. The candles are already lit. Everyone begins in a natural, relaxed pose.

**Dialogue and actions:**

**0.2–1.6 seconds — Mia:** “Happy birthday, Leo!”

Mia smiles warmly and opens both hands toward Leo and the decorated room. Adam smiles silently. Only Mia speaks and moves her mouth.

**1.9–3.9 seconds — Leo:** “Wow! What a big surprise!”

Leo looks around with genuine surprise, raises his eyebrows, and briefly places one hand against his chest. He then looks back at Mia and Adam. Only Leo speaks and moves his mouth.

**4.2–6.8 seconds — Adam:** “We are happy to celebrate together.”

Adam smiles and makes a welcoming open-hand gesture toward Mia, Leo, and the party table. Mia and Leo listen without speaking. Only Adam moves his mouth.

**7.1–9.5 seconds — Mia:** “We decorated the room for you.”

Mia gestures naturally toward the balloons, garlands, gifts, and other decorations. Leo follows her gesture with his eyes and smiles appreciatively. Only Mia speaks and moves her mouth.

**9.5–11.0 seconds — Final hold:**

Mia lowers her hand into a relaxed position. Leo continues looking around the decorated room with a grateful smile. Adam remains beside Mia, smiling. End on a stable held frame with Mia on the left, Adam slightly behind her, Leo on the right near the cake, and the lit candles clearly visible. Nobody touches the cake or blows out the candles in this clip.

Use clear, warm, natural adult voices with accurate lip synchronization. Speakers must speak one at a time with no overlapping dialogue. Include every line exactly as written and in the specified order. Do not add, remove, repeat, or paraphrase any dialogue. No narration, subtitles, captions, speech bubbles, readable text, or extra voices. Use only very subtle room ambience; speech must remain clear.


### Clip 1.2: The Candles and Celebration (Lines 5–7, approximately 11.0s)

> **Prompt:** Create an approximately **11.0-second, 1:1 square**, clean professional flat-vector lifestyle animation for adult English learners. Begin exactly from the supplied final held frame of the previous clip, while treating every specification below as authoritative and self-contained. Use clear consistent dark outlines, natural adult body proportions, restrained facial animation, warm indoor lighting, and a polished editorial look. Use one continuous fixed wide shot with no cuts, zooms, pans, reframing, camera movement, scene changes, or transition effects.
>
> The setting is the same tasteful birthday gathering in a modern adult apartment dining room. Show exactly three adult characters, all fully visible throughout. **Mia** is an adult woman with shoulder-length wavy dark-brown hair, wearing a burgundy blouse, cream trousers, and tan shoes. She stands on the left side of the birthday table. **Leo** is the adult birthday celebrant, a man with short dark-brown hair, wearing a navy button-down shirt with rolled sleeves, beige trousers, and brown shoes. He stands at the center behind the cake, angled slightly toward Mia and Adam. **Adam** is an adult man with short light-brown hair, wearing a forest-green sweater over a white collared shirt, dark trousers, and black shoes. He stands on the right side of the table. All characters must have mature proportions and styling; do not portray children or teenagers.
>
> Preserve the exact supplied camera composition and fixed room layout. A medium round wooden birthday table stands in the center foreground. On it is one decorated birthday cake with exactly five small lit candles, three simple plates, and three drinking glasses. Behind the characters are a sideboard with exactly three wrapped gifts, clusters of burgundy, gold, and cream balloons, and simple paper garlands and streamers with no readable text. A window with closed pale curtains is on the left background wall, and a framed abstract picture is on the right background wall. Preserve the exact room geometry, furniture, cake design, candle count, gifts, decorations, props, lighting, character positions, identities, faces, hairstyles, body proportions, and clothing from the supplied starting frame.
>
> Use natural synchronized mouth movements and clear conversational turn-taking. Mia has a warm, cheerful adult female voice. Leo has a pleasantly surprised adult male voice. Adam has a friendly, relaxed adult male voice distinct from Leo's. Only the named character speaks each line. Every non-speaking character keeps their mouth closed. Do not overlap voices or add dialogue, narration, background speech, actual singing, music, applause, or sound effects. Preserve the following dialogue exactly; do not paraphrase, shorten, omit, repeat, or reorder any words.
>
> Begin with a quiet 0.4-second continuity hold matching the supplied starting frame. Mia stands on the left, Leo remains centered behind the cake, and Adam stands on the right. All mouths are closed and hands are relaxed. The cake and exactly five lit candles remain unchanged.
>
> **Line 5:** Leo looks around appreciatively at the decorated room, then toward Mia and Adam. He smiles, gives one small grateful nod, and says, “It looks wonderful. Thank you!” Mia and Adam listen with closed mouths.
>
> **Required pause before Line 6:** After Leo finishes, hold a natural silent settled beat for approximately 0.5 seconds. Every mouth remains closed. Mia shifts her attention toward the cake but must not speak or begin her gesture early. Leo remains upright and does not lean toward the candles yet.
>
> **Line 6:** Mia makes one gentle open-hand gesture toward the cake and says, “Now make a wish and blow out the candles.” Leo watches her attentively without speaking. Adam remains quiet with a supportive smile. Mia completes the entire sentence and lowers her hand.
>
> After Mia finishes, hold a brief silent beat. Leo closes his eyes for a moment to make a wish, then leans forward naturally and blows once toward the five candles. All five flames go out together without changing the cake or candle shapes. Show only a small subtle wisp of smoke. Leo then returns to an upright balanced standing position. Mia and Adam watch silently with restrained happy expressions; they do not clap, sing, or speak.
>
> Hold a brief natural silent turn-taking pause after Leo returns upright. All mouths remain closed and the extinguished candles stay unchanged.
>
> **Line 7:** Leo looks toward Mia and Adam, makes one small inviting open-hand gesture, and says, “Okay. Then let's sing and dance!” Mia and Adam smile and give only a subtle anticipatory body shift; they do not actually sing, speak, or perform a large dance during Leo's sentence.
>
> **Required recall-question hold after Line 7:** After Leo completes the full sentence, hold approximately 0.5 seconds of silence. Every mouth remains closed. Leo lowers his hand and all three characters settle naturally.
>
> End on a calm stable final frame held for approximately 0.8 seconds. Leo stands upright at the center behind the cake with both hands lowered and a happy expression. Mia and Adam remain in their established left and right positions, smiling with relaxed hands. All five candles are visibly extinguished with no active flame. The table, cake, plates, glasses, gifts, balloons, garlands, sideboard, window, picture, lighting, and character designs remain unchanged. Do not add further dialogue or noticeable movement.
>
> **Timing targets — do not display these timings on screen:** 0.0–0.4 opening continuity hold; 0.4–2.4 Line 5; 2.4–2.9 silent pause; 2.9–5.8 Line 6; 5.8–7.0 silent wish-and-candle action; 7.0–7.3 silent turn-taking pause; 7.3–9.7 Line 7; 9.7–10.2 silent recall hold; 10.2–11.0 final hold.
>
> Do not show readable text, captions, labels, logos, watermarks, speech bubbles, age numbers, or written birthday messages. Do not add extra guests, children, pets, people in reflections, or background figures. Do not relight the candles after Leo blows them out. Avoid exaggerated reactions, large dancing, lip movement from non-speaking characters, character sliding, camera drift, furniture movement, decoration changes, candle-count changes, cake deformation, duplicate gifts, objects appearing or disappearing, malformed hands, merged fingers, floating objects, distorted limbs, anatomy changes, clothing changes, or changes in character size.

### Clip 2.1: The Invitation and Surprise (Lines 1–2, approximately 7.0s)

> **Prompt:** Create an approximately **13-second, 1:1 square**, clean professional flat-vector lifestyle animation for adult English learners. Begin exactly from the supplied starting image.

Preserve the supplied characters, faces, hairstyles, clothing, proportions, room layout, furniture, decorations, wrapped gifts, cake-preparation items, colors, lighting, and camera composition throughout. Do not add, remove, replace, redesign, or reposition any visual element.

Use one continuous locked-off wide shot. No cuts, zooms, pans, reframing, camera movement, scene changes, or transition effects. Mia remains on the left and Adam remains on the right. Noah does not appear. Do not add other characters.

Keep the wrapped gifts closed and untouched. Keep the undecorated cake, frosting bowl, and spatula visible but unused throughout this video.

**Action and dialogue sequence:**

**0.2–3.1 seconds — Mia:** “Did Noah invite you to the party?”

Mia looks at Adam with a friendly, curious expression and makes a small questioning gesture with one open hand. Only Mia speaks and moves her mouth.

**3.1–3.4 seconds — Silent beat:**

Mia lowers her hand slightly. Adam maintains eye contact and prepares to answer.

**3.4–8.3 seconds — Adam:** “Yes, and he will be surprised when he unwraps the gifts.”

Adam smiles and nods once. While speaking, he makes a gentle open-hand gesture toward the wrapped gifts without touching them. Mia follows his gesture with her eyes. Only Adam speaks and moves his mouth.

**8.3–8.6 seconds — Silent beat:**

Adam returns his hand to a relaxed position. Mia looks from the gifts back to Adam.

**8.6–11.8 seconds — Mia:** “Really? What did you buy for him?”

Mia raises her eyebrows with interested curiosity and briefly gestures toward the gift nearest Adam. She does not touch or open it. Only Mia speaks and moves her mouth.

**11.8–13 seconds — Final hold:**

Mia lowers her hand and waits for Adam’s answer with a curious smile. Adam looks back at her with a small, playful, secretive smile but does not answer. End on a stable held frame. The characters, gifts, cake-preparation items, lighting, and composition remain unchanged.

Use clear, warm, natural adult English voices with accurate lip synchronization. Speakers talk one at a time with no overlapping dialogue. Include all three lines exactly as written and in the specified order. Do not add, omit, repeat, or paraphrase dialogue. Use subtle ambient room sound only, with no background music. No narration, subtitles, captions, speech bubbles, readable text, extra voices, or off-screen dialogue.


### Clip 2.2: The Gifts and Cake (Lines 3–5, approximately 9.2s)

> **Prompt:** Create an approximately **10-second, 1:1 square**, clean professional flat-vector lifestyle animation for adult English learners. Begin exactly from the supplied starting frame.

Preserve the supplied character identities, faces, hairstyles, clothing, body proportions, positions, room layout, furniture, decorations, props, colors, lighting, and fixed camera composition. Do not add, remove, replace, or redesign anything. Only make the character and prop movements explicitly described below.

Use one continuous locked-off wide shot. No cuts, zooms, pans, reframing, camera movement, scene changes, or transition effects. Keep Mia, Adam, the wrapped gifts, and the cake-preparation area visible throughout. Noah remains off-screen, and no additional characters appear.

**Opening pose:** Begin with Mia waiting for Adam’s answer with a curious smile. Adam looks back at her with a small, playful, secretive smile. Both begin still, with their mouths closed.

**Action and dialogue sequence:**

**0.2–3.8 seconds — Adam:** “I cannot say, but we will enjoy the party.”

Adam gives a small playful head shake and briefly raises one hand in a gentle “it is a secret” gesture. As he mentions enjoying the party, his expression becomes warmer and he makes a relaxed open-hand gesture toward Mia. He does not touch, move, or open any gift. Only Adam speaks and moves his mouth.

**3.8–4.1 seconds — Silent beat:**

Adam lowers his hand. Mia smiles and briefly looks toward the cake-preparation area.

**4.1–6.8 seconds — Mia:** “Great. Let’s prepare the cake too.”

Mia brightens and gestures with one open hand toward the cake and preparation tools. Adam follows her gesture with his eyes and nods once. Only Mia speaks and moves her mouth.

**6.8–9.4 seconds — Cake-preparation movement:**

Only after Mia completely finishes speaking, Mia and Adam turn toward the cake-preparation area. Each takes no more than one small natural step toward it. Mia carefully reaches for and lifts the cake spatula. Adam stands beside her and gestures toward the cake and frosting bowl. Keep the movement simple and controlled. Do not begin spreading frosting, cutting the cake, lighting candles, or adding decorations.

**9.4–10 seconds — Final hold:**

End on a stable held frame with Mia holding the spatula naturally near the frosting bowl and Adam standing beside her, ready to help. Both smile gently toward the cake. All wrapped gifts remain stationary, closed, and untouched.

Use clear, warm, natural adult English voices with accurate lip synchronization. Speakers talk one at a time with no overlapping dialogue. Include both lines exactly as written and in the specified order. Do not add, omit, repeat, or paraphrase dialogue. Use subtle ambient room sound only, with no background music. No narration, subtitles, captions, speech bubbles, readable text, extra voices, or off-screen dialogue.


## 5. Image Dialogs

`<TBD — image dialogue placeholders for approved vocabulary best taught through a still visual/audio context. Do not add entries here until agreed.>`

### Image Question Placeholder

- **Context:** `<TBD>`
- **Adult characters:** `<TBD>`
- **Dialogue:** `<TBD>`
- **Teaching targets:** `<TBD>`
- **Template:** `<TBD>`
- **Image filename:** `<TBD>`
- **Image description:** `<TBD>`

## 6. Questions JSON Structure

`<TBD — questions.json content goes here once Section 3's dialogue and question-type mapping are agreed. Not filled in yet.>`

## 7. Translations JSON Structure

`<TBD — proposed changes to translations_list go here for review before being applied to the live translations.json. Do not duplicate the current live file here until a change is actually proposed.>`

## 9. Message Pipeline

Maximum messages: 20.
Order: oldest to newest.
Each agent appends one named message using `Claude`, `Codex`, or `Antigravity`; the Developer (`d`/`Developer`) may also comment directly.
When appending message 21, remove the oldest message first (FIFO), then append the new one.
Only current Birthday Party discussion messages belong here.
Formatting rule: every agent's acceptance/agreement list must use `✅` green checkboxes; every issue, disagreement, or open item must use `❌` red crosses. Use these markers consistently in all new pipeline comments.

---

<!-- The Birthday Party discussion starts here. -->
