import json

path = "app/assets/quiz-data/levels/at-the-farmers-market/adults/questions.json"
with open(path) as f:
    data = json.load(f)

for q in data["levelQuestions"]:
    if q.get("template") == "VideoConversation":
        # Fix Q6
        if q.get("question_enter_audio") == "at-the-farmers-market1-q6-confirm":
            q["start_at"] = "00:22.80"
            q["pause_at"] = "00:25.50" # Approximate end of first sentence
            q["answer_until"] = "00:28.20"
            q["audio_file1_text"] = "I'll give you a discount if you buy in bulk."
            
        # Fix Q4 in Clip 2
        if q.get("audio_file1_text") == "Can we choose the big ones?":
            q["audio_file1"] = "at-the-farmers-market2-q4-setup"

with open(path, "w") as f:
    json.dump(data, f, indent=2)
