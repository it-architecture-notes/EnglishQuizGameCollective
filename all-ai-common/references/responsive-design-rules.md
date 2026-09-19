# Responsive design contract — active quiz gameplay screens

This document defines how every quiz question screen (video, image, and text-only templates
alike) sizes and arranges itself across devices, text scales, and languages. Scope: active
question gameplay only — the Chapter interstitial card, reminder-mode's distinct header, story
overlays, and non-gameplay screens (settings, achievements, levels list) are out of scope here
and covered elsewhere or left for later.

A) Shared layout principles
   - Every question screen is divided into a header/progress region, a media or image region, a prompt/dialogue region, an answer region, and a fixed Next/action region.
   - Regular non-image-template questions share one page shell: the same header implementation, the same media-frame sizing and clipping policy whenever media exists, and the same fixed Next/Finish action region. This includes VideoConversation, DialogueCompletion, ConvoTemplate-1, ClozeSequence, SentenceBuilder, and AppearDisappear.
   - ImageQuizTemplate-1 and ImageQuizTemplate-2 retain their specialized image-game layouts, and WordPairs retains its specialized two-column answer layout. They still follow the relevant accessibility, touch-target, and safe-area rules in this contract, but they are not required to use the regular question shell's media frame. Chapter cards are interstitials rather than questions and remain outside this shell.
   - A regular question without media reserves no empty media region. Adding or removing media changes only whether the shared media frame is present; it does not create a template-specific header or action region.
   - Percentage sizing uses usable portrait height as its denominator: full logical viewport height minus the current top and bottom safe-area insets. The safe-area pixels themselves are never included in or consumed by a percentage region.
   - Header, media, and Next/action-region shares are **not** a single min/preferred/max range per phone/tablet. They are fixed, non-jumping percentages resolved once per device from `QuestionLayoutBudget` (`lib/services/question_layout_budget.dart`) — a *two-stage* classifier kept intentionally separate from `resolution_service.dart`'s `ResolutionBucket` (which only selects a background-art asset folder and stays aspect-ratio-only on purpose; do not conflate the two systems or let one silently drive the other).
     - **Stage 1 — family, from absolute size**: `isTablet = shortestSide >= 600`. Aspect ratio never participates in this decision, because two devices in different families can share the same aspect ratio (a 16:9 phone and a 16:9 tablet both round to ~1.78 H/W) — aspect-only classification cannot tell them apart at any threshold.
     - **Stage 2 — tier, from aspect ratio, within the family already chosen**: 6 phone tiers (`phoneUltraTall`/`phoneSuperTall`/`phoneFlagship`/`phoneTransition`/`phoneClassic2to1`/`phone16to9`) and 4 tablet tiers (`tablet16to9`/`tablet16to10`/`tablet3to2`/`tablet4to3`), by `longestSide/shortestSide`.
     - Each of the 10 tiers has a fixed Header/Media/Footer percentage (of usable height) that never changes across questions on that device; the remainder is the template's own prompt/answer budget:

       | Tier | Aspect (H/W) | Header | Media | Footer | Remainder |
       |---|---:|---:|---:|---:|---:|
       | `phoneUltraTall` | ≥2.30 | 7.0% | 46.0% | 8.5% | 38.5% |
       | `phoneSuperTall` | 2.18–2.30 | 7.5% | 48.0% | 9.5% | 35.0% |
       | `phoneFlagship` | 2.10–2.18 | 8.0% | 50.0% | 8.0% | 34.0% |
       | `phoneTransition` | 1.95–2.10 | 8.5% | 47.0% | 10.0% | 34.5% |
       | `phoneClassic2to1` | 1.85–1.95 | 9.0% | 46.0% | 10.0% | 35.0% |
       | `phone16to9` | 1.70–1.85 (fallback below) | 9.0% | 43.0% | 10.0% | 38.0% |
       | `tablet16to9` | ≥1.65 | 7.5% | 44.0% | 8.5% | 40.0% |
       | `tablet16to10` | 1.55–1.65 | 7.0% | 48.0% | 8.0% | 37.0% |
       | `tablet3to2` | 1.40–1.55 | 6.5% | 50.0% | 7.5% | 36.0% |
       | `tablet4to3` | <1.40 (fallback) | 6.0% | 52.0% | 7.0% | 35.0% |

     - Media height and width are both computed from the real, locally measured `LayoutBuilder` constraints for the widget actually rendering them (`bodyConstraints.maxHeight`/`.maxWidth`), never from `MediaQuery` directly — a widget's real assigned space can be smaller than the full app window (nested inside this shell's own header/body/footer composition, or an actual split-screen/multi-window pane), and `MediaQuery` alone cannot see that. Header height is the sole exception: a `Scaffold` `AppBar`'s height is decided before its body's `LayoutBuilder` ever runs, so it structurally has to come from `MediaQuery`; that residual exposure is intentionally closed at the OS-config level (disabling multi-window) rather than in layout code.
     - Tablet media width is additionally capped at 560 logical pixels regardless of tier, so a wide-screen tablet cannot stretch a percentage-sized square media frame into something oversized or distorted.
     - This tier table governs the 6 shared-shell templates named in this section's second bullet. `imageQuizTemplate-1`/`-2` and `WordPairs` are out of scope for it, per the third bullet.
   - The 48-logical-pixel minimum interactive touch target remains the sole absolute sizing exception for these shell regions. If its percentage region would be smaller, the touch-target floor wins.
   - The header/progress region's rules (title/counter sizing, truncation behavior) are the same for every question, in every level — this is not something that varies by level content or is tuned per-level.
   - The header's level-title text has a bounded max size and, if a title is unusually long, wraps or truncates the same way every other equivalent-control text does (see K) rather than inventing header-specific truncation behavior.
   - The header's question counter ("Q N/M", or its reminder-mode equivalent) has a stable min/max size and does not change size based on the number of digits in N or M.
   - In the regular and answer-only-scroll profiles, the header, media/image, prompt, and Next/action control remain visible. Only the answer region may scroll. The last-resort accessibility profile in C is the sole exception.
   - At regular play and 100% text scale, normal English content must fit without scrolling.
   - Scrolling is a last-resort safety mechanism for larger accessibility text, unusually long localized content, larger tile/slot groups, or genuinely short viewports. Four-choice questions always contain exactly four answers as defined in D.
   - Use logical pixels, not physical device pixels.
   - Every repeated component must define minimum, preferred, and maximum sizes where applicable.
   - Every repeated component must define minimum and maximum spacing where applicable.
   - Repeated controls inside the prompt/answer region may retain logical-pixel accessibility floors, but the shared shell's header, media, prompt/answer reserve, and action-region design caps are percentage-based rather than device-specific fixed pixel allocations.
   - Extra space must not create oversized controls or excessive gaps.
   - Equivalent controls must use consistent typography, height, padding, and alignment.
   - Use finite constraints from LayoutBuilder before calculating sizes. Never read a height from a LayoutBuilder placed inside a vertical scroll view.
   - Do not place unconstrained Expanded widgets inside scroll views.
   - When absolute and relative bounds conflict, resolve them in this order: safe-area containment, minimum interactive touch target, minimum readable content size, relative target, then absolute maximum.
   - A layout profile is selected from the viewport, safe-area insets, content requirements, and accessibility settings. Components stay visually stable within that profile.
   - "Normal content" is represented by the Greetings adult level's production questions as the primary named fixture: four-choice answers of up to two lines, dialogue lines of up to two lines, SentenceBuilder/AppearDisappear groups of up to eleven total selectable tiles, Cloze sentences of up to two lines, the level's five-pair WordPairs question across its supported translations, and the longest configured Greetings guide message at the guide's 1.35x cap. No-scroll requirements are validated against this fixture rather than subjective judgment. Future production content that intentionally exceeds it uses the bounded fallback rules in this contract.

