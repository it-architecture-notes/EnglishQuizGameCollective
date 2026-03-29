import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/profile_state.dart';
import '../quiz_game_constants.dart';
import '../services/profile_service.dart';

/// Opens the profile as a centered overlay panel (not full screen).
void showProfilePanelOverlay(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, _, __) => const _ProfileOverlayRoute(),
      transitionsBuilder: (context, animation, _, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final scale = Tween<double>(begin: 0.96, end: 1.0).animate(curve);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: AnimatedBuilder(
                  animation: curve,
                  builder: (_, __) => BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: curve.value * 8,
                      sigmaY: curve.value * 8,
                    ),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.15 * curve.value),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: curve,
                child: ScaleTransition(
                  scale: scale,
                  alignment: Alignment.center,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _ProfileOverlayRoute extends StatelessWidget {
  const _ProfileOverlayRoute();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width * 0.88;
    final height = size.height * 0.82;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: GestureDetector(
          onTap: () {},
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 8,
            child: SizedBox(
              width: width,
              height: height,
              child: const ProfilePanelScreen(overlayMode: true),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePanelScreen extends StatefulWidget {
  const ProfilePanelScreen({super.key, this.overlayMode = false});

  final bool overlayMode;

  @override
  State<ProfilePanelScreen> createState() => _ProfilePanelScreenState();
}

class _ProfilePanelScreenState extends State<ProfilePanelScreen> {
  ProfileState? _profile;
  ProfileSummary? _summary;
  List<String> _avatarAssets = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (widget.overlayMode && _profile != null) {
      final trimmed = _nameController.text.trim();
      final toSave = _profile!.copyWith(
        avatarName: trimmed.isNotEmpty ? trimmed : _profile!.avatarName,
      );
      ProfileService.instance.saveProfile(toSave);
    }
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await ProfileService.instance.loadOrCreateProfile();
      final avatars = await ProfileService.instance.listAvatarAssets();
      final summary = await ProfileService.instance.buildSummary(profile);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _avatarAssets = avatars;
        _summary = summary;
        _nameController.text = profile.avatarName;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _closeAndSave() async {
    if (_isSaving || _profile == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _isSaving = true);
    try {
      final trimmed = _nameController.text.trim();
      final toSave = _profile!.copyWith(
        avatarName: trimmed.isNotEmpty ? trimmed : _profile!.avatarName,
      );
      await ProfileService.instance.saveProfile(toSave);
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _openAvatarPicker() async {
    if (_avatarAssets.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No avatars yet'),
          content: const Text(
              'No avatar images were found in assets/images/avatars/.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final options = _avatarAssets.take(16).toList();
        return AlertDialog(
          title: const Text('Choose Avatar'),
          content: SizedBox(
            width: 320,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (_, i) {
                final assetPath = options[i];
                return InkWell(
                  onTap: () => Navigator.of(ctx).pop(assetPath),
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(ctx).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    final updated = _profile?.copyWith(avatarAssetPath: selected);
    if (updated != null) {
      setState(() {
        _profile = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _closeAndSave();
      },
      child: widget.overlayMode ? _buildOverlayContent() : _buildFullScreen(),
    );
  }

  Widget _buildOverlayContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: _closeAndSave,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildFullScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _closeAndSave,
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile;
    final summary = _summary;
    if (profile == null || summary == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        _buildIdentitySection(profile),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        _buildLifetimeRow(summary),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        ...summary.perQuizStats.map(_buildQuizTypeRow),
      ],
    );
  }

  Widget _buildIdentitySection(ProfileState profile) {
    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              _buildAvatarPreview(profile),
              GestureDetector(
                onTap: _openAvatarPicker,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          onChanged: (_) => _syncNameFromController(),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Joined ${_formatDate(profile.dateJoinedIso)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  void _syncNameFromController() {
    if (_profile != null) {
      setState(() {
        _profile = _profile!.copyWith(avatarName: _nameController.text);
      });
    }
  }

  Widget _buildAvatarPreview(ProfileState profile) {
    final hasAvatar = profile.avatarAssetPath != null;
    final initial = profile.avatarName.isNotEmpty
        ? profile.avatarName[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 40,
      backgroundImage:
          hasAvatar ? AssetImage(profile.avatarAssetPath!) : null,
      onBackgroundImageError: hasAvatar ? (_, __) {} : null,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: hasAvatar
          ? null
          : Text(
              initial,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
    );
  }

  Widget _buildLifetimeRow(ProfileSummary summary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatChip(
          icon: Icons.star_rounded,
          color: Colors.amber,
          label: summary.lifetimeStars.toString(),
          sublabel: 'Total Stars',
        ),
        _buildStatChip(
          icon: Icons.diamond,
          color: Colors.blue.shade600,
          label: summary.lifetimeDiamonds.toString(),
          sublabel: 'Total Diamonds',
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color color,
    required String label,
    required String sublabel,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        Text(
          sublabel,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildQuizTypeRow(QuizTypeProfileStats stats) {
    final sectionColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stats.quizType == kQuizGameType
                      ? 'Game'
                      : _titleCase(stats.quizType),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: sectionColor,
                      ),
                ),
              ),
              Text(
                'Level ${stats.currentLevel}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: sectionColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.progressRatio,
                    minHeight: 8,
                    backgroundColor:
                        Theme.of(context).colorScheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(sectionColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${stats.completedLevels} / ${stats.totalLevels}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMiniStat(
                Icons.help_outline,
                stats.totalQuestionsAnswered.toString(),
                'Questions',
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                Icons.local_fire_department,
                stats.currentStreak.toString(),
                'Day streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade700),
        ),
      ],
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }
}
