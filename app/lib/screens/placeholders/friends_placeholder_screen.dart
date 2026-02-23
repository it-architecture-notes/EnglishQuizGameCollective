import 'package:flutter/material.dart';

class FriendsPlaceholderScreen extends StatelessWidget {
  const FriendsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('Animal friend grid – coming soon'),
      ),
    );
  }
}