B) Regular gameplay sizing
   - At 100% text scale, media, prompts, answer controls, and Next must fit naturally for normal English content.
   - Reduce spacing and padding before reducing readable text size.
   - Reduce media height before reducing essential answer text.
   - Do not shrink only the longest answer. Equivalent answers must retain the same font size.
   - Use content-driven sizing within defined bounds rather than continuously stretching controls to consume all leftover height.
   - Center a compact answer group when there is extra space, while keeping gaps bounded.
   - The final answer control must not receive an unnecessary trailing gap.
   - Responsive profile selection uses the actual finite viewport constraints, safe-area insets, and rendered content measurements. It never assumes that 100% text scale means a standard-size viewport; platform display-size/zoom settings may reduce the logical viewport independently of text scale.

C) Accessibility and overflow
   - Do not disable, override, or cap the user's system text scaling.
   - The regular responsive layout profile covers 100% through 160% text scaling. Above 160%, the app may activate an accessibility-specific layout profile. The 160% boundary changes layout behavior; it is not a text-size cap.
   - Essential question, dialogue, answer, slot, and tile text continues to respect the active system TextScaler through at least 200%.
   - Preserve one shared font size for equivalent controls whenever possible.
   - Allow text to wrap to two lines by default; allow additional lines only where the template explicitly supports them.
   - Let controls grow within their maximum height before enabling scrolling.
   - Reduce media height, prompt spacing, panel padding, and gaps within safe limits before scrolling.
   - If the minimum usable layout still cannot fit, enable scrolling only for the answer controls.
   - In the regular and answer-only-scroll profiles, never scroll or hide the header, media/image, question/prompt, or fixed Next button.
   - Do not clip, overlap, or silently hide meaningful answer text.
   - Ellipsis is a final safeguard only and must not be the normal handling for meaningful quiz answers.
   - Meaningful answer text must never be made ambiguous by ellipsis. If truncation would hide answer-distinguishing content, wrap and scroll the answer region instead.
   - Maximum component heights are normal-layout bounds, not accessibility clipping limits. A control may exceed its normal maximum when required to render scaled text without clipping.
   - Do not assume text scaling is linear or derive layout from one numeric scale factor alone; measure the rendered constraints under Flutter's active TextScaler.
   - If media has reached its accessibility floor and the remaining answer viewport is smaller than one usable answer control, switch to the last-resort accessibility profile. The header and Next/action region remain fixed; media, prompt/dialogue, and answers become one vertically scrollable question-content region in their natural reading order. This is the only profile in which media or prompt content may scroll.
   - The last-resort accessibility profile opens at the top of the question content, keeps all answer-relevant media available, introduces no nested vertical scroller, and brings the selected answer and required feedback into view after interaction.
   - Text scale below 100% (a common OS setting, not just above) is not a special case: the same content-driven, bounded sizing applies and simply has more headroom to work with — no separate shrink-below-normal behavior is needed or should be added.

