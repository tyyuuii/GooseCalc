// calc_hit.goose — pure hit-testing against Layout.

import calc_layout;

fn button_at(lay: const Layout&, x: f32, y: f32) -> i32 {
    for i in 0..20 {
        let r = &lay.buttons[i];
        if x >= r.x1 && x <= r.x2 && y >= r.y1 && y <= r.y2 {
            return i as i32;
        }
    }
    return -1;
}

fn in_hist_close(lay: const Layout&, x: f32, y: f32) -> bool {
    let p = &lay.hist_panel;
    // Must match the drawn rectangle exactly (draw_history):
    //   cx = p.x2 - CLOSE_SIZE - 10, cy = p.y1 + 10, size CLOSE_SIZE
    let cx = p.x2 - CLOSE_SIZE - 10.0;
    let cy = p.y1 + 10.0;
    return x >= cx && x <= cx + CLOSE_SIZE && y >= cy && y <= cy + CLOSE_SIZE;
}

fn in_hist_panel(lay: const Layout&, x: f32, y: f32) -> bool {
    let p = &lay.hist_panel;
    return x >= p.x1 && x <= p.x2 && y >= p.y1 && y <= p.y2;
}