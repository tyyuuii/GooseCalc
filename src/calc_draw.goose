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

// === Sudoku game drawing ===

fn draw_sudoku(lay: const Layout&, sudoku: const SudokuGame&, highlight: i32) {
    let w = lay.width;
    let h = lay.height;
    let board_h = (h as f32 * 0.60) as i32;
    let cell_w = w as f32 / 9.0;
    let cell_h = (board_h as f32) / 9.0;

    // Background
    set_color(0x101010FF);
    draw_rect(0, 0, w, h);
    set_color(0x000000FF);
    draw_rect(0, 0, w, board_h);

    // Mistake message overlay — takes priority, dims the board
    if sudoku.mistake_msg_timer > 0 {
        draw_mistake_dialog(w, h);
        return;
    }

    // Difficulty dialog overlay
    if sudoku.showing_difficulty || sudoku.game_over {
        draw_difficulty_dialog(w, h, sudoku);
        return;
    }

    // === Square board layout ===
    // Board is always square: size = min(width, height * 0.75)
    let board_size = if w as f32 < (h as f32 * 0.75) { w as f32 } else { h as f32 * 0.75 };
    let board_x = (w as f32 - board_size) * 0.5;
    let board_y = (h as f32 * 0.08);  // small top margin
    let cell_w = board_size / 9.0;
    let cell_h = board_size / 9.0;
    let board_h = board_size;

    // Background
    set_color(0x101010FF);
    draw_rect(0, 0, w, h);

    // Grid background (full board area)
    set_color(0x000000FF);
    draw_rect(board_x as i32, board_y as i32, (board_x + board_size) as i32, (board_y + board_h) as i32);

    // Grid lines — thicker every 3 cells
    var i = 0;
    while i < 10 {
        let x = board_x + (i as f32) * cell_w;
        let y = board_y + (i as f32) * cell_h;
        if i % 3 == 0 {
            set_color(0xFFFFFFFF);
        } else {
            set_color(0x606060FF);
        }
        draw_segment(x as i32, board_y as i32, x as i32, (board_y + board_h) as i32);
        draw_segment(board_x as i32, y as i32, (board_x + board_size) as i32, y as i32);
        i += 1;
    }

    // Determine which number to highlight (from selected cell)
    let hi_num = if sudoku.highlight_num >= 1 && sudoku.highlight_num <= 9 {
        sudoku.highlight_num
    } else {
        // Auto-highlight based on selected cell's value
        if sudoku.cursor >= 0 && sudoku.cursor < 81 {
            sudoku.values[sudoku.cursor]
        } else { 0 }
    };

    // Draw cell numbers
    i = 0;
    while i < 81 {
        let r = i / 9;
        let c = i % 9;
        let v = sudoku.values[i];
        if v != 0 {
            let cx = board_x + ((c as f32) + 0.5) * cell_w;
            let cy = board_y + ((r as f32) + 0.5) * cell_h;
            var buf: u8[>..] = [];
            buf.push((v as u8) + '0');

            // Determine color:
            // - wrong cells: red
            // - fixed cells: white
            // - user cells matching highlight: light blue
            // - normal user cells: green
            var col: u32 = 0xFFFFFFFF;
            if sudoku.wrong[i] != 0 {
                col = 0xFF0000FF;   // red — wrong number
            } else if sudoku.fixed[i] != 0 {
                col = 0xFFFFFFFF;   // white — fixed clue
            } else if hi_num > 0 && v == hi_num {
                col = 0x00BFFFFF;   // light blue — highlighted match
            } else {
                col = 0x00FF00FF;   // green — user entry
            }

            // Highlight glow: draw a soft background behind highlighted cells
            if hi_num > 0 && v == hi_num {
                let glow_w = cell_w * 0.70;
                let glow_h = cell_h * 0.70;
                let gx = board_x + ((c as f32) + 0.15) * cell_w;
                let gy = board_y + ((r as f32) + 0.15) * cell_h;
                set_color(0x00BFFF44);   // semi-transparent light blue glow
                draw_rect(gx as i32, gy as i32, (gx + glow_w) as i32, (gy + glow_h) as i32);
            }

            draw_text((cx - 4) as i32, (cy - 6) as i32, copy(buf), 6);
        }
        i += 1;
    }

    // Cursor highlight
    if sudoku.cursor >= 0 && sudoku.cursor < 81 {
        let cr = sudoku.cursor / 9;
        let cc = sudoku.cursor % 9;
        let x1 = board_x + (cc as f32) * cell_w;
        let y1 = board_y + (cr as f32) * cell_h;
        let x2 = x1 + cell_w;
        let y2 = y1 + cell_h;
        set_color(0x00FFFF00);
        draw_rect(x1 as i32, y1 as i32, x2 as i32, y2 as i32);
    }

    // Solved banner
    if sudoku.solved {
        set_color(0x00FF00FF);
        draw_text((board_x + board_size * 0.5 - 50) as i32, (board_y + board_h * 0.5 - 8) as i32, "SOLVED!", 6);
    }

    // Mistakes counter (top-right)
    var mstr: u8[>..] = [];
    mstr.push('M'); mstr.push('i'); mstr.push('s'); mstr.push('t'); mstr.push('a'); mstr.push('k'); mstr.push('e'); mstr.push('s'); mstr.push(':');
    mstr.push(' ');
    let m = sudoku.mistakes;
    if m == 0 { mstr.push('0'); }
    else {
        var md: u8[4] = [0; 4];
        var d = 0;
        var tmp = m;
        while tmp > 0 { md[d] = (tmp % 10) as u8 + '0'; tmp /= 10; d += 1; }
        while d > 0 { d -= 1; mstr.push(md[d]); }
    }
    mstr.push('/'); mstr.push('3');
    draw_text((w - 110) as i32, 20, copy(mstr), 4);

    // Separator line between board and buttons
    let btn_area_top = board_y + board_h;
    set_color(0xFFFFFFFF);
    draw_segment(0, btn_area_top as i32, w, btn_area_top as i32);

    // Sudoku buttons — square cells, centered below board
    let btn_area_h = (h as f32) - btn_area_top;
    let btn_cols: i32 = 4;
    let btn_rows: i32 = 3;
    let bw = w as f32 / (btn_cols as f32);
    let bh = btn_area_h / (btn_rows as f32);
    // Make buttons square-ish: use the smaller dimension for both width and height
    let cell_size = if bw < bh { bw } else { bh };
    let grid_w = cell_size * (btn_cols as f32);
    let grid_h = cell_size * (btn_rows as f32);
    let grid_x = (w as f32 - grid_w) * 0.5;
    let grid_y = btn_area_top + (btn_area_h - grid_h) * 0.5;

    // Button indices that have labels, in reading order
    let btn_order: i32[12] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 12, 16, 17];

    var bi = 0;
    while bi < 12 {
        let btn = btn_order[bi];
        let lbl = label_for_sudoku(btn);
        if lbl.len > 0 {
            let row = bi / 4;
            let col = bi % 4;
            let x1 = grid_x + (col as f32) * cell_size;
            let y1 = grid_y + (row as f32) * cell_size;
            let x2 = x1 + cell_size;
            let y2 = y1 + cell_size;

            // Press feedback: lighter color when button is flashed
            let pressed = highlight == btn;
            var r = Rect { x1: x1, y1: y1, x2: x2, y2: y2 };
            set_color(if pressed { 0x808080FF } else { 0x404040FF });
            draw_rect(x1 as i32, y1 as i32, x2 as i32, y2 as i32);
            set_color(0xFFFFFFFF);
            draw_segment(x1 as i32, y1 as i32, x2 as i32, y1 as i32);
            draw_segment(x1 as i32, y1 as i32, x1 as i32, y2 as i32);
            text_centered_in(r, copy(lbl), SCALE_BUTTON);
        }
        bi += 1;
    }
}

