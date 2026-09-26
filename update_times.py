import json

path = "app/assets/quiz-data/levels/in-the-bathroom/adults-beginner/questions.json"

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

# Update the first 7 questions
times = [
    ("00:00.00", "00:02.25", "00:02.25"),
    ("00:02.25", "00:04.60", "00:04.60"),
    ("00:04.60", "00:06.60", "00:07.80"),
    ("00:07.80", "00:07.80", "00:07.80"),
    ("00:07.80", "00:15.30", "00:17.90"),
    ("00:17.90", "00:17.90", "00:17.90"),
    ("00:17.90", "00:26.00", "00:29.20")
]

for i in range(7):
    data["levelQuestions"][i]["start_at"] = times[i][0]
    data["levelQuestions"][i]["pause_at"] = times[i][1]
    data["levelQuestions"][i]["answer_until"] = times[i][2]

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)

print("Timestamps updated.")
