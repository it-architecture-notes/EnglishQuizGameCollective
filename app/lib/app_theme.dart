import 'package:flutter/material.dart';

import 'app_flavor.dart';

/// Per-flavor [ThemeData]. Seed colors are placeholders pending final palette choice.
class AppTheme {
  static ThemeData forFlavor(AppFlavor flavor) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor:
            flavor == AppFlavor.kids ? Colors.orange : Colors.blue, // placeholder seeds, TBD
      ),
      useMaterial3: true,
    );
  }
}
