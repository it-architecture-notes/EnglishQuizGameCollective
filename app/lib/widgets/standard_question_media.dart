import 'dart:math';

import 'package:flutter/material.dart';

import '../services/question_layout_budget.dart';

/// Percentage-based sizing shared by the regular question header, media,
/// prompt/answer reserve, and action region.
///
/// Header and action-region height are sourced from [QuestionLayoutBudget] — the two-stage
/// (size-then-aspect) device classifier shared with the 6 media-bearing templates, so chrome
/// and media are always resolved from the same device tier and never disagree. The other
/// fractions below (`mediaMinFraction` etc.) remain the older, coarser phone/tablet-only
/// fallback used solely by [StandardQuestionMedia]'s own default sizing path, for any caller
/// that doesn't supply `heightOverride`/`widthOverride` — every current media-bearing template
/// supplies both and reads its media height straight from [QuestionLayoutBudget] instead.
class StandardQuestionLayoutProfile {
  const StandardQuestionLayoutProfile._({
    required this.usableHeight,
    required this.isTablet,
    required this.budget,
  });

  factory StandardQuestionLayoutProfile.of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final budget = QuestionLayoutBudget.of(context);
    return StandardQuestionLayoutProfile._(
      usableHeight: max(
        0.0,
        mediaQuery.size.height - mediaQuery.padding.vertical,
      ),
      isTablet: mediaQuery.size.shortestSide >= 600,
      budget: budget,
    );
  }

  static const minimumTouchTarget = 48.0;

  final double usableHeight;
  final bool isTablet;
  final QuestionLayoutBudget budget;

  double get mediaMinFraction => 0.22;
  double get mediaMaxFraction => isTablet ? 0.55 : 0.45;
  double get mediaWidthFraction => isTablet ? 0.80 : 1.0;

  double get contentMinFraction => isTablet ? 0.34 : 0.40;
  double get contentPreferredFraction => isTablet ? 0.36 : 0.42;
  double get contentMaxFraction => isTablet ? 0.42 : 0.48;

  double get headerHeight =>
      max(minimumTouchTarget, budget.headerHeight);

  double get mediaMinHeight => usableHeight * mediaMinFraction;
  double get mediaMaxHeight => usableHeight * mediaMaxFraction;
  double get contentReserveHeight => usableHeight * contentPreferredFraction;
  double get mediaContentGap => usableHeight * 0.005;

  double get actionRegionHeight => max(minimumTouchTarget, budget.footerHeight);

  double get actionButtonHeight {
    final heightAfterPadding = actionRegionHeight * 0.84;
    return max(minimumTouchTarget, heightAfterPadding)
        .clamp(0.0, actionRegionHeight)
        .toDouble();
  }

  double get actionVerticalPadding =>
      max(0, (actionRegionHeight - actionButtonHeight) / 2);
}

/// Shared media frame for regular quiz templates.
///
/// The sizing profile depends only on the viewport and the question body's
/// available height, never on the current answer type. This keeps video and
/// image-backed regular questions visually aligned while leaving their media
/// ownership and playback behavior inside each template.
class StandardQuestionMedia extends StatelessWidget {
  const StandardQuestionMedia({
    super.key,
    required this.availableBodyHeight,
    required this.aspectRatio,
    required this.child,
    this.heightOverride,
    this.widthOverride,
  });

  final double availableBodyHeight;
  final double aspectRatio;
  final Widget child;
  final double? heightOverride;
  final double? widthOverride;

  @override
  Widget build(BuildContext context) {
    final profile = StandardQuestionLayoutProfile.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthLimit = widthOverride ??
            constraints.maxWidth * profile.mediaWidthFraction;
        final budgetHeightLimit = availableBodyHeight.isFinite
            ? max(
                0.0,
                availableBodyHeight -
                    profile.contentReserveHeight -
                    profile.mediaContentGap,
              )
            : double.infinity;
        final effectiveBudgetLimit = max(
          profile.mediaMinHeight,
          budgetHeightLimit,
        );

        final safeAspectRatio = aspectRatio > 0 ? aspectRatio : 1.0;
        var mediaWidth = widthLimit;
        var mediaHeight = mediaWidth / safeAspectRatio;
        final heightLimit = heightOverride ??
            min(
              profile.mediaMaxHeight,
              effectiveBudgetLimit,
            );
        if (mediaHeight > heightLimit) {
          mediaHeight = heightLimit;
          mediaWidth = mediaHeight * safeAspectRatio;
        }

        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: mediaWidth,
              height: mediaHeight,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
