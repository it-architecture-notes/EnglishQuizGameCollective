import 'dart:ui';

enum ResolutionBucket {
  phoneTall,
  phoneWide,
  tablet43,
  tablet1610,
}

extension ResolutionBucketExtension on ResolutionBucket {
  String get assetPath {
    switch (this) {
      case ResolutionBucket.phoneTall:
        return 'phone_tall';
      case ResolutionBucket.phoneWide:
        return 'phone_wide';
      case ResolutionBucket.tablet43:
        return 'tablet_43';
      case ResolutionBucket.tablet1610:
        return 'tablet_1610';
    }
  }

  bool get isTablet =>
      this == ResolutionBucket.tablet43 || this == ResolutionBucket.tablet1610;
}

ResolutionBucket resolutionBucketFromSize(Size size) {
  final w = size.width;
  final h = size.height;
  final aspect = w > h ? w / h : h / w;
  if (aspect > 2.0) return ResolutionBucket.phoneTall;
  if (aspect > 1.6) return ResolutionBucket.phoneWide;
  if (aspect > 1.33) return ResolutionBucket.tablet1610;
  return ResolutionBucket.tablet43;
}
