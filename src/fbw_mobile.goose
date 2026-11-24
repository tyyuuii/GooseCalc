// fbw_mobile.goose — Mobile touch controls, HUD, modals, and GLES3 world sync for Fractal Block World.

import calc_bridge;
import fbw_bridge;
import fbw_core;

const MAX_POINTERS: i32 = 10;

// Touch event kinds matching main.c
const PTR_UP: i32 = 0;
const PTR_DOWN: i32 = 1;
const PTR_MOVE: i32 = 2;

// Action pad IDs
const ACT_NONE: i32 = 0;
const ACT_STICK: i32 = 1;
const ACT_LOOK: i32 = 2;
const ACT_FIRE: i32 = 3;
const ACT_ALT: i32 = 4;
const ACT_USE: i32 = 5;
const ACT_SHRINK: i32 = 6;
const ACT_GROW: i32 = 7;
const ACT_UP: i32 = 8;
const ACT_DOWN: i32 = 9;
const ACT_BRAKE: i32 = 10;
const ACT_ROLL_L: i32 = 11;
const ACT_ROLL_R: i32 = 12;
const ACT_TK: i32 = 13;

struct TouchPointer {
    active: i32,
    role: i32,
    start_x: i32,
    start_y: i32,
    cur_x: i32,
    cur_y: i32,
    last_x: i32,
    last_y: i32,
}

struct MobileLayout {
    w: i32,
    h: i32,
    stick_cx: i32,
    stick_cy: i32,
    stick_r: i32,
    // Action rectangles [x1, y1, x2, y2]
    fire_x1: i32, fire_y1: i32, fire_x2: i32, fire_y2: i32,
    alt_x1: i32,  alt_y1: i32,  alt_x2: i32,  alt_y2: i32,
    use_x1: i32,  use_y1: i32,  use_x2: i32,  use_y2: i32,
    shk_x1: i32,  shk_y1: i32,  shk_x2: i32,  shk_y2: i32,
    grw_x1: i32,  grw_y1: i32,  grw_x2: i32,  grw_y2: i32,
    tk_x1: i32,   tk_y1: i32,   tk_x2: i32,   tk_y2: i32,
    up_x1: i32,   up_y1: i32,   up_x2: i32,   up_y2: i32,
    dn_x1: i32,   dn_y1: i32,   dn_x2: i32,   dn_y2: i32,
    brk_x1: i32,  brk_y1: i32,  brk_x2: i32,  brk_y2: i32,
    rl_x1: i32,   rl_y1: i32,   rl_x2: i32,   rl_y2: i32,
    rr_x1: i32,   rr_y1: i32,   rr_x2: i32,   rr_y2: i32,
    wep_y1: i32,  wep_y2: i32,
    top_h: i32,
}

struct MobileController {
    initialized: i32,
    last_ms: i32,
    want_exit_to_calc: i32,
    ptrs: TouchPointer[10],
    lay: MobileLayout,
    // Cached chunk signature for dirty detection
    sync_depth: i32,
    sync_delta_head: i32,
    sync_parent_sig: i32,
    sync_force: i32,
    // Held continuous flags
    hold_up: i32,
    hold_dn: i32,
    hold_fire: i32,
    hold_roll_l: i32,
    hold_roll_r: i32,
    stick_dx: f64,
    stick_dy: f64,
}

var g_mob: MobileController;

fn compute_mobile_layout(w: i32, h: i32) -> MobileLayout {
    var l = MobileLayout {
        w: w, h: h,
        stick_cx: 0, stick_cy: 0, stick_r: 0,
        fire_x1: 0, fire_y1: 0, fire_x2: 0, fire_y2: 0,
        alt_x1: 0,  alt_y1: 0,  alt_x2: 0,  alt_y2: 0,
        use_x1: 0,  use_y1: 0,  use_x2: 0,  use_y2: 0,
        shk_x1: 0,  shk_y1: 0,  shk_x2: 0,  shk_y2: 0,
        grw_x1: 0,  grw_y1: 0,  grw_x2: 0,  grw_y2: 0,
        tk_x1: 0,   tk_y1: 0,   tk_x2: 0,   tk_y2: 0,
        up_x1: 0,   up_y1: 0,   up_x2: 0,   up_y2: 0,
        dn_x1: 0,   dn_y1: 0,   dn_x2: 0,   dn_y2: 0,
        brk_x1: 0,  brk_y1: 0,  brk_x2: 0,  brk_y2: 0,
        rl_x1: 0,   rl_y1: 0,   rl_x2: 0,   rl_y2: 0,
        rr_x1: 0,   rr_y1: 0,   rr_x2: 0,   rr_y2: 0,
        wep_y1: 0,  wep_y2: 0,
        top_h: 0,
    };

    let min_dim = if w < h { w } else { h };
    let u = clamp_i(min_dim / 12, 36, 92);

    l.top_h = clamp_i(h / 10, 56, 92);
    l.wep_y2 = h - 8;
    l.wep_y1 = l.wep_y2 - clamp_i(h / 10, 48, 76);

    // Left virtual flight stick
    l.stick_r = clamp_i((u * 145) / 100, 74, 150);
    l.stick_cx = 28 + l.stick_r;
    l.stick_cy = l.wep_y1 - 18 - l.stick_r;

    // Left vertical & roll pads above stick
    let bw = clamp_i((u * 95) / 100, 54, 110);
    let bh = clamp_i((u * 75) / 100, 44, 84);
    let gap: i32 = 10;

    l.rl_x1 = 22;
    l.rl_y1 = l.top_h + 14;
    l.rl_x2 = l.rl_x1 + bw;
    l.rl_y2 = l.rl_y1 + bh;

    l.rr_x1 = l.rl_x2 + gap;
    l.rr_y1 = l.rl_y1;
    l.rr_x2 = l.rr_x1 + bw;
    l.rr_y2 = l.rr_y1 + bh;

    l.up_x1 = l.rr_x2 + gap;
    l.up_y1 = l.rl_y1;
    l.up_x2 = l.up_x1 + bw;
    l.up_y2 = l.up_y1 + bh;

    l.dn_x1 = l.up_x1;
    l.dn_y1 = l.up_y2 + gap;
    l.dn_x2 = l.up_x2;
    l.dn_y2 = l.dn_y1 + bh;

    l.brk_x1 = l.stick_cx + l.stick_r + 16;
    l.brk_y1 = l.stick_cy + l.stick_r - bh;
    l.brk_x2 = l.brk_x1 + bw;
    l.brk_y2 = l.brk_y1 + bh;

    // Right action cluster
    let fire_sz = clamp_i((u * 145) / 100, 84, 156);
    let alt_sz = clamp_i((u * 105) / 100, 62, 118);
    l.fire_x2 = w - 24;
    l.fire_x1 = l.fire_x2 - fire_sz;
    l.fire_y2 = l.wep_y1 - 18;
    l.fire_y1 = l.fire_y2 - fire_sz;

    l.alt_x2 = l.fire_x1 - 14;
    l.alt_x1 = l.alt_x2 - alt_sz;
    l.alt_y2 = l.fire_y2;
    l.alt_y1 = l.alt_y2 - alt_sz;

    // Fractal & interaction buttons above FIRE / ALT
    l.shk_x2 = l.fire_x2;
    l.shk_x1 = l.shk_x2 - bw - 10;
    l.shk_y2 = l.fire_y1 - 12;
    l.shk_y1 = l.shk_y2 - bh;

    l.use_x2 = l.shk_x1 - gap;
    l.use_x1 = l.use_x2 - bw - 10;
    l.use_y2 = l.shk_y2;
    l.use_y1 = l.shk_y1;

    l.grw_x2 = l.shk_x2;
    l.grw_x1 = l.shk_x1;
    l.grw_y2 = l.shk_y1 - gap;
    l.grw_y1 = l.grw_y2 - bh;

    l.tk_x2 = l.use_x2;
    l.tk_x1 = l.use_x1;
    l.tk_y2 = l.grw_y2;
    l.tk_y1 = l.grw_y1;

    return l;
}

