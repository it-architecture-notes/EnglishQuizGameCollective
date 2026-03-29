import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../services/test_data_service.dart';

class SettingsPanelContent extends ConsumerWidget {
  const SettingsPanelContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final stringsAsync = ref.watch(currentLocalizedStringsProvider);
    final codesAsync = ref.watch(availableLanguageCodesProvider);

    return settings.when(
      data: (state) {
        final strings = stringsAsync.valueOrNull ?? {};
        final codes = codesAsync.valueOrNull ?? ['en'];
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LanguageDropdown(
                  value: state.language,
                  codes: codes,
                  strings: strings,
                  onChanged: (lang) =>
                      ref.read(settingsProvider.notifier).setLanguage(lang),
                ),
                const SizedBox(height: 16),
                _MusicSwitch(
                  value: state.musicOn,
                  label: strings['music'] ?? 'Music',
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setMusicOn(v),
                ),
                const SizedBox(height: 8),
                _SoundFxSwitch(
                  value: state.soundFxOn,
                  label: strings['sound_fx'] ?? 'Sound / FX',
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setSoundFxOn(v),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Test data',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await TestDataService.instance
                              .seedShortQuizEndAfter3With2Stars();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Short quiz on: levels end after 3 questions with 2 stars. '
                                  'Start a level to test.',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Seed: 3 questions → 2 stars'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await TestDataService.instance.clearTestData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Test data cleared.'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade300,
                        ),
                        child: const Text('Clear test data'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          e.toString(),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.value,
    required this.codes,
    required this.strings,
    required this.onChanged,
  });

  final String value;
  final List<String> codes;
  final Map<String, String> strings;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = strings['language'] ?? 'Language';
    return DropdownButtonFormField<String>(
      initialValue: codes.contains(value) ? value : (codes.isNotEmpty ? codes.first : null),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: codes
          .map((code) => DropdownMenuItem<String>(
                value: code,
                child: Text(strings['language_name_$code'] ?? code),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _MusicSwitch extends StatelessWidget {
  const _MusicSwitch({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _SoundFxSwitch extends StatelessWidget {
  const _SoundFxSwitch({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
