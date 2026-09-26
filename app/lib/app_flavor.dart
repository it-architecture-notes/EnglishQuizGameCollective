/// Kids vs. adults app flavor, set at build/run time via `--dart-define=FLAVOR=kids`.
///
/// `adults` was renamed to `adults-intermediate` (folders, assets, flow config) to make
/// room for `adults-beginner`, a second adult difficulty level. Both adult flavors share
/// music/FX and avatars (see [sharedAssetFlavorDir]) and achievements (achievements.json
/// is not flavor-split for adults — only kids gets its own `achievements-kids.json`), but
/// have independent per-level quiz content and flow config. Default flavor (no `FLAVOR`
/// dart-define passed) is `adults-beginner`.
enum AppFlavor { adultsIntermediate, adultsBeginner, kids }

class AppConfig {
  static late final AppFlavor flavor;

  /// Reads the `FLAVOR` dart-define once at startup. Call before [runApp].
  static void init() {
    const raw = String.fromEnvironment('FLAVOR', defaultValue: 'adults-beginner');
    flavor = switch (raw) {
      'kids' => AppFlavor.kids,
      'adults-beginner' => AppFlavor.adultsBeginner,
      _ => AppFlavor.adultsIntermediate,
    };
  }

  static bool get isKids => flavor == AppFlavor.kids;
  static bool get isAdultsBeginner => flavor == AppFlavor.adultsBeginner;
  static bool get isAdultsIntermediate => flavor == AppFlavor.adultsIntermediate;
  static bool get storiesEnabled => isKids;

  /// `'kids'`, `'adults-intermediate'`, or `'adults-beginner'` — used to build per-level
  /// content subfolder paths (`quiz-data/levels/{level}/{flavorDir}/`). Each adult flavor
  /// has its own independent level content; there is no fallback between them here.
  static String get flavorDir => switch (flavor) {
        AppFlavor.kids => 'kids',
        AppFlavor.adultsBeginner => 'adults-beginner',
        AppFlavor.adultsIntermediate => 'adults-intermediate',
      };

  /// `'kids'` or `'adults-intermediate'` — used for the *shared* flavor subfolders that
  /// `adults-beginner` doesn't (yet) have its own copies of: music/FX (`audio/`) and the
  /// avatar picker (`images/avatars/`). `adults-beginner` intentionally falls back to
  /// `adults-intermediate`'s assets here rather than requiring duplicates from day one.
  static String get sharedAssetFlavorDir => isKids ? 'kids' : 'adults-intermediate';
}