fn in_box(x: i32, y: i32, x1: i32, y1: i32, x2: i32, y2: i32) -> bool {
    return x >= x1 && x <= x2 && y >= y1 && y <= y2;
}

fn fbw_mobile_enter() {
    let st = core();
    g_mob.want_exit_to_calc = 0;
    if g_mob.initialized == 0 {
        st.rng = 0x4642575f4d4f4231 ^ (fbw_now_ms() as u64);
        st.genesis_mode = 0;
        st.true_up = 1;
        st.show_minimap = 1;
        init_new_game();
        g_mob.initialized = 1;
    }
    st.screen = SCREEN_PLAY;
    g_mob.last_ms = fbw_now_ms();
    g_mob.sync_force = 1;
    g_mob.hold_up = 0;
    g_mob.hold_dn = 0;
    g_mob.hold_fire = 0;
    g_mob.hold_roll_l = 0;
    g_mob.hold_roll_r = 0;
    g_mob.stick_dx = 0.0;
    g_mob.stick_dy = 0.0;
    var i: i32 = 0;
    while i < MAX_POINTERS {
        g_mob.ptrs[i].active = 0;
        g_mob.ptrs[i].role = ACT_NONE;
        i = i + 1;
    }
}

fn fbw_should_exit_to_calc() -> i32 {
    return g_mob.want_exit_to_calc;
}

fn fbw_clear_exit_flag() {
    g_mob.want_exit_to_calc = 0;
}

// ---------------------------------------------------------------------------
// Sync fbw_core state -> fbw_gl.c (integer-only FFI)
// ---------------------------------------------------------------------------

fn sync_chunks_to_gl() {
    let st = core();
    var p0_sig: i32 = st.depth * 31 + st.delta_head * 7;
    var p: i32 = 0;
    while p < 3 {
        p0_sig = p0_sig * 17 + st.parent_valid[p] + st.parent_bx[p] * 3 + st.parent_by[p] * 5 + st.parent_bz[p] * 11 + st.parent_biome[p] * 13;
        p = p + 1;
    }

    if g_mob.sync_force == 0 &&
       g_mob.sync_depth == st.depth &&
       g_mob.sync_delta_head == st.delta_head &&
       g_mob.sync_parent_sig == p0_sig {
        return;
    }

    g_mob.sync_force = 0;
    g_mob.sync_depth = st.depth;
    g_mob.sync_delta_head = st.delta_head;
    g_mob.sync_parent_sig = p0_sig;

    var q: i32 = 0;
    while q < 1024 {
        let base = q * 4;
        let b0 = st.blocks[base + 0] as! i32;
        let b1 = st.blocks[base + 1] as! i32;
        let b2 = st.blocks[base + 2] as! i32;
        let b3 = st.blocks[base + 3] as! i32;
        let packed = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
        fbw_gl_push_chunk_quad(0, q, packed);
        q = q + 1;
    }

    p = 0;
    while p < 3 {
        fbw_gl_set_parent_meta(p, st.parent_valid[p], st.parent_bx[p], st.parent_by[p], st.parent_bz[p], st.parent_biome[p]);
        if st.parent_valid[p] != 0 {
            let p_off = p * CHUNK_VOL;
            q = 0;
            while q < 1024 {
                let base = p_off + q * 4;
                let b0 = st.parent_blocks[base + 0] as! i32;
                let b1 = st.parent_blocks[base + 1] as! i32;
                let b2 = st.parent_blocks[base + 2] as! i32;
                let b3 = st.parent_blocks[base + 3] as! i32;
                let packed = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
                fbw_gl_push_chunk_quad(p + 1, q, packed);
                q = q + 1;
            }
        }
        p = p + 1;
    }

    fbw_gl_mark_chunks_dirty();
}

