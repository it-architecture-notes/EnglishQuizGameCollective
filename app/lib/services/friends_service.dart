import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/friends_state.dart';

class FriendsService {
  FriendsService._();
  static final FriendsService _instance = FriendsService._();
  static FriendsService get instance => _instance;

  static const String _key = 'friends_state';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<FriendsState> loadState() async {
    try {
      final prefs = await _preferences;
      final json = prefs.getString(_key);
      if (json == null) return const FriendsState();
      final map = jsonDecode(json) as Map<String, dynamic>;
      return FriendsState.fromJson(map);
    } catch (e, st) {
      debugPrint('FriendsService.loadState: $e\n$st');
      return const FriendsState();
    }
  }

  Future<void> saveState(FriendsState state) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(
        _key,
        const JsonEncoder.withIndent('  ').convert(state.toJson()),
      );
    } catch (e, st) {
      debugPrint('FriendsService.saveState: $e\n$st');
    }
  }
}
