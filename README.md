# GooseCalc

A lightweight Android calculator written entirely in [Goose](https://github.com/aardappel/goose), with hidden game modes and background music.

[![Build APK](https://img.shields.io/github/actions/workflow/status/tyyuuii/GooseCalc/build.yml?label=Build%20APK)](https://github.com/tyyuuii/GooseCalc/actions/workflows/build.yml)
[![Latest Release](https://img.shields.io/github/v/release/tyyuuii/GooseCalc?label=Latest)](https://github.com/tyyuuii/GooseCalc/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

GooseCalc is an Android calculator built entirely in the Goose systems language, rendered with [rawdrawandroid](https://github.com/cnlohr/rawdrawandroid). It targets **Android 6+ (API 23)** and ships as a single **arm64-v8a** APK, signed v1+v2+v3.

---

## Features

### Calculator
* Working calculator UI with 20 buttons (digits, decimal, `+ - * /`, `=`, `C`, `HIST`)
* Touch input with landscape rotation support — layout recomputes on resize
* Sequential (desk-calculator) arithmetic: `2 + 3 * 4 = 20`, not `14`
* Live expression display while typing (`10 + `)
* Pixel-perfect centered button text
* Scrollable calculation history (`10 + 20 = 30`) overlay
* Auto-shrinking display font so long numbers always fit
* Highlighted pressed button and short click sound
* Native crash reporter (SIGSEGV, SIGABRT, SIGBUS, SIGFPE, SIGILL) writing a readable crash log to external storage — no ADB required
* On-screen crash viewer on relaunch

### Sudoku Game Mode — `69 + 420 / 69 =`
Unlock a 9×9 Sudoku puzzle by entering the cheat code:
**`6 9 + 4 2 0 / 6 9 =`**

* Real puzzle generator with backtracking solver — every puzzle is unique
* Three difficulties: Easy (40 cells), Medium (32 cells), Hard (26 cells)
* Tap cells to select; number buttons 1–9 to fill; `CLR` to clear; `RST` to reset; `EXIT` to return
* Wrong numbers shown in **red**, correct entries in **green**, fixed clues in **white**
* Tap a cell to highlight all matching numbers with a glow effect
* Mistake counter (3 strikes = game over); difficulty dialog reappears after game over
* "You made a mistake!" dialog auto-dismisses after ~1 second
* Square board layout — works in both portrait and landscape

### Fractal Block World (Xar) — `1 0 + 1 6 9 = =`
Unlock a full 6-DOF recursive voxel adventure by entering:
**`1 0 + 1 6 9 = =`** (press `=` twice)

* OpenGL ES 3.0 hardware renderer with VBO chunk meshing and GLSL ES shaders
* Recursive fractal world — Layer 0 (1×) + parent layers 16×, 256×, 4096×
* Animated concentric fractal portals with glowing cores
* Multi-touch mobile controls for landscape orientation
* Left flight stick + right free-look zone
* Combat: FIRE, ALT, USE/F, SHRINK, GROW, TELEKINESIS, MARK
* 10-weapon strip (Plasma → Dark Hole / Quasar Drive)
* Entities & FX: rotating portal rings, voxel monsters, projectiles, railgun beams, explosions, starfield sky dome
* Pause menu: Classic / Genesis / Restart / Exit to Calculator
* Improved map rendering and navigation
* Background music system (minimp3 decoder + embedded BGM)

### UI Editor & Save System
* UI editor for layout customization
* Save/load system for game state and settings

---

## Cheat Codes

| Code | Mode | Notes |
|------|------|-------|
| `6 9 + 4 2 0 / 6 9 =` | Sudoku | First `=` evaluates `69 + 420 / 69` normally; second `=` unlocks Sudoku |
| `1 0 + 1 6 9 = =` | Fractal Block World | First `=` evaluates `10 + 169` normally; second `=` launches FBW in landscape |

---

## Architecture

The project follows a strict, finite structure:

### Goose Files (9)
```
calc_main.goose   →  root module; only file exporting Goose symbols to C
├── calc_draw.goose   →  all rendering (buttons, display, history, crash screen, Sudoku, FBW HUD)
├── calc_dispatch.goose →  Action enum + button table + apply() + cheat-code detection
├── calc_state.goose  →  CalcState machine + evaluate() (sequential ops)
├── calc_format.goose →  f64 → string (fixed-point + scientific notation)
├── calc_history.goose →  ring buffer of "left op right = result" strings
├── calc_layout.goose →  all constants + Rect/Layout/UIState + SudokuGame struct + generator
├── calc_hit.goose    →  pure hit-testing against Layout
└── calc_bridge.goose →  the ONLY file touching ffi; safe i32/u32 wrappers
```

### Fractal Block World Files (5)
```
fbw_core.goose      →  voxel engine, chunk management, fractal logic
fbw_mobile.goose    →  mobile controls, touch input, UI overlays
fbw_bridge.goose    →  FFI boundary between Goose and C for FBW
fbw_gl.c            →  OpenGL ES 3.0 renderer, VBO chunk meshing, shaders
fbw_gl.h            →  GL renderer header
```

### C Files (2)
```
main.c      →  int main() entry point called by rawdrawandroid's android_main glue
              + crash reporter init + C shims + OpenSLES click + music init
crash.c/h   →  signal handler writing crash.log to externalDataPath
```

### Design Principles
* **One FFI boundary.** `calc_bridge.goose` and `fbw_bridge.goose` are the only modules importing `ffi`.
* **Integer-only FFI.** No floats or structs cross the Goose↔C boundary — eliminates ARM64 float/aggregate ABI hazards.
* **Exported symbols only in `calc_main.goose`.** `goose_init`, `goose_draw`, `goose_handle_touch`, `goose_handle_back`, `goose_force_resize`, `goose_exit` are compiled with default visibility.
* **Crash reporter first.** `main.c` installs signal handlers before `goose_init()` and writes to `externalDataPath` (file-manager visible) with an internal fallback.

---

## Build

GooseCalc targets **arm64-v8a (64-bit) only**.

```bash
make \
  NDK=/path/to/ndk \
  BUILD_TOOLS=/path/to/build-tools \
  OS_NAME=linux-x86_64 \
  CC_ARM64=/path/to/aarch64-linux-android-clang \
  ANDROID_JAR=/path/to/android-29/android.jar \
  ANDROID_HOME=/path/to/sdk \
  ANDROIDVERSION=29 \
  ANDROIDTARGET=29 \
  MINSDKVERSION=23 \
  CFLAGS_ARM64="-target aarch64-linux-android29"
```

This produces `goosecalc.apk`. The build requires:
* The Goose compiler (`goose`)
* Android NDK (API 29+)
* Android SDK build-tools (`aapt`, `zipalign`, `apksigner`)

### Example (Termux)
```bash
make NDK=/data/data/com.termux/files/usr \
  BUILD_TOOLS=/data/data/com.termux/files/usr/bin \
  OS_NAME=linux-x86_64 \
  CC_ARM64=/data/data/com.termux/files/usr/bin/aarch64-linux-android-clang \
  ANDROID_JAR=~/Android/Sdk/platforms/android-29/android.jar \
  ANDROID_HOME=~/Android/Sdk \
  ANDROIDVERSION=29 ANDROIDTARGET=29 MINSDKVERSION=23 \
  CFLAGS_ARM64="-target aarch64-linux-android29"
```

CI builds and releases the APK on every version tag via GitHub Actions.

---

## Install

Install the APK on an Android 6+ device:

```bash
adb install -r goosecalc.apk
```

Or transfer the APK via file manager and tap to install (enable "Install unknown apps" for your file manager first).

Crash logs appear at:

```
/storage/emulated/0/Android/data/com.goosecalc.app/files/crash.log
```

---

## Releases

| Version | Highlights | APK |
|---------|-----------|-----|
| v0.4.2 | Background music (minimp3 + embedded BGM) | [Download](https://github.com/tyyuuii/GooseCalc/releases/tag/v0.4.2) |
| v0.4.1 | UI editor, save system, improved map | [Download](https://github.com/tyyuuii/GooseCalc/releases/tag/v0.4.1) |
| v0.4.0 | Fractal Block World map improvements | [Download](https://github.com/tyyuuii/GooseCalc/releases/tag/v0.4.0) |
| v0.3.x | Fractal Block World core, LOD, generation | [Releases](https://github.com/tyyuuii/GooseCalc/releases) |
| v0.2.6 | Sudoku game mode, cheat code `69 + 420 / 69 =` | [Download](https://github.com/tyyuuii/GooseCalc/releases/tag/v0.2.6) |

Full release history: https://github.com/tyyuuii/GooseCalc/releases

---

## License

MIT
