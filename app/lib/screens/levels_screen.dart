import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../models/level_completion_result.dart';
import '../models/quiz_flow.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart' as audio;
import '../services/quiz_flow_loader.dart';
import '../services/quiz_progress_service.dart';
import 'grammar_quiz_screen.dart';
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

class LevelsScreen extends ConsumerStatefulWidget {
  const LevelsScreen({super.key, required this.quizType});

  /// Quiz type slug: 'image', 'vocabulary', 'grammar'.
  final String quizType;

  @override
  ConsumerState<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends ConsumerState<LevelsScreen> {
  List<LevelListItem> _items = [];
  List<LevelListItem> _filtered = [];
  QuizTypeProgress _progress = const QuizTypeProgress();
  /// Window into _filtered: only _filtered[_windowStart.._windowEnd-1] are shown.
  int _windowStart = 0;
  int _windowEnd = 0;
  int? _pendingScrollOrdinal;
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

  /// Finds the index in [filtered] where the frontier level starts.
  /// The frontier is the first unlocked level with 0 stars (current level to play).
  /// Returns 0 if no frontier found (e.g. all completed or fresh start).
  int _findFrontierIndex(List<LevelListItem> filtered, QuizTypeProgress progress) {
    final unlocked = progress.unlockedLevelNumbers;
    for (var i = 0; i < filtered.length; i++) {
      final item = filtered[i];
      if (item is SubLevelItem) {
        final ordinal = item.ordinalLevelIndex;
        if (unlocked.contains(ordinal) &&
            (progress.levels[ordinal]?.highestStars ?? 0) == 0) {
          if (i > 0 && filtered[i - 1] is BannerItem) return i - 1;
          return i;
        }
      }
    }
    return 0;
  }

  /// Finds the index in [filtered] for a given ordinalLevelIndex.
  int _findOrdinalIndex(List<LevelListItem> filtered, int ordinal) {
    for (var i = 0; i < filtered.length; i++) {
      final item = filtered[i];
      if (item is SubLevelItem && item.ordinalLevelIndex == ordinal) {
        if (i > 0 && filtered[i - 1] is BannerItem) return i - 1;
        return i;
      }
    }
    return 0;
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        loadQuizFlow(widget.quizType),
        QuizProgressService.instance.loadProgress(widget.quizType),
      ]);
      final data = results[0] as QuizFlowData;
      final progress = results[1] as QuizTypeProgress;
      final allItems = buildLevelItems(data);
      final filtered = _applyFilter(allItems, progress);

      int startAt;
      final pending = _pendingScrollOrdinal;
      if (pending != null) {
        _pendingScrollOrdinal = null;
        startAt = _findOrdinalIndex(filtered, pending);
      } else {
        startAt = _findFrontierIndex(filtered, progress);
      }

      final end = (startAt + _batchSize).clamp(0, filtered.length);

