// calc_bridge.goose — FFI only. Safe i32/u32 wrappers.
// NO other file touches CNFG or extern fn.

import ffi;
import os;

// === Raw CNFG — private to this file. Never exported. ===
extern fn CNFGTackRectangle(x1: f32, y1: f32, x2: f32, y2: f32);
extern fn CNFGTackSegment(x1: i16, y1: i16, x2: i16, y2: i16);
extern fn CNFGColor(rgba: u32);
extern fn CNFGDrawText(text: const u8[:], scale: f32);

// === Existing C accessors (visibility("default") on C side) ===
extern fn get_CNFGPenX() -> i32;
extern fn set_CNFGPenX(x: i32);
extern fn get_CNFGPenY() -> i32;
extern fn set_CNFGPenY(y: i32);
extern fn get_android_width() -> i32;
extern fn get_android_height() -> i32;
extern fn get_data_path() -> u64;
extern fn get_crash_text() -> u64;
extern fn get_crash_len() -> i32;
extern fn clear_crash();

// === New C shims — integer args only, float cast happens in C ===
extern fn goose_draw_rect(x1: i32, y1: i32, x2: i32, y2: i32);
// i32-only text protocol. No slices or pointers cross to C.
extern fn goose_text_clear();
extern fn goose_text_append(c: i32);
extern fn goose_text_draw(x: i32, y: i32, scale: i32);
extern fn goose_text_width(scale: i32) -> i32;

// === Public safe wrappers ===

fn draw_rect(x1: i32, y1: i32, x2: i32, y2: i32) {
    goose_draw_rect(x1, y1, x2, y2);
}

fn draw_segment(x1: i32, y1: i32, x2: i32, y2: i32) {
    CNFGTackSegment(x1 as i16, y1 as i16, x2 as i16, y2 as i16);
}

fn set_color(rgba: u32) {
    CNFGColor(rgba);
}

// Appends each byte to C's staging buffer, then triggers the draw.
// Only i32 crosses the FFI — no aggregate types, no pointers.
fn draw_text(x: i32, y: i32, s: u8[>..], scale: i32) {
    goose_text_clear();
    for i in 0..s.len {
        let c = s[i];
        if c == 0 { break; }
        goose_text_append(c as i32);
    }
    goose_text_draw(x, y, scale);
}

// Exact pixel width of the staged text (bitmap font, proportional advance).
fn text_width(s: u8[>..], scale: i32) -> i32 {
    goose_text_clear();
    for i in 0..s.len {
        let c = s[i];
        if c == 0 { break; }
        goose_text_append(c as i32);
    }
    return goose_text_width(scale);
}

fn screen_w() -> i32 { return get_android_width(); }
fn screen_h() -> i32 { return get_android_height(); }

fn data_path() -> u8[>..] {
    let p = get_data_path();
    if p == 0 { return []; }
    return ffi::cstr(p);
}

fn crash_text() -> u8[>..] {
    let p = get_crash_text();
    if p == 0 { return []; }
    return ffi::cstr(p);
}
fn crash_len() -> i32 { return get_crash_len(); }
fn crash_clear() { clear_crash(); }