D) Four-choice answer buttons
   - Every single-choice question contains exactly one correct answer and exactly three distractors. Any other option count is invalid question data and is rejected by content validation; production playback skips the invalid question through the existing safe question-error path rather than inventing a different layout.
   - All four buttons have equal height in normal operation.
   - All four buttons use the same font size and line height.
   - Text supports up to two lines.
   - Buttons have bounded minimum, preferred, and maximum heights.
   - Buttons use bounded horizontal padding. Width is **not** independent per button and is **not** always the full answer-panel width: compute one shared width from the widest of the four options' natural rendered content width (at the active font size, plus padding), apply that same width to all four, capped at the answer panel's maximum width — the same tallest-answer-drives-shared-height pattern below, applied to the width axis. A short answer set (e.g. "yes"/"no"/"maybe"/"ok") renders as four modest, equally-narrow pills rather than four full-width pills with mostly empty space; a set containing one long option widens all four together to match it, same as height does.
   - Before accepting or editing four-choice answer content, check each option's rendered line count at the supported phone width and the active font size (see the tile/slot equivalent in E). If any option would require more than one line, warn the developer and recommend shortening that option before continuing. Two-line rendering remains a supported runtime fallback (see this section and C, L) for content that already shipped or for accessibility text scaling — it is a content-quality warning during authoring, not the design target for new four-choice content.
   - Buttons have bounded gaps, normally approximately 8–12 logical pixels.
   - Buttons must not stretch into oversized pills on tablets or tall screens.
   - Buttons use refined rounded rectangles with an approximately 20–24 logical-pixel corner radius, a near-white/light-gray neutral fill, a thin neutral outline, and flat or minimal depth rather than full capsules with prominent shadows.
   - The wrong state uses a pale red surface, red outline, dark-red text, and a red circular badge containing a white X.
   - If one answer requires two lines, all four buttons retain the same dimensions and typography.
   - If all four answers require two lines, calculate one shared height from the tallest rendered answer and apply it to all four; reduce media and bounded spacing before enabling answer-region scrolling.
   - At regular scale, the four-choice group must fit without scrolling whenever the content is normally usable.
   - At larger accessibility scales or unusually long translations, only the answer group may scroll.
   - In the accessibility-specific layout, answer text may use as many wrapped lines as required. All four buttons remain equal height, using the tallest answer's required height, and the answer region scrolls when the resulting equal-height group does not fit.
   - The Next button has minimum and maximum heights and may shrink within safe bounds to preserve the answer group.
   - A template that lays four choices out as a 2x2 grid instead of a single stacked column (e.g. ConvoTemplate-1) follows the same per-button rules above, with width halved (minus the inter-column gap) instead of full-width, and the same equal-height/equal-typography rule applying across all four cells, not just within a row.
   - Every interactive answer button has a touch target of at least 48 logical pixels in both axes, even when its visible decoration is smaller.

