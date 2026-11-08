# Linker & FFI Quirks: Goose ↔ rawdrawandroid C

This document explains how the C and Goose halves of GooseCalc link together, the main ABI/linker quirks, and why some crashes are invisible without full Android logcat output.

---

## 1. How Linking Works

### The two-language boundary

GooseCalc is split across two language worlds:

| Side | Language | Responsibility |
|------|----------|----------------|
| **Goose** | Goose systems language | Calculator UI, state machine, event handling, formatting |
| **C** | C (via rawdrawandroid) | Android NativeActivity glue, OpenGL ES rendering (CNFG), crash reporter, OpenSL ES audio |

They meet at a **single FFI boundary**: only `calc_bridge.goose` imports `ffi`, and only `calc_main.goose` exports functions to C.

### The build pipeline

```
src/calc_main.goose  ──goose -o calc_main.c──>  calc_main.c
calc_main.c          ──clang -c───────────────>  calc_main.o
main.c crash.c       ──clang -c───────────────>  main.o crash.o
calc_main.o + main.o + crash.o  ──clang──>  libgoosecalc.so
libgoosecalc.so      ───>  packaged into APK (makecapk/lib/arm64-v8a/)
```

### What `goose` generates

Running `goose --standalone --header calc_main.h -o calc_main.c src/calc_main.goose` produces:

1. **`calc_main.c`** — C translation of all Goose code, including:
   - Generated struct types (`CalcState_g`, `Layout_g`, `History_g`, etc.) with `gs_*` scalar typedefs
   - Exported function prototypes bound with `__attribute__((visibility("default")))` so they're visible to the C linker
   - Internal Goose functions with hidden visibility (not callable from C)

2. **`calc_main.h`** — C header declaring the exported Goose functions:
   ```c
   void goose_init(int argc, char **argv);
   void goose_exit(void);
   gs_i32 goose_handle_touch(gs_i32, gs_i32, gs_i32);
   void goose_draw(void);
   gs_i32 goose_handle_back(void);
   void goose_force_resize(void);
   ```

### The C host (main.c)

`main.c` is the entry point called by rawdrawandroid's `android_main` glue (`ANativeActivity_onCreate`). It:
1. Installs crash signal handlers
2. Calls `goose_init(argc, argv)` to start the Goose runtime
3. Enters the render loop: `CNFGHandleInput()` → `goose_draw()` → `CNFGSwapBuffers()`
4. On exit, calls `crash_clear()` and `goose_exit()`

---

## 2. Main ABI / Linker Quirks

### Quirk 1: `-fvisibility=hidden` hides Goose exports

The Makefile compiles with `-fvisibility=hidden`. Without `__attribute__((visibility("default")))` on every C function that Goose calls, the linker drops those symbols from `libgoosecalc.so`. Goose's `extern fn` declarations then resolve to `NULL` at runtime → immediate crash on first touch/draw.

**Fix applied:** All C accessors in `main.c` use `__attribute__((visibility("default")))`:
```c
__attribute__((visibility("default"))) int get_CNFGPenX(void) { ... }
```

### Quirk 2: Goose `export fn` must be linked into the SAME `.so`

Goose compiles `calc_main.goose` → `calc_main.c` → `calc_main.o`. This object must be linked into `libgoosecalc.so` alongside `main.c` and `crash.c`. If the Goose object is omitted or linked into a different shared library, C can't find `goose_draw`, `goose_handle_touch`, etc. → `UnsatisfiedLinkError` at app launch.

**Fix applied:** The Makefile override links `calc_main.o` directly into `$(TARGETS)`:
```make
$(TARGETS) : $(ANDROIDSRCS) $(CNFGSRCS) $(GOOSE_O)
	$(CC_ARM64) ... -o $@ $(filter-out $(GOOSE_C),$(ANDROIDSRCS)) $(CNFGSRCS) $(GOOSE_O) ...
```

### Quirk 3: `ANativeActivity_onCreate` must be defined

Android's `NativeActivity` looks for `ANativeActivity_onCreate` in the app's native library. rawdrawandroid's `android_native_app_glue.c` provides this symbol. If it's missing (wrong build target, wrong `.so`), the app crashes instantly with:

```
java.lang.UnsatisfiedLinkError: Unable to load native library
undefined symbol: ANativeActivity_onCreate
```

This crash happens **before any Goose code runs** — there's no stack trace, no Goose frame, nothing in the crash reporter.

### Quirk 4: ARM64 f32 ABI hazard

Goose's `f32` type doesn't reliably cross the FFI boundary on ARM64. Float arguments can land in the wrong registers or be widened/truncated unexpectedly between the Goose calling convention and C's.

**Fix applied:** `calc_bridge.goose` uses **integer-only FFI**. `goose_draw_rect` takes `i32` args; `main.c` casts them to `float` for `CNFGTackRectangle`:
```c
void goose_draw_rect(int x1, int y1, int x2, int y2) {
    CNFGTackRectangle((float)x1, (float)y2, (float)x2, (float)y2);
}
```

Text drawing uses a byte-by-byte `i32` protocol (`goose_text_append(c)`) — no pointers or slices cross the boundary.

### Quirk 5: Goose struct layout in C header

`calc_main.h` defines Goose structs with C-compatible layouts (`gs_i32`, `gs_f64`, packed structs via `#pragma pack(push, 1)`). Any change to a Goose struct field order or type changes the C layout. If `calc_main.h` is not regenerated after editing `calc_main.goose`, C reads/wrong offsets → silent memory corruption.

**Rule:** Always regenerate `calc_main.h` and `calc_main.c` together after editing any Goose file imported by `calc_main.goose`.

