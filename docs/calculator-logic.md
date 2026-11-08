# Calculator Logic

GooseCalc implements a desk-calculator (chained operation) state machine with expression display, history, and number formatting.

## State Machine

### CalcState Struct

| Field | Type | Description |
|-------|------|-------------|
| `display` | `f64` | Current display value |
| `accumulator` | `f64` | Left operand for pending operation |
| `pending_op` | `Op` | Waiting operator (`None`, `Add`, `Sub`, `Mul`, `Div`) |
| `just_evaluated` | `bool` | True after `=` was pressed |
| `error` | `bool` | True if in error state (e.g. divide by zero) |
| `decimal_mode` | `bool` | True while entering fractional digits |
| `decimal_digits` | `u32` | Count of decimal digits entered |
| `starting_new_number` | `bool` | Next digit starts a fresh number |
| `expr_left` | `f64` | Left operand for expression display |
| `expr_op` | `Op` | Operator for expression display |
| `has_expr` | `bool` | True if waiting for second operand |

## Operation Semantics

**Chained (desk-calculator) evaluation:** Operations are applied left-to-right as they are entered.

```
2 + 3 * 4 = 20   (not 14)
   └─ 2+3=5, then 5*4=20
```

### Operator Replacement

If an operator is pressed while `starting_new_number` is true (no digits entered yet), the operator is swapped without evaluation:

```
2 + * 3  →  2 * 3 = 6
```

### Digit Input

| Condition | Behavior |
|-----------|----------|
| Error state | Clear first |
| Just evaluated | Start new number (display = 0) |
| Starting new number | Start new number (display = 0) |
| Decimal mode | Add digit / divisor^position |
| Normal | `display = display * 10 + digit` |

Overflow clamp: values beyond ±9.999999999999999e15 are ignored.

### Decimal Input

- Enters decimal mode, resets digit counter
- If starting new number, starts from 0
- If just evaluated, resets all state

### Equals (`=`)

1. Snapshot `has_expr`, `expr_left`, `expr_op`, `display` (before `evaluate()` clears them)
2. Call `evaluate()` → applies pending operation
3. If OK: push history entry `"left op right = result"`
4. If error: push `"Error"`
5. Set `just_evaluated = true`, clear expression state

### Clear (`C`)

Resets all state to initial values.

## Expression Display

The display shows different content depending on state:

| State | Display Shows |
|-------|---------------|
| Error | `"Error"` |
| `has_expr && expr_op != None && starting_new_number` | `"left op "` (e.g. `"10 + "`) |
| Otherwise | Current `display` value |

This shows the pending expression while waiting for the second operand, then switches to the operand being typed.

## History

### HistoryEntry Struct

| Field | Type | Description |
|-------|------|-------------|
| `text` | `u8[128]` | Full expression string (e.g. `"10 + 10 = 20"`) |
| `ok` | `bool` | True if calculation succeeded |

### History Ring Buffer

- Capacity: 32 entries
- `history_push()`: writes at `(head + count) % 32`
- When full: advances `head` (overwrites oldest)
- `history_load()` / `history_save()`: stubbed (persistence disabled)

### History Panel UI

- Centered floating panel (80% width, 80% height)
- Close button ("X") at top-right of panel
- List shows newest entries first
- Empty state shows "(empty)"
- Each entry: green/white text, error entries show "Error"

## Button Layout

4 columns × 5 rows = 20 buttons:

| Row 0 | Row 1 | Row 2 | Row 3 | Row 4 |
|-------|-------|-------|-------|-------|
| 7 | 4 | 1 | 0 | |
| 8 | 5 | 2 | . | |
| 9 | 6 | 3 | = | |
| / | * | - | + | |
| | | | C | HIST |

Button indices 0-19 map to:
```
0→7, 1→8, 2→9, 3→/,
4→4, 5→5, 6→6, 7→*,
8→1, 9→2, 10→3, 11→-,
12→0, 13→., 14→=, 15→+,
16→C, 17→HIST, 18-19→None
```

## Number Formatting

### format_number(v)

Routes to the appropriate formatter:

1. **NaN** → `"Error"`
2. **+Inf** → `"Infinity"`, **-Inf** → `"-Infinity"`
3. **\|v\| >= 1e16** → `format_sci(v)`
4. **0 < \|v\| < 1e-9** → `format_sci(v)` (avoids truncation)
5. **0 < \|v\| < 1e-4** → `format_dec(v)` (fixed-point, no sci notation)
6. **Otherwise** → `format_dec(v)`

### format_dec(v) — Fixed Point

- Single rounding step: `r = round(v * 10^frac_digits)`
- Integer part from `r / 10^frac_digits`
- Fraction part from `r % 10^frac_digits`, trailing zeros trimmed
- Max 16 characters total (including sign and decimal point)
- No repeated multiply/subtract (avoids `1.19999999999` artifacts)

### format_sci(v) — Scientific Notation

- Format: `"1.234567e+20"` or `"-9.876543e-15"`
- Mantissa normalized to `[1, 10)` via pure f64 math
- 6 fraction digits, exponent up to 3 digits
- Max 16 characters

## Display Auto-Shrink

When the number is too wide for the display area:
- Start at `SCALE_DISPLAY = 6`
- Decrease scale until text fits between padding (or floor at scale 2)
- Text is right-aligned in the display area

## Error Handling

| Error | Result |
|-------|--------|
| Division by zero | Error state, display `"Error"`, history entry `"Error"` |
| Overflow | Digit ignored, value clamped |
| Invalid operation | Error state |

Error state is cleared by any new digit input or `C`.

## Drawing

`draw_calculator()` renders each frame:

1. Dark gray background (`0x101010FF`)
2. Black display area (top 20% of screen)
3. White display text (right-aligned, auto-scaled)
4. 20 buttons: dark gray fill (`0x404040FF`), white top/left edges (3D effect), centered labels
5. Pressed button: lighter gray (`0x808080FF`) flash for ~8 frames (~130ms)
6. History panel overlay (if visible): semi-transparent black background, centered panel, close button, entry list

## Touch Handling

1. If crash banner showing → dismiss crash, return
2. If history panel showing → check close button, else ignore taps outside panel
3. Hit-test against button rects → `button_at()`
4. If button found → `action_for()` → `apply()` → set pressed highlight (flash = 8 frames)
5. Return 1 (handled) or 2 (button hit)

## Rotation Handling

On resume after rotation, `HandleResume()` calls `goose_force_resize()` which resets layout to empty. Next `goose_draw()` recomputes layout from new screen dimensions.
