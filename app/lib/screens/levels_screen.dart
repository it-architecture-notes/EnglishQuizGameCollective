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
import '../services/level_config_loader.dart';
import '../services/quiz_flow_loader.dart';
import '../services/quiz_progress_service.dart';
import '../services/reminder_progress_service.dart';
import '../services/story_config_loader.dart';
import '../services/story_progress_service.dart';
import '../services/story_trigger_service.dart';
import '../widgets/level_translations_view.dart';
import 'quiz_runner_screen.dart';
import 'story/story_overlay_screen.dart';
import 'transitions/custom_page_routes.dart';

/// Builds the flattened list of items (banner + sub-level cells) from loaded flow data.
/// Invoked after [loadGameFlow] so the scroll list can render main-level headers then each [SubLevelItem].
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
    items.add(SubLevelItem(sub,
        ordinalLevelIndex: i + 1, progressKey: sub.progressKey));
  }

  return items;
}

/// Converts a slice of [LevelListItem]s into row descriptors for the curvy path layout pass.
/// Called from [build] when mapping the windowed [_filtered] slice into visual rows.
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

/// Scrollable world map of main-level banners and tappable sub-level nodes (regular + reminders).
class LevelsScreen extends ConsumerStatefulWidget {
  const LevelsScreen({super.key});

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

  /// Levels with `translations.json` (for Words button on map when completed + stars).
  Set<String> _levelsWithTranslations = {};

  /// Row index (in the fully-rendered layout row list) to align at the top of
  /// the viewport on the next list build. Set to the just-played level on return
  /// from a quiz, or the progression frontier on a fresh open.
  int _initialScrollIndex = 0;

  /// Bumped on every (re)load so the ScrollablePositionedList is rebuilt fresh
  /// and re-applies [_initialScrollIndex].
  int _listReloadToken = 0;
  String? _loadError;
  bool _loading = true;
  late ItemScrollController _itemScrollController;
  late ItemPositionsListener _itemPositionsListener;

  /// Curvy path: (sin+1)/2 drives position from left (0) to right (1).
  static const double _sinFrequency = 0.5;

  /// Wires scroll listeners and kicks off the first [_loadData] for flow + progress + story state.
  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Scroll anchor helpers
  // ---------------------------------------------------------------------------

  /// Returns the ordinal of the sub-level immediately before [ordinalLevelIndex]
  /// in [filtered] (banners skipped), or null if it is the first sub-level.
  /// Used to anchor scroll to `X-1` when replaying an already-completed level.
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

  /// Returns the index in [filtered] (equivalently, the layout row index) to
  /// align at the top of the viewport.
  ///
  /// With [anchorOrdinal]: positions the named sub-level at the top.
  /// Without anchor (default / fresh open): positions the last completed sub-level
  /// at the top so the frontier appears as the second visible sub-level.
  /// If no completed sub-level exists (very first quiz), returns 0 so the
  /// Level 1 banner is at the top.
  ///
  /// Picks the first visible list index after load—either [anchorOrdinal] or the progression frontier heuristic.
  /// Call only after [_loadData]’s first setState so unlock helpers read fresh progress.
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
                (progress.levels[item.progressKey]?.highestStars ?? 0) == 0;
        final isCompleted = isRem
            ? _isReminderCompleted(item)
            : (progress.levels[item.progressKey]?.highestStars ?? 0) > 0;
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

  /// Extracts non-reminder sub-level items from any [LevelListItem] list (e.g. full flow or filtered).
  List<SubLevelItem> _regularSubLevelsFrom(List<LevelListItem> items) {
    return items
        .whereType<SubLevelItem>()
        .where((item) => !item.sub.isReminder)
        .toList(growable: false);
  }

  /// Cached regular (non-reminder) sub-levels from the full loaded [_items] list.
  List<SubLevelItem> get _regularSubLevels => _regularSubLevelsFrom(_items);

  /// Maps each `progressKey` in [mainLevel] to its [SubLevelItem] for reminder question resolution.
  Map<String, SubLevelItem> _regularSourceLevelsByMain(int mainLevel) {
    return {
      for (final item in _regularSubLevels.where(
        (item) => item.sub.mainLevel == mainLevel,
      ))
        item.progressKey: item,
    };
  }

