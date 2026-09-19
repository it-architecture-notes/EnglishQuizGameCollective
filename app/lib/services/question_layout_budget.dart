import 'dart:math';

import 'package:flutter/widgets.dart';

/// Two-stage device classification for the fixed header/media/footer quiz layout, kept
/// entirely separate from `resolution_service.dart`'s `ResolutionBucket` (which only picks a
/// background-art asset folder and stays aspect-ratio-only on purpose).
///
/// Stage 1 picks the device *family* from absolute size (`shortestSide >= 600`), stage 2 picks
/// the aspect-ratio *tier* within that already-chosen family. Aspect ratio alone can't do this
/// in one step: a 16:9 phone and a 16:9 tablet share the same H/W ratio by construction, so any
/// single aspect-ratio-only classifier necessarily collides between the two.
enum QuestionLayoutTier {
  phoneUltraTall,
  phoneSuperTall,
  phoneFlagship,
  phoneTransition,
  phoneClassic2to1,
  phone16to9,
  tablet16to9,
  tablet16to10,
  tablet3to2,
  tablet4to3,
}

extension QuestionLayoutTierExtension on QuestionLayoutTier {
  bool get isTablet =>
      this == QuestionLayoutTier.tablet16to9 ||
      this == QuestionLayoutTier.tablet16to10 ||
      this == QuestionLayoutTier.tablet3to2 ||
      this == QuestionLayoutTier.tablet4to3;
}

/// Fixed header/media/footer height fractions (of the safe usable viewport height) for one
/// [QuestionLayoutTier]. The remainder (`1 - header - media - footer`) is not stored here — it
/// belongs entirely to whichever template is rendering, per the 12-template independence
/// directive; this resolver only owns the three shared, device-fixed regions.
class QuestionLayoutBudget {
  const QuestionLayoutBudget._({
    required this.tier,
    required this.usableHeight,
    required this.headerFraction,
    required this.mediaFraction,
    required this.footerFraction,
  });

  final QuestionLayoutTier tier;
  final double usableHeight;
  final double headerFraction;
  final double mediaFraction;
  final double footerFraction;

  bool get isTablet => tier.isTablet;

  double get headerHeight => usableHeight * headerFraction;
  double get footerHeight => usableHeight * footerFraction;

  /// `1 - header - media - footer` — the share of [usableHeight] left for the active
  /// template's own prompt/answer content once the three fixed regions are reserved.
  double get remainderFraction =>
      (1.0 - headerFraction - mediaFraction - footerFraction).clamp(0.0, 1.0);

  /// Media height computed from the *real, locally available* height for the media+remainder
  /// region (a `LayoutBuilder.bodyConstraints.maxHeight` measured inside the template, after
  /// the `Scaffold` header, the footer, and any body padding are already subtracted by Flutter
  /// itself) — not from [usableHeight] (the whole device window). `usableHeight` alone can't be
  /// trusted for this: it's exactly what Flutter's own adaptive-layout guidance warns about
  /// (`MediaQuery` describes the whole app window; a widget's real assigned space, e.g. inside
  /// a header/body/footer composition or a split-screen/multi-window pane, can be smaller). The
  /// media:remainder *ratio* from the tier table is preserved exactly — only the pixel base it's
  /// applied to changes, from a global assumption to a locally-measured fact.
  double mediaHeightForAvailable(double availableHeight) {
    final denominator = mediaFraction + remainderFraction;
    if (denominator <= 0) return 0.0;
    return availableHeight * (mediaFraction / denominator);
  }

  /// Media box width as a fraction of the real available width on tablets — always 60%,
  /// developer-directed replacement for the old flat `tabletMediaMaxWidth` (560px) pixel cap.
  /// Phones use the full available width (no fraction): a phone screen is already narrow
  /// enough that a percentage cap there would never engage anyway.
  static const double _mediaWidthFractionTablet = 0.60;

  /// Answer/content column width as a fraction of the real available width. Phones use nearly
  /// all of it — no meaningful risk of overly long lines on a screen that narrow. Tablets are
  /// capped tighter so dialogue/prompt text and tile/button rows keep a bounded, readable width
  /// on a large tablet instead of stretching indefinitely with the screen.
  static const double _answerWidthFractionPhone = 1.0;
  static const double _answerWidthFractionTablet = 0.80;

