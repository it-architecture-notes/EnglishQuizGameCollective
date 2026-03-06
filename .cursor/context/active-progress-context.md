# Active Progress Context

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
“(what sounds will be played for which activities will be added)”

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
IDENTIFIED GAPS & REMAINING WORK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. **Localization (Hardcoded UI Strings)** — DONE
   - Quiz screens and Levels use localization JSON; generic UI strings (Level complete!, Next, OK, Question X/Y, Back to Levels) are driven from `localization.json`.
   - Optional future: add quiz sub-level titles to localization or level JSON if needed.

2. **Reactive Music Toggling** — DONE
   - Quiz screens use `ref.listen(settingsProvider)`; music resumes when toggled ON during an active quiz session.

3. **Audio Placeholders** — DONE
   - `playCorrect` and `playWrong` use distinct assets from `playClick`.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ARCHITECTURAL CONSTRAINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Single source of truth (e.g., SettingsState / SettingsProvider)
Settings must be reactive (UI updates instantly)
Localization must be driven from config JSON, not hardcoded
Acceptance criteria = externally observable behavior
Architectural constraints = internal design rules