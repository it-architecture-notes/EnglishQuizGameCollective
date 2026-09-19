# Baby Care — Adult Level Content Plan

## Current Topic

`<TBD — describe what this planning round is for: e.g. adding a VideoConversation intro to the existing adult Baby Care level, reworking specific questions, etc.>`

## 1. Decisions

- Scope is adults only. Kids content (`baby-care/kids/`) will be planned separately.
- This document belongs exclusively to the Baby Care level. Do not carry over another level's content unless it is deliberately approved as reinforcement.
- The English teaching vocabulary is the source of truth. Questions and dialogues must be created from the approved vocabulary, not used to expand it accidentally.
- Existing level distributions must be checked before adding vocabulary so words already taught in earlier levels are not repeated without a clear teaching reason.
- Vocabulary taught primarily by image-only levels must be checked before selecting tangible nouns for this level.
- `questions.json` and `translations.json` currently hold **live, already-shipped** content (13 approved vocabulary items, 15 questions across `imageQuizTemplate-1`, `ClozeSequence`, `ConvoTemplate-1`, `WordPairs`, `DialogueCompletion`, `AppearDisappear`, `imageQuizTemplate-2`, `SentenceBuilder`). Nothing has been cleared yet — no live file changes happen until new questions are proposed and agreed here first.
- Adult-oriented characters and settings should be used throughout the level. Any secondary characters must be older teenagers or adults, with mature proportions and styling; do not use young children in adult-level scenes (standing rule from the At the School level). A baby/infant character is the expected exception here given the level's subject matter — treat as a prop/scene element, not a speaking character.
- No automated test code will be created for this content-planning work, per project rules. JSON syntax and content consistency will be validated before implementation.
- **Section 3 shows the dialogue with inline annotations** (developer preference): each line gets the approved word(s) it carries and, where graded, its question template in parentheses/suffix. Full mechanic detail (exact answer, distractors, audio1/audio2 mapping, timestamps) still lives in Section 6 — Section 3's tags are a quick-reference summary, not the source of truth for those specifics.
- **Video prompts must be fully self-contained** (see `all-ai-common/rules/rules.md` § Video Generator Prompt Authoring): the developer can only paste the quoted prompt text into the video generator, nothing else from Section 4. Every generation-relevant detail — room/character description, exact dialogue, per-line gestures, required silent beats, the held final frame, negative constraints — must live inside the prompt block itself, not only in surrounding bullets.
- **Section 3/6 sequencing**: Section 6 (and Section 4's clip prompts) only get drafted after Section 3's dialogue and question-type mapping are actually agreed — not before.

## 2. Actions

1. Confirm the approved teaching scope from `translations.json`.
   - Review earlier levels for vocabulary overlap.
   - Classify each of the approved words as required, reinforcement, or remove.
   - Identify any gaps in the approved Baby Care teaching scope not yet covered.

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

7. Validate the complete Baby Care level.
   - Parse JSON and verify every referenced asset.
   - Check vocabulary coverage and unintended repetition.
   - Play through every question at normal text scale and supported accessibility text scale.
   - Check audio timing, feedback, progression, and question totals.

## 3. Video Dialog

**Mom:** Please whisper. The baby is sleeping. (`to whisper`) — `AppearDisappear`
**Dad:** Too late—she just started to cry. (`to cry`)
**Mom:** Let's feed her. That should calm her down. (`to feed`) — `DialogueCompletion`
**Dad:** You prepare the bottle, and I'll hold her gently. (`to hold`, `gently`) — `ClozeSequence` (double blank)
**Mom:** Could you change her diaper first? (`to change`)
**Dad:** Sure. Look—she is already starting to smile! (`to smile`) — `DialogueCompletion`
**Mom:** Now I want to kiss her soft little cheek. (`to kiss`) — `AppearDisappear`

## 4. Video Scripts

### Clip 1.1: The Baby Wakes Up (Lines 1–4, approximately 14.6s)

> **Prompt:** Create an approximately **14.6-second, 1:1 square**, clean professional 2D flat-vector lifestyle animation for adult English learners. Begin exactly from the supplied starting image while treating every specification below as authoritative and self-contained. Use clear consistent dark outlines, natural adult body proportions, restrained facial animation, warm neutral colors with dusty-rose, muted-teal, cream, and pale-yellow accents, and soft evening nursery lighting. Use one continuous fixed wide shot with no cuts, zooms, pans, reframing, camera movement, scene changes, or transition effects.
>
> Show exactly two adults and one newborn in a calm modern nursery. **Mom** is an adult woman in her early thirties with medium-brown skin, shoulder-length wavy dark-brown hair tied in a low ponytail, and mature facial features. She wears a dusty-rose cardigan over a cream shirt, navy trousers, and simple beige flats. She stands on the left side of the room beside a low bottle-preparation dresser. **Dad** is an adult man in his early thirties with medium skin, short slightly curly black hair, and mature facial features. He wears a muted-teal long-sleeve shirt, charcoal trousers, and dark house shoes. He stands on the right side of a waist-high bassinet, facing Mom. **Baby** is a very small newborn girl with fine dark hair, wearing a pale-yellow long-sleeve footed onesie and initially lying safely on her back in the bassinet beneath a lightweight cream blanket that reaches only to her waist. The baby remains fully clothed throughout.
>
> Preserve a strict fixed nursery layout. A waist-high cream bassinet stands in the center foreground between Mom and Dad. The bottle-preparation dresser remains against the left wall and holds one clean empty baby bottle, one capped container of prepared formula, and one folded burp cloth. A padded changing table with a raised safety edge stands against the right wall and holds a closed diaper package and one folded baby blanket. Behind the bassinet is one window with closed pale curtains. A soft-shaded floor lamp stands in the back-left corner, and one plain upholstered chair stands in the back-right corner. The floor is light wood with one fixed cream rug. Do not add, remove, replace, duplicate, or unexpectedly move any environmental element or prop.
>
> Use accurate natural lip-sync and clear conversational turn-taking. Mom has a warm, quiet adult female voice. Dad has a calm adult male voice. Only the named adult speaker uses speech lip movements; the other adult keeps their mouth completely closed. The baby may use subtle non-speaking facial and mouth movement while waking or fussing, but must never appear to speak. Permit only a very soft, brief infant cry during the silent waking action; it must end before Dad begins speaking and must not overlap or obscure any dialogue. Do not add narration, background speech, music, or other sound effects. Preserve the following dialogue exactly; do not paraphrase, shorten, omit, repeat, or reorder any words.
>
> Begin with a quiet 0.5-second opening hold. Mom stands to the left of the bassinet with one index finger already resting naturally near her lips. Dad stands to the right, looking toward Mom. The baby sleeps peacefully on her back with her eyes closed and mouth closed. Dad and the baby remain still and quiet.
>
> **Line 1:** Mom looks toward Dad, keeps one finger near her lips in a restrained quiet gesture, and speaks softly: “Please whisper. The baby is sleeping.” Dad listens without speaking or moving his mouth. The baby remains asleep and still throughout the full sentence.
>
> After Mom finishes, she closes her mouth and lowers her hand. Keep both adults settled around the end of the line so the frame can be paused cleanly. The baby then slowly opens her eyes, moves her arms only slightly, and begins to fuss with a small visible cry. Mom looks concerned, and Dad looks down toward the baby. The cry is gentle and brief, with no exaggerated body movement.
>
> **Line 2:** After the brief cry has stopped, Dad makes one small reassuring gesture toward the awake baby and says: “Too late—she just started to cry.” Mom listens with her mouth closed. The baby remains awake and mildly fussy but does not make noise over Dad's sentence.
>
> **Line 3:** Mom looks from the baby toward the bottle supplies on the left dresser and says: “Let's feed her. That should calm her down.” Dad listens with his mouth closed and keeps his hands relaxed near the bassinet. Mom must finish the complete line before beginning to prepare the bottle.
>
> **Line 4:** Dad looks at Mom and says: “You prepare the bottle, and I'll hold her gently.” While Dad speaks, Mom turns only slightly toward the left dresser and begins calmly preparing the bottle without spilling or shaking it. At the same time, Dad carefully places both hands around the baby, fully supports her head and neck, lifts her once from the bassinet in one slow stable motion, and holds her securely upright against his chest. Dad's handling must look gentle, competent, and anatomically safe. The cream blanket remains in the bassinet and does not cling to or lift with the baby.
>
> End on a calm stable continuity frame held from approximately **13.6–14.6 seconds**. Dad stands on the right holding the fully clothed, awake baby securely against his chest with her head and neck supported. The baby is slightly calmer and is not crying. Mom stands on the left at the dresser, continuing a small controlled bottle-preparation action. The empty bassinet remains centered, with the cream blanket lying neatly inside. The changing table and all other room elements remain fixed. Both adults' mouths are closed. This exact composition must be suitable as the supplied starting frame for Clip 1.2.
>
> **Timing targets — do not display these timings on screen:** 0.0–0.5 opening hold; 0.5–3.0 Line 1; 3.0–4.1 silent waking and brief crying action; 4.1–6.6 Line 2; 6.6–9.4 Line 3; 9.4–13.6 Line 4 and coordinated bottle-and-lifting action; 13.6–14.6 final continuity hold.
>
> Do not show readable words, letters, numbers, measurement markings, product labels, captions, subtitles, logos, watermarks, speech bubbles, or decorative text. Do not add extra adults, children, babies, pets, people in reflections, toys, or new nursery objects. Do not expose the baby's body, remove or change her onesie, change a diaper, feed the baby, place the baby in an unsafe position, or leave her unsupported. Avoid exaggerated crying, adult lip movement while not speaking, overlapping dialogue, character sliding, camera drift, furniture movement, prop duplication, objects appearing or disappearing, malformed hands, merged fingers, floating objects, distorted limbs, anatomy changes, clothing changes, or changes in character size.

### Clip 1.2: The Diaper Request and Smile (Lines 5–7, approximately 10.2s)

> **Prompt:** Create an approximately **10.2-second, 1:1 square**, clean professional 2D flat-vector lifestyle animation for adult English learners. Begin exactly from the supplied final held frame of the previous clip while treating every specification below as authoritative and self-contained. Use clear consistent dark outlines, natural adult body proportions, restrained facial animation, warm neutral colors with dusty-rose, muted-teal, cream, and pale-yellow accents, and soft evening nursery lighting. Use one continuous fixed wide shot with no cuts, zooms, pans, reframing, camera movement, scene changes, or transition effects.
>
> Show exactly two adults and one newborn in the same calm modern nursery. **Mom** is an adult woman in her early thirties with medium-brown skin, shoulder-length wavy dark-brown hair tied in a low ponytail, and mature facial features. She wears a dusty-rose cardigan over a cream shirt, navy trousers, and simple beige flats. She stands on the left beside the low bottle-preparation dresser. **Dad** is an adult man in his early thirties with medium skin, short slightly curly black hair, and mature facial features. He wears a muted-teal long-sleeve shirt, charcoal trousers, and dark house shoes. He stands on the right side of the central bassinet and securely holds the newborn against his chest with both hands supporting her head, neck, and body. **Baby** is a very small newborn girl with fine dark hair, wearing the same pale-yellow long-sleeve footed onesie. She remains fully clothed, awake, calm, and safely supported throughout.
>
> Preserve the exact supplied camera composition and strict fixed nursery layout. The waist-high cream bassinet remains centered in the foreground, now empty except for the lightweight cream blanket lying neatly inside. The bottle-preparation dresser remains against the left wall with the same baby bottle, capped formula container, and folded burp cloth. The padded changing table with raised safety edge remains against the right wall with the same closed diaper package and folded baby blanket. Preserve the window with closed pale curtains, soft-shaded floor lamp, plain upholstered chair, light wood floor, cream rug, props, colors, lighting, and every character's exact identity, face, hairstyle, proportions, clothing, and position from the supplied starting frame. Do not add, remove, replace, duplicate, or unexpectedly move any environmental element or prop.
>
> Use accurate natural lip-sync and clear conversational turn-taking. Mom has the same warm, quiet adult female voice used in the previous clip. Dad has the same calm adult male voice used in the previous clip. Only the named adult speaker uses speech lip movements; the other adult keeps their mouth completely closed. The baby may make subtle non-speaking facial movements but must never appear to speak or cry during this clip. Do not add narration, background speech, infant vocalizations, music, or sound effects. Preserve the following dialogue exactly; do not paraphrase, shorten, omit, repeat, or reorder any words.
>
> Begin with a quiet 0.4-second continuity hold matching the supplied starting frame. Dad remains on the right, holding the fully clothed baby securely against his chest with her head and neck supported. Mom remains on the left beside the bottle supplies. The empty bassinet stays centered. Both adults' mouths are closed.
>
> **Line 5:** Mom stops the bottle-preparation action, looks toward Dad and the baby, makes one small practical open-hand gesture toward the changing table, and says: “Could you change her diaper first?” Dad listens without speaking or moving his mouth and continues supporting the baby securely.
>
> After Mom finishes, both adults settle naturally. Dad glances briefly toward the changing table and then back at the baby. Keep his body and arms stable, and keep the baby fully supported so the frame can be paused cleanly before his response.
>
> **Line 6:** Dad looks down at the baby with a gentle smile and says: “Sure. Look—she is already starting to smile!” Mom watches attentively with her mouth closed. During the final part of Dad's sentence, the baby forms one small natural smile while remaining comfortably supported against his chest. Dad does not walk to the changing table or begin changing her diaper during the sentence.
>
> After Dad finishes, hold a brief natural turn-taking beat. Both adults close their mouths. Mom takes one small step toward Dad and the baby, stopping at a comfortable distance without blocking the baby's face.
>
> **Line 7:** Mom looks warmly at the baby's face and says: “Now I want to kiss her soft little cheek.” Dad listens with his mouth closed and continues holding the baby safely and steadily. The baby remains calm with a faint smile. Mom does not kiss the baby until she has completed the entire sentence.
>
> After Mom finishes, keep every mouth closed. Mom leans forward only slightly and gives the baby one gentle kiss on the visible cheek, then returns to a balanced upright posture. Dad remains still and maintains full support of the baby's head, neck, and body throughout the kiss.
>
> End on a calm stable final frame held from approximately **9.4–10.2 seconds**. Dad remains on the right holding the fully clothed baby safely against his chest. Mom stands close beside them with a warm expression and both hands relaxed. The baby is awake, calm, and faintly smiling. The empty bassinet and cream blanket remain centered, the bottle supplies remain on the left dresser, and the changing table and all other room elements remain unchanged. All mouths are closed. Do not add further dialogue or noticeable movement.
>
> **Timing targets — do not display these timings on screen:** 0.0–0.4 opening continuity hold; 0.4–2.8 Line 5; 2.8–3.2 settled response boundary; 3.2–5.9 Line 6; 5.9–6.2 silent turn-taking beat and Mom's small step; 6.2–8.9 Line 7; 8.9–9.4 gentle cheek kiss; 9.4–10.2 final hold.
>
> Do not show readable words, letters, numbers, measurement markings, product labels, captions, subtitles, logos, watermarks, speech bubbles, or decorative text. Do not add extra adults, children, babies, pets, people in reflections, toys, or new nursery objects. Do not expose the baby's body, remove or change her onesie, visibly change a diaper, feed the baby, transfer the baby between adults, place the baby in an unsafe position, or leave her unsupported. Avoid exaggerated facial expressions, adult lip movement while not speaking, overlapping dialogue, character sliding, camera drift, furniture movement, prop duplication, objects appearing or disappearing, malformed hands, merged fingers, floating objects, distorted limbs, anatomy changes, clothing changes, or changes in character size.

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
Only current Baby Care discussion messages belong here.
Formatting rule: every agent's acceptance/agreement list must use `✅` green checkboxes; every issue, disagreement, or open item must use `❌` red crosses. Use these markers consistently in all new pipeline comments.

---

<!-- The Baby Care discussion starts here. -->
