# Fractal Block World (Xar) → GooseCalc Android Port Plan

## 1. Objective & Entry Trigger
Port the complete **Fractal Block World (`fbw_core.goose`)** 6-DOF recursive voxel adventure from `tyyuuii/goosebox2` into `tyyuuii/GooseCalc` (Android API 29, `arm64-v8a`, `rawdrawandroid`), upgrading the terminal 240×140 half-block (`▀`) CPU raycaster to a **native 60 FPS OpenGL ES 3.0 hardware renderer** with **automatic horizontal (landscape) lock** and **multi-touch mobile controls**.

- **Secret Launch Sequence:** Typing `1` `0` `+` `1` `6` `9` `=` `=` on the calculator (buttons `[8, 12, 15, 8, 6, 2, 14, 14]`).
  - First `=` evaluates `10 + 169 = 179` normally in calculator history and display.
  - Second `=` immediately switches `g_game_mode = 2`, requests Android **Sensor Landscape (`SCREEN_ORIENTATION_SENSOR_LANDSCAPE = 6`)** via JNI on `NativeActivity`, initializes `fbw_core` + `fbw_gl`, and enters active 3D play with touch controls.
  - Exiting Fractal Block World via `[EXIT]` or the Pause menu restores `g_game_mode = 0` and unlocks orientation (`SCREEN_ORIENTATION_UNSPECIFIED = -1`).
- **Existing Easter Egg Preserved:** `69 + 420 / 69 =` continues to launch the 9×9 Sudoku mode (`g_game_mode = 1`).

---

## 2. Graphics & FPS Upgrade Architecture (Terminal CPU → Mobile GLES 3.0)

| Subsystem | `goosebox2/fbw.goose` (Terminal) | `GooseCalc` Android Port (`fbw_gl.c` + `fbw_mobile.goose`) |
|---|---|---|
| **Resolution** | Capped 240×140 half-block (`▀`) | Full native display resolution (`1920×1080` / `2400×1080`+) |
| **Rendering Pipeline** | Per-pixel CPU 3D DDA raycast every frame | Hardware **OpenGL ES** culled VBO chunk meshing + universal GLSL ES 1.00 shaders (`-lGLESv3`) |
| **Frame Pacing** | Terminal stdout flush bound (~12–25 FPS) | Clamped `CLOCK_MONOTONIC` `dt_ms` (`1..50ms`) targeting **60 FPS** |
| **World Scales** | Layer 0 + 3 parent layers raycast per ray | Layer 0 (`1×`) + Layer 1 (`16×`) + Layer 2 (`256×`) + Layer 3 (`4096×`) hardware Z-buffered geometry |
| **Fractal Portals** | 2D edge ring tint + expensive sub-voxel DDA | Animated concentric fractal portal shader + recessed glowing core geometry |
| **Lighting & Depth** | Flat axis shade + CPU integer fog | 3-axis directional key/fill lighting + per-face AO + deep-depth (`500..2000`) darkening + atmospheric fog + procedural starfield sky dome |
| **Entities & FX** | Disc/pixel splats in `fb_rgb` | 3D rotating portal rings, multi-part voxel monsters with cryo-freeze glow, 3D projectiles, hitscan laser/railgun beams, explosion particles, screen flash |

### Dirty-Flagged Chunk Sync (Zero Per-Frame World Overhead)
- `fbw_core.goose` maintains the authoritative `16×16×16` active chunk (`blocks[4096]`) and up to 3 parent scale chunks (`parent_blocks[12288]`).
- `fbw_mobile.goose` hashes/tracks chunk transitions (`depth`, `px/py/pz` parent coordinates, `delta_head`, and active block count). Only when a chunk changes (shrink/grow/chunk-border/block-break) does Goose push 1024 `u32` packed words (4 `u8` block IDs per `i32`) per dirty layer to `fbw_gl.c`.
- During normal 60 FPS flight and combat, **zero chunk bytes cross FFI**—only the 6-DOF camera (in fixed-point milli-units), active entities, shots, particles, and hitscan beam cross per frame.

### Clean GLES ↔ `CNFGOGL` State Handshake
`rawdrawandroid` (`CNFGEGLDriver.c` + `CNFGOGL.c`) creates an EGL context (`EGL_OPENGL_ES3_BIT` renderable config at `ANDROIDVERSION=29` with `EGL_CONTEXT_CLIENT_VERSION=2`) and uses VAO 0 + client-side attribute arrays `0` and `1` for 2D UI (`CNFGTackRectangle`, `CNFGTackSegment`, `goose_text_draw`). Using GLSL ES 1.00 shaders with explicit `glBindAttribLocation` in `fbw_gl.c` guarantees 100% shader compilation across both ES 2.0 and ES 3.0 mobile GPU drivers.
`fbw_gl_render_3d()` renders the 3D scene first, then cleanly restores:
```c
glDisableVertexAttribArray(2);
glBindBuffer(GL_ARRAY_BUFFER, 0);
glDisable(GL_DEPTH_TEST);
glDepthMask(GL_FALSE);
glDisable(GL_CULL_FACE);
glEnable(GL_BLEND);
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
glUseProgram(0);
```
so `CNFG` 2D HUD and touch overlays composite on top with zero state corruption.

