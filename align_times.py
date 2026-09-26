import json
import subprocess

path = "app/assets/quiz-data/levels/in-the-bathroom/adults-beginner/questions.json"

def get_duration(audio_key):
    if not audio_key or audio_key == "none":
        return 0.0
    # The file might be an array for exit_audio of paused templates, but we only care about non-paused!
    if isinstance(audio_key, list):
        return 0.0 # Handled by paused logic
    file_path = f"app/assets/quiz-data/levels/in-the-bathroom/adults-beginner/{audio_key}.m4a"
    try:
        output = subprocess.check_output(
            ["ffprobe", "-i", file_path, "-show_entries", "format=duration", "-v", "quiet", "-of", "csv=p=0"]
        )
        return float(output.strip())
    except Exception as e:
        print(f"Error getting duration for {file_path}: {e}")
        return 0.0

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

current_time = 0.0

for q in data["levelQuestions"]:
    if q.get("template") != "VideoConversation":
        break
    
    t_type = q.get("questionData", {}).get("answer_type", "")
    
    if "paused" in t_type:
        # Paused questions have 0 duration in terms of video roll
        time_str = f"00:{current_time:05.2f}"
        q["start_at"] = time_str
        q["pause_at"] = time_str
        q["answer_until"] = time_str
    else:
        # Non-paused questions
        start_time = current_time
        q["start_at"] = f"00:{start_time:05.2f}"
        
        enter_dur = get_duration(q.get("question_enter_audio"))
        pause_time = start_time + enter_dur
        q["pause_at"] = f"00:{pause_time:05.2f}"
        
        exit_dur = get_duration(q.get("question_exit_correct_audio"))
        
        if t_type == "AppearDisappear":
            # AppearDisappear doesn't have a post-answer video roll (usually)
            # Its answer_until is equal to pause_at. 
            answer_time = pause_time
        else:
            answer_time = pause_time + exit_dur
            
        q["answer_until"] = f"00:{answer_time:05.2f}"
        
        current_time = answer_time

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)

print("Times aligned based on contiguous audio lengths.")
