## High Level Project Use Case and Features

This file lists the issues to be completed for the project.

## Target Users / Personas
Target users is english learners especially kids who are interested in quizzes.


## (Issues) Use Case Flow and Functional Features

**Issue-1: Project Baseline Setup**

-- Description:
Establish the foundational project structure and technical baseline for the portrait-mode mobile application. This includes selecting and agreeing on a technology stack with the developer, and setting up a scalable framework that supports multiple device resolutions—specifically targeting two mobile phone aspect ratios (e.g., 19.5:9 and 16:9) and two tablet aspect ratios (e.g., 4:3 and 16:10). The framework must also accommodate different background images optimized for each resolution group.

-- Goals

Define and document the tech stack in collaboration with the developer.
Set up the project structure to support future feature development.
Implement a resolution-aware system that can load appropriate background assets based on device type and aspect ratio.

-- Acceptance Criteria

Tech stack is selected, documented, and agreed upon by all stakeholders.
The project is initialized and configured for both Android and iOS portrait-mode development.
A resolution-handling mechanism is in place that detects device aspect ratios and serves corresponding background images.
Background image assets are organized and integrated for the four target aspect ratios.
The baseline is verified on representative devices or emulators for each target category.
The project is ready for the team to begin implementing user stories and features.

**Issue-2: Home screen with 4 Buttons**

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