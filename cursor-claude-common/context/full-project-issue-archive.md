

**Issue-13: Reminder Quiz Levels at the end of Main Level**

Description: At the end of each main level we will include 2 reminder levels automatically which will ask a mix of questions from the level in the main level. The purpose is to remind the already compeleted items to the user. This is for every quiz type.

Use Cases:
- In the flow configuration, at the end of each level there will be two reminder quizzez. These quizzes will have common questions from the previous mainLevel levels. Their icon name will be iconImageName = "reminder.png"
- These levels will not have configured questions, they will pick the questions from the previous level based on this logic:
    - App will keep the wrongly answered each question from the levels of a main level in the gameplay state. e.g if users answers a question wrong in level 2 of main level this will be recorded so that question may be repeated in the reminder levels.
    - Some arbitatry questions from the previous levels some of the questions.
    - Don't make reminder level over 30 questions if wrong answers are over 60 (2 times 30) then remove starting from the least wrongly answered looking at the counter. If you need to decide between the wrongly answered with same wrong count then select randomly. Don't include any regular questions if wrong answers are more than than 60. If wrong questions is less then 60 then complete it to 60 by selecting random questions from the previous levels.
- Quizzez will be exactly same format of the quiz type (e.g. for image quiz reminder level quizzez, the page design etc will be the same as image quizzez)
- Quizzez will be included in the story flow as they are configured as part of the main level flow.

FAQ answers:
- User answered the same question wrong 3 times appear only once in the reminders.
- User played the same level and this time answered correctly, doesn't matter, still present in the reminders.
- User played the same level and this time answered wrong even previuous correct not in wrong list, include in the reminders.
- User played the same level and this time answered wrong and previuously in the wrong list, include in the reminders by increasing wrong counter.
- Random questions exclude wrong questions.
- The number of questions is dynamic since we don't know how many questions will be wrong.
- Questions distributed to reminder levels randomly, NOT first half to first reminder. shuffle(allReminderQuestions) split into two groups.
- Same question cannot appear in two levels
- If the user answers the same question wrong again, repeat it at the end of quiz until getting right. When you repeat the wrong questions in the reminder level ask them randomly at the end. so if there are 20 questions in total in the reminder level, user answers 5 wrong, ask this 5 with random order at the end, if still answers 3 wrong, ask after asking 5 questions this 3 in random order etc.
- There is no star and diamond earning in reminder levels
- Main level story is completed only after reminder levels
- Reminder levels will appear in the map UI with the same special icon picked from assets.
- question pool for reminders is all the levels in the same main level but not the reminder levels
- When are reminder questions generated is up to your decision.
- Wrong answer tracking is kept in the state json files.
- Reminder levels can be played only once and cannot be repeated. Since the user need to answer all questions right at some point. If user quits in the middle they can restart the reminder level again. User can play regular levels as much as they prefer.
- Reminder levels are locked and shown locked until the turn comes to them. Reminder levels are always at the end of main level.
- Main levels should not have less than 60 questions but in that case use all the questions in the main level as the regular questions and reminder levels will have less than 30 questions.
- If the user quits in the middle of the reminder level the same questions are repeated again, that means reminder level answers do not clear the wrong answer list.
- The scenario: 65 wrong answers, need to remove 5 to get down to 60. If the bottom 10 all have the same wrong count (e.g., all wrong once), randomly select which 5 to remove.
- No need to show users see how many times they've gotten a question wrong.
- For a reminder level to be considered "completed," the user needs to get ALL questions correct (due to the repetition of wrong questions at the end)
- The list is only cleared/updated once the entire Reminder Level is successfully completed, and we clear only the questions answered in that reminder level since there are more than one reminder levels.
- the 50 wrong answers and 10 randoms shuffled together first, then sliced
- the progress bar stays at 100% while they loop through. there be a visual indicator (like a header saying "Reviewing Mistakes")

---

**Issue-12: Main Level Story Implemenation**

* Description

Each main level contains a short story sequence (similar to Gardenscapes) where the player helps a character or situation improve.

The story progresses as the user completes quiz levels inside that main level.

Each main level has its own independent story.


* Functional Behavior

Story Start
When the user starts the first quiz level of a main level, the first story page is shown.

Story Progression
Story pages appear before specific quiz levels based on configuration.

Story Completion
After the last quiz of the main level is completed with ≥1 star, the final story page is shown.

Story Replay Rules

If a quiz is completed with 0 stars, the story page associated with that level will repeat when the user retries the level.