  /// Resolves the media box's real width from the real available width, tier-aware — replaces
  /// every `isTablet ? min(available, tabletMediaMaxWidth) : available` call site.
  double mediaWidthForAvailable(double availableWidth) =>
      isTablet ? availableWidth * _mediaWidthFractionTablet : availableWidth;

  /// Resolves the answer/content column's real width from the real available width, tier-aware
  /// — replaces every `min(screenWidth * 0.87, 560.0)` call site.
  double answerWidthForAvailable(double availableWidth) => isTablet
      ? availableWidth * _answerWidthFractionTablet
      : availableWidth * _answerWidthFractionPhone;

  factory QuestionLayoutBudget.of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final usableHeight =
        (size.height - mediaQuery.padding.vertical).clamp(0.0, double.infinity);

    final shortestSide = size.shortestSide;
    final longestSide = size.longestSide;
    final aspect = shortestSide > 0 ? longestSide / shortestSide : 1.0;
    final isTabletFamily = shortestSide >= 600;

    final tier = isTabletFamily
        ? _tabletTierForAspect(aspect)
        : _phoneTierForAspect(aspect);
    final fractions = _fractionsForTier[tier]!;

    return QuestionLayoutBudget._(
      tier: tier,
      usableHeight: usableHeight,
      headerFraction: fractions.header,
      mediaFraction: fractions.media,
      footerFraction: fractions.footer,
    );
  }

  static QuestionLayoutTier _phoneTierForAspect(double aspect) {
    if (aspect >= 2.30) return QuestionLayoutTier.phoneUltraTall;
    if (aspect >= 2.18) return QuestionLayoutTier.phoneSuperTall;
    if (aspect >= 2.10) return QuestionLayoutTier.phoneFlagship;
    if (aspect >= 1.95) return QuestionLayoutTier.phoneTransition;
    if (aspect >= 1.85) return QuestionLayoutTier.phoneClassic2to1;
    return QuestionLayoutTier.phone16to9;
  }

  static QuestionLayoutTier _tabletTierForAspect(double aspect) {
    if (aspect >= 1.65) return QuestionLayoutTier.tablet16to9;
    if (aspect >= 1.55) return QuestionLayoutTier.tablet16to10;
    if (aspect >= 1.40) return QuestionLayoutTier.tablet3to2;
    return QuestionLayoutTier.tablet4to3;
  }

  static const Map<QuestionLayoutTier,
      ({double header, double media, double footer})> _fractionsForTier = {
    QuestionLayoutTier.phoneUltraTall: (
      header: 0.070,
      media: 0.460,
      footer: 0.085
    ),
    QuestionLayoutTier.phoneSuperTall: (
      header: 0.075,
      media: 0.480,
      footer: 0.095
    ),
    QuestionLayoutTier.phoneFlagship: (
      header: 0.080,
      media: 0.500,
      footer: 0.080
    ),
    QuestionLayoutTier.phoneTransition: (
      header: 0.085,
      media: 0.470,
      footer: 0.100
    ),
    QuestionLayoutTier.phoneClassic2to1: (
      header: 0.090,
      media: 0.460,
      footer: 0.100
    ),
    QuestionLayoutTier.phone16to9: (header: 0.090, media: 0.430, footer: 0.100),
    QuestionLayoutTier.tablet16to9: (
      header: 0.075,
      media: 0.440,
      footer: 0.085
    ),
    QuestionLayoutTier.tablet16to10: (
      header: 0.070,
      media: 0.480,
      footer: 0.080
    ),
    QuestionLayoutTier.tablet3to2: (header: 0.065, media: 0.500, footer: 0.075),
    QuestionLayoutTier.tablet4to3: (header: 0.060, media: 0.520, footer: 0.070),
  };
}

/// Shared interaction metrics for tile-based questions. Heights scale with the safe usable
/// viewport; text sizes stay fixed for the device tier so wrapping into more rows never makes
/// the controls smaller.
const Map<QuestionLayoutTier, double> _tileHeightFractions = {
  QuestionLayoutTier.phoneUltraTall: 0.057,
  QuestionLayoutTier.phoneSuperTall: 0.057,
  QuestionLayoutTier.phoneFlagship: 0.057,
  QuestionLayoutTier.phoneTransition: 0.057,
  QuestionLayoutTier.phoneClassic2to1: 0.057,
  QuestionLayoutTier.phone16to9: 0.057,
  QuestionLayoutTier.tablet16to9: 0.0475,
  QuestionLayoutTier.tablet16to10: 0.0494,
  QuestionLayoutTier.tablet3to2: 0.05415,
  QuestionLayoutTier.tablet4to3: 0.05795,
};