E) Tile, slot, and sentence questions
   - Applies to SentenceBuilder, AppearDisappear, ClozeSequence, Video tile questions, and WordPairs.
   - All selectable tiles use consistent typography and bounded height/padding.
   - All tiles in an equivalent group use the same text size, including across the two columns of a two-column layout (e.g. WordPairs) — a tile in the left column must not end up a different size than one in the right column.
   - A question whose combined tile/word-slot count is large enough that normal sizing would force scrolling at 100% scale switches as a whole to a smaller bounded sizing profile (tighter padding, smaller min/max height, smaller — but still readable — text) rather than scrolling; the exact item-count threshold is an implementation constant, not fixed here, but the behavior itself (bounded profile switch before scrolling) is part of the contract.
   - Word slots and filled blanks use consistent sizing and alignment; all word slots and sentence words in the same question share one text size, same as the tile-uniformity rule above.
   - Empty word slots use equal dimensions and never expose the length of their hidden words. Once filled, slots may expand and the complete slot group may reflow onto another line while preserving reading order.
   - Very short tile labels (for example "is", "am", "a", or "I") retain the shared tile height and touch target instead of collapsing to the text's intrinsic height. Tile widths may remain content-responsive within the question's shared minimum and maximum width bounds.
   - Repeated visible answer words in one tile question are invalid content and are rejected during content validation; tile questions do not rely on duplicate-word disambiguation behavior.
   - Cloze sentences and built sentences may wrap to a second line when needed.
   - Before accepting or editing tile-question content, count the rendered rows at the supported phone width. If word slots exceed 2 rows or answer tiles exceed 3 rows, warn the developer and recommend shortening the sentence or reducing distractors before continuing; these row counts are content-quality limits, not a reason to silently compress the controls.
   - Sentence words, word slots, cloze text, and tile-choice text each have their own minimum readable text size.
   - Tiles have minimum width and height, preferred bounds, and maximum bounds.
   - Tile gaps have minimum and maximum values and must not expand excessively on tall screens.
   - If there are few tiles or sentence words, the tile group and sentence/slot group must not become excessively far apart.
   - They must also retain enough separation to remain visually distinct and tappable.
   - Tile layouts should be centered when spare space exists.
   - If the minimum tile size and minimum text size are reached and the content still does not fit, the answer area may scroll.
   - Correct, wrong, selected, disabled, and revealed tile states use the shared answer color palette.
   - The Next button has minimum and maximum heights and may shrink within safe bounds to preserve tile controls.
   - WordPairs' matched tiles lock in their original position rather than reflowing into a separate "matched" group — row order is a stable landmark for the player and must not change size or position once matched.
   - WordPairs' pre-match "selected" state (a tile tapped but not yet paired) has its own stable styling and must not change that tile's size relative to its unselected siblings.
   - WordPairs' column header labels (source/target language names) follow the same equivalent-control typography rule as prompt text (H) and are sized independently of the tiles beneath them.
   - Every selectable tile has a touch target of at least 48 logical pixels in both axes; closely packed visible tiles may use transparent hit-area padding only when hit areas do not overlap.
   - A scrollable tile region must keep the focused, selected, wrong, or next-required tile visible and must not create nested vertical scrolling.

