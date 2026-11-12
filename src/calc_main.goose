// calc_main.goose — ONLY file with export fn. Wires modules. Thin.

import calc_bridge;
import calc_state;
import calc_history;
import calc_layout;
import calc_hit;
import calc_draw;
import calc_dispatch;

var g_state: CalcState = new_state();
var g_history: History = new_history();
var g_ui: UIState = new_ui();
var g_show_crash: bool = false;

// === Sudoku game mode ===
var g_game_mode: i32 = 0;          // 0 = calculator, 1 = sudoku
var g_sudoku: SudokuGame = new_sudoku();
var g_cheat_progress: i32 = 0;     // cheat code sequence progress

// Cheat sequence: 6, 9, +, 4, 2, 0, /, 6, 9, =
// Button indices: 6→digit 6, 2→digit 9, 15→+, 4→digit 4, 9→digit 2, 12→digit 0,
//                 3→/, 6→digit 6, 2→digit 9, 14→=
const CHEAT_SEQ: i32[10] = [6, 2, 15, 4, 9, 12, 3, 6, 2, 14];

fn sudoku_set_cell(digit: i32) {
    if g_sudoku.solved { return; }
    if g_sudoku.game_over { return; }
    if g_sudoku.showing_difficulty { return; }
    if g_sudoku.cursor < 0 || g_sudoku.cursor >= 81 { return; }
    if g_sudoku.fixed[g_sudoku.cursor] != 0 { return; }

    // Always place the number (if cell is not fixed)
    g_sudoku.values[g_sudoku.cursor] = digit;
    g_sudoku.wrong[g_sudoku.cursor] = 0;  // clear wrong flag first

    // Validate against the solution
    if digit != 0 && g_sudoku.values[g_sudoku.cursor] != g_sudoku.solution[g_sudoku.cursor] {
        g_sudoku.wrong[g_sudoku.cursor] = 1;   // mark as wrong
        g_sudoku.mistakes += 1;
        g_sudoku.mistake_msg_timer = 60;       // show dialog for ~1 second (60 frames)
        if g_sudoku.mistakes >= 3 {
            g_sudoku.game_over = true;
            g_sudoku.showing_difficulty = true;  // show difficulty dialog again
        }
        return;
    }

    // Check if puzzle is fully solved
    if sudoku_is_solved(g_sudoku.values, g_sudoku.fixed) {
        g_sudoku.solved = true;
    }
}

fn sudoku_clear_cell() {
    if g_sudoku.solved { return; }
    if g_sudoku.game_over { return; }
    if g_sudoku.showing_difficulty { return; }
    if g_sudoku.cursor < 0 || g_sudoku.cursor >= 81 { return; }
    if g_sudoku.fixed[g_sudoku.cursor] != 0 { return; }
    g_sudoku.values[g_sudoku.cursor] = 0;
    g_sudoku.wrong[g_sudoku.cursor] = 0;
}

fn sudoku_reset() {
    // Keep current difficulty, just reload the puzzle
    load_sudoku_puzzle(g_sudoku, g_sudoku.difficulty);
}

fn sudoku_load_difficulty(diff: SudokuDifficulty) {
    load_sudoku_puzzle(g_sudoku, diff);
}

fn check_cheat(btn: i32) -> bool {
    if btn == CHEAT_SEQ[g_cheat_progress] {
        g_cheat_progress += 1;
        if g_cheat_progress >= 10 {
            g_cheat_progress = 0;
            return true;
        }
    } else {
        g_cheat_progress = 0;
        if btn == CHEAT_SEQ[0] {
            g_cheat_progress = 1;
        }
    }
    return false;
}

fn goose_init(argc: i32, argv: u64) {
    g_show_crash = crash_len() > 0;
    g_history = history_load();
    // Start with difficulty dialog showing
    g_sudoku.showing_difficulty = true;
    g_sudoku.game_over = false;
    g_sudoku.mistakes = 0;
}

