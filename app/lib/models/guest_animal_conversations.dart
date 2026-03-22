class StepChoice {
  const StepChoice({required this.attacker, required this.guest});

  final String attacker;
  final String guest;

  static StepChoice fromJson(Map<String, dynamic> json) {
    return StepChoice(
      attacker: (json['attacker'] as String?) ?? '',
      guest: (json['guest'] as String?) ?? '',
    );
  }
}

class LanguageConversations {
  const LanguageConversations({
    required this.language,
    required this.step1Choices,
    required this.step2Choices,
    required this.step3Choices,
    required this.step4Choices,
  });

  final String language;
  final List<StepChoice> step1Choices;
  final List<StepChoice> step2Choices;
  final List<StepChoice> step3Choices;
  final List<StepChoice> step4Choices;

  List<StepChoice> choicesForStep(int step) {
    switch (step) {
      case 1:
        return step1Choices;
      case 2:
        return step2Choices;
      case 3:
        return step3Choices;
      case 4:
        return step4Choices;
      default:
        return [];
    }
  }

  static LanguageConversations fromJson(Map<String, dynamic> json) {
    return LanguageConversations(
      language: (json['language'] as String?) ?? 'en',
      step1Choices: _parseChoices(json['step1Choices']),
      step2Choices: _parseChoices(json['step2Choices']),
      step3Choices: _parseChoices(json['step3Choices']),
      step4Choices: _parseChoices(json['step4Choices']),
    );
  }

  static List<StepChoice> _parseChoices(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(StepChoice.fromJson)
        .toList();
  }
}

class GuestAnimalConversationsConfig {
  const GuestAnimalConversationsConfig({
    required this.conversations,
  });

  final List<LanguageConversations> conversations;
}