const Map<QuestionLayoutTier, double> _slotHeightFractions = {
  QuestionLayoutTier.phoneUltraTall: 0.052,
  QuestionLayoutTier.phoneSuperTall: 0.052,
  QuestionLayoutTier.phoneFlagship: 0.052,
  QuestionLayoutTier.phoneTransition: 0.052,
  QuestionLayoutTier.phoneClassic2to1: 0.052,
  QuestionLayoutTier.phone16to9: 0.052,
  QuestionLayoutTier.tablet16to9: 0.041,
  QuestionLayoutTier.tablet16to10: 0.044,
  QuestionLayoutTier.tablet3to2: 0.052,
  QuestionLayoutTier.tablet4to3: 0.055,
};

/// Floor for [questionTileHeightFor]/[questionSlotHeightFor] — on the smallest phone reference
/// (e.g. iPhone SE-class), the raw fraction dips below this app's established minimum tappable
/// size (`_clozeSequenceButtonMinTouchTarget`/`_convo1ButtonMinTouchTarget`/
/// `_imageQuiz1ButtonMinTouchTarget`, all 44.0) — this clamp keeps tile/slot height from ever
/// going below that same floor, matching every other answer-choice control in the app.
const double _questionCellMinHeight = 44.0;

const Map<QuestionLayoutTier, double> _tileTextSizes = {
  QuestionLayoutTier.phoneUltraTall: 16.0,
  QuestionLayoutTier.phoneSuperTall: 16.0,
  QuestionLayoutTier.phoneFlagship: 16.0,
  QuestionLayoutTier.phoneTransition: 16.0,
  QuestionLayoutTier.phoneClassic2to1: 16.0,
  QuestionLayoutTier.phone16to9: 16.0,
  QuestionLayoutTier.tablet16to9: 20.0,
  QuestionLayoutTier.tablet16to10: 20.0,
  QuestionLayoutTier.tablet3to2: 20.0,
  QuestionLayoutTier.tablet4to3: 20.0,
};

const Map<QuestionLayoutTier, double> _slotTextSizes = {
  QuestionLayoutTier.phoneUltraTall: 15.0,
  QuestionLayoutTier.phoneSuperTall: 15.0,
  QuestionLayoutTier.phoneFlagship: 15.0,
  QuestionLayoutTier.phoneTransition: 15.0,
  QuestionLayoutTier.phoneClassic2to1: 15.0,
  QuestionLayoutTier.phone16to9: 15.0,
  QuestionLayoutTier.tablet16to9: 20.0,
  QuestionLayoutTier.tablet16to10: 20.0,
  QuestionLayoutTier.tablet3to2: 20.0,
  QuestionLayoutTier.tablet4to3: 20.0,
};

const Map<QuestionLayoutTier, double> _sentenceTextSizes = {
  QuestionLayoutTier.phoneUltraTall: 16.0,
  QuestionLayoutTier.phoneSuperTall: 16.0,
  QuestionLayoutTier.phoneFlagship: 16.0,
  QuestionLayoutTier.phoneTransition: 16.0,
  QuestionLayoutTier.phoneClassic2to1: 16.0,
  QuestionLayoutTier.phone16to9: 16.0,
  QuestionLayoutTier.tablet16to9: 20.0,
  QuestionLayoutTier.tablet16to10: 20.0,
  QuestionLayoutTier.tablet3to2: 20.0,
  QuestionLayoutTier.tablet4to3: 20.0,
};

double questionTileHeightFor(QuestionLayoutBudget budget) => max(
      _questionCellMinHeight,
      budget.usableHeight * _tileHeightFractions[budget.tier]!,
    );

double questionSlotHeightFor(QuestionLayoutBudget budget) => max(
      _questionCellMinHeight,
      budget.usableHeight * _slotHeightFractions[budget.tier]!,
    );

double questionTileTextSizeFor(QuestionLayoutTier tier) => _tileTextSizes[tier]!;

double questionSlotTextSizeFor(QuestionLayoutTier tier) => _slotTextSizes[tier]!;

double questionSentenceTextSizeFor(QuestionLayoutTier tier) =>
    _sentenceTextSizes[tier]!;
