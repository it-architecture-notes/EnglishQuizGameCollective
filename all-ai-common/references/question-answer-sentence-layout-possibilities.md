# Question, answer, and sentence layout possibilities

This catalog defines the reasonable content-shape variants that quiz layouts must support at normal text scale. It describes content geometry, not device-specific dimensions. The responsive reference viewport matcher and the active gameplay design contract remain the source of sizing and safe-area rules.

## Shared constraints

- A **line** means one rendered line at the active layout's normal text size.
- A `DialogueCompletion` question always has exactly four answer buttons.
- DialogueCompletion answer choices may use one or two lines. Three-line answer buttons are not a reasonable production design.
- Sentence/dialogue text may use one, two, or three lines where stated below.
- Tile-choice groups may use at most three rows, except Cloze tile-choice groups, which may use at most two rows.
- Word-slot groups may use at most two rows.
- Equivalent answer buttons or tiles in one question retain equal typography and matching control height.
- These are the normal production variants. Content exceeding them should be shortened or handled by the established overflow/accessibility behavior rather than creating a new layout shape.
- **Media (image or video) is mandatory going forward in every template below except `ImageQuizTemplate-2` and `WordPairs`.** No new question in any other template may omit media. Media-absent is not a supported production variant and is not enumerated in the tables below; the image-optional code paths (`hasImage`/`imagePath` branches) remain for legacy content authored before this rule.

## Standalone DialogueCompletion

The standalone dialogue box/sentence uses one to three lines. All four stacked answer buttons have a shared one-line or shared two-line height.

| Dialogue box / sentence | Four answer-button height |
|---|---|
| 1 line | 1 line each |
| 2 lines | 1 line each |
| 3 lines | 1 line each |
| 1 line | 2 lines each |
| 2 lines | 2 lines each |
| 3 lines | 2 lines each |

## Video DialogueCompletion

Video DialogueCompletion has no separate dialogue box or sentence prompt: the video and its audio provide the setup. It always shows four stacked answer buttons. The shared video box must not change between equivalent video questions.

| Four answer-button height |
|---|
| 1 line each |
| 2 lines each |

## Video SentenceBuilder

Video SentenceBuilder has no standalone prompt or audio row: the paused video and its audio provide the setup. It shows a built-sentence/word-slot group and selectable tiles below the fixed video box.

| Sentence/word-slot rows | Selectable-tile rows |
|---|---|
| 1 | 1 |
| 1 | 2 |
| 1 | 3 |
| 2 | 1 |
| 2 | 2 |
| 2 | 3 |

## Video ClozeSequence

Video ClozeSequence has no standalone prompt or audio row: the paused video and its audio provide the setup. Its cloze sentence may use one, two, or three lines; its selectable tile group may use one or two rows.

| Cloze sentence lines | Cloze tile rows |
|---|---|
| 1 | 1 |
| 1 | 2 |
| 2 | 1 |
| 2 | 2 |
| 3 | 1 |
| 3 | 2 |

### Video single-word cloze

A video one-word cloze uses a one- or two-line sentence and four choices in a 2 × 2 grid. All four choice cells share the same single-line control height.

| Cloze sentence lines | Choices |
|---|---|
| 1 | 2 × 2, single-line cells |
| 2 | 2 × 2, single-line cells |

## Video AppearDisappear

Video AppearDisappear has no standalone prompt or audio row: the paused video and its initial audio provide the setup. Empty or filled word slots use one or two rows, and selectable tiles use one, two, or three rows. The one-use **listen again** button, when available, is shown above the slots and does not create another layout variant.

| Word-slot rows | Selectable-tile rows |
|---|---|
| 1 | 1 |
| 1 | 2 |
| 1 | 3 |
| 2 | 1 |
| 2 | 2 |
| 2 | 3 |

## ConvoTemplate-1 (2 × 2 dialogue completion)

This variant shows exactly two dialogue lines above four choices in a 2 × 2 grid. Each dialogue line may independently use one, two, or three rendered lines. Every grid cell is a shared single-line height; two-line answer cells are not a supported production layout.

| Dialogue line 1 | Dialogue line 2 | Four 2 × 2 choice cells |
|---|---|---|
| 1 line | 1 line | 1 line each |
| 1 line | 2 lines | 1 line each |
| 1 line | 3 lines | 1 line each |
| 2 lines | 1 line | 1 line each |
| 2 lines | 2 lines | 1 line each |
| 2 lines | 3 lines | 1 line each |
| 3 lines | 1 line | 1 line each |
| 3 lines | 2 lines | 1 line each |
| 3 lines | 3 lines | 1 line each |

## SentenceBuilder

SentenceBuilder shows a one- or two-line prompt (with its audio control when present), a built-sentence/word-slot group, and a selectable tile group. The sentence/slot group may occupy one or two rows; the tile group may occupy one, two, or three rows. **A prompt line is mandatory going forward** — unlike `AppearDisappear`, `SentenceBuilder` may not omit `line1`; a no-prompt `SentenceBuilder` is not a supported production variant.