If a quiz is completed with ≥1 star, the associated story page is marked as completed and will not repeat during later replays of the same level.

Story progress is therefore tied to star completion status.

* Example Story Flow

Example main level with 5 quiz levels.

Flow:

Start Main Level 1 → Select Quiz 1
Show Story Page 0

Quiz 1 finished

if ≥1 star → Story Page 0 marked complete

Select Quiz 2
Show Story Page 1

Quiz 2 finished

if ≥1 star → Story Page 1 marked complete

Show Story Page 2
(This page instructs the player to complete the next two quizzes covered_levels_number = 2)

Quiz 3 finished

if ≥1 star → continue

Quiz 4 finished

if ≥1 star → Story Page 2 marked complete

Select Quiz 5

Quiz 5 finished

if ≥1 star → Show Final Story Page + congratulations animation

* Story Page Rules

Story pages are only displayed before a quiz starts.
One story page may cover multiple quiz levels.
Story pages belong to a specific main level.


* Story Configuration

Story content is defined in JSON configuration files.

Each story entry must specify:

main level ID
story pages
trigger quiz level
number of levels covered by the page
template type
text
images
animations

* Story Templates

Multiple story page templates can exist.

Each template may include different numbers of:

images

text blocks

animations

A template may omit certain elements.

Examples:

Template A

 character image
 speech bubble
 scene image

Template B

scene animation
multiple dialogue blocks

Template C

animation only
no dialogue

Templates are identified by page_template_id.

* Main Level Screen UI

On the level selection screen:

A round story icon is shown above the right side of the main level banner.

Rules:

If the first quiz of the main level is locked

→ show grey circle with question mark

If the first quiz is unlocked

→ show story icon image

* Transitions

When a story page opens or closes:

Use a fade-in / fade-out transition between the level map and the story overlay.

* Proposed Configuration Example - This schema can be improved during implementation.
{
  "main_levels": [
    {
      "main_level_id": 1,
      "story_sequences": [
        {
          "page_template_id": 1,
          "page_text_list_for_template": [
            {
              "en": "This puppy is injured! Help me take her to the vet.",
              "es": "¡Este cachorro está herido! Ayúdame a llevarla al veterinario."
            }
          ],

          "page_image_list_for_template": [
            "guide_puppy.png",
            "character_2.png"
          ],
          "page_animation_list_for_template": [
            "puppy_injury_animation"
          ],
          "event_id": 1,
          "trigger": {
        "type": "before_level or after_level",
        "level": 1
      },
          "covered_levels_number": 1
        }
      ]
    }
  ]
}

for templates:

{
  "story_templates": [
    {
      "template_id": 1,
      "layout": "character_left_dialogue_right",
      "requires_text": true,
      "requires_images": true,
      "requires_animation": false
    }
  ]
}

FAQ Answers: 

- If the player closes the story page the quiz start immediately since the story page is shown when the user already selects the level.
- players NOT be able to replay story pages later from a menu
- Not decided on type of animations, placeholder.
- story assets be bundled with the app
- main level story icon come from : defined in story JSON
- trigger->level = 3 covered_levels_number = 2 means page covers 3,4 
- If the user finishes Quiz 3 with 0 stars, then retries the story page before Quiz 3 reappear
- If A story page covers Level 3 and Level 4 and level 3 is completed, and level 4 failed. When the user replays level 4 don't show the story again.
- the "Animation" meant to an object contained inside the Frame not the full page.
- When Quiz 5 (the last level) is finished with $\ge 1$ star, wait until the user returns to the Map, then auto-pop the story.

**Issue-1: Project Baseline Setup**

-- Description:
Establish the foundational project structure and technical baseline for the portrait-mode mobile application. This includes selecting and agreeing on a technology stack with the developer, and setting up a scalable framework that supports multiple device resolutions—specifically targeting two mobile phone aspect ratios (e.g., 19.5:9 and 16:9) and two tablet aspect ratios (e.g., 4:3 and 16:10). The framework must also accommodate different background images optimized for each resolution group.

-- Goals

Define and document the tech stack in collaboration with the developer.
Set up the project structure to support future feature development.
Implement a resolution-aware system that can load appropriate background assets based on device type and aspect ratio.
Add folder structure for the assets as well: images (some images will be different for different resoutions), json files for configuration and state data.

-- Acceptance Criteria