### Quirk 6: No debug symbols = invisible crashes

Release builds strip symbol tables from `.so` files. When a native crash occurs:
- Android shows "Process: com.goosecalc.app, PID: ####"
- No Java stack trace (it's native code)
- No source file/line info without unstripped symbols + `addr2line`
- The crash reporter captures fault address, PC, LR, SP — but **not** a full backtrace

**Workaround:** The crash reporter writes `signal:`, `fault:`, `pc:`, `lr:`, `sp:` hex values. To decode them, you need the unstripped `.so` and `aarch64-linux-android-addr2line`.

---

## 3. Why Some Crashes Can't Be Detected Without Full Android Logs

### Categories of invisible crashes

| Crash Type | What You See | What You're Missing |
|------------|--------------|---------------------|
| **Installer rejection** | "App not installed" / "Parse error" | Exact reason (signature conflict, minSdk mismatch, corrupt ZIP, missing permissions) |
| **NativeActivity load failure** | App closes instantly | `ANativeActivity_onCreate` missing, wrong `.so` architecture, missing dependencies |
| **Goose FFI symbol missing** | Crashes on first touch/draw | Which `extern fn` resolved to NULL, whether `calc_main.o` was linked |
| **Native segfault in CNFG** | "Process: com.goosecalc.app" | Faulting instruction, register state, which C function was executing |
| **Stack overflow** | Silent process death | Stack depth, which recursion triggered it |
| **Memory exhaustion** | Process killed by OOM killer | Available memory, other apps' memory usage |

### What the crash reporter captures (limited)

The signal handler in `crash.c` writes:
```
signal: SIGSEGV
fault: 0x0000000000000000
pc:    0x0000007f8a123456
lr:    0x0000007f8a123400
sp:    0x0000007fffd00000
```

This tells you **what** faulted and **where** (PC), but not:
- Which C function contained `pc` (needs `addr2line` + unstripped `.so`)
- What Goose function called into C (no Goose frame info in native signal context)
- What led to the fault (no call stack)
- Whether it was a null deref, out-of-bounds access, or alignment fault

### What `adb logcat` reveals (without it, you're blind)

```
E/AndroidRuntime: FATAL EXCEPTION: main
E/AndroidRuntime: Process: com.goosecalc.app, PID: 12345
E/AndroidRuntime: java.lang.UnsatisfiedLinkError: ...
E/AndroidRuntime:    at android.app.NativeActivity.onCreate(NativeActivity.java)
E/libc: Fatal signal 11 (SIGSEGV), code 1, fault addr 0x0 in pid 12345
E/DEBUG: backtrace:
E/DEBUG:     #00 pc 0000000000012345  /system/lib/libc.so
E/DEBUG:     #01 pc 0000000000067890  /data/app/com.goosecalc.app/lib/arm64/libgoosecalc.so
```

Without logcat:
- You don't know if it's a **signature conflict** (installer), **missing symbol** (loader), or **native segfault** (runtime)
- You can't distinguish "app won't install" from "app installs but crashes on launch"
- You can't see if the crash is in rawdrawandroid's EGL setup, Goose's runtime, or your own C code

### The "silent uninstall" problem

On Android 10, if an APK fails signature verification, the package installer simply says **"App not installed"** with no details. There's no log entry, no crash report, nothing the app can write — because the app was never loaded. The only way to diagnose:
1. `adb logcat` during install attempt
2. `adb install -r goosecalc.apk` to see the exact error
3. `apksigner verify --verbose goosecalc.apk` to confirm signature validity on the build machine

---

## 4. Debugging Checklist

When GooseCalc won't install or crashes on launch:

```
□ apksigner verify --verbose goosecalc.apk          # Is the APK signed correctly?
□ unzip -l goosecalc.apk | grep "\.so"              # Is libgoosecalc.so present?
□ nm -D libgoosecalc.so | grep " T goose_"          # Are Goose exports visible?
□ nm -D libgoosecalc.so | grep "ANativeActivity"    # Is the NativeActivity entry present?
□ adb install -r goosecalc.apk                      # What does the installer say?
□ adb logcat | grep -i goosecalc                    # Any native crash traces?
□ cat /data/data/com.goosecalc.app/files/crash.log   # Did the crash reporter fire?
□ File manager → Android/data/com.goosecalc.app/files/ # Is crash.log visible?
```

### If the app installs but crashes immediately:
The crash reporter should have caught it. Check `crash.log` in the file manager. If `crash.log` doesn't exist, the crash happened **before** `crash_reporter_init()` ran — likely during `ANativeActivity_onCreate` or `goose_init()`. You need `adb logcat`.

### If the app won't install at all:
The crash reporter can't help — the app never ran. Check signature validity, keystore consistency with previous installs, and `adb install` output.

---

## 5. Summary of Fixes Applied in GooseCalc

| Issue | Fix |
|-------|-----|
| `-fvisibility=hidden` hiding Goose exports | `__attribute__((visibility("default")))` on all C accessors |
| `calc_main.o` not linked into `.so` | Makefile override links `$(GOOSE_O)` into `$(TARGETS)` |
| ARM64 f32 FFI bug | Integer-only FFI: `i32` args cast to `float` in C |
| `ANativeActivity_onCreate` missing | rawdrawandroid's `android_native_app_glue.c` provides it |
| Crashes invisible without logcat | Signal handler writes fault/PC/LR/SP to `crash.log` in external storage |
| Install rejection gives no reason | `adb install -r` + `apksigner verify` for diagnosis |
| Back key kills app on release | `HandleKey` checks `bDown` — acts only on key down |
| Background→foreground freeze | `CNFGHandleInput()` called before `window == NULL` guard — always drains ALooper |