F) Video media
   - Video preserves its source aspect ratio and must not be stretched or squashed.
   - Video height uses the same fixed per-tier Media percentage defined in A (35%–44% of usable height depending on the resolved `QuestionLayoutTier`, not a flat 45%/55% phone/tablet split) — there is no separate video-specific percentage table. Width uses nearly the full available content width on phones; tablets are additionally capped at 560 logical pixels (A) rather than a flat 80% target. For a 1:1 video, its side is `min(available content width, tier media height, tablet width cap)`.
   - Both phone and tablet calculations reserve the header and fixed action region (via the same per-tier budget) before assigning vertical space to video; media height is computed from the real local `LayoutBuilder` constraints, not from `MediaQuery` directly (A).
   - The selected tier's media target is constant across every video question in a level, regardless of answer_type or content — video is one continuous asset chained across consecutive question rows, so its realized size must not visibly change question to question (unlike an image, which may vary; see G). This was intentionally re-coupled across the 4 video `answer_type`s (`DialogueCompletion`/`SentenceBuilder`/`ClozeSequence`/`AppearDisappear`) after briefly being made independent per answer_type — media is device-fixed, not per-template or per-answer_type.
   - If the normal answer reserve cannot fit at regular scale, the viewport profile may select a smaller common video height within its safe minimum; it never reduces the video for only one answer type.
   - Video remains visible and pinned while the answer area scrolls.
   - Video controls, playback state, and audio controls must not unexpectedly change the layout dimensions.
   - Resolve the phone/tablet targets through named adaptive profiles. Every video question in the same viewport/profile uses the same realized video box; a shorter viewport or accessibility profile may choose a smaller box for the entire video-question family, never a different size per answer type.
   - Video loading, first-frame preparation, pause, resume, and error fallback must reserve the same media box so playback state changes do not shift surrounding content.

G) Image media
   - Applies to imageQuizTemplate-1, imageQuizTemplate-2, DialogueCompletion, ConvoTemplate-1, GrammarForm, image SentenceBuilder, image AppearDisappear, image ClozeSequence, and other image-backed questions.
   - DialogueCompletion, ConvoTemplate-1, image SentenceBuilder, image AppearDisappear, image ClozeSequence, and other regular image-backed questions use the same shared media-frame profile as regular video questions. ImageQuizTemplate-1 and ImageQuizTemplate-2 remain specialized exceptions as defined in A.
   - Images preserve their source aspect ratio.
   - Regular-question image height follows the corresponding phone/tablet percentage media range in F; it does not introduce a separate fixed-pixel shell cap.
   - Unlike video, an image is not chained across consecutive questions, so its realized size may vary question to question with its own content and aspect ratio — only the cap has to stay constant, not the rendered size.
   - Define independent maximum width and maximum height constraints.
   - Images use consistent clipping, border radius, and alignment within a template family.
   - Do not unintentionally crop the important subject or answer-relevant visual information.
   - Use BoxFit rules intentionally: contain when the full image is required; cover only when cropping is acceptable and specified.
   - Image width is responsive and capped on tablets and wide screens.
   - Image height may reduce before reducing essential answer text when the answer area cannot fit.
   - Images remain visible and pinned while the answer region scrolls.
   - A question with no image field at all reserves no image space and shows no placeholder — the prompt/answer panel simply starts from the top of the section.
   - A question with an image field whose asset fails to load shows a fallback placeholder at the same capped box size instead of collapsing the layout, so the answer panel's position doesn't jump.
   - A question with neither image nor video (e.g. WordPairs) reserves no media space either — it goes straight to its prompt/answer rules, same "no reservation" behavior as the missing-image case.
   - Image-backed dialogue bubbles, prompts, and answer panels must not overlap the image unintentionally.
   - Image-based single-choice questions use the same bounded answer-button rules as video single-choice questions.
   - Image-based tile questions use the same bounded tile, slot, and sentence rules as video tile questions.
   - ImageQuizTemplate-1 must keep the question/prompt visually associated with the image and the answer controls.
   - ImageQuizTemplate-2 must keep all answer images equally sized and aligned so image dimensions do not reveal the answer.
   - ConvoTemplate-1 must keep dialogue lines readable, keep its audio control accessible, and use the freed CTA space for answer controls.
   - GrammarForm is structurally identical to ClozeSequence's single-blank mode (sentence-with-blank as the prompt, four word-choice buttons) and follows that ruleset exactly (D for the buttons, this section's sentence-as-prompt treatment) rather than a separate GrammarForm-specific ruleset.
   - Image loading and image-error placeholders reserve a stable media box to prevent layout jumps.
   - Image decoding/rendering must use an appropriate target size where supported so oversized source assets do not cause avoidable memory pressure or frame drops.
   - Informative images expose accessible semantics that describe answer-relevant context without revealing the correct answer. Decorative images are excluded from accessibility traversal.

