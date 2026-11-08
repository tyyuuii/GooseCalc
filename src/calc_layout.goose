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