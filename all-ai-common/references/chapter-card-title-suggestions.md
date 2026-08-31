# Chapter card title suggestions

Candidate on-screen titles/captions for the `Chapter` template (`{"template": "Chapter", "displayImage": "..."}`)
— a passive, non-quiz interstitial card (image + Continue button) marking a beat in a level, e.g. before a
video segment starts or when switching from video-embedded questions into standalone practice questions.

Reuse this list when adding `Chapter` cards to other sub-levels — pick whichever pair best fits that level's
actual content rather than defaulting to the same two every time.

## Greetings / Adults level — chosen pair

- Before the video segment: **"Watch & Learn"**
- After the video segment (before the standalone age/grammar questions): **"Keep Going to Finish"**

## Full candidate list

### Before-video / intro-style cards
- **Watch & Learn** — chosen. Short, active, matches the app's energetic tone.
- Let's Watch! — close alternative, slightly more casual/exclamatory.

### After-video / "a bit more content" cards
- **Keep Going to Finish** — chosen. Forward-motion, gamified tone (matches stars/diamonds framing), doesn't imply the video wasn't already interactive.
- Finish the Level — solid, more neutral/direct alternative if a level wants a plainer tone.
- A Few More Questions — honest about what's coming; softer than "Keep Going to Finish."
- Just One More Thing — casual, works for a level with only one trailing question.
- Before You Go... — atmospheric, works well right before a level's final beat.

### Rejected (with reasons — avoid these unless the framing genuinely fits)
- Level Video / More Questions — reads like an internal/dev label, not player-facing copy.
- Complete Your Practice / Finish with More Practice — **avoid whenever the video itself already contained interactive questions** (as in the VideoConversation template): calling the post-video segment "practice" wrongly implies the video part wasn't already quizzing the player.
- More Questions to Complete — grammatically awkward as a title, reads like a to-do list.
- Continue the Level — accurate but flat, doesn't add energy over having no card at all.
- Final Level Questions — clear and honest, but leans back toward the dry/technical tone we moved away from with "Level Video."

## Guidance for future levels

- Only call a post-video segment "practice" if the video itself was *not* already interactive (e.g. a pure
  narrative/exposure video with no embedded quiz questions). If the video already asked questions (like this
  level's `VideoConversation` rows), use one of the "a bit more content" options instead.
- Keep titles short (2–4 words) — these are title-card beats, not descriptions.
- Prefer forward-motion/action framing ("Watch & Learn," "Keep Going to Finish") over purely descriptive
  labels ("Level Video," "Final Level Questions") to match the app's existing gamified tone.