fn sync_dynamic_to_gl() {
    let st = core();
    fbw_gl_clear_dynamic();

    var i: i32 = 0;
    while i < MAX_ENTITIES {
        if st.entities[i].active != 0 {
            fbw_gl_push_entity(
                st.entities[i].kind,
                (st.entities[i].x * 1000.0) as! i32,
                (st.entities[i].y * 1000.0) as! i32,
                (st.entities[i].z * 1000.0) as! i32,
                st.entities[i].hp,
                st.entities[i].max_hp,
                st.entities[i].freeze_ms
            );
        }
        i = i + 1;
    }

    i = 0;
    while i < MAX_SHOTS {
        if st.shots[i].active != 0 {
            fbw_gl_push_shot(
                (st.shots[i].x * 1000.0) as! i32,
                (st.shots[i].y * 1000.0) as! i32,
                (st.shots[i].z * 1000.0) as! i32,
                st.shots[i].rgb as! i32
            );
        }
        i = i + 1;
    }

    i = 0;
    while i < MAX_PARTICLES {
        if st.particles[i].active != 0 {
            fbw_gl_push_particle(
                (st.particles[i].x * 1000.0) as! i32,
                (st.particles[i].y * 1000.0) as! i32,
                (st.particles[i].z * 1000.0) as! i32,
                st.particles[i].rgb as! i32
            );
        }
        i = i + 1;
    }

    if st.beam_timer_ms > 0 {
        fbw_gl_push_beam(
            1,
            (st.beam_x1 * 1000.0) as! i32,
            (st.beam_y1 * 1000.0) as! i32,
            (st.beam_z1 * 1000.0) as! i32,
            (st.beam_x2 * 1000.0) as! i32,
            (st.beam_y2 * 1000.0) as! i32,
            (st.beam_z2 * 1000.0) as! i32,
            st.beam_rgb as! i32
        );
    }
}

// ---------------------------------------------------------------------------
// Continuous Mobile Input + Simulation Tick
// ---------------------------------------------------------------------------

fn step_mobile_controls(dt_ms: i32) {
    let st = core();
    if st.screen != SCREEN_PLAY { return; }

    let dt_s = (dt_ms as f64) * 0.001;
    let thrust: f64 = 18.0 * dt_s;

    // Virtual flight stick -> camera-aligned forward + horizontal strafe
    if fabs(g_mob.stick_dx) > 0.08 || fabs(g_mob.stick_dy) > 0.08 {
        var fx: f64 = 0.0;
        var fy: f64 = 0.0;
        var fz: f64 = 0.0;
        camera_forward(fx, fy, fz);
        let sy = fsin(st.yaw);
        let cy = fcos(st.yaw);
        let rx = -sy;
        let rz = cy;
        let fwd = -g_mob.stick_dy * thrust;
        let strafe = g_mob.stick_dx * thrust;
        apply_thrust(fx * fwd + rx * strafe, fy * fwd, fz * fwd + rz * strafe);
    }

    if g_mob.hold_up != 0 {
        apply_thrust(0.0, thrust * 0.9, 0.0);
    }
    if g_mob.hold_dn != 0 {
        apply_thrust(0.0, -thrust * 0.9, 0.0);
    }
    if g_mob.hold_roll_l != 0 {
        st.roll = wrap_angle(st.roll - 1.8 * dt_s);
    }
    if g_mob.hold_roll_r != 0 {
        st.roll = wrap_angle(st.roll + 1.8 * dt_s);
    }
    if g_mob.hold_fire != 0 {
        if st.fire_cd_ms <= 0 {
            fire_weapon(0);
            fbw_sound_fx(if st.weapon == WEP_LASER || st.weapon == WEP_RAILGUN { 2 } else { 1 });
        }
    }
}

fn fbw_mobile_tick_and_draw(w: i32, h: i32) {
    let st = core();
    if g_mob.lay.w != w || g_mob.lay.h != h {
        g_mob.lay = compute_mobile_layout(w, h);
    }

    let now = fbw_now_ms();
    var dt_ms = now - g_mob.last_ms;
    g_mob.last_ms = now;
    if dt_ms < 1 { dt_ms = 16; }
    if dt_ms > 50 { dt_ms = 50; }

    let prev_depth = st.depth;
    let prev_delta = st.delta_head;

    if st.screen == SCREEN_PLAY {
        step_mobile_controls(dt_ms);
        step_simulation(dt_ms);
    } else {
        st.anim_ms = st.anim_ms + dt_ms;
    }

    if st.depth != prev_depth || st.delta_head != prev_delta {
        g_mob.sync_force = 1;
    }

    // 1. Hardware OpenGL ES 3.0 Pass
    sync_chunks_to_gl();
    sync_dynamic_to_gl();
    fbw_gl_set_viewport(w, h, st.depth, cur_biome(), st.flash_rgb as! i32, st.flash_ms);
    fbw_gl_set_camera(
        (st.px * 1000.0) as! i32,
        (st.py * 1000.0) as! i32,
        (st.pz * 1000.0) as! i32,
        (st.yaw * 1000.0) as! i32,
        (st.pitch * 1000.0) as! i32,
        (st.roll * 1000.0) as! i32,
        st.anim_ms as! i32
    );
    fbw_gl_render_3d();

    // 2. 2D CNFG Overlay: HUD + Touch Controls + Interactive Modals
    draw_mobile_hud(w, h);
    if st.screen == SCREEN_PLAY {
        draw_mobile_controls();
    } else {
        draw_mobile_modal(w, h);
    }
}

// ---------------------------------------------------------------------------
// 2D HUD, Crosshair, Minimap & Touch Controls Overlay
// ---------------------------------------------------------------------------

fn buf_str(buf: u8[160]&, len: i32&, s: const u8[:]) {
    var i: i32 = 0;
    let n = s.len as! i32;
    while i < n && len < 158 {
        buf[len] = s[i];
        len = len + 1;
        i = i + 1;
    }
}

fn buf_int(buf: u8[160]&, len: i32&, val_in: i32) {
    var v = val_in;
    if v < 0 {
        if len < 158 { buf[len] = '-'; len = len + 1; }
        v = -v;
    }
    var tmp: u8[16] = [0; 16];
    var tl: i32 = 0;
    if v == 0 {
        tmp[0] = '0'; tl = 1;
    } else {
        while v > 0 && tl < 16 {
            tmp[tl] = (0x30 + (v % 10)) as! u8;
            v = v / 10;
            tl = tl + 1;
        }
    }
    var i = tl - 1;
    while i >= 0 && len < 158 {
        buf[len] = tmp[i];
        len = len + 1;
        i = i - 1;
    }
}

