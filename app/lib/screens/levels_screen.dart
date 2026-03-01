import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../models/level_completion_result.dart';
import '../models/quiz_flow.dart';
import '../services/quiz_flow_loader.dart';
import '../services/quiz_progress_service.dart';
import 'image_quiz_screen.dart';
import 'placeholders/quiz_placeholder_screen.dart';
import 'transitions/custom_page_routes.dart';
import 'vocabulary_quiz_screen.dart';

/// Builds the flattened list of items (banner + sub-level cells) from loaded flow data.
/// Each banner counts as 1 item; each sub-level counts as 1 item (batch size applies to this list).
List<LevelListItem> buildLevelItems(QuizFlowData data) {
  final metaByMain = {for (final m in data.mainLevels) m.mainLevel: m};
  final shownBanners = <int>{};
  final items = <LevelListItem>[];

  for (var i = 0; i < data.subLevels.length; i++) {
    final sub = data.subLevels[i];
    final meta = metaByMain[sub.mainLevel];
    if (meta == null) continue;

    if (!shownBanners.contains(sub.mainLevel)) {
      shownBanners.add(sub.mainLevel);
      items.add(BannerItem(meta));
    }
    items.add(SubLevelItem(sub, ordinalLevelIndex: i + 1));
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
      rows.add(_SubsLayoutRow(item));
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
  _SubsLayoutRow(this.subLevelItem) : super._();
  final SubLevelItem subLevelItem;
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
  int _lastCompletedOrdinalIndex = 0;
  int _firstLockedOrdinalIndex = 2; // 2 = level 1 unlocked only
  int? _justReturnedFromOrdinal;
  String? _loadError;
  bool _loading = true;
  late ItemScrollController _itemScrollController;
  late ItemPositionsListener _itemPositionsListener;

  static const int _batchSize = 10;
  /// Curvy path: (sin+1)/2 drives position from left (0) to right (1).
  static const double _sinFrequency = 0.5;

  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _itemPositionsListener.itemPositions.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await loadQuizFlow(widget.quizType);
      final progress = await QuizProgressService.instance.loadProgress(widget.quizType);
      final allItems = buildLevelItems(data);

      int lastCompleted = 0;
      for (final item in allItems) {
        if (item is SubLevelItem) {
          final lp = progress.level(item.ordinalLevelIndex);
          if (lp.isCompleted && item.ordinalLevelIndex > lastCompleted) {
            lastCompleted = item.ordinalLevelIndex;
          }
        }
      }

      final horizon = lastCompleted + 10;
      final filteredItems = <LevelListItem>[];
      for (var i = 0; i < allItems.length; i++) {
        final item = allItems[i];
        if (item is SubLevelItem) {
          if (item.ordinalLevelIndex <= horizon) filteredItems.add(item);
        } else if (item is BannerItem) {
          var hasVisibleSub = false;
          for (var j = i + 1; j < allItems.length; j++) {
            final next = allItems[j];
            if (next is BannerItem) break;
            if (next is SubLevelItem && next.ordinalLevelIndex <= horizon) {
              hasVisibleSub = true;
              break;
            }
          }
          if (hasVisibleSub) filteredItems.add(item);
        }
      }

      final visibleCount = filteredItems.length < _batchSize
          ? filteredItems.length
          : _batchSize.clamp(0, filteredItems.length);

      if (mounted) {
        setState(() {
          _items = filteredItems;
          _visibleCount = visibleCount;
          _lastCompletedOrdinalIndex = lastCompleted;
          _firstLockedOrdinalIndex = lastCompleted + 2;
          _loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final toScroll = _justReturnedFromOrdinal;
          if (toScroll != null) {
            _scrollToOrdinal(toScroll);
            setState(() => _justReturnedFromOrdinal = null);
          } else {
            _scrollToFurthestUnlocked();
          }
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
    if (_items.length - _visibleCount <= 0) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final maxVisible = positions
        .where((p) => p.itemTrailingEdge > 0)
        .map((p) => p.index)
        .fold<int>(0, (a, b) => a > b ? a : b);
    if (maxVisible >= _visibleCount - 2) {
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

  void _scrollToOrdinal(int ordinal) {
    final rows = _visibleLayoutRows;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row is _SubsLayoutRow &&
          row.subLevelItem.ordinalLevelIndex == ordinal) {
        _itemScrollController.scrollTo(
          index: i,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
        return;
      }
    }
  }

  void _scrollToFurthestUnlocked() {
    final targetOrdinal = _lastCompletedOrdinalIndex + 1;
    if (targetOrdinal <= 0) return;
    _scrollToOrdinal(targetOrdinal.clamp(1, 999));
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
        child: ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
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
      _SubsLayoutRow(subLevelItem: final item) => _buildSubLevelRow(
            context,
            globalSubRowIndex,
            item,
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
    SubLevelItem subLevelItem,
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
    final isUnlocked = subLevelItem.ordinalLevelIndex <= _firstLockedOrdinalIndex;
    final isLocked = !isUnlocked;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: leftOffset),
          SizedBox(
            width: cellWidth,
            child: _buildSubLevelCell(
              context,
              subLevelItem,
              iconSize,
              isLocked: isLocked,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubLevelCell(
    BuildContext context,
    SubLevelItem subLevelItem,
    double iconSize, {
    required bool isLocked,
  }) {
    final sub = subLevelItem.sub;
    final iconPath = 'assets/images/level-icons/${sub.iconImageName}.png';

    Widget cell = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : () => _openQuiz(context, subLevelItem),
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

    if (isLocked) {
      cell = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: cell,
      );
    }
    return cell;
  }

  void _openQuiz(BuildContext context, SubLevelItem subLevelItem) async {
    final sub = subLevelItem.sub;
    final route = popFadeRoute<LevelCompletionResult>(
      widget.quizType == 'image'
          ? ImageQuizScreen(
              quizType: widget.quizType,
              subLevel: sub,
              ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
            )
          : widget.quizType == 'vocabulary'
              ? VocabularyQuizScreen(
                  quizType: widget.quizType,
                  subLevel: sub,
                  ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
                )
              : QuizPlaceholderScreen(
                  quizType: widget.quizType,
                  subLevel: sub,
                  ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
                ),
    );

    final result = await Navigator.of(context).push<LevelCompletionResult>(route);

    if (!mounted) return;
    if (result != null && result.completed) {
      setState(() {
        _justReturnedFromOrdinal = result.ordinalLevelIndex;
      });
      await _loadData();
      if (!mounted) return;
      _scrollToOrdinal(result.ordinalLevelIndex);
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