Tech stack is selected, documented, and agreed upon by all stakeholders.
The project is initialized and configured for both Android and iOS portrait-mode development.
A resolution-handling mechanism is in place that detects device aspect ratios and serves corresponding background images.
Background image assets are organized and integrated for the four target aspect ratios.
The baseline is verified on representative devices or emulators for each target category.
The project is ready for the team to begin implementing user stories and features.

**Issue-2: Home screen with Buttons**

-- Description:
Generate a Flutter HomeScreen. Use a Stack to place a colorful background. In the center, create a Column with three large ElevatedButtons for 'Image Quiz', 'Vocabulary', and 'Grammar'. At the bottom of the screen, add a Container with 4 IconButtons representing Profile, Achievements, Friends, and Settings. Ensure the layout is responsive using MediaQuery."

- Image Quiz - When clicked opens a image quiz level screen. Level selection screen Will be explained in detail later.
 - Vocabulary - When clicked opens a vocabulary quiz level screen. Level selection screen Will be explained in detail later.
 - Grammar - When clicked opens a grammar quiz level screen. Level selection screen Will be explained in detail later.

Component,UI Strategy
Quiz Buttons,Use a Column for phones and a Grid (2 columns) for tablets to fill the width.
Navigation,Use a custom Container at the bottom with MainAxisAlignment.spaceEvenly.
Text Labels,"Keep labels short (e.g., ""Play,"" ""Me,"" ""Prizes"") or use icons only for younger kids."
Safe Area,"Wrap the entire Home Screen in a SafeArea to avoid the ""notch"" on iPhones."

Instead of a hidden menu, use a Bottom Navigation Bar or Action Row with these 4 high-visibility buttons:
Me (Profile): Displays the user's current avatar. Opens the Profile/Avatar customization screen. Opens profile settings panel where users can set their name and avatar.
Trophies (Achievements): A gold trophy icon. Opens a full-screen achievement panel.(placeholder UI for now)
Friends: An icon of a "Red heart" Opens the animal friend grid.(placeholder implementation)
Settings: A colorful gear icon. Opens the app settings.

Make Flutter automatically pick the right background.jpg for the device's screen density, create a folder structure accordingly for background image of home screen.

-- Goals

Create a vivid game entry page with user selections as explained

-- Acceptance Criteria

1. Visuals & Layout

Background: Use Stack with background.jpg set to BoxFit.cover.

Resolution: Asset folders (2.0x, 3.0x) must handle density automatically.

Safe Zone: Wrap all UI in a SafeArea to avoid notches/dynamic islands.

2. Main Quiz Buttons (Center)

Adaptive: Single Column on phones; 2-column Grid on tablets (MediaQuery).

Items: 3 Large buttons: Image Quiz, Vocabulary, Grammar.

Action: Tap navigates to placeholder level selection screens.

3. Dashboard Nav (Bottom)

Style: Fixed bottom container with spaceEvenly alignment.

4. Technical

Accessibility: Minimum 48x48 touch targets for kid-friendly use.

Performance: Precache background image to prevent flickering.

**Issue-3: Levels Page (Finite Batch Scroll) Objective**

Implement a vertically scrollable Levels page which opens when homescreen quiz is selected and that:

Loads data from local JSON files based on selected quiz type in home screen

Groups sub-levels under main-level ribbon banners

Renders sub-levels in batches of 10

Loads next batch when user scrolls within 300px of bottom

Opens correct quiz page on sub-level click

Data Sources
1. Sub-levels

File:

[quiz-type]-quiz-flow.json

Structure:

[
  { "mainLevel": 1, "iconImageName": "plane", "title": "Items in a Plane" },
  { "mainLevel": 1, "iconImageName": "hospital", "title": "Hospital Items" },
  { "mainLevel": 2, "iconImageName": "animals", "title": "Wild Animals" }
]

Rules:

Render in the order they appear.

No additional sorting.

2. Main Level Metadata

File:

[quiz-type]-flow-main-levels.json

Structure:

[
  { "mainLevel": 1, "title": "Transportation" },
  { "mainLevel": 2, "title": "Nature" }
]

Rules:

mainLevel must match sub-level file.

Banner title comes from this file.

If metadata missing for a mainLevel → skip rendering that group.

If metadata exists but no sub-levels → do not render banner.

Rendering Rules

Vertical scroll layout.

2-column responsive grid for sub-level icons.

Icon on top, title below.

Each main level banner appears once before its first sub-level.

Sub-level icons stored in:

/assets/flow-icons/[iconImageName].png

Missing image → show fallback placeholder.

Scroll Logic (Finite Batch Rendering)

Load entire JSON in memory at init.

