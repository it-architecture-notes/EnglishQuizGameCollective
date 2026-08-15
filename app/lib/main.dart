import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_flavor.dart';
import 'app_theme.dart';
import 'screens/home_screen.dart';

/// App entry: binds Flutter, reads the flavor, locks portrait, and starts Riverpod + [MainApp].
///
/// Also installs explicit error logging so every exception — framework-caught (build/layout/paint)
/// or otherwise-uncaught (async callbacks, plugin channel errors, etc.) — is printed to the
/// terminal running `flutter run`, not just whichever subset Flutter's defaults happen to surface.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[UncaughtError] $error\n$stack');
    return true;
  };

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  /// Root [MaterialApp] theme and initial route ([HomeScreen]).
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Quiz Game',
      theme: AppTheme.forFlavor(AppConfig.flavor),
      home: const HomeScreen(),
    );
  }
}
