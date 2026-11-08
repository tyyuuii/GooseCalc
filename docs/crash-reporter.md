# Crash Reporter

GooseCalc includes a native crash reporter that captures signals, writes diagnostic logs to device storage, and displays an on-screen crash viewer on the next launch — all without requiring ADB.

## Overview

| Feature | Implementation |
|---------|---------------|
| Captured signals | `SIGSEGV`, `SIGABRT`, `SIGBUS`, `SIGFPE`, `SIGILL` |
| Log format | Text: signal name, fault address, PC, LR, SP (hex) |
| Log location (primary) | `externalDataPath/crash.log` (file manager visible) |
| Log location (fallback) | `internalDataPath/crash.log` |
| On-screen viewer | Red banner + "Dismiss" button drawn via CNFG |
| Clean shutdown | Log deleted on normal exit to prevent false positives |

## Architecture

### crash.c / crash.h

```
crash_reporter_init(dir)     → opens log file, installs signal handlers
handler(sig, info, context)  → writes signal info to log, re-raises signal
crash_clear()                → deletes log on clean exit
crash_read(out, cap)         → reads log content (for Goose display)
```

### Signal Handler

On crash, the handler writes:
```
signal: SIGSEGV
fault: 0x0000000000000000
pc:    0x0000007f8a123456
lr:    0x0000007f8a123400
sp:    0x0000007fffd00000
```

Then restores default handler and re-raises the signal so Android terminates the process normally.

### Startup / Shutdown Markers

- **Startup marker**: `=== goosecalc startup ===\npath: <dir>` — written on every launch
- **Clean shutdown marker**: Log file is deleted via `crash_clear()` on normal exit

### False Positive Prevention

If a previous session was killed by the OS (not a crash), its log contains only the startup marker. On next launch, `main.c` reads the log and checks:
- If log contains `signal:` but NOT `clean shutdown` → treated as crash → `g_show_crash = true`
- If log contains `clean shutdown` → treated as normal exit → no crash banner

### Flow

```
App Launch
    │
    ▼
Read previous crash.log (before truncation)
    │
    ├── Contains "signal:" without "clean shutdown"
    │   └─► g_show_crash = true  → show crash banner on next draw
    │
    └─► Otherwise → normal start
    │
    ▼
crash_reporter_init() truncates log, installs signal handlers
    │
    ▼
[App runs...]
    │
    ├── Normal exit (back button / destroy)
    │   └─► crash_clear() deletes log
    │
    └─► Crash (signal handler fires)
        └─► Writes fault info, re-raises signal, process dies
        │
        ▼
Next launch: crash banner shows fault details, "Dismiss" button clears it
```

## Crash Viewer UI

When `g_show_crash` is true, `draw_crash()` renders:

```
┌─────────────────────────────────┐
│  CRASH DETECTED                 │  ← Red banner (top 80px)
│                                 │
│  signal: SIGSEGV                │  ← Crash details (scale 2)
│  fault: 0x0000...               │
│  pc:    0x0000...               │
│                                 │
│              [ Dismiss ]        │  ← Red button, bottom center
└─────────────────────────────────┘
```

- **Dismiss**: Clears crash state (`crash_clear()`, `g_show_crash = false`), returns to normal calculator
- **Back button**: Also dismisses crash

## Log Paths

| Priority | Path | Accessible via File Manager |
|----------|------|------------------------------|
| Primary | `<externalDataPath>/crash.log` | ✅ Yes |
| Fallback | `<internalDataPath>/crash.log` | ❌ No (app-private) |

On Termux/Android 10:
- External: `Android/data/com.goosecalc.app/files/crash.log`
- Internal: app-private data directory

## Goose Integration

`calc_bridge.goose` bridges crash functions:
- `crash_text()` → `get_crash_text()` (C string pointer)
- `crash_len()` → `get_crash_len()` (int)
- `crash_clear()` → `clear_crash()` (void)

`calc_main.goose`:
- `goose_init()`: sets `g_show_crash = crash_len() > 0`
- `goose_handle_touch()`: if crash showing, clears and returns
- `goose_handle_back()`: if crash showing, clears and returns

## C Integration

`main.c` exposes:
- `get_data_path()` → returns `externalDataPath` or `internalDataPath`
- `get_crash_text()` → pointer to crash log buffer (4096 bytes)
- `get_crash_len()` → length of crash log
- `clear_crash()` → zeroes crash buffer

## Testing

To test the crash reporter:
1. Install and launch the app normally
2. Force a crash (e.g., kill the process)
3. Relaunch — crash banner should appear with fault details
4. Tap "Dismiss" — banner should disappear
5. Check `crash.log` in file manager at `Android/data/com.goosecalc.app/files/`