fn wep_tag(w: i32) -> const u8[:] {
    if w == 0 { return "1:PLS"; }
    if w == 1 { return "2:CAN"; }
    if w == 2 { return "3:LSR"; }
    if w == 3 { return "4:RKT"; }
    if w == 4 { return "5:HOM"; }
    if w == 5 { return "6:MNG"; }
    if w == 6 { return "7:RAL"; }
    if w == 7 { return "8:EMP"; }
    if w == 8 { return "9:NUK"; }
    return "0:DRK";
}

fn draw_mobile_hud(w: i32, h: i32) {
    let st = core();
    let l = &g_mob.lay;

    // Top status bar
    fbw_box(0, 0, w, l.top_h, 0x0A101CE0, 0x22D3EE80);

    var b1: u8[160] = [0; 160];
    var n1: i32 = 0;
    buf_str(b1, n1, "HP "); buf_int(b1, n1, st.hp);
    buf_str(b1, n1, "/"); buf_int(b1, n1, st.max_hp);
    buf_str(b1, n1, "  ARM "); buf_int(b1, n1, st.armor);
    buf_str(b1, n1, "  G "); buf_int(b1, n1, st.gold);
    buf_str(b1, n1, "  K "); buf_int(b1, n1, st.keys);
    b1[n1] = 0;
    set_color(0xF8FAFCFF);
    fbw_text(14, 10, b1[0..n1], 3);

    var b2: u8[160] = [0; 160];
    var n2: i32 = 0;
    buf_str(b2, n2, biome_name(cur_biome()));
    buf_str(b2, n2, "  LVL "); buf_int(b2, n2, st.depth);
    buf_str(b2, n2, "  (");
    buf_int(b2, n2, ffloor(st.px)); buf_str(b2, n2, ",");
    buf_int(b2, n2, ffloor(st.py)); buf_str(b2, n2, ",");
    buf_int(b2, n2, ffloor(st.pz)); buf_str(b2, n2, ")");
    if st.genesis_mode != 0 { buf_str(b2, n2, " [GEN]"); }
    b2[n2] = 0;
    set_color(0x38BDF8FF);
    fbw_text(14, 38, b2[0..n2], 2);

    // Top-right quick utility buttons: [MAP] [RKT] [TRU] [MRK] [F1] [II]
    let btn_w = clamp_i(w / 14, 64, 96);
    let btn_h = l.top_h - 14;
    let gap: i32 = 6;
    var bx = w - 10 - btn_w;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, 0x334155EE, 0xFACC15FF);
    set_color(0xFACC15FF);
    fbw_text(bx + 10, 20, "MENU", 2);
    bx = bx - btn_w - gap;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, 0x1E293BEE, 0x38BDF8FF);
    set_color(0x38BDF8FF);
    fbw_text(bx + 12, 20, "INFO", 2);
    bx = bx - btn_w - gap;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, 0x1E293BEE, 0x4ADE80FF);
    set_color(0x4ADE80FF);
    fbw_text(bx + 12, 20, "MRK", 2);
    bx = bx - btn_w - gap;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, if st.true_up != 0 { 0x0E7490EE } else { 0x1E293BEE }, 0x38BDF8FF);
    set_color(0xFFFFFFFF);
    fbw_text(bx + 12, 20, "TRU", 2);
    bx = bx - btn_w - gap;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, if st.rocket_mode != 0 { 0xB45309EE } else { 0x1E293BEE }, 0xFB923CFF);
    set_color(0xFFFFFFFF);
    fbw_text(bx + 12, 20, "RKT", 2);
    bx = bx - btn_w - gap;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, if st.show_minimap != 0 { 0x065F46EE } else { 0x1E293BEE }, 0x4ADE80FF);
    set_color(0xFFFFFFFF);
    fbw_text(bx + 12, 20, "MAP", 2);

    // Center crosshair
    let cx = w / 2;
    let cy = h / 2;
    set_color(if st.near_prompt_len > 0 { 0xFACC15FF } else { 0xFFFFFFFF });
    draw_segment(cx - 12, cy, cx - 4, cy);
    draw_segment(cx + 4, cy, cx + 12, cy);
    draw_segment(cx, cy - 12, cx, cy - 4);
    draw_segment(cx, cy + 4, cx, cy + 12);

    // Proximity prompt or status toast
    if st.msg_ms > 0 && st.msg_len > 0 {
        let tw = fbw_text_w(st.msg_buf[0..st.msg_len], 2);
        let mx = (w - tw) / 2;
        fbw_box(mx - 12, l.top_h + 8, mx + tw + 12, l.top_h + 36, 0x0F172AE0, 0xFACC15AA);
        set_color(0xFACC15FF);
        fbw_text(mx, l.top_h + 14, st.msg_buf[0..st.msg_len], 2);
    } else if st.near_prompt_len > 0 {
        let tw = fbw_text_w(st.near_prompt[0..st.near_prompt_len], 2);
        let mx = (w - tw) / 2;
        fbw_box(mx - 12, l.top_h + 8, mx + tw + 12, l.top_h + 36, 0x0F172AE0, 0x4ADE80AA);
        set_color(0x4ADE80FF);
        fbw_text(mx, l.top_h + 14, st.near_prompt[0..st.near_prompt_len], 2);
    }

    // Compact corner minimap
    if st.show_minimap != 0 && w >= 600 {
        let cell: i32 = 6;
        let ms: i32 = 16 * cell;
        let mx = w - ms - 18;
        let my = l.top_h + 12;
        fbw_box(mx - 4, my - 4, mx + ms + 4, my + ms + 4, 0x080C18D8, 0x38BDF8AA);
        let py_i = clamp_i(ffloor(st.py), 1, 14);
        var z: i32 = 0;
        while z < 16 {
            var x: i32 = 0;
            while x < 16 {
                let blk = get_block(x, py_i, z);
                if blk != BLK_AIR {
                    set_color(if is_block_shrinkable(blk) != 0 { 0x38BDF8FF } else { 0x64748BFF });
                    draw_rect(mx + x * cell, my + z * cell, mx + (x + 1) * cell, my + (z + 1) * cell);
                }
                x = x + 1;
            }
            z = z + 1;
        }
        let px_i = clamp_i(ffloor(st.px), 0, 15);
        let pz_i = clamp_i(ffloor(st.pz), 0, 15);
        set_color(0xFACC15FF);
        draw_rect(mx + px_i * cell, my + pz_i * cell, mx + (px_i + 1) * cell, my + (pz_i + 1) * cell);
    }

    // Bottom 10-weapon touch strip
    let slot_w = (w - 28) / NUM_WEAPONS;
    var wi: i32 = 0;
    while wi < NUM_WEAPONS {
        let sx1 = 14 + wi * slot_w;
        let sx2 = sx1 + slot_w - 4;
        let active = (wi == st.weapon);
        let unlocked = (st.wep_unlocked[wi] != 0);
        let bg: u32 = if active { 0x2563EBEE } else if unlocked { 0x111827D8 } else { 0x090D16B0 };
        let bd: u32 = if active { 0xFACC15FF } else if unlocked { 0x475569FF } else { 0x1E293BFF };
        fbw_box(sx1, l.wep_y1, sx2, l.wep_y2, bg, bd);
        set_color(if unlocked { 0xF8FAFCFF } else { 0x64748BFF });
        fbw_text(sx1 + 6, l.wep_y1 + 8, wep_tag(wi), 2);
        if unlocked {
            var ab: u8[160] = [0; 160];
            var al: i32 = 0;
            if st.max_ammo[wi] > 9000 {
                buf_str(ab, al, "INF");
            } else {
                buf_int(ab, al, st.ammo[wi]);
            }
            ab[al] = 0;
            set_color(if active { 0xFDE047FF } else { 0x94A3B8FF });
            fbw_text(sx1 + 6, l.wep_y1 + 28, ab[0..al], 2);
        }
        wi = wi + 1;
    }
}

