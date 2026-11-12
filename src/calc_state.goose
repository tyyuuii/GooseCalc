// calc_state.goose — state machine, evaluate()
// Chained ops are SEQUENTIAL (desk-calculator): 2 + 3 * 4 = 20, not 14.

import calc_format;

enum Op { None, Add, Sub, Mul, Div }

struct CalcState {
    display: f64,
    accumulator: f64,
    pending_op: Op,
    just_evaluated: bool,
    error: bool,
    decimal_mode: bool,
    decimal_digits: u32,
    starting_new_number: bool,  // next digit starts a new number (after op)
    expr_left: f64,             // left operand for expression display
    expr_op: Op,                // pending operator for expression display
    has_expr: bool,             // whether we have a partial expression
}

fn new_state() -> CalcState {
    return CalcState {
        display: 0.0,
        accumulator: 0.0,
        pending_op: Op.None,
        just_evaluated: false,
        error: false,
        decimal_mode: false,
        decimal_digits: 0,
        starting_new_number: false,
        expr_left: 0.0,
        expr_op: Op.None,
        has_expr: false,
    };
}

fn clear(state: CalcState&) {
    state.display = 0.0;
    state.accumulator = 0.0;
    state.pending_op = Op.None;
    state.just_evaluated = false;
    state.error = false;
    state.decimal_mode = false;
    state.decimal_digits = 0;
    state.starting_new_number = false;
    state.expr_left = 0.0;
    state.expr_op = Op.None;
    state.has_expr = false;
}

fn input_digit(state: CalcState&, digit: i32) {
    if state.error {
        clear(state);
    }
    if state.just_evaluated {
        state.display = 0.0;
        state.just_evaluated = false;
        state.decimal_mode = false;
        state.decimal_digits = 0;
        state.has_expr = false;
        state.expr_op = Op.None;
    }
    if state.starting_new_number {
        state.display = 0.0;
        state.starting_new_number = false;
        state.decimal_mode = false;
        state.decimal_digits = 0;
    }
    
    // Clamp to prevent overflow in display formatting (MAX_DISPLAY_CHARS = 16)
    const MAX_VAL: f64 = 9.999999999999999e15;
    if state.display > MAX_VAL || state.display < -MAX_VAL {
        return;
    }
    
    if state.decimal_mode {
        state.decimal_digits += 1;
        var divisor: f64 = 10.0;
        var d: u32 = 1;
        while d < state.decimal_digits {
            divisor *= 10.0;
            d += 1;
        }
        if state.display >= 0.0 {
            state.display += (digit as f64) / divisor;
        } else {
            state.display -= (digit as f64) / divisor;
        }
    } else {
        state.display = state.display * 10.0 + digit as f64;
    }
}

fn input_decimal(state: CalcState&) {
    if state.error {
        clear(state);
    }
    if state.just_evaluated {
        state.display = 0.0;
        state.just_evaluated = false;
        state.has_expr = false;
        state.expr_op = Op.None;
        state.decimal_mode = false;      // fresh decimal state after equals
        state.decimal_digits = 0;
    }
    if state.starting_new_number {
        state.display = 0.0;
        state.starting_new_number = false;
        state.decimal_mode = false;
        state.decimal_digits = 0;
    }
    if !state.decimal_mode {
        state.decimal_mode = true;
        state.decimal_digits = 0;
    }
}

fn op_to_str(op: Op) -> u8[>..] {
    match op {
        Add => "+",
        Sub => "-",
        Mul => "*",
        Div => "/",
        None => "",
    }
}

fn input_op(state: CalcState&, op: Op) {
    if state.error {
        return;
    }
    // Chained op (second operand fully entered): fold pending into display.
    // Operator REPLACEMENT ("2 + * 3"): starting_new_number still true and
    // nothing was typed — swap the operator, do NOT evaluate left with itself.
    if state.pending_op != Op.None && !state.just_evaluated && !state.starting_new_number {
        evaluate_pending(state);
    }
    // Store left operand and operator for expression display
    state.expr_left = state.display;
    state.expr_op = op;
    state.has_expr = true;
    state.accumulator = state.display;
    state.pending_op = op;
    state.just_evaluated = false;
    state.starting_new_number = true;
    state.decimal_mode = false;
    state.decimal_digits = 0;
}

fn evaluate_pending(state: CalcState&) -> bool {
    if state.pending_op == Op.None {
        return true;
    }
    let a = state.accumulator;
    let b = state.display;
    var ok = true;
    
    let result = match state.pending_op {
        Add => a + b,
        Sub => a - b,
        Mul => a * b,
        Div => {
            if b == 0.0 {
                ok = false;
                0.0
            } else {
                a / b
            }
        },
        None => {
            ok = false;
            0.0
        },
    };
    
    if !ok {
        state.error = true;
        state.display = 0.0;
        state.pending_op = Op.None;
        state.has_expr = false;
        state.expr_op = Op.None;
        return false;
    }
    
    state.display = result;
    state.accumulator = result;
    state.pending_op = Op.None;
    return true;
}

fn evaluate(state: CalcState&) -> bool {
    if state.error {
        return false;
    }
    let ok = evaluate_pending(state);
    state.just_evaluated = true;
    // After =, clear expression state but keep result for chained ops
    state.has_expr = false;
    state.expr_op = Op.None;
    return ok;
}

