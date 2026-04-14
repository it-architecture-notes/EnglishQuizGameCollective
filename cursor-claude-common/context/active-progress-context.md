# Active Progress Context

## Active Issue

Description: Refactorings on audio, monster approach and translation on templates and quizzez.

Use Cases:
    General rules:
        - For all the audio enabled templates first check the audio tag in json object and second whether a audio file with the same name exists in the levels folder. if not don't enable the audio feature of the template.
        - If in any case user goes to next question when an audio is played, the audio will stop immediately and new page cycle will begin. 
    - Templates and corresponding objects will be refactored for the new requirements.
        - imageQuizTemplate-1: No translation or audio. remove both of them from the template and if provided ignore the given json object tags.
        - imageQuizTemplate-2: No translation. Audio file will be played once when the question appears after a pause (1 sec default), also there will be a button for audio, if the user presses this button while in the page it will play the audio for the question word again. while audio played, button will be disabled.
        - image template 3: No translation or audio. remove both of them from the template and if provided ignore the given json object tags.
        - image template spot difference: remove spot_difference_prompt from the template, only title_spot_difference is enough. no audio, no translation for this template.
        - convo template word pairs: No translation or audio. remove both of them from the template and if provided ignore the given json object tags.
        - convo template appear disappear:
            - this template will have translation however the translation will not be shown right away or auto. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation.
            - we will remove the initial follow the words intro screen and flashing. when entered the screen there will be a pause of 2 sec(configurable) then the words will start to appear in the box as it is now but on the main page not on a separate page. when completed, there will be another pause and then words will disappear. no flashing.
            - we will add a new feature. when user presses a title that's been already pressed the process will go back to the beginning to the time after the words disappear. That means user may restart the tapping to the tiles. however question page cycle will not begin from the beginning where words appear etc.
            - when the words appear in the boxes in the beginning, the audio file will play. without the audio file completed don't enable tapping to the tiles. audio file may finish before or after the word appearing cycle ends.
            - update to audio generation script: while generating the audio for this template put a pause between each word seperated by space so that they align with the words appearing one by one sequence.
        - convo template sentence builder:
            - this template will have translation however the translation will not be shown right away or auto. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation.     
            - Audio button will appear in the template. when tapped it will play the audio, when audio played button will be disabled.
        - convo template grammar:
            - this template will have translation however the translation will not be shown right away or auto. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation. translation will be the for the full sentence not with a blank.
            - no audio for this template.
        - convo dialog completion:
            - this template will have translation however the translation will not be shown right away or auto. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation. translation will be the for the full sentence not with a blank.
            - this template as a special template will support two audio file names: "audio_file1" and "audio_file2". First audio belongs to the question text. second audio belongs to the right answer.
            - first audio will be played in the beginning of the question, when question appers with a pause in the beginning.
            - second audio will be played when the user answers the questions. Whether answer is right or wrong the right answer audio will be played which is audio_file2.
            - if answer is correct the flow will go to next question after audio_file2 is completed. if answer is wrong the user next button will be avaialble only after audio_file2 playback is completed.
            - for audio_file1, which is question audio, a button will be placed in the template similar to sentence builder.
        - convo cloze sequence:
            - for this tempate there will not be an auto audio. however there will be an audio button similar to sentence builder playing the audio when pressed.
            - we will refactor the translation: we will not add the translation after the question sentence. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation. translation will be the for the full sentence not with a blank.
            - new feature for this template: when user presses a title that's been already pressed the process will go back to the beginning. That means user may restart the tapping to the tiles. this feature is available only if there are more than one cloze.
        - convo template 1:
            - this template will have translation however the translation will not be shown right away or auto. there will be a button in the screen and if tapped translation will appear and button will be disabled. the flow will not change based on translation button, it will only reveal the translation. translation will be the for the full sentence not with a blank.
            - for this template there will not be an auto audio. however there will be an audio button similar to sentence builder playing the audio when pressed.
        - convo template simon: remove this template completly I don't want to use this question template type.
