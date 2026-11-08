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

fn goose_init(argc: i32, argv: u64) {
    g_show_crash = crash_len() > 0;
    g_history = history_load();
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

    if g_ui.history_visible {
        if in_hist_close(g_ui.layout, fx, fy) {
            g_ui.history_visible = false;
        }
        return 1;
    }

    let btn = button_at(g_ui.layout, fx, fy);
    if btn < 0 { return 1; }
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
    // Compute highlight from flash countdown, then tick it
    var highlight: i32 = -1;
    if g_ui.flash > 0 && g_ui.pressed >= 0 {
        highlight = g_ui.pressed;
        g_ui.flash -= 1;
        if g_ui.flash == 0 { g_ui.pressed = -1; }
    }
    draw_calculator(g_ui.layout, g_state, highlight);
    if g_ui.history_visible {
        draw_history(g_ui.layout, g_history);
    }
}

export fn goose_handle_back() -> i32 {
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