Render first 10 sub-level items.

When scroll position is within 300px of bottom → render next 10.

Continue until all items rendered.

After last batch → stop loading (end-of-content behavior TBD).

Do not re-render previous items.

Batching is based on raw sub-level items (not grouped per main level).

Navigation

From Home:

Pass quiz-type string (e.g., image, text).

On Levels page:

Load:

[quiz-type]-quiz-flow.json

[quiz-type]-flow-main-levels.json

On sub-level click:

[quiz-type]-quiz.html

Example:

image → image-quiz-flow.json → image-flow-main-levels.json → image-quiz.html
Performance Constraints

Lazy load images.

Smooth scroll on mid-range mobile.

Expected total items < 300.

No virtualization required.

*Acceptance Criteria

Correct JSON files load per quiz type.

Sub-levels grouped under correct banners.

Initial render = 10 items.

Next batch loads at 300px threshold.

No duplicate banner rendering.

Images lazy load.

Clicking sub-level opens correct quiz page.

Responsive on mobile portrait.

No console errors when metadata and flow files align.

**Issue-4: Image Quiz Page**

* Description

This page is opened with a fade and scale animation when a level icon is selected from the Levels Page and the selected quiz type is Image Quiz.

The page contains:

A quiz question image displayed at the top of the page, loaded dynamically from the application assets.

Four answer buttons showing different words.

A Next button that is hidden by default and appears only when a wrong answer is selected.

An end-of-game panel that appears when all questions are answered. This panel contains:

Star rating (0–3 stars),

A diamond icon with text showing how many diamonds were earned in this level,

An “OK” button that navigates back to the Levels Page.

A loading screen may appear before the first question while assets are prepared.

* User Flow

When the user selects a level from the Levels Page, the selected level provides an iconName and levelNumber. The application loads all images from the assets subfolder named <iconName>-<levelNumber> (for example: plane-4). All image filenames inside that folder are collected. The filename without its extension becomes the correct answer text for that image. For example, from pilot.png the application extracts “pilot”.

The level folder must contain at least 4 images. If fewer than 4 images exist, the level must not start.

* Question Generation

For each question in the level:

A random unused image from the level folder is selected.

The filename (without extension) becomes the correct answer.

Three incorrect answers are randomly selected from the remaining vocabulary of the same level.

The four answers (one correct + three incorrect) are shuffled randomly.

No duplicate answers are allowed.

The same question image cannot appear more than once in the same level session.

The quiz continues until all images in the folder have been used exactly once.

* Answer Behavior

When the user selects an answer:

All answer buttons immediately become inactive to prevent multiple selections.

If the selected answer is correct:

The selected button turns green.

The application waits for a globally configured delay (autoAdvanceDelay seconds).

If it is not the last question, the next question loads automatically.

If it is the last question, the quiz proceeds directly to the end-of-level panel.

The correct answer counter is incremented.

If the selected answer is wrong:

The selected button turns red.

The correct answer button turns green.

The Next button appears below the answers.

The application waits for the user to press Next.

If it is the last question, the Next button becomes “Finish”.

* Scoring and Completion Rules

At the end of the level, the success rate is calculated as:

successRate = (correctAnswers / totalQuestions) × 100

Stars are awarded according to the following rules:

successRate ≥ 85% → 3 stars

successRate ≥ 70% and < 85% → 2 stars

successRate ≥ 60% and < 70% → 1 star

successRate < 60% → 0 stars

A level is considered completed only if the player earns at least 1 star (successRate ≥ 60%). The next level is unlocked only if the current level is completed.

If the player earns 0 stars, the level is not marked complete and the next level remains locked.

After the result panel is shown, pressing “OK” returns the player to the Levels Page.

* Diamonds and Replay Rules

Diamonds earned in a level are calculated as:

diamondsEarned = correctAnswers

Diamonds are accumulated globally across all levels within the same quiz type.

If the level is replayed:

If the new diamondsEarned is less than or equal to the previously recorded diamonds for that level, no additional diamonds are added to the total.

If the new diamondsEarned is greater than the previously recorded value, only the difference is added to totalDiamonds.

Example:

First play: 6 diamonds

Second play: 9 diamonds

Additional diamonds awarded: 3

Star ratings are stored as the highest star achieved. A new star value overwrites the previous value only if it is higher.

* Persistence

Game state is stored in a JSON file in the local storage of the mobile device, accessible by the application for reading and writing.

Data is saved only when a level is completed (after the end-of-level screen appears).