// === Difficulty dialog drawing ===

fn draw_difficulty_dialog(w: i32, h: i32, sudoku: const SudokuGame&) {
    let dlg_w = (w as f32 * 0.70);
    let dlg_h = (h as f32 * 0.45);
    let dlg_x = (w as f32 - dlg_w) * 0.5;
    let dlg_y = (h as f32 - dlg_h) * 0.5;

    // Dim background
    set_color(0x00000088);
    draw_rect(0, 0, w, h);

    // Dialog panel
    set_color(0x202020FF);
    draw_rect(dlg_x as i32, dlg_y as i32, (dlg_x + dlg_w) as i32, (dlg_y + dlg_h) as i32);
    set_color(0xFFFFFFFF);
    draw_segment(dlg_x as i32, dlg_y as i32, (dlg_x + dlg_w) as i32, dlg_y as i32);
    draw_segment(dlg_x as i32, dlg_y as i32, dlg_x as i32, (dlg_y + dlg_h) as i32);

    // Title
    set_color(0xFFFFFF00);
    var title_buf: u8[>..] = [];
    title_buf.push('S'); title_buf.push('U'); title_buf.push('D'); title_buf.push('O'); title_buf.push('K'); title_buf.push('U');
    let tw = text_width(copy(title_buf), 6);
    draw_text((dlg_x + dlg_w * 0.5 - (tw as f32) * 0.5) as i32, (dlg_y + 40) as i32, copy(title_buf), 6);

    if sudoku.game_over {
        set_color(0xFF0000FF);
        var go_buf: u8[>..] = [];
        for ch in "3 MISTAKES — GAME OVER" {
            go_buf.push(ch);
        }
        let tw2 = text_width(copy(go_buf), 4);
        draw_text((dlg_x + dlg_w * 0.5 - (tw2 as f32) * 0.5) as i32, (dlg_y + 80) as i32, copy(go_buf), 4);
    }

    // Subtitle
    set_color(0xFFFFFFFF);
    var sub_buf: u8[>..] = [];
    for ch in "Choose difficulty:" {
        sub_buf.push(ch);
    }
    let tw3 = text_width(copy(sub_buf), 4);
    draw_text((dlg_x + dlg_w * 0.5 - (tw3 as f32) * 0.5) as i32, (dlg_y + dlg_h * 0.30) as i32, copy(sub_buf), 4);

    let btn_w = dlg_w * 0.40;
    let btn_h = dlg_h * 0.12;
    let btn_x = dlg_x + (dlg_w - btn_w) * 0.5;

    // Easy
    let easy_y = dlg_y + dlg_h * 0.50;
    set_color(0x00AA00FF);
    draw_rect(btn_x as i32, easy_y as i32, (btn_x + btn_w) as i32, (easy_y + btn_h) as i32);
    set_color(0xFFFFFFFF);
    var easy_buf: u8[>..] = [];
    for ch in "1 - EASY" {
        easy_buf.push(ch);
    }
    let tw4 = text_width(copy(easy_buf), 5);
    draw_text((btn_x + btn_w * 0.5 - (tw4 as f32) * 0.5) as i32, (easy_y + 8) as i32, copy(easy_buf), 5);

    // Medium
    let med_y = dlg_y + dlg_h * 0.66;
    set_color(0xAAAA00FF);
    draw_rect(btn_x as i32, med_y as i32, (btn_x + btn_w) as i32, (med_y + btn_h) as i32);
    set_color(0xFFFFFFFF);
    var med_buf: u8[>..] = [];
    for ch in "2 - MEDIUM" {
        med_buf.push(ch);
    }
    let tw5 = text_width(copy(med_buf), 5);
    draw_text((btn_x + btn_w * 0.5 - (tw5 as f32) * 0.5) as i32, (med_y + 8) as i32, copy(med_buf), 5);

    // Hard
    let hard_y = dlg_y + dlg_h * 0.82;
    set_color(0xAA0000FF);
    draw_rect(btn_x as i32, hard_y as i32, (btn_x + btn_w) as i32, (hard_y + btn_h) as i32);
    set_color(0xFFFFFFFF);
    var hard_buf: u8[>..] = [];
    for ch in "3 - HARD" {
        hard_buf.push(ch);
    }
    let tw6 = text_width(copy(hard_buf), 5);
    draw_text((btn_x + btn_w * 0.5 - (tw6 as f32) * 0.5) as i32, (hard_y + 8) as i32, copy(hard_buf), 5);
}

