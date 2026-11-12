// calc_layout.goose — ALL constants + Rect/Layout/UIState + compute(w,h). Pure.

struct Rect {
    x1: f32, y1: f32, x2: f32, y2: f32,
}

struct Layout {
    buttons: Rect[20],
    hist_panel: Rect,
    width: i32,
    height: i32,
}

struct UIState {
    layout: Layout,
    history_visible: bool,
    pressed: i32,   // button index currently flashing (-1 = none)
    flash: i32,     // frames remaining on highlight
}

const DISPLAY_H_FRAC: f32 = 0.20;
const PANEL_W_FRAC:   f32 = 0.80;
const PANEL_H_FRAC:   f32 = 0.80;
const CHAR_CELL:      f32 = 8.0;
const CLOSE_SIZE:     f32 = 40.0;
const HIST_ROW_H:     f32 = 35.0;
const PAD:            f32 = 20.0;
const CRASH_BANNER_H: f32 = 80.0;

const BTN_COLS:  i32 = 4;
const BTN_ROWS:  i32 = 5;
const BTN_COUNT: i32 = 20;

const SCALE_DISPLAY: i32 = 6;
const SCALE_BUTTON:  i32 = 6;   // font8x8: HIST = 162px at 6, fits 180px button
const SCALE_HIST:    i32 = 3;
const SCALE_CRASH:   i32 = 2;

// === Sudoku game ===

const SUDOKU_SIZE: i32 = 9;
const SUDOKU_CELLS: i32 = 81;   // 9 * 9

// Difficulty levels: number of pre-filled cells
const SUDOKU_EASY_FILLED: i32 = 40;
const SUDOKU_MEDIUM_FILLED: i32 = 32;
const SUDOKU_HARD_FILLED: i32 = 26;

enum SudokuDifficulty { Easy, Medium, Hard }

// Sudoku game state
struct SudokuGame {
    values: i32[81],         // 0-9, 0 = empty
    fixed: u8[81],           // 0 or 1 — 1 means part of the original puzzle
    solution: i32[81],       // the correct solution for each cell
    wrong: u8[81],           // 0 or 1 — 1 means user placed a wrong number
    cursor: i32,             // 0-80, currently selected cell
    solved: bool,            // true when puzzle is completed correctly
    highlight_num: i32,      // 1-9 to highlight matching cells, -1 = none
    difficulty: SudokuDifficulty,
    mistakes: i32,           // count of wrong moves
    showing_difficulty: bool,// true when difficulty dialog is shown
    game_over: bool,         // true when mistakes >= 3 and waiting for difficulty pick
    mistake_msg_timer: i32,  // frames remaining for "you made a mistake" dialog (60 = ~1s)
}

fn new_sudoku() -> SudokuGame {
    return SudokuGame {
        values: [0; 81],
        fixed: [0; 81],
        solution: [0; 81],
        wrong: [0; 81],
        cursor: 0,
        solved: false,
        highlight_num: -1,
        difficulty: SudokuDifficulty.Easy,
        mistakes: 0,
        showing_difficulty: true,   // show difficulty on first launch
        game_over: false,
        mistake_msg_timer: 0,
    };
}

fn empty_rect() -> Rect {
    return Rect { x1: 0.0, y1: 0.0, x2: 0.0, y2: 0.0 };
}

fn empty_layout() -> Layout {
    return Layout {
        buttons: [empty_rect(); 20],
        hist_panel: empty_rect(),
        width: 0, height: 0,
    };
}

fn new_ui() -> UIState {
    return UIState { layout: empty_layout(), history_visible: false, pressed: -1, flash: 0 };
}

fn compute(w: i32, h: i32) -> Layout {
    var lay = empty_layout();
    lay.width = w;
    lay.height = h;
    let wf = w as f32;
    let hf = h as f32;
    let display_h = hf * DISPLAY_H_FRAC;
    let grid_h = hf - display_h;
    let bw = wf / (BTN_COLS as f32);
    let bh = grid_h / (BTN_ROWS as f32);
    for row in 0..5 {
        for col in 0..4 {
            let i = (row * 4 + col) as i32;
            let x1 = (col as f32) * bw;
            let y1 = display_h + (row as f32) * bh;
            lay.buttons[i] = Rect { x1: x1, y1: y1, x2: x1 + bw, y2: y1 + bh };
        }
    }
    let pw = wf * PANEL_W_FRAC;
    let ph = hf * PANEL_H_FRAC;
    lay.hist_panel = Rect {
        x1: (wf - pw) * 0.5, y1: (hf - ph) * 0.5,
        x2: (wf + pw) * 0.5, y2: (hf + ph) * 0.5,
    };
    return lay;
}

fn button_font_px(scale: i32) -> i32 {
    return scale * (CHAR_CELL as i32);
}

// === Sudoku generator ===

