import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/quiz_flow.dart';
import '../services/quiz_flow_loader.dart';
import 'image_quiz_screen.dart';
import 'placeholders/quiz_placeholder_screen.dart';
import 'transitions/custom_page_routes.dart';

/// Builds the flattened list of items (banner + sub-level cells) from loaded flow data.
/// Each banner counts as 1 item; each sub-level counts as 1 item (batch size applies to this list).
List<LevelListItem> buildLevelItems(QuizFlowData data) {
  final metaByMain = {for (final m in data.mainLevels) m.mainLevel: m};
  final shownBanners = <int>{};
  final items = <LevelListItem>[];

  for (final sub in data.subLevels) {
    final meta = metaByMain[sub.mainLevel];
    if (meta == null) continue;

    if (!shownBanners.contains(sub.mainLevel)) {
      shownBanners.add(sub.mainLevel);
      items.add(BannerItem(meta));
    }
    items.add(SubLevelItem(sub));
  }

  return items;
}

/// Converts a slice of LevelListItems into row descriptors for layout.
/// Each sub-level is one row so icons can follow a curvy path (one icon per step).
List<_LayoutRow> _itemsToLayoutRows(List<LevelListItem> items) {
  final rows = <_LayoutRow>[];
  for (final item in items) {
    if (item is BannerItem) {
      rows.add(_BannerLayoutRow(item.meta));
    } else if (item is SubLevelItem) {
      rows.add(_SubsLayoutRow([item.sub]));
    }
  }
  return rows;
}

sealed class _LayoutRow {
  _LayoutRow._();
}

class _BannerLayoutRow extends _LayoutRow {
  _BannerLayoutRow(this.meta) : super._();
  final MainLevelMeta meta;
}

class _SubsLayoutRow extends _LayoutRow {
  _SubsLayoutRow(this.subs) : super._();
  final List<SubLevel> subs;
}

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key, required this.quizType});

  /// Quiz type slug: 'image', 'vocabulary', 'grammar'.
  final String quizType;

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  List<LevelListItem> _items = [];
  int _visibleCount = 10;
  String? _loadError;
  bool _loading = true;
  late ScrollController _scrollController;

  static const double _loadMoreThreshold = 300;
  static const int _batchSize = 10;
  /// Curvy path: (sin+1)/2 drives position from left (0) to right (1).
  static const double _sinFrequency = 0.5;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await loadQuizFlow(widget.quizType);
      final items = buildLevelItems(data);
      if (mounted) {
        setState(() {
          _items = items;
          _visibleCount = _items.length < _batchSize ? _items.length : _batchSize;
          _loading = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loading = false;
        });
      }
      debugPrint('LevelsScreen load error: $e\n$st');
    }
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      final newCount = (_visibleCount + _batchSize).clamp(0, _items.length);
      if (newCount != _visibleCount && mounted) {
        setState(() => _visibleCount = newCount);
      }
    }
  }

  List<_LayoutRow> get _visibleLayoutRows {
    final slice = _items.take(_visibleCount).toList();
    return _itemsToLayoutRows(slice);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_titleFromSlug(widget.quizType))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_titleFromSlug(widget.quizType)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      );
    }

    final visibleRows = _visibleLayoutRows;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFromSlug(widget.quizType)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: visibleRows.length,
          itemBuilder: (context, index) {
            final row = visibleRows[index];
            final globalSubRowIndex = visibleRows
                .take(index)
                .whereType<_SubsLayoutRow>()
                .length;
            return _buildRow(context, row, globalSubRowIndex);
          },
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, _LayoutRow row, int globalSubRowIndex) {
    return switch (row) {
      _BannerLayoutRow(meta: final meta) => _buildBanner(context, meta),
      _SubsLayoutRow(subs: final subs) => _buildSubLevelRow(
            context,
            globalSubRowIndex,
            subs,
          ),
    };
  }

  Widget _buildBanner(BuildContext context, MainLevelMeta meta) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        meta.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSubLevelRow(
    BuildContext context,
    int globalSubRowIndex,
    List<SubLevel> subs,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    const horizontalPadding = 16.0 * 2; // ListView horizontal padding
    final iconSize = width / 5;
    final contentWidth = width - horizontalPadding;
    const cellHorizontalPadding = 8.0; // 4 + 4 from cell
    final cellWidth = iconSize + 8 + cellHorizontalPadding;
    final pathRange = (contentWidth - cellWidth).clamp(0.0, double.infinity);
    const phase = -math.pi / 2;
    final t = (math.sin(globalSubRowIndex * _sinFrequency + phase) + 1) / 2;
    final leftOffset = t * pathRange;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: leftOffset),
          SizedBox(width: cellWidth, child: _buildSubLevelCell(context, subs.single, iconSize)),
        ],
      ),
    );
  }

  Widget _buildSubLevelCell(BuildContext context, SubLevel sub, double iconSize) {
    final iconPath = 'assets/flow-icons/${sub.iconImageName}.png';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openQuiz(context, sub),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    iconPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: iconSize * 0.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: iconSize + 8,
                child: Text(
                  sub.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuiz(BuildContext context, SubLevel sub) {
    if (widget.quizType == 'image') {
      Navigator.of(context).push(
        popFadeRoute(ImageQuizScreen(
          quizType: widget.quizType,
          subLevel: sub,
        )),
      );
    } else {
      Navigator.of(context).push(
        popFadeRoute(QuizPlaceholderScreen(
          quizType: widget.quizType,
          subLevel: sub,
        )),
      );
    }
  }

  static String _titleFromSlug(String slug) {
    switch (slug) {
      case 'image':
        return 'Image Quiz';
      case 'vocabulary':
        return 'Vocabulary';
      case 'grammar':
        return 'Grammar';
      default:
        return slug;
    }
  }
}
