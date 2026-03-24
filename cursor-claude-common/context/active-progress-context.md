# Active Progress Context

## Issue-17: Refactor All the Levels to Single Level Map and Quiz with Question Template Structure
Description: In the current implementation we have different quiz types with different templates for them. This structure will be changed and there will be a single level map and a quiz subLevel will have different type of questions (image, vocabulary or grammar) in it.

Use Case:

- When user selects a sub level a subLevel (with iconImageName) config file will be read to identify the questions in the quiz.
- Each question will have a template that identifies the view of the screen and the parameters needed to fill that template.
- Current vocabulary, grammar (with conversations) and image quiz templates (with guest animal and monster) will be kept the same and reused. For vocabulary questions there could be more than one template with different set of template parameters. e.g. instead of conversation a template that has a single sentence and an image of the cloze.
- Image quiz data will still come from the images under folders for the quiz, however the wrong answers will be read from the config file instead of randomly picked from all the image list under the folder. Therefore, for image questions there will be a config object.
- Questions config object will be like one of these:
{
  "levelQuestions": [
    {
      "type": "image",
      "template": "imageQuizTemplate-1",
      "questionData": {
        "imageName": "Apple",
        "wrongAnswers": [
          "Appricot",
          "Soap",
          "Bored"
        ]
      }
    },
    {
      "type": "vocab",
      "template": "ConvoTemplate-1",
      "questionData": {
        "character1": "mike",
        "character2": "sarah",
        "line1": {
          "en": "Excuse me, where is the _____?",
          "tr": "Affedersiniz, _____ nerede?",
          "es": "Perdona, ¿dónde está _____?"
        },
        "line2": {
          "en": "The departure gate is on the right.",
          "tr": "Kalkış kapısı sağda.",
          "es": "La puerta de embarque está a la derecha."
        },
        "answer": "gate",
        "distractors": [
          "ticket",
          "luggage",
          "passport"
        ]
      }
    }
  ]
}
- Level maps will be merged into a single map and 3 buttons in the home screen will merge into a "Start Game" button. Since we merged level maps that means we will have a longer map but the logic of how many unlocked levels are shown etc will all remain the same.
- Reminder levels will now be quiz type agnostic so in a reminder level unanswered questions should be stored in a storage array to be able to generate reminder levels later.
