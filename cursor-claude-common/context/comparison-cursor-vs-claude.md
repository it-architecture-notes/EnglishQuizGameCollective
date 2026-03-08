# Comparison: EnglishQuizGameWCursor vs EnglishQuizGameWClaude

## Summary

| Area | Cursor (this project) | Claude (other) | Best / Notes |
|------|----------------------|----------------|--------------|
| **Streak** | Global in `ProfileState` (lastPlayedDay, currentStreak) | Per quiz type in `QuizTypeProgress`; "global" = max of types | **Cursor** matches requirement (global streak). |
| **Level progression** | Ordinal index, 10-level horizon, scroll-to-index, lock/unlock | levelNumber from JSON, simple unlocked set, no horizon | **Cursor** has Issue-7 progression; Claude does not. |
| **Achievements** | Config-driven (phase), progress computed on open; overlay panel | Defs + persisted unlock states; full-screen; tier in config | Cursor: no persisted unlock state. Claude: tier + checkAndGrant. |
| **Quiz progress** | levels + totalDiamonds; time/streak in Profile/AchievementState | levels + totalDiamonds + totalQuestionsAnswered + currentStreak + lastPlayedDay + categoriesPlayed; LevelProgress has fastestTimeMs | Claude richer per-type; Cursor keeps streak/time global. |
| **Test data** | Settings panel, 3 buttons (trophy, 3-day, 30-day) | kDebugMode floating panel; Seed A/B + Clear | **Claude**: debug-only + Clear. **Cursor**: add guard + Clear. |
| **Trophies entry** | Overlay (showPanelOverlay) | Push full-screen AchievementsScreen | Preference; Cursor keeps overlay. |

---

## Differences that affect correctness

### 1. Streak (Cursor correct vs Claude)

- **Cursor:** One global `lastPlayedDay` and `currentStreak` in `ProfileState`. Completing any quiz type with ≥1 star updates the same streak.
- **Claude:** Each `QuizTypeProgress` has its own `currentStreak` and `lastPlayedDay`. Achievements use `global_daily_streak = max(currentStreak)` across types. So streak is per quiz type, not truly global.

**Verdict:** Cursor aligns with “global streak” requirement. Claude’s design would need to be changed if the same requirement applies there (we do not change Claude’s code).

### 2. Bug in Cursor test data (fixed in this repo)

- In `test_data_service.dart`, `seedStreakTestData3Day()` set `currentStreak: 12` instead of `2`, so “play one level today → 3-day” would not test correctly. Fixed to `currentStreak: 2`.

---

## Claude’s code – potential issues (for reference only; we do not change that repo)

1. **Per-type streak:** As above; if the product requirement is global streak, Claude’s logic is inconsistent.
2. **TestDataSeeder image stars:** Scenario A/B seed image progress with `stars: 2` for all 20 levels. So no “perfect” (3-star) from image; first perfect and ten_perfect come from vocab/grammar only. Likely intentional for mixed state, but worth being aware of.
3. **Level progression:** No ordinal index or horizon; uses `levelNumber` from JSON. If levelNumbers repeat or ordering matters, Cursor’s ordinal-based approach is safer.

---

## Alignments applied in Cursor (this project only)

1. **Fix 3-day streak seed:** `seedStreakTestData3Day()` now sets `currentStreak: 2` (was 12).
2. **Debug-only test section:** The “Issue-8 test data” block in Settings is shown only when `kDebugMode` is true, so release builds don’t expose test buttons (matching Claude’s idea).
3. **Clear test data:** A “Clear test data” button clears the same data we seed (quiz progress image/vocabulary/grammar, achievement state, profile streak) so you can re-run tests from a clean state.

No changes were made to the Claude project.