---

## 3. Mobile Multi-Touch Control Scheme (Horizontal Landscape)

`CNFGEGLDriver.c` delivers simultaneous multi-touch pointer IDs (`pid` 0..9) through `HandleButton(x, y, pid, bDown)` and `HandleMotion(x, y, pid)`. `main.c` forwards all pointer down/move/up events to `goose_handle_pointer(x, y, pid, event_type)`.

```
┌───────────────────────────────────────────────────────────────────────────┐
│ [HP 100 | ARM 50 | G 120 | K 1]  YING FOREST LVL:1 (8,4,9)   [MAP][F1-F5]│
│                                                           [RKT][TRU][II]  │
│  [Q] [E]  [UP]                                       [USE/F]  [SHRINK/B]  │
│           [DN]                  ( + )                  [GROW/V]   [TK]    │
│   ╭─────────╮   [BRK]                                 ╭───────╮  ╭─────╮  │
│   │  FLIGHT │                 LOOK ZONE               │ FIRE  │  │ ALT │  │
│   │  STICK  │            (Right-Half Drag)            │       │  │     │  │
│   ╰─────────╯                                         ╰───────╯  ╰─────╯  │
│  [1:PLS][2:CAN][3:LSR][4:RKT][5:HOM][6:MNG][7:RAL][8:EMP][9:NUK][0:DRK]   │
└───────────────────────────────────────────────────────────────────────────┘
```

- **Left Thumb (Flight Stick + Vertical/Roll Cluster):**
  - Anchored circular thumbpad (`px, py` drag delta) applies continuous camera-relative forward/back/strafe thrust (`apply_thrust`).
  - Dedicated perimeter pads for `UP` (`+Y`), `DN` (`-Y`), `BRK` (inertia brake), and `Q` / `E` (3D camera roll).
- **Right Thumb (Free-Look Zone + Combat/Fractal Actions):**
  - Dragging anywhere on the open right playfield rotates `yaw` and `pitch` smoothly (`1:1` touch sensitivity).
  - Large ergonomic `FIRE` (primary) and `ALT` (secondary) thumb buttons + `USE/F` (stations/tomes/rings/pickups), `SHK/B` (shrink targeted block `16×`), `GRW/V` (grow outward `16×`), `TK` (telekinesis), and `MRK` (drop short/long marker).
- **Bottom 10-Weapon Strip & Top Quick Bar:**
  - Single-tap switching across all 10 Xar weapons (`Plasma` → `Dark Hole / Quasar Drive`) with live ammo counts and lock state.
  - Touch-interactive modals for **Buy Station**, **Sell Station**, **Black Market**, **Lore Tome**, **Guides (`F1..F5` + Marker Warp)**, **Pause (Classic / Genesis / Restart / Exit to Calc)**, and **Victory**.

---

## 4. `UnsatisfiedLinkError` & ARM64 ABI Prevention

1. **Integer-Only FFI Boundary:** Every `extern fn` in `calc_bridge.goose` and `fbw_bridge.goose` passes strictly `i32` / `u32` (positions in milli-units `mm`, angles in milliradians `mrad`, 4×`u8` packed chunk quads). Zero `f32`, `f64`, slices, or structs cross Goose ↔ C, eliminating the ARM64 float/aggregate ABI hazard.
2. **Default Visibility on All Bridge Symbols:** `Makefile` uses `-fvisibility=hidden` for C files. Every C symbol imported by Goose carries `__attribute__((visibility("default")))`, and every Goose entrypoint called by C is declared with `export fn` in `src/calc_main.goose` (`goose_handle_touch`, `goose_handle_pointer`, `goose_draw`, `goose_handle_back`, `goose_force_resize`) alongside Goose's runtime-generated `goose_init` and `goose_exit`.
3. **Complete `SRC` Linkage in `Makefile`:** `SRC := main.c crash.c fbw_gl.c` ensures `fbw_gl.o` is compiled into `$(ANDROIDSRCS)` and linked into `makecapk/lib/arm64-v8a/libgoosecalc.so` together with `$(GOOSE_O)` (`calc_main.o`).
4. **NativeActivity Entrypoint Preserved:** `rawdrawandroid/Makefile` links `-shared -uANativeActivity_onCreate -lm -lGLESv3 -lEGL -landroid -llog -lOpenSLES`.
5. **Exception-Safe JNI Orientation Switching:** `fbw_set_orientation(int landscape)` attaches via `gapp->activity->vm`, checks every `jclass` / `jmethodID` for `NULL`, clears any pending JNI exception (`ExceptionCheck` / `ExceptionClear`), and never references external Java classes (`android:hasCode="false"`).
6. **Pre-Release Symbol Verification:**
   - `nm -u libgoosecalc.so` confirms zero undefined non-system symbols.
   - `nm -D libgoosecalc.so | grep -E "goose_|ANativeActivity_onCreate"` confirms all runtime & `NativeActivity` exports are present.