// === Mistake message dialog ===

fn draw_mistake_dialog(w: i32, h: i32) {
    let dlg_w = (w as f32 * 0.50);
    let dlg_h = (h as f32 * 0.20);
    let dlg_x = (w as f32 - dlg_w) * 0.5;
    let dlg_y = (h as f32 - dlg_h) * 0.5;

    // Dim background
    set_color(0x000000AA);
    draw_rect(0, 0, w, h);

    // Dialog panel
    set_color(0x202020FF);
    draw_rect(dlg_x as i32, dlg_y as i32, (dlg_x + dlg_w) as i32, (dlg_y + dlg_h) as i32);
    set_color(0xFFFFFFFF);
    draw_segment(dlg_x as i32, dlg_y as i32, (dlg_x + dlg_w) as i32, dlg_y as i32);
    draw_segment(dlg_x as i32, dlg_y as i32, dlg_x as i32, (dlg_y + dlg_h) as i32);

    // Message — center properly using text_width
    let msg = "You made a mistake!";
    var msg_buf: u8[>..] = [];
    var mi = 0;
    while mi < msg.len {
        msg_buf.push(msg[mi]);
        mi += 1;
    }
    let tw = text_width(copy(msg_buf), 5);
    let msg_x = (dlg_x + dlg_w * 0.5 - (tw as f32) * 0.5) as i32;
    let msg_y = (dlg_y + dlg_h * 0.5 - 8) as i32;
    set_color(0xFF0000FF);
    draw_text(msg_x, msg_y, copy(msg_buf), 5);
}