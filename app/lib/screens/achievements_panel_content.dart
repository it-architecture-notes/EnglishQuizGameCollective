import 'package:flutter/material.dart';

import '../services/achievement_config_loader.dart';
import '../services/achievement_progress_service.dart';
import '../services/profile_service.dart';

/// Scrollable achievements list for the Trophies panel overlay.
class AchievementsPanelContent extends StatefulWidget {
  const AchievementsPanelContent({super.key});

  @override
  State<AchievementsPanelContent> createState() =>
      _AchievementsPanelContentState();
}

class _AchievementsPanelContentState extends State<AchievementsPanelContent> {
  List<AchievementProgress>? _progress;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ProfileService.instance.loadOrCreateProfile();
      final definitions = await loadAchievementConfig();
      final progress = await AchievementProgressService.instance.computeProgress(
        definitions: definitions,
        profile: profile,
      );
      if (mounted) {
        setState(() {
          _progress = progress;
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('AchievementsPanelContent _load: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    final progress = _progress ?? [];
    if (progress.isEmpty) {
      return const Center(child: Text('No achievements configured.'));
    }

    final grouped = <String?, List<AchievementProgress>>{};
    for (final p in progress) {
      grouped.putIfAbsent(p.definition.phase, () => []).add(p);
    }
    const phases = [
      'EARLY GAME',
      'MID GAME',
      'LATE GAME',
      'ULTIMATE CHALLENGES',
    ];
    final ordered = <List<AchievementProgress>>[];
    for (final phase in phases) {
      final list = grouped[phase];
      if (list != null && list.isNotEmpty) ordered.add(list);
    }
    final noPhase = grouped[null];
    if (noPhase != null && noPhase.isNotEmpty) ordered.add(noPhase);

    final children = <Widget>[];
    for (final list in ordered) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            list.first.definition.phase ?? 'Achievements',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      );
      for (final p in list) {
        children.add(_AchievementTile(progress: p));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.progress});

  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final def = progress.definition;
    final unlocked = progress.isUnlocked;

    Widget iconWidget;
    if (def.icon.isNotEmpty) {
      iconWidget = Image.asset(
        def.icon,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallbackIcon(context, unlocked),
      );
    } else {
      iconWidget = _fallbackIcon(context, unlocked);
    }

    if (!unlocked) {
      iconWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: iconWidget,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 48, height: 48, child: iconWidget),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  def.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
                if (def.showProgressBar && progress.goalValue > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.progressFraction.clamp(0.0, 1.0),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _progressLabel(def, progress),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context, bool unlocked) {
    return Icon(
      Icons.emoji_events,
      size: 48,
      color: unlocked
          ? Colors.amber.shade700
          : Colors.grey.shade400,
    );
  }

  String _progressLabel(AchievementDefinition def, AchievementProgress p) {
    if (def.trackingKey == 'best_quiz_time_seconds') {
      return p.currentValue > 0 && p.currentValue < 999
          ? 'Best: ${p.currentValue}s'
          : 'Not yet completed';
    }
    return '${p.currentValue} / ${p.goalValue}';
  }
}
