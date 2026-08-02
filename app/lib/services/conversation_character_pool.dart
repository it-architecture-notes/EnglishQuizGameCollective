import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// Fills in display names for [ConvoQuestionData]/[DialogueCompletionQuestionData]
/// rows that omit `character1`/`character2` in JSON.
///
/// An authored (non-blank) name is always used verbatim, in every language —
/// this is what keeps rows where the name is baked into the spoken/displayed
/// text (e.g. "Hello, I am Beth") correct. A blank name is filled in from
/// `conversation_characters.json`'s pool for the current `userLanguage`
/// (falling back to the `en` pool for English, an unknown locale, or an
/// empty locale pool).
///
/// Which gender fills a blank slot is driven entirely by the row's mandatory
/// top-level `genders` field (e.g. `"m-f"` — see [LevelQuestion.genders]),
/// never inferred from the other slot's name. This keeps the picked display
/// name consistent with whatever voice/art was cast for that slot.
///
/// One instance is built per level load (see [loadLevelConfig]) and reused
/// for every question in that level, so its random picks are effectively
/// "one pool per game/level session" rather than reshuffled per question.
class ConversationCharacterPool {
  ConversationCharacterPool._({
    required List<String> poolMale,
    required List<String> poolFemale,
    Random? random,
  })  : _poolMale = poolMale,
        _poolFemale = poolFemale,
        _random = random ?? Random();

  static const String _assetPath =
      'assets/data/config/conversation_characters.json';

  final List<String> _poolMale;
  final List<String> _poolFemale;
  final Random _random;

  static Future<ConversationCharacterPool> loadForLanguage(
    String userLanguage,
  ) async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final pools = decoded['characterNamePools'] as Map<String, dynamic>? ?? const {};
      final en = pools['en'] as Map<String, dynamic>? ?? const {};
      final enMale = _stringList(en['male']);
      final enFemale = _stringList(en['female']);

      final locale = pools[userLanguage] as Map<String, dynamic>?;
      final localeMale = _stringList(locale?['male']);
      final localeFemale = _stringList(locale?['female']);

      return ConversationCharacterPool._(
        poolMale: localeMale.isNotEmpty ? localeMale : enMale,
        poolFemale: localeFemale.isNotEmpty ? localeFemale : enFemale,
      );
    } catch (_) {
      return ConversationCharacterPool._(poolMale: const [], poolFemale: const []);
    }
  }

  static List<String> _stringList(dynamic value) =>
      (value as List<dynamic>? ?? const []).map((e) => e.toString()).toList();

  String? _pickMale() =>
      _poolMale.isEmpty ? null : _poolMale[_random.nextInt(_poolMale.length)];

  String? _pickFemale() => _poolFemale.isEmpty
      ? null
      : _poolFemale[_random.nextInt(_poolFemale.length)];

  String? _pickForCode(String? code) {
    if (code == 'm') return _pickMale();
    if (code == 'f') return _pickFemale();
    // Missing/malformed genders code: last-resort random pick so the app
    // never crashes on bad content; validate_quiz_level_json.py is what
    // should actually catch this before it ships.
    return _random.nextBool() ? (_pickMale() ?? _pickFemale()) : (_pickFemale() ?? _pickMale());
  }

  /// Resolves the pair of display names for one conversational question.
  /// [genders] is the row's `"m-f"`-style code (character1-character2).
  /// Authored (non-blank) names are always returned unchanged; blank ones
  /// are filled from the pool using that slot's code from [genders].
  (String, String) resolveNames(String? genders, String character1, String character2) {
    final c1 = character1.trim();
    final c2 = character2.trim();

    final parts = (genders ?? '').trim().toLowerCase().split('-');
    final code1 = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
    final code2 = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : code1;

    final resolved1 = c1.isNotEmpty ? c1 : (_pickForCode(code1) ?? c1);
    final resolved2 = c2.isNotEmpty ? c2 : (_pickForCode(code2) ?? c2);
    return (resolved1, resolved2);
  }
}
