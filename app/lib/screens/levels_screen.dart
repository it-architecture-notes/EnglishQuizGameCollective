import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../models/level_completion_result.dart';
import '../models/quiz_flow.dart';
import '../models/reminder_progress.dart';
import '../models/story_config.dart';
import '../models/story_progress.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart' as audio;
import '../services/grammar_quiz_loader.dart';
import '../services/image_quiz_level_loader.dart';
import '../services/quiz_flow_loader.dart';
import '../services/quiz_progress_service.dart';
import '../services/reminder_progress_service.dart';
import '../services/story_config_loader.dart';
import '../services/story_progress_service.dart';
import '../services/story_trigger_service.dart';
import '../services/vocabulary_quiz_loader.dart';
import 'grammar_quiz_screen.dart';
import 'image_quiz_screen.dart';
import 'placeholders/quiz_placeholder_screen.dart';
import 'story/story_overlay_screen.dart';
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
    items.add(SubLevelItem(sub, ordinalLevelIndex: sub.levelNumber));
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
  ReminderProgressData _reminderProgress = const ReminderProgressData();
  StoryConfigData _storyConfig = const StoryConfigData(
    mainLevels: [],
    templatesById: {},
  );
  StoryProgressState _storyProgress = const StoryProgressState();

  /// Window into _filtered: only _filtered[_windowStart.._windowEnd-1] are shown.
  int _windowStart = 0;
  int _windowEnd = 0;
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

  // ---------------------------------------------------------------------------
  // Scroll anchor helpers
  // ---------------------------------------------------------------------------