      if (mounted) {
        setState(() {
          _items = allItems;
          _filtered = filtered;
          _progress = progress;
          _windowStart = startAt;
          _windowEnd = end;
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

  Future<void> _reloadProgress() async {
    final progress =
        await QuizProgressService.instance.loadProgress(widget.quizType);
    if (!mounted) return;
    final filtered = _applyFilter(_items, progress);
    setState(() {
      _progress = progress;
      _filtered = filtered;
      _windowEnd = _windowEnd.clamp(0, filtered.length);
      _windowStart = _windowStart.clamp(0, _windowEnd);
    });
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final minVisible = positions
        .where((p) => p.itemLeadingEdge < 1)
        .map((p) => p.index)
        .fold<int>(999999, (a, b) => a < b ? a : b);
    final maxVisible = positions
        .where((p) => p.itemTrailingEdge > 0)
        .map((p) => p.index)
        .fold<int>(0, (a, b) => a > b ? a : b);

    final windowedItemCount = _windowEnd - _windowStart;

    if (maxVisible >= windowedItemCount - 2 && _windowEnd < _filtered.length) {
      final newEnd = (_windowEnd + _batchSize).clamp(0, _filtered.length);
      if (newEnd != _windowEnd && mounted) {
        setState(() => _windowEnd = newEnd);
      }
    }

    if (minVisible <= 1 && _windowStart > 0) {
      final oldStart = _windowStart;
      final newStart = (_windowStart - _batchSize).clamp(0, _filtered.length);
      if (newStart != oldStart && mounted) {
        final added = oldStart - newStart;
        setState(() => _windowStart = newStart);
        if (_itemScrollController.isAttached) {
          _itemScrollController.jumpTo(index: minVisible + added);
        }
      }
    }
  }

  List<_LayoutRow> get _visibleLayoutRows {
    final windowed = _filtered.sublist(_windowStart, _windowEnd);
    return _itemsToLayoutRows(windowed);
  }

  static const int _maxLockedPreview = 10;

  static List<LevelListItem> _applyFilter(
    List<LevelListItem> rawItems,
    QuizTypeProgress progress,
  ) {
    final unlocked = progress.unlockedLevelNumbers;
    final visibleOrdinals = <int>{};
    var lockedRemaining = _maxLockedPreview;
    for (final item in rawItems) {
      if (item is SubLevelItem) {
        if (unlocked.contains(item.ordinalLevelIndex)) {
          visibleOrdinals.add(item.ordinalLevelIndex);
        } else if (lockedRemaining > 0) {
          visibleOrdinals.add(item.ordinalLevelIndex);
          lockedRemaining--;
        }
      }
    }

    final visibleMainLevels = <int>{};
    for (final item in rawItems) {
      if (item is SubLevelItem &&
          visibleOrdinals.contains(item.ordinalLevelIndex)) {
        visibleMainLevels.add(item.sub.mainLevel);
      }
    }

    return rawItems.where((item) {
      if (item is BannerItem) {
        return visibleMainLevels.contains(item.meta.mainLevel);
      }
      if (item is SubLevelItem) {
        return visibleOrdinals.contains(item.ordinalLevelIndex);
      }
      return false;
    }).toList();
  }

  String _titleFromStrings(Map<String, String> strings) {
    final key = 'quiz_title_${widget.quizType}';
    return strings[key] ?? _titleFromSlug(widget.quizType);
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

  @override
  Widget build(BuildContext context) {
    final strings =
        ref.watch(currentLocalizedStringsProvider).valueOrNull ?? {};
    final title = _titleFromStrings(strings);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
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
    int subRowsBefore = 0;
    for (var i = 0; i < _windowStart; i++) {
      if (_filtered[i] is SubLevelItem) subRowsBefore++;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
            final globalSubRowIndex = subRowsBefore +
                visibleRows.take(index).whereType<_SubsLayoutRow>().length;
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
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.6),
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
    const horizontalPadding = 16.0 * 2;
    final iconSize = width / 5;
    final contentWidth = width - horizontalPadding;
    const cellHorizontalPadding = 8.0;
    final cellWidth = iconSize + 8 + cellHorizontalPadding;
    final pathRange = (contentWidth - cellWidth).clamp(0.0, double.infinity);
    const phase = -math.pi / 2;
    final t = (math.sin(globalSubRowIndex * _sinFrequency + phase) + 1) / 2;
    final leftOffset = t * pathRange;

    final isLocked =
        !_progress.unlockedLevelNumbers.contains(subLevelItem.ordinalLevelIndex);
    final stars =
        _progress.levels[subLevelItem.ordinalLevelIndex]?.highestStars ?? 0;

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
              stars: stars,
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
    required int stars,
  }) {
    final sub = subLevelItem.sub;
    final iconPath = 'assets/images/level-icons/${sub.iconImageName}.png';

    Widget iconWidget = ClipRRect(
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
    );

    if (isLocked) {
      iconWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 0.5, 0,
        ]),
        child: iconWidget,
      );
      iconWidget = Stack(
        alignment: Alignment.center,
        children: [
          iconWidget,
          const Icon(Icons.lock_rounded, color: Colors.white70, size: 28),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked
              ? null
              : () {
                  final soundFxOn =
                      ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
                  audio.playClick(soundFxOn: soundFxOn);
                  _openQuiz(context, subLevelItem);
                },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: iconWidget,
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: iconSize + 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      sub.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isLocked ? Colors.grey.shade400 : null,
                          ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List.generate(
                        3,
                        (i) => Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 12,
                          color: isLocked
                              ? Colors.grey.shade300
                              : Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              : widget.quizType == 'grammar'
                  ? GrammarQuizScreen(
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

    final result =
        await Navigator.of(context).push<LevelCompletionResult>(route);
    if (!mounted) return;
    if (result == null) return;

    if (result.completed) {
      _pendingScrollOrdinal = result.ordinalLevelIndex;
      await _loadData();
    } else {
      await _reloadProgress();
    }
  }
}
