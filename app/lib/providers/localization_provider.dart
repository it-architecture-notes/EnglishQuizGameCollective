import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/localization_loader.dart';
import 'settings_provider.dart';

final availableLanguageCodesProvider =
    FutureProvider<List<String>>((ref) => LocalizationLoader.availableLanguageCodes());

final localizedStringsProvider =
    FutureProvider.family<Map<String, String>, String>((ref, languageCode) async {
  final all = await LocalizationLoader.loadAll();
  return all[languageCode] ?? all['en'] ?? <String, String>{};
});

final currentLocalizedStringsProvider = Provider<AsyncValue<Map<String, String>>>((ref) {
  final settings = ref.watch(settingsProvider);
  final lang = settings.valueOrNull?.language ?? 'en';
  return ref.watch(localizedStringsProvider(lang));
});