export fn goose_handle_touch(x: i32, y: i32, bDown: i32) -> i32 {
    if bDown == 0 { return 1; }
    let fx = x as f32;
    let fy = y as f32;

    if g_ui.layout.width == 0 {
        g_ui.layout = compute(screen_w(), screen_h());
    }

    if g_show_crash {
        crash_clear();
        g_show_crash = false;
        return 1;
    }

    let btn = button_at(g_ui.layout, fx, fy);

    // === Sudoku mode ===
    if g_game_mode == 1 {
        let w = screen_w();
        let h = screen_h();

        // Difficulty dialog overlay (top-center modal)
        if g_sudoku.showing_difficulty || g_sudoku.game_over {
            let dlg_w = (w as f32 * 0.70);
            let dlg_h = (h as f32 * 0.45);
            let dlg_x = (w as f32 - dlg_w) * 0.5;
            let dlg_y = (h as f32 - dlg_h) * 0.5;

            // Button dimensions (must match draw_difficulty_dialog exactly)
            let btn_w = dlg_w * 0.40;
            let btn_h = dlg_h * 0.12;
            let btn_x1 = dlg_x + (dlg_w - btn_w) * 0.5;
            let btn_x2 = btn_x1 + btn_w;

            // Easy: y from 0.50 to 0.62 of dialog height
            let easy_y1 = dlg_y + dlg_h * 0.50;
            let easy_y2 = easy_y1 + btn_h;
            // Medium: y from 0.66 to 0.78
            let med_y1 = dlg_y + dlg_h * 0.66;
            let med_y2 = med_y1 + btn_h;
            // Hard: y from 0.82 to 0.94
            let hard_y1 = dlg_y + dlg_h * 0.82;
            let hard_y2 = hard_y1 + btn_h;

            if fx >= btn_x1 && fx <= btn_x2 && fy >= easy_y1 && fy <= easy_y2 {
                sudoku_load_difficulty(SudokuDifficulty.Easy);
                g_ui.pressed = -1; g_ui.flash = 0;
                return 1;
            }
            if fx >= btn_x1 && fx <= btn_x2 && fy >= med_y1 && fy <= med_y2 {
                sudoku_load_difficulty(SudokuDifficulty.Medium);
                g_ui.pressed = -1; g_ui.flash = 0;
                return 1;
            }
            if fx >= btn_x1 && fx <= btn_x2 && fy >= hard_y1 && fy <= hard_y2 {
                sudoku_load_difficulty(SudokuDifficulty.Hard);
                g_ui.pressed = -1; g_ui.flash = 0;
                return 1;
            }
            // Taps outside buttons do nothing — must pick a difficulty
            return 1;
        }

        // Board tap — select a cell (square board, centered)
        let board_size = if w as f32 < (h as f32 * 0.75) { w as f32 } else { h as f32 * 0.75 };
        let board_x = (w as f32 - board_size) * 0.5;
        let board_y = (h as f32 * 0.08);
        let cell_w = board_size / 9.0;
        let cell_h = board_size / 9.0;

        if fy >= board_y && fy < (board_y + board_size) && fx >= board_x && fx < (board_x + board_size) {
            let col = ((fx - board_x) / cell_w) as i32;
            let row = ((fy - board_y) / cell_h) as i32;
            if col >= 0 && col < 9 && row >= 0 && row < 9 {
                g_sudoku.cursor = row * 9 + col;
                let v = g_sudoku.values[g_sudoku.cursor];
                g_sudoku.highlight_num = if v >= 1 && v <= 9 { v } else { -1 };
                g_ui.pressed = -1;
                g_ui.flash = 0;
            }
            return 1;
        }

        // Button tap — bottom area (below board), 4 cols x 3 rows of square cells
        let btn_area_top = board_y + board_size;
        let btn_area_h = (screen_h() as f32) - btn_area_top;
        if fy >= btn_area_top && fy < (screen_h() as f32) {
            let btn_cols: i32 = 4;
            let btn_rows: i32 = 3;
            let bw = (screen_w() as f32) / (btn_cols as f32);
            let bh = btn_area_h / (btn_rows as f32);
            let cell_size = if bw < bh { bw } else { bh };
            let grid_w = cell_size * (btn_cols as f32);
            let grid_h = cell_size * (btn_rows as f32);
            let grid_x = (screen_w() as f32 - grid_w) * 0.5;
            let grid_y = btn_area_top + (btn_area_h - grid_h) * 0.5;
            let col = ((fx - grid_x) / cell_size) as i32;
            let row = ((fy - grid_y) / cell_size) as i32;
            if col >= 0 && col < btn_cols && row >= 0 && row < btn_rows {
                let bi = row * btn_cols + col;
                let btn_order: i32[12] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 12, 16, 17];
                let sbtn = btn_order[bi];
                var exit_game: bool = false;
                if sbtn == 0 { sudoku_set_cell(1); }
                else if sbtn == 1 { sudoku_set_cell(2); }
                else if sbtn == 2 { sudoku_set_cell(3); }
                else if sbtn == 3 { sudoku_set_cell(4); }
                else if sbtn == 4 { sudoku_set_cell(5); }
                else if sbtn == 5 { sudoku_set_cell(6); }
                else if sbtn == 6 { sudoku_set_cell(7); }
                else if sbtn == 7 { sudoku_set_cell(8); }
                else if sbtn == 8 { sudoku_set_cell(9); }
                else if sbtn == 12 { sudoku_clear_cell(); }
                else if sbtn == 16 { sudoku_reset(); }
                else if sbtn == 17 { exit_game = true; }
                if exit_game {
                    g_game_mode = 0;
                    g_ui.pressed = -1;
                    g_ui.flash = 0;
                    return 1;
                }
                g_ui.pressed = sbtn;
                g_ui.flash = 8;
            }
            return 1;
        }

        return 1;
    }

    // === Calculator mode ===
    if g_ui.history_visible {
        if in_hist_close(g_ui.layout, fx, fy) {
            g_ui.history_visible = false;
        }
        return 1;
    }

    if btn < 0 { return 1; }

    // Cheat code detection (only in calculator mode)
    if check_cheat(btn) {
        g_game_mode = 1;
        g_sudoku.showing_difficulty = true;   // show difficulty picker first
        g_ui.pressed = btn;
        g_ui.flash = 8;
        return 1;
    }

    let a = action_for(btn);
    apply(g_state, g_history, g_ui, a);
    // Press feedback: highlight this button for ~8 frames (~130ms)
    g_ui.pressed = btn;
    g_ui.flash = 8;
    return 1;
}

