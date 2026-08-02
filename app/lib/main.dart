import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_flavor.dart';
import 'app_theme.dart';
import 'screens/home_screen.dart';

/// App entry: binds Flutter, reads the flavor, locks portrait, and starts Riverpod + [MainApp].
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
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
