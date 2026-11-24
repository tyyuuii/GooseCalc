// fbw_bridge.goose — Integer-only FFI bridge to fbw_gl.c and main.c Android helpers.
// Zero f32/f64 or slice pointers cross the FFI boundary.

import ffi;
import calc_bridge;

extern fn fbw_set_orientation(landscape: i32);
extern fn fbw_now_ms() -> i32;
extern fn fbw_sound_fx(kind: i32);

extern fn fbw_gl_set_viewport(w: i32, h: i32, depth: i32, biome: i32, flash_rgb: i32, flash_ms: i32);
extern fn fbw_gl_set_camera(px_mm: i32, py_mm: i32, pz_mm: i32,
                              yaw_mrad: i32, pitch_mrad: i32, roll_mrad: i32, anim_ms: i32);

extern fn fbw_gl_set_parent_meta(layer: i32, valid: i32, bx: i32, by: i32, bz: i32, biome: i32);
extern fn fbw_gl_push_chunk_quad(layer: i32, qidx: i32, packed4: i32);
extern fn fbw_gl_mark_chunks_dirty();

extern fn fbw_gl_set_inward_meta(slot: i32, valid: i32, bx: i32, by: i32, bz: i32, biome: i32);
extern fn fbw_gl_push_inward_quad(slot: i32, qidx: i32, packed4: i32);
extern fn fbw_gl_set_l1_inward_meta(slot: i32, valid: i32, bx: i32, by: i32, bz: i32, biome: i32);
extern fn fbw_gl_push_l1_inward_quad(slot: i32, qidx: i32, packed4: i32);
extern fn fbw_gl_mark_inward_dirty();

extern fn fbw_gl_clear_dynamic();
extern fn fbw_gl_push_entity(kind: i32, x_mm: i32, y_mm: i32, z_mm: i32, hp: i32, max_hp: i32, freeze_ms: i32);
extern fn fbw_gl_push_shot(x_mm: i32, y_mm: i32, z_mm: i32, rgb: i32);
extern fn fbw_gl_push_particle(x_mm: i32, y_mm: i32, z_mm: i32, rgb: i32);
extern fn fbw_gl_push_beam(active: i32, x1_mm: i32, y1_mm: i32, z1_mm: i32,
                           x2_mm: i32, y2_mm: i32, z2_mm: i32, rgb: i32);

extern fn fbw_gl_render_3d();

fn fbw_text(x: i32, y: i32, s: const u8[:], scale: i32) {
    goose_text_clear();
    var i: i32 = 0;
    let n = s.len as! i32;
    while i < n {
        let c = s[i];
        if c == 0 { break; }
        goose_text_append(c as! i32);
        i = i + 1;
    }
    goose_text_draw(x, y, scale);
}

fn fbw_text_w(s: const u8[:], scale: i32) -> i32 {
    goose_text_clear();
    var i: i32 = 0;
    let n = s.len as! i32;
    while i < n {
        let c = s[i];
        if c == 0 { break; }
        goose_text_append(c as! i32);
        i = i + 1;
    }
    return goose_text_width(scale);
}

fn fbw_box(x1: i32, y1: i32, x2: i32, y2: i32, fill_rgba: u32, border_rgba: u32) {
    set_color(fill_rgba);
    draw_rect(x1, y1, x2, y2);
    set_color(border_rgba);
    draw_segment(x1, y1, x2, y1);
    draw_segment(x2, y1, x2, y2);
    draw_segment(x2, y2, x1, y2);
    draw_segment(x1, y2, x1, y1);
}
