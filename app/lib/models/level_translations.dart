import 'dart:convert';

/// One row in `translations.json` (`translations_list` element).
class TranslationEntry {
  const TranslationEntry({
    required this.englishWord,
    required this.translations,
  });

  final String englishWord;
  final Map<String, String> translations;
}

/// Parsed `translations.json` for the end-of-level / Words sheet.
class TranslationsPageData {
  const TranslationsPageData({required this.entries});

  final List<TranslationEntry> entries;

  /// Returns null on malformed JSON or missing `translations_list`.
  static TranslationsPageData? parse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final list = decoded['translations_list'];
      if (list is! List<dynamic>) return null;
      final out = <TranslationEntry>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final ew = e['english_word'];
        if (ew is! String) continue;
        final tr = e['translations'];
        if (tr is! Map) continue;
        final map = <String, String>{};
        for (final MapEntry(:key, :value) in tr.entries) {
          if (key is String && value is String) map[key] = value;
        }
        out.add(TranslationEntry(englishWord: ew, translations: map));
      }
      if (out.isEmpty) return null;
      return TranslationsPageData(entries: out);
    } catch (_) {
      return null;
    }
  }
}
