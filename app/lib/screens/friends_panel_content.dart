import 'package:flutter/material.dart';

import '../models/friends_state.dart';
import '../services/friends_config_loader.dart';
import '../services/friends_service.dart';
import '../services/profile_service.dart';

class FriendsPanelContent extends StatefulWidget {
  const FriendsPanelContent({super.key});

  @override
  State<FriendsPanelContent> createState() => _FriendsPanelContentState();
}

class _FriendsPanelContentState extends State<FriendsPanelContent> {
  List<FriendAnimalDefinition>? _definitions;
  FriendsState? _friendsState;
  int _availableDiamonds = 0;
  String? _error;
  bool _loading = true;
  String? _justFreedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ProfileService.instance.loadOrCreateProfile();
      final summary = await ProfileService.instance.buildSummary(profile);
      final definitions = await loadFriendsConfig();
      final state = await FriendsService.instance.loadState();

      final idToCost = {
        for (final d in definitions) d.id: d.diamondCost,
      };
      final spent = state.freedAnimalIds.fold<int>(
        0,
        (sum, id) => sum + (idToCost[id] ?? 0),
      );
      final available = summary.lifetimeDiamonds - spent;

      if (mounted) {
        setState(() {
          _definitions = definitions;
          _friendsState = state;
          _availableDiamonds = available;
          _loading = false;
        });
        if (mounted && !state.hintDismissed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showHintDialog();
          });
        }
      }
    } catch (e, st) {
      debugPrint('FriendsPanelContent _load: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _showHintDialog() async {
    final state = _friendsState;
    if (state == null || state.hintDismissed) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          'Diamonds are needed to free the animals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final updated = state.copyWith(hintDismissed: true);
    await FriendsService.instance.saveState(updated);
    if (mounted) setState(() => _friendsState = updated);
  }

  void _onTapAnimal(FriendAnimalDefinition def) {
    final state = _friendsState;
    if (state == null) return;
    if (state.freedAnimalIds.contains(def.id)) return;

    if (_availableDiamonds < def.diamondCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough diamonds.')),
      );
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Free animal'),
        content: Text(
          '${def.displayName} will be freed for ${def.diamondCost} diamonds?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      final updated = state.copyWith(
        freedAnimalIds: {...state.freedAnimalIds, def.id},
      );
      FriendsService.instance.saveState(updated);
      setState(() {
        _friendsState = updated;
        _availableDiamonds = _availableDiamonds - def.diamondCost;
        _justFreedId = def.id;
      });
    });
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
    final definitions = _definitions ?? [];
    final state = _friendsState ?? const FriendsState();
    if (definitions.isEmpty) {
      return const Center(child: Text('No animals configured.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Your diamonds: $_availableDiamonds',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: definitions.length,
          itemBuilder: (context, index) {
              final def = definitions[index];
              final isFreed = state.freedAnimalIds.contains(def.id);
              final justFreed = _justFreedId == def.id;
              return _FriendTile(
                definition: def,
                isFreed: isFreed,
                justFreed: justFreed,
                onTap: () => _onTapAnimal(def),
                onAnimationDone: () {
                  if (mounted) setState(() => _justFreedId = null);
                },
              );
            },
        ),
      ],
    );
  }
}

class _FriendTile extends StatefulWidget {
  const _FriendTile({
    required this.definition,
    required this.isFreed,
    required this.justFreed,
    required this.onTap,
    required this.onAnimationDone,
  });

  final FriendAnimalDefinition definition;
  final bool isFreed;
  final bool justFreed;
  final VoidCallback onTap;
  final VoidCallback onAnimationDone;

  @override
  State<_FriendTile> createState() => _FriendTileState();
}

class _FriendTileState extends State<_FriendTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.2)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ));
    _offset = Tween<double>(begin: 0, end: -12)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ));
  }

  @override
  void didUpdateWidget(_FriendTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.justFreed && !oldWidget.justFreed) {
      _controller.forward().then((_) {
        _controller.reverse().then((_) {
          widget.onAnimationDone();
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static Color _placeholderColor(String id) {
    final hash = id.hashCode.abs() % 0xFFFFFF;
    final r = ((hash >> 16) & 0xFF).clamp(140, 220);
    final g = ((hash >> 8) & 0xFF).clamp(140, 220);
    final b = (hash & 0xFF).clamp(140, 220);
    return Color.fromARGB(255, r, g, b);
  }

  Widget _buildPlaceholderBox(Color placeColor, bool isFreed) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isFreed ? placeColor : placeColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.pets,
        size: 48,
        color: isFreed ? Colors.white : Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    final isFreed = widget.isFreed;
    final placeColor = _placeholderColor(def.id);

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Image.asset(
            def.imageAssetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildPlaceholderBox(placeColor, isFreed),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          def.displayName,
          style: Theme.of(context).textTheme.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (!isFreed)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.diamond, size: 12, color: Colors.blue[700]),
                const SizedBox(width: 2),
                Text(
                  '${def.diamondCost}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
      ],
    );

    if (!isFreed) {
      content = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.grey,
          BlendMode.saturation,
        ),
        child: content,
      );
    }

    if (widget.justFreed || _controller.isAnimating) {
      content = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _offset.value),
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          );
        },
        child: content,
      );
    }

    return GestureDetector(
      onTap: isFreed ? null : widget.onTap,
      child: content,
    );
  }
}
