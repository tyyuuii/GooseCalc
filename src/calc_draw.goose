// calc_draw.goose — all drawing. Imports layout/state/history/format/dispatch. No hit-testing.

import calc_bridge;
import calc_layout;
import calc_state;
import calc_history;
import calc_format;
import calc_dispatch;

fn text_centered_in(r: const Rect&, s: u8[>..], scale: i32) {
    // Exact pixel width from the baked bitmap font (proportional advances)
    let tw = text_width(copy(s), scale) as f32;
    let ch = CHAR_CELL * (scale as f32);
    let cx = (r.x1 + r.x2) * 0.5 - tw * 0.5;
    let cy = (r.y1 + r.y2) * 0.5 - ch * 0.5;
    draw_text(cx as i32, cy as i32, copy(s), scale);
}

fn draw_button(lay: const Layout&, i: i32, pressed: bool) {
    let r = &lay.buttons[i];
    set_color(if pressed { 0x808080FF } else { 0x404040FF });
    draw_rect(r.x1 as i32, r.y1 as i32, r.x2 as i32, r.y2 as i32);
    set_color(0xFFFFFFFF);
    draw_segment(r.x1 as i32, r.y1 as i32, r.x2 as i32, r.y1 as i32);
    draw_segment(r.x1 as i32, r.y1 as i32, r.x1 as i32, r.y2 as i32);
    let lbl = label_for(i);
    if lbl.len > 0 {
        text_centered_in(r, copy(lbl), SCALE_BUTTON);
    }
}

fn draw_calculator(lay: const Layout&, state: const CalcState&, highlight: i32) {
    let w = lay.width;
    let h = lay.height;
    let display_h = (h as f32 * DISPLAY_H_FRAC) as i32;
    set_color(0x101010FF);
    draw_rect(0, 0, w, h);
    set_color(0x000000FF);
    draw_rect(0, 0, w, display_h);
    set_color(0xFFFFFFFF);
    let disp = get_display(state);
    var disp_slice: u8[>..] = disp[..];
    // Auto-shrink: start at SCALE_DISPLAY, drop one cell per step until the
    // whole number fits between the paddings. Floor at scale 2.
    var scale = SCALE_DISPLAY;
    let max_w = (w as f32 - 2.0 * PAD) as i32;
    while scale > 2 && text_width(copy(disp_slice), scale) > max_w {
        scale -= 1;
    }
    let glyph_h = 8.0 * (scale as f32);
    let dy = (display_h as f32 * 0.5 - glyph_h * 0.5) as i32;
    // Right-aligned like a real calculator display
    var dx: i32 = (w as f32 - PAD - (text_width(copy(disp_slice), scale) as f32)) as i32;
    if dx < (PAD as i32) { dx = PAD as i32; }
    draw_text(dx, dy, copy(disp_slice), scale);
    for i in 0..BTN_COUNT {
        draw_button(lay, i, i == highlight);
    }
}

fn draw_history(lay: const Layout&, hist: const History&) {
    let w = lay.width;
    let h = lay.height;
    set_color(0x000000CC);
    draw_rect(0, 0, w, h);
    let p = &lay.hist_panel;
    set_color(0x202020FF);
    draw_rect(p.x1 as i32, p.y1 as i32, p.x2 as i32, p.y2 as i32);
    set_color(0xFFFFFFFF);
    draw_text((p.x1 + PAD) as i32, (p.y1 + PAD) as i32, "History", SCALE_HIST);

    let cs = CLOSE_SIZE;
    let cx = p.x2 - cs - 10.0;
    let cy = p.y1 + 10.0;
    set_color(0xFF0000FF);
    draw_rect(cx as i32, cy as i32, (cx + cs) as i32, (cy + cs) as i32);
    set_color(0xFFFFFFFF);
    draw_text((cx + 10.0) as i32, (cy + 10.0) as i32, "X", SCALE_HIST);

    let start_y = p.y1 + 60.0;
    let max_vis = ((p.y2 - p.y1 - 80.0) / HIST_ROW_H) as i32;
    if hist.count == 0 {
        set_color(0x808080FF);
        draw_text((p.x1 + PAD) as i32, (start_y + 10.0) as i32, "(empty)", SCALE_HIST);
        return;
    }
    var shown = 0;
    // Start at the NEWEST entry: ring writes at (head+count)%32, so newest
    // is head+count-1. Starting at head showed oldest-first and, after the
    // first entry, could read never-written slots.
    var idx = (hist.head + hist.count - 1) % 32;
    while shown < max_vis && shown < hist.count {
        let e = hist.entries[idx];
        let y = start_y + (shown as f32) * HIST_ROW_H;
        set_color(0xFFFFFFFF);
        if e.ok {
            var text_slice: u8[>..] = e.text[..];
            draw_text((p.x1 + PAD) as i32, (y + 5.0) as i32, copy(text_slice), SCALE_HIST);
        } else {
            draw_text((p.x1 + PAD) as i32, (y + 5.0) as i32, "Error", SCALE_HIST);
        }
        shown += 1;
        if idx == 0 { idx = 31; } else { idx -= 1; }
    }
}

fn draw_crash(lay: const Layout&) {
    let w = lay.width;
    let h = lay.height;
    set_color(0x000000FF);
    draw_rect(0, 0, w, h);
    set_color(0xFF0000FF);
    draw_rect(0, 0, w, CRASH_BANNER_H as i32);
    set_color(0xFFFFFFFF);
    draw_text((w as f32 * 0.5 - 100.0) as i32, 20, "CRASH DETECTED", SCALE_HIST);

    let ct = crash_text();
    if ct.len > 0 {
        var buf: u8[512] = [0; 512];
        let n = if ct.len < 511 { ct.len } else { 511 };
        for i in 0..n { buf[i] = ct[i]; }
        buf[n] = 0;
        var ct_slice: u8[>..] = buf[..];
        draw_text(20, 100, copy(ct_slice), SCALE_CRASH);
    }

    let bw = 200.0;
    let bh = 60.0;
    let bx = (w as f32 - bw) * 0.5;
    let by = (h as f32) - bh - 40.0;
    set_color(0xFF0000FF);
    draw_rect(bx as i32, by as i32, (bx + bw) as i32, (by + bh) as i32);
    set_color(0xFFFFFFFF);
    draw_text((bx + bw * 0.5 - 40.0) as i32, (by + bh * 0.5 - 15.0) as i32, "Dismiss", SCALE_HIST);
}