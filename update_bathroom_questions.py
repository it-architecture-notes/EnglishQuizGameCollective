import json
import os

path = "app/assets/quiz-data/levels/in-the-bathroom/adults-beginner/questions.json"

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_questions = [
    {
      "template": "VideoConversation",
      "videoFile": "in-the-bathroom1",
      "start_at": "TBD",
      "pause_at": "TBD",
      "answer_until": "TBD",
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
      "start_at": "TBD",
      "pause_at": "TBD",
      "answer_until": "TBD",
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
      "start_at": "TBD",
      "pause_at": "TBD",
      "answer_until": "TBD",
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
      "start_at": "TBD",
      "pause_at": "TBD",
      "answer_until": "TBD",
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
      "start_at": "TBD",
      "pause_at": "TBD",
      "answer_until": "TBD",
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
      "start_at": "TBD",
      "pause_at": "TBD",
      "answer_until": "TBD",
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
      "start_at": "TBD",
      "pause_at": "TBD",
      "answer_until": "TBD",
      "question_enter_audio": "none",
      "question_exit_correct_audio": "in-the-bathroom1-q7-confirm",
      "question_exit_correct_audio_text": "Yes, you are going to comb your hair too.",
      "questionData": {
        "answer_type": "SentenceBuilder",
        "correct_order": "Yes, you are going to comb your hair too."
      }
    },
    {
      "template": "Chapter",
      "displayImage": "image-questions"
    }
]

# Insert at the beginning
data["levelQuestions"] = new_questions + data["levelQuestions"]

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)

print("Updated questions.json")