// Seed counter — increments each time a puzzle is generated, ensuring
// each puzzle is different without needing the os module.
var g_rng_seed: u32 = 1;

// Simple deterministic-but-seeded PRNG: xorshift32
struct SimpleRng { state: u32 }

fn rng_new(seed: u32) -> SimpleRng {
    return SimpleRng { state: seed };
}

fn rng_next(rng: SimpleRng&) -> u32 {
    var x = rng.state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    rng.state = x;
    return x;
}

// Generate a complete, valid solved 9x9 Sudoku grid using backtracking.
// Fills `grid` in place. Starts with diagonal 3x3 boxes seeded for efficiency.
fn generate_full_grid(grid: i32[81]&, rng: SimpleRng&) {
    // Start with an empty grid
    var i = 0;
    while i < 81 {
        grid[i] = 0;
        i += 1;
    }

    // Fill the diagonal 3x3 boxes first (they are independent of each other)
    var box = 0;
    while box < 3 {
        var nums: i32[9] = [1, 2, 3, 4, 5, 6, 7, 8, 9];
        // Fisher-Yates shuffle using seeded RNG
        var k = 8;
        while k > 0 {
            let j = (rng_next(rng) as i64 % (k + 1) as i64) as i32;
            let tmp = nums[k];
            nums[k] = nums[j];
            nums[j] = tmp;
            k -= 1;
        }
        let br = box * 3;
        let bc = box * 3;
        var n = 0;
        while n < 9 {
            let r = br + (n / 3);
            let c = bc + (n % 3);
            grid[r * 9 + c] = nums[n];
            n += 1;
        }
        box += 1;
    }

    // Solve the rest using backtracking with randomized number order
    sudoku_solve(grid, rng);
}

// Generate a puzzle by removing cells from a full grid while keeping a unique solution.
// `difficulty` determines how many cells remain filled (EASY=40, MEDIUM=32, HARD=26).
// Fills both `game.values` (the puzzle) and `game.solution` (the answer).
fn generate_sudoku_puzzle(game: SudokuGame&, diff: SudokuDifficulty) {
    // Seed RNG from incrementing counter so each puzzle is different
    let seed = g_rng_seed;
    g_rng_seed += 1;
    var rng = rng_new(seed);

    // Step 1: Generate a complete solved grid
    var full: i32[81] = [0; 81];
    generate_full_grid(full, rng);

    // Copy the full solution into game.solution
    var i = 0;
    while i < 81 {
        game.solution[i] = full[i];
        i += 1;
    }

    // Step 2: Determine target number of filled cells
    let target_filled: i32;
    if diff == SudokuDifficulty.Easy { target_filled = SUDOKU_EASY_FILLED; }
    else if diff == SudokuDifficulty.Medium { target_filled = SUDOKU_MEDIUM_FILLED; }
    else { target_filled = SUDOKU_HARD_FILLED; }

    // Step 3: Start with full grid as the puzzle, then remove cells
    var puzzle: i32[81] = [0; 81];
    i = 0;
    while i < 81 {
        puzzle[i] = full[i];
        i += 1;
    }

    // Create a removal order (shuffle indices 0..80 using seeded RNG)
    var order: i32[81] = [0; 81];
    i = 0;
    while i < 81 {
        order[i] = i as i32;
        i += 1;
    }
    // Fisher-Yates shuffle using seeded RNG
    i = 80;
    while i > 0 {
        let j = (rng_next(rng) as i64 % (i + 1) as i64) as i32;
        let tmp = order[i];
        order[i] = order[j];
        order[j] = tmp;
        i -= 1;
    }

    // Count currently filled cells
    var filled = 81;
    i = 0;
    while i < 81 {
        if puzzle[order[i]] != 0 {
            // Try removing this cell
            puzzle[order[i]] = 0;
            // Check if the puzzle still has a unique solution
            let unique = sudoku_removal_keeps_unique(puzzle, order[i]);
            if unique {
                filled -= 1;
            } else {
                // Put it back — removing would break uniqueness
                puzzle[order[i]] = full[order[i]];
            }
            if filled <= target_filled { break; }
        }
        i += 1;
    }

    // Step 4: Copy puzzle into game.values, set fixed flags
    i = 0;
    while i < 81 {
        game.values[i] = puzzle[i];
        game.fixed[i] = if puzzle[i] != 0 { 1 } else { 0 };
        game.wrong[i] = 0;
        i += 1;
    }

    game.cursor = 0;
    game.solved = false;
    game.mistakes = 0;
    game.highlight_num = -1;
    game.game_over = false;
    game.showing_difficulty = false;
    game.mistake_msg_timer = 0;
}

fn load_sudoku_puzzle(game: SudokuGame&, diff: SudokuDifficulty) {
    generate_sudoku_puzzle(game, diff);
}