fn get_display(state: const CalcState&) -> u8[17] {
    if state.error {
        return copy_to_fixed(str("Error"));
    }
    // Show partial expression "left op " only while waiting for second operand
    // Once user starts typing (starting_new_number = false), show the right operand
    if state.has_expr && state.expr_op != Op.None && state.starting_new_number {
        var buf: u8[17] = [0; 17];
        let left_str = format_number(state.expr_left);
        let op_str = op_to_str(state.expr_op);
        var idx = 0;
        // Copy left number
        var i = 0;
        while i < left_str.len && left_str[i] != 0 && idx < 16 {
            buf[idx] = left_str[i];
            idx += 1;
            i += 1;
        }
        // Copy operator with spaces
        if idx < 15 {
            buf[idx] = ' ';
            idx += 1;
        }
        i = 0;
        while i < op_str.len && idx < 16 {
            buf[idx] = op_str[i];
            idx += 1;
            i += 1;
        }
        if idx < 16 {
            buf[idx] = ' ';
            idx += 1;
        }
        buf[idx] = 0;
        return buf;
    }
    // Otherwise show current display value (right operand being typed, or result)
    return format_number(state.display);
}

fn get_display_value(state: const CalcState&) -> f64 {
    return state.display;
}

fn has_error(state: const CalcState&) -> bool {
    return state.error;
}

// === Sudoku game logic ===

fn sudoku_row_contains(values: const i32[81], row: i32, val: i32) -> bool {
    var c = 0;
    while c < 9 {
        if values[row * 9 + c] == val { return true; }
        c += 1;
    }
    return false;
}

fn sudoku_col_contains(values: const i32[81], col: i32, val: i32) -> bool {
    var r = 0;
    while r < 9 {
        if values[r * 9 + col] == val { return true; }
        r += 1;
    }
    return false;
}

fn sudoku_box_contains(values: const i32[81], idx: i32, val: i32) -> bool {
    let r = idx / 9;
    let c = idx % 9;
    let br = (r / 3) * 3;
    let bc = (c / 3) * 3;
    var rr = br;
    while rr < br + 3 {
        var cc = bc;
        while cc < bc + 3 {
            if values[rr * 9 + cc] == val { return true; }
            cc += 1;
        }
        rr += 1;
    }
    return false;
}

fn sudoku_box_contains_excl(values: const i32[81], idx: i32, val: i32) -> bool {
    let r = idx / 9;
    let c = idx % 9;
    let br = (r / 3) * 3;
    let bc = (c / 3) * 3;
    var rr = br;
    while rr < br + 3 {
        var cc = bc;
        while cc < bc + 3 {
            let i = rr * 9 + cc;
            if i != idx && values[i] == val { return true; }
            cc += 1;
        }
        rr += 1;
    }
    return false;
}

fn sudoku_is_valid(values: const i32[81], idx: i32) -> bool {
    let val = values[idx];
    if val == 0 { return true; }
    let r = idx / 9;
    let c = idx % 9;
    var ci = 0;
    while ci < 9 {
        let i = r * 9 + ci;
        if i != idx && values[i] == val { return false; }
        ci += 1;
    }
    var ri = 0;
    while ri < 9 {
        let i = ri * 9 + c;
        if i != idx && values[i] == val { return false; }
        ri += 1;
    }
    return !sudoku_box_contains_excl(values, idx, val);
}

fn sudoku_is_solved(values: const i32[81], fixed: const u8[81]) -> bool {
    // All cells filled
    var i = 0;
    while i < 81 {
        if values[i] == 0 { return false; }
        i += 1;
    }
    // No duplicates anywhere
    i = 0;
    while i < 81 {
        if !sudoku_is_valid(values, i as i32) { return false; }
        i += 1;
    }
    return true;
}

// === Sudoku generator: backtracking solver ===

// Find first empty cell (value == 0), return index or -1 if none
fn sudoku_find_empty(values: const i32[81]) -> i32 {
    var i = 0;
    while i < 81 {
        if values[i] == 0 { return i as i32; }
        i += 1;
    }
    return -1;
}

// Recursive backtracking solver. Returns true when grid is solved.
// The grid is modified in place. Uses `rng` to randomize number order so
// each generated puzzle is different.
recursive fn sudoku_solve(values: i32[81]&, rng: SimpleRng&) -> bool {
    let idx = sudoku_find_empty(values);
    if idx == -1 { return true; }  // no empty cells = solved

    // Build a shuffled list of numbers 1..9 using the RNG
    var nums: i32[9] = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    var k = 8;
    while k > 0 {
        let j = (rng_next(rng) as i64 % (k + 1) as i64) as i32;
        let tmp = nums[k];
        nums[k] = nums[j];
        nums[j] = tmp;
        k -= 1;
    }

    var n = 0;
    while n < 9 {
        let num = nums[n];
        values[idx] = num;
        if sudoku_is_valid(values, idx as i32) {
            if sudoku_solve(values, rng) { return true; }
        }
        values[idx] = 0;
        n += 1;
    }
    return false;
}

// Count solutions up to `limit` (used to verify unique solution after cell removal).
// Returns the count (capped at `limit`).
recursive fn sudoku_count_solutions(values: i32[81]&, limit: i32) -> i32 {
    if limit <= 0 { return limit; }
    let idx = sudoku_find_empty(values);
    if idx == -1 { return 1; }  // found one complete solution

    var count: i32 = 0;
    var num: i32 = 1;
    while num <= 9 && count < limit {
        values[idx] = num;
        if sudoku_is_valid(values, idx as i32) {
            count += sudoku_count_solutions(values, limit - count);
        }
        values[idx] = 0;
        num += 1;
    }
    return count;
}

// Check if removing cell at `idx` still leaves a unique solution.
// Returns true if the puzzle with that cell removed has exactly one solution.
fn sudoku_removal_keeps_unique(values: i32[81]&, idx: i32) -> bool {
    let saved = values[idx];
    values[idx] = 0;
    let count = sudoku_count_solutions(values, 2);
    values[idx] = saved;
    return count == 1;
}