export fn goose_draw() {
    let w = screen_w();
    let h = screen_h();
    if w > 1 && h > 1 && (g_ui.layout.width != w || g_ui.layout.height != h) {
        g_ui.layout = compute(w, h);
    }
    if g_show_crash {
        draw_crash(g_ui.layout);
        return;
    }

    // Tick flash countdown (works in both modes)
    var highlight: i32 = -1;
    if g_ui.flash > 0 && g_ui.pressed >= 0 {
        highlight = g_ui.pressed;
        g_ui.flash -= 1;
        if g_ui.flash == 0 { g_ui.pressed = -1; }
    }

    // === Sudoku mode ===
    if g_game_mode == 1 {
        // Count down mistake message timer
        if g_sudoku.mistake_msg_timer > 0 {
            g_sudoku.mistake_msg_timer -= 1;
        }
        draw_sudoku(g_ui.layout, g_sudoku, highlight);
        return;
    }

    // === Calculator mode ===
    draw_calculator(g_ui.layout, g_state, highlight);
    if g_ui.history_visible {
        draw_history(g_ui.layout, g_history);
    }
}

export fn goose_handle_back() -> i32 {
    if g_game_mode == 1 {
        if g_sudoku.showing_difficulty || g_sudoku.game_over {
            // Can't back out of difficulty dialog
            return 1;
        }
        g_game_mode = 0;
        return 1;
    }
    if g_ui.history_visible { g_ui.history_visible = false; return 1; }
    if g_show_crash { crash_clear(); g_show_crash = false; return 1; }
    return 0;
}

export fn goose_force_resize() {
    g_ui.layout = empty_layout();
}

fn goose_exit() {
    history_save(g_history);
}
