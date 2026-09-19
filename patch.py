import json

with open("app/assets/quiz-data/levels/greetings/adults/translations.json", "r") as f:
    data = json.load(f)

new_words = [
    "Hello", "Hi", "How's it going?", "Not bad", "How about you?",
    "take care", "See you next time", "bye",
    "to live", "neighborhood", "also", "to need", "to go"
]

for w in new_words:
    data["translations_list"].append({
        "english_word": w,
        "translations": {
            "tr": "", "es": "", "fr": "", "de": "", "it": "", "pt": "",
            "ru": "", "zh": "", "ja": "", "ko": "", "ar": "", "hi": ""
        }
    })

with open("app/assets/quiz-data/levels/greetings/adults/translations.json", "w") as f:
    json.dump(data, f, indent=2)

print("Done")
