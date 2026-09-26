import json

path = "app/assets/quiz-data/levels/in-the-bathroom/adults-beginner/questions.json"

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

# The first 7 elements are the current video questions, plus the Chapter. 
# We'll replace the first 7 video questions with our new 10 questions.
old_questions = data["levelQuestions"]
# Keep the Chapter and everything after
remainder = [q for q in old_questions if q.get("template") != "VideoConversation"]

new_questions = [
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "00:00.00",
      "pause_at": "00:02.25",
      "answer_until": "00:02.25",
      "question_enter_audio": "none",
      "question_exit_correct_audio": "in-the-bathroom1-q1-setup",
      "question_exit_correct_audio_text": "I want you to take a shower.",
      "questionData": {
        "answer_type": "AppearDisappear",
        "words": "I want you to take a shower.",
        "distractors": ["need", "go", "make", "have"]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "00:02.25",
      "pause_at": "00:02.25",
      "answer_until": "00:04.60",
      "question_enter_audio": "none",
      "question_exit_correct_audio": "in-the-bathroom1-q2-confirm",
      "question_exit_correct_audio_text": "But I am not dirty.",
      "questionData": {
        "answer_type": "SentenceBuilder",
        "correct_order": "But I am not dirty."
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "00:04.60",
      "pause_at": "00:04.60",
      "answer_until": "00:04.60",
      "question_enter_audio": "in-the-bathroom1-q2-pause-setup",
      "question_enter_audio_text": "Does he want to take a shower?",
      "question_exit_correct_audio": "in-the-bathroom1-q2-pause-confirm",
      "question_exit_correct_audio_text": "No, he doesn't.",
      "genders": "f-m",
      "questionData": {
        "answer_type": "pausedClozeSequence",
        "sentence": "Does he _____ to take a shower? No, he _____.",
        "answer": ["want", "doesn't"],
        "distractors": ["wants", "don't", "is", "not"]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "00:04.60",
      "pause_at": "00:06.60",
      "answer_until": "00:07.80",
      "question_enter_audio": "none",
      "question_exit_correct_audio": "in-the-bathroom1-q3-confirm",
      "question_exit_correct_audio_text": "Just look in the mirror.",
      "questionData": {
        "answer_type": "ClozeSequence",
        "sentence": "Just _____ _____ the mirror.",
        "answer": ["look", "in"],
        "distractors": ["see", "at", "watch", "on"]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "00:07.80",
      "pause_at": "00:07.80",
      "answer_until": "00:07.80",
      "question_enter_audio": "in-the-bathroom1-q4-pause-setup",
      "question_enter_audio_text": "What does mom think?",
      "question_exit_correct_audio": "in-the-bathroom1-q4-pause-confirm",
      "question_exit_correct_audio_text": "The child is dirty.",
      "genders": "f-m",
      "questionData": {
        "answer_type": "pausedDialogueCompletion",
        "line1": "What does mom think?",
        "answer": "The child is dirty.",
        "distractors": [
          "The child is clean.",
          "The mirror is dirty.",
          "The child is tired."
        ]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "00:07.80",
      "pause_at": "00:08.93",
      "answer_until": "00:12.71",
      "question_enter_audio": "none",
      "question_exit_correct_audio": "in-the-bathroom1-q6-confirm",
      "question_exit_correct_audio_text": "I can just wash my hands and use soap.",
      "questionData": {
        "answer_type": "SentenceBuilder",
        "correct_order": "I can just wash my hands and use soap."
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "00:12.71",
      "pause_at": "00:15.30",
      "answer_until": "00:17.90",
      "question_enter_audio": "none",
      "question_exit_correct_audio": "in-the-bathroom1-q5-confirm",
      "question_exit_correct_audio_text": "No, you need to clean your body.",
      "questionData": {
        "answer_type": "SentenceBuilder",
        "correct_order": "No, you need to clean your body."
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "00:17.90",
      "pause_at": "00:17.90",
      "answer_until": "00:17.90",
      "question_enter_audio": "in-the-bathroom1-q6-pause-setup",
      "question_enter_audio_text": "What does he want to do?",
      "question_exit_correct_audio": "in-the-bathroom1-q6-pause-confirm",
      "question_exit_correct_audio_text": "Wash his hands and use soap.",
      "genders": "f-m",
      "questionData": {
        "answer_type": "pausedDialogueCompletion",
        "line1": "What does he want to do?",
        "answer": "Wash his hands and use soap.",
        "distractors": [
          "Clean his whole body.",
          "Look in the mirror.",
          "Comb his hair."
        ]
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "00:17.90",
      "pause_at": "00:23.80",
      "answer_until": "00:25.80",
      "question_enter_audio": "none",
      "question_exit_correct_audio": "in-the-bathroom1-q9-confirm",
      "question_exit_correct_audio_text": "Okay, do I comb my hair too?",
      "questionData": {
        "answer_type": "SentenceBuilder",
        "correct_order": "Okay, do I comb my hair too?"
      }
    },
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "00:25.80",
      "pause_at": "00:26.00",
      "answer_until": "00:29.20",
      "question_enter_audio": "none",
      "question_exit_correct_audio": "in-the-bathroom1-q7-confirm",
      "question_exit_correct_audio_text": "Yes, you are going to comb your hair too.",
      "questionData": {
        "answer_type": "SentenceBuilder",
        "correct_order": "Yes, you are going to comb your hair too."
      }
    }
]

data["levelQuestions"] = new_questions + remainder

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)

print("Fixed questions.json")