H) Prompt, dialogue, and guide text
   - Prompt text has a minimum readable size and a bounded maximum size.
   - Equivalent prompts use consistent typography and alignment.
   - Prompt spacing and panel padding have minimum and maximum values.
   - A guide instruction must not be repeated as an identical page CTA.
   - If a guide provides the CTA, the page uses that space for answer controls or other useful components.
   - Dialogue lines may wrap naturally and must not be clipped.
   - Removing a prompt to solve overflow is allowed only when the guide already communicates the same instruction.
   - Guide overlays must not alter the underlying question layout after dismissal.
   - Active question pages contain no inline translation-reveal control or translation text. Translations are shown only on the separate end-of-level translations page, which may scroll normally.
   - Audio-play controls have their own bounded min/max size, independent of the prompt text's own sizing, and their presence or absence must not shift the prompt's own layout position.
   - Audio controls are lower shrink-priority than the prompt or answer text: their padding and spacing may compress before prompt or answer text size is touched, but their tap target has the same minimum floor as any other interactive control.
   - A dialogue layout that places an audio control beside text reserves a fixed audio-control column whether audio is available, loading, disabled, or absent, so dialogue width and line wrapping do not change asynchronously.
   - Guide overlays move accessibility focus into the guide, announce the instruction, prevent interaction with obscured controls, and return focus to the question after dismissal.
   - Guide character artwork is decorative unless it communicates essential information; decorative portraits are excluded from screen-reader traversal.
   - Guide bubbles may grow upward within the full-screen overlay and safe area, but guide content never scrolls. Guide messages are intentionally short and their text scaling is capped at 1.35x so the complete message and OK action remain visible.
   - The guide-specific text cap is an explicit exception to the unrestricted question-content text-scaling rule in C; it applies only to short tutorial guidance, never to questions, answers, dialogue, tiles, or end-of-level translation text.

I) Next/action control
   - The Next/action control remains outside the answer scroll region.
   - It remains reachable above the bottom safe-area inset.
   - It has minimum, preferred, and maximum heights.
   - It may shrink within safe bounds to preserve answer controls.
   - The regular action region uses the phone or tablet percentage profile defined in A. Its button occupies 84% of that region and the remaining height is divided equally above and below it. The 48-logical-pixel touch-target floor overrides the percentage only when required for accessibility.
   - Action-region profile selection depends only on viewport/accessibility conditions, never on the current question type, so Next/Finish does not jump in size while moving between equivalent questions.
   - It must not be pushed below the viewport by answer content.
   - Its width, color, typography, pressed state, and alignment are consistent across templates.
   - On active quiz-question pages action labels are always English uppercase text and are not localized: "NEXT" for an intermediate question and "FINISH" for the final question. Long localized action-label handling is therefore out of scope.
   - Reserve the Next/action region before the button becomes visible so answering a question does not shift media, prompts, or answer controls.
   - The Next/action control has a touch target of at least 48 logical pixels and a semantic label that reflects Next versus Finish.
   - The fixed action region always uses the current bottom safe-area inset and does not assume a fixed navigation-bar or gesture-area height.

