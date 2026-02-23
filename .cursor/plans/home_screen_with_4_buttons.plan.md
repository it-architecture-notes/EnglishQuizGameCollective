# Plan: Issue-2 — Home screen with 4 Buttons

## Acceptance criteria: Home background assets (aligned)

Use **four aspect-ratio folders** so different background images can be used for tall phones, wide phones, and two tablet ratios. Each folder holds the background asset(s) for that bucket.

**Asset folder structure:**

```
assets/images/backgrounds/
├── phone_tall/     ← 1080×2400 (tall phones, e.g. 19.5:9 / 20:9)
│   └── background.png   (or .jpg)
├── phone_wide/     ← 1080×1920 (16:9 phones)
│   └── background.png   (or .jpg)
├── tablet_43/      ← 4:3 tablets
│   └── background.png   (or .jpg)
└── tablet_1610/    ← 16:10 tablets
    └── background.png   (or .jpg)
```

- **Resolution-aware loading:** The app chooses the folder from the device’s aspect ratio using [app/lib/services/resolution_service.dart](app/lib/services/resolution_service.dart) (`resolutionBucketFromSize` → `ResolutionBucket` → `assetPath` → `phone_tall` | `phone_wide` | `tablet_43` | `tablet_1610`). Each folder can contain a **different** background image suited to that aspect ratio.
- **Image widget:** Build the path from the current bucket and load it:
  - `final path = 'assets/images/backgrounds/${bucket.assetPath}/background.png';`
  - `Image.asset(path, fit: BoxFit.cover)`
- **pubspec.yaml:** Declare all four background directories under `flutter: assets:` (already present in baseline): `assets/images/backgrounds/phone_tall/`, `phone_wide/`, `tablet_43/`, `tablet_1610/`.

**Optional density variants:** Inside each folder you can add Flutter density subfolders (e.g. `2.0x/background.png`, `3.0x/background.png`) so Flutter picks by device pixel ratio within that bucket; the plan does not require this for Issue-2.

---

## Rest of plan

### Current state

- [app/lib/main.dart](app/lib/main.dart): `HomeScreen` already uses a Stack with bucket-based `background.png` and `resolutionBucketFromSize`. For Issue-2, keep this approach; add SafeArea, precache, quiz buttons, and bottom nav.
- [app/lib/services/resolution_service.dart](app/lib/services/resolution_service.dart): Used for both (1) selecting the background folder and (2) phone vs tablet layout (Column vs 2-column Grid for quiz buttons).

### 1. Layout and visuals

- **SafeArea:** Wrap the entire Home screen content in `SafeArea`.
- **Background:** Stack with bucket-based path `assets/images/backgrounds/${bucket.assetPath}/background.png` (or `.jpg`), `BoxFit.cover`. Precache this asset (e.g. in StatefulWidget) to avoid flicker.

### 2. Main quiz buttons (center)

- **Adaptive layout:** Use `resolutionBucketFromSize` or `MediaQuery` to choose phone vs tablet. Phone: center Column of three large buttons. Tablet: center 2-column Grid.
- **Buttons:** Three large ElevatedButtons: Image Quiz, Vocabulary, Grammar. Minimum 48 dp touch targets.
- **Actions:** Navigate to placeholder level-selection screens.

### 3. Bottom dashboard nav

- Fixed bottom Container with Row and `MainAxisAlignment.spaceEvenly`.
- Four IconButtons (min 48x48): Profile (Me), Trophies (Achievements), Friends (heart), Settings (gear). Each navigates to its placeholder screen.

### 4. Placeholder screens

- Level selection placeholder (reused for Image Quiz, Vocabulary, Grammar).
- Profile, Achievements, Friends, Settings placeholders (each with AppBar and back).

### 5. File and code changes summary

| Item | Action |
|------|--------|
| **Asset structure** | Four folders under `assets/images/backgrounds/`: `phone_tall/`, `phone_wide/`, `tablet_43/`, `tablet_1610/`. Each contains a background image (e.g. `background.png` or `background.jpg`) for 1080×2400, 1080×1920, 4:3, and 16:10 respectively. |
| **pubspec.yaml** | Keep existing declarations: `assets/images/backgrounds/phone_tall/`, `phone_wide/`, `tablet_43/`, `tablet_1610/`. |
| **Home screen** | Use bucket-based path `assets/images/backgrounds/${bucket.assetPath}/background.png` for background; keep Stack, add SafeArea, precache, adaptive quiz buttons, bottom nav. |
| **lib/screens/** | Extract HomeScreen; add placeholder screens; wire navigation. |

### 6. Acceptance criteria mapping

- **Asset folders:** `assets/images/backgrounds/` with `phone_tall/`, `phone_wide/`, `tablet_43/`, `tablet_1610/`, each with its own background image (e.g. for 1080×2400, 1080×1920, 4:3, 16:10).
- **Resolution-aware loading:** Select folder by device aspect ratio via `resolutionBucketFromSize` and `bucket.assetPath`.
- **Image declaration:** pubspec.yaml already lists the four background directories.
- **Image widget:** `Image.asset('assets/images/backgrounds/${bucket.assetPath}/background.png')` (or `.jpg`) with `BoxFit.cover`.
- **Layout:** SafeArea, adaptive quiz buttons, bottom nav, 48 dp targets, precache, placeholders.
