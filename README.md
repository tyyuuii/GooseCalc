# GooseCalc

A very lightweight calculator written in Goose.

[![Build APK](https://github.com/YOUR_USERNAME/GooseCalc/actions/workflows/build.yml/badge.svg)](https://github.com/YOUR_USERNAME/GooseCalc/actions/workflows/build.yml)

GooseCalc is an Android calculator built entirely in the [Goose](https://github.com/aardappel/goose) systems language, rendered with [rawdrawandroid](https://github.com/cnlohr/rawdrawandroid). It targets **Android 10 (API 29)** and ships as a single **arm64-v8a** APK.

## What it does

* Launches a working calculator UI with 20 buttons (digits, decimal, `+ - * /`, `=`, `C`, `HIST`)
* Handles touch input and landscape rotation (layout recomputes on resize)
* Performs sequential (desk-calculator) arithmetic: `2 + 3 * 4 = 20`, not `14`
* Shows a live expression while typing (`10 + `) and centers button text pixel-perfectly
* Maintains a calculation history (`10 + 20 = 30`) in a scrollable overlay
* Auto-shrinks the display font so long numbers always fit
* Highlights the pressed button and plays a short click sound
* Catches native crashes (SIGSEGV, SIGABRT, SIGBUS, SIGFPE, SIGILL) and writes a readable crash log to **external storage** so you can retrieve it with any file manager — no ADB required
* Shows an on-screen crash viewer on relaunch that you tap to dismiss
* **Sudoku game mode** — enter `69 + 420 / 69 =` on the calculator to unlock a 9×9 Sudoku puzzle. Tap cells to select, use number buttons 1–9 to fill, `CLR` to clear, `RST` to reset, `EXIT` to return to calculator

## Architecture

The project follows a strict, finite structure: exactly **9 Goose files + 2 C files**, one acyclic dependency graph, and a single FFI boundary.

```
calc_main.goose   →  root module; only file exporting Goose symbols to C
├── calc_draw.goose   →  all rendering (buttons, display, history, crash screen)
├── calc_dispatch.goose →  Action enum + button table + apply()
├── calc_state.goose  →  CalcState machine + evaluate() (sequential ops)
├── calc_format.goose →  f64 → string (fixed-point + scientific notation)
├── calc_history.goose →  ring buffer of "left op right = result" strings
├── calc_layout.goose →  all constants + Rect/Layout/UIState + compute(w,h)
├── calc_hit.goose    →  pure hit-testing against Layout
└── calc_bridge.goose →  the ONLY file touching ffi; safe i32/u32 wrappers
```

```
main.c      →  int main() entry point called by rawdrawandroid's android_main glue
              + crash reporter init + C shims (draw_rect, text, sound) + OpenSLES click
crash.c/h   →  signal handler writing crash.log to externalDataPath
```

### Why this structure

* **One FFI boundary.** `calc_bridge.goose` is the only module importing `ffi`. No other Goose file talks to C, keeping the C/Goose interface small and auditable.
* **Integer-only FFI.** Strings never cross the boundary as pointers/slices. Goose appends bytes one at a time via `goose_text_append(c)`, and C draws them with `CNFGDrawText`. This avoids the ARM64 float-pointer ABI hazard entirely.
* **Exported symbols only in `calc_main.goose`.** `goose_init`, `goose_draw`, `goose_handle_touch`, `goose_handle_back`, `goose_force_resize`, `goose_exit` are compiled with default visibility so the C entry point can bind them directly.
* **Crash reporter first.** `main.c` installs signal handlers before `goose_init()`, reads any previous crash log before truncating it, and writes to `externalDataPath` (file-manager visible) with an internal fallback.

## Build

GooseCalc targets **arm64-v8a (64-bit) only**.

```bash
make
```

This produces `goosecalc.apk`. The build requires:
* The Goose compiler (`goose`)
* Android NDK (API 29)
* Android SDK build-tools (`aapt`, `zipalign`, `apksigner`)

CI builds and releases the APK on every version tag via GitHub Actions.

## Install

Install the APK on an Android 10+ device:

```bash
adb install -r goosecalc.apk
```

Or transfer the APK via file manager and tap to install (enable "Install unknown apps" for your file manager first).

Crash logs appear at:

```
/storage/emulated/0/Android/data/com.goosecalc.app/files/crash.log
```

## License

MIT
