import 'dart:convert';

import 'package:flutter/services.dart';

const String _path = 'assets/data/settings/localization.json';

Map<String, Map<String, String>>? _cache;

Future<Map<String, Map<String, String>>> _load() async {
  if (_cache != null) return _cache!;
  final json = await rootBundle.loadString(_path);
  final map = jsonDecode(json) as Map<String, dynamic>;
  _cache = map.map((lang, data) {
    final inner = (data as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as String),
    );
    return MapEntry(lang, inner);
  });
  return _cache!;
}

class LocalizationLoader {
  LocalizationLoader._();

  static Future<Map<String, Map<String, String>>> loadAll() async {
    return await _load();
  }

  static Future<List<String>> availableLanguageCodes() async {
    final m = await _load();
    return m.keys.toList()..sort();
  }

  static Future<String> string(String key, {String? lang}) async {
    final m = await _load();
    final code = lang ?? 'en';
    final inner = m[code] ?? m['en'];
    return inner?[key] ?? key;
  }
}
