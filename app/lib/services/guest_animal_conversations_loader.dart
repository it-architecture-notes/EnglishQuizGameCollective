import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/guest_animal_conversations.dart';

const String _path = 'assets/data/config/guest_animal_conversations.json';

Future<GuestAnimalConversationsConfig> loadGuestAnimalConversations() async {
  final json = await rootBundle.loadString(_path);
  final map = jsonDecode(json) as Map<String, dynamic>;
  final list = (map['guestAnimalConversations'] as List<dynamic>?)
      ?.whereType<Map<String, dynamic>>()
      .map(LanguageConversations.fromJson)
      .toList() ??
      [];
  return GuestAnimalConversationsConfig(conversations: list);
}

/// Returns the entry for [language], or fallback to "en" if not found.
LanguageConversations? getForLanguage(
  GuestAnimalConversationsConfig config,
  String language,
) {
  for (final c in config.conversations) {
    if (c.language == language) return c;
  }
  for (final c in config.conversations) {
    if (c.language == 'en') return c;
  }
  return config.conversations.isNotEmpty ? config.conversations.first : null;
}

final _random = Random();

/// Picks one random [StepChoice] for the given step (1..4). Returns null if the step's array is empty or missing.
StepChoice? pickRandomStepConversation(LanguageConversations entry, int step) {
  final choices = entry.choicesForStep(step);
  if (choices.isEmpty) return null;
  return choices[_random.nextInt(choices.length)];
}
