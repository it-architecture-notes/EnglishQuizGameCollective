/// Kids vs. adults app flavor, set at build/run time via `--dart-define=FLAVOR=kids`.
enum AppFlavor { adults, kids }

class AppConfig {
  static late final AppFlavor flavor;

  /// Reads the `FLAVOR` dart-define once at startup. Call before [runApp].
  static void init() {
    const raw = String.fromEnvironment('FLAVOR', defaultValue: 'adults');
    flavor = raw == 'kids' ? AppFlavor.kids : AppFlavor.adults;
  }

  static bool get isKids => flavor == AppFlavor.kids;
  static bool get storiesEnabled => isKids;

  /// `'kids'` or `'adults'` — used to build subfolder paths (music/FX, avatars, achievements).
  static String get flavorDir => isKids ? 'kids' : 'adults';
}