fn draw_pad_btn(x1: i32, y1: i32, x2: i32, y2: i32, label: const u8[:], fill: u32, border: u32) {
    fbw_box(x1, y1, x2, y2, fill, border);
    let tw = fbw_text_w(label, 2);
    let tx = (x1 + x2 - tw) / 2;
    let ty = (y1 + y2 - 16) / 2;
    set_color(0xFFFFFFFF);
    fbw_text(tx, ty, label, 2);
}

fn draw_mobile_controls() {
    let l = &g_mob.lay;

    // Left virtual flight stick base + thumb knob
    let sx1 = l.stick_cx - l.stick_r;
    let sy1 = l.stick_cy - l.stick_r;
    let sx2 = l.stick_cx + l.stick_r;
    let sy2 = l.stick_cy + l.stick_r;
    fbw_box(sx1, sy1, sx2, sy2, 0x0F172A70, 0x38BDF8B0);

    let kx = l.stick_cx + ((g_mob.stick_dx * (l.stick_r as f64) * 0.65) as! i32);
    let ky = l.stick_cy + ((g_mob.stick_dy * (l.stick_r as f64) * 0.65) as! i32);
    fbw_box(kx - 26, ky - 26, kx + 26, ky + 26, 0x38BDF8C0, 0xFFFFFFFF);

    // Left vertical & roll pads
    draw_pad_btn(l.rl_x1, l.rl_y1, l.rl_x2, l.rl_y2, "ROL-", if g_mob.hold_roll_l != 0 { 0x0284C7CC } else { 0x0F172A90 }, 0x64748BFF);
    draw_pad_btn(l.rr_x1, l.rr_y1, l.rr_x2, l.rr_y2, "ROL+", if g_mob.hold_roll_r != 0 { 0x0284C7CC } else { 0x0F172A90 }, 0x64748BFF);
    draw_pad_btn(l.up_x1, l.up_y1, l.up_x2, l.up_y2, "UP",   if g_mob.hold_up != 0 { 0x16A34ACC } else { 0x0F172A90 }, 0x4ADE80FF);
    draw_pad_btn(l.dn_x1, l.dn_y1, l.dn_x2, l.dn_y2, "DN",   if g_mob.hold_dn != 0 { 0x16A34ACC } else { 0x0F172A90 }, 0x4ADE80FF);
    draw_pad_btn(l.brk_x1, l.brk_y1, l.brk_x2, l.brk_y2, "BRK", 0x7C2D12B0, 0xFB923CFF);

    // Right action buttons
    draw_pad_btn(l.fire_x1, l.fire_y1, l.fire_x2, l.fire_y2, "FIRE", if g_mob.hold_fire != 0 { 0xDC2626E0 } else { 0x991B1BB8 }, 0xFCA5A5FF);
    draw_pad_btn(l.alt_x1, l.alt_y1, l.alt_x2, l.alt_y2, "ALT", 0x9A3412B8, 0xFDBA74FF);
    draw_pad_btn(l.use_x1, l.use_y1, l.use_x2, l.use_y2, "USE", 0x065F46B8, 0x4ADE80FF);
    draw_pad_btn(l.shk_x1, l.shk_y1, l.shk_x2, l.shk_y2, "SHRK", 0x1E40AFB8, 0x60A5FAFF);
    draw_pad_btn(l.grw_x1, l.grw_y1, l.grw_x2, l.grw_y2, "GROW", 0x831843B8, 0xF472B6FF);
    draw_pad_btn(l.tk_x1, l.tk_y1, l.tk_x2, l.tk_y2, "TK", 0x581C87B8, 0xC084FCFF);
}

// ---------------------------------------------------------------------------
// Touch-Interactive Modals (Buy / Sell / Black Market / Tome / Info / Pause / Victory)
// ---------------------------------------------------------------------------