  /// First regular sub-level row belonging to [mainLevel] in the given flow ordering.
  SubLevelItem? _firstRegularItemForMain(
    int mainLevel, {
    Iterable<SubLevelItem>? regularFlowSubLevels,
  }) {
    final flow = regularFlowSubLevels ?? _regularSubLevels;
    for (final item in flow) {
      if (item.sub.mainLevel == mainLevel) return item;
    }
    return null;
  }

  /// Derives which `progressKey`s are reachable from the start given linear completion in [progress].
  Set<String> _computeUnlockedKeys(
    Iterable<SubLevelItem> regularItems,
    QuizTypeProgress progress,
  ) {
    final ordered = regularItems.toList();
    final unlocked = <String>{};
    if (ordered.isEmpty) return unlocked;
    unlocked.add(ordered.first.progressKey);

    int maxCompletedIndex = -1;
    for (var i = 0; i < ordered.length; i++) {
      if (progress.levels[ordered[i].progressKey]?.isCompleted == true) {
        maxCompletedIndex = i;
      }
    }
    for (var i = 0; i <= maxCompletedIndex + 1 && i < ordered.length; i++) {
      unlocked.add(ordered[i].progressKey);
    }
    return unlocked;
  }

  /// True if [item] passes linear unlock rules plus reminder gating for the first node of a main level.
  bool _isRegularLevelUnlocked(
    SubLevelItem item,
    QuizTypeProgress progress, {
    Iterable<SubLevelItem>? regularFlowSubLevels,
    ReminderProgressData? reminderProgress,
  }) {
    final flow = regularFlowSubLevels ?? _regularSubLevels;
    final reminders = reminderProgress ?? _reminderProgress;
    final baseUnlocked =
        _computeUnlockedKeys(flow, progress).contains(item.progressKey);
    if (!baseUnlocked) return false;

    final firstRegularItem = _firstRegularItemForMain(
      item.sub.mainLevel,
      regularFlowSubLevels: flow,
    );
    if (firstRegularItem == null) return false;
    if (item.progressKey != firstRegularItem.progressKey) return true;

    final previousMainLevel = item.sub.mainLevel - 1;
    if (previousMainLevel < 1) return true;
    // Only gate on the previous main level's second reminder when reminder
    // nodes actually exist for it. The current flow has no reminder levels, so
    // without this guard the first level of every main level (>= 2) would be
    // permanently locked (reminders can never be shown or completed).
    if (!_hasReminderNodesForMain(previousMainLevel)) return true;
    return reminders.isReminderCompleted(previousMainLevel, 2);
  }

  /// Whether the loaded flow contains any reminder sub-level nodes for [mainLevel].
  bool _hasReminderNodesForMain(int mainLevel) {
    for (final item in _items) {
      if (item is SubLevelItem &&
          item.sub.isReminder &&
          item.sub.mainLevel == mainLevel) {
        return true;
      }
    }
    return false;
  }

  /// Whether this reminder node was already cleared according to persisted reminder progress.
  bool _isReminderCompleted(SubLevelItem item) {
    return ReminderProgressService.instance.isReminderCompleted(
      data: _reminderProgress,
      mainLevel: item.sub.mainLevel,
      reminderIndex: item.sub.reminderIndex,
    );
  }

  /// Whether the player may open this reminder based on prior main-level and reminder completion rules.
  bool _isReminderUnlocked(SubLevelItem item) {
    return ReminderProgressService.instance.isReminderUnlocked(
      data: _reminderProgress,
      quizProgress: _progress,
      mainLevel: item.sub.mainLevel,
      reminderIndex: item.sub.reminderIndex,
      regularFlowSubLevels: _regularSubLevels,
    );
  }

  /// Counts how many regular sub-level rows exist for [mainLevelId] inside [regularFlow].
  int _lastRegularLocalLevel(
      int mainLevelId, Iterable<SubLevelItem> regularFlow) {
    return regularFlow
        .where((item) => item.sub.mainLevel == mainLevelId)
        .length;
  }

