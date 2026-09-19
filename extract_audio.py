import json
import subprocess
import os

level_dir = "app/assets/quiz-data/levels/at-the-farmers-market/adults"
video_path = os.path.join(level_dir, "Clip1.mp4")
q_path = os.path.join(level_dir, "questions.json")
scratch_dir = "/Users/nsahin/.gemini/antigravity/brain/e5989c2b-4e9d-4bec-a95d-e4af191f9eb2/scratch"

def time_to_sec(t_str):
    m, s = t_str.split(':')
    return int(m) * 60 + float(s)

with open(q_path) as f:
    data = json.load(f)

for i, q in enumerate(data.get("levelQuestions", [])):
    if q.get("template") == "VideoConversation":
        start_t = time_to_sec(q["start_at"])
        pause_t = time_to_sec(q["pause_at"])
        answer_t = time_to_sec(q.get("answer_until", q["pause_at"]))
        
        # Audio 1 (setup)
        if "audio_file1" in q:
            name = q["audio_file1"]
            out_m4a = os.path.join(level_dir, f"{name}.m4a")
            out_wav = os.path.join(scratch_dir, f"{name}.wav")
            dur = pause_t - start_t
            if dur > 0:
                print(f"Extracting {name} from {start_t} to {pause_t} ({dur}s)")
                subprocess.run(["ffmpeg", "-y", "-i", video_path, "-ss", str(start_t), "-t", str(dur), "-vn", "-c:a", "aac", "-b:a", "128k", out_m4a], capture_output=True)
                subprocess.run(["ffmpeg", "-y", "-i", video_path, "-ss", str(start_t), "-t", str(dur), "-vn", "-ac", "1", "-ar", "16000", out_wav], capture_output=True)

        # Audio 2 (confirm)
        if "audio_file2" in q:
            name = q["audio_file2"]
            out_m4a = os.path.join(level_dir, f"{name}.m4a")
            out_wav = os.path.join(scratch_dir, f"{name}.wav")
            dur = answer_t - pause_t
            if dur > 0:
                print(f"Extracting {name} from {pause_t} to {answer_t} ({dur}s)")
                subprocess.run(["ffmpeg", "-y", "-i", video_path, "-ss", str(pause_t), "-t", str(dur), "-vn", "-c:a", "aac", "-b:a", "128k", out_m4a], capture_output=True)
                subprocess.run(["ffmpeg", "-y", "-i", video_path, "-ss", str(pause_t), "-t", str(dur), "-vn", "-ac", "1", "-ar", "16000", out_wav], capture_output=True)