J) Safe areas and device environments
   - Account for top and bottom safe-area insets.
   - This app is portrait-only (see CLAUDE.md) — landscape is explicitly out of scope, not a supported orientation to validate against.
   - Test short phones, tall phones, wide phones, and tablets, all in portrait.
   - Foldables unfolded to a nearly-square or wider-than-tall main screen, and Android split-screen/multi-window, are both real "portrait" viewport shapes that don't match any of the 10 `QuestionLayoutTier` assumptions in A (shorter and/or wider than reasoned about there) — treat them as environments to size against, not edge cases to ignore. Split-screen/multi-window is a known, currently-open exposure specifically for header height (A) until multi-window is disabled at the OS-config level; media height/width are already locally-constraint-safe.
   - Account for keyboard and system inset changes where platform UI can affect the viewport.
   - Do not rely on hardcoded device dimensions or a single aspect ratio.
   - Cap content width on tablets and center the content column.
   - Define explicit tablet caps for media width, answer-panel width, prompt width, and guide portrait/bubble size; do not scale any of them directly with the full tablet height or width without a cap.
   - This app ships one fixed light theme; the device's system dark-mode preference does not change quiz-screen colors, palette, or contrast. This is a deliberate scope decision, not an unhandled case.

K) Localization and typography
   - Never assume English answer length.
   - Support longer translations, diacritics, non-Latin scripts, and different word widths.
   - Equivalent controls use the same font family, weight, size, and line height.
   - Do not resize one answer independently from the others.
   - Avoid truncating meaningful answer text.
   - Ensure punctuation and line wrapping remain readable in every supported language.
   - Right-to-left languages (Arabic is already a supported locale) mirror layout direction: text alignment, icon side (e.g. the wrong-answer marker), tile/button reading order, and audio-control placement all flip together rather than only the text direction changing while icons/order stay LTR.
   - Interface chrome follows the selected UI language direction, while exercise content follows the direction of the language being taught or displayed. For example, an English sentence and its word tiles remain LTR and in English reading order inside an Arabic RTL interface.
   - Text uses natural language wrapping first. If a long word has no valid natural break and would otherwise overflow, it may break at a character boundary as the final fallback; it is not clipped, ellipsized, or assigned a smaller per-answer font size.
   - Screen-reader traversal and keyboard focus order follow the visual/logical reading order for both LTR and RTL layouts.
   - The bundled Inter font is the typeface for supported Latin-script text; every non-Latin supported script has its own explicit fallback family defined rather than relying on whatever the OS happens to substitute — Arabic in particular needs a bundled family (e.g. Noto Sans Arabic), not Inter's own (nonexistent) Arabic glyph coverage.
   - Layout bounds (line-height, 2-line max, min/max text size) must tolerate the realistic metric differences between the bundled font and its fallback(s) — they are tuned to a font family in general, not to Inter's exact line-height number, so a fallback rendering the same string doesn't clip or need a third line.
   - Mixed-script strings (e.g. an English prompt with an embedded non-Latin word or numeral) render every script at a consistent visual size and baseline, without one script's fallback looking mismatched in weight or scale next to the rest of the string.
   - Active quiz pages localize only guide messages and WordPairs translation tiles. Question prompts, answer choices, English action labels (including "NEXT" and "FINISH"), and other quiz chrome remain English. Full translation text is localized on the separate end-of-level translations page.

L) Interaction states
   - Layout sizing remains stable or predictably bounded for neutral, selected, correct, wrong, revealed, disabled, audio-playing, translation-revealed, and guide-visible states.
   - Icons, error markers, check marks, order labels, and status text must not unexpectedly change control dimensions.
   - A wrong-answer X icon is shown only when its reserved width does not cause the answer to wrap onto an additional line. If adding the X would change the line count, omit the icon and preserve the answer geometry; retain the wrong border/state treatment and accessible incorrect-answer announcement.
   - Wrong and correct states must use the shared palette consistently across image, video, button, and tile templates.
   - Correct, wrong, selected, and revealed states never rely on color alone; pair color with an icon, text label, shape/border treatment, or another perceivable cue.
   - Text, icons, borders, disabled states, focus indicators, feedback states, and guide overlays meet platform-appropriate accessibility contrast requirements.
   - Accessibility focus indicators remain visible and do not change component dimensions.
   - Loading, audio-playing, translation-reveal, correct/wrong feedback, disabled, and Next-visible transitions preserve layout geometry unless an intentional animated transition is specified.