  /// Blocks auto-completing certain “after level” story pages until reminder 2 is done for that main level.
  bool _shouldGateAfterStoryPage({
    required StoryPageConfig page,
    required int mainLevelId,
    required Iterable<SubLevelItem> regularFlowSubLevels,
  }) {
    if (page.trigger.type != StoryTriggerType.afterLevel) return false;
    return StoryTriggerService.isTriggerOnLastRegularLevel(
          page: page,
          mainLevelId: mainLevelId,
          flowSubLevels: regularFlowSubLevels,
        ) &&
        !_reminderProgress.isReminderCompleted(mainLevelId, 2);
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  /// Fetches flow JSON, quiz/reminder/story progress, builds items, filters, window, and initial scroll state.
  Future<void> _loadData({int? anchorOrdinal}) async {
    try {
      final data = await loadGameFlow();
      final progressFuture = QuizProgressService.instance.loadProgress();
      final reminderProgressFuture =
          ReminderProgressService.instance.loadProgress();
      final progress = await progressFuture;
      final reminderProgress = await reminderProgressFuture;
      StoryConfigData storyConfig = const StoryConfigData(
        mainLevels: [],
        templatesById: {},
      );
      StoryProgressState storyProgress = const StoryProgressState();
      try {
        final storyResults = await Future.wait([
          loadStoryConfig(),
          StoryProgressService.instance.loadProgress(),
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

      final showAllLevels =
          ref.read(settingsProvider).valueOrNull?.showAllLevels ?? false;
      final filtered = _applyFilter(
        allItems,
        progress,
        reminderProgress,
        showAllLevels: showAllLevels,
      );
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

      var levelsWithTranslations = <String>{};
      final uiLang = ref.read(settingsProvider).valueOrNull?.language ?? 'en';
      if (uiLang != 'en') {
        for (final item in allItems) {
          if (item is SubLevelItem && !item.sub.isReminder) {
            final stars = progress.levels[item.progressKey]?.highestStars ?? 0;
            if (stars >= 1) {
              final d = await loadLevelTranslations(item.sub.directoryName);
              if (d != null) {
                levelsWithTranslations.add(item.sub.directoryName);
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _items = allItems;
          _filtered = filtered;
          _progress = progress;
          _reminderProgress = reminderProgress;
          _storyConfig = storyConfig;
          _storyProgress = storyProgress;
          _initialScrollIndex = startAt;
          _listReloadToken++;
          _loading = false;
          _levelsWithTranslations = levelsWithTranslations;
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

  /// Reloads data with a fresh list render (identical to the home-screen entry path).
  /// Sets _loading = true first so the ScrollablePositionedList is destroyed and
  /// rebuilt from scratch, so it re-applies [_initialScrollIndex] on the new list.
  Future<void> _freshLoadData({int? anchorOrdinal}) async {
    if (mounted) setState(() => _loading = true);
    await _loadData(anchorOrdinal: anchorOrdinal);
  }

  /// Marks story pages as completed when quiz progress satisfies triggers; persists when anything changed.
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
      await StoryProgressService.instance.saveProgress(updated);
    }
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Scroll windowing
  // ---------------------------------------------------------------------------

  /// Maps the full [_filtered] list into layout rows for the list builder.
  List<_LayoutRow> get _visibleLayoutRows => _itemsToLayoutRows(_filtered);

  /// Shows every level all the time; locked levels still render frozen. There is
  /// no preview budget or hiding of far-future nodes.
  List<LevelListItem> _applyFilter(
    List<LevelListItem> rawItems,
    QuizTypeProgress progress,
    ReminderProgressData reminderProgress, {
    bool showAllLevels = false,
  }) {
    return rawItems;
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  /// Localized AppBar title for this screen.
  String _titleFromStrings(Map<String, String> strings) {
    return strings['quiz_title_game'] ?? 'Levels';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  /// Loading/error scaffold or the scrollable map with AppBar back to [HomeScreen].
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
          key: ValueKey('levels-list-$_listReloadToken'),
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          initialScrollIndex: _initialScrollIndex,
          initialAlignment: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: visibleRows.length,
          itemBuilder: (context, index) {
            final row = visibleRows[index];
            final globalSubRowIndex =
                visibleRows.take(index).whereType<_SubsLayoutRow>().length;
            return _buildRow(context, row, globalSubRowIndex);
          },
        ),
      ),
    );
  }

  /// Dispatches one visible layout row to either a main-level banner or a sub-level path row.
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

  /// Colored title strip for a main level plus optional story shortcut when the first sub-level is unlocked.
  Widget _buildBanner(BuildContext context, MainLevelMeta meta) {
    final firstItem = _firstRegularItemForMain(meta.mainLevel);
    final isStoryUnlocked =
        firstItem != null && _isRegularLevelUnlocked(firstItem, _progress);
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
            isStoryUnlocked ? meta.title : 'Future Story',
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

  /// Circular story affordance on a banner (~70% of level-icon size); locked shows “?” until the first regular level opens.
  Widget _buildStoryIcon(
    BuildContext context, {
    required bool isUnlocked,
    required String? iconPath,
  }) {
    final levelIconSize = MediaQuery.sizeOf(context).width / 5;
    final size = levelIconSize * 0.7;
    final fallbackIconSize = size * 0.5;
    final bg = isUnlocked
        ? Theme.of(context).colorScheme.tertiaryContainer
        : Colors.grey.shade400;
    final border = isUnlocked
        ? Theme.of(context).colorScheme.tertiary
        : Colors.grey.shade600;
    return Container(
      width: size,
      height: size,
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
                          Icon(Icons.menu_book_rounded, size: fallbackIconSize),
                    )
                  : Icon(Icons.menu_book_rounded, size: fallbackIconSize),
            )
          : Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.45,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  /// Positions one sub-level icon along the sinusoidal path and computes lock/star state for the cell.
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
        : _progress.levels[subLevelItem.progressKey]?.highestStars ?? 0;

    // Words: gap from icon to screen left vs right; larger left gap → button on right.
    final iconLeftScreen = 16 + leftOffset + 4;
    final iconRightScreen = iconLeftScreen + iconSize;
    final leftGap = iconLeftScreen;
    final rightGap = width - iconRightScreen;
    final wordsOnRight = leftGap > rightGap;
    final showWords = !isReminder &&
        !isLocked &&
        stars >= 1 &&
        (ref.read(settingsProvider).valueOrNull?.language ?? 'en') != 'en' &&
        _levelsWithTranslations.contains(subLevelItem.sub.directoryName);

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
              showWordsButton: showWords,
              wordsOnRight: wordsOnRight,
            ),
          ),
        ],
      ),
    );
  }

  /// Fade popup with the same translations table as end-of-level sheet.
  Future<void> _showLevelWordsDialog(SubLevelItem item) async {
    final data = await loadLevelTranslations(item.sub.directoryName);
    if (!mounted || data == null) return;
    final strings = ref.read(currentLocalizedStringsProvider).valueOrNull ?? {};
    final lang = ref.read(settingsProvider).valueOrNull?.language ?? 'en';
    final soundFxOn = ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
    final mq = MediaQuery.of(context);
    final listH = (mq.size.height * 0.5).clamp(200.0, 420.0);

    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, animation, secChild, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
      pageBuilder: (ctx, anim, sec) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: math.min(360, mq.size.width - 48),
            child: LevelTranslationsView(
              entries: data.entries,
              userLanguage: lang,
              title: strings['translations_page_title'] ??
                  'Words Used In This Level',
              primaryLabel: strings['ok'] ?? 'OK',
              listViewportHeight: listH,
              onPrimary: () {
                audio.playClick(soundFxOn: soundFxOn);
                Navigator.of(ctx).pop();
              },
            ),
          ),
        );
      },
    );
  }

  /// Tappable level icon with lock desaturation, star row for regular levels, and reminder completion styling.
  Widget _buildSubLevelCell(
    BuildContext context,
    SubLevelItem subLevelItem,
    double iconSize, {
    required bool isLocked,
    required int stars,
    required bool isCompletedReminder,
    required bool showWordsButton,
    required bool wordsOnRight,
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

    final showAllLevels =
        ref.read(settingsProvider).valueOrNull?.showAllLevels ?? false;
    if (isLocked && !showAllLevels) {
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLocked || isCompletedReminder
                  ? null
                  : () {
                      final soundFxOn =
                          ref.read(settingsProvider).valueOrNull?.soundFxOn ??
                              true;
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isLocked && !showAllLevels
                                        ? Colors.grey.shade400
                                        : null,
                                  ),
                        ),
                        if (sub.isReminder)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Icon(
                              isCompletedReminder
                                  ? Icons.check_circle_rounded
                                  : isLocked && !showAllLevels
                                      ? Icons.lock_rounded
                                      : Icons.quiz_rounded,
                              size: 16,
                              color: isCompletedReminder
                                  ? Colors.green
                                  : isLocked && !showAllLevels
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
                                color: isLocked && !showAllLevels
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
          // Gap-based placement: more space on left of icon → Words on the right of cell.
          if (showWordsButton)
            Positioned(
              top: 0,
              left: wordsOnRight ? null : 0,
              right: wordsOnRight ? 0 : null,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  final soundFxOn =
                      ref.read(settingsProvider).valueOrNull?.soundFxOn ?? true;
                  audio.playClick(soundFxOn: soundFxOn);
                  _showLevelWordsDialog(subLevelItem);
                },
                child: const Text('Words', style: TextStyle(fontSize: 11)),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Quiz navigation
  // ---------------------------------------------------------------------------

  /// Loads each regular sub-level’s `questions.json` to count rows for reminder question generation.
  Future<Map<String, int>> _buildRegularQuestionCountsForMain(
      int mainLevel) async {
    final counts = <String, int>{};
    final regularItems =
        _regularSubLevels.where((item) => item.sub.mainLevel == mainLevel);
    for (final item in regularItems) {
      final sub = item.sub;
      try {
        final cfg = await loadLevelConfig(sub.directoryName);
        counts[item.progressKey] = cfg.questions.length;
      } catch (_) {
        counts[item.progressKey] = 10;
      }
    }
    return counts;
  }

  /// Ensures reminder 1 has a non-empty ID list by sampling wrong answers across that main level’s quizzes.
  Future<void> _ensureReminderQuestionsGenerated(int mainLevel) async {
    final reminderState = _reminderProgress.reminderState(mainLevel, 1);
    if (reminderState.questionIds.isNotEmpty) return;
    final counts = await _buildRegularQuestionCountsForMain(mainLevel);
    final updated =
        await ReminderProgressService.instance.generateReminderQuestions(
      mainLevel: mainLevel,
      questionCountByProgressKey: counts,
    );
    if (!mounted) return;
    setState(() {
      _reminderProgress = updated;
    });
  }

  /// Wraps [QuizRunnerScreen] in the standard fade route with progress/reminder parameters.
  Route<LevelCompletionResult> _buildQuizRoute(
    SubLevelItem subLevelItem, {
    bool reminderMode = false,
    List<String>? reminderQuestionIds,
    Map<String, SubLevelItem>? reminderSourceLevelsByProgressKey,
  }) {
    final sub = subLevelItem.sub;
    return popFadeRoute<LevelCompletionResult>(
      QuizRunnerScreen(
        subLevel: sub,
        ordinalLevelIndex: subLevelItem.ordinalLevelIndex,
        progressKey: subLevelItem.progressKey,
        reminderMode: reminderMode,
        reminderQuestionIds: reminderQuestionIds,
        reminderSourceLevelsByProgressKey: reminderSourceLevelsByProgressKey,
      ),
    );
  }

  /// Story gating, reminder prep, pushes the quiz, then refreshes the map and may show post-level story.
  void _openQuiz(BuildContext context, SubLevelItem subLevelItem) async {
    final sub = subLevelItem.sub;

    // Capture scroll-anchor context BEFORE pushing the quiz, while _filtered,
    // _progress and _reminderProgress still reflect the pre-play state.
    //
    // wasCompletedBefore: this level already had progress (replay) — option 2.
    // Otherwise it is a first play of a newly-playable level — option 1.
    final bool wasCompletedBefore = sub.isReminder
        ? _isReminderCompleted(subLevelItem)
        : (_progress.levels[subLevelItem.progressKey]?.highestStars ?? 0) > 0;
    final int? previousOrdinal =
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
      reminderSourceLevelsByProgressKey:
          sub.isReminder ? _regularSourceLevelsByMain(sub.mainLevel) : null,
    );

    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final result = await navigator.push<LevelCompletionResult>(route);
    if (!mounted) return;
    if (result == null) return;

    // Scroll anchor on return:
    //   Option 2 (replay of an already-completed level): anchor to X-1 so that
    //     level sits at the top of the viewport.
    //   Option 1 (first play of a newly-playable level, success OR fail): use
    //     the frontier heuristic (null anchor) which shows the last completed
    //     level above the current frontier — i.e. two colorful levels on top.
    //     On success the frontier advances (lands on X); on fail it stays (X-1).
    final int? anchorOrdinal = wasCompletedBefore ? previousOrdinal : null;

    if (result.completed) {
      final regularFlowSubLevels = _regularSubLevels;
      final localByOrdinal =
          StoryTriggerService.localLevelByOrdinal(regularFlowSubLevels);
      final completedLocalLevel = sub.isReminder
          ? _lastRegularLocalLevel(sub.mainLevel, regularFlowSubLevels)
          : localByOrdinal[subLevelItem.ordinalLevelIndex] ?? 1;
      // Story triggers match by flow title (works for reminders too).
      final completedLevelTitle = sub.title;
      final mainLevelId = sub.mainLevel;

      final mainStoryForBefore = _storyConfig.storyForMainLevel(mainLevelId);
      final beforePage = StoryTriggerService.findBeforeLevelPage(
        mainStory: mainStoryForBefore,
        storyProgress: _storyProgress,
        mainLevelId: mainLevelId,
        levelTitle: sub.title,
        flowSubLevels: regularFlowSubLevels,
      );
      if (beforePage != null) {
        _storyProgress = await StoryProgressService.instance.markCompleted(
          current: _storyProgress,
          mainLevelId: mainLevelId,
          eventId: beforePage.eventId,
        );
      }
      final mainStory = _storyConfig.storyForMainLevel(mainLevelId);
      StoryPageConfig? afterPage;
      if (sub.isReminder) {
        if (sub.reminderIndex == 2) {
          afterPage = StoryTriggerService.findAfterLevelPage(
            mainStory: mainStory,
            storyProgress: _storyProgress,
            mainLevelId: mainLevelId,
            levelTitle: completedLevelTitle,
            flowSubLevels: regularFlowSubLevels,
          );
        }
      } else {
        final isLastRegularLevel = completedLocalLevel ==
            _lastRegularLocalLevel(mainLevelId, regularFlowSubLevels);
        if (!isLastRegularLevel) {
          afterPage = StoryTriggerService.findAfterLevelPage(
            mainStory: mainStory,
            storyProgress: _storyProgress,
            mainLevelId: mainLevelId,
            levelTitle: sub.title,
            flowSubLevels: regularFlowSubLevels,
          );
        } else {
          await _ensureReminderQuestionsGenerated(mainLevelId);
          // Test Mode: skip reminder levels. Once the last regular level of this
          // main level is done, auto-complete both reminders so the player moves
          // on to the next main level without playing them.
          final testModeOn =
              ref.read(settingsProvider).valueOrNull?.testModeOn ?? false;
          if (testModeOn) {
            await ReminderProgressService.instance.markReminderCompleted(
              mainLevel: mainLevelId,
              reminderIndex: 1,
              answeredIds: const [],
            );
            await ReminderProgressService.instance.markReminderCompleted(
              mainLevel: mainLevelId,
              reminderIndex: 2,
              answeredIds: const [],
            );
          }
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

  /// Presents a “before level” story page when configured for this title.
  Future<void> _showBeforeStoryIfNeeded(SubLevelItem subLevelItem) async {
    final regularFlowSubLevels = _regularSubLevels;
    final mainLevelId = subLevelItem.sub.mainLevel;
    final mainStory = _storyConfig.storyForMainLevel(mainLevelId);
    final page = StoryTriggerService.findBeforeLevelPage(
      mainStory: mainStory,
      storyProgress: _storyProgress,
      mainLevelId: mainLevelId,
      levelTitle: subLevelItem.sub.title,
      flowSubLevels: regularFlowSubLevels,
    );
    if (page == null || !mounted) return;
    await _showStoryPage(page);
  }

  /// Full-screen story overlay with localized labels; used for before/after level narrative beats.
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
      previousLabel: strings['previous'] ?? 'Previous',
      nextLabel: strings['next'] ?? 'Next',
      okLabel: strings['ok'] ?? 'OK',
      isFinalPage: page.trigger.type == StoryTriggerType.afterLevel,
    );
  }
}