Stored data includes, per quiz type:

levelNumber

highestStars

highestDiamonds

completion status

totalDiamonds (global for that quiz type)

unlocked levels

Each quiz type maintains separate progress. Completing Level 1 in Image Quiz does not complete or unlock Level 1 in other quiz types.

If the user exits the application during a level, no progress is saved and the level restarts from the beginning when reopened.

* Acceptance Criteria

A level must not start if its folder contains fewer than 4 images.

Each image in a level is used exactly once per level session.

Each question displays exactly 4 answer buttons.

Answer options contain exactly one correct answer and no duplicates.

After selecting an answer, all answer buttons become inactive.

If the answer is correct, the next question loads automatically after the configured delay.

If the answer is wrong, the correct answer is highlighted and a Next button appears.

On the final question, the flow proceeds to the end-of-level screen.

Star rating follows the defined percentage thresholds.

A level is marked complete only if at least 1 star is earned.

Diamonds are awarded equal to the number of correct answers.

Replay does not allow diamond farming; only improvement differences are added.

Only the highest star value is stored.

Progress is saved only after level completion.

Exiting mid-level results in a full restart of that level.


**Issue-5: Vocabulary Test Quiz Page**

Description:
Implement a vocabulary test quiz page that tests users' vocabulary through cloze (fill-in-the-blank) questions within a conversational context. The page presents a step-by-step conversation between two characters across 10 questions, where users must identify the correct word to complete the blank space.

User Flow:

User selects a vocabulary quiz level from the Levels Page (e.g., "airport" theme, level 4)

System loads the corresponding JSON data file and character images

User progresses through 10 conversation steps, each with one fill-in-the-blank question

User selects answers from 4 multiple-choice buttons

After completing all questions, user can view the full conversation

Users can toggle translations at any time to see the conversation in other languages

Data Structure & Assets:

JSON File Format:

Location: /assets/vocabulary/data/

Naming convention: [theme-name]-[level-number].json (e.g., airport-4.json)

Schema:

json
[
  {
    "character1": "mike",  // icon name for first character
    "character2": "sarah", // icon name for second character
    "line1": {
      "en": "Can you help me find the _____?",  // English with blank
      "tr": "_____ bulmama yardım eder misin?",  // Turkish translation
      "es": "¿Puedes ayudarme a encontrar _____?" // Spanish translation
      // Additional languages as needed
    },
    "line2": {
      "en": "The departure gate is on the right.",
      "tr": "Kalkış kapısı sağda.",
      "es": "La puerta de embarque está a la derecha."
    },
    "answer": "gate",  // correct word for the blank
    "distractors": ["ticket", "luggage", "passport"] // wrong answer options
  },
  // 9 more objects for the full conversation
]
Character Images:

Location: /assets/vocabulary/characters/

Format: PNG files named after character identifiers (e.g., mike.png, sarah.png)

Page Design & UI Components:

Header Section:

Two character images displayed side by side

Character name labels under each image (e.g., "Mike", "Sarah")

Conversation bubbles pointing to each character containing their dialogue line

Current question indicator (e.g., "Question 3/10")

Conversation Display:

Character 1 image with bubble showing line1 text (with blank)

Character 2 image with bubble showing line2 text (may or may not contain blank)

Blank represented as "_____" in the text

One blank per question, located in either line1 or line2 based on answer field

Answer Selection:

4 multiple-choice buttons below the conversation bubbles

Options include correct answer + 3 distractors from JSON

Styling consistent with Image Quiz buttons

Immediate visual feedback on answer selection

Selected answer highlights

Next question appears automatically after selection (or with "Next" button - TBD)

Action Buttons:

Translate Button:

Tap to toggle functionality

When active, replaces all conversation text with translations in selected language

Tapping again reverts to English

Translates both conversation bubbles simultaneously

Language selection (if multiple languages) to be determined

Show Full Conversation Button:

Grayed out/disabled until all 10 questions are completed

After completion, tap to open scrollable panel

Panel displays complete conversation with line owner labels

Shows original English text only

Format: "Mike: Can you help me find the gate?" (with actual word, not blank)

Technical Requirements:

Data Loading:

On page load, parse theme and level from URL/state

Construct JSON file path: /assets/vocabulary/data/[theme]-[level].json

Load character images from /assets/vocabulary/characters/

Handle missing files gracefully with error message

Question Logic:

Track current question index (0-9)

Parse JSON to determine which line contains the blank (line with answer in its English text)

Display correct line with "_____" placeholder

