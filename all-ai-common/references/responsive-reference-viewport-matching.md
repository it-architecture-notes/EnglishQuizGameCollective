# Responsive reference viewport matching

This document records the approved direction for the next responsive-layout system. It is a reference for implementation and complements, rather than replaces, the active quiz-screen design contract in `responsive-design-rules.md`.

## Scope and core principle

Use a finite set of representative **logical viewport** resolutions. Do not use raw physical/native panel resolutions, device manufacturer names, or a layout for every possible resolution.

Use the framework's post-density-scaling viewport dimensions (Flutter: `MediaQuery` / `View` logical size). The system must:

1. Obtain the actual usable logical viewport width and height.
2. Select the phone or tablet reference pool using the app's logical-size/device-class mechanism.
3. Calculate `actualRatio = actualHeight / actualWidth`.
4. Consider only references where `reference.height / reference.width <= actualRatio`.
5. Sort eligible references by `abs(reference.width - actualWidth)` and consider up to the four closest-width candidates.
6. For each candidate, calculate `scale = actualWidth / reference.width` and `scalingAmount = abs(1 - scale)`.
7. Select the candidate with the least scaling. If scaling is effectively tied, choose the closest H/W ratio.
8. Scale the selected reference uniformly to actual width; never scale X and Y independently.
9. Vertically center the fitted reference content area.
10. Let the normal page background extend into unused top/bottom space. Do not use black letterboxing.

Width is intentionally the primary match after ratio eligibility: it has a major effect on text wrapping, answer widths, margins, touch targets, card dimensions, media sizing, and perceived UI scale. Small unused vertical background space is preferred to large overall scaling.

## Normal matching algorithm

```text
actualWidth = usableLogicalWidth
actualHeight = usableLogicalHeight
actualRatio = actualHeight / actualWidth

references = phone ? phoneReferences : tabletReferences
eligible = references where reference.height / reference.width <= actualRatio

if eligible is not empty:
  candidates = eligible sorted by abs(reference.width - actualWidth), take first 4
  selected = candidate minimizing abs(1 - actualWidth / candidate.width)
  if scaling is effectively tied:
    choose closest H/W ratio

  scale = actualWidth / selected.width
  scaledHeight = selected.height * scale
  unusedVertical = actualHeight - scaledHeight
  topExtra = unusedVertical / 2
  bottomExtra = unusedVertical / 2
```

The ratio filter comes before width because a reference whose H/W ratio is greater than the actual viewport would become too tall when scaled to actual width.

### Examples

- Actual `430 × 950`, ratio `2.209`: `430 × 932` is selected over nearby eligible references because it has zero width scaling. The remaining 18 logical units are normal background space, about 9 above and below.
- Actual `448 × 997`, ratio about `2.225`: `440 × 956` is preferred when eligible because `448 / 440` is about `1.018`, even if another reference has a slightly closer ratio but a worse width match.

## Short-viewport fallback

If no reference satisfies the normal ratio eligibility condition:

1. Find references with the closest H/W ratio.
2. From those candidates, prefer closest width.
3. Uniformly scale the chosen reference to **fit height** rather than width.
4. Center horizontally.
5. Let normal page background fill unused left/right space.
6. Never crop structured UI.

This is a fallback path only.

## Phone reference pool

Centralize these portrait logical reference viewports:

| Class | Logical viewport |
|---|---:|
| Compact / legacy | 375 × 667 |
| Compact tall | 375 × 812 |
| Mainstream Android | 360 × 800 |
| Mainstream modern iPhone | 390 × 844 |
| Modern iPhone | 393 × 852 |
| Slightly taller modern phone (keep only if testing proves useful) | 393 × 873 |
| Modern Android flagship | 412 × 915 |
| Legacy large iPhone | 414 × 896 |
| Large modern iPhone | 430 × 932 |
| Extra-large modern iPhone | 440 × 956 |

The list is a set of reference classes, not device-specific layouts. Configuration order does not matter; matching is dynamic. Do not add device-name conditional logic.

An ultra-tall foldable cover-display reference may be added only after framework testing identifies its real logical viewport. An unfolded, large, nearly square foldable should normally enter the tablet/large-screen path, not the phone pool.

## Tablet reference pool

Centralize these portrait logical reference viewports:

| Class | Logical viewport |
|---|---:|
| Modern iPad mini | 744 × 1133 |
| Older / classic iPad | 768 × 1024 |
| Mainstream Android tablet | 800 × 1280 |
| iPad 10.2-inch | 810 × 1080 |
| Modern mainstream iPad / iPad Air | 820 × 1180 |
| Modern 11-inch iPad Pro | 834 × 1210 |
| Large Android tablet | 876 × 1400 |
| Extra-large Android tablet | 924 × 1480 |
| Large iPad | 1024 × 1366 |
| Newer large iPad Pro | 1032 × 1376 |

Older `834 × 1194` iPad Pro coverage should be naturally approximated; add it only if testing proves a separate reference materially improves matching.

## Classification, safe areas, and runtime changes

- Classify phone versus tablet from logical viewport characteristics and existing design requirements, never physical pixels or model names.
- The matcher must re-evaluate when the logical viewport changes, including fold/unfold and runtime resize.
- Preserve existing safe-area architecture. Do not blindly subtract status bars, home indicators, cutouts, or navigation bars if Flutter has already represented them through insets.
- Intended flow: full logical viewport → safe-area information → reference layout calculation → screen content layout.
- Background may extend behind safe areas when the existing design allows it; important interactive content continues respecting safe areas.

## Architecture direction

Implement centralized reusable infrastructure. Conceptual names include:

```text
ReferenceViewport
ReferenceViewportPool
ReferenceViewportMatcher
SelectedReferenceViewport
scaleFactor
contentBounds
unusedTop
unusedBottom
deviceClass
```

Use project naming conventions. Phone and tablet reference tables must be easy to modify later.

Once selected, a reference layout is rendered as one coordinated system with its uniform scale. Do not independently scale text, buttons, media, or regions simply to consume unused vertical space.

## Required validation fixtures

Validate at debug level or through automated coverage for:

- exact reference-size matches;
- unknown widths between two references;
- unknown ratios between reference classes;
- very tall phones and short compact phones;
- modern Pixel-like viewports and large iPhones;
- Android tablets and iPads;
- unusual artificial intermediate viewports;
- fold/unfold and runtime viewport resize where supported.

Do not limit validation to named real-device dimensions; artificial intermediate values must demonstrate that the matcher generalizes.

