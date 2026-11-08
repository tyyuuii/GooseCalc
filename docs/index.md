# GooseCalc Documentation

GooseCalc is a lightweight Android calculator built with the **Goose systems language** and **rawdrawandroid** (a minimal C framework for Android). It targets Android 10 (API 29) and runs entirely native via `android_native_app_glue`.

## Project Status

**Current version: 0.2.4** — stable, installs and runs on Android 10 devices.

**Known working build:** v0.2.4 — installable APK available for device deployment

## Documentation Index

| Document | Description |
|----------|-------------|
| [Architecture](architecture.md) | Code structure, module layout, import graph |
| [Build System](build.md) | How to compile, sign, and package the APK |
| [Crash Reporter](crash-reporter.md) | Native crash capture, log paths, on-screen viewer |
| [Linker & FFI Quirks](linker-quirks.md) | Goose↔C ABI, symbol visibility, invisible crashes |
| [Calculator Logic](calculator-logic.md) | State machine, expression parsing, display formatting |
| [Installation](installation.md) | Installing on device, troubleshooting |
| [Development](development.md) | Contributing, modifying code, release process |

## Technology Stack

| Component | Technology | Role |
|-----------|------------|------|
| Application logic | **Goose** (systems language) | Calculator UI, state machine, event handling |
| Graphics | **rawdrawandroid** (C) | OpenGL ES rendering, Android NativeActivity glue |
| Font rendering | **font8x8** (bitmap font) | Proportional bitmap text rendering |
| Audio | **OpenSL ES** | Button click sound feedback |
| Crash capture | **C signal handlers** | SIGSEGV/SIGABRT/SIGBUS/SIGFPE/SIGILL |
| Build system | **GNU Make** + **Android NDK** | Cross-compilation for arm64-v8a |
| APK packaging | **rawdrawandroid Makefile** | Zip, align, sign with JAR/v2/v3 schemes |

## Key Design Decisions

- **Single FFI boundary**: Only `calc_bridge.goose` imports `ffi`. All other Goose modules are pure.
- **Only `calc_main.goose` exports functions** to C (`goose_draw`, `goose_handle_touch`, etc.).
- **Integer-only FFI**: Goose f32 has a known ARM64 bug; rectangles use `int` args cast to `float` in C.
- **Crash logs in external storage**: Written to `externalDataPath` so they're visible in any file manager (no ADB required).
- **v1+v2+v3 signing**: All three APK signature schemes for maximum compatibility.
- **No Java/Kotlin**: 100% native C/Goose via `android_native_app_glue`.