Shuffle answer options (correct + distractors) for each question

Validate user selection against answer field

Track correct/incorrect answers for reporting

Translation Feature:

Store current language state (default: 'en')

On translate toggle, switch all visible text to selected language

Maintain blank placeholder in translations where answer should be

Ensure smooth transition between languages

Full Conversation Panel:

Enable button only after question 10 is answered

Generate ordered list of all 10 exchanges

Replace blanks with actual answers

Display in scrollable modal/drawer

State Management:

Current question index

User answers for each question

Translation language state

Quiz completion status

Acceptance Criteria:

Loads correct JSON data based on selected theme and level

Displays 2 character images with name labels and conversation bubbles

Shows current question progress (e.g., "3/10")

Correctly identifies which line contains the blank

Displays blank as "_____" in appropriate line

Presents 4 shuffled answer options including correct answer

Provides immediate visual feedback on answer selection

Translate button toggles all text between English and selected language

Full conversation button disabled until quiz completion

After completion, full conversation panel shows all 10 exchanges with answers filled in

Character images load correctly from assets folder

Graceful error handling for missing JSON files or images

Responsive design works on mobile and tablet

Dependencies:

Level selection passes correct theme and level parameters

Vocabulary JSON files created for all themes/levels

Character icon images available in assets folder

Translation strings available in JSON files

Future Considerations:

Add support for multiple translation languages

Implement scoring and progress saving

Add sound effects for correct/incorrect answers

Consider animation for conversation flow


**Issue-6: Profile Panel**

Description:
Defines scope and strcuture of the user profile panel that can be opened on the home screen.

- Profile button opens the panel
- On the panel there are these fields:
- Avatar Name
- Avatar Picture, Avatar Change Button, A panel opens when avatar change button is pressed (pop up) and a grid of avatar pictures are offered 4x4 for now. Avatar pictures will be read from avatars folder. When an avatar is selected panel is closed and avatar is accepted as user avatar and saved when profile panel is closed. In the beginning an avatar picture with ? mark will be assigned to each new user.
- Profile Panel Close Button on top right. This button saves the state to the game play json state file where stars and diamonds are kept.
- The main achievements like how many stars, diamonds are collected until to date is shown.
- When the user opens the profile panel the first time a unique id or uuid (timestamp uniqueness nonce) is assigned to the user and saved in the state json. Also the date joined is created and saved. 
- Current Level, completed levels, level progress. total number of questions answered, streak also presented for each quiz type are shown. All of these parameters are calculated when a quiz ends (any type of quiz) and saved in the state json. Level progress will be calculated with maximum level is calculated according to the flow json

1. Access & Navigation

Trigger: Tapping the Profile button on the Home Screen opens the panel.

Dismissal: A Close Button (X) is located in the top-right corner.

Persistence: Closing the panel triggers a save operation to the game_play_state.json file.

2. Identity & Avatar Management

User Info: Display Avatar Name, generate but do not show Unique ID (UUID), and Date Joined.

Logic: If a UUID/Date Joined does not exist (first-time open), generate them using a timestamp or any other method to avoid collision.

Avatar Selection: * Initial State: New users are assigned a default "?" placeholder image.

Change Workflow: Tapping the "Change" button opens a 4x4 grid popup.

Source: Images are dynamically loaded from the /avatars folder.

Selection: Selecting an image updates the preview and closes the popup immediately. The change is committed to the state file when the main Profile Panel is closed.

3. Statistics & Achievement Display

Economy: Show lifetime totals for Stars and Diamonds.

Progression: * Current Level & Completed Levels.

Level Progress Bar per quiz type: Calculated based on the flow json number of levels, or instead of calculating again everytime you can store the number of levels in a persisted data parameter.

Activity Metrics: * Total questions answered.

Current Streak.

Performance breakdown per Quiz Type.

Note: These values are pre-calculated and updated in the JSON state at the end of each quiz session.


**Issue-7: Progression System – Level Unlocking & Star History**

Description

Refactor the Levels Page from a fully unlocked state to a progression-based system. Users must earn stars to advance, and visibility of future levels is restricted to a dynamic "10-level window."

Functional Requirements & Core Logic
- Initial State: New users (no progress) see only the first level of all quiz types as unlocked. All other levels are initially disabled.
- Unlock Criteria: Level $N+1$ unlocks only if Level $N$ is completed with $\ge 1$ star. A score of 0 stars indicates the level is not yet completed.
- Replayability: Users can replay any unlocked level (including those with 3 stars) at any time.