| Prompt lines | Sentence/word-slot rows | Selectable-tile rows |
|---|---|---|
| 1 | 1 | 1 |
| 1 | 1 | 2 |
| 1 | 1 | 3 |
| 1 | 2 | 1 |
| 1 | 2 | 2 |
| 1 | 2 | 3 |
| 2 | 1 | 1 |
| 2 | 1 | 2 |
| 2 | 1 | 3 |
| 2 | 2 | 1 |
| 2 | 2 | 2 |
| 2 | 2 | 3 |

The completed sentence may wrap naturally within its maximum two-row word-slot layout. Tile labels remain single-line controls.

## AppearDisappear

AppearDisappear has an optional zero-, one-, or two-line prompt (with its audio control when present), then uses the same slot-and-tile geometry as SentenceBuilder. Before interaction, empty slots occupy the same one- or two-row layout; after recall/playback, filled slots use the same layout without a geometry jump. **`AppearDisappear` is the only template permitted to omit the prompt line** — when absent, `audio1` narrates the target words directly with no lead-in line; `SentenceBuilder` and `ClozeSequence` may not use this shape.

| Prompt lines | Word-slot rows | Selectable-tile rows |
|---|---|---|
| 0 | 1 | 1 |
| 0 | 1 | 2 |
| 0 | 1 | 3 |
| 0 | 2 | 1 |
| 0 | 2 | 2 |
| 0 | 2 | 3 |
| 1 | 1 | 1 |
| 1 | 1 | 2 |
| 1 | 1 | 3 |
| 1 | 2 | 1 |
| 1 | 2 | 2 |
| 1 | 2 | 3 |
| 2 | 1 | 1 |
| 2 | 1 | 2 |
| 2 | 1 | 3 |
| 2 | 2 | 1 |
| 2 | 2 | 2 |
| 2 | 2 | 3 |

## ClozeSequence

ClozeSequence has a one- or two-line prompt (with its audio control when present), a sentence with one or more blanks, and a selectable tile group. The cloze sentence may use one, two, or three lines. Cloze answer tiles may use one or two rows only. **A prompt line is mandatory going forward** — same rule as `SentenceBuilder`; a no-prompt `ClozeSequence` is not a supported production variant.

| Prompt lines | Cloze sentence lines | Cloze tile rows |
|---|---|---|
| 1 | 1 | 1 |
| 1 | 1 | 2 |
| 1 | 2 | 1 |
| 1 | 2 | 2 |
| 1 | 3 | 1 |
| 1 | 3 | 2 |
| 2 | 1 | 1 |
| 2 | 1 | 2 |
| 2 | 2 | 1 |
| 2 | 2 | 2 |
| 2 | 3 | 1 |
| 2 | 3 | 2 |

### Single-word cloze

A one-word cloze has a one- or two-line prompt (with its audio control when present), a one- or two-line sentence, and four choices in a 2 × 2 grid. All four choice cells share the same single-line control height.

| Prompt lines | Cloze sentence lines | Choices |
|---|---|---|
| 1 | 1 | 2 × 2, single-line cells |
| 1 | 2 | 2 × 2, single-line cells |
| 2 | 1 | 2 × 2, single-line cells |
| 2 | 2 | 2 × 2, single-line cells |

## WordPairs

WordPairs uses two stable columns of matching tiles. It is an intentional exception to the shared-height rule: each tile independently takes a one- or two-line height according to its own label, so adjacent or paired tiles may have different heights. Matching does not reflow either column. **Pair count is intentionally not a table dimension**: each tile is always one or two lines regardless of set size, and the answer area falls back to scroll once the column height exceeds its budget — a 4-, 5-, or 6-pair set is the same layout shape, just a different scroll length, not a new one.

| Tile-label combination | Column arrangement |
|---|---|
| All tiles 1 line | Two stable columns |
| Mixed 1- and 2-line tiles | Two stable columns; each tile keeps its intrinsic supported height |
| All tiles 2 lines | Two stable columns |

## ImageQuizTemplate-1

ImageQuizTemplate-1 has one fixed layout: a centered hero image in its media frame followed by four equal answer cells in a 2 × 2 grid. It has no separate prompt or audio-control row. Answer labels retain the shared one- or two-line support, but the overall layout arrangement does not change.

| Media | Answer arrangement |
|---|---|
| Centered hero image | 2 × 2, four equal answer cells |

## ImageQuizTemplate-2

ImageQuizTemplate-2 has one fixed layout: a single-line noun prompt with its audio control, followed by four equal image-choice cells in a 2 × 2 grid. It has no hero-image row separate from the answer grid.

| Prompt | Answer arrangement |
|---|---|
| 1 line with audio control | 2 × 2, four equal image-choice cells |
