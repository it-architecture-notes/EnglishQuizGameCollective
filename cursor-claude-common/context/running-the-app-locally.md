# Running the App Locally

`app/` is the Flutter project root — run every command below from inside `app/`, not the repo root.

## Chrome (web, with DevTools inspector open)

```bash
cd app
flutter run -d chrome --web-browser-flag "--auto-open-devtools-for-tabs"
```

This launches the app in Chrome and automatically opens Chrome DevTools (inspect mode) for that tab, so you get the browser's Elements/Console/Network panels alongside the running app.

If you only want the app running in Chrome without forcing DevTools open (and prefer to open inspect manually via right-click → Inspect, or `Cmd+Option+I`):

```bash
flutter run -d chrome
```

**Flutter's own DevTools** (widget tree, performance, layout explorer — separate from Chrome's native inspector) are available either way once the app is running: the terminal output prints a DevTools URL, or run:

```bash
dart devtools
```

**Useful hot-reload/restart keys while `flutter run` is active:**
- `r` — hot reload
- `R` — hot restart
- `q` — quit

**Confirm Chrome is available as a target first:**

```bash
flutter devices
```

Chrome should appear as `Chrome (web) • chrome • web-javascript`. If it's missing, ensure Google Chrome is installed and `flutter config --enable-web` has been run once (usually on by default).

## Android device

### 0. One-time machine setup: Android SDK (command-line only, no Android Studio)

If `flutter doctor` reports "Unable to locate Android SDK", you don't need the full Android Studio
GUI — the command-line tools are enough to build/run/install:

```bash
brew install --cask android-commandlinetools
brew install openjdk@17

flutter config --android-sdk /opt/homebrew/share/android-commandlinetools
flutter config --jdk-dir /opt/homebrew/opt/openjdk@17

export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" \
  "platform-tools" "platforms;android-36" "build-tools;28.0.3"

flutter doctor --android-licenses   # accept all with 'y'
flutter doctor                      # confirm Android toolchain shows ✓
```

Notes:
- `platforms;android-36` / `build-tools;28.0.3` are what this Flutter version (3.41.2) currently
  requires — if `flutter doctor -v` asks for different versions, install those instead.
- `openjdk@17` from Homebrew is keg-only (not symlinked into `/opt/homebrew` automatically); pointing
  Flutter at it directly via `flutter config --jdk-dir` avoids needing a `sudo` symlink step.

### 1. Enable Developer Options + USB debugging on the device
- Settings → About phone → tap "Build number" 7 times to unlock Developer Options.
- Settings → Developer options → enable **USB debugging**.

### 2. Connect the device and verify it's detected
```bash
cd app
flutter devices
```
The device should show up (e.g. `Pixel 7 (mobile) • <device-id> • android-arm64 • Android 14`). If not:
- Check the USB cable supports data transfer (not charge-only).
- Accept the "Allow USB debugging?" prompt on the device screen.
- Run `flutter doctor` to confirm the Android toolchain is set up.

### 3. Run directly on the device (debug build, hot reload works)
```bash
flutter run -d <device-id>
```
Omit `-d <device-id>` if it's the only device connected.

### 4. Build and install a release APK instead (no hot reload, closer to production)
```bash
flutter build apk --release
flutter install -d <device-id>
```
The built APK lands at `app/build/app/outputs/flutter-apk/app-release.apk` — it can also be sideloaded manually (`adb install app-release.apk`) or shared for testing without a USB connection.

### App identifiers
- **Android application ID:** `com.englishquiz.english_quiz_game` (`app/android/app/build.gradle.kts`)
- **Package name:** `english_quiz_game` (`app/pubspec.yaml`)

### Wireless debugging (optional, no cable needed after initial pairing)
```bash
flutter devices  # will also search for wireless devices already paired
```
Pairing a device wirelessly for the first time still requires `adb pair <ip>:<port>` (from the device's Developer Options → Wireless debugging → Pair device with pairing code) before `flutter run` will see it over Wi-Fi.