fn draw_modal_row(mx: i32, y: i32, mw: i32, label: const u8[:], fill: u32, text_col: u32) {
    fbw_box(mx + 18, y, mx + mw - 18, y + 46, fill, 0x475569FF);
    set_color(text_col);
    fbw_text(mx + 30, y + 14, label, 2);
}

fn draw_mobile_modal(w: i32, h: i32) {
    let st = core();
    let mw = clamp_i((w * 72) / 100, 420, 760);
    let mh = clamp_i((h * 76) / 100, 320, 560);
    let mx = (w - mw) / 2;
    let my = (h - mh) / 2;

    fbw_box(mx, my, mx + mw, my + mh, 0x0B1220F2, 0x38BDF8FF);

    if st.screen == SCREEN_BUY {
        set_color(0x4ADE80FF);
        fbw_text(mx + 22, my + 16, "BUY STATION - TAP ITEM TO PURCHASE", 3);
        draw_modal_row(mx, my + 60,  mw, "[1] +40 Health (15g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 114, mw, "[2] +40 Armor (20g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 168, mw, "[3] Refill All Ammo (25g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 222, mw, "[4] +1 Damage Level (60g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 276, mw, "[5] +1 Speed / Fire Rate (55g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 330, mw, "[6] Unlock Next Weapon (90g)", 0x1E293BFF, 0xFACC15FF);
        draw_modal_row(mx, my + mh - 64, mw, "CLOSE STATION", 0x334155FF, 0x38BDF8FF);
    } else if st.screen == SCREEN_SELL {
        set_color(0xFACC15FF);
        fbw_text(mx + 22, my + 16, "SELL STATION - CONVERT SURPLUS TO GOLD", 3);
        draw_modal_row(mx, my + 70,  mw, "[1] Sell 40 Armor -> +25 Gold", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 130, mw, "[2] Sell 1 Key -> +60 Gold", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 190, mw, "[3] Sell Surplus Ammo -> +35 Gold", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + mh - 64, mw, "CLOSE STATION", 0x334155FF, 0x38BDF8FF);
    } else if st.screen == SCREEN_BLACK_MARKET {
        set_color(0xE879F9FF);
        fbw_text(mx + 22, my + 16, "BLACK MARKET - RARE ARTIFACTS", 3);
        draw_modal_row(mx, my + 70,  mw, "[1] Key (80g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 130, mw, "[2] EMP + Nuke Unlock (140g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 190, mw, "[3] Dark Hole Gun (220g)", 0x1E293BFF, 0xFACC15FF);
        draw_modal_row(mx, my + mh - 64, mw, "CLOSE BLACK MARKET", 0x334155FF, 0x38BDF8FF);
    } else if st.screen == SCREEN_TOME {
        set_color(0x38BDF8FF);
        fbw_text(mx + 22, my + 16, "XAR LORE TOME", 3);
        set_color(0xF8FAFCFF);
        fbw_text(mx + 22, my + 72, "Every block contains a 16x16x16 universe.", 2);
        fbw_text(mx + 22, my + 104, "Tap SHRK on portals or fly through green rings.", 2);
        fbw_text(mx + 22, my + 136, "Use GROW or red rings to climb outward scales.", 2);
        fbw_text(mx + 22, my + 168, "Descend to the Inner Core to rescue Friend K!", 2);
        draw_modal_row(mx, my + mh - 64, mw, "RESUME EXPLORATION", 0x1E3A8AFF, 0xFFFFFFFF);
    } else if st.screen == SCREEN_VICTORY {
        set_color(0xFACC15FF);
        fbw_text(mx + 22, my + 18, "VICTORY! FRIEND 'K' RESCUED!", 3);
        set_color(0xFFFFFFFF);
        fbw_text(mx + 22, my + 74, "The Singularity defeated! (+500 Gold & Quasar Drive)", 2);
        draw_modal_row(mx, my + 140, mw, "KEEP EXPLORING XAR", 0x065F46FF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 200, mw, "START NEW RUN", 0x1E3A8AFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 260, mw, "EXIT TO CALCULATOR", 0x7F1D1DFF, 0xFFFFFFFF);
    } else if st.screen == SCREEN_INFO_F1 || st.screen == SCREEN_INFO_F4 {
        set_color(0x38BDF8FF);
        fbw_text(mx + 22, my + 16, "MARKERS & XAR COMPENDIUM (TAP MARKER TO WARP)", 2);
        var i: i32 = 0;
        while i < 5 {
            var mb: u8[160] = [0; 160];
            var ml: i32 = 0;
            buf_str(mb, ml, "Marker "); buf_int(mb, ml, i); buf_str(mb, ml, ": ");
            if st.markers[i].used != 0 {
                buf_str(mb, ml, "LVL "); buf_int(mb, ml, st.markers[i].depth);
                buf_str(mb, ml, " "); buf_str(mb, ml, biome_name(st.markers[i].biome));
            } else {
                buf_str(mb, ml, "(Empty - tap MRK in HUD to drop)");
            }
            mb[ml] = 0;
            draw_modal_row(mx, my + 54 + i * 52, mw, mb[0..ml], 0x1E293BFF, if st.markers[i].used != 0 { 0x4ADE80FF } else { 0x94A3B8FF });
            i = i + 1;
        }
        draw_modal_row(mx, my + mh - 64, mw, "CLOSE GUIDE", 0x334155FF, 0xFFFFFFFF);
    } else {
        // SCREEN_PAUSE or fallback
        set_color(0x38BDF8FF);
        fbw_text(mx + 22, my + 18, "FRACTAL BLOCK WORLD - PAUSED", 3);
        draw_modal_row(mx, my + 70,  mw, "RESUME GAME", 0x065F46FF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 130, mw, if st.genesis_mode != 0 { "MODE: GENESIS (TAP FOR CLASSIC)" } else { "MODE: CLASSIC (TAP FOR GENESIS)" }, 0x1E3A8AFF, 0xFACC15FF);
        draw_modal_row(mx, my + 190, mw, if st.shrink_any != 0 { "SHRINK ANY: ON (TAP TO TOGGLE)" } else { "SHRINK ANY: OFF (TAP TO TOGGLE)" }, 0x312E81FF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 250, mw, "RESTART NEW RUN", 0x7C2D12FF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 310, mw, "EXIT TO GOOSECALC", 0x7F1D1DFF, 0xFFFFFFFF);
    }
}

fn handle_modal_tap(x: i32, y: i32) {
    let st = core();
    let w = g_mob.lay.w;
    let h = g_mob.lay.h;
    let mw = clamp_i((w * 72) / 100, 420, 760);
    let mh = clamp_i((h * 76) / 100, 320, 560);
    let mx = (w - mw) / 2;
    let my = (h - mh) / 2;

    if x < mx || x > mx + mw || y < my || y > my + mh {
        st.screen = SCREEN_PLAY;
        return;
    }

    if in_box(x, y, mx + 18, my + mh - 64, mx + mw - 18, my + mh - 18) &&
       st.screen != SCREEN_PAUSE && st.screen != SCREEN_VICTORY {
        st.screen = SCREEN_PLAY;
        return;
    }

    if st.screen == SCREEN_BUY {
        var r: i32 = 0;
        while r < 6 {
            let ry = my + 60 + r * 54;
            if y >= ry && y <= ry + 46 {
                handle_buy_action(r + 1);
                fbw_sound_fx(5);
                return;
            }
            r = r + 1;
        }
    } else if st.screen == SCREEN_SELL {
        var r: i32 = 0;
        while r < 3 {
            let ry = my + 70 + r * 60;
            if y >= ry && y <= ry + 46 {
                handle_sell_action(r + 1);
                fbw_sound_fx(5);
                return;
            }
            r = r + 1;
        }
    } else if st.screen == SCREEN_BLACK_MARKET {
        var r: i32 = 0;
        while r < 3 {
            let ry = my + 70 + r * 60;
            if y >= ry && y <= ry + 46 {
                handle_black_market_action(r + 1);
                fbw_sound_fx(5);
                return;
            }
            r = r + 1;
        }
    } else if st.screen == SCREEN_INFO_F1 || st.screen == SCREEN_INFO_F4 {
        var i: i32 = 0;
        while i < 5 {
            let ry = my + 54 + i * 52;
            if y >= ry && y <= ry + 46 {
                if warp_to_marker(i) != 0 {
                    st.screen = SCREEN_PLAY;
                    g_mob.sync_force = 1;
                    fbw_sound_fx(4);
                }
                return;
            }
            i = i + 1;
        }
    } else if st.screen == SCREEN_VICTORY {
        if y >= my + 140 && y <= my + 186 { st.screen = SCREEN_PLAY; return; }
        if y >= my + 200 && y <= my + 246 { init_new_game(); st.screen = SCREEN_PLAY; g_mob.sync_force = 1; return; }
        if y >= my + 260 && y <= my + 306 { g_mob.want_exit_to_calc = 1; return; }
    } else if st.screen == SCREEN_PAUSE {
        if y >= my + 70 && y <= my + 116 { st.screen = SCREEN_PLAY; return; }
        if y >= my + 130 && y <= my + 176 {
            st.genesis_mode = if st.genesis_mode != 0 { 0 } else { 1 };
            init_new_game();
            st.screen = SCREEN_PLAY;
            g_mob.sync_force = 1;
            return;
        }
        if y >= my + 190 && y <= my + 236 {
            st.shrink_any = if st.shrink_any != 0 { 0 } else { 1 };
            st.screen = SCREEN_PLAY;
            return;
        }
        if y >= my + 250 && y <= my + 296 {
            init_new_game();
            st.screen = SCREEN_PLAY;
            g_mob.sync_force = 1;
            return;
        }
        if y >= my + 310 && y <= my + 356 {
            g_mob.want_exit_to_calc = 1;
            return;
        }
    }
}

// ---------------------------------------------------------------------------
// Multi-Touch Pointer Handler (10-finger simultaneous stick + look + actions)
// ---------------------------------------------------------------------------

fn recompute_held_flags() {
    g_mob.hold_up = 0;
    g_mob.hold_dn = 0;
    g_mob.hold_fire = 0;
    g_mob.hold_roll_l = 0;
    g_mob.hold_roll_r = 0;
    g_mob.stick_dx = 0.0;
    g_mob.stick_dy = 0.0;

    let l = &g_mob.lay;
    var i: i32 = 0;
    while i < MAX_POINTERS {
        if g_mob.ptrs[i].active != 0 {
            let role = g_mob.ptrs[i].role;
            if role == ACT_UP { g_mob.hold_up = 1; }
            else if role == ACT_DOWN { g_mob.hold_dn = 1; }
            else if role == ACT_FIRE { g_mob.hold_fire = 1; }
            else if role == ACT_ROLL_L { g_mob.hold_roll_l = 1; }
            else if role == ACT_ROLL_R { g_mob.hold_roll_r = 1; }
            else if role == ACT_STICK {
                var dx = (g_mob.ptrs[i].cur_x - l.stick_cx) as f64;
                var dy = (g_mob.ptrs[i].cur_y - l.stick_cy) as f64;
                let r = if l.stick_r > 1 { l.stick_r as f64 } else { 100.0 };
                dx = fclamp(dx / r, -1.0, 1.0);
                dy = fclamp(dy / r, -1.0, 1.0);
                g_mob.stick_dx = dx;
                g_mob.stick_dy = dy;
            }
        }
        i = i + 1;
    }
}

fn handle_top_bar_tap(x: i32, y: i32) -> bool {
    let st = core();
    let l = &g_mob.lay;
    if y > l.top_h { return false; }

    let btn_w = clamp_i(l.w / 14, 64, 96);
    let gap: i32 = 6;
    var bx = l.w - 10 - btn_w;

    if x >= bx && x <= bx + btn_w {
        st.screen = if st.screen == SCREEN_PAUSE { SCREEN_PLAY } else { SCREEN_PAUSE };
        return true;
    }
    bx = bx - btn_w - gap;
    if x >= bx && x <= bx + btn_w {
        st.screen = if st.screen == SCREEN_INFO_F4 { SCREEN_PLAY } else { SCREEN_INFO_F4 };
        return true;
    }
    bx = bx - btn_w - gap;
    if x >= bx && x <= bx + btn_w {
        drop_marker(0);
        fbw_sound_fx(5);
        return true;
    }
    bx = bx - btn_w - gap;
    if x >= bx && x <= bx + btn_w {
        st.true_up = if st.true_up != 0 { 0 } else { 1 };
        set_status_msg(if st.true_up != 0 { "True Up ON" } else { "Free 3D Roll ON" }, 1100);
        return true;
    }
    bx = bx - btn_w - gap;
    if x >= bx && x <= bx + btn_w {
        st.rocket_mode = if st.rocket_mode != 0 { 0 } else { 1 };
        set_status_msg(if st.rocket_mode != 0 { "Rocket Mode ON" } else { "Rocket Mode OFF" }, 1100);
        return true;
    }
    bx = bx - btn_w - gap;
    if x >= bx && x <= bx + btn_w {
        st.show_minimap = if st.show_minimap != 0 { 0 } else { 1 };
        return true;
    }
    return true;
}

fn fbw_mobile_pointer(x: i32, y: i32, pid_in: i32, ev_type: i32) {
    let st = core();
    let pid = clamp_i(pid_in, 0, MAX_POINTERS - 1);
    let l = &g_mob.lay;

    if ev_type == PTR_DOWN {
        if st.screen != SCREEN_PLAY {
            handle_modal_tap(x, y);
            return;
        }
        if handle_top_bar_tap(x, y) {
            return;
        }

        // Bottom 10-weapon strip tap
        if y >= l.wep_y1 && y <= l.wep_y2 {
            let slot_w = (l.w - 28) / NUM_WEAPONS;
            if slot_w > 0 {
                let wi = clamp_i((x - 14) / slot_w, 0, NUM_WEAPONS - 1);
                st.weapon = wi;
                fbw_sound_fx(0);
            }
            return;
        }

        var role = ACT_NONE;
        if in_box(x, y, l.fire_x1, l.fire_y1, l.fire_x2, l.fire_y2) {
            role = ACT_FIRE;
            fire_weapon(0);
            fbw_sound_fx(if st.weapon == WEP_LASER || st.weapon == WEP_RAILGUN { 2 } else { 1 });
        } else if in_box(x, y, l.alt_x1, l.alt_y1, l.alt_x2, l.alt_y2) {
            role = ACT_ALT;
            fire_weapon(1);
            fbw_sound_fx(2);
        } else if in_box(x, y, l.use_x1, l.use_y1, l.use_x2, l.use_y2) {
            role = ACT_USE;
            use_nearest();
            fbw_sound_fx(4);
            g_mob.sync_force = 1;
        } else if in_box(x, y, l.shk_x1, l.shk_y1, l.shk_x2, l.shk_y2) {
            role = ACT_SHRINK;
            shrink_targeted_block();
            fbw_sound_fx(4);
            g_mob.sync_force = 1;
        } else if in_box(x, y, l.grw_x1, l.grw_y1, l.grw_x2, l.grw_y2) {
            role = ACT_GROW;
            grow_in_place();
            fbw_sound_fx(4);
            g_mob.sync_force = 1;
        } else if in_box(x, y, l.tk_x1, l.tk_y1, l.tk_x2, l.tk_y2) {
            role = ACT_TK;
            trigger_telekinesis();
            fbw_sound_fx(5);
        } else if in_box(x, y, l.up_x1, l.up_y1, l.up_x2, l.up_y2) {
            role = ACT_UP;
        } else if in_box(x, y, l.dn_x1, l.dn_y1, l.dn_x2, l.dn_y2) {
            role = ACT_DOWN;
        } else if in_box(x, y, l.brk_x1, l.brk_y1, l.brk_x2, l.brk_y2) {
            role = ACT_BRAKE;
            apply_brake();
        } else if in_box(x, y, l.rl_x1, l.rl_y1, l.rl_x2, l.rl_y2) {
            role = ACT_ROLL_L;
        } else if in_box(x, y, l.rr_x1, l.rr_y1, l.rr_x2, l.rr_y2) {
            role = ACT_ROLL_R;
        } else if in_box(x, y, l.stick_cx - l.stick_r - 24, l.stick_cy - l.stick_r - 24,
                         l.stick_cx + l.stick_r + 24, l.stick_cy + l.stick_r + 24) {
            role = ACT_STICK;
        } else {
            role = ACT_LOOK;
        }

        g_mob.ptrs[pid].active = 1;
        g_mob.ptrs[pid].role = role;
        g_mob.ptrs[pid].start_x = x;
        g_mob.ptrs[pid].start_y = y;
        g_mob.ptrs[pid].cur_x = x;
        g_mob.ptrs[pid].cur_y = y;
        g_mob.ptrs[pid].last_x = x;
        g_mob.ptrs[pid].last_y = y;
        recompute_held_flags();
    } else if ev_type == PTR_MOVE {
        if g_mob.ptrs[pid].active == 0 { return; }
        let dx = x - g_mob.ptrs[pid].last_x;
        let dy = y - g_mob.ptrs[pid].last_y;
        g_mob.ptrs[pid].last_x = x;
        g_mob.ptrs[pid].last_y = y;
        g_mob.ptrs[pid].cur_x = x;
        g_mob.ptrs[pid].cur_y = y;
        if g_mob.ptrs[pid].role == ACT_LOOK && st.screen == SCREEN_PLAY {
            st.yaw = wrap_angle(st.yaw + (dx as f64) * 0.0042);
            st.pitch = fclamp(st.pitch - (dy as f64) * 0.0042, -1.35, 1.35);
            st.turning_ms = 120;
        } else if g_mob.ptrs[pid].role == ACT_STICK {
            recompute_held_flags();
        }
    } else if ev_type == PTR_UP {
        g_mob.ptrs[pid].active = 0;
        g_mob.ptrs[pid].role = ACT_NONE;
        recompute_held_flags();
    }
}