/// Returns the ordinalLevelIndex of the sub-level immediately before [ordinalLevelIndex]
  /// in [filtered], skipping banners. Returns null if [ordinalLevelIndex] is the first sub-level.
  int? _findPreviousSubLevelOrdinal(
      List<LevelListItem> filtered, int ordinalLevelIndex) {
    int? prevOrdinal;
    for (final item in filtered) {
      if (item is SubLevelItem) {
        if (item.ordinalLevelIndex == ordinalLevelIndex) return prevOrdinal;
        prevOrdinal = item.ordinalLevelIndex;
      }
    }
    return null;
  }

  /// Returns the index in [filtered] that should become [_windowStart].
  ///
  /// With [anchorOrdinal]: positions the named sub-level at the top.
  /// Without anchor (default / fresh open): positions the last completed sub-level
  /// at the top so the frontier appears as the second visible sub-level.
  /// If no completed sub-level exists (very first quiz), returns 0 so the
  /// Level 1 banner is at the top.
  ///
  /// Call this only after the first setState in [_loadData] has run, so that
  /// the state-based helpers (_isReminderUnlocked etc.) use fresh data.
  int _findScrollStartIndex(
    List<LevelListItem> filtered,
    QuizTypeProgress progress, {
    int? anchorOrdinal,
  }) {
    if (anchorOrdinal != null) {
      for (var i = 0; i < filtered.length; i++) {
        final item = filtered[i];
        if (item is SubLevelItem && item.ordinalLevelIndex == anchorOrdinal) {
          return i;
        }
      }
      // Anchor not found — fall through to default.
    }

    // Default: find last completed sub-level before the frontier.
    int? lastCompletedIndex;
    for (var i = 0; i < filtered.length; i++) {
      final item = filtered[i];
      if (item is SubLevelItem) {
        final isRem = item.sub.isReminder;
        final isFrontier = isRem
            ? _isReminderUnlocked(item) && !_isReminderCompleted(item)
            : _isRegularLevelUnlocked(item, progress) &&
                (progress.levels[item.ordinalLevelIndex]?.highestStars ?? 0) == 0;
        final isCompleted = isRem
            ? _isReminderCompleted(item)
            : (progress.levels[item.ordinalLevelIndex]?.highestStars ?? 0) > 0;
        if (isFrontier) return lastCompletedIndex ?? 0;
        if (isCompleted) lastCompletedIndex = i;
      }
    }
    // No frontier found (all completed): show last completed or Level 1 banner.
    return lastCompletedIndex ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Unlock / completion helpers
  // ---------------------------------------------------------------------------

  List<SubLevelItem> _regularSubLevelsFrom(List<LevelListItem> items) {
    return items
        .whereType<SubLevelItem>()
        .where((item) => !item.sub.isReminder)
        .toList(growable: false);
  }

  List<SubLevelItem> get _regularSubLevels => _regularSubLevelsFrom(_items);

  Map<int, SubLevel> _regularSourceLevelsByMain(int mainLevel) {
    return {
      for (final item in _regularSubLevels.where(
        (item) => item.sub.mainLevel == mainLevel,
      ))
        item.sub.levelNumber: item.sub,
    };
  }

  int? _firstRegularOrdinalForMain(
    int mainLevel, {
    Iterable<SubLevelItem>? regularFlowSubLevels,
  }) {
    final flow = regularFlowSubLevels ?? _regularSubLevels;
    for (final item in flow) {
      if (item.sub.mainLevel == mainLevel) {
        return item.ordinalLevelIndex;
      }
    }
    return null;
  }

  bool _isRegularLevelUnlocked(
    SubLevelItem item,
    QuizTypeProgress progress, {
    Iterable<SubLevelItem>? regularFlowSubLevels,
    ReminderProgressData? reminderProgress,
  }) {
    final flow = regularFlowSubLevels ?? _regularSubLevels;
    final reminders = reminderProgress ?? _reminderProgress;
    final baseUnlocked =
        progress.unlockedLevelNumbers.contains(item.ordinalLevelIndex);
    if (!baseUnlocked) return false;

    final firstRegularOrdinal = _firstRegularOrdinalForMain(
      item.sub.mainLevel,
      regularFlowSubLevels: flow,
    );
    if (firstRegularOrdinal == null) return false;
    if (item.ordinalLevelIndex != firstRegularOrdinal) return true;

    final previousMainLevel = item.sub.mainLevel - 1;
    if (previousMainLevel < 1) return true;
    return reminders.isReminderCompleted(previousMainLevel, 2);
  }

  bool _isReminderCompleted(SubLevelItem item) {
    return ReminderProgressService.instance.isReminderCompleted(
      data: _reminderProgress,
      mainLevel: item.sub.mainLevel,
      reminderIndex: item.sub.reminderIndex,
    );
  }

  bool _isReminderUnlocked(SubLevelItem item) {
    return ReminderProgressService.instance.isReminderUnlocked(
      data: _reminderProgress,
      quizProgress: _progress,
      mainLevel: item.sub.mainLevel,
      reminderIndex: item.sub.reminderIndex,
      regularFlowSubLevels: _regularSubLevels,
    );
  }

  int _lastRegularLocalLevel(int mainLevelId, Iterable<SubLevelItem> regularFlow) {
    return regularFlow.where((item) => item.sub.mainLevel == mainLevelId).length;
  }

  bool _shouldGateAfterStoryPage({
    required StoryPageConfig page,
    required int mainLevelId,
    required Iterable<SubLevelItem> regularFlowSubLevels,
  }) {
    if (page.trigger.type != StoryTriggerType.afterLevel) return false;
    final resolvedTriggerLevel = StoryTriggerService.resolveTriggerLevel(
      page: page,
      mainLevelId: mainLevelId,
      flowSubLevels: regularFlowSubLevels,
    );
    final lastRegularLocalLevel =
        _lastRegularLocalLevel(mainLevelId, regularFlowSubLevels);
    return resolvedTriggerLevel == lastRegularLocalLevel &&
        !_reminderProgress.isReminderCompleted(mainLevelId, 2);
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadData({int? anchorOrdinal}) async {
    try {
      final data = await loadQuizFlow(widget.quizType);
      final progressFuture =
          QuizProgressService.instance.loadProgress(widget.quizType);
      final reminderProgressFuture =
          ReminderProgressService.instance.loadProgress(widget.quizType);
      final progress = await progressFuture;
      final reminderProgress = await reminderProgressFuture;
      StoryConfigData storyConfig = const StoryConfigData(
        mainLevels: [],
        templatesById: {},
      );
      StoryProgressState storyProgress = const StoryProgressState();
      try {
        final storyResults = await Future.wait([
          loadStoryConfig(widget.quizType),
          StoryProgressService.instance.loadProgress(widget.quizType),
        ]);
        storyConfig = storyResults[0] as StoryConfigData;
        storyProgress = storyResults[1] as StoryProgressState;
      } catch (e, st) {
        debugPrint('LevelsScreen story load skipped: $e\n$st');
      }
      final allItems = buildLevelItems(data);

      // Update state with fresh progress so scroll-anchor helpers use correct data.
      if (mounted) {
        setState(() {
          _items = allItems;
          _progress = progress;
          _reminderProgress = reminderProgress;
        });
      }

      final filtered = _applyFilter(allItems, progress, reminderProgress);
      storyProgress = await _syncCompletedStoryPages(
        storyConfig: storyConfig,
        storyProgress: storyProgress,
        progress: progress,
        allItems: allItems,
      );

      final startAt = _findScrollStartIndex(
        filtered,
        progress,
        anchorOrdinal: anchorOrdinal,
      );
      final end = (startAt + _batchSize).clamp(0, filtered.length);

      if (mounted) {
        setState(() {
          _items = allItems;
          _filtered = filtered;
          _progress = progress;
          _reminderProgress = reminderProgress;
          _storyConfig = storyConfig;
          _storyProgress = storyProgress;
          _windowStart = startAt;
          _windowEnd = end;
          _loading = false;
        });
        // The ItemScrollController retains its previous scroll offset even after
        // the widget is rebuilt via the loading spinner. If the user had scrolled
        // down before pushing the quiz (e.g. to tap a reminder level), the
        // controller restores that offset on the new list, causing minVisible > 1
        // which prevents the backward-expansion logic from firing.
        //
        // Fix: after the first frame, if backward expansion has not yet fired
        // (i.e. _windowStart still > 0), reset scroll to index 0 so _onScroll
        // sees minVisible=0 and triggers backward expansion normally.
        if (startAt > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_windowStart > 0 && _itemScrollController.isAttached) {
              _itemScrollController.jumpTo(index: 0);
            }
          });
        }
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

  /// Reloads data with a fresh list render (identical to the home-screen entry path).
  /// Sets _loading = true first so the ScrollablePositionedList is destroyed and
  /// rebuilt from scratch, ensuring _onScroll fires at index 0 on first render.
  Future<void> _freshLoadData({int? anchorOrdinal}) async {
    if (mounted) setState(() => _loading = true);
    await _loadData(anchorOrdinal: anchorOrdinal);
  }

  Future<StoryProgressState> _syncCompletedStoryPages({
    required StoryConfigData storyConfig,
    required StoryProgressState storyProgress,
    required QuizTypeProgress progress,
    required List<LevelListItem> allItems,
  }) async {
    final flowSubLevels = _regularSubLevelsFrom(allItems);
    var updated = storyProgress;
    var changed = false;
    for (final mainStory in storyConfig.mainLevels) {
      final ready = StoryTriggerService.pagesReadyToMarkCompleted(
        mainStory: mainStory,
        storyProgress: updated,
        quizProgress: progress,
        mainLevelId: mainStory.mainLevelId,
        flowSubLevels: flowSubLevels,
      );
      for (final page in ready) {
        if (_shouldGateAfterStoryPage(
          page: page,
          mainLevelId: mainStory.mainLevelId,
          regularFlowSubLevels: flowSubLevels,
        )) {
          continue;
        }
        if (updated.isCompleted(
          mainLevelId: mainStory.mainLevelId,
          eventId: page.eventId,
        )) {
          continue;
        }
        updated = updated.markCompleted(
          mainLevelId: mainStory.mainLevelId,
          eventId: page.eventId,
        );
        changed = true;
      }
    }
    if (changed) {
      await StoryProgressService.instance
          .saveProgress(widget.quizType, updated);
    }
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Scroll windowing
  // ---------------------------------------------------------------------------

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
        final jumpTarget = minVisible + added;
        setState(() => _windowStart = newStart);
        // Defer jumpTo to the next frame so it runs against the already-rebuilt
        // list. Calling jumpTo immediately after setState hits the OLD item list
        // whose size is _batchSize; when jumpTarget >= oldWindowSize the index
        // is out of bounds and the scroll lands on the wrong item.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _itemScrollController.isAttached) {
            _itemScrollController.jumpTo(index: jumpTarget);
          }
        });
      }
    }
  }

  List<_LayoutRow> get _visibleLayoutRows {
    final windowed = _filtered.sublist(_windowStart, _windowEnd);
    return _itemsToLayoutRows(windowed);
  }

  static const int _maxLockedPreview = 10;

  List<LevelListItem> _applyFilter(
    List<LevelListItem> rawItems,
    QuizTypeProgress progress,
    ReminderProgressData reminderProgress,
  ) {
    final visibleOrdinals = <int>{};
    var lockedRemaining = _maxLockedPreview;
    final regularFlowSubLevels = _regularSubLevelsFrom(rawItems);
    for (final item in rawItems) {
      if (item is SubLevelItem) {
        // Always include reminder levels in the filtered list so scroll indices
        // match the flow (otherwise startAt=10 can show L9 instead of Reminder 2).
        if (item.sub.isReminder) {
          visibleOrdinals.add(item.ordinalLevelIndex);
          continue;
        }
        final isUnlocked = _isRegularLevelUnlocked(
          item,
          progress,
          regularFlowSubLevels: regularFlowSubLevels,
          reminderProgress: reminderProgress,
        );
        if (isUnlocked) {
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

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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

  Widget _buildRow(
      BuildContext context, _LayoutRow row, int globalSubRowIndex) {
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
    final firstOrdinal = _firstRegularOrdinalForMain(meta.mainLevel);
    final isStoryUnlocked = firstOrdinal != null &&
        _isRegularLevelUnlocked(
          SubLevelItem(
            SubLevel(
              mainLevel: meta.mainLevel,
              levelNumber: firstOrdinal,
              iconImageName: '',
              title: '',
            ),
            ordinalLevelIndex: firstOrdinal,
          ),
          _progress,
        );
    final storyIconPath =
        _storyConfig.storyForMainLevel(meta.mainLevel)?.storyIconAssetPath;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
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
        ),
        Positioned(
          top: -2,
          right: 10,
          child: _buildStoryIcon(
            context,
            isUnlocked: isStoryUnlocked,
            iconPath: storyIconPath,
          ),
        ),
      ],
    );
  }

  Widget _buildStoryIcon(
    BuildContext context, {
    required bool isUnlocked,
    required String? iconPath,
  }) {
    final bg = isUnlocked
        ? Theme.of(context).colorScheme.tertiaryContainer
        : Colors.grey.shade400;
    final border = isUnlocked
        ? Theme.of(context).colorScheme.tertiary
        : Colors.grey.shade600;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: border, width: 1.5),
      ),
      child: isUnlocked
          ? ClipOval(
              child: iconPath != null
                  ? Image.asset(
                      iconPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.menu_book_rounded, size: 20),
                    )
                  : const Icon(Icons.menu_book_rounded, size: 20),
            )
          : const Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
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

    final isReminder = subLevelItem.sub.isReminder;
    final isCompletedReminder =
        isReminder && _isReminderCompleted(subLevelItem);
    final isUnlocked = isReminder
        ? _isReminderUnlocked(subLevelItem)
        : _isRegularLevelUnlocked(subLevelItem, _progress);
    final isLocked = !isUnlocked && !isCompletedReminder;
    final stars = isReminder
        ? 0
        : _progress.levels[subLevelItem.ordinalLevelIndex]?.highestStars ?? 0;

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
              isCompletedReminder: isCompletedReminder,
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
    required bool isCompletedReminder,
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
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          0.5,
          0,
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
              || isCompletedReminder
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
                    if (sub.isReminder)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          isCompletedReminder
                              ? Icons.check_circle_rounded
                              : isLocked
                                  ? Icons.lock_rounded
                                  : Icons.quiz_rounded,
                          size: 16,
                          color: isCompletedReminder
                              ? Colors.green
                              : isLocked
                                  ? Colors.grey.shade400
                                  : Theme.of(context).colorScheme.primary,
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(
                          3,
                          (i) => Icon(
                            i < stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 12,
                            color: isLocked ? Colors.grey.shade300 : Colors.amber,
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

  // ---------------------------------------------------------------------------
  // Quiz navigation
  // ---------------------------------------------------------------------------

  Future<Map<int, int>> _buildRegularQuestionCountsForMain(int mainLevel) async {
    final counts = <int, int>{};
    final regularSourceLevels = _regularSourceLevelsByMain(mainLevel);
    for (final sourceLevel in regularSourceLevels.values) {
      if (widget.quizType == 'image') {
        final levelKey =
            imageQuizLevelKey(sourceLevel.iconImageName, sourceLevel.levelNumber);
        final paths = await loadImageQuizLevelAssetPaths(levelKey);
        counts[sourceLevel.levelNumber] = paths.length;
      } else if (widget.quizType == 'vocabulary') {
        final level = await loadVocabularyLevel(
          sourceLevel.iconImageName,
          sourceLevel.levelNumber,
        );
        counts[sourceLevel.levelNumber] = level.questions.length;
      } else if (widget.quizType == 'grammar') {
        final level = await loadGrammarLevel(
          sourceLevel.iconImageName,
          sourceLevel.levelNumber,
        );
        counts[sourceLevel.levelNumber] = level.questions.length;
      }
    }
    return counts;
  }

  Future<void> _ensureReminderQuestionsGenerated(int mainLevel) async {
    final reminderState = _reminderProgress.reminderState(mainLevel, 1);
    if (reminderState.questionIds.isNotEmpty) return;
    final counts = await _buildRegularQuestionCountsForMain(mainLevel);
    final updated = await ReminderProgressService.instance.generateReminderQuestions(
      quizType: widget.quizType,
      mainLevel: mainLevel,
      questionCountByLevelNumber: counts,
    );
    if (!mounted) return;
    setState(() {
      _reminderProgress = updated;
    });
  }

  Route<LevelCompletionResult> _buildQuizRoute(
    SubLevelItem subLevelItem, {
    bool reminderMode = false,
    List<String>? reminderQuestionIds,
    Map<int, SubLevel>? reminderSourceLevelsByLevelNumber,
  }) {
    final sub = subLevelItem.sub;
    return popFadeRoute<LevelCompletionResult>(
      widget.quizType == 'image'
          ? ImageQuizScreen(
              quizType: widget.quizType,
              subLevel: sub,
              ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
              reminderMode: reminderMode,
              reminderQuestionIds: reminderQuestionIds,
              reminderSourceLevelsByLevelNumber:
                  reminderSourceLevelsByLevelNumber,
            )
          : widget.quizType == 'vocabulary'
              ? VocabularyQuizScreen(
                  quizType: widget.quizType,
                  subLevel: sub,
                  ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
                  reminderMode: reminderMode,
                  reminderQuestionIds: reminderQuestionIds,
                  reminderSourceLevelsByLevelNumber:
                      reminderSourceLevelsByLevelNumber,
                )
              : widget.quizType == 'grammar'
                  ? GrammarQuizScreen(
                      quizType: widget.quizType,
                      subLevel: sub,
                      ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
                      reminderMode: reminderMode,
                      reminderQuestionIds: reminderQuestionIds,
                      reminderSourceLevelsByLevelNumber:
                          reminderSourceLevelsByLevelNumber,
                    )
                  : QuizPlaceholderScreen(
                      quizType: widget.quizType,
                      subLevel: sub,
                      ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
                    ),
    );
  }

  void _openQuiz(BuildContext context, SubLevelItem subLevelItem) async {
    final sub = subLevelItem.sub;

    // Capture scroll anchor context before pushing the quiz, while _filtered
    // and _progress reflect the current state.
    //
    // wasAlreadyCompleted: true if this level was beaten before (replay).
    // A simpler check than full frontier detection — no unlock logic needed.
    final previousOrdinal =
        _findPreviousSubLevelOrdinal(_filtered, subLevelItem.ordinalLevelIndex);

    await _showBeforeStoryIfNeeded(subLevelItem);
    if (sub.isReminder) {
      await _ensureReminderQuestionsGenerated(sub.mainLevel);
    }
    final reminderState = _reminderProgress.reminderState(
      sub.mainLevel,
      sub.reminderIndex,
    );
    final route = _buildQuizRoute(
      subLevelItem,
      reminderMode: sub.isReminder,
      reminderQuestionIds: sub.isReminder ? reminderState.questionIds : null,
      reminderSourceLevelsByLevelNumber:
          sub.isReminder ? _regularSourceLevelsByMain(sub.mainLevel) : null,
    );

    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final result = await navigator.push<LevelCompletionResult>(route);
    if (!mounted) return;
    if (result == null) return;

    final int? anchorOrdinal = result.completed
        ? result.ordinalLevelIndex
        : previousOrdinal;

    if (result.completed) {
      final regularFlowSubLevels = _regularSubLevels;
      final localByOrdinal =
          StoryTriggerService.localLevelByOrdinal(regularFlowSubLevels);
      final completedLocalLevel = sub.isReminder
          ? _lastRegularLocalLevel(sub.mainLevel, regularFlowSubLevels)
          : localByOrdinal[subLevelItem.ordinalLevelIndex] ?? 1;
      final mainLevelId = sub.mainLevel;
      final mainStory = _storyConfig.storyForMainLevel(mainLevelId);
      StoryPageConfig? afterPage;
      if (sub.isReminder) {
        if (sub.reminderIndex == 2) {
          afterPage = StoryTriggerService.findAfterLevelPage(
            mainStory: mainStory,
            storyProgress: _storyProgress,
            mainLevelId: mainLevelId,
            completedLocalLevel: completedLocalLevel,
            flowSubLevels: regularFlowSubLevels,
          );
        }
      } else {
        final isLastRegularLevel =
            completedLocalLevel == _lastRegularLocalLevel(mainLevelId, regularFlowSubLevels);
        if (!isLastRegularLevel) {
          afterPage = StoryTriggerService.findAfterLevelPage(
            mainStory: mainStory,
            storyProgress: _storyProgress,
            mainLevelId: mainLevelId,
            completedLocalLevel: completedLocalLevel,
            flowSubLevels: regularFlowSubLevels,
          );
        } else {
          await _ensureReminderQuestionsGenerated(mainLevelId);
        }
      }
      await _freshLoadData(anchorOrdinal: anchorOrdinal);
      if (afterPage != null && mounted) {
        await _showStoryPage(afterPage);
      }
      await _freshLoadData(anchorOrdinal: anchorOrdinal);
    } else {
      await _freshLoadData(anchorOrdinal: anchorOrdinal);
    }
  }

  Future<void> _showBeforeStoryIfNeeded(SubLevelItem subLevelItem) async {
    if (subLevelItem.sub.isReminder) return;
    final regularFlowSubLevels = _regularSubLevels;
    final localByOrdinal = StoryTriggerService.localLevelByOrdinal(
      regularFlowSubLevels,
    );
    final localLevel = localByOrdinal[subLevelItem.ordinalLevelIndex] ?? 1;
    final mainLevelId = subLevelItem.sub.mainLevel;
    final mainStory = _storyConfig.storyForMainLevel(mainLevelId);
    final page = StoryTriggerService.findBeforeLevelPage(
      mainStory: mainStory,
      storyProgress: _storyProgress,
      mainLevelId: mainLevelId,
      currentLocalLevel: localLevel,
      flowSubLevels: regularFlowSubLevels,
    );
    if (page == null || !mounted) return;
    await _showStoryPage(page);
  }

  Future<void> _showStoryPage(StoryPageConfig page) async {
    final language = ref.read(settingsProvider).valueOrNull?.language ?? 'en';
    final strings =
        ref.read(currentLocalizedStringsProvider).valueOrNull ?? const {};
    final template = _storyConfig.templatesById[page.pageTemplateId];
    await StoryOverlayScreen.show(
      context,
      page: page,
      template: template,
      languageCode: language,
      continueLabel: strings['story_continue'] ?? 'Continue',
      congratulationsLabel:
          strings['story_congratulations'] ?? 'Congratulations!',
      isFinalPage: page.trigger.type == StoryTriggerType.afterLevel,
    );
  }
}
