# Installation & Usage

## Installing on Device

### Prerequisites on Android Device

1. **Enable "Install unknown apps"** for your file manager:
   - Settings → Apps → [Your File Manager] → Install unknown apps → **Allow from this source**
2. **Disable Play Protect** (temporarily, if needed):
   - Play Store → Profile → Play Protect → Settings → "Scan apps with Play Protect" → OFF

### Installation Steps

1. Transfer the APK to device storage (e.g. via file manager or ADB):
   ```
   goosecalc-latest.apk
   ```
2. Open your file manager and navigate to the APK
3. Tap the APK to install
4. If prompted, confirm "Install anyway"

### Upgrading

⚠️ **Critical:** The same signing keystore must be used. If you previously installed a version signed with a different key, you must **uninstall first**:
- Settings → Apps → GooseCalc → **Uninstall for all users**

Then install the new APK.

### First Launch

1. Tap the GooseCalc icon
2. Calculator appears with `0` display
3. Tap buttons to calculate
4. Tap "HIST" to view history, "X" to close history panel
5. Tap "C" to clear

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| "App not installed" | Signature conflict with existing install | Uninstall existing GooseCalc first |
| "App not installed" | Play Protect blocking | Disable Play Protect temporarily |
| "Parse error" | Corrupt APK download | Re-download APK |
| App crashes on launch | Missing native symbols | Rebuild with correct keystore and symbols |
| Black screen | Window not ready | Wait, or rotate device to trigger resize |

## Crash Log Access

If the app crashes, the log is written to:
- **File Manager path:** `Android/data/com.goosecalc.app/files/crash.log`
- **Internal path:** app-private data directory

On next launch, an on-screen "CRASH DETECTED" banner shows fault details. Tap "Dismiss" to clear.

## Usage Examples

| Operation | Key Sequence | Display |
|-----------|--------------|---------|
| 2 + 3 | `2`, `+`, `3`, `=` | `5` |
| 10 / 0 | `1`, `0`, `/`, `0`, `=` | `Error` |
| 2 + 3 * 4 | `2`, `+`, `3`, `*`, `4`, `=` | `20` |
| 3.14 + 2 | `3`, `.`, `1`, `4`, `+`, `2`, `=` | `5.14` |
| View history | `HIST` | History panel |
| Close history | Tap `X` | Back to calculator |

## Rotation

Supports landscape and portrait via `screenOrientation="fullSensor"`. Layout auto-recomputes on rotation.
