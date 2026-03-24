import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_state.dart';
import '../quiz_game_constants.dart';
import 'quiz_flow_loader.dart';
import 'quiz_progress_service.dart';

class QuizTypeProfileStats {
  const QuizTypeProfileStats({
    required this.quizType,
    required this.currentLevel,
    required this.completedLevels,
    required this.totalLevels,
    required this.totalQuestionsAnswered,
    required this.currentStreak,
  });

  final String quizType;
  final int currentLevel;
  final int completedLevels;
  final int totalLevels;
  final int totalQuestionsAnswered;
  final int currentStreak;

  double get progressRatio {
    if (totalLevels <= 0) return 0;
    return completedLevels / totalLevels;
  }
}

class ProfileSummary {
  const ProfileSummary({
    required this.lifetimeStars,
    required this.lifetimeDiamonds,
    required this.perQuizStats,
  });

  final int lifetimeStars;
  final int lifetimeDiamonds;
  final List<QuizTypeProfileStats> perQuizStats;
}

class ProfileService {
  ProfileService._();
  static final ProfileService _instance = ProfileService._();
  static ProfileService get instance => _instance;

  static const String _profileKey = 'user_profile_state';
  static const List<String> _quizTypes = [kQuizGameType];
  static const String _avatarPrefix = 'assets/images/avatars/';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<ProfileState> loadOrCreateProfile() async {
    final prefs = await _preferences;
    final json = prefs.getString(_profileKey);
    if (json == null) {
      final created = ProfileState.initial(
        userId: _generateUserId(),
        now: DateTime.now(),
      );
      await saveProfile(created);
      return created;
    }
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final profile = ProfileState.fromJson(map);
      if (profile.userId.isEmpty || profile.dateJoinedIso.isEmpty) {
        final fixed = profile.copyWith(
          userId: profile.userId.isEmpty ? _generateUserId() : null,
          dateJoinedIso: profile.dateJoinedIso.isEmpty
              ? DateTime.now().toIso8601String()
              : null,
        );
        await saveProfile(fixed);
        return fixed;
      }
      return profile;
    } catch (_) {
      final created = ProfileState.initial(
        userId: _generateUserId(),
        now: DateTime.now(),
      );
      await saveProfile(created);
      return created;
    }
  }

  Future<void> saveProfile(ProfileState profile) async {
    final prefs = await _preferences;
    await prefs.setString(
      _profileKey,
      const JsonEncoder.withIndent('  ').convert(profile.toJson()),
    );
  }

  Future<List<String>> listAvatarAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final all = manifest.listAssets();
    final assets = all
        .where((path) =>
            path.startsWith(_avatarPrefix) &&
            (path.endsWith('.png') ||
                path.endsWith('.jpg') ||
                path.endsWith('.jpeg') ||
                path.endsWith('.webp')))
        .toList()
      ..sort();
    return assets;
  }

  Future<ProfileState> registerQuizCompletion({
    required String quizType,
    required int questionCount,
    DateTime? now,
  }) async {
    final profile = await loadOrCreateProfile();
    final localNow = (now ?? DateTime.now()).toLocal();
    final today = _dayKey(localNow);
    final yesterday = _dayKey(localNow.subtract(const Duration(days: 1)));

    final lastDay = profile.lastPlayedDay;
    final currentStreak = profile.currentStreak;
    int nextStreak;
    if (lastDay == today) {
      nextStreak = currentStreak;
    } else if (lastDay == yesterday) {
      nextStreak = currentStreak + 1;
    } else {
      nextStreak = 1;
    }

    final updatedQuestionCounts =
        Map<String, int>.from(profile.totalQuestionsAnsweredByQuizType)
          ..[quizType] =
              (profile.totalQuestionsAnsweredByQuizType[quizType] ?? 0) +
                  questionCount;

    final updated = profile.copyWith(
      lastPlayedDay: today,
      currentStreak: nextStreak,
      totalQuestionsAnsweredByQuizType: updatedQuestionCounts,
    );
    await saveProfile(updated);
    return updated;
  }

  Future<ProfileSummary> buildSummary(ProfileState profile) async {
    var lifetimeStars = 0;
    var lifetimeDiamonds = 0;
    final stats = <QuizTypeProfileStats>[];

    for (final quizType in _quizTypes) {
      final progress =
          await QuizProgressService.instance.loadProgress(quizType);
      final completed =
          progress.levels.values.where((level) => level.isCompleted).length;
      final totalStarsForType = progress.levels.values.fold<int>(
        0,
        (sum, level) => sum + level.highestStars,
      );
      lifetimeStars += totalStarsForType;
      lifetimeDiamonds += progress.totalDiamonds;

      int totalLevels = 0;
      try {
        final flowData = await loadGameFlow();
        totalLevels = flowData.subLevels.length;
      } catch (_) {
        totalLevels = 0;
      }

      final currentLevel =
          totalLevels == 0 ? 0 : min(completed + 1, totalLevels);

      stats.add(
        QuizTypeProfileStats(
          quizType: quizType,
          currentLevel: currentLevel,
          completedLevels: completed,
          totalLevels: totalLevels,
          totalQuestionsAnswered:
              profile.totalQuestionsAnsweredByQuizType[quizType] ?? 0,
          currentStreak: profile.currentStreak,
        ),
      );
    }

    return ProfileSummary(
      lifetimeStars: lifetimeStars,
      lifetimeDiamonds: lifetimeDiamonds,
      perQuizStats: stats,
    );
  }

  String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = Random().nextInt(1000000).toString().padLeft(6, '0');
    return '$timestamp-$nonce';
  }

  String _dayKey(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