Rewards & Persistence
- Performance Tracking: Maintain a history in the state JSON of the best_stars and best_diamonds earned for every level.
- Delta-Based Rewards: Users only earn the improvement over their previous best.Calculation: $Earned = \max(0, Current\_Play - Previous\_Best)$.
  If the current run is lower than the previous high score, 0 additional diamonds/stars are awarded.
- Wallet Integration: The Total Wallet (Global Stars/Diamonds) must be updated immediately upon level completion.

Navigation & UX
- Cold Boot Behavior: When the app is launched fresh, the Levels Page should auto-scroll to the furthest unlocked level.
- Session Persistence: During an active app session, after completing a level and returning to the menu, the scroll view must focus (center) on the level just played, rather than jumping to the furthest progress point.

UI States & Visibility ("The Horizon")
- Active State: Levels with $\ge 1$ star and the first currently available locked level are fully colored and interactable.
- Locked State (The Window): The 10 levels immediately following the last completed level are visible but desaturated (greyscale) and non-interactable.
- Hidden State: Any level index $> (Last\_Completed\_Index + 10)$ must not be rendered in the DOM/UI list.
- Dynamic Update: Upon successful completion of a level, the UI must append the next available "Hidden" level to the list to maintain the 10-level visibility buffer.Issue-7: Progression System – Level Unlocking & Star History


**Issue-8: Achievements Page**

Description: Adding the achievements to the existing achievements panel which is opened by thropies button from homescreen.

Use Cases:
- User will be able to see the current achievements locked or unlocked in the achievements panel. Locked are greyed out.
- Use a list style ui since column grid might get very cramped
- Which image icon belongs to which achievement will be identified with a config json file, it can be in game_config or a separata file.
- For progress icons also show a progress bar showing the progress (e.g. how many days streak currently, how many perfect scores etc)
- Sorting is according to the order of the list below
- Panel will have a scrollable grid with icons and icon labels for achievements
- If I add achievements later, grant achievements based on existing stats, the tracking does not start only once the feature is live.
- Achievements are not per Quiz Type, they are global covering all quiz types
- Progress is stored locally in a local data store, similar to profile data
- New achievements could be added later, be flexible while creating the data structure
- Achivements are as follows:
  EARLY GAME
    First Quiz Completed
    First Perfect Score
    3-Day Streak
  MID GAME
    Lightning Round (Complete a quiz in under 30 seconds)
    Jack of All Trades (Play quizzes from 5 different categories)
    10 Quizzes with 3 Stars
    50 Quizzes Completed
    Brainiac (Get 50 consecutive correct answers spanning quizzez)

  LATE GAME
    30-Day Streak
    50 Perfect Scores
    Flash (Complete a quiz in under 15 seconds)
    World Explorer (Play quizzes from 15 different categories)

    ULTIMATE CHALLENGES
    All Quizzes with 3 Stars
    100-Day Streak
    Get a perfect score in 10 different levels in each quiz type

    As a sample this config can be used or enhanced:
    "achievements": [
    {
      "id": "first_quiz_complete",
      "type": "milestone",
      "title": "First Quiz Completed",
      "description": "Finish your very first quiz!",
      "icon_locked": "icon_first_quiz_grey",
      "icon_unlocked": "icon_first_quiz_color",
      "goal_value": 1,
      "tracking_key": "total_quizzes_completed"
    },
    {
      "id": "brainiac_streak",
      "type": "progress",
      "title": "Brainiac",
      "description": "50 consecutive correct answers.",
      "icon_locked": "icon_brainiac_grey",
      "icon_unlocked": "icon_brainiac_color",
      "goal_value": 50,
      "tracking_key": "current_correct_streak",
      "show_progress_bar": true
    }
    ]

**Issue-9: Friends Page**

Description:
There will be a friends page as a panel and user will be able to free some animals using their diamonds.

Use Case:
- A friends page will be opened from the home screen using the relevant button.
- On the panel there will be a grid of 12 animals. Animal icons will be locked (greyed) in the beginning.
- Animal images (square) will be placed under the assets in the a well named and placed directory.
- The user will be able to free these animals using the collected diamonds.
- Grid animals will be sorted in the grid based on a game configuration in the json. How many diamonds are needed per animal will be added in the same config.
- There will be a popup message when the panel started stating that diamonds are needed to free the animals.
- When an animal is freed there will be an animation of that animal being happy and jumping.

**Issue-10: Settings Page Test Driven Requirements**

