// calc_dispatch.goose — Action enum + button table + apply(). No drawing, no layout math.

import calc_state;
import calc_history;
import calc_layout;

enum Action {
    None,
    Digit { d: i32 },
    Decimal,
    Add, Sub, Mul, Div,
    Equals,
    Clear,
    History,
    DismissCrash,
}

fn action_for(i: i32) -> Action {
    match i {
        0  => Action.Digit { d: 7 },
        1  => Action.Digit { d: 8 },
        2  => Action.Digit { d: 9 },
        3  => Action.Div,
        4  => Action.Digit { d: 4 },
        5  => Action.Digit { d: 5 },
        6  => Action.Digit { d: 6 },
        7  => Action.Mul,
        8  => Action.Digit { d: 1 },
        9  => Action.Digit { d: 2 },
        10 => Action.Digit { d: 3 },
        11 => Action.Sub,
        12 => Action.Digit { d: 0 },
        13 => Action.Decimal,
        14 => Action.Equals,
        15 => Action.Add,
        16 => Action.Clear,
        17 => Action.History,
        _  => Action.None,
    }
}

fn label_for(i: i32) -> u8[>..] {
    match i {
        0  => "7",  1  => "8",  2  => "9",  3  => "/",
        4  => "4",  5  => "5",  6  => "6",  7  => "*",
        8  => "1",  9  => "2",  10 => "3",  11 => "-",
        12 => "0",  13 => ".",  14 => "=",  15 => "+",
        16 => "C",  17 => "HIST",
        _  => "",
    }
}

// Sudoku mode button labels (repurposes the calculator button grid)
fn label_for_sudoku(i: i32) -> u8[>..] {
    match i {
        0  => "1",  1  => "2",  2  => "3",  3  => "4",
        4  => "5",  5  => "6",  6  => "7",  7  => "8",
        8  => "9",  9  => "",   10 => "",   11 => "",
        12 => "CLR",13 => "",   14 => "",   15 => "",
        16 => "RST",17 => "EXIT",
        _  => "",
    }
}

// Build "left op right = result" from an explicit snapshot. The snapshot is
// taken BEFORE evaluate() clears the expression state (evaluate() sets
// has_expr=false), so history keeps the original expression.
fn build_history_entry(had_expr: bool, left: f64, op: Op, right: f64, result: f64) -> u8[>..] {
    var buf: u8[128] = [0; 128];
    var idx = 0;
    
    if had_expr && op != Op.None {
        let left_str = format_number(left);
        let op_str = match op {
            Add => "+", Sub => "-", Mul => "*", Div => "/", None => "",
        };
        let right_str = format_number(right);
        let result_str = format_number(result);
        
        var i = 0;
        while i < left_str.len && left_str[i] != 0 && idx < 120 {
            buf[idx] = left_str[i];
            idx += 1;
            i += 1;
        }
        if idx < 117 {
            buf[idx] = ' '; idx += 1;
        }
        i = 0;
        while i < op_str.len && idx < 118 {
            buf[idx] = op_str[i];
            idx += 1;
            i += 1;
        }
        if idx < 118 {
            buf[idx] = ' '; idx += 1;
        }
        i = 0;
        while i < right_str.len && right_str[i] != 0 && idx < 119 {
            buf[idx] = right_str[i];
            idx += 1;
            i += 1;
        }
        if idx < 119 {
            buf[idx] = ' '; idx += 1;
        }
        if idx < 119 {
            buf[idx] = '='; idx += 1;
        }
        if idx < 119 {
            buf[idx] = ' '; idx += 1;
        }
        i = 0;
        while i < result_str.len && result_str[i] != 0 && idx < 127 {
            buf[idx] = result_str[i];
            idx += 1;
            i += 1;
        }
    } else {
        // No operation — just the entered number
        let result_str = format_number(result);
        var i = 0;
        while i < result_str.len && result_str[i] != 0 && idx < 127 {
            buf[idx] = result_str[i];
            idx += 1;
            i += 1;
        }
    }
    buf[idx] = 0;
    return buf[..];
}

fn apply(state: CalcState&, hist: History&, ui: UIState&, a: Action) {
    match a {
        Digit d => input_digit(state, d.d),
        Decimal => input_decimal(state),
        Add => input_op(state, Op.Add),
        Sub => input_op(state, Op.Sub),
        Mul => input_op(state, Op.Mul),
        Div => input_op(state, Op.Div),
        Equals => {
            // Snapshot BEFORE evaluate() — evaluate clears has_expr/expr_op,
            // which previously made every history entry collapse to its result.
            let had_expr = state.has_expr;
            let left = state.expr_left;
            let op = state.expr_op;
            let right = state.display;
            let ok = evaluate(state);
            if ok {
                let entry = build_history_entry(had_expr, left, op, right, state.display);
                history_push(hist, copy(entry), true);
            } else {
                history_push(hist, "Error", false);
            }
        },
        Clear => clear(state),
        History => { ui.history_visible = true; },
        DismissCrash => {},
        None => {},
    }
}