M) Motion, input, scrolling, and failure behavior
   - Respect reduced-motion platform preferences. Disable or simplify nonessential guide, tile, answer, character, and transition animations when reduced motion is requested.
   - Essential state changes remain understandable without animation.
   - Do not require hover, drag precision, or gesture-only interaction for essential quiz actions.
   - A scrollable answer region provides a visible or discoverable scroll affordance and preserves the user's position during state updates.
   - Avoid nested vertical scrolling inside a question screen.
   - Focused controls, newly revealed feedback, and required next actions are brought into view within the answer scroller without moving pinned media unexpectedly.
   - Every new question resets its answer-region scroll position to the top; scroll position is never carried from the previous question.
   - After an answer is selected, the selected control remains visible while correct/wrong feedback is shown. A mobile viewport/inset change scrolls only enough to return the selected or focused control to view.
   - After a wrong answer in a scrollable answer region, choose the nearest scroll position that shows both the selected wrong control and the revealed correct control when they can fit together. If they cannot both fit, smoothly scroll the answer region to prioritize the correct control because it is the required learning feedback; pinned media, prompt, header, and action regions do not move.
   - Wrong-answer feedback announces both outcomes through accessibility semantics (for example, "Incorrect. Correct answer: ...") even when one of the two controls is outside the visible answer viewport.
   - Page CTA text is omitted from every active question template. Guided questions receive their instruction from the guide; non-guided questions intentionally show no visible instructional CTA.
   - Missing audio hides or disables only the audio control while preserving prompt and answer geometry.
   - Failed media initialization shows a stable fallback in the reserved media region and exposes a usable path to answer or continue.
   - Delayed loading displays stable-size placeholders; asynchronous completion must not cause unexpected layout jumps.

N) Validation contract
   - Use these named portrait logical-viewport fixtures: small phone 360x640, iPhone 12 390x844, Pixel 9/10 class 412x923, tall/wide phone 430x932, tablet 800x1280, and wide tablet 1024x1366. Safe-area insets are applied in addition to these viewport dimensions where the platform profile supplies them.
   - Validate iPhone 12 portrait at 100% text scale.
   - Validate the small-phone, Pixel 9/10-class, tall/wide-phone, tablet, and wide-tablet fixtures.
   - Validate 130%, 160%, and 200% accessibility text scaling.
   - Validate long localized answers, two-line answers, and unusually long content.
   - Validate image aspect-ratio variations and video aspect-ratio variations.
   - Validate neutral, selected, correct, wrong, revealed, disabled, and audio-playing states.
   - Validate guide visible, guide dismissed, and guide-before-playback states.
   - Validate an RTL locale (Arabic) for layout mirroring, and a 2x2 grid template (ConvoTemplate-1) for the halved-width button rule.
   - Confirm that at 100% scale normal content does not scroll.
   - Confirm that only the answer region scrolls when the answer-only overflow profile is sufficient.
   - Confirm the last-resort accessibility profile activates only when the answer-only viewport cannot display one usable answer control, keeps header and Next fixed, and exposes media, prompt, answers, selection, and feedback through one non-nested question-content scroller.
   - Confirm that the media, prompt, header, and Next button remain visible and usable.
   - Validate minimum 48-logical-pixel touch targets for buttons, tiles, audio controls, guide actions, and Next/Finish.
   - Validate contrast and non-color cues for neutral, selected, correct, wrong, revealed, disabled, and focused states.
   - Validate screen-reader labels, traversal order, focus restoration after guides, and RTL traversal.
   - Validate reduced-motion behavior.
   - Validate media loading, missing-audio, missing-image, video-error, and delayed-loading states for layout stability.
   - Validate a foldable unfolded to its wide/near-square main screen and Android split-screen/multi-window at a short height.
   - Validate rendering with each supported script's fallback font (not just Inter/Latin) — Arabic in particular — and a mixed-script string, checking line-height/2-line-max/button-height still hold.
