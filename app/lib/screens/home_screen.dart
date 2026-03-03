import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/resolution_service.dart';
import '../services/test_data_service.dart';
import 'achievements_panel_content.dart';
import 'levels_screen.dart';
import 'panel_overlay.dart';
import 'profile_panel_screen.dart';
import 'transitions/custom_page_routes.dart';

/// Home screen design colors (light lavender background, purple accent).
class _HomeColors {
  static const Color background =
      Color(0xFFF8F8FF); // Ghost white / light lavender
  static const Color primary = Color(0xFF6B3AFF); // Vibrant purple
  static const Color onPrimary = Color(0xFFFFFFFF); // White text & icons
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bucket = resolutionBucketFromSize(size);
    final isTablet = bucket.isTablet;

    return Scaffold(
      backgroundColor: _HomeColors.background,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: _HomeColors.background),
            Center(
              child: isTablet
                  ? _buildTabletQuizButtons()
                  : _buildPhoneQuizButtons(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneQuizButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quizButton(
              'Image Quiz', _openLevelSelection('Image Quiz', popFadeRoute)),
          const SizedBox(height: 16),
          _quizButton(
              'Vocabulary', _openLevelSelection('Vocabulary', popFadeRoute)),
          const SizedBox(height: 16),
          _quizButton('Grammar', _openLevelSelection('Grammar', popFadeRoute)),
        ],
      ),
    );
  }

  Widget _buildTabletQuizButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.8,
        children: [
          _quizButton(
              'Image Quiz', _openLevelSelection('Image Quiz', popFadeRoute)),
          _quizButton(
              'Vocabulary', _openLevelSelection('Vocabulary', popFadeRoute)),
          _quizButton('Grammar', _openLevelSelection('Grammar', popFadeRoute)),
        ],
      ),
    );
  }

  Widget _quizButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _HomeColors.primary,
          foregroundColor: _HomeColors.onPrimary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
  }

  static String _quizTypeToSlug(String label) {
    switch (label) {
      case 'Image Quiz':
        return 'image';
      case 'Vocabulary':
        return 'vocabulary';
      case 'Grammar':
        return 'grammar';
      default:
        return label.toLowerCase().replaceAll(' ', '_');
    }
  }

  VoidCallback _openLevelSelection(
    String quizType,
    Route<void> Function(Widget) routeBuilder,
  ) {
    return () {
      final slug = _quizTypeToSlug(quizType);
      Navigator.of(context).push(
        routeBuilder(LevelsScreen(quizType: slug)),
      );
    };
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(
            Icons.person_outline,
            'Me',
            () => showProfilePanelOverlay(context),
          ),
          _navItem(Icons.emoji_events, 'Trophies',
              () => _showAchievementsPanel()),
          _navItem(Icons.favorite, 'Friends',
              () => _showPanel('Friends', 'Animal friend grid – coming soon')),
          _navItem(Icons.settings, 'Settings', () => _showSettingsPanel()),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _HomeColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _HomeColors.onPrimary, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPanel(String title, String bodyText) {
    showPanelOverlay(
      context,
      title: title,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          bodyText,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  void _showSettingsPanel() {
    showPanelOverlay(
      context,
      title: 'Settings',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App settings – coming soon',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                Text(
                  'Issue-8 test data',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await TestDataService.instance.seedTrophyTestData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Trophy test data seeded. Open Trophies to verify.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Seed trophy test data'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await TestDataService.instance.seedStreakTestData3Day();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '3-day streak seed: complete one level today to unlock.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Seed 3-day streak test'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await TestDataService.instance.seedStreakTestData30Day();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '30-day streak seed: complete one level today to unlock.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Seed 30-day streak test'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await TestDataService.instance.clearTestData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test data cleared.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade300,
                      ),
                      child: const Text('Clear test data'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementsPanel() {
    showPanelOverlay(
      context,
      title: 'Achievements',
      body: const AchievementsPanelContent(),
    );
  }
}
