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