FEATURE: Setting Panel Page for Game Settings

AS A user
I WANT TO configure my game preferences (language, music, sound effects)
SO THAT the game experience matches my preferences and persists across sessions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ACCEPTANCE CRITERIA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

** TEST 1 — Happy Path
  GIVEN the user is on the home screen
  WHEN the user presses the settings button
  THEN the settings panel opens showing:
    - Language selection dropdown
    - Music on/off toggle
    - Sound/FX on/off toggle

** TEST 2 — Music Toggle Behavior

GIVEN music is currently ON
WHEN the user turns the Music toggle OFF
THEN background music should stop immediately (if playing)
AND background music should not play during quiz sessions

GIVEN music is currently OFF
WHEN the user turns the Music toggle ON
THEN background music should play during quiz sessions
AND in both cases
    The application state is updated
    The new value is stored in settings state
** TEST 3 — Sound/FX Toggle Behavior

GIVEN Sound/FX is ON
WHEN the user turns the Sound/FX toggle OFF
THEN no sound effects should be played during:
 Correct answer
 Wrong answer
 Button clicks (if applicable)

GIVEN Sound/FX is OFF
WHEN the user turns the Sound/FX toggle ON
THEN sound effects should be played during supported game events
AND
The application state is updated accordingly
Note:
"(what sounds will be played for which activities will be added)"

TEST 4 — Language Selection & Localization

GIVEN the user selects a language from the dropdown
AND the dropdown values are loaded from a configuration JSON file
WHEN a new language is selected
THEN:
 All visible UI labels update to the selected language immediately
 Settings page labels update
 Menu labels update
 Popup messages update
AND:
Localization values are read from configuration (e.g.:
{
"en": { "settings_title": "Settings" },
"fr": { "settings_title": "Paramètres" }
})
AND:
Non-visible resource identifiers (e.g., image file names) are not required to support localization. language change apply immediately

TEST 5 — Settings Persistence

GIVEN the user has modified one or more settings
WHEN the application is fully closed
AND reopened
THEN:
 The previously selected Language is restored
 The previously selected Music state is restored
 The previously selected Sound/FX state is restored
 Settings must be stored in local persistent storage on the device

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ARCHITECTURAL CONSTRAINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Single source of truth (e.g., SettingsState / SettingsProvider)
Settings must be reactive (UI updates instantly)
Localization must be driven from config JSON, not hardcoded
Acceptance criteria = externally observable behavior
Architectural constraints = internal design rules

**Issue-11: Grammar Quiz Page**

Description: There will be a grammar quiz page with multiple choice selections.

Use Cases:

* Grammar Quiz Question Types are as follows, all of them are multi choice:
    - Similar to Vocabulary Page a conversation between two parties will be presented with one verb is empty and the user will try to find the right tense for the verb, or the right auxillary
    - There will be 4 selections with different orders of the words and only one of them is a correct sentence and user will try to find which one.
    - Banked close: where there will be many empty places in the sentence on the middle top of the screen and user will try to find the right choice with all the words in sequence are correct. so the answer will be like (e.g.was/have/asked)
    - (Yes/No): Is the given sentence gramatically correct or not.
    - Which of them are correct: one of the selections is correct for a given context. e.g.
        A) Me and John are going.
        B) John and I are going.
        C) John and me are going.
        D) Me and him are going.
* A quiz can have these questions mixed, so not necessarily only one type. We have to have an object identifying question type and necessary fields for the question. You decide on the ojbect structure but obviously there will be a question type.
* No drag drop questions
* For every question except first one which is similar to vocab quiz and has to chararacters talking, there will be a character on the screen and a speech bubble and the question will be in the bubble. character images will be read from a folder (your choice but don't share with vocabulary folder) under assets and will be randomly selected every time. Images will be not full body length but from hip or chest up.
* Right wrong behaviour is same as vocab or image quiz
* No translation or toggling is needed for grammar
* Rewards and final screen structure is same as other quizzez.
* grammar quiz data follow the same pattern as vocabulary (one JSON file per level)
* except yes/no all questions have have 4 answer options
* Grammar quiz progress be tracked and persisted like other quizzes.
* For yes/no there will be only 2 buttons not 4 buttons with 2 empty.
* Banked cloze: one choice fills ALL blanks at once (not one blank at a time). Each option shows a sequence like "was/have/asked".
* All 5 question types to be built in this issue.
* AI creates sample quiz data JSON files for the existing 2 levels (airport-1, airport-2) with mixed question types.