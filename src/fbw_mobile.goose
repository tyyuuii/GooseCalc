// fbw_mobile.goose — Mobile touch controls, HUD, modals, and GLES world sync for Fractal Block World.

import calc_bridge;
import fbw_bridge;
import fbw_core;

const MAX_POINTERS: i32 = 10;
const MAX_INWARD_GL: i32 = 256;
const MAX_L1_INWARD_GL: i32 = 64;
const LOD_NORM_L0_CAP: i32 = 64;
const LOD_NORM_L1_CAP: i32 = 16;

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
    // Chunk + Inward LOD cache for dirty detection
    sync_depth: i32,
    sync_rev: i32,
    sync_force: i32,
    inw_force: i32,
    inw_qpx: i32,
    inw_qpy: i32,
    inw_qpz: i32,
    inw_qyaw: i32,
    inw_qpitch: i32,
    inw_qlod: i32,
    inw_qlod_dist: i32,
    inw_qrev: i32,
    inw_pending: i32,
    frame_tick: i32,
    inw_valid: i32[256],
    inw_bx: i32[256],
    inw_by: i32[256],
    inw_bz: i32[256],
    inw_blk: u8[256],
    inw_seed: u64[256],
    inw_last_seen: i32[256],
    l1_inw_valid: i32[64],
    l1_inw_bx: i32[64],
    l1_inw_by: i32[64],
    l1_inw_bz: i32[64],
    l1_inw_blk: u8[64],
    l1_inw_seed: u64[64],
    l1_inw_last_seen: i32[64],
    l0_slot_grid: i32[4096],
    l1_slot_grid: i32[4096],
    // BSS scratch arrays for inward candidate selection (avoid large stack allocs)
    cand_x: i32[256],
    cand_y: i32[256],
    cand_z: i32[256],
    cand_sc: f64[256],
    cand_pin: i32[256],
    l1_cand_x: i32[64],
    l1_cand_y: i32[64],
    l1_cand_z: i32[64],
    l1_cand_sc: f64[64],
    l1_cand_pin: i32[64],
    // Held continuous flags
    hold_up: i32,
    hold_dn: i32,
    hold_fire: i32,
    hold_roll_l: i32,
    hold_roll_r: i32,
    stick_dx: f64,
    stick_dy: f64,
    info_marker_page: i32,
    fps_ms: i32,
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
    l.rr_y2 = l.rl_y1 + bh;

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
        st.lod_dist_level = 4;
        st.view_chunk_radius = 2;
        init_new_game();
        g_mob.initialized = 1;
    }
    if st.lod_dist_level < 1 || st.lod_dist_level > 7 {
        st.lod_dist_level = 4;
    }
    if st.view_chunk_radius < 1 || st.view_chunk_radius > 3 {
        st.view_chunk_radius = 2;
        load_current_chunk();
        g_mob.sync_force = 1;
    }
    st.screen = SCREEN_PLAY;
    g_mob.last_ms = fbw_now_ms();
    g_mob.sync_force = 1;
    g_mob.inw_force = 1;
    g_mob.inw_pending = 0;
    g_mob.frame_tick = 1;
    g_mob.inw_qlod_dist = 0;
    g_mob.hold_up = 0;
    g_mob.hold_dn = 0;
    g_mob.hold_fire = 0;
    g_mob.hold_roll_l = 0;
    g_mob.hold_roll_r = 0;
    g_mob.stick_dx = 0.0;
    g_mob.stick_dy = 0.0;
    g_mob.info_marker_page = 0;
    g_mob.fps_ms = g_mob.last_ms;
    st.frame_cnt = 0;
    st.fps = 60;
    var i: i32 = 0;
    while i < MAX_POINTERS {
        g_mob.ptrs[i].active = 0;
        g_mob.ptrs[i].role = ACT_NONE;
        i = i + 1;
    }
    i = 0;
    while i < 4096 {
        g_mob.l0_slot_grid[i] = -1;
        g_mob.l1_slot_grid[i] = -1;
        i = i + 1;
    }
    i = 0;
    while i < MAX_INWARD_GL {
        g_mob.inw_valid[i] = 0;
        g_mob.inw_last_seen[i] = 0;
        fbw_gl_set_inward_meta(i, 0, 0, 0, 0, 0);
        i = i + 1;
    }
    i = 0;
    while i < MAX_L1_INWARD_GL {
        g_mob.l1_inw_valid[i] = 0;
        g_mob.l1_inw_last_seen[i] = 0;
        fbw_gl_set_l1_inward_meta(i, 0, 0, 0, 0, 0);
        i = i + 1;
    }
    fbw_gl_mark_inward_dirty();
}

fn fbw_should_exit_to_calc() -> i32 {
    return g_mob.want_exit_to_calc;
}

fn fbw_clear_exit_flag() {
    g_mob.want_exit_to_calc = 0;
}

// ---------------------------------------------------------------------------
// Sync fbw_core state -> fbw_gl.c (5 parent layers + Inward 1/16x LOD)
// ---------------------------------------------------------------------------

