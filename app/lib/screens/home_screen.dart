import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart' as audio;
import '../services/resolution_service.dart';
import 'achievements_panel_content.dart';
import 'friends_panel_content.dart';
import 'levels_screen.dart';
import 'panel_overlay.dart';
import 'profile_panel_screen.dart';
import 'settings_panel_content.dart';
import 'transitions/custom_page_routes.dart';

/// Home screen design colors (light lavender background, purple accent).
class _HomeColors {
  static const Color background =
      Color(0xFFF8F8FF); // Ghost white / light lavender
  static const Color primary = Color(0xFF6B3AFF); // Vibrant purple
  static const Color onPrimary = Color(0xFFFFFFFF); // White text & icons
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bucket = resolutionBucketFromSize(size);
    final isTablet = bucket.isTablet;
    final strings = ref.watch(currentLocalizedStringsProvider).valueOrNull ?? {};
    final settings = ref.watch(settingsProvider).valueOrNull;
    final soundFxOn = settings?.soundFxOn ?? true;

    return Scaffold(
      backgroundColor: _HomeColors.background,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: _HomeColors.background),
            Center(
              child: isTablet
                  ? _buildTabletQuizButtons(soundFxOn, strings)
                  : _buildPhoneQuizButtons(soundFxOn, strings),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNav(strings, soundFxOn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneQuizButtons(bool soundFxOn, Map<String, String> strings) {
    void withClick(VoidCallback action) {
      audio.playClick(soundFxOn: soundFxOn);
      action();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quizButton(
            strings['start_game'] ?? 'Start Game',
            () => withClick(() {
              Navigator.of(context).push(
                popFadeRoute(const LevelsScreen()),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletQuizButtons(bool soundFxOn, Map<String, String> strings) {
    void withClick(VoidCallback action) {
      audio.playClick(soundFxOn: soundFxOn);
      action();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: _quizButton(
        strings['start_game'] ?? 'Start Game',
        () => withClick(() {
          Navigator.of(context).push(
            popFadeRoute(const LevelsScreen()),
          );
        }),
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

  Widget _buildBottomNav(Map<String, String> strings, bool soundFxOn) {
    void withClick(VoidCallback action) {
      audio.playClick(soundFxOn: soundFxOn);
      action();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(
            Icons.person_outline,
            strings['nav_me'] ?? 'Me',
            () => withClick(() => showProfilePanelOverlay(context)),
          ),
          _navItem(Icons.emoji_events, strings['nav_trophies'] ?? 'Trophies',
              () => withClick(() => _showAchievementsPanel(strings))),
          _navItem(Icons.favorite, strings['nav_friends'] ?? 'Friends',
              () => withClick(() => _showFriendsPanel(strings))),
          _navItem(Icons.settings, strings['nav_settings'] ?? 'Settings',
              () => withClick(() => _showSettingsPanel(strings))),
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

  void _showSettingsPanel(Map<String, String> strings) {
    showPanelOverlay(
      context,
      title: strings['settings_title'] ?? 'Settings',
      body: const SettingsPanelContent(),
    );
  }

  void _showAchievementsPanel(Map<String, String> strings) {
    showPanelOverlay(
      context,
      title: strings['nav_trophies'] ?? 'Trophies',
      body: const AchievementsPanelContent(),
    );
  }

  void _showFriendsPanel(Map<String, String> strings) {
    showPanelOverlay(
      context,
      title: strings['nav_friends'] ?? 'Friends',
      body: const FriendsPanelContent(),
    );
  }
}
