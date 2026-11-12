# Development Guide

## Building from Source

```bash
cd /data/data/com.termux/files/home/GooseCalc

make \
  ANDROID_SDK_ROOT=~/Android/Sdk \
  ANDROID_HOME=~/Android/Sdk \
  ANDROID_NDK_HOME=/data/data/com.termux/files/usr \
  NDK=/data/data/com.termux/files/usr \
  BUILD_TOOLS=/data/data/com.termux/files/usr/bin \
  OS_NAME=linux-x86_64 \
  CC_ARM64=/data/data/com.termux/files/usr/bin/aarch64-linux-android-clang \
  ANDROIDVERSION=29 \
  ANDROIDTARGET=29 \
  MINSDKVERSION=23 \
  CFLAGS_ARM64="-target aarch64-linux-android29"
```

## Adding a New Goose Module

1. Create `src/calc_new.goose`
2. Import it in `calc_main.goose`
3. Follow these rules:
   - **Only `calc_bridge.goose` imports `ffi`**
   - **Only `calc_main.goose` exports functions to C**
   - Keep import graph acyclic
   - Use integer-only types for any FFI boundary

## Modifying the Build

### Changing the APK name
Edit `APPNAME` in `Makefile` and `AndroidManifest.xml.template`.

### Changing the package name
Edit `PACKAGENAME` in `Makefile` and update the manifest template.

### Changing target SDK
Edit `ANDROIDVERSION` and `ANDROIDTARGET` in Makefile or pass via environment.

### Changing minimum SDK
Edit `MINSDKVERSION` in Makefile or pass via environment. Defaults to `23` (Android 6). The compile target (`ANDROIDVERSION`) can stay at `29` (Android 10) — `minSdkVersion` and the compile target are decoupled.

## Signing Key Management

The keystore (`my-release-key.keystore`) must be preserved for all updates.

**To generate a new keystore:**
```bash
keytool -genkey -v -keystore my-release-key.keystore \
  -alias standkey -keyalg RSA -keysize 2048 \
  -sigalg SHA256withRSA -validity 10000 \
  -storepass password -keypass password \
  -dname "CN=goosecalc, OU=GooseCalc, O=GooseCalc, L=Termux, S=Termux, C=US"
```

**Never change the keystore after publishing** — existing installations will fail to update with "App not installed."

## Adding New C Symbols for Goose

1. Add function in `main.c` with `__attribute__((visibility("default")))`
2. Declare `extern fn` in `calc_bridge.goose`
3. Create a safe Goose wrapper in `calc_bridge.goose`
4. Use the wrapper from other Goose modules

## Adding New Drawing Primitives

All drawing goes through CNFG functions accessed via `calc_bridge.goose`:

```goose
// In calc_bridge.goose
extern fn CNFGTackRectangle(x1: f32, y1: f32, x2: f32, y2: f32);
extern fn CNFGTackSegment(x1: i16, y1: i16, x2: i16, y2: i16);
extern fn CNFGColor(rgba: u32);
```

Colors are `0xRRGGBBAA`. Use `CNFGTackRectangle` for filled rects, `CNFGTackSegment` for lines.

## Text Rendering

Goose-side text uses the i32 byte protocol:

```goose
// In calc_bridge.goose
fn draw_text(x: i32, y: i32, s: u8[>..], scale: i32) {
    goose_text_clear();
    for i in 0..s.len {
        let c = s[i];
        if c == 0 { break; }
        goose_text_append(c as i32);
    }
    goose_text_draw(x, y, scale);
}
```

C-side implementation in `main.c` uses `font8x8.h` bitmap font, rendering each glyph as filled rectangles.

## Debugging

### No ADB available
- Crash logs go to file manager: `Android/data/com.goosecalc.app/files/crash.log`
- On-screen crash viewer shows fault details
- No stdout/stderr (removed for release builds)

### With ADB
```bash
adb logcat | grep UnsatisfiedLinkError  # Check for missing symbols
adb install -r goosecalc.apk             # Install via ADB
```

## Release Process

1. Update `VERSION` file (e.g. `0.2.5`)
2. Build APK
3. Copy to device storage (e.g. `goosecalc-latest.apk`)
4. Copy to versioned APK name (e.g. `goosecalc-<version>.apk`)
5. Run `bundle.sh` to regenerate source bundle
6. Test on device before publishing

## Known Issues & Workarounds

| Issue | Workaround |
|-------|-----------|
| Goose f32 FFI bug on ARM64 | Pass integers to C wrapper, cast to float in C |
| No `os` module in Goose | History save/load stubbed (returns empty) |
| No ADB for log viewing | Crash reporter writes to file manager |
| Signature conflict on upgrade | Uninstall first, or use same keystore |
| Back key fires on press AND release | `HandleKey` checks `bDown` — only acts on key down |
| ALooper not drained while `window == NULL` | `CNFGHandleInput()` called before `window == NULL` guard — prevents background→foreground freeze |

## Project Conventions

- Goose files: snake_case (`calc_*.goose`)
- Struct names: PascalCase (`CalcState`, `Layout`, `Rect`)
- Constants: SCREAMING_SNAKE (`MAX_DISPLAY_CHARS`)
- Functions: snake_case (`input_digit`, `format_number`)
- C functions called from Goose: `visibility("default")`
- Goose functions exported to C: `export fn` in `calc_main.goose` only
