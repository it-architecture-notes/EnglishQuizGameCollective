import json
import os

path = "app/assets/quiz-data/levels/at-the-farmers-market/adults/questions.json"
with open(path) as f:
    data = json.load(f)

# Update the VideoConversation questions based on our transcription findings
q_updates = [
    # Q1 is fine (0-3.2, 3.2-7.2)
    {}, 
    # Q2
    {"start_at": "00:07.20", "pause_at": "00:09.60", "answer_until": "00:09.60"},
    # Q3
    {"start_at": "00:09.60", "pause_at": "00:12.60", "answer_until": "00:14.40"},
    # Q4
    {"start_at": "00:14.40", "pause_at": "00:14.40", "answer_until": "00:17.60"},
    # Q5
    {"start_at": "00:17.60", "pause_at": "00:21.00", "answer_until": "00:22.80"},
    # Q6
    {"start_at": "00:22.80", "pause_at": "00:22.80", "answer_until": "00:28.20"},
]

v_idx = 0
for q in data["levelQuestions"]:
    if q.get("template") == "VideoConversation":
        updates = q_updates[v_idx]
        for k, v in updates.items():
            q[k] = v
        v_idx += 1

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    
