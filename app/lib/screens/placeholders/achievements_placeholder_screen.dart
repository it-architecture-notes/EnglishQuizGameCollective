import 'package:flutter/material.dart';

class AchievementsPlaceholderScreen extends StatelessWidget {
  const AchievementsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('Achievements – coming soon'),
      ),
    );
  }
}