fn sync_chunks_to_gl() {
    let st = core();
    var full = 0;
    if g_mob.sync_force != 0 ||
       g_mob.sync_depth != st.depth ||
       g_mob.sync_rev != st.chunk_rev {
        full = 1;
    } else {
        // Streaming light pass: push only slots whose data changed this frame
        var sd: i32 = 0;
        var pushed: i32 = 0;
        while sd < MAX_NEIGHBORS {
            if st.neighbor_dirty[sd] != 0 {
                push_neighbor_slot(sd);
                pushed = pushed + 1;
            }
            sd = sd + 1;
        }
        if pushed > 0 { fbw_gl_mark_chunks_dirty(); }
        return;
    }

    g_mob.sync_force = 0;
    g_mob.sync_depth = st.depth;
    g_mob.sync_rev = st.chunk_rev;
    g_mob.inw_force = 1;

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

    var p: i32 = 0;
    while p < 5 {
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

    var nb: i32 = 0;
    while nb < MAX_NEIGHBORS {
        push_neighbor_slot(nb);
        nb = nb + 1;
    }

    fbw_gl_mark_chunks_dirty();
}

// Push one neighbor slot to the renderer (meta + quads). Empty chunks (all air)
// are reported invalid so the C side never meshes them; zero-packed quads are
// skipped because fbw_gl_set_neighbor_meta clears the slot buffer first.
fn push_neighbor_slot(nb: i32) {
    let st = core();
    let filled = st.neighbor_fill[nb];
    let valid = if filled != 0 { st.neighbor_valid[nb] } else { 0 };
    fbw_gl_set_neighbor_meta(nb, valid, st.neighbor_dx[nb], st.neighbor_dy[nb], st.neighbor_dz[nb], st.neighbor_biome[nb]);
    if valid != 0 {
        let n_off = nb * CHUNK_VOL;
        var q: i32 = 0;
        while q < 1024 {
            let base = n_off + q * 4;
            let b0 = st.neighbor_blocks[base + 0] as! i32;
            let b1 = st.neighbor_blocks[base + 1] as! i32;
            let b2 = st.neighbor_blocks[base + 2] as! i32;
            let b3 = st.neighbor_blocks[base + 3] as! i32;
            let packed = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
            if packed != 0 { fbw_gl_push_neighbor_quad(nb, q, packed); }
            q = q + 1;
        }
    }
    st.neighbor_dirty[nb] = 0;
}

fn layer0_block_exposed(x: i32, y: i32, z: i32) -> i32 {
    if (x < 15 && get_block(x + 1, y, z) == BLK_AIR) ||
       (x > 0  && get_block(x - 1, y, z) == BLK_AIR) ||
       (y < 15 && get_block(x, y + 1, z) == BLK_AIR) ||
       (y > 0  && get_block(x, y - 1, z) == BLK_AIR) ||
       (z < 15 && get_block(x, y, z + 1) == BLK_AIR) ||
       (z > 0  && get_block(x, y, z - 1) == BLK_AIR) {
        return 2;
    }
    if x == 0 || x == 15 || y == 0 || y == 15 || z == 0 || z == 15 { return 1; }
    return 0;
}

fn l1_blk_at(x: i32, y: i32, z: i32) -> u8 {
    let st = core();
    return st.parent_blocks[(y << 8) | (z << 4) | x];
}

fn is_l1_covered_by_neighbor(x: i32, y: i32, z: i32, hx: i32, hy: i32, hz: i32) -> i32 {
    let st = core();
    let dx = x - hx;
    let dy = y - hy;
    let dz = z - hz;
    var nb: i32 = 0;
    while nb < MAX_NEIGHBORS {
        if st.neighbor_valid[nb] != 0 &&
           st.neighbor_dx[nb] == dx && st.neighbor_dy[nb] == dy && st.neighbor_dz[nb] == dz {
            return 1;
        }
        nb = nb + 1;
    }
    return 0;
}

fn layer1_block_exposed(x: i32, y: i32, z: i32, hx: i32, hy: i32, hz: i32) -> i32 {
    if x < 15 {
        if l1_blk_at(x + 1, y, z) == BLK_AIR || (x + 1 == hx && y == hy && z == hz) ||
           is_l1_covered_by_neighbor(x + 1, y, z, hx, hy, hz) != 0 { return 2; }
    }
    if x > 0 {
        if l1_blk_at(x - 1, y, z) == BLK_AIR || (x - 1 == hx && y == hy && z == hz) ||
           is_l1_covered_by_neighbor(x - 1, y, z, hx, hy, hz) != 0 { return 2; }
    }
    if y < 15 {
        if l1_blk_at(x, y + 1, z) == BLK_AIR || (x == hx && y + 1 == hy && z == hz) ||
           is_l1_covered_by_neighbor(x, y + 1, z, hx, hy, hz) != 0 { return 2; }
    }
    if y > 0 {
        if l1_blk_at(x, y - 1, z) == BLK_AIR || (x == hx && y - 1 == hy && z == hz) ||
           is_l1_covered_by_neighbor(x, y - 1, z, hx, hy, hz) != 0 { return 2; }
    }
    if z < 15 {
        if l1_blk_at(x, y, z + 1) == BLK_AIR || (x == hx && y == hy && z + 1 == hz) ||
           is_l1_covered_by_neighbor(x, y, z + 1, hx, hy, hz) != 0 { return 2; }
    }
    if z > 0 {
        if l1_blk_at(x, y, z - 1) == BLK_AIR || (x == hx && y == hy && z - 1 == hz) ||
           is_l1_covered_by_neighbor(x, y, z - 1, hx, hy, hz) != 0 { return 2; }
    }
    if x == 0 || x == 15 || y == 0 || y == 15 || z == 0 || z == 15 { return 1; }
    return 0;
}

fn block_on_screen(
    dx: f64, dy: f64, dz: f64, r_blk: f64,
    fx: f64, fy: f64, fz: f64,
    rx: f64, ry: f64, rz: f64,
    ux: f64, uy: f64, uz: f64,
    tan_x: f64, tan_y: f64
) -> i32 {
    let vz = dx * fx + dy * fy + dz * fz;
    if vz + r_blk * 1.35 < 0.0 { return 0; }
    let vx = dx * rx + dy * ry + dz * rz;
    let vy = dx * ux + dy * uy + dz * uz;
    if vz <= 0.25 {
        return if fabs(vx) <= r_blk * 1.75 && fabs(vy) <= r_blk * 1.75 { 1 } else { 0 };
    }
    if fabs(vx) <= vz * tan_x + r_blk * 1.45 && fabs(vy) <= vz * tan_y + r_blk * 1.45 {
        return 1;
    }
    return 0;
}

fn sync_inward_to_gl() {
    let st = core();
    let qpx = ffloor(st.px * 2.0);
    let qpy = ffloor(st.py * 2.0);
    let qpz = ffloor(st.pz * 2.0);
    let qyaw = ffloor(st.yaw * 3.0);
    let qpitch = ffloor(st.pitch * 3.0);
    let qlod = st.disable_lod;
    let qlod_dist = clamp_i(st.lod_dist_level, 1, 7);
    if g_mob.inw_force == 0 &&
       g_mob.inw_pending == 0 &&
       g_mob.inw_qrev == st.chunk_rev &&
       g_mob.inw_qpx == qpx && g_mob.inw_qpy == qpy && g_mob.inw_qpz == qpz &&
       g_mob.inw_qyaw == qyaw && g_mob.inw_qpitch == qpitch &&
       g_mob.inw_qlod == qlod && g_mob.inw_qlod_dist == qlod_dist {
        return;
    }
    let was_forced = g_mob.inw_force != 0;
    let rev_changed = g_mob.inw_qrev != st.chunk_rev;
    g_mob.inw_force = 0;
    g_mob.inw_qrev = st.chunk_rev;
    g_mob.inw_qpx = qpx;
    g_mob.inw_qpy = qpy;
    g_mob.inw_qpz = qpz;
    g_mob.inw_qyaw = qyaw;
    g_mob.inw_qpitch = qpitch;
    g_mob.inw_qlod = qlod;
    g_mob.inw_qlod_dist = qlod_dist;
    g_mob.frame_tick = g_mob.frame_tick + 1;
    let tick = g_mob.frame_tick;

    let pseed = cur_seed();
    let pdepth = st.depth;
    let pbio = cur_biome();
    let l1_seed = st.parent_seed[0];
    let l1_depth = st.parent_depth[0];
    let l1_bio = st.parent_biome[0];
    var any_dirty: i32 = 0;

    // Revalidate pinned slots only when chunk_rev changed (block edited or scale shifted)
    if rev_changed {
        var rs: i32 = 0;
        while rs < MAX_INWARD_GL {
            if g_mob.inw_valid[rs] != 0 {
                let ox = g_mob.inw_bx[rs];
                let oy = g_mob.inw_by[rs];
                let oz = g_mob.inw_bz[rs];
                let nblk = get_block(ox, oy, oz);
                let nseed = resolve_child_frame_seed(pseed, pdepth, ox, oy, oz, nblk);
                if nblk == BLK_AIR || is_block_subdivisible(nblk) == 0 ||
                   nblk != g_mob.inw_blk[rs] || nseed != g_mob.inw_seed[rs] {
                    let oidx = (oy << 8) | (oz << 4) | ox;
                    if g_mob.l0_slot_grid[oidx] == rs { g_mob.l0_slot_grid[oidx] = -1; }
                    g_mob.inw_valid[rs] = 0;
                    fbw_gl_set_inward_meta(rs, 0, 0, 0, 0, 0);
                    any_dirty = 1;
                }
            }
            rs = rs + 1;
        }
        rs = 0;
        let l1_v = st.parent_valid[0];
        let l1_hx = st.parent_bx[0];
        let l1_hy = st.parent_by[0];
        let l1_hz = st.parent_bz[0];
        while rs < MAX_L1_INWARD_GL {
            if g_mob.l1_inw_valid[rs] != 0 {
                let ox = g_mob.l1_inw_bx[rs];
                let oy = g_mob.l1_inw_by[rs];
                let oz = g_mob.l1_inw_bz[rs];
                let nblk = l1_blk_at(ox, oy, oz);
                let nseed = resolve_child_frame_seed(l1_seed, l1_depth, ox, oy, oz, nblk);
                if l1_v == 0 || (ox == l1_hx && oy == l1_hy && oz == l1_hz) ||
                   is_l1_covered_by_neighbor(ox, oy, oz, l1_hx, l1_hy, l1_hz) != 0 ||
                   nblk == BLK_AIR || is_block_subdivisible(nblk) == 0 ||
                   nblk != g_mob.l1_inw_blk[rs] || nseed != g_mob.l1_inw_seed[rs] {
                    let oidx = (oy << 8) | (oz << 4) | ox;
                    if g_mob.l1_slot_grid[oidx] == rs { g_mob.l1_slot_grid[oidx] = -1; }
                    g_mob.l1_inw_valid[rs] = 0;
                    fbw_gl_set_l1_inward_meta(rs, 0, 0, 0, 0, 0);
                    any_dirty = 1;
                }
            }
            rs = rs + 1;
        }
    }

    let cp = fcos(st.pitch);
    let sp = fsin(st.pitch);
    let cy = fcos(st.yaw);
    let sy = fsin(st.yaw);
    let cr = fcos(st.roll);
    let sr = fsin(st.roll);
    let fx = cp * cy;
    let fy = sp;
    let fz = cp * sy;
    let rx0 = -sy;
    let rz0 = cy;
    let ux0 = -sp * cy;
    let uy0 = cp;
    let uz0 = -sp * sy;
    let rx = rx0 * cr + ux0 * sr;
    let ry = uy0 * sr;
    let rz = rz0 * cr + uz0 * sr;
    let ux = ux0 * cr - rx0 * sr;
    let uy = uy0 * cr;
    let uz = uz0 * cr - rz0 * sr;
    let aspect: f64 = if g_mob.lay.h > 0 { (g_mob.lay.w as f64) / (g_mob.lay.h as f64) } else { 1.777 };
    let tan_y: f64 = 0.74;
    let tan_x: f64 = 0.74 * aspect;
    let no_lod = st.disable_lod != 0;
    let lf = qlod_dist as f64;
    let l0_cap = if no_lod { MAX_INWARD_GL } else { clamp_i(28 + qlod_dist * 18, 46, 154) };
    let l1_cap = if no_lod { MAX_L1_INWARD_GL } else { clamp_i(8 + qlod_dist * 4, 12, 36) };
    let l0_base_d2 = 30.0 + lf * 38.0;
    let l0_portal_d2 = l0_base_d2 * 1.45;
    let l1_base_d2 = 1600.0 + lf * 1800.0;
    let l1_portal_d2 = l1_base_d2 * 1.45;

    // 1. Select Layer 0 (1x -> 1/16x) on-screen candidates
    var cand_cnt: i32 = 0;
    var y: i32 = 0;
    while y < 16 {
        var z: i32 = 0;
        while z < 16 {
            var x: i32 = 0;
            while x < 16 {
                let blk = get_block(x, y, z);
                if blk != BLK_AIR && is_block_subdivisible(blk) != 0 {
                    let exp = layer0_block_exposed(x, y, z);
                    if exp != 0 {
                        let dx = (x as f64) + 0.5 - st.px;
                        let dy = (y as f64) + 0.5 - st.py;
                        let dz = (z as f64) + 0.5 - st.pz;
                        let d2 = dx * dx + dy * dy + dz * dz;
                        let is_portal = is_block_shrinkable(blk);
                        let dist_ok = if no_lod { true } else { d2 <= (if is_portal != 0 { l0_portal_d2 } else { l0_base_d2 }) };
                        if dist_ok {
                            let touch_d2: f64 = if no_lod { 3.0 } else { 6.5 };
                            let vis = if d2 < touch_d2 { 1 } else {
                                block_on_screen(dx, dy, dz, 0.87, fx, fy, fz, rx, ry, rz, ux, uy, uz, tan_x, tan_y)
                            };
                            if vis != 0 {
                                var sc = d2;
                                if exp == 1 { sc = sc + 40.0; }
                                if !no_lod && is_portal != 0 { sc = sc - 18.0; }
                                if cand_cnt < l0_cap {
                                    g_mob.cand_x[cand_cnt] = x;
                                    g_mob.cand_y[cand_cnt] = y;
                                    g_mob.cand_z[cand_cnt] = z;
                                    g_mob.cand_sc[cand_cnt] = sc;
                                    cand_cnt = cand_cnt + 1;
                                } else {
                                    var wi: i32 = 0;
                                    var max_i: i32 = 0;
                                    while wi < l0_cap {
                                        if g_mob.cand_sc[wi] > g_mob.cand_sc[max_i] { max_i = wi; }
                                        wi = wi + 1;
                                    }
                                    if sc < g_mob.cand_sc[max_i] {
                                        g_mob.cand_x[max_i] = x;
                                        g_mob.cand_y[max_i] = y;
                                        g_mob.cand_z[max_i] = z;
                                        g_mob.cand_sc[max_i] = sc;
                                    }
                                }
                            }
                        }
                    }
                }
                x = x + 1;
            }
            z = z + 1;
        }
        y = y + 1;
    }

    // 2. Select Layer 1 (16x -> 1x) on-screen candidates
    var l1_cand_cnt: i32 = 0;
    if st.parent_valid[0] != 0 {
        let hx = st.parent_bx[0];
        let hy = st.parent_by[0];
        let hz = st.parent_bz[0];
        y = 0;
        while y < 16 {
            var z: i32 = 0;
            while z < 16 {
                var x: i32 = 0;
                while x < 16 {
                    if !(x == hx && y == hy && z == hz) &&
                       is_l1_covered_by_neighbor(x, y, z, hx, hy, hz) == 0 {
                        let blk = l1_blk_at(x, y, z);
                        if blk != BLK_AIR && is_block_subdivisible(blk) != 0 {
                            let exp = layer1_block_exposed(x, y, z, hx, hy, hz);
                            if exp != 0 {
                                let dx = ((x as f64) + 0.5 - (hx as f64)) * 16.0 - st.px;
                                let dy = ((y as f64) + 0.5 - (hy as f64)) * 16.0 - st.py;
                                let dz = ((z as f64) + 0.5 - (hz as f64)) * 16.0 - st.pz;
                                let d2 = dx * dx + dy * dy + dz * dz;
                                let is_portal = is_block_shrinkable(blk);
                                let dist_ok = if no_lod { true } else { d2 <= (if is_portal != 0 { l1_portal_d2 } else { l1_base_d2 }) };
                                if dist_ok {
                                    let touch_d2: f64 = if no_lod { 300.0 } else { 400.0 };
                                    let vis = if d2 < touch_d2 { 1 } else {
                                        block_on_screen(dx, dy, dz, 13.9, fx, fy, fz, rx, ry, rz, ux, uy, uz, tan_x, tan_y)
                                    };
                                    if vis != 0 {
                                        var sc = d2;
                                        if exp == 1 { sc = sc + 1600.0; }
                                        if !no_lod && is_portal != 0 { sc = sc - 600.0; }
                                        if l1_cand_cnt < l1_cap {
                                            g_mob.l1_cand_x[l1_cand_cnt] = x;
                                            g_mob.l1_cand_y[l1_cand_cnt] = y;
                                            g_mob.l1_cand_z[l1_cand_cnt] = z;
                                            g_mob.l1_cand_sc[l1_cand_cnt] = sc;
                                            l1_cand_cnt = l1_cand_cnt + 1;
                                        } else {
                                            var wi: i32 = 0;
                                            var max_i: i32 = 0;
                                            while wi < l1_cap {
                                                if g_mob.l1_cand_sc[wi] > g_mob.l1_cand_sc[max_i] { max_i = wi; }
                                                wi = wi + 1;
                                            }
                                            if sc < g_mob.l1_cand_sc[max_i] {
                                                g_mob.l1_cand_x[max_i] = x;
                                                g_mob.l1_cand_y[max_i] = y;
                                                g_mob.l1_cand_z[max_i] = z;
                                                g_mob.l1_cand_sc[max_i] = sc;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    x = x + 1;
                }
                z = z + 1;
            }
            y = y + 1;
        }
    }

    // 3. Sticky Cache Match & Per-Frame Upload Budget for Layer 0
    var l0_unpinned: i32 = 0;
    var i: i32 = 0;
    while i < cand_cnt {
        let cx = g_mob.cand_x[i];
        let cy = g_mob.cand_y[i];
        let cz = g_mob.cand_z[i];
        let idx = (cy << 8) | (cz << 4) | cx;
        let s = g_mob.l0_slot_grid[idx];
        if s >= 0 && s < MAX_INWARD_GL && g_mob.inw_valid[s] != 0 &&
           g_mob.inw_bx[s] == cx && g_mob.inw_by[s] == cy && g_mob.inw_bz[s] == cz {
            g_mob.inw_last_seen[s] = tick;
            g_mob.cand_pin[i] = 1;
        } else {
            g_mob.cand_pin[i] = 0;
            l0_unpinned = l0_unpinned + 1;
        }
        i = i + 1;
    }

    var l0_active: i32 = 0;
    var s: i32 = 0;
    while s < MAX_INWARD_GL {
        if g_mob.inw_valid[s] != 0 { l0_active = l0_active + 1; }
        s = s + 1;
    }

    let budget_l0 = if was_forced { 14 } else { 10 };
    var up_l0: i32 = 0;
    while up_l0 < budget_l0 && l0_unpinned > 0 {
        var best_i: i32 = -1;
        var best_sc: f64 = 1.0e18;
        i = 0;
        while i < cand_cnt {
            if g_mob.cand_pin[i] == 0 && g_mob.cand_sc[i] < best_sc {
                best_sc = g_mob.cand_sc[i];
                best_i = i;
            }
            i = i + 1;
        }
        if best_i < 0 { break; }

        var dst: i32 = -1;
        if l0_active < l0_cap {
            s = 0;
            while s < MAX_INWARD_GL {
                if g_mob.inw_valid[s] == 0 { dst = s; break; }
                s = s + 1;
            }
        }
        if dst < 0 {
            var oldest_t: i32 = tick;
            s = 0;
            while s < MAX_INWARD_GL {
                if g_mob.inw_valid[s] != 0 && g_mob.inw_last_seen[s] < oldest_t {
                    oldest_t = g_mob.inw_last_seen[s];
                    dst = s;
                }
                s = s + 1;
            }
        }
        if dst < 0 { break; }

        if g_mob.inw_valid[dst] != 0 {
            let old_idx = (g_mob.inw_by[dst] << 8) | (g_mob.inw_bz[dst] << 4) | g_mob.inw_bx[dst];
            if g_mob.l0_slot_grid[old_idx] == dst { g_mob.l0_slot_grid[old_idx] = -1; }
        } else {
            l0_active = l0_active + 1;
        }

        let cx = g_mob.cand_x[best_i];
        let cy = g_mob.cand_y[best_i];
        let cz = g_mob.cand_z[best_i];
        let blk = get_block(cx, cy, cz);
        let cseed = resolve_child_frame_seed(pseed, pdepth, cx, cy, cz, blk);
        let cbio = resolve_child_frame_biome(pseed, pdepth, pbio, cx, cy, cz, blk, -1);
        let cslot = resolve_subchunk_slot(pseed, pdepth, pbio, cx, cy, cz, blk);
        let c_off = cslot * CHUNK_VOL;
        var q: i32 = 0;
        while q < 1024 {
            let base = c_off + q * 4;
            let b0 = st.inward_blocks[base + 0] as! i32;
            let b1 = st.inward_blocks[base + 1] as! i32;
            let b2 = st.inward_blocks[base + 2] as! i32;
            let b3 = st.inward_blocks[base + 3] as! i32;
            let packed = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
            fbw_gl_push_inward_quad(dst, q, packed);
            q = q + 1;
        }
        fbw_gl_set_inward_meta(dst, 1, cx, cy, cz, cbio);
        let new_idx = (cy << 8) | (cz << 4) | cx;
        g_mob.l0_slot_grid[new_idx] = dst;
        g_mob.inw_valid[dst] = 1;
        g_mob.inw_bx[dst] = cx;
        g_mob.inw_by[dst] = cy;
        g_mob.inw_bz[dst] = cz;
        g_mob.inw_blk[dst] = blk;
        g_mob.inw_seed[dst] = cseed;
        g_mob.inw_last_seen[dst] = tick;
        g_mob.cand_pin[best_i] = 1;
        l0_unpinned = l0_unpinned - 1;
        up_l0 = up_l0 + 1;
        any_dirty = 1;
    }

    // Prune off-screen excess slots if l0_cap shrank (e.g. LOD OPT toggled back ON or slider lowered)
    while l0_active > l0_cap {
        var oldest_s: i32 = -1;
        var oldest_t: i32 = tick;
        s = 0;
        while s < MAX_INWARD_GL {
            if g_mob.inw_valid[s] != 0 && g_mob.inw_last_seen[s] < oldest_t {
                oldest_t = g_mob.inw_last_seen[s];
                oldest_s = s;
            }
            s = s + 1;
        }
        if oldest_s < 0 { break; }
        let old_idx = (g_mob.inw_by[oldest_s] << 8) | (g_mob.inw_bz[oldest_s] << 4) | g_mob.inw_bx[oldest_s];
        if g_mob.l0_slot_grid[old_idx] == oldest_s { g_mob.l0_slot_grid[old_idx] = -1; }
        g_mob.inw_valid[oldest_s] = 0;
        fbw_gl_set_inward_meta(oldest_s, 0, 0, 0, 0, 0);
        l0_active = l0_active - 1;
        any_dirty = 1;
    }

    // 4. Sticky Cache Match & Per-Frame Upload Budget for Layer 1
    var l1_unpinned: i32 = 0;
    i = 0;
    while i < l1_cand_cnt {
        let cx = g_mob.l1_cand_x[i];
        let cy = g_mob.l1_cand_y[i];
        let cz = g_mob.l1_cand_z[i];
        let idx = (cy << 8) | (cz << 4) | cx;
        let s1 = g_mob.l1_slot_grid[idx];
        if s1 >= 0 && s1 < MAX_L1_INWARD_GL && g_mob.l1_inw_valid[s1] != 0 &&
           g_mob.l1_inw_bx[s1] == cx && g_mob.l1_inw_by[s1] == cy && g_mob.l1_inw_bz[s1] == cz {
            g_mob.l1_inw_last_seen[s1] = tick;
            g_mob.l1_cand_pin[i] = 1;
        } else {
            g_mob.l1_cand_pin[i] = 0;
            l1_unpinned = l1_unpinned + 1;
        }
        i = i + 1;
    }

    var l1_active: i32 = 0;
    s = 0;
    while s < MAX_L1_INWARD_GL {
        if g_mob.l1_inw_valid[s] != 0 { l1_active = l1_active + 1; }
        s = s + 1;
    }

    let budget_l1 = if was_forced { 6 } else { 4 };
    var up_l1: i32 = 0;
    while up_l1 < budget_l1 && l1_unpinned > 0 {
        var best_i: i32 = -1;
        var best_sc: f64 = 1.0e18;
        i = 0;
        while i < l1_cand_cnt {
            if g_mob.l1_cand_pin[i] == 0 && g_mob.l1_cand_sc[i] < best_sc {
                best_sc = g_mob.l1_cand_sc[i];
                best_i = i;
            }
            i = i + 1;
        }
        if best_i < 0 { break; }

        var dst: i32 = -1;
        if l1_active < l1_cap {
            s = 0;
            while s < MAX_L1_INWARD_GL {
                if g_mob.l1_inw_valid[s] == 0 { dst = s; break; }
                s = s + 1;
            }
        }
        if dst < 0 {
            var oldest_t: i32 = tick;
            s = 0;
            while s < MAX_L1_INWARD_GL {
                if g_mob.l1_inw_valid[s] != 0 && g_mob.l1_inw_last_seen[s] < oldest_t {
                    oldest_t = g_mob.l1_inw_last_seen[s];
                    dst = s;
                }
                s = s + 1;
            }
        }
        if dst < 0 { break; }

        if g_mob.l1_inw_valid[dst] != 0 {
            let old_idx = (g_mob.l1_inw_by[dst] << 8) | (g_mob.l1_inw_bz[dst] << 4) | g_mob.l1_inw_bx[dst];
            if g_mob.l1_slot_grid[old_idx] == dst { g_mob.l1_slot_grid[old_idx] = -1; }
        } else {
            l1_active = l1_active + 1;
        }

        let cx = g_mob.l1_cand_x[best_i];
        let cy = g_mob.l1_cand_y[best_i];
        let cz = g_mob.l1_cand_z[best_i];
        let blk = l1_blk_at(cx, cy, cz);
        let cseed = resolve_child_frame_seed(l1_seed, l1_depth, cx, cy, cz, blk);
        let cbio = resolve_child_frame_biome(l1_seed, l1_depth, l1_bio, cx, cy, cz, blk, -1);
        let cslot = resolve_subchunk_slot(l1_seed, l1_depth, l1_bio, cx, cy, cz, blk);
        let c_off = cslot * CHUNK_VOL;
        var q: i32 = 0;
        while q < 1024 {
            let base = c_off + q * 4;
            let b0 = st.inward_blocks[base + 0] as! i32;
            let b1 = st.inward_blocks[base + 1] as! i32;
            let b2 = st.inward_blocks[base + 2] as! i32;
            let b3 = st.inward_blocks[base + 3] as! i32;
            let packed = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
            fbw_gl_push_l1_inward_quad(dst, q, packed);
            q = q + 1;
        }
        fbw_gl_set_l1_inward_meta(dst, 1, cx, cy, cz, cbio);
        let new_idx = (cy << 8) | (cz << 4) | cx;
        g_mob.l1_slot_grid[new_idx] = dst;
        g_mob.l1_inw_valid[dst] = 1;
        g_mob.l1_inw_bx[dst] = cx;
        g_mob.l1_inw_by[dst] = cy;
        g_mob.l1_inw_bz[dst] = cz;
        g_mob.l1_inw_blk[dst] = blk;
        g_mob.l1_inw_seed[dst] = cseed;
        g_mob.l1_inw_last_seen[dst] = tick;
        g_mob.l1_cand_pin[best_i] = 1;
        l1_unpinned = l1_unpinned - 1;
        up_l1 = up_l1 + 1;
        any_dirty = 1;
    }

    while l1_active > l1_cap {
        var oldest_s: i32 = -1;
        var oldest_t: i32 = tick;
        s = 0;
        while s < MAX_L1_INWARD_GL {
            if g_mob.l1_inw_valid[s] != 0 && g_mob.l1_inw_last_seen[s] < oldest_t {
                oldest_t = g_mob.l1_inw_last_seen[s];
                oldest_s = s;
            }
            s = s + 1;
        }
        if oldest_s < 0 { break; }
        let old_idx = (g_mob.l1_inw_by[oldest_s] << 8) | (g_mob.l1_inw_bz[oldest_s] << 4) | g_mob.l1_inw_bx[oldest_s];
        if g_mob.l1_slot_grid[old_idx] == oldest_s { g_mob.l1_slot_grid[old_idx] = -1; }
        g_mob.l1_inw_valid[oldest_s] = 0;
        fbw_gl_set_l1_inward_meta(oldest_s, 0, 0, 0, 0, 0);
        l1_active = l1_active - 1;
        any_dirty = 1;
    }

    g_mob.inw_pending = if l0_unpinned > 0 || l1_unpinned > 0 { 1 } else { 0 };
    if any_dirty != 0 {
        fbw_gl_mark_inward_dirty();
    }
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

    if st.markers[0].used != 0 && st.markers[0].depth == st.depth {
        fbw_gl_push_entity(
            ENT_MARKER_BEACON,
            (st.markers[0].px * 1000.0) as! i32,
            (st.markers[0].py * 1000.0) as! i32,
            (st.markers[0].pz * 1000.0) as! i32,
            1, 1, 0
        );
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

    let cy = fcos(st.yaw);
    let sy = fsin(st.yaw);
    let cp = fcos(st.pitch);
    let sp = fsin(st.pitch);
    let cr = if st.true_up != 0 { 1.0 } else { fcos(st.roll) };
    let sr = if st.true_up != 0 { 0.0 } else { fsin(st.roll) };

    let fx = cp * cy;
    let fy = sp;
    let fz = cp * sy;

    let rx0 = -sy;
    let rz0 = cy;
    let ux0 = -sp * cy;
    let uy0 = cp;
    let uz0 = -sp * sy;

    let rx = rx0 * cr + ux0 * sr;
    let ry = uy0 * sr;
    let rz = rz0 * cr + uz0 * sr;

    let ux = ux0 * cr - rx0 * sr;
    let uy = uy0 * cr;
    let uz = uz0 * cr - rz0 * sr;

    // Virtual flight stick -> camera-aligned forward + roll-aligned strafe
    if fabs(g_mob.stick_dx) > 0.08 || fabs(g_mob.stick_dy) > 0.08 {
        let fwd = -g_mob.stick_dy * thrust;
        let strafe = g_mob.stick_dx * thrust;
        apply_thrust(fx * fwd + rx * strafe, fy * fwd + ry * strafe, fz * fwd + rz * strafe);
    }

    if g_mob.hold_up != 0 {
        if st.true_up != 0 {
            apply_thrust(0.0, thrust * 0.9, 0.0);
        } else {
            apply_thrust(ux * thrust * 0.9, uy * thrust * 0.9, uz * thrust * 0.9);
        }
    }
    if g_mob.hold_dn != 0 {
        if st.true_up != 0 {
            apply_thrust(0.0, -thrust * 0.9, 0.0);
        } else {
            apply_thrust(-ux * thrust * 0.9, -uy * thrust * 0.9, -uz * thrust * 0.9);
        }
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
        }
    }
}

fn drain_pending_sfx() {
    let st = core();
    if st.pending_sfx >= 0 {
        fbw_sound_fx(st.pending_sfx);
        st.pending_sfx = -1;
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

    st.frame_cnt = st.frame_cnt + 1;
    let fps_dt = now - g_mob.fps_ms;
    if fps_dt >= 500 {
        st.fps = clamp_i((st.frame_cnt * 1000) / fps_dt, 1, 240);
        st.frame_cnt = 0;
        g_mob.fps_ms = now;
    }

    let prev_depth = st.depth;
    let prev_rev = st.chunk_rev;

    if st.screen == SCREEN_PLAY {
        step_mobile_controls(dt_ms);
        step_simulation(dt_ms);
        drain_pending_sfx();
        let _ = resolve_pending_neighbors(8);  // stream far-ring chunks (8/frame)
    } else {
        st.anim_ms = st.anim_ms + dt_ms;
    }

    if st.depth != prev_depth || st.chunk_rev != prev_rev {
        g_mob.sync_force = 1;
    }

    if st.lod_dist_level < 1 || st.lod_dist_level > 7 {
        st.lod_dist_level = 4;
    }
    if st.view_chunk_radius < 1 || st.view_chunk_radius > 3 {
        st.view_chunk_radius = 2;
    }
    // 1. Hardware OpenGL Pass (Sky + 5 Macro Parents + Layer 0 + Inward 1/16x LOD + Dynamic)
    fbw_gl_set_lod_config(st.disable_lod, st.lod_dist_level);
    sync_chunks_to_gl();
    sync_inward_to_gl();
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

fn wep_tag(w: i32, quasar: i32) -> const u8[:] {
    if w == 0 { return "1:PLS"; }
    if w == 1 { return "2:CAN"; }
    if w == 2 { return "3:LSR"; }
    if w == 3 { return "4:RKT"; }
    if w == 4 { return "5:HOM"; }
    if w == 5 { return "6:MNG"; }
    if w == 6 { return "7:RAL"; }
    if w == 7 { return "8:EMP"; }
    if w == 8 { return "9:NUK"; }
    if quasar != 0 { return "0:QSR"; }
    return "0:DRK";
}

fn buf_pad2(buf: u8[160]&, len: i32&, v: i32) {
    if v < 10 {
        if len < 158 { buf[len] = '0'; len = len + 1; }
    }
    buf_int(buf, len, v);
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
    buf_str(b1, n1, " SHD "); buf_int(b1, n1, st.shields);
    buf_str(b1, n1, " ARM "); buf_int(b1, n1, st.armor);
    buf_str(b1, n1, " G "); buf_int(b1, n1, st.gold);
    buf_str(b1, n1, " K "); buf_int(b1, n1, st.keys);
    buf_str(b1, n1, " T "); buf_int(b1, n1, st.trophies);
    b1[n1] = 0;
    set_color(0xF8FAFCFF);
    fbw_text(12, 10, b1[0..n1], 2);

    let pt_sec = (st.play_ms / 1000) as! i32;
    let pt_min = pt_sec / 60;
    let pt_rem = pt_sec % 60;
    var b2: u8[160] = [0; 160];
    var n2: i32 = 0;
    buf_str(b2, n2, biome_name(cur_biome()));
    buf_str(b2, n2, " LVL "); buf_int(b2, n2, st.depth);
    buf_str(b2, n2, " Lv"); buf_int(b2, n2, st.level);
    buf_str(b2, n2, " XP"); buf_int(b2, n2, (st.xp * 100) / xp_to_next(st.level));
    buf_str(b2, n2, "% FPS "); buf_int(b2, n2, st.fps);
    buf_str(b2, n2, " "); buf_pad2(b2, n2, pt_min); buf_str(b2, n2, ":"); buf_pad2(b2, n2, pt_rem);
    if st.dps_val > 0 { buf_str(b2, n2, " DPS "); buf_int(b2, n2, st.dps_val); }
    if st.quasar_drive_ms > 0 { buf_str(b2, n2, " [QSR]"); }
    else if st.black_hole_drive_ms > 0 { buf_str(b2, n2, " [BH-DRV]"); }
    if st.genesis_mode != 0 { buf_str(b2, n2, " [GEN]"); }
    b2[n2] = 0;
    set_color(0x38BDF8FF);
    fbw_text(12, 34, b2[0..n2], 2);

    // Top-right quick utility buttons: [MAP] [RKT] [TRU] [MRK] [INFO] [MENU]
    let btn_w = clamp_i(w / 15, 56, 86);
    let btn_h = l.top_h - 14;
    let gap: i32 = 5;
    var bx = w - 10 - btn_w;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, 0x334155EE, 0xFACC15FF);
    set_color(0xFACC15FF);
    fbw_text(bx + 8, 20, "MENU", 2);
    bx = bx - btn_w - gap;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, 0x1E293BEE, 0x38BDF8FF);
    set_color(0x38BDF8FF);
    fbw_text(bx + 8, 20, "INFO", 2);
    bx = bx - btn_w - gap;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, 0x1E293BEE, 0x4ADE80FF);
    set_color(0x4ADE80FF);
    fbw_text(bx + 10, 20, "MRK", 2);
    bx = bx - btn_w - gap;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, if st.true_up != 0 { 0x0E7490EE } else { 0x1E293BEE }, 0x38BDF8FF);
    set_color(0xFFFFFFFF);
    fbw_text(bx + 10, 20, "TRU", 2);
    bx = bx - btn_w - gap;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, if st.rocket_mode != 0 { 0xB45309EE } else { 0x1E293BEE }, 0xFB923CFF);
    set_color(0xFFFFFFFF);
    fbw_text(bx + 10, 20, "RKT", 2);
    bx = bx - btn_w - gap;

    fbw_box(bx, 7, bx + btn_w, 7 + btn_h, if st.show_minimap != 0 { 0x065F46EE } else { 0x1E293BEE }, 0x4ADE80FF);
    set_color(0xFFFFFFFF);
    fbw_text(bx + 10, 20, "MAP", 2);

    // Center crosshair
    let cx = w / 2;
    let cy = h / 2;
    set_color(if st.target_max_hp > 0 { 0xF87171FF } else if st.near_prompt_len > 0 || st.near_ring_kind != ENT_NONE { 0xFACC15FF } else { 0xFFFFFFFF });
    draw_segment(cx - 12, cy, cx - 4, cy);
    draw_segment(cx + 4, cy, cx + 12, cy);
    draw_segment(cx, cy - 12, cx, cy - 4);
    draw_segment(cx, cy + 4, cx, cy + 12);

    // 3D-Projected Waypoint Compass for Active Marker (or Short Marker slot 0)
    var mslot = st.active_marker;
    if mslot < 0 || mslot >= MAX_MARKERS || st.markers[mslot].used == 0 {
        mslot = if st.markers[0].used != 0 { 0 } else { -1 };
    }
    if mslot >= 0 {
        let mk = &st.markers[mslot];
        if mk.depth == st.depth {
            let mdx = mk.px - st.px;
            let mdy = mk.py - st.py;
            let mdz = mk.pz - st.pz;
            let mdist = fsqrt(mdx * mdx + mdy * mdy + mdz * mdz);
            if mdist > 0.6 {
                let cp = fcos(st.pitch);
                let sp = fsin(st.pitch);
                let cya = fcos(st.yaw);
                let sya = fsin(st.yaw);
                let cr = if st.true_up != 0 { 1.0 } else { fcos(st.roll) };
                let sr = if st.true_up != 0 { 0.0 } else { fsin(st.roll) };
                let fx = cp * cya;
                let fy = sp;
                let fz = cp * sya;
                let rx0 = -sya;
                let rz0 = cya;
                let ux0 = -sp * cya;
                let uy0 = cp;
                let uz0 = -sp * sya;
                let rx = rx0 * cr + ux0 * sr;
                let ry = uy0 * sr;
                let rz = rz0 * cr + uz0 * sr;
                let ux = ux0 * cr - rx0 * sr;
                let uy = uy0 * cr;
                let uz = uz0 * cr - rz0 * sr;
                let cvz = mdx * fx + mdy * fy + mdz * fz;
                let cvx = mdx * rx + mdy * ry + mdz * rz;
                let cvy = mdx * ux + mdy * uy + mdz * uz;
                let aspect = if h > 0 { (w as f64) / (h as f64) } else { 1.777 };
                var sx_n: f64 = 0.0;
                var sy_n: f64 = 0.0;
                if cvz > 0.25 {
                    sx_n = cvx / (cvz * 0.74 * aspect);
                    sy_n = cvy / (cvz * 0.74);
                } else {
                    let plen = fsqrt(cvx * cvx + cvy * cvy + 0.0001);
                    sx_n = (cvx / plen) * 1.15;
                    sy_n = (cvy / plen) * 1.15;
                }
                let wx = clamp_i(cx + ((sx_n * ((w / 2) as f64)) as! i32), 28, w - 28);
                let wy = clamp_i(cy - ((sy_n * ((h / 2) as f64)) as! i32), l.top_h + 44, l.wep_y1 - 24);
                fbw_box(wx - 7, wy - 7, wx + 7, wy + 7, 0x22C55ECC, 0xFFFFFFFF);
                var wb: u8[160] = [0; 160];
                var wn: i32 = 0;
                buf_str(wb, wn, "MRK "); buf_int(wb, wn, ffloor(mdist)); buf_str(wb, wn, "m");
                wb[wn] = 0;
                set_color(0x4ADE80FF);
                fbw_text(wx + 10, wy - 7, wb[0..wn], 2);
            }
        }
    }

    // Proximity prompt, status toast & crosshair Target HP Bar
    var banner_y = l.top_h + 8;
    if st.msg_ms > 0 && st.msg_len > 0 {
        let tw = fbw_text_w(st.msg_buf[0..st.msg_len], 2);
        let mx = (w - tw) / 2;
        fbw_box(mx - 12, banner_y, mx + tw + 12, banner_y + 28, 0x0F172AE0, 0xFACC15AA);
        set_color(0xFACC15FF);
        fbw_text(mx, banner_y + 6, st.msg_buf[0..st.msg_len], 2);
        banner_y = banner_y + 32;
    } else if st.near_prompt_len > 0 {
        let tw = fbw_text_w(st.near_prompt[0..st.near_prompt_len], 2);
        let mx = (w - tw) / 2;
        fbw_box(mx - 12, banner_y, mx + tw + 12, banner_y + 28, 0x0F172AE0, 0x4ADE80AA);
        set_color(0x4ADE80FF);
        fbw_text(mx, banner_y + 6, st.near_prompt[0..st.near_prompt_len], 2);
        banner_y = banner_y + 32;
    } else if st.near_ring_kind != ENT_NONE {
        let rmsg = if st.near_ring_kind == ENT_RING_RED { "Tap USE on Red Ring to Grow 16x!" }
                   else if st.near_ring_kind == ENT_RING_PINK { "Tap USE on Pink Ring to Dive 256x!" }
                   else if st.near_ring_kind == ENT_RING_DANGER { "Tap USE on Danger Rift Ring (256x)!" }
                   else if st.near_ring_kind == ENT_RING_BLUE { "Tap USE on Blue Ring to Teleport!" }
                   else { "Tap USE on Green Ring to Shrink 16x!" };
        let tw = fbw_text_w(rmsg, 2);
        let mx = (w - tw) / 2;
        fbw_box(mx - 12, banner_y, mx + tw + 12, banner_y + 28, 0x0F172AE0, 0x38BDF8AA);
        set_color(0x38BDF8FF);
        fbw_text(mx, banner_y + 6, rmsg, 2);
        banner_y = banner_y + 32;
    }

    if st.target_name_len > 0 {
        let tw = fbw_text_w(st.target_name[0..st.target_name_len], 2);
        let bw: i32 = if tw > 180 { tw + 24 } else { 204 };
        let bx1 = cx - bw / 2;
        let bh: i32 = if st.target_max_hp > 0 { 36 } else { 24 };
        fbw_box(bx1, banner_y, bx1 + bw, banner_y + bh, 0x0A101CD8, if st.target_max_hp > 0 { 0xF87171CC } else { 0x94A3B8AA });
        set_color(if st.target_max_hp > 0 { 0xFCA5A5FF } else { 0xE2E8F0FF });
        fbw_text(cx - tw / 2, banner_y + 4, st.target_name[0..st.target_name_len], 2);
        if st.target_max_hp > 0 {
            let bar_w = bw - 20;
            let fill_w = clamp_i((bar_w * st.target_hp) / st.target_max_hp, 0, bar_w);
            fbw_box(bx1 + 10, banner_y + 22, bx1 + 10 + bar_w, banner_y + 31, 0x1E293BFF, 0x64748BFF);
            if fill_w > 2 {
                set_color(0xEF4444FF);
                draw_rect(bx1 + 11, banner_y + 23, bx1 + 9 + fill_w, banner_y + 30);
            }
        }
    }

    // Compact corner minimap (with cross-neighbor seam sampling!)
    if st.show_minimap != 0 && w >= 600 {
        let cell: i32 = 6;
        let ms: i32 = 16 * cell;
        let mx = w - ms - 22;
        let my = l.top_h + 12;
        fbw_box(mx - 4, my - 4, mx + ms + 4, my + ms + 4, 0x080C18D8, 0x38BDF8AA);
        let py_i = clamp_i(ffloor(st.py), 0, 15);
        var z: i32 = 0;
        while z < 16 {
            var x: i32 = 0;
            while x < 16 {
                let blk = world_block_rel(x, py_i, z);
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

    // Right-edge Steam-style vertical elevation bar (y / 16 + active marker height)
    let ev_y1 = l.top_h + 116;
    let ev_y2 = l.wep_y1 - 16;
    if ev_y2 - ev_y1 >= 48 {
        let ev_x1 = w - 14;
        let ev_x2 = w - 6;
        fbw_box(ev_x1, ev_y1, ev_x2, ev_y2, 0x0F172AC0, 0xFACC15AA);
        let yn = fclamp(st.py / 16.0, 0.0, 1.0);
        let py_px = ev_y2 - ((yn * ((ev_y2 - ev_y1 - 6) as f64)) as! i32) - 3;
        set_color(0xFACC15FF);
        draw_rect(ev_x1 + 1, py_px - 3, ev_x2 - 1, py_px + 3);
        if mslot >= 0 && st.markers[mslot].depth == st.depth {
            let myn = fclamp(st.markers[mslot].py / 16.0, 0.0, 1.0);
            let my_px = ev_y2 - ((myn * ((ev_y2 - ev_y1 - 4) as f64)) as! i32) - 2;
            set_color(0x4ADE80FF);
            draw_rect(ev_x1 + 1, my_px - 2, ev_x2 - 1, my_px + 2);
        }
    }

    // Active Weapon Mode label pill directly above weapon bar center
    let wmode_lbl = weapon_mode_name(st.weapon, st.wep_mode[st.weapon]);
    if wmode_lbl.len > 0 {
        var mb: u8[160] = [0; 160];
        var ml: i32 = 0;
        buf_str(mb, ml, weapon_name(st.weapon));
        buf_str(mb, ml, " [");
        buf_str(mb, ml, wmode_lbl);
        buf_str(mb, ml, "]");
        mb[ml] = 0;
        let mtw = fbw_text_w(mb[0..ml], 2);
        let mx0 = cx - mtw / 2;
        fbw_box(mx0 - 10, l.wep_y1 - 24, mx0 + mtw + 10, l.wep_y1 - 3, 0x0B1220D8, 0x38BDF8AA);
        set_color(0x38BDF8FF);
        fbw_text(mx0, l.wep_y1 - 21, mb[0..ml], 2);
    }

    // Bottom 10-weapon touch strip + right-side [MOD] mode cycle button
    let mod_w = clamp_i(w / 14, 62, 86);
    let wep_area_w = w - 34 - mod_w;
    let slot_w = wep_area_w / NUM_WEAPONS;
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
        fbw_text(sx1 + 4, l.wep_y1 + 6, wep_tag(wi, st.quasar_drive), 2);
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
            fbw_text(sx1 + 4, l.wep_y1 + 26, ab[0..al], 2);
        }
        wi = wi + 1;
    }
    let mod_x1 = 14 + NUM_WEAPONS * slot_w + 2;
    let mod_x2 = w - 14;
    fbw_box(mod_x1, l.wep_y1, mod_x2, l.wep_y2, 0x0F766EEE, 0x22D3EEFF);
    set_color(0xFFFFFFFF);
    fbw_text(mod_x1 + 8, l.wep_y1 + 14, "MOD", 2);
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

fn draw_modal_row_h(mx: i32, y: i32, mw: i32, rh: i32, label: const u8[:], fill: u32, text_col: u32) {
    fbw_box(mx + 18, y, mx + mw - 18, y + rh, fill, 0x475569FF);
    set_color(text_col);
    fbw_text(mx + 30, y + (rh - 16) / 2, label, 2);
}

fn draw_modal_row(mx: i32, y: i32, mw: i32, label: const u8[:], fill: u32, text_col: u32) {
    draw_modal_row_h(mx, y, mw, 46, label, fill, text_col);
}

fn draw_mobile_modal(w: i32, h: i32) {
    let st = core();
    let mw = clamp_i((w * 74) / 100, 440, 780);
    let mh = clamp_i((h * 80) / 100, 340, 580);
    let mx = (w - mw) / 2;
    let my = (h - mh) / 2;

    fbw_box(mx, my, mx + mw, my + mh, 0x0B1220F2, 0x38BDF8FF);

    if st.screen == SCREEN_BUY {
        // Authentic buy menu (Xar manual 8.4)
        set_color(0x4ADE80FF);
        fbw_text(mx + 22, my + 14, "BUY STATION - TAP ITEM TO PURCHASE", 3);
        draw_modal_row_h(mx, my + 48,  mw, 34, "[1] 20 Cannon ammo (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 88,  mw, 34, "[2] 100 Laser ammo (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 128, mw, 34, "[3] 50 Rocket ammo (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 168, mw, 34, "[4] 1000 Homing ammo (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 208, mw, 34, "[5] 100 Minigun ammo (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 248, mw, 34, "[6] 20 Railgun ammo (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 288, mw, 34, "[7] 1 EMP charge (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 328, mw, 34, "[8] 200% Health (100g)", 0x1E293BFF, 0x4ADE80FF);
        draw_modal_row_h(mx, my + 368, mw, 34, "[9] 100% Armor (100g)", 0x1E293BFF, 0x38BDF8FF);
        draw_modal_row_h(mx, my + 408, mw, 34, "[10] 150% Armor (150g)", 0x1E293BFF, 0x38BDF8FF);
        draw_modal_row_h(mx, my + 448, mw, 34, "[11] 200% Armor (200g)", 0x1E293BFF, 0x38BDF8FF);
        draw_modal_row(mx, my + mh - 60, mw, "CLOSE STATION", 0x334155FF, 0x38BDF8FF);
    } else if st.screen == SCREEN_UPGRADE {
        // Upgrade Station (Xar manual 8.6) - the main gold sink; weapon damage
        // purchases also unlock that weapon.
        set_color(0xFF8C28FF);
        fbw_text(mx + 22, my + 14, "UPGRADE STATION - SPEND GOLD, GET STRONGER", 3);
        draw_modal_row_h(mx, my + 48,  mw, 34, "[1] Plasma damage (100g)", 0x1E293BFF, 0x38BDF8FF);
        draw_modal_row_h(mx, my + 88,  mw, 34, "[2] Cannon damage (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 128, mw, 34, "[3] Laser damage (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 168, mw, 34, "[4] Rocket damage (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 208, mw, 34, "[5] Railgun damage (200g)", 0x1E293BFF, 0xFACC15FF);
        draw_modal_row_h(mx, my + 248, mw, 34, "[6] EMP damage (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 288, mw, 34, "[7] Nuke damage (200g)", 0x1E293BFF, 0xFACC15FF);
        draw_modal_row_h(mx, my + 328, mw, 34, "[8] Dark Hole damage (300g)", 0x1E293BFF, 0xE879F9FF);
        draw_modal_row_h(mx, my + 368, mw, 34, "[9] Health capacity (200g)", 0x1E293BFF, 0x4ADE80FF);
        draw_modal_row_h(mx, my + 408, mw, 34, "[10] Health regen (100g)", 0x1E293BFF, 0x4ADE80FF);
        draw_modal_row(mx, my + mh - 60, mw, "CLOSE STATION", 0x334155FF, 0xFF8C28FF);
    } else if st.screen == SCREEN_SELL {
        set_color(0xFACC15FF);
        fbw_text(mx + 22, my + 16, "SELL STATION - CONVERT SURPLUS TO GOLD", 3);
        draw_modal_row(mx, my + 64,  mw, "[1] Sell 100 Laser ammo -> +40 Gold", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 108, mw, "[2] Sell 50 Cannon ammo -> +40 Gold", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 152, mw, "[3] Sell 50 Rocket ammo -> +40 Gold", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 196, mw, "[4] Sell 200 Minigun ammo -> +40 Gold", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 240, mw, "[5] Sell 20 Railgun slugs -> +60 Gold", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 284, mw, "[6] Sell 1 Nuke -> +80 Gold", 0x1E293BFF, 0xFACC15FF);
        draw_modal_row(mx, my + mh - 60, mw, "CLOSE STATION", 0x334155FF, 0x38BDF8FF);
    } else if st.screen == SCREEN_BLACK_MARKET {
        set_color(0xE879F9FF);
        fbw_text(mx + 22, my + 16, "BLACK MARKET - RARE MUNITIONS", 3);
        draw_modal_row(mx, my + 64,  mw, "[1] 50 Railgun ammo (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 120, mw, "[2] 2 EMP charges (100g)", 0x1E293BFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 176, mw, "[3] 2 Nukes (100g)", 0x1E293BFF, 0xFACC15FF);
        draw_modal_row(mx, my + mh - 60, mw, "CLOSE BLACK MARKET", 0x334155FF, 0x38BDF8FF);
    } else if st.screen == SCREEN_TOME {
        set_color(0x38BDF8FF);
        fbw_text(mx + 22, my + 16, tome_title(st.tome_id), 3);
        set_color(0xF8FAFCFF);
        fbw_text(mx + 22, my + 72, tome_body_line(st.tome_id, 0), 2);
        fbw_text(mx + 22, my + 106, tome_body_line(st.tome_id, 1), 2);
        fbw_text(mx + 22, my + 140, tome_body_line(st.tome_id, 2), 2);
        set_color(0xFACC15FF);
        fbw_text(mx + 22, my + 174, tome_body_line(st.tome_id, 3), 2);
        draw_modal_row(mx, my + mh - 60, mw, "RESUME EXPLORATION", 0x1E3A8AFF, 0xFFFFFFFF);
    } else if st.screen == SCREEN_VICTORY {
        set_color(0xFACC15FF);
        fbw_text(mx + 22, my + 18, "VICTORY! FRIEND 'K' RESCUED!", 3);
        set_color(0xFFFFFFFF);
        fbw_text(mx + 22, my + 74, "The Singularity defeated! (+500 Gold & Quasar Drive)", 2);
        draw_modal_row(mx, my + 140, mw, "KEEP EXPLORING XAR", 0x065F46FF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 200, mw, "START NEW RUN", 0x1E3A8AFF, 0xFFFFFFFF);
        draw_modal_row(mx, my + 260, mw, "EXIT TO CALCULATOR", 0x7F1D1DFF, 0xFFFFFFFF);
    } else if st.screen >= SCREEN_INFO_F1 && st.screen <= SCREEN_INFO_F5 {
        // 5-Tab Xar Compendium Header: [F1 HELP] [F2 WEPS] [F3 MOBS] [F4 MRKS] [F5 LORE]
        let tw = (mw - 48) / 5;
        let t_lbls: const u8[:][5] = ["F1 HELP", "F2 WEPS", "F3 MOBS", "F4 MRKS", "F5 LORE"];
        var ti: i32 = 0;
        while ti < 5 {
            let tx1 = mx + 14 + ti * (tw + 5);
            let active = (st.screen == (SCREEN_INFO_F1 + ti));
            fbw_box(tx1, my + 10, tx1 + tw, my + 42, if active { 0x1D4ED8FF } else { 0x1E293BFF }, if active { 0xFACC15FF } else { 0x475569FF });
            set_color(if active { 0xFACC15FF } else { 0xCBD5E1FF });
            fbw_text(tx1 + 10, my + 18, t_lbls[ti], 2);
            ti = ti + 1;
        }

        if st.screen == SCREEN_INFO_F1 {
            set_color(0x38BDF8FF);
            fbw_text(mx + 22, my + 56, "FRACTAL BLOCK WORLD (XAR) - SURVIVAL GUIDE", 2);
            set_color(0xF8FAFCFF);
            fbw_text(mx + 22, my + 88, "1. Every block contains a 16x16x16 universe inside.", 2);
            fbw_text(mx + 22, my + 116, "2. Tap SHRK or fly into Green/Pink rings to dive 16x/256x.", 2);
            fbw_text(mx + 22, my + 144, "3. Tap GROW or Red rings / fly out bounds to grow 16x.", 2);
            fbw_text(mx + 22, my + 172, "4. Short Marker [MRK] costs 10g past LVL 0; Plasma clears it.", 2);
            fbw_text(mx + 22, my + 200, "5. Tap [MOD] or active weapon slot to switch firing modes.", 2);
            fbw_text(mx + 22, my + 228, "6. Defeat The Singularity Boss in Inner Core to free 'K'!", 2);
            fbw_text(mx + 22, my + 256, "7. Spend gold at Upgrade Stations; dying loses armor & ammo!", 2);
        } else if st.screen == SCREEN_INFO_F2 {
            set_color(0x38BDF8FF);
            fbw_text(mx + 22, my + 54, "ARSENAL (TAP TO EQUIP / CYCLE FIRING MODE)", 2);
            var wi: i32 = 0;
            while wi < 10 {
                let col_i = wi / 5;
                let row_i = wi % 5;
                let rx1 = mx + 18 + col_i * ((mw - 42) / 2 + 6);
                let rw = (mw - 42) / 2;
                let ry1 = my + 80 + row_i * 38;
                let unl = st.wep_unlocked[wi] != 0;
                let eq = wi == st.weapon;
                fbw_box(rx1, ry1, rx1 + rw, ry1 + 32, if eq { 0x1E3A8AFF } else { 0x1E293BFF }, if eq { 0xFACC15FF } else { 0x475569FF });
                var wb: u8[160] = [0; 160];
                var wn: i32 = 0;
                buf_str(wb, wn, weapon_name(wi));
                buf_str(wb, wn, " ");
                if unl {
                    if st.max_ammo[wi] > 9000 { buf_str(wb, wn, "INF"); }
                    else { buf_int(wb, wn, st.ammo[wi]); buf_str(wb, wn, "/"); buf_int(wb, wn, st.max_ammo[wi]); }
                    buf_str(wb, wn, " ");
                    buf_str(wb, wn, weapon_mode_name(wi, st.wep_mode[wi]));
                } else {
                    buf_str(wb, wn, "[LOCKED]");
                }
                wb[wn] = 0;
                set_color(if unl { 0xF8FAFCFF } else { 0x64748BFF });
                fbw_text(rx1 + 8, ry1 + 8, wb[0..wn], 2);
                wi = wi + 1;
            }
        } else if st.screen == SCREEN_INFO_F3 {
            set_color(0xFACC15FF);
            var sb: u8[160] = [0; 160];
            var sn: i32 = 0;
            buf_str(sb, sn, "PROGRESS: KILLS "); buf_int(sb, sn, st.kills);
            buf_str(sb, sn, "  Lv"); buf_int(sb, sn, st.level);
            buf_str(sb, sn, "  XP "); buf_int(sb, sn, st.score_xp);
            buf_str(sb, sn, "  TROPHIES "); buf_int(sb, sn, st.trophies);
            buf_str(sb, sn, "/7  DEATHS "); buf_int(sb, sn, st.deaths);
            sb[sn] = 0;
            fbw_text(mx + 22, my + 56, sb[0..sn], 2);
            set_color(0x38BDF8FF);
            fbw_text(mx + 22, my + 86, if st.singularity_defeated != 0 { "SINGULARITY: DEFEATED (Quasar Drive Active!)" } else { "SINGULARITY: ACTIVE IN INNER CORE" }, 2);
            set_color(0xE2E8F0FF);
            fbw_text(mx + 22, my + 118, "MONSTER MANUAL:", 2);
            fbw_text(mx + 22, my + 144, "- Space Rat / Void Spider / Ying Goon: Swarm scouts", 2);
            fbw_text(mx + 22, my + 170, "- Slime Marine / Space Pirate / Menace Cube: Ranged", 2);
            fbw_text(mx + 22, my + 196, "- Pool Ball Guardian: Stun via Laser Cold Beam / EMP", 2);
            fbw_text(mx + 22, my + 222, "- Core Demon & Singularity: High HP, drops Trophies", 2);
        } else if st.screen == SCREEN_INFO_F4 {
            let page = clamp_i(g_mob.info_marker_page, 0, 2);
            let base = page * 5;
            var i: i32 = 0;
            while i < 5 {
                let slot = base + i;
                var mb: u8[160] = [0; 160];
                var ml: i32 = 0;
                buf_str(mb, ml, if slot == 0 { "Short: " } else { "Long " });
                if slot > 0 { buf_int(mb, ml, slot); buf_str(mb, ml, ": "); }
                if st.markers[slot].used != 0 {
                    buf_str(mb, ml, "LVL "); buf_int(mb, ml, st.markers[slot].depth);
                    buf_str(mb, ml, " "); buf_str(mb, ml, biome_name(st.markers[slot].biome));
                } else {
                    buf_str(mb, ml, if slot == 0 { "(Empty - tap MRK in HUD)" } else { "(Empty Long Marker)" });
                }
                mb[ml] = 0;
                draw_modal_row_h(mx, my + 52 + i * 38, mw, 34, mb[0..ml], 0x1E293BFF, if st.markers[slot].used != 0 { 0x4ADE80FF } else { 0x94A3B8FF });
                i = i + 1;
            }
            var pb: u8[160] = [0; 160];
            var pl: i32 = 0;
            buf_str(pb, pl, "NEXT PAGE ("); buf_int(pb, pl, page + 1); buf_str(pb, pl, "/3)");
            pb[pl] = 0;
            let hw = (mw - 42) / 2;
            fbw_box(mx + 18, my + mh - 108, mx + 18 + hw, my + mh - 68, 0x14532DFF, 0x4ADE80FF);
            set_color(0x4ADE80FF);
            fbw_text(mx + 26, my + mh - 96, "+ DROP LONG MARKER", 2);
            fbw_box(mx + 24 + hw, my + mh - 108, mx + mw - 18, my + mh - 68, 0x1E293BFF, 0x38BDF8FF);
            set_color(0x38BDF8FF);
            fbw_text(mx + 34 + hw, my + mh - 96, pb[0..pl], 2);
        } else {
            let cb = cur_biome();
            set_color(0x38BDF8FF);
            fbw_text(mx + 22, my + 56, tome_title(cb), 2);
            set_color(0xF8FAFCFF);
            fbw_text(mx + 22, my + 90, tome_body_line(cb, 0), 2);
            fbw_text(mx + 22, my + 120, tome_body_line(cb, 1), 2);
            fbw_text(mx + 22, my + 150, tome_body_line(cb, 2), 2);
            set_color(0xFACC15FF);
            fbw_text(mx + 22, my + 180, tome_body_line(cb, 3), 2);
            var tb: u8[160] = [0; 160];
            var tn: i32 = 0;
            var read_cnt: i32 = 0;
            var bi: i32 = 0;
            while bi < 10 {
                if (st.tome_read_mask & (1 << bi)) != 0 { read_cnt = read_cnt + 1; }
                bi = bi + 1;
            }
            buf_str(tb, tn, "Tomes Discovered: "); buf_int(tb, tn, read_cnt); buf_str(tb, tn, "/9  (Max Depth: ");
            buf_int(tb, tn, st.max_depth_reached); buf_str(tb, tn, ")");
            tb[tn] = 0;
            set_color(0x4ADE80FF);
            fbw_text(mx + 22, my + 220, tb[0..tn], 2);
        }
        draw_modal_row(mx, my + mh - 60, mw, "CLOSE COMPENDIUM", 0x334155FF, 0xFFFFFFFF);
    } else {
        set_color(0x38BDF8FF);
        fbw_text(mx + 22, my + 14, "FRACTAL BLOCK WORLD - PAUSED", 3);
        draw_modal_row_h(mx, my + 46,  mw, 36, "RESUME GAME", 0x065F46FF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 86,  mw, 36, if st.genesis_mode != 0 { "MODE: GENESIS (TAP FOR CLASSIC)" } else { "MODE: CLASSIC (TAP FOR GENESIS)" }, 0x1E3A8AFF, 0xFACC15FF);
        draw_modal_row_h(mx, my + 126, mw, 36, if st.shrink_any != 0 { "SHRINK ANY: ON (TAP TO TOGGLE)" } else { "SHRINK ANY: OFF (TAP TO TOGGLE)" }, 0x312E81FF, 0xFFFFFFFF);
        draw_modal_row_h(mx, my + 166, mw, 36, if st.disable_lod != 0 { "LOD OPT: OFF (ON-SCREEN FULL)" } else { "LOD OPT: ON (3-TIER 16/8/4X)" }, 0x0F766EFF, if st.disable_lod != 0 { 0x4ADE80FF } else { 0xFFFFFFFF });
        // Interactive LOD Distance Slider Bar (1..7)
        let sy = my + 206;
        fbw_box(mx + 18, sy, mx + mw - 18, sy + 36, 0x0F172AFF, 0x38BDF8FF);
        var lb: u8[160] = [0; 160];
        var ll: i32 = 0;
        let lv = clamp_i(st.lod_dist_level, 1, 7);
        buf_str(lb, ll, "LOD DIST: ");
        buf_int(lb, ll, lv);
        buf_str(lb, ll, "/7");
        lb[ll] = 0;
        set_color(0xFFFFFFFF);
        fbw_text(mx + 30, sy + 10, lb[0..ll], 2);
        let tx1 = mx + (mw * 42) / 100;
        let tx2 = mx + mw - 30;
        let tw = tx2 - tx1;
        fbw_box(tx1, sy + 11, tx2, sy + 25, 0x1E293BFF, 0x475569FF);
        let fx2 = tx1 + (tw * lv) / 7;
        set_color(if st.disable_lod != 0 { 0x64748BFF } else { 0x38BDF8FF });
        draw_rect(tx1 + 2, sy + 13, fx2 - 2, sy + 23);
        let kx = tx1 + (tw * (2 * lv - 1)) / 14;
        fbw_box(kx - 5, sy + 7, kx + 5, sy + 29, 0xFACC15FF, 0xFFFFFFFF);
        let vy = my + 246;
        fbw_box(mx + 18, vy, mx + mw - 18, vy + 36, 0x0F172AFF, 0x38BDF8FF);
        var vb: u8[160] = [0; 160];
        var vl: i32 = 0;
        let vr = clamp_i(st.view_chunk_radius, 1, 3);
        buf_str(vb, vl, "VIEW DIST: ");
        buf_int(vb, vl, vr);
        buf_str(vb, vl, " CHUNKS");
        vb[vl] = 0;
        set_color(0xFFFFFFFF);
        fbw_text(mx + 30, vy + 10, vb[0..vl], 2);
        let vx1 = mx + (mw * 42) / 100;
        let vx2 = mx + mw - 30;
        let vw = vx2 - vx1;
        fbw_box(vx1, vy + 11, vx2, vy + 25, 0x1E293BFF, 0x475569FF);
        let vfx = vx1 + (vw * vr) / 3;
        set_color(0x38BDF8FF);
        draw_rect(vx1 + 2, vy + 13, vfx - 2, vy + 23);
        let vkx = vx1 + (vw * (2 * vr - 1)) / 6;
        fbw_box(vkx - 5, vy + 7, vkx + 5, vy + 29, 0xFACC15FF, 0xFFFFFFFF);
        let rw2 = (mw - 42) / 2;
        draw_modal_row_h(mx + 18, my + 286, rw2, 36, "RESTART RUN", 0x7C2D12FF, 0xFFFFFFFF);
        draw_modal_row_h(mx + 24 + rw2, my + 286, rw2, 36, "EXIT", 0x7F1D1DFF, 0xFFFFFFFF);
    }
}

fn handle_modal_tap(x: i32, y: i32) {
    let st = core();
    let w = g_mob.lay.w;
    let h = g_mob.lay.h;
    let mw = clamp_i((w * 74) / 100, 440, 780);
    let mh = clamp_i((h * 80) / 100, 400, 580);
    let mx = (w - mw) / 2;
    let my = (h - mh) / 2;

    if x < mx || x > mx + mw || y < my || y > my + mh {
        st.screen = SCREEN_PLAY;
        return;
    }

    if in_box(x, y, mx + 18, my + mh - 60, mx + mw - 18, my + mh - 14) &&
       st.screen != SCREEN_PAUSE && st.screen != SCREEN_VICTORY {
        st.screen = SCREEN_PLAY;
        return;
    }

    if st.screen == SCREEN_BUY {
        var r: i32 = 0;
        while r < 11 {
            let ry = my + 48 + r * 40;
            if y >= ry && y <= ry + 34 {
                handle_buy_action(r + 1);
                drain_pending_sfx();
                return;
            }
            r = r + 1;
        }
    } else if st.screen == SCREEN_UPGRADE {
        var r: i32 = 0;
        while r < 10 {
            let ry = my + 48 + r * 40;
            if y >= ry && y <= ry + 34 {
                handle_upgrade_action(r + 1);
                drain_pending_sfx();
                return;
            }
            r = r + 1;
        }
    } else if st.screen == SCREEN_SELL {
        var r: i32 = 0;
        while r < 6 {
            let ry = my + 64 + r * 44;
            if y >= ry && y <= ry + 40 {
                handle_sell_action(r + 1);
                drain_pending_sfx();
                return;
            }
            r = r + 1;
        }
    } else if st.screen == SCREEN_BLACK_MARKET {
        var r: i32 = 0;
        while r < 4 {
            let ry = my + 64 + r * 56;
            if y >= ry && y <= ry + 46 {
                handle_black_market_action(r + 1);
                drain_pending_sfx();
                return;
            }
            r = r + 1;
        }
    } else if st.screen >= SCREEN_INFO_F1 && st.screen <= SCREEN_INFO_F5 {
        if y >= my + 10 && y <= my + 42 {
            let tw = (mw - 48) / 5;
            var ti: i32 = 0;
            while ti < 5 {
                let tx1 = mx + 14 + ti * (tw + 5);
                if x >= tx1 && x <= tx1 + tw {
                    st.screen = SCREEN_INFO_F1 + ti;
                    fbw_sound_fx(SFX_CLICK);
                    return;
                }
                ti = ti + 1;
            }
        }
        if st.screen == SCREEN_INFO_F2 {
            let rw = (mw - 42) / 2;
            var wi: i32 = 0;
            while wi < 10 {
                let col_i = wi / 5;
                let row_i = wi % 5;
                let rx1 = mx + 18 + col_i * (rw + 6);
                let ry1 = my + 80 + row_i * 38;
                if x >= rx1 && x <= rx1 + rw && y >= ry1 && y <= ry1 + 32 {
                    if st.wep_unlocked[wi] != 0 {
                        if st.weapon == wi { cycle_weapon_mode(); }
                        else { st.weapon = wi; fbw_sound_fx(SFX_CLICK); }
                    } else {
                        set_status_msg("Weapon locked! Find Weapon Module or Buy Station.", 1400);
                    }
                    drain_pending_sfx();
                    return;
                }
                wi = wi + 1;
            }
        } else if st.screen == SCREEN_INFO_F4 {
            if y >= my + mh - 108 && y <= my + mh - 68 {
                let hw = (mw - 42) / 2;
                if x <= mx + 18 + hw {
                    drop_marker(1);
                    drain_pending_sfx();
                } else {
                    g_mob.info_marker_page = (g_mob.info_marker_page + 1) % 3;
                    fbw_sound_fx(SFX_CLICK);
                }
                return;
            }
            let base = clamp_i(g_mob.info_marker_page, 0, 2) * 5;
            var i: i32 = 0;
            while i < 5 {
                let ry = my + 52 + i * 38;
                if y >= ry && y <= ry + 34 {
                    if warp_to_marker(base + i) != 0 {
                        st.screen = SCREEN_PLAY;
                        g_mob.sync_force = 1;
                        drain_pending_sfx();
                    }
                    return;
                }
                i = i + 1;
            }
        }
    } else if st.screen == SCREEN_VICTORY {
        if y >= my + 140 && y <= my + 186 { st.screen = SCREEN_PLAY; return; }
        if y >= my + 200 && y <= my + 246 { init_new_game(); st.screen = SCREEN_PLAY; g_mob.sync_force = 1; return; }
        if y >= my + 260 && y <= my + 306 { g_mob.want_exit_to_calc = 1; return; }
    } else if st.screen == SCREEN_PAUSE {
        if y >= my + 46 && y <= my + 82 { st.screen = SCREEN_PLAY; return; }
        if y >= my + 86 && y <= my + 122 {
            st.genesis_mode = if st.genesis_mode != 0 { 0 } else { 1 };
            init_new_game();
            st.screen = SCREEN_PLAY;
            g_mob.sync_force = 1;
            return;
        }
        if y >= my + 126 && y <= my + 162 {
            st.shrink_any = if st.shrink_any != 0 { 0 } else { 1 };
            st.screen = SCREEN_PLAY;
            return;
        }
        if y >= my + 166 && y <= my + 202 {
            st.disable_lod = if st.disable_lod != 0 { 0 } else { 1 };
            g_mob.inw_force = 1;
            fbw_gl_set_lod_config(st.disable_lod, st.lod_dist_level);
            set_status_msg(if st.disable_lod != 0 { "LOD Opt OFF: Full On-Screen Detail" } else { "LOD Opt ON: 3-Tier Volumetric" }, 1400);
            st.screen = SCREEN_PLAY;
            return;
        }
        if y >= my + 206 && y <= my + 242 {
            let tx1 = mx + (mw * 42) / 100;
            let tx2 = mx + mw - 30;
            let tw = tx2 - tx1;
            var lv = st.lod_dist_level;
            if x >= tx1 - 10 && tw > 0 {
                lv = clamp_i(1 + ((x - tx1) * 7) / tw, 1, 7);
            } else {
                lv = (clamp_i(lv, 1, 7) % 7) + 1;
            }
            st.lod_dist_level = lv;
            g_mob.inw_force = 1;
            fbw_gl_set_lod_config(st.disable_lod, st.lod_dist_level);
            fbw_sound_fx(0);
            return;
        }
        if y >= my + 246 && y <= my + 282 {
            let vx1 = mx + (mw * 42) / 100;
            let vx2 = mx + mw - 30;
            let vw = vx2 - vx1;
            var vr = st.view_chunk_radius;
            if x >= vx1 - 10 && vw > 0 {
                vr = clamp_i(1 + ((x - vx1) * 3) / vw, 1, 3);
            } else {
                vr = (clamp_i(vr, 1, 3) % 3) + 1;
            }
            if vr != st.view_chunk_radius {
                st.view_chunk_radius = vr;
                load_current_chunk();
                var nv: i32 = 0;
                var ci: i32 = 0;
                while ci < MAX_NEIGHBORS {
                    if st.neighbor_valid[ci] != 0 { nv = nv + 1; }
                    ci = ci + 1;
                }
                g_mob.sync_force = 1;
                var mb: u8[160] = [0; 160];
                var ml: i32 = 0;
                buf_str(mb, ml, "VIEW DIST: ");
                buf_int(mb, ml, vr);
                buf_str(mb, ml, " CHUNKS (");
                buf_int(mb, ml, nv);
                buf_str(mb, ml, " LOADED)");
                mb[ml] = 0;
                set_status_msg(mb[0..ml], 1600);
            }
            fbw_sound_fx(0);
            return;
        }
        let rw2 = (mw - 42) / 2;
        if in_box(x, y, mx + 18, my + 286, mx + 18 + rw2, my + 322) {
            init_new_game();
            st.screen = SCREEN_PLAY;
            g_mob.sync_force = 1;
            return;
        }
        if in_box(x, y, mx + 24 + rw2, my + 286, mx + mw - 18, my + 322) {
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

    let btn_w = clamp_i(l.w / 15, 56, 86);
    let gap: i32 = 5;
    var bx = l.w - 10 - btn_w;

    if x >= bx && x <= bx + btn_w {
        st.screen = if st.screen == SCREEN_PAUSE { SCREEN_PLAY } else { SCREEN_PAUSE };
        return true;
    }
    bx = bx - btn_w - gap;
    if x >= bx && x <= bx + btn_w {
        st.screen = if st.screen >= SCREEN_INFO_F1 && st.screen <= SCREEN_INFO_F5 { SCREEN_PLAY } else { SCREEN_INFO_F4 };
        return true;
    }
    bx = bx - btn_w - gap;
    if x >= bx && x <= bx + btn_w {
        drop_marker(0);
        drain_pending_sfx();
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
            g_mob.ptrs[pid].active = 1;
            g_mob.ptrs[pid].role = ACT_NONE;
            g_mob.ptrs[pid].cur_x = x;
            g_mob.ptrs[pid].cur_y = y;
            handle_modal_tap(x, y);
            drain_pending_sfx();
            return;
        }
        if handle_top_bar_tap(x, y) {
            drain_pending_sfx();
            return;
        }

        // Bottom 10-weapon strip + [MOD] mode button tap
        if y >= l.wep_y1 && y <= l.wep_y2 {
            let mod_w = clamp_i(l.w / 14, 62, 86);
            let wep_area_w = l.w - 34 - mod_w;
            let slot_w = wep_area_w / NUM_WEAPONS;
            let mod_x1 = 14 + NUM_WEAPONS * slot_w + 2;
            if x >= mod_x1 {
                cycle_weapon_mode();
            } else if slot_w > 0 {
                let wi = clamp_i((x - 14) / slot_w, 0, NUM_WEAPONS - 1);
                if st.wep_unlocked[wi] != 0 {
                    if st.weapon == wi {
                        cycle_weapon_mode();
                    } else {
                        st.weapon = wi;
                        fbw_sound_fx(SFX_CLICK);
                    }
                } else {
                    set_status_msg("Weapon locked! Find Weapon Module or Buy Station.", 1400);
                }
            }
            drain_pending_sfx();
            return;
        }

        var role = ACT_NONE;
        if in_box(x, y, l.fire_x1, l.fire_y1, l.fire_x2, l.fire_y2) {
            role = ACT_FIRE;
            fire_weapon(0);
        } else if in_box(x, y, l.alt_x1, l.alt_y1, l.alt_x2, l.alt_y2) {
            role = ACT_ALT;
            fire_weapon(1);
        } else if in_box(x, y, l.use_x1, l.use_y1, l.use_x2, l.use_y2) {
            role = ACT_USE;
            use_nearest();
            g_mob.sync_force = 1;
        } else if in_box(x, y, l.shk_x1, l.shk_y1, l.shk_x2, l.shk_y2) {
            role = ACT_SHRINK;
            shrink_targeted_block();
            g_mob.sync_force = 1;
        } else if in_box(x, y, l.grw_x1, l.grw_y1, l.grw_x2, l.grw_y2) {
            role = ACT_GROW;
            grow_in_place();
            g_mob.sync_force = 1;
        } else if in_box(x, y, l.tk_x1, l.tk_y1, l.tk_x2, l.tk_y2) {
            role = ACT_TK;
            trigger_telekinesis();
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
        drain_pending_sfx();
        recompute_held_flags();
    } else if ev_type == PTR_MOVE {
        if g_mob.ptrs[pid].active == 0 { return; }
        let dx = x - g_mob.ptrs[pid].last_x;
        let dy = y - g_mob.ptrs[pid].last_y;
        g_mob.ptrs[pid].last_x = x;
        g_mob.ptrs[pid].last_y = y;
        g_mob.ptrs[pid].cur_x = x;
        g_mob.ptrs[pid].cur_y = y;
        if st.screen == SCREEN_PAUSE {
            let mw = clamp_i((l.w * 74) / 100, 440, 780);
            let mh = clamp_i((l.h * 80) / 100, 340, 580);
            let mx = (l.w - mw) / 2;
            let my = (l.h - mh) / 2;
            let tx1 = mx + (mw * 42) / 100;
            let tx2 = mx + mw - 30;
            let tw = tx2 - tx1;
            if y >= my + 206 && y <= my + 242 && x >= tx1 - 10 && x <= tx2 + 10 && tw > 0 {
                let lv = clamp_i(1 + ((x - tx1) * 7) / tw, 1, 7);
                if lv != st.lod_dist_level {
                    st.lod_dist_level = lv;
                    g_mob.inw_force = 1;
                    fbw_gl_set_lod_config(st.disable_lod, st.lod_dist_level);
                }
            }
        } else if g_mob.ptrs[pid].role == ACT_LOOK && st.screen == SCREEN_PLAY {
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
