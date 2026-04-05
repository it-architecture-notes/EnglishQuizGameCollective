# Active Progress Context

## Active Issue: New Image and Vocab Question Templates

Description: Additional question templates with design and animations will be added to the game.

Use Case:

1. Convo-Template-Appear-Disappear (Sequence Memory from Disappearing Words)
Description:
A sentence appears word-by-word at the top. Each word disappears after a short delay. Then the player must tap the words in the correct order from a 3×3 grid below.

Parameters:
display_duration (default: 1 sec) – how long each word is shown before disappearing.
auto_next_delay (default: 1 sec) – wait time after a correct full sequence before moving to next question.

Step-by-step:
Sentence is shown one word at a time in the top area.
After the last word disappears, a prompt appears: “Click in order”. Add “ghost preview” mode After disappearance, show:_ _ _ _ _ (word slots)

Below, a 3×3 grid shows 9 words (some from the sentence + distractors).

Player taps words in the same order as the original sentence.

If correct tap:
Word tile turns green. Word is placed in the right place in the ghost preview.
A small number appears on the tile (1, 2, 3… for its position in the sentence).

If wrong tap (wrong word or wrong order):
All tile presses are disabled. The last pressed wrong tile turns to red. All right words will be placed in the ghost preview.
A “Next” button appears. Ensure there is a distinct visual difference between words the player correctly placed and the words the system auto-filled after a mistake. Suggestion: Use a solid background for player-correct words and a dashed border/semi-transparent look for the system-filled words.

If full sentence order completed correctly:
An “OK” sign appears. and auto to next.

2. Simon Game Template (Light & Repeat Word Order)
Description:
Words from a sentence are placed on: 3×3 grid. Like Simon, tiles light up (and optionally play a tone) in the order of the sentence. Player repeats the sequence by tapping tiles.

Parameters:
auto_next_delay (default: 1 sec)
tile_highlight_duration (default: 0.5 sec) – how long each tile lights up during demo.

Step-by-step:
Sentence is configured (e.g., “I like apples”) and also distractors are configured in the question.
Words are shuffled onto a 3×3 grid (extra empty or distractor tiles possible).

Game shows the sequence: each tile in sentence order lights up (and plays sound).

Player taps tiles in the same order.

Correct tap: tile turns green, shows its position number (1, 2, 3…).

Wrong tap (wrong tile or wrong order):
All tiles disabled. Last pressed tile is red. The expected tile is green and the full sentence is presented on the top of the tiles. To keep it clean, make sure the 3x3 grid dims slightly when the full sentence appears at the top so the player’s eye is drawn to the correct text for reading practice.

“Next” button appears.
If full sequence correct: all correct tiles green → OK sign → auto-next.

3. Cloze with One-by-One Appear (Fill-in-sequence)
Description:
A sentence appears word-by-word, but cloze positions (missing words) show _____ with a number. Player must select missing words in the correct order from a tile grid. Distractors is in the config of the question.

Parameters:
auto_next_delay (default: 1 sec)
grid_size: 2×2 for 1 cloze, 3×3 for 2+ clozes.

Step-by-step:
Sentence words appear one at a time in the top area and stay visible.
When a cloze word is reached, _____ (1) appears instead (incrementing for multiple clozes).

Bottom grid shows possible answers (target words + distractors).
Player selects words in the correct cloze order (e.g., fill blank 1, then blank 2).

Correct selection: tile turns green and shows the cloze number at the corner and placed in the cloze location.

Wrong selection: tiles disabled → Next button appears. The last pressed tile turns to red, expected tile turns to green. On fail → show full correct sentence Highlight filled words

All clozes filled correctly: OK sign → auto-next.

4. Image Template – Find Correct Object from Noun
Description:
A noun is shown at the top. Below, 4 images are displayed. Player taps the image matching the noun.

Logic:
Same as existing image question template but reversed (noun first → pick image).
Correct: image background turns green → auto-next after delay.
Wrong: selected image background turns red, correct turns to green → Next button appears.

Parameters:
auto_next_delay (default: 1 sec)
show_correct_on_wrong (default: false)


FAQ: 
- For cloze template UX flow. If the sentence is: "The [1] jumped over the [2] dog," and the player taps the word for blank [2] first, what happens? - If they press word 2 first the question is wrong.
- If the sentence has 5 words but the grid has 9 tiles (4 distractors), should the player be allowed to tap distractors at all? Yes and it will be a wrong selection
- On wrong tap, do you want to replay the correct sequence once (to teach the player) before disabling tiles, or just fail immediately? - We show the correct order by showing the full sentence.
- After a cloze is filled correctly, does the _____ (1) in the sentence above get replaced by the selected word immediately, or only after all clozes are filled? - Immediately
- 
