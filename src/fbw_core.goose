// fbw_core.goose — Pure Simulation & Fractal World Engine for Fractal Block World (Xar)
// Zero terminal/rendering dependency so core mechanics can be unit-tested directly.

const PI: f64 = 3.14159265358979323846;
const TAU: f64 = 6.28318530717958647692;
const HALF_PI: f64 = 1.57079632679489661923;

const CHUNK_DIM: i32 = 16;
const CHUNK_VOL: i32 = 4096;

const MAX_POS_DEPTH: i32 = 3000;
const MAX_NEG_DEPTH: i32 = -128;

const MAX_ENTITIES: i32 = 96;
const MAX_SHOTS: i32 = 72;
const MAX_PARTICLES: i32 = 72;
const MAX_DELTAS: i32 = 512;
const MAX_MARKERS: i32 = 16;

const MAX_GOLD: i32 = 1000000;
const DEATH_GOLD_PENALTY: i32 = 30;

// Screen / Modal states
const SCREEN_TITLE: i32 = 0;
const SCREEN_PLAY: i32 = 1;
const SCREEN_BUY: i32 = 2;
const SCREEN_SELL: i32 = 3;
const SCREEN_BLACK_MARKET: i32 = 4;
const SCREEN_PAUSE: i32 = 5;
const SCREEN_INFO_F1: i32 = 6;
const SCREEN_INFO_F2: i32 = 7;
const SCREEN_INFO_F3: i32 = 8;
const SCREEN_INFO_F4: i32 = 9;
const SCREEN_INFO_F5: i32 = 10;
const SCREEN_TOME: i32 = 11;
const SCREEN_VICTORY: i32 = 12;

// Biomes (Authentic Xar Progression)
const BIOME_SPACE: i32 = 0;         // Outer Space Level 0 (depth < 0)
const BIOME_TUTORIAL: i32 = 1;      // Tutorial Room & Tutorial Island (depth == 0)
const BIOME_YING_FOREST: i32 = 2;   // Ying Forest (Ying Trees, Totems, Flowers)
const BIOME_WHITE_FLOWER: i32 = 3;  // Small White Flower / Alpha Cube
const BIOME_YELLOW_FLOWER: i32 = 4; // Small & Jumbo Yellow Flower Labyrinths
const BIOME_MYLANTIS: i32 = 5;      // Mylantis Crust & Caves
const BIOME_BLACK_CUBE: i32 = 6;    // Black Cube / I1 / I2 / I3 Menger Lattice
const BIOME_INNER_CORE: i32 = 7;    // The Core / Singularity & K

// Block IDs
const BLK_AIR: u8 = 0;
const BLK_WALL_TUT: u8 = 1;
const BLK_GRASS: u8 = 2;
const BLK_DIRT: u8 = 3;
const BLK_WOOD: u8 = 4;
const BLK_LEAVES: u8 = 5;
const BLK_PETAL_Y: u8 = 6;
const BLK_POLLEN: u8 = 7;
const BLK_PETAL_W: u8 = 8;
const BLK_MYLANTIS: u8 = 9;
const BLK_ICE: u8 = 10;
const BLK_SAND: u8 = 11;
const BLK_GLASS: u8 = 12;
const BLK_STONE: u8 = 13;
const BLK_GOLD_ORE: u8 = 14;
const BLK_CRATE: u8 = 15;
const BLK_SPAWNER: u8 = 16;
const BLK_LOCKED_DOOR: u8 = 17;

// Shrinkable Fractal Portal Blocks (fly into or press F to shrink 16x deeper!)
const BLK_BLACK_CUBE: u8 = 20;
const BLK_WHITE_FLOWER: u8 = 21;
const BLK_ALPHA_CUBE: u8 = 22;
const BLK_FLOWER_Y_CORE: u8 = 23;
const BLK_MYLANTIS_M: u8 = 24;
const BLK_YING_PLANET: u8 = 25;
const BLK_ICE_WORLD: u8 = 26;
const BLK_DESERT_WORLD: u8 = 27;
const BLK_CORE_GATE: u8 = 28;

// Interactive Station & Upgrade Blocks
const BLK_BUY_STATION: u8 = 32;
const BLK_SELL_STATION: u8 = 33;
const BLK_BLACK_MARKET: u8 = 34;
const BLK_TOME: u8 = 35;
const BLK_UPG_HP: u8 = 36;
const BLK_UPG_REGEN: u8 = 37;
const BLK_UPG_ARMOR: u8 = 38;
const BLK_UPG_DMG: u8 = 39;
const BLK_UPG_ROF: u8 = 40;
const BLK_UPG_AMMO: u8 = 41;
const BLK_UPG_SPEED: u8 = 42;
const BLK_KEY_BLOCK: u8 = 43;
const BLK_UPG_WEP: u8 = 44;

// Entity kinds
const ENT_NONE: i32 = 0;
const ENT_RING_GREEN: i32 = 1;  // Shrink 16x (1 level)
const ENT_RING_RED: i32 = 2;    // Grow 16x outward
const ENT_RING_BLUE: i32 = 3;   // Mylantis / Biome Teleporter
const ENT_RING_PINK: i32 = 4;   // Deep Dive 256x (2 levels)

// Xar Monster Manual Enemies
const ENT_RAT: i32 = 5;
const ENT_SPIDER: i32 = 6;
const ENT_GOON: i32 = 7;
const ENT_GOBLIN: i32 = 7;
const ENT_MARINE: i32 = 8;
const ENT_PIRATE: i32 = 9;
const ENT_YINYANG: i32 = 10;
const ENT_MENACE: i32 = 11;
const ENT_DEMON: i32 = 12;
const ENT_GUARDIAN: i32 = 13;   // Pool Ball / Guardian (freezable by Laser 2nd / EMP!)
const ENT_SINGULARITY: i32 = 14; // Core Boss

// Pickups & NPC
const ENT_GOLD: i32 = 15;
const ENT_HEALTH: i32 = 16;
const ENT_ARMOR: i32 = 17;
const ENT_AMMO: i32 = 18;
const ENT_KEY: i32 = 19;
const ENT_FRIEND_K: i32 = 20;

// 10 Authentic Weapons (Keys 1..9, 0)
const WEP_PLASMA: i32 = 0;   // 1
const WEP_CANNON: i32 = 1;   // 2
const WEP_LASER: i32 = 2;    // 3
const WEP_ROCKET: i32 = 3;   // 4
const WEP_HOMING: i32 = 4;   // 5
const WEP_MINIGUN: i32 = 5;  // 6
const WEP_RAILGUN: i32 = 6;  // 7
const WEP_EMP: i32 = 7;      // 8
const WEP_NUKE: i32 = 8;     // 9
const WEP_DARKHOLE: i32 = 9; // 0
const NUM_WEAPONS: i32 = 10;

struct ScaleFrame {
    bx: i32,
    by: i32,
    bz: i32,
    biome: i32,
    parent_block: u8,
    seed: u64,
}

struct Entity {
    kind: i32,
    x: f64,
    y: f64,
    z: f64,
    vx: f64,
    vy: f64,
    vz: f64,
    hp: i32,
    max_hp: i32,
    cooldown: i32,
    freeze_ms: i32,
    target_biome: i32,
    target_block: u8,
    active: i32,
}

struct Shot {
    active: i32,
    from_player: i32,
    wep: i32,
    secondary: i32,
    x: f64,
    y: f64,
    z: f64,
    vx: f64,
    vy: f64,
    vz: f64,
    dmg: i32,
    ttl_ms: i32,
    rgb: u32,
}

struct Particle {
    active: i32,
    x: f64,
    y: f64,
    z: f64,
    vx: f64,
    vy: f64,
    vz: f64,
    ttl_ms: i32,
    rgb: u32,
}

struct BlockDelta {
    used: i32,
    seed: u64,
    bx: u8,
    by: u8,
    bz: u8,
    blk: u8,
}

struct Marker {
    used: i32,
    is_long: i32,
    depth: i32,
    px: f64,
    py: f64,
    pz: f64,
    biome: i32,
    pos_off: i32,
    pos_cnt: i32,
    neg_off: i32,
    neg_cnt: i32,
}

root struct fbw_state {
    // Viewport & rendering flags (used by frontend)
    term_w: i32,
    term_h: i32,
    pw: i32,
    ph: i32,
    screen: i32,
    truecolor: i32,
    show_minimap: i32,
    render_scale: i32,
    is_termux: i32,
    modal_bg_ready: i32,
    genesis_mode: i32, // 1 = Peaceful Genesis Mode (no monsters)
    shrink_any: i32,   // 1 = Shrink into ANY touched block (Xar 'shrinkany')

    // Unbounded recursive 16x16x16 world stack (-128..3000)
    blocks: u8[CHUNK_VOL],
    parent_blocks: u8[12288], // MAX_PARENT_VIS (3) * CHUNK_VOL
    scratch_blocks: u8[CHUNK_VOL],
    inward_blocks: u8[1048576], // 256-slot * CHUNK_VOL multi-layer 3D sub-voxel cache
    inward_seeds: u64[256],
    inward_blks: u8[256],
    inward_depths: i32[256],
    inward_used: i32[256],
    inward_next: i32,
    parent_bx: i32[3],
    parent_by: i32[3],
    parent_bz: i32[3],
    parent_biome: i32[3],
    parent_depth: i32[3],
    parent_seed: u64[3],
    parent_valid: i32[3],
    pos_stack: ScaleFrame[>..],
    neg_stack: ScaleFrame[>..],
    marker_frames: ScaleFrame[>..],
    marker_frames_len: i32,
    depth: i32, // 0 = Tutorial Island, <0 = Outer Space, >0 = Deep Fractals
    max_depth_reached: i32,
    min_depth_reached: i32,

    // Player 6-DOF kinematics
    px: f64,
    py: f64,
    pz: f64,
    vx: f64,
    vy: f64,
    vz: f64,
    yaw: f64,
    pitch: f64,
    roll: f64,
    yaw_vel: f64,
    pitch_vel: f64,
    turning_ms: i32,
    true_up: i32,     // 1 = True Up locks horizon level; 0 = Q/E roll freely
    rocket_mode: i32, // 1 = Low-drag Rocket Mode (Tab)

    // Player stats & economy
    hp: i32,
    max_hp: i32,
    hp_regen: i32,    // HP restored per 2 seconds
    regen_accum_ms: i32,
    armor: i32,
    max_armor: i32,
    gold: i32,
    keys: i32,
    kills: i32,
    deaths: i32,
    quasar_drive: i32, // Unlocked by defeating The Singularity
    k_rescued: i32,
    telekinesis_ms: i32,

    // 10 Weapons & Upgrade levels
    weapon: i32,
    wep_unlocked: i32[NUM_WEAPONS],
    ammo: i32[NUM_WEAPONS],
    max_ammo: i32[NUM_WEAPONS],
    dmg_lvl: i32,
    rof_lvl: i32,
    spd_lvl: i32,
    ammo_cap_lvl: i32,
    fire_cd_ms: i32,
    ring_cd_ms: i32,

    // Hitscan beam visual
    beam_timer_ms: i32,
    beam_rgb: u32,
    beam_x1: f64,
    beam_y1: f64,
    beam_z1: f64,
    beam_x2: f64,
    beam_y2: f64,
    beam_z2: f64,

    // Markers (Short & Long)
    markers: Marker[MAX_MARKERS],
    active_marker: i32,

    // Mouse drag tracking
    mouse_last_x: i32,
    mouse_last_y: i32,
    mouse_dragging: i32,
    mouse_drag_moved: i32,

    // Feedback / Flash / Lore Tome
    flash_ms: i32,
    flash_rgb: u32,
    msg_ms: i32,
    msg_len: i32,
    msg_buf: u8[128],
    tome_id: i32,

    // Crosshair target readout
    target_name_len: i32,
    target_name: u8[40],
    target_hp: i32,
    target_max_hp: i32,
    near_ring_kind: i32,
    near_prompt_len: i32,
    near_prompt: u8[64],

    // Simulation arrays
    entities: Entity[MAX_ENTITIES],
    shots: Shot[MAX_SHOTS],
    particles: Particle[MAX_PARTICLES],
    deltas: BlockDelta[MAX_DELTAS],
    delta_head: i32,

    // Framebuffer
    fb_rgb: u32[33600],
    fb_z: f64[33600],

    // PRNG & Timing
    rng: u64,
    tick_ms: i64,
    fps: i32,
    frame_cnt: i32,
    fps_last_ms: i64,
    anim_ms: i64,
}

var st: fbw_state;

fn core() -> fbw_state& {
    return st;
}

// ---------------------------------------------------------------------------
// Pure Goose Math Helpers
// ---------------------------------------------------------------------------
fn fabs(x: f64) -> f64 {
    if x < 0.0 { return -x; }
    return x;
}

fn fmin(a: f64, b: f64) -> f64 {
    if a < b { return a; }
    return b;
}

fn fmax(a: f64, b: f64) -> f64 {
    if a > b { return a; }
    return b;
}

fn fclamp(x: f64, lo: f64, hi: f64) -> f64 {
    if x < lo { return lo; }
    if x > hi { return hi; }
    return x;
}

fn ffloor(x: f64) -> i32 {
    let i = x as! i32;
    if i > x { return i - 1; }
    return i;
}

fn clamp_i(v: i32, lo: i32, hi: i32) -> i32 {
    if v < lo { return lo; }
    if v > hi { return hi; }
    return v;
}

fn fsqrt(x: f64) -> f64 {
    if x <= 0.0 { return 0.0; }
    var v: f64 = x;
    var scale: f64 = 1.0;
    var k: i32 = 0;
    while v > 4.0 && k < 24 {
        v = v * 0.25;
        scale = scale * 2.0;
        k = k + 1;
    }
    while v < 0.25 && k < 24 {
        v = v * 4.0;
        scale = scale * 0.5;
        k = k + 1;
    }
    var g: f64 = (0.5 + 0.5 * v) * scale;
    var i: i32 = 0;
    while i < 7 {
        g = 0.5 * (g + x / g);
        i = i + 1;
    }
    return g;
}

fn wrap_angle(a_in: f64) -> f64 {
    var a: f64 = a_in;
    while a > PI { a = a - TAU; }
    while a < -PI { a = a + TAU; }
    return a;
}

fn fsin(x_in: f64) -> f64 {
    var x: f64 = wrap_angle(x_in);
    if x > HALF_PI { x = PI - x; }
    if x < -HALF_PI { x = -PI - x; }
    let x2 = x * x;
    let x3 = x2 * x;
    let x5 = x3 * x2;
    let x7 = x5 * x2;
    let x9 = x7 * x2;
    return x - (x3 / 6.0) + (x5 / 120.0) - (x7 / 5040.0) + (x9 / 362880.0);
}

fn fcos(x_in: f64) -> f64 {
    return fsin(x_in + HALF_PI);
}

// ---------------------------------------------------------------------------
// Hashing, PRNG & Color Helpers
// ---------------------------------------------------------------------------
fn splitmix64(x_in: u64) -> u64 {
    var z: u64 = x_in + 0x9e3779b97f4a7c15;
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9;
    z = (z ^ (z >> 27)) * 0x94d049bb133111eb;
    return z ^ (z >> 31);
}

fn hash_block_seed(parent_seed: u64, bx: i32, by: i32, bz: i32, depth: i32) -> u64 {
    let h1 = splitmix64(parent_seed ^ ((bx as u64) * 0x517cc1b727220a95));
    let h2 = splitmix64(h1 ^ ((by as u64) * 0x94d049bb133111eb));
    let h3 = splitmix64(h2 ^ ((bz as u64) * 0xbf58476d1ce4e5b9));
    return splitmix64(h3 ^ ((depth + 128) as u64));
}

fn rng_u32() -> u32 {
    st.rng = splitmix64(st.rng);
    return (st.rng >> 16) as! u32;
}

fn rng_range(lo: i32, hi: i32) -> i32 {
    if hi <= lo { return lo; }
    let span = (hi - lo + 1) as u32;
    return lo + ((rng_u32() % span) as! i32);
}

fn rng_f01() -> f64 {
    return (rng_u32() & 0xffff) / 65536.0;
}

fn pack_rgb(r_in: i32, g_in: i32, b_in: i32) -> u32 {
    let r = clamp_i(r_in, 0, 255) as! u32;
    let g = clamp_i(g_in, 0, 255) as! u32;
    let b = clamp_i(b_in, 0, 255) as! u32;
    return (r << 16) | (g << 8) | b;
}

fn scale_rgb(rgb: u32, mul: f64) -> u32 {
    let r = ((rgb >> 16) & 0xff) * mul;
    let g = ((rgb >> 8) & 0xff) * mul;
    let b = (rgb & 0xff) * mul;
    return pack_rgb(r as! i32, g as! i32, b as! i32);
}

fn lerp_rgb(c1: u32, c2: u32, t_in: f64) -> u32 {
    let t = fclamp(t_in, 0.0, 1.0);
    let it = 1.0 - t;
    let r1 = ((c1 >> 16) & 0xff) as f64;
    let g1 = ((c1 >> 8) & 0xff) as f64;
    let b1 = (c1 & 0xff) as f64;
    let r2 = ((c2 >> 16) & 0xff) as f64;
    let g2 = ((c2 >> 8) & 0xff) as f64;
    let b2 = (c2 & 0xff) as f64;
    return pack_rgb((r1 * it + r2 * t) as! i32, (g1 * it + g2 * t) as! i32, (b1 * it + b2 * t) as! i32);
}

// ---------------------------------------------------------------------------
// Messages & Names
// ---------------------------------------------------------------------------
fn set_status_msg(msg: const u8[:], ms: i32) {
    var n: i32 = msg.len as! i32;
    if n > 127 { n = 127; }
    var i: i32 = 0;
    while i < n {
        st.msg_buf[i] = msg[i];
        i = i + 1;
    }
    st.msg_len = n;
    st.msg_ms = ms;
}

fn set_target_name(name: const u8[:], hp: i32, max_hp: i32) {
    var n: i32 = name.len as! i32;
    if n > 39 { n = 39; }
    var i: i32 = 0;
    while i < n {
        st.target_name[i] = name[i];
        i = i + 1;
    }
    st.target_name_len = n;
    st.target_hp = hp;
    st.target_max_hp = max_hp;
}

fn set_near_prompt(msg: const u8[:]) {
    var n: i32 = msg.len as! i32;
    if n > 63 { n = 63; }
    var i: i32 = 0;
    while i < n {
        st.near_prompt[i] = msg[i];
        i = i + 1;
    }
    st.near_prompt_len = n;
}

// ---------------------------------------------------------------------------
// Block & Biome Helpers
// ---------------------------------------------------------------------------
fn b_idx(x: i32, y: i32, z: i32) -> i32 {
    return (y << 8) | (z << 4) | x;
}

fn get_block(x: i32, y: i32, z: i32) -> u8 {
    if x < 0 || x >= CHUNK_DIM || y < 0 || y >= CHUNK_DIM || z < 0 || z >= CHUNK_DIM {
        return BLK_AIR;
    }
    return st.blocks[b_idx(x, y, z)];
}

fn set_block(x: i32, y: i32, z: i32, b: u8) {
    if x < 0 || x >= CHUNK_DIM || y < 0 || y >= CHUNK_DIM || z < 0 || z >= CHUNK_DIM {
        return;
    }
    st.blocks[b_idx(x, y, z)] = b;
}

fn dst_set_block(dst_layer: i32, x: i32, y: i32, z: i32, b: u8) {
    if x < 0 || x >= CHUNK_DIM || y < 0 || y >= CHUNK_DIM || z < 0 || z >= CHUNK_DIM {
        return;
    }
    let idx = b_idx(x, y, z);
    if dst_layer < 0 {
        st.blocks[idx] = b;
    } else if dst_layer == 3 {
        st.scratch_blocks[idx] = b;
    } else if dst_layer >= 10 {
        st.inward_blocks[(dst_layer - 10) * CHUNK_VOL + idx] = b;
    } else {
        st.parent_blocks[dst_layer * CHUNK_VOL + idx] = b;
    }
}

fn dst_get_block(dst_layer: i32, x: i32, y: i32, z: i32) -> u8 {
    if x < 0 || x >= CHUNK_DIM || y < 0 || y >= CHUNK_DIM || z < 0 || z >= CHUNK_DIM {
        return BLK_AIR;
    }
    let idx = b_idx(x, y, z);
    if dst_layer < 0 {
        return st.blocks[idx];
    } else if dst_layer == 3 {
        return st.scratch_blocks[idx];
    } else if dst_layer >= 10 {
        return st.inward_blocks[(dst_layer - 10) * CHUNK_VOL + idx];
    }
    return st.parent_blocks[dst_layer * CHUNK_VOL + idx];
}

fn get_parent_block(layer: i32, x: i32, y: i32, z: i32) -> u8 {
    if layer < 0 || layer >= 3 { return BLK_AIR; }
    if x < 0 || x >= CHUNK_DIM || y < 0 || y >= CHUNK_DIM || z < 0 || z >= CHUNK_DIM {
        return BLK_AIR;
    }
    return st.parent_blocks[layer * CHUNK_VOL + b_idx(x, y, z)];
}

fn ensure_depth_slot(d: i32) {
    if d >= 0 {
        while (st.pos_stack.len as! i32) <= d {
            st.pos_stack.push(ScaleFrame {
                bx: 8, by: 7, bz: 8,
                biome: BIOME_BLACK_CUBE, parent_block: BLK_BLACK_CUBE, seed: 0
            });
        }
    } else {
        let ni = (-d) - 1;
        while (st.neg_stack.len as! i32) <= ni {
            st.neg_stack.push(ScaleFrame {
                bx: 8, by: 7, bz: 8,
                biome: BIOME_SPACE, parent_block: BLK_YING_PLANET, seed: 0
            });
        }
    }
}

fn get_frame(d: i32) -> ScaleFrame {
    ensure_depth_slot(d);
    if d >= 0 { return st.pos_stack[d]; }
    return st.neg_stack[(-d) - 1];
}

fn set_frame(d: i32, f: ScaleFrame) {
    ensure_depth_slot(d);
    if d >= 0 { st.pos_stack[d] = f; }
    else { st.neg_stack[(-d) - 1] = f; }
}

fn ensure_neg_frame_seed(d: i32) {
    if d >= 0 { return; }
    let nf = get_frame(d);
    if nf.seed == 0 {
        let mseed = hash_block_seed(0x4642575f584152, 8, 7, 8, d);
        set_frame(d, ScaleFrame {
            bx: 8, by: 7, bz: 8,
            biome: BIOME_SPACE, parent_block: BLK_YING_PLANET, seed: mseed
        });
    }
}

fn cur_biome() -> i32 {
    return get_frame(st.depth).biome;
}

fn cur_parent_block() -> u8 {
    return get_frame(st.depth).parent_block;
}

fn cur_seed() -> u64 {
    return get_frame(st.depth).seed;
}

fn invalidate_inward_cache() {
    var i: i32 = 0;
    while i < 256 {
        st.inward_used[i] = 0;
        i = i + 1;
    }
}

fn compute_air_depth(d_in: i32) -> i32 {
    var cnt: i32 = 0;
    var d: i32 = d_in;
    while d >= MAX_NEG_DEPTH && cnt < 32 {
        let f = get_frame(d);
        if f.parent_block != BLK_AIR {
            break;
        }
        cnt = cnt + 1;
        d = d - 1;
    }
    return cnt;
}

fn record_block_delta(bx: i32, by: i32, bz: i32, b: u8) {
    invalidate_inward_cache();
    let seed = cur_seed();
    var i: i32 = 0;
    while i < MAX_DELTAS {
        if st.deltas[i].used != 0 &&
           st.deltas[i].seed == seed &&
           st.deltas[i].bx == bx &&
           st.deltas[i].by == by &&
           st.deltas[i].bz == bz {
            st.deltas[i].blk = b;
            return;
        }
        i = i + 1;
    }
    let idx = st.delta_head;
    st.deltas[idx].used = 1;
    st.deltas[idx].seed = seed;
    st.deltas[idx].bx = bx as! u8;
    st.deltas[idx].by = by as! u8;
    st.deltas[idx].bz = bz as! u8;
    st.deltas[idx].blk = b;
    st.delta_head = (st.delta_head + 1) % MAX_DELTAS;
}

fn is_block_solid(b: u8) -> i32 {
    if b == BLK_AIR { return 0; }
    return 1;
}

fn is_block_shrinkable(b: u8) -> i32 {
    if b == BLK_BLACK_CUBE || b == BLK_WHITE_FLOWER || b == BLK_ALPHA_CUBE ||
       b == BLK_FLOWER_Y_CORE || b == BLK_MYLANTIS_M || b == BLK_YING_PLANET ||
       b == BLK_ICE_WORLD || b == BLK_DESERT_WORLD || b == BLK_CORE_GATE {
        return 1;
    }
    return 0;
}

fn is_block_subdivisible(b: u8) -> i32 {
    if is_block_shrinkable(b) != 0 { return 1; }
    if b == BLK_WALL_TUT || b == BLK_GRASS || b == BLK_DIRT || b == BLK_WOOD ||
       b == BLK_LEAVES || b == BLK_PETAL_Y || b == BLK_POLLEN || b == BLK_PETAL_W ||
       b == BLK_MYLANTIS || b == BLK_ICE || b == BLK_SAND || b == BLK_STONE ||
       b == BLK_GOLD_ORE {
        return 1;
    }
    return 0;
}

fn should_render_hole_lod_ex(depth: i32, hit_layer: i32, hit_blk: u8, hit_t: f64, is_turning: i32) -> i32 {
    if depth <= 0 || hit_layer <= 0 { return 0; }
    if is_block_subdivisible(hit_blk) == 0 { return 0; }
    if is_block_shrinkable(hit_blk) == 0 && depth < 3 && hit_layer < 3 { return 0; }
    if is_turning != 0 {
        if hit_layer >= 2 { return 0; }
        return if hit_t < 15.0 { 1 } else { 0 };
    }
    if hit_layer == 1 {
        let cap1 = if depth >= 3 { 18.0 } else { 22.0 };
        return if hit_t < cap1 { 1 } else { 0 };
    }
    if hit_layer == 2 {
        let cap2 = if depth >= 3 { 56.0 } else { 84.0 };
        return if hit_t < cap2 { 1 } else { 0 };
    }
    if hit_layer == 3 {
        let cap3 = if depth >= 3 { 150.0 } else { 260.0 };
        return if hit_t < cap3 { 1 } else { 0 };
    }
    return 0;
}

fn should_render_hole_lod(depth: i32, hit_layer: i32, hit_blk: u8, hit_t: f64) -> i32 {
    return should_render_hole_lod_ex(depth, hit_layer, hit_blk, hit_t, 0);
}

fn subvoxel_max_steps(hit_layer: i32, hit_t: f64, is_turning: i32) -> i32 {
    if is_turning != 0 { return 12; }
    if hit_layer == 1 {
        if hit_t < 10.0 { return 24; }
        return 16;
    }
    if hit_layer == 2 {
        if hit_t < 32.0 { return 18; }
        return 11;
    }
    if hit_t < 110.0 { return 14; }
    return 9;
}

fn is_block_upgrade(b: u8) -> i32 {
    if b >= BLK_UPG_HP && b <= BLK_UPG_WEP { return 1; }
    return 0;
}

fn is_block_destructible(b: u8) -> i32 {
    if b == BLK_CRATE || b == BLK_SPAWNER || b == BLK_GOLD_ORE { return 1; }
    return 0;
}

fn biome_name(biome: i32) -> const u8[:] {
    if biome == BIOME_SPACE { return "Outer Space"; }
    if biome == BIOME_TUTORIAL { return "Tutorial Island"; }
    if biome == BIOME_YING_FOREST { return "Ying Forest"; }
    if biome == BIOME_WHITE_FLOWER { return "Alpha Cube"; }
    if biome == BIOME_YELLOW_FLOWER { return "Yellow Flower"; }
    if biome == BIOME_MYLANTIS { return "Mylantis Caves"; }
    if biome == BIOME_BLACK_CUBE { return "I2 Menger Lattice"; }
    return "Inner Core";
}

fn weapon_name(w: i32) -> const u8[:] {
    if w == WEP_PLASMA { return "1:Plasma"; }
    if w == WEP_CANNON { return "2:Cannon"; }
    if w == WEP_LASER { return "3:Laser"; }
    if w == WEP_ROCKET { return "4:Rocket"; }
    if w == WEP_HOMING { return "5:Homing"; }
    if w == WEP_MINIGUN { return "6:Minigun"; }
    if w == WEP_RAILGUN { return "7:Railgun"; }
    if w == WEP_EMP { return "8:EMP"; }
    if w == WEP_NUKE { return "9:Nuke"; }
    if st.quasar_drive != 0 { return "0:Quasar"; }
    return "0:DarkHole";
}

fn block_label(b: u8) -> const u8[:] {
    if is_block_shrinkable(b) != 0 {
        return "Fractal World Block (Shrink [B] & fly into 3D hole)";
    }
    if b == BLK_UPG_WEP { return "Weapon Arsenal Module"; }
    if b == BLK_BUY_STATION { return "Buy Station [F]"; }
    if b == BLK_SELL_STATION { return "Sell Station [F]"; }
    if b == BLK_BLACK_MARKET { return "Black Market [F]"; }
    if b == BLK_TOME { return "Xar Manual Tome [F]"; }
    if b == BLK_LOCKED_DOOR { return "Locked Vault Door [F: Key]"; }
    if st.shrink_any != 0 { return "Solid Block (ShrinkAny ON: Fly/Press B)"; }
    return "";
}

fn block_base_rgb(b: u8) -> u32 {
    if b == BLK_WALL_TUT { return pack_rgb(168, 176, 198); }
    if b == BLK_GRASS { return pack_rgb(44, 172, 82); }
    if b == BLK_DIRT { return pack_rgb(112, 78, 52); }
    if b == BLK_WOOD { return pack_rgb(128, 78, 42); }
    if b == BLK_LEAVES { return pack_rgb(26, 134, 68); }
    if b == BLK_PETAL_Y { return pack_rgb(245, 198, 38); }
    if b == BLK_POLLEN { return pack_rgb(255, 244, 128); }
    if b == BLK_PETAL_W { return pack_rgb(236, 242, 250); }
    if b == BLK_MYLANTIS { return pack_rgb(24, 172, 168); }
    if b == BLK_ICE { return pack_rgb(122, 212, 250); }
    if b == BLK_SAND { return pack_rgb(218, 182, 108); }
    if b == BLK_GLASS { return pack_rgb(148, 224, 248); }
    if b == BLK_STONE { return pack_rgb(86, 94, 114); }
    if b == BLK_GOLD_ORE { return pack_rgb(245, 196, 42); }
    if b == BLK_CRATE { return pack_rgb(202, 138, 46); }
    if b == BLK_SPAWNER { return pack_rgb(196, 40, 68); }
    if b == BLK_LOCKED_DOOR { return pack_rgb(210, 165, 38); }
    if b == BLK_BLACK_CUBE { return pack_rgb(18, 18, 28); }
    if b == BLK_WHITE_FLOWER { return pack_rgb(248, 250, 255); }
    if b == BLK_ALPHA_CUBE { return pack_rgb(236, 72, 153); }
    if b == BLK_FLOWER_Y_CORE { return pack_rgb(255, 214, 48); }
    if b == BLK_MYLANTIS_M { return pack_rgb(249, 115, 22); }
    if b == BLK_YING_PLANET { return pack_rgb(52, 211, 102); }
    if b == BLK_ICE_WORLD { return pack_rgb(96, 218, 255); }
    if b == BLK_DESERT_WORLD { return pack_rgb(234, 179, 82); }
    if b == BLK_CORE_GATE { return pack_rgb(244, 63, 184); }
    if b == BLK_BUY_STATION { return pack_rgb(34, 197, 94); }
    if b == BLK_SELL_STATION { return pack_rgb(56, 189, 248); }
    if b == BLK_BLACK_MARKET { return pack_rgb(147, 51, 234); }
    if b == BLK_TOME { return pack_rgb(250, 204, 21); }
    if b == BLK_UPG_HP { return pack_rgb(244, 63, 94); }
    if b == BLK_UPG_REGEN { return pack_rgb(251, 113, 133); }
    if b == BLK_UPG_ARMOR { return pack_rgb(59, 130, 246); }
    if b == BLK_UPG_DMG { return pack_rgb(249, 115, 22); }
    if b == BLK_UPG_ROF { return pack_rgb(234, 179, 8); }
    if b == BLK_UPG_AMMO { return pack_rgb(168, 85, 247); }
    if b == BLK_UPG_SPEED { return pack_rgb(34, 211, 238); }
    if b == BLK_KEY_BLOCK { return pack_rgb(253, 224, 71); }
    if b == BLK_UPG_WEP { return pack_rgb(34, 230, 148); }
    return pack_rgb(128, 128, 128);
}

// ---------------------------------------------------------------------------
// Entities, Shots & Particles
// ---------------------------------------------------------------------------
fn clear_entities_and_shots() {
    var i: i32 = 0;
    while i < MAX_ENTITIES {
        st.entities[i].active = 0;
        st.entities[i].kind = ENT_NONE;
        st.entities[i].freeze_ms = 0;
        i = i + 1;
    }
    i = 0;
    while i < MAX_SHOTS {
        st.shots[i].active = 0;
        i = i + 1;
    }
    i = 0;
    while i < MAX_PARTICLES {
        st.particles[i].active = 0;
        i = i + 1;
    }
}

fn spawn_entity(kind: i32, x: f64, y: f64, z: f64, hp: i32, target_biome: i32, target_blk: u8) -> i32 {
    var i: i32 = 0;
    while i < MAX_ENTITIES {
        if st.entities[i].active == 0 {
            st.entities[i].active = 1;
            st.entities[i].kind = kind;
            st.entities[i].x = x;
            st.entities[i].y = y;
            st.entities[i].z = z;
            st.entities[i].vx = 0.0;
            st.entities[i].vy = 0.0;
            st.entities[i].vz = 0.0;
            st.entities[i].hp = hp;
            st.entities[i].max_hp = hp;
            st.entities[i].cooldown = rng_range(400, 1400);
            st.entities[i].freeze_ms = 0;
            st.entities[i].target_biome = target_biome;
            st.entities[i].target_block = target_blk;
            return i;
        }
        i = i + 1;
    }
    return -1;
}

fn spawn_shot(from_player: i32, wep: i32, secondary: i32, x: f64, y: f64, z: f64, vx: f64, vy: f64, vz: f64, dmg: i32, ttl_ms: i32, rgb: u32) {
    var i: i32 = 0;
    while i < MAX_SHOTS {
        if st.shots[i].active == 0 {
            st.shots[i].active = 1;
            st.shots[i].from_player = from_player;
            st.shots[i].wep = wep;
            st.shots[i].secondary = secondary;
            st.shots[i].x = x;
            st.shots[i].y = y;
            st.shots[i].z = z;
            st.shots[i].vx = vx;
            st.shots[i].vy = vy;
            st.shots[i].vz = vz;
            st.shots[i].dmg = dmg;
            st.shots[i].ttl_ms = ttl_ms;
            st.shots[i].rgb = rgb;
            return;
        }
        i = i + 1;
    }
}

fn spawn_burst(x: f64, y: f64, z: f64, rgb: u32, count: i32) {
    var spawned: i32 = 0;
    var i: i32 = 0;
    while i < MAX_PARTICLES && spawned < count {
        if st.particles[i].active == 0 {
            st.particles[i].active = 1;
            st.particles[i].x = x;
            st.particles[i].y = y;
            st.particles[i].z = z;
            st.particles[i].vx = (rng_f01() - 0.5) * 8.0;
            st.particles[i].vy = (rng_f01() - 0.3) * 8.0;
            st.particles[i].vz = (rng_f01() - 0.5) * 8.0;
            st.particles[i].ttl_ms = rng_range(180, 520);
            st.particles[i].rgb = rgb;
            spawned = spawned + 1;
        }
        i = i + 1;
    }
}

fn add_gold(amount: i32) {
    st.gold = clamp_i(st.gold + amount, 0, MAX_GOLD);
}

// ---------------------------------------------------------------------------
// Authentic Xar Procedural World Generators (16x16x16 Spatial Chunks)
// ---------------------------------------------------------------------------
fn pick_biome_for_entry(depth: i32, parent_blk: u8, forced_biome: i32, seed: u64, fallback_biome: i32) -> i32 {
    if forced_biome >= 0 { return forced_biome; }
    // Shrinking in open air or inside generic solid world blocks preserves the parent world's biome!
    if parent_blk == BLK_AIR {
        if fallback_biome >= 0 { return fallback_biome; }
        if depth < 0 { return BIOME_SPACE; }
        return BIOME_YING_FOREST;
    }
    if depth < 0 { return BIOME_SPACE; }
    if depth == 0 { return BIOME_TUTORIAL; }
    if is_block_shrinkable(parent_blk) == 0 {
        if fallback_biome >= 0 { return fallback_biome; }
        return BIOME_YING_FOREST;
    }
    if parent_blk == BLK_CORE_GATE { return BIOME_INNER_CORE; }
    if parent_blk == BLK_WHITE_FLOWER { return BIOME_WHITE_FLOWER; }
    if parent_blk == BLK_ALPHA_CUBE || parent_blk == BLK_FLOWER_Y_CORE || parent_blk == BLK_DESERT_WORLD {
        return BIOME_YELLOW_FLOWER;
    }
    if parent_blk == BLK_YING_PLANET {
        return BIOME_YING_FOREST;
    }
    if parent_blk == BLK_MYLANTIS_M || parent_blk == BLK_ICE_WORLD {
        return BIOME_MYLANTIS;
    }
    if parent_blk == BLK_BLACK_CUBE {
        if depth == 1 { return BIOME_YING_FOREST; }
        return BIOME_BLACK_CUBE;
    }
    if depth == 1 { return BIOME_YING_FOREST; }
    let r = (splitmix64(seed) % 4) as! i32;
    if r == 0 { return BIOME_YING_FOREST; }
    if r == 1 { return BIOME_YELLOW_FLOWER; }
    if r == 2 { return BIOME_MYLANTIS; }
    return BIOME_BLACK_CUBE;
}

fn build_ying_tree_to(dst: i32, tx: i32, tz: i32, base_y: i32, h: i32, has_fruit: i32) {
    var y: i32 = 0;
    while y < h {
        dst_set_block(dst, tx, base_y + y, tz, BLK_WOOD);
        y = y + 1;
    }
    let cy = base_y + h;
    var dy: i32 = -1;
    while dy <= 2 {
        var dz: i32 = -2;
        while dz <= 2 {
            var dx: i32 = -2;
            while dx <= 2 {
                let man = (if dx < 0 { -dx } else { dx }) + (if dz < 0 { -dz } else { dz });
                if (dy == 2 && man > 1) || (man == 2 && (dy == -1 || dy == 1)) {
                    dx = dx + 1;
                    continue;
                }
                if has_fruit != 0 && dx == 0 && dz == 0 && dy == 0 {
                    dst_set_block(dst, tx, cy, tz, BLK_FLOWER_Y_CORE);
                } else {
                    dst_set_block(dst, tx + dx, cy + dy, tz + dz, BLK_LEAVES);
                }
                dx = dx + 1;
            }
            dz = dz + 1;
        }
        dy = dy + 1;
    }
}

fn generate_space_blocks(dst: i32) {
    // Outer Space: Floating Ying World (base y=5..6 + top crown at (8,7,8) holding Tutorial!)
    var dz: i32 = -1;
    while dz <= 1 {
        var dy: i32 = -1;
        while dy <= 0 {
            var dx: i32 = -1;
            while dx <= 1 {
                dst_set_block(dst, 8 + dx, 6 + dy, 8 + dz, BLK_YING_PLANET);
                dx = dx + 1;
            }
            dy = dy + 1;
        }
        dz = dz + 1;
    }
    dst_set_block(dst, 8, 7, 8, BLK_YING_PLANET);

    // Iconic Orange Mylantis 'M' Block floating in Space!
    dst_set_block(dst, 13, 8, 12, BLK_MYLANTIS_M);
    dst_set_block(dst, 13, 9, 12, BLK_MYLANTIS_M);
    dst_set_block(dst, 14, 8, 12, BLK_MYLANTIS_M);
    dst_set_block(dst, 14, 9, 12, BLK_MYLANTIS_M);

    // Ice World & Desert World Planets
    dst_set_block(dst, 3, 9, 12, BLK_ICE_WORLD);
    dst_set_block(dst, 3, 9, 13, BLK_ICE_WORLD);
    dst_set_block(dst, 3, 4, 4, BLK_DESERT_WORLD);
    dst_set_block(dst, 4, 4, 4, BLK_DESERT_WORLD);

    // Giant Cosmic Black Cube
    dst_set_block(dst, 12, 4, 4, BLK_BLACK_CUBE);
    dst_set_block(dst, 12, 5, 4, BLK_BLACK_CUBE);
}

fn populate_space_entities(depth: i32) {
    let _ = spawn_entity(ENT_RING_BLUE, 13.5, 10.2, 12.5, 1, BIOME_MYLANTIS, BLK_MYLANTIS_M);
    // In-place Green Shrink Ring floating in open Space above Ying Planet!
    let _ = spawn_entity(ENT_RING_GREEN, 8.5, 9.2, 8.5, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_RED, 8.5, 13.8, 8.5, 1, BIOME_SPACE, BLK_AIR);
    let _ = spawn_entity(ENT_GOLD, 8.5, 8.5, 11.5, 1, -1, 0);

    // Outer Space Level -1 right outside Tutorial is peaceful; deep cosmic void (-3+) has space raiders
    if depth <= -3 && st.genesis_mode == 0 {
        let _ = spawn_entity(ENT_MENACE, 5.5, 8.0, 6.5, 65, -1, 0);
        let _ = spawn_entity(ENT_PIRATE, 11.5, 7.5, 8.0, 55, -1, 0);
    }
}

fn generate_tutorial_blocks(dst: i32) {
    // Peaceful Tutorial Island (2-block thick ground, open sky & open sides so Outer Space is visible & reachable!)
    var z: i32 = 1;
    while z <= 14 {
        var x: i32 = 1;
        while x <= 14 {
            dst_set_block(dst, x, 0, z, BLK_DIRT);
            dst_set_block(dst, x, 1, z, BLK_GRASS);
            x = x + 1;
        }
        z = z + 1;
    }

    // Tutorial Hall around (x=4..12, y=2..7, z=2..12) with 2-voxel thick walls, doorway, windows & skylight
    var ry: i32 = 2;
    while ry <= 7 {
        var rz: i32 = 2;
        while rz <= 12 {
            var rx: i32 = 4;
            while rx <= 12 {
                let wall = if rx <= 5 || rx >= 11 || rz <= 3 || rz >= 11 || ry >= 6 { 1 } else { 0 };
                if wall != 0 {
                    let is_door = if rx >= 11 && rz >= 6 && rz <= 8 && ry >= 2 && ry <= 4 { 1 } else { 0 };
                    let is_win =
                        if (rx <= 5 && rz >= 6 && rz <= 8 && ry >= 3 && ry <= 4) ||
                           (rz <= 3 && rx >= 7 && rx <= 9 && ry >= 3 && ry <= 4) ||
                           (rz >= 11 && rx >= 7 && rx <= 9 && ry >= 3 && ry <= 5) { 1 } else { 0 };
                    let is_sky = if ry >= 6 && rx >= 7 && rx <= 9 && rz >= 5 && rz <= 9 { 1 } else { 0 };
                    if is_door == 0 && is_win == 0 && is_sky == 0 {
                        dst_set_block(dst, rx, ry, rz, BLK_WALL_TUT);
                    }
                }
                rx = rx + 1;
            }
            rz = rz + 1;
        }
        ry = ry + 1;
    }

    // Embedded 2-level micro-hole alcoves visible inside Tutorial Hall's 2-voxel wall thickness
    dst_set_block(dst, 5, 3, 4, BLK_AIR);
    dst_set_block(dst, 4, 3, 4, BLK_ALPHA_CUBE);
    dst_set_block(dst, 11, 3, 10, BLK_AIR);
    dst_set_block(dst, 12, 3, 10, BLK_BLACK_CUBE);
    dst_set_block(dst, 12, 4, 10, BLK_GOLD_ORE);

    // Iconic Tutorial Black Cube straight ahead at (8, 2..3, 9) -> Ying Forest
    dst_set_block(dst, 8, 2, 9, BLK_BLACK_CUBE);
    dst_set_block(dst, 8, 3, 9, BLK_BLACK_CUBE);
    dst_set_block(dst, 6, 2, 7, BLK_TOME);        // Xar Tutorial Tome
    dst_set_block(dst, 10, 2, 7, BLK_BUY_STATION); // Tutorial Buy Station
    dst_set_block(dst, 6, 2, 9, BLK_CRATE);        // Destructible crate with starting Gold

    // Outside Tutorial Hall: Small White Flower (Alpha Cube), HP Upgrade, Sell Station
    dst_set_block(dst, 13, 2, 8, BLK_WOOD);
    dst_set_block(dst, 13, 3, 8, BLK_PETAL_W);
    dst_set_block(dst, 12, 3, 8, BLK_PETAL_W);
    dst_set_block(dst, 14, 3, 8, BLK_PETAL_W);
    dst_set_block(dst, 13, 4, 8, BLK_WHITE_FLOWER);

    dst_set_block(dst, 3, 2, 12, BLK_UPG_HP);
    dst_set_block(dst, 13, 2, 3, BLK_SELL_STATION);
}

fn populate_tutorial_entities() {
    // In-place Green Shrink Ring right inside Tutorial Hall! Shrinking keeps you inside the Tutorial Hall at 1/16th scale!
    let _ = spawn_entity(ENT_RING_GREEN, 9.5, 3.2, 6.2, 1, -1, BLK_AIR);
    // Second in-place Green Shrink Ring above the White Flower garden
    let _ = spawn_entity(ENT_RING_GREEN, 13.5, 5.2, 8.5, 1, -1, BLK_AIR);
    // Floating Red Grow Ring above skylight -> Outer Space LVL -1
    let _ = spawn_entity(ENT_RING_RED, 8.5, 11.5, 7.5, 1, BIOME_SPACE, BLK_AIR);
    let _ = spawn_entity(ENT_GOLD, 8.5, 2.5, 6.5, 1, -1, 0);
}

fn generate_ying_forest_blocks(dst: i32) {
    // 2-voxel thick floor (Dirt + Grass) + 2-voxel thick Black Cube perimeter with 4x8 cardinal 3D archways!
    var y: i32 = 0;
    while y <= 11 {
        var z: i32 = 0;
        while z < CHUNK_DIM {
            var x: i32 = 0;
            while x < CHUNK_DIM {
                if y == 0 {
                    dst_set_block(dst, x, y, z, BLK_DIRT);
                } else if y == 1 {
                    dst_set_block(dst, x, y, z, BLK_GRASS);
                } else {
                    let is_wall = if x <= 1 || x >= 14 || z <= 1 || z >= 14 { 1 } else { 0 };
                    let is_roof = if y == 11 && (x <= 2 || x >= 13 || z <= 2 || z >= 13) { 1 } else { 0 };
                    if is_wall != 0 || is_roof != 0 {
                        let arch_z = if (z <= 1 || z >= 14) && x >= 6 && x <= 9 && y >= 2 && y <= 9 { 1 } else { 0 };
                        let arch_x = if (x <= 1 || x >= 14) && z >= 6 && z <= 9 && y >= 2 && y <= 9 { 1 } else { 0 };
                        if arch_z == 0 && arch_x == 0 {
                            let trim = if (x == 1 || x == 14 || z == 1 || z == 14) && (y == 2 || y == 10) { 1 } else { 0 };
                            dst_set_block(dst, x, y, z, if trim != 0 { BLK_STONE } else { BLK_BLACK_CUBE });
                        }
                    }
                }
                x = x + 1;
            }
            z = z + 1;
        }
        y = y + 1;
    }

    // Hidden 2-level micro-holes embedded inside Ying Forest's 2-block thick outer walls
    dst_set_block(dst, 1, 5, 3, BLK_ALPHA_CUBE);
    dst_set_block(dst, 14, 5, 12, BLK_GOLD_ORE);

    // Ying Trees with fractal Yellow Flower buds
    build_ying_tree_to(dst, 4, 11, 2, 4, 1);
    build_ying_tree_to(dst, 11, 11, 2, 4, 0);
    build_ying_tree_to(dst, 11, 4, 2, 5, 1);

    // Totem Pole + Health Regen House
    dst_set_block(dst, 3, 2, 4, BLK_WOOD);
    dst_set_block(dst, 3, 3, 4, BLK_STONE);
    dst_set_block(dst, 3, 4, 4, BLK_WOOD);
    dst_set_block(dst, 3, 5, 4, BLK_UPG_REGEN);

    // Jumbo Yellow Flower -> Yellow Flower Labyrinth
    dst_set_block(dst, 8, 2, 11, BLK_WOOD);
    dst_set_block(dst, 8, 3, 11, BLK_WOOD);
    var fz: i32 = 9;
    while fz <= 13 {
        var fx: i32 = 6;
        while fx <= 10 {
            let dx = fx - 8;
            let dz = fz - 11;
            let r2 = dx * dx + dz * dz;
            if r2 <= 4 {
                if r2 <= 1 { dst_set_block(dst, fx, 4, fz, BLK_POLLEN); }
                else { dst_set_block(dst, fx, 5, fz, BLK_PETAL_Y); }
            }
            fx = fx + 1;
        }
        fz = fz + 1;
    }
    dst_set_block(dst, 8, 5, 11, BLK_FLOWER_Y_CORE);

    // Small White Flower -> Alpha Cube
    dst_set_block(dst, 5, 2, 4, BLK_WHITE_FLOWER);

    // Black Cube Monolith -> I1/I2 Lattice
    dst_set_block(dst, 13, 2, 9, BLK_BLACK_CUBE);
    dst_set_block(dst, 13, 3, 9, BLK_BLACK_CUBE);

    // Buy Station, Crates, Damage Upgrade & Early Weapon Module (2:Cannon + 3:Laser)
    dst_set_block(dst, 10, 2, 6, BLK_BUY_STATION);
    dst_set_block(dst, 6, 2, 8, BLK_CRATE);
    dst_set_block(dst, 11, 2, 8, BLK_UPG_DMG);
    dst_set_block(dst, 7, 2, 5, BLK_UPG_WEP);
}

fn populate_ying_forest_entities(depth: i32, seed: u64) {
    // In-place Green & Pink Shrink Rings inside Ying Forest!
    let _ = spawn_entity(ENT_RING_GREEN, 7.5, 3.2, 7.5, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_PINK, 11.5, 3.2, 5.5, 1, -1, BLK_AIR);
    // Blue Ring shortcut to Mylantis & Red Grow Ring
    let _ = spawn_entity(ENT_RING_BLUE, 3.5, 3.2, 8.5, 1, BIOME_MYLANTIS, BLK_MYLANTIS_M);
    let _ = spawn_entity(ENT_RING_RED, 8.5, 12.5, 8.5, 1, -1, BLK_AIR);

    // Early Ying Forest (depth <= 2) is peaceful exploration; deep Ying Forests (depth >= 3) have YinYangs/Goblins!
    if depth >= 3 && st.genesis_mode == 0 {
        let hp_scale = 35 + depth * 12;
        let _ = spawn_entity(ENT_YINYANG, 6.5, 3.2, 10.5, hp_scale + 10, -1, 0);
        let _ = spawn_entity(ENT_GOBLIN, 10.5, 2.6, 10.5, hp_scale, -1, 0);
        if (seed & 1) == 0 {
            let _ = spawn_entity(ENT_SPIDER, 4.5, 2.5, 7.5, hp_scale - 6, -1, 0);
        }
    }
    let _ = spawn_entity(ENT_GOLD, 8.5, 2.6, 7.5, 1, -1, 0);
    let _ = spawn_entity(ENT_AMMO, 5.5, 2.6, 8.5, 1, -1, 0);
}

fn generate_white_flower_alpha_blocks(dst: i32, seed: u64) {
    // Open-top White Flower petal calyx with 2-block thick walls & floor, 4x8 cardinal 3D archways
    var ls = seed;
    var y: i32 = 0;
    while y <= 11 {
        var z: i32 = 0;
        while z < CHUNK_DIM {
            var x: i32 = 0;
            while x < CHUNK_DIM {
                let is_floor = if y <= 1 { 1 } else { 0 };
                let is_wall = if x <= 1 || x >= 14 || z <= 1 || z >= 14 { 1 } else { 0 };
                if is_floor != 0 {
                    if (x >= 6 && x <= 9 && z >= 6 && z <= 9) || ((x + z) % 3) == 0 {
                        dst_set_block(dst, x, y, z, BLK_PETAL_W);
                    } else {
                        dst_set_block(dst, x, y, z, BLK_GLASS);
                    }
                } else if is_wall != 0 {
                    let arch_z = if (z <= 1 || z >= 14) && x >= 6 && x <= 9 && y >= 2 && y <= 9 { 1 } else { 0 };
                    let arch_x = if (x <= 1 || x >= 14) && z >= 6 && z <= 9 && y >= 2 && y <= 9 { 1 } else { 0 };
                    if arch_z == 0 && arch_x == 0 {
                        if ((x + y + z) % 3) == 0 { dst_set_block(dst, x, y, z, BLK_PETAL_W); }
                        else { dst_set_block(dst, x, y, z, BLK_GLASS); }
                    }
                }
                x = x + 1;
            }
            z = z + 1;
        }
        y = y + 1;
    }

    // Hidden 2-level micro-holes in calyx wall jambs
    dst_set_block(dst, 1, 5, 4, BLK_ALPHA_CUBE);
    dst_set_block(dst, 14, 5, 11, BLK_BLACK_CUBE);

    // Central Alpha Cube pedestal + Weapon Module (6:Minigun) + random fractal pillars
    dst_set_block(dst, 8, 2, 8, BLK_ALPHA_CUBE);
    dst_set_block(dst, 8, 3, 8, BLK_ALPHA_CUBE);
    dst_set_block(dst, 5, 2, 8, BLK_UPG_HP);
    dst_set_block(dst, 11, 2, 8, BLK_UPG_ARMOR);
    dst_set_block(dst, 5, 2, 11, BLK_UPG_WEP);
    dst_set_block(dst, 8, 2, 11, BLK_SELL_STATION);
    dst_set_block(dst, 8, 2, 4, BLK_TOME);

    var p: i32 = 0;
    while p < 4 {
        ls = splitmix64(ls);
        let px = 3 + ((ls % 10) as! i32);
        ls = splitmix64(ls);
        let pz = 3 + ((ls % 10) as! i32);
        if px != 8 || pz != 8 {
            dst_set_block(dst, px, 2, pz, BLK_ALPHA_CUBE);
            dst_set_block(dst, px, 3, pz, BLK_GOLD_ORE);
        }
        p = p + 1;
    }
}

fn populate_white_flower_alpha_entities(depth: i32) {
    let _ = spawn_entity(ENT_RING_GREEN, 6.5, 3.5, 6.5, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_PINK, 11.5, 3.5, 5.5, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_RED, 8.0, 12.2, 8.0, 1, -1, BLK_AIR);

    if depth >= 3 && st.genesis_mode == 0 {
        let hp_scale = 22 + depth * 10;
        let _ = spawn_entity(ENT_RAT, 4.5, 3.0, 5.5, hp_scale, -1, 0);
        let _ = spawn_entity(ENT_GOBLIN, 11.5, 3.0, 11.5, hp_scale + 12, -1, 0);
    }
    let _ = spawn_entity(ENT_GOLD, 6.5, 3.0, 9.5, 1, -1, 0);
    let _ = spawn_entity(ENT_HEALTH, 9.5, 3.0, 6.5, 1, -1, 0);
}

fn generate_black_cube_blocks(dst: i32, seed: u64) {
    // Authentic 3D Menger Sponge Lattice (I1 / I2 / I3) — 5-voxel thick outer frame + open cross-shafts on ALL 6 faces!
    var y: i32 = 0;
    while y < CHUNK_DIM {
        var z: i32 = 0;
        while z < CHUNK_DIM {
            var x: i32 = 0;
            while x < CHUNK_DIM {
                let mx = if x >= 5 && x <= 10 { 1 } else { 0 };
                let my = if y >= 5 && y <= 10 { 1 } else { 0 };
                let mz = if z >= 5 && z <= 10 { 1 } else { 0 };
                let mid1 = mx + my + mz;

                let sx = if (x % 5) == 2 { 1 } else { 0 };
                let sy = if (y % 5) == 2 { 1 } else { 0 };
                let sz = if (z % 5) == 2 { 1 } else { 0 };
                let mid2 = sx + sy + sz;

                if mid1 < 2 && mid2 < 2 {
                    let is_frame = if x == 0 || x == 15 || y == 0 || y == 15 || z == 0 || z == 15 { 1 } else { 0 };
                    if is_frame != 0 && ((x + y + z) % 7 == 0) {
                        dst_set_block(dst, x, y, z, BLK_GLASS);
                    } else {
                        dst_set_block(dst, x, y, z, BLK_BLACK_CUBE);
                    }
                }
                x = x + 1;
            }
            z = z + 1;
        }
        y = y + 1;
    }

    // Embedded 2-level micro-holes in Menger corner blocks
    dst_set_block(dst, 1, 4, 14, BLK_ALPHA_CUBE);
    dst_set_block(dst, 14, 4, 1, BLK_GOLD_ORE);

    // Clear a walkable central landing platform & Menger chamber stations
    var cz: i32 = 5;
    while cz <= 10 {
        var cx: i32 = 5;
        while cx <= 10 {
            dst_set_block(dst, cx, 0, cz, BLK_BLACK_CUBE);
            cx = cx + 1;
        }
        cz = cz + 1;
    }
    let _ = seed;
    dst_set_block(dst, 5, 1, 8, BLK_BUY_STATION);
    dst_set_block(dst, 10, 1, 8, BLK_SELL_STATION);
    dst_set_block(dst, 5, 1, 10, BLK_BLACK_MARKET);
    dst_set_block(dst, 8, 1, 5, BLK_UPG_DMG);
    dst_set_block(dst, 8, 1, 10, BLK_TOME);
    dst_set_block(dst, 6, 1, 6, BLK_UPG_WEP);
    dst_set_block(dst, 4, 2, 8, BLK_CORE_GATE);
    dst_set_block(dst, 11, 2, 8, BLK_CORE_GATE);
    dst_set_block(dst, 9, 1, 6, BLK_CRATE);
}

fn generate_interior_biome_blocks(dst: i32, biome: i32, depth: i32, seed: u64) {
    if biome == BIOME_BLACK_CUBE {
        generate_black_cube_blocks(dst, seed);
        return;
    }

    var ls = seed;
    let wall_blk: u8 =
        if biome == BIOME_YELLOW_FLOWER { BLK_PETAL_Y }
        else if biome == BIOME_MYLANTIS { BLK_MYLANTIS }
        else { BLK_CORE_GATE };
    let trim_blk: u8 =
        if biome == BIOME_YELLOW_FLOWER { BLK_POLLEN }
        else if biome == BIOME_MYLANTIS { BLK_ICE }
        else { BLK_GOLD_ORE };

    // Open-sky terraced chamber with 2-block thick walls & floor and wide 3D cardinal archways!
    var y: i32 = 0;
    while y <= 11 {
        var z: i32 = 0;
        while z < CHUNK_DIM {
            var x: i32 = 0;
            while x < CHUNK_DIM {
                let is_floor = if y <= 1 { 1 } else { 0 };
                let is_rim = if x <= 1 || x >= 14 || z <= 1 || z >= 14 { 1 } else { 0 };
                if is_floor != 0 {
                    if ((x + z) % 5) == 0 { dst_set_block(dst, x, y, z, trim_blk); }
                    else { dst_set_block(dst, x, y, z, wall_blk); }
                } else if is_rim != 0 {
                    let arch_x = if (z <= 1 || z >= 14) && x >= 5 && x <= 10 && y >= 2 && y <= 8 { 1 } else { 0 };
                    let arch_z = if (x <= 1 || x >= 14) && z >= 5 && z <= 10 && y >= 2 && y <= 8 { 1 } else { 0 };
                    if arch_x == 0 && arch_z == 0 {
                        if ((x + y + z) % 5) == 0 { dst_set_block(dst, x, y, z, trim_blk); }
                        else { dst_set_block(dst, x, y, z, wall_blk); }
                    }
                }
                x = x + 1;
            }
            z = z + 1;
        }
        y = y + 1;
    }

    // Hidden 2-level micro-holes embedded inside outer wall jambs
    dst_set_block(dst, 1, 5, 3, BLK_ALPHA_CUBE);
    dst_set_block(dst, 14, 5, 12, BLK_BLACK_CUBE);

    // Floating fractal bridges / petal platforms
    var p: i32 = 0;
    while p < 4 {
        ls = splitmix64(ls);
        let px = 3 + ((ls % 9) as! i32);
        ls = splitmix64(ls);
        let pz = 3 + ((ls % 9) as! i32);
        ls = splitmix64(ls);
        let py = 4 + ((ls % 6) as! i32);
        var dz: i32 = -1;
        while dz <= 1 {
            var dx: i32 = -1;
            while dx <= 1 {
                if dx != 0 || dz != 0 {
                    let tx = px + dx;
                    let tz = pz + dz;
                    if (tx >= 2 && tx <= 13 && tz >= 2 && tz <= 13) && (tx < 7 || tx > 9 || tz < 6 || tz > 9) {
                        dst_set_block(dst, tx, py, tz, wall_blk);
                    }
                }
                dx = dx + 1;
            }
            dz = dz + 1;
        }
        p = p + 1;
    }

    dst_set_block(dst, 5, 2, 8, BLK_BUY_STATION);
    dst_set_block(dst, 11, 2, 8, BLK_SELL_STATION);
    dst_set_block(dst, 4, 2, 4, BLK_CRATE);
    dst_set_block(dst, 11, 2, 4, BLK_GOLD_ORE);
    if depth >= 3 { dst_set_block(dst, 11, 2, 11, BLK_SPAWNER); }
    if biome == BIOME_MYLANTIS {
        dst_set_block(dst, 4, 2, 12, BLK_BLACK_MARKET);
        dst_set_block(dst, 12, 2, 12, BLK_LOCKED_DOOR);
        dst_set_block(dst, 12, 2, 13, BLK_UPG_AMMO);
    }

    if biome == BIOME_YELLOW_FLOWER {
        dst_set_block(dst, 8, 2, 4, BLK_UPG_HP);
        dst_set_block(dst, 8, 2, 12, BLK_KEY_BLOCK);
        dst_set_block(dst, 5, 2, 12, BLK_UPG_WEP);
        dst_set_block(dst, 4, 2, 8, BLK_MYLANTIS_M);
    } else if biome == BIOME_MYLANTIS {
        dst_set_block(dst, 8, 2, 4, BLK_UPG_ROF);
        dst_set_block(dst, 8, 2, 12, BLK_UPG_SPEED);
        dst_set_block(dst, 4, 2, 10, BLK_UPG_WEP);
        dst_set_block(dst, 4, 2, 8, BLK_BLACK_CUBE);
    } else {
        dst_set_block(dst, 8, 2, 4, BLK_UPG_ARMOR);
        dst_set_block(dst, 8, 2, 12, BLK_UPG_HP);
        dst_set_block(dst, 4, 2, 8, BLK_BLACK_CUBE);
    }
}

fn populate_interior_biome_entities(biome: i32, depth: i32) {
    // In-place Green (16x) and Pink (256x) Shrink Rings + Red Grow Ring!
    let _ = spawn_entity(ENT_RING_RED, 8.0, 12.2, 8.0, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_GREEN, 6.2, 3.5, 8.0, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_PINK, 10.2, 3.5, 6.2, 1, -1, BLK_AIR);

    if st.genesis_mode == 0 {
        let d_cap = clamp_i(depth, 1, 40);
        let scale_hp = 30 + d_cap * 18;
        if biome == BIOME_YELLOW_FLOWER {
            let _ = spawn_entity(ENT_GOBLIN, 4.5, 3.0, 11.5, scale_hp, -1, 0);
            let _ = spawn_entity(ENT_RAT, 11.5, 3.0, 4.5, scale_hp - 8, -1, 0);
            if depth >= 3 {
                let _ = spawn_entity(ENT_PIRATE, 8.0, 7.5, 12.0, scale_hp + 15, -1, 0);
            }
        } else if biome == BIOME_MYLANTIS {
            let _ = spawn_entity(ENT_SPIDER, 4.5, 3.0, 11.5, scale_hp, -1, 0);
            let _ = spawn_entity(ENT_MARINE, 5.5, 5.5, 5.5, scale_hp + 15, -1, 0);
            let _ = spawn_entity(ENT_DEMON, 11.5, 3.5, 11.5, scale_hp + 30, -1, 0);
        } else if biome == BIOME_BLACK_CUBE {
            let _ = spawn_entity(ENT_GUARDIAN, 6.5, 5.0, 9.5, scale_hp + 85, -1, 0);
            let _ = spawn_entity(ENT_DEMON, 9.5, 3.5, 6.5, scale_hp + 45, -1, 0);
            let _ = spawn_entity(ENT_MENACE, 12.0, 8.5, 12.0, scale_hp + 30, -1, 0);
        } else {
            let _ = spawn_entity(ENT_SINGULARITY, 8.0, 6.8, 11.8, 320 + d_cap * 35, -1, 0);
            let _ = spawn_entity(ENT_GUARDIAN, 4.2, 3.2, 11.5, scale_hp + 70, -1, 0);
        }
    }

    if biome == BIOME_INNER_CORE && st.k_rescued == 0 {
        let _ = spawn_entity(ENT_FRIEND_K, 8.0, 3.0, 13.6, 1, -1, 0);
    }

    let _ = spawn_entity(ENT_GOLD, 6.5, 3.0, 5.5, 1, -1, 0);
    let _ = spawn_entity(ENT_AMMO, 4.0, 3.0, 8.0, 1, -1, 0);
    let _ = spawn_entity(ENT_HEALTH, 8.0, 3.0, 3.5, 1, -1, 0);
}

fn generate_generic_hollow_block(dst: i32, blk: u8, depth: i32, seed: u64) {
    // Every solid world block subdivides into a 16x16x16 hollow structure with 2-3 sub-block
    // thick walls ("girth"), recessed 3D tunnels on cardinal faces, inner beams/pillars,
    // and embedded 2-level micro-holes in the thick wall jambs!
    let _ = depth;
    let thick: i32 = 2 + ((seed & 1) as! i32); // 2 or 3 voxels thick
    let trim_blk: u8 =
        if blk == BLK_WALL_TUT || blk == BLK_STONE { BLK_STONE }
        else if blk == BLK_GRASS || blk == BLK_DIRT { BLK_WOOD }
        else if blk == BLK_WOOD || blk == BLK_LEAVES { BLK_GRASS }
        else if blk == BLK_PETAL_Y || blk == BLK_POLLEN { BLK_POLLEN }
        else if blk == BLK_PETAL_W { BLK_ICE }
        else if blk == BLK_MYLANTIS || blk == BLK_ICE { BLK_MYLANTIS }
        else { BLK_SAND };

    let has_floor_pit: i32 = if (seed & 4) != 0 { 1 } else { 0 };
    var y: i32 = 0;
    while y < CHUNK_DIM {
        var z: i32 = 0;
        while z < CHUNK_DIM {
            var x: i32 = 0;
            while x < CHUNK_DIM {
                let in_x_wall = if x < thick || x >= CHUNK_DIM - thick { 1 } else { 0 };
                let in_z_wall = if z < thick || z >= CHUNK_DIM - thick { 1 } else { 0 };
                let in_y_bot = if y < thick { 1 } else { 0 };
                let in_y_top = if y >= CHUNK_DIM - thick { 1 } else { 0 };

                if in_x_wall != 0 || in_z_wall != 0 || in_y_bot != 0 || in_y_top != 0 {
                    // Cardinal 4x4 3D tunnels piercing completely through the 2-3 thick walls
                    let tunnel_z = if x >= 6 && x <= 9 && y >= 6 && y <= 9 && in_x_wall == 0 && in_y_bot == 0 && in_y_top == 0 { 1 } else { 0 };
                    let tunnel_x = if z >= 6 && z <= 9 && y >= 6 && y <= 9 && in_z_wall == 0 && in_y_bot == 0 && in_y_top == 0 { 1 } else { 0 };
                    let sky_hole = if in_y_top != 0 && x >= 6 && x <= 9 && z >= 6 && z <= 9 { 1 } else { 0 };
                    let pit_hole = if has_floor_pit != 0 && in_y_bot != 0 && x >= 7 && x <= 8 && z >= 7 && z <= 8 { 1 } else { 0 };

                    // Recessed 2x2 micro-hole alcoves on outer skin exposing 2-level secret pockets inside wall thickness
                    let alcove_front = if z == 0 && x >= 2 && x <= 3 && y >= 2 && y <= 3 { 1 } else { 0 };
                    let alcove_side = if x == 15 && z >= 12 && z <= 13 && y >= 12 && y <= 13 { 1 } else { 0 };

                    if tunnel_z == 0 && tunnel_x == 0 && sky_hole == 0 && pit_hole == 0 && alcove_front == 0 && alcove_side == 0 {
                        let inner_skin = if x == thick - 1 || x == CHUNK_DIM - thick || z == thick - 1 || z == CHUNK_DIM - thick || y == thick - 1 { 1 } else { 0 };
                        dst_set_block(dst, x, y, z, if inner_skin != 0 && ((x + y + z) & 1) == 0 { trim_blk } else { blk });
                    }
                }
                x = x + 1;
            }
            z = z + 1;
        }
        y = y + 1;
    }

    // Internal structural ribs & lower pedestal so looking through any 3D hole shows multi-layer depth!
    var b: i32 = thick;
    while b <= 15 - thick {
        dst_set_block(dst, b, 5, 5, trim_blk);
        dst_set_block(dst, b, 5, 10, trim_blk);
        b = b + 1;
    }
    dst_set_block(dst, 5, 4, 5, trim_blk);
    dst_set_block(dst, 10, 4, 5, trim_blk);
    dst_set_block(dst, 5, 4, 10, trim_blk);
    dst_set_block(dst, 10, 4, 10, trim_blk);
    dst_set_block(dst, 8, thick, 8, BLK_GOLD_ORE);

    // 2-level hidden micro-hole targets seated inside the thick wall alcoves
    dst_set_block(dst, 2, 2, 1, BLK_ALPHA_CUBE);
    dst_set_block(dst, 14, 12, 12, BLK_BLACK_CUBE);
}

fn populate_generic_hollow_entities(depth: i32) {
    let _ = spawn_entity(ENT_RING_GREEN, 8.0, 8.0, 4.8, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_RED, 8.0, 12.2, 8.0, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_GOLD, 8.0, 8.0, 11.2, 1, -1, 0);
    if depth >= 3 && st.genesis_mode == 0 {
        let _ = spawn_entity(ENT_RAT, 5.5, 4.5, 10.5, 24 + depth * 6, -1, 0);
    }
}

fn generate_air_subchunk_blocks(dst: i32, biome: i32, seed: u64, air_depth: i32) {
    // Open-air subdivision: ZERO enclosing walls!
    // air_depth == 1: sparse XAR_YING_FOREST_AIR mote + stone so giant rooms remain clear.
    // air_depth >= 2: progressive microscopic air atoms, molecules & lattice obstacles.
    var ls = splitmix64(seed);
    let ox: i32 = if (ls & 1) != 0 { 11 } else { 2 };
    ls = splitmix64(ls);
    let oy: i32 = if (ls & 1) != 0 { 10 } else { 2 };
    ls = splitmix64(ls);
    let oz: i32 = if (ls & 1) != 0 { 11 } else { 2 };

    let mote_blk: u8 =
        if biome == BIOME_TUTORIAL || biome == BIOME_YING_FOREST { BLK_GOLD_ORE }
        else if biome == BIOME_WHITE_FLOWER { BLK_ALPHA_CUBE }
        else if biome == BIOME_YELLOW_FLOWER { BLK_POLLEN }
        else if biome == BIOME_MYLANTIS { BLK_ICE }
        else { BLK_BLACK_CUBE };

    dst_set_block(dst, ox, oy, oz, BLK_STONE);
    dst_set_block(dst, ox + 1, oy, oz, mote_blk);

    if air_depth <= 1 {
        return;
    }

    if air_depth == 2 {
        // Scattered microscopic air atoms (diatom/single cubes, navigable gaps)
        var a: i32 = 0;
        while a < 8 {
            ls = splitmix64(ls);
            let ax = 2 + ((ls % 12) as! i32);
            ls = splitmix64(ls);
            let ay = 2 + ((ls % 12) as! i32);
            ls = splitmix64(ls);
            let az = 2 + ((ls % 12) as! i32);
            if (ax < 7 || ax > 8) || (ay < 7 || ay > 8) || (az < 7 || az > 8) {
                let ablk: u8 =
                    if (a % 4) == 0 { BLK_ICE }
                    else if (a % 4) == 1 { BLK_GLASS }
                    else if (a % 4) == 2 { BLK_STONE }
                    else { BLK_ALPHA_CUBE };
                dst_set_block(dst, ax, ay, az, ablk);
                if ax + 1 < 14 {
                    dst_set_block(dst, ax + 1, ay, az, BLK_GLASS);
                }
            }
            a = a + 1;
        }
        return;
    }

    if air_depth == 3 {
        // Dense molecular tri-atom dumbbells & micro-rings
        var c: i32 = 0;
        while c < 13 {
            ls = splitmix64(ls);
            let cx = 2 + ((ls % 11) as! i32);
            ls = splitmix64(ls);
            let cy = 2 + ((ls % 11) as! i32);
            ls = splitmix64(ls);
            let cz = 2 + ((ls % 11) as! i32);
            let nucleus: u8 =
                if (c % 5) == 0 { BLK_BLACK_CUBE }
                else if (c % 3) == 0 { BLK_MYLANTIS }
                else { BLK_STONE };
            if (cx < 7 || cx > 8) || (cy < 7 || cy > 8) {
                dst_set_block(dst, cx, cy, cz, nucleus);
                dst_set_block(dst, cx + 1, cy, cz, BLK_GLASS);
                dst_set_block(dst, cx, cy + 1, cz, BLK_ICE);
                dst_set_block(dst, cx, cy, cz + 1, BLK_GLASS);
            }
            c = c + 1;
        }
        return;
    }

    // air_depth >= 4: Dense sub-atomic air crystal lattice (requires steering or shrinking into atoms!)
    let density_pct = clamp_i(34 + (air_depth - 4) * 8, 34, 58);
    var z: i32 = 1;
    while z <= 14 {
        var y: i32 = 1;
        while y <= 14 {
            var x: i32 = 1;
            while x <= 14 {
                let on_bar =
                    if ((x % 4) == 2 && (y % 4) == 2) ||
                       ((y % 4) == 2 && (z % 4) == 2) ||
                       ((x % 4) == 2 && (z % 4) == 2) { 1 } else { 0 };
                if on_bar != 0 {
                    let center_safe = if x >= 7 && x <= 8 && y >= 7 && y <= 8 && z >= 7 && z <= 8 { 1 } else { 0 };
                    if center_safe == 0 {
                        let hv = splitmix64(seed ^ ((x * 73856093 + y * 19349663 + z * 83492791) as u64));
                        if ((hv % 100) as! i32) < density_pct {
                            let mod_b = (hv >> 8) % 9;
                            let lblk: u8 =
                                if mod_b == 0 { BLK_BLACK_CUBE }
                                else if mod_b == 1 || mod_b == 2 { BLK_MYLANTIS }
                                else if mod_b == 3 || mod_b == 4 { BLK_ICE }
                                else if mod_b == 5 || mod_b == 6 { BLK_GLASS }
                                else { BLK_STONE };
                            dst_set_block(dst, x, y, z, lblk);
                        }
                    }
                }
                x = x + 1;
            }
            y = y + 1;
        }
        z = z + 1;
    }
}

fn find_clear_air_pos(x_in: f64, y_in: f64, z_in: f64, ox: f64&, oy: f64&, oz: f64&) {
    var cx: i32 = clamp_i(ffloor(x_in), 1, 14);
    var cy: i32 = clamp_i(ffloor(y_in), 1, 14);
    var cz: i32 = clamp_i(ffloor(z_in), 1, 14);
    var r: i32 = 0;
    while r < 4 {
        if get_block(cx, cy + r, cz) == BLK_AIR {
            ox = cx + 0.5; oy = cy + r + 0.5; oz = cz + 0.5;
            return;
        }
        if get_block(cx + r, cy, cz) == BLK_AIR {
            ox = cx + r + 0.5; oy = cy + 0.5; oz = cz + 0.5;
            return;
        }
        r = r + 1;
    }
    ox = 8.0; oy = 8.0; oz = 8.0;
}

fn populate_air_subchunk_entities(depth: i32, seed: u64) {
    var ls = splitmix64(seed ^ 0x52494e47);
    let gx = 4.5 + ((ls % 7) as f64);
    ls = splitmix64(ls);
    let gz = 4.5 + ((ls % 7) as f64);
    var rx: f64 = 0.0;
    var ry: f64 = 0.0;
    var rz: f64 = 0.0;
    // In-place Green Shrink Ring (dive another 16x inside this same space) + Pink + Red Grow Ring!
    find_clear_air_pos(gx, 8.0, gz, rx, ry, rz);
    let _ = spawn_entity(ENT_RING_GREEN, rx, ry, rz, 1, -1, BLK_AIR);
    find_clear_air_pos(3.2, 6.0, 12.2, rx, ry, rz);
    let _ = spawn_entity(ENT_RING_PINK, rx, ry, rz, 1, -1, BLK_AIR);
    find_clear_air_pos(12.5, 11.5, 3.5, rx, ry, rz);
    let _ = spawn_entity(ENT_RING_RED, rx, ry, rz, 1, -1, BLK_AIR);
    find_clear_air_pos(8.0, 5.5, 8.0, rx, ry, rz);
    let _ = spawn_entity(ENT_GOLD, rx, ry, rz, 1, -1, 0);
    if depth >= 4 && st.genesis_mode == 0 && (seed % 3) == 0 {
        find_clear_air_pos(4.5, 4.5, 4.5, rx, ry, rz);
        let _ = spawn_entity(ENT_RAT, rx, ry, rz, 18 + depth * 4, -1, 0);
    }
}

fn generate_chunk_blocks_to(dst_layer: i32, depth: i32, biome: i32, parent_blk: u8, seed: u64, air_depth: i32) {
    var i: i32 = 0;
    while i < CHUNK_VOL {
        if dst_layer < 0 { st.blocks[i] = BLK_AIR; }
        else if dst_layer == 3 { st.scratch_blocks[i] = BLK_AIR; }
        else if dst_layer >= 10 { st.inward_blocks[(dst_layer - 10) * CHUNK_VOL + i] = BLK_AIR; }
        else { st.parent_blocks[dst_layer * CHUNK_VOL + i] = BLK_AIR; }
        i = i + 1;
    }

    if parent_blk == BLK_AIR {
        generate_air_subchunk_blocks(dst_layer, biome, seed, air_depth);
    } else if depth < 0 || biome == BIOME_SPACE {
        generate_space_blocks(dst_layer);
    } else if depth == 0 && biome == BIOME_TUTORIAL {
        generate_tutorial_blocks(dst_layer);
    } else if is_block_shrinkable(parent_blk) == 0 {
        generate_generic_hollow_block(dst_layer, parent_blk, depth, seed);
    } else if biome == BIOME_TUTORIAL {
        generate_tutorial_blocks(dst_layer);
    } else if biome == BIOME_YING_FOREST {
        generate_ying_forest_blocks(dst_layer);
    } else if biome == BIOME_WHITE_FLOWER {
        generate_white_flower_alpha_blocks(dst_layer, seed);
    } else {
        generate_interior_biome_blocks(dst_layer, biome, depth, seed);
    }

    // Reapply persistent block deltas (broken crates, opened doors, collected upgrades)
    i = 0;
    while i < MAX_DELTAS {
        if st.deltas[i].used != 0 && st.deltas[i].seed == seed {
            dst_set_block(dst_layer, st.deltas[i].bx, st.deltas[i].by, st.deltas[i].bz, st.deltas[i].blk);
        }
        i = i + 1;
    }
}

fn get_subchunk_biome(
    parent_seed: u64, parent_depth: i32, parent_biome: i32,
    mx: i32, my: i32, mz: i32, blk: u8
) -> i32 {
    if parent_depth == -1 && mx == 8 && my == 7 && mz == 8 && blk == BLK_YING_PLANET {
        return BIOME_TUTORIAL;
    }
    let child_d = parent_depth + 1;
    let cseed = hash_block_seed(parent_seed, mx, my, mz, child_d);
    return pick_biome_for_entry(child_d, blk, -1, cseed, parent_biome);
}

fn resolve_subchunk_slot(
    parent_seed: u64, parent_depth: i32, parent_biome: i32,
    mx: i32, my: i32, mz: i32, blk: u8
) -> i32 {
    let is_tut_crown = if parent_depth == -1 && mx == 8 && my == 7 && mz == 8 && blk == BLK_YING_PLANET { 1 } else { 0 };
    let child_d = parent_depth + 1;
    let cseed =
        if is_tut_crown != 0 { 0x5841525f54555430 }
        else { hash_block_seed(parent_seed, mx, my, mz, child_d) };
    let kh = cseed ^ ((blk as u64) * 0x9e3779b97f4a7c15) ^ (((child_d & 0xffff) as u64) * 0xbf58476d1ce4e5b9);
    let h0 = ((kh ^ (kh >> 8)) & 255) as! i32;
    if st.inward_used[h0] != 0 && st.inward_seeds[h0] == cseed && st.inward_blks[h0] == blk && st.inward_depths[h0] == child_d {
        return h0;
    }
    let h1 = (h0 + 131) & 255;
    if st.inward_used[h1] != 0 && st.inward_seeds[h1] == cseed && st.inward_blks[h1] == blk && st.inward_depths[h1] == child_d {
        return h1;
    }
    var slot: i32 = h0;
    if st.inward_used[h0] != 0 {
        if st.inward_used[h1] == 0 {
            slot = h1;
        } else {
            slot = if (st.inward_next & 1) == 0 { h0 } else { h1 };
            st.inward_next = st.inward_next + 1;
        }
    }
    st.inward_used[slot] = 1;
    st.inward_seeds[slot] = cseed;
    st.inward_blks[slot] = blk;
    st.inward_depths[slot] = child_d;
    let cbio =
        if is_tut_crown != 0 { BIOME_TUTORIAL }
        else { pick_biome_for_entry(child_d, blk, -1, cseed, parent_biome) };
    generate_chunk_blocks_to(10 + slot, child_d, cbio, blk, cseed, 0);
    return slot;
}

fn get_subchunk_block(
    parent_seed: u64, parent_depth: i32, parent_biome: i32,
    mx: i32, my: i32, mz: i32, blk: u8,
    cx: i32, cy: i32, cz: i32
) -> u8 {
    if cx < 0 || cx >= CHUNK_DIM || cy < 0 || cy >= CHUNK_DIM || cz < 0 || cz >= CHUNK_DIM {
        return BLK_AIR;
    }
    let slot = resolve_subchunk_slot(parent_seed, parent_depth, parent_biome, mx, my, mz, blk);
    return st.inward_blocks[slot * CHUNK_VOL + b_idx(cx, cy, cz)];
}

fn get_inward_preview_block(mx: i32, my: i32, mz: i32, blk: u8, cx: i32, cy: i32, cz: i32) -> u8 {
    return get_subchunk_block(cur_seed(), st.depth, cur_biome(), mx, my, mz, blk, cx, cy, cz);
}

fn load_current_chunk() {
    clear_entities_and_shots();
    invalidate_inward_cache();

    let cf = get_frame(st.depth);
    let biome = cf.biome;
    let seed = cf.seed;
    let air_d = compute_air_depth(st.depth);

    generate_chunk_blocks_to(-1, st.depth, biome, cf.parent_block, seed, air_d);

    if cf.parent_block == BLK_AIR {
        populate_air_subchunk_entities(st.depth, seed);
    } else if st.depth < 0 || biome == BIOME_SPACE {
        populate_space_entities(st.depth);
    } else if st.depth == 0 && biome == BIOME_TUTORIAL {
        populate_tutorial_entities();
    } else if is_block_shrinkable(cf.parent_block) == 0 {
        populate_generic_hollow_entities(st.depth);
    } else if biome == BIOME_TUTORIAL {
        populate_tutorial_entities();
    } else if biome == BIOME_YING_FOREST {
        populate_ying_forest_entities(st.depth, seed);
    } else if biome == BIOME_WHITE_FLOWER {
        populate_white_flower_alpha_entities(st.depth);
    } else {
        populate_interior_biome_entities(biome, st.depth);
    }

    // Populate 3 outward parent visibility layers (16x, 256x, 4096x) for hierarchical DDA raycasting
    var pl: i32 = 0;
    while pl < 3 {
        let pd = st.depth - 1 - pl;
        if pd < MAX_NEG_DEPTH {
            st.parent_valid[pl] = 0;
        } else {
            ensure_neg_frame_seed(pd);
            let child_f = get_frame(pd + 1);
            let pf = get_frame(pd);
            st.parent_valid[pl] = 1;
            st.parent_bx[pl] = child_f.bx;
            st.parent_by[pl] = child_f.by;
            st.parent_bz[pl] = child_f.bz;
            st.parent_biome[pl] = pf.biome;
            st.parent_depth[pl] = pd;
            st.parent_seed[pl] = pf.seed;
            generate_chunk_blocks_to(pl, pd, pf.biome, pf.parent_block, pf.seed, compute_air_depth(pd));
        }
        pl = pl + 1;
    }
}

// ---------------------------------------------------------------------------
// True Spatial 16x In-Place Shrink & 6-Face Continuous Grow
// ---------------------------------------------------------------------------
fn shrink_into_ex(bx: i32, by: i32, bz: i32, target_blk: u8, forced_biome: i32, steps: i32, ref_px: f64, ref_py: f64, ref_pz: f64) {
    if st.ring_cd_ms > 0 { return; }
    var d: i32 = 0;
    var cur_bx: i32 = clamp_i(bx, 0, 15);
    var cur_by: i32 = clamp_i(by, 0, 15);
    var cur_bz: i32 = clamp_i(bz, 0, 15);
    var cur_blk: u8 = target_blk;
    var cur_forced: i32 = forced_biome;

    // Precompute continuous sub-voxel landing coordinates inside the child 16x16x16 chunk
    var new_px: f64 = 8.0;
    var new_py: f64 = 3.2;
    var new_pz: f64 = 6.5;

    if cur_blk == BLK_AIR {
        let rx = fclamp(ref_px - cur_bx, 0.08, 0.92);
        let ry = fclamp(ref_py - cur_by, 0.08, 0.92);
        let rz = fclamp(ref_pz - cur_bz, 0.08, 0.92);
        new_px = rx * 16.0;
        new_py = ry * 16.0;
        new_pz = rz * 16.0;
    } else {
        // Face-preserving block entry: enter just inside whichever face the player approached
        let ox = ref_px - (cur_bx + 0.5);
        let oy = ref_py - (cur_by + 0.5);
        let oz = ref_pz - (cur_bz + 0.5);
        let ax = fabs(ox);
        let ay = fabs(oy);
        let az = fabs(oz);
        new_px = fclamp((ref_px - cur_bx) * 16.0, 2.0, 14.0);
        new_py = fclamp((ref_py - cur_by) * 16.0, 2.0, 14.0);
        new_pz = fclamp((ref_pz - cur_bz) * 16.0, 2.0, 14.0);
        if ax >= ay && ax >= az {
            new_px = if ox < 0.0 { 1.6 } else { 14.4 };
        } else if ay >= ax && ay >= az {
            new_py = if oy < 0.0 { 1.6 } else { 14.4 };
        } else {
            new_pz = if oz < 0.0 { 1.6 } else { 14.4 };
        }
    }

    while d < steps {
        let next_depth = st.depth + 1;
        if next_depth > MAX_POS_DEPTH {
            set_status_msg("Max Xar fractal scale depth (3000) reached!", 1600);
            break;
        }
        let pf = get_frame(st.depth);
        let pseed = pf.seed;
        let nseed = hash_block_seed(pseed, cur_bx, cur_by, cur_bz, next_depth);
        st.depth = next_depth;
        if st.depth > st.max_depth_reached { st.max_depth_reached = st.depth; }
        let nbio = pick_biome_for_entry(next_depth, cur_blk, cur_forced, nseed, pf.biome);
        set_frame(next_depth, ScaleFrame {
            bx: cur_bx, by: cur_by, bz: cur_bz,
            biome: nbio, parent_block: cur_blk, seed: nseed
        });
        if d + 1 < steps {
            if cur_blk == BLK_AIR {
                cur_bx = clamp_i(ffloor(new_px), 0, 15);
                cur_by = clamp_i(ffloor(new_py), 0, 15);
                cur_bz = clamp_i(ffloor(new_pz), 0, 15);
                new_px = fclamp((new_px - cur_bx) * 16.0, 1.2, 14.8);
                new_py = fclamp((new_py - cur_by) * 16.0, 1.2, 14.8);
                new_pz = fclamp((new_pz - cur_bz) * 16.0, 1.2, 14.8);
            } else {
                cur_bx = 8; cur_by = 8; cur_bz = 8;
                cur_blk = BLK_BLACK_CUBE;
            }
            cur_forced = -1;
        }
        d = d + 1;
    }

    load_current_chunk();

    // Ensure collision-free arrival while staying as close as possible to the continuous entry point
    if point_collides(new_px, new_py, new_pz) != 0 {
        var step_in: i32 = 0;
        while point_collides(new_px, new_py, new_pz) != 0 && step_in < 10 {
            new_px = new_px + (8.0 - new_px) * 0.25;
            new_py = new_py + (6.0 - new_py) * 0.25;
            new_pz = new_pz + (8.0 - new_pz) * 0.25;
            step_in = step_in + 1;
        }
        if point_collides(new_px, new_py, new_pz) != 0 {
            new_px = 8.0; new_py = 3.2; new_pz = 6.5;
            if point_collides(new_px, new_py, new_pz) != 0 {
                new_px = 8.0; new_py = 8.0; new_pz = 8.0;
            }
        }
    }

    st.px = new_px;
    st.py = new_py;
    st.pz = new_pz;
    if target_blk == BLK_AIR {
        st.vx = st.vx * 0.45; st.vy = st.vy * 0.45; st.vz = st.vz * 0.45;
    } else {
        st.vx = 0.0; st.vy = 0.0; st.vz = 0.0;
    }
    st.ring_cd_ms = 260;
    st.flash_ms = 200;
    st.flash_rgb = pack_rgb(40, 235, 130);
    if target_blk == BLK_AIR {
        set_status_msg(if steps >= 2 { "Shrank 256x in-place (same world)!" } else { "Shrank 16x in-place (same world)!" }, 1600);
    } else {
        set_status_msg("Shrank 16x into fractal block!", 1600);
    }
}

fn shrink_into(bx: i32, by: i32, bz: i32, target_blk: u8, forced_biome: i32, steps: i32) {
    shrink_into_ex(bx, by, bz, target_blk, forced_biome, steps, st.px, st.py, st.pz);
}

fn grow_out_axis(exit_x: f64, exit_y: f64, exit_z: f64) {
    if st.ring_cd_ms > 0 { return; }
    let next_depth = st.depth - 1;
    if next_depth < MAX_NEG_DEPTH {
        st.px = fclamp(exit_x, 0.5, 15.5);
        st.py = fclamp(exit_y, 0.5, 15.5);
        st.pz = fclamp(exit_z, 0.5, 15.5);
        set_status_msg("Outer Cosmic Boundary of Xar reached!", 1500);
        return;
    }

    let cur_f = get_frame(st.depth);
    let ret_bx = cur_f.bx;
    let ret_by = cur_f.by;
    let ret_bz = cur_f.bz;
    let was_air = if cur_f.parent_block == BLK_AIR { 1 } else { 0 };

    ensure_neg_frame_seed(next_depth);
    st.depth = next_depth;
    if st.depth < st.min_depth_reached { st.min_depth_reached = st.depth; }
    load_current_chunk();

    var nx: f64 = ret_bx + fclamp(exit_x / 16.0, -0.02, 1.02);
    var ny: f64 = ret_by + fclamp(exit_y / 16.0, -0.02, 1.02);
    var nz: f64 = ret_bz + fclamp(exit_z / 16.0, -0.02, 1.02);

    if was_air == 0 {
        if exit_x < 0.0 { nx = ret_bx - 0.30; }
        else if exit_x >= 16.0 { nx = ret_bx + 1.30; }
        if exit_y < 0.0 { ny = ret_by - 0.30; }
        else if exit_y >= 16.0 { ny = ret_by + 1.30; }
        if exit_z < 0.0 { nz = ret_bz - 0.30; }
        else if exit_z >= 16.0 { nz = ret_bz + 1.30; }
    }

    st.px = fclamp(nx, 0.15, 15.85);
    st.py = fclamp(ny, 0.15, 15.85);
    st.pz = fclamp(nz, 0.15, 15.85);

    // Push cleanly outside multi-block structures (e.g. Ying Planet or Black Cube) if colliding
    let base_nx = st.px;
    let base_ny = st.py;
    let base_nz = st.pz;
    var push: i32 = 0;
    while point_collides(st.px, st.py, st.pz) != 0 && push < 6 {
        if exit_x < 0.0 { st.px = st.px - 1.0; }
        else if exit_x >= 16.0 { st.px = st.px + 1.0; }
        else if exit_y < 0.0 { st.py = st.py - 1.0; }
        else if exit_y >= 16.0 { st.py = st.py + 1.0; }
        else if exit_z < 0.0 { st.pz = st.pz - 1.0; }
        else if exit_z >= 16.0 { st.pz = st.pz + 1.0; }
        else { st.py = st.py + 1.0; }
        st.px = fclamp(st.px, 0.2, 15.8);
        st.py = fclamp(st.py, 0.2, 15.8);
        st.pz = fclamp(st.pz, 0.2, 15.8);
        push = push + 1;
    }
    if point_collides(st.px, st.py, st.pz) != 0 {
        let off_x = [ 0.0, 0.0, 0.0, -1.1, 1.1, 0.0 ];
        let off_y = [ 1.1, 0.0, 0.0, 0.0, 0.0, -1.1 ];
        let off_z = [ 0.0, -1.1, 1.1, 0.0, 0.0, 0.0 ];
        var od: i32 = 0;
        while od < 6 && point_collides(st.px, st.py, st.pz) != 0 {
            let tx = fclamp(base_nx + off_x[od], 0.25, 15.75);
            let ty = fclamp(base_ny + off_y[od], 0.25, 15.75);
            let tz = fclamp(base_nz + off_z[od], 0.25, 15.75);
            if point_collides(tx, ty, tz) == 0 {
                st.px = tx; st.py = ty; st.pz = tz;
                break;
            }
            od = od + 1;
        }
    }
    if point_collides(st.px, st.py, st.pz) != 0 {
        st.px = 8.5;
        st.py = 11.5;
        st.pz = 8.5;
    }

    if was_air != 0 {
        st.vx = st.vx * 0.35; st.vy = st.vy * 0.35; st.vz = st.vz * 0.35;
    } else {
        st.vx = 0.0; st.vy = 0.0; st.vz = 0.0;
    }
    st.ring_cd_ms = 260;
    st.flash_ms = 200;
    st.flash_rgb = pack_rgb(245, 70, 70);
    set_status_msg("Grew 16x outward in-place!", 1600);
}

fn grow_in_place() {
    st.ring_cd_ms = 0;
    grow_out_axis(fclamp(st.px, 0.2, 15.8), fclamp(st.py, 0.2, 15.8), fclamp(st.pz, 0.2, 15.8));
}

// ---------------------------------------------------------------------------
// Init, Respawn & Reset
// ---------------------------------------------------------------------------
fn set_default_ammo_caps() {
    let mul = 1.0 + 0.35 * ((st.ammo_cap_lvl - 1) as f64);
    st.max_ammo[WEP_PLASMA] = 9999;
    st.max_ammo[WEP_CANNON] = (80.0 * mul) as! i32;
    st.max_ammo[WEP_LASER] = (120.0 * mul) as! i32;
    st.max_ammo[WEP_ROCKET] = (40.0 * mul) as! i32;
    st.max_ammo[WEP_HOMING] = (32.0 * mul) as! i32;
    st.max_ammo[WEP_MINIGUN] = (400.0 * mul) as! i32;
    st.max_ammo[WEP_RAILGUN] = (30.0 * mul) as! i32;
    st.max_ammo[WEP_EMP] = (20.0 * mul) as! i32;
    st.max_ammo[WEP_NUKE] = (8.0 * mul) as! i32;
    st.max_ammo[WEP_DARKHOLE] = (6.0 * mul) as! i32;
}

fn unlock_all_weapons() {
    var wi: i32 = 0;
    while wi < NUM_WEAPONS {
        st.wep_unlocked[wi] = 1;
        wi = wi + 1;
    }
}

fn init_new_game() {
    var i: i32 = 0;
    let plen = st.pos_stack.len as! i32;
    while i < plen {
        st.pos_stack[i].seed = 0;
        st.pos_stack[i].biome = BIOME_BLACK_CUBE;
        i = i + 1;
    }
    i = 0;
    let nlen = st.neg_stack.len as! i32;
    while i < nlen {
        st.neg_stack[i].seed = 0;
        st.neg_stack[i].biome = BIOME_SPACE;
        i = i + 1;
    }
    st.marker_frames_len = 0;
    st.inward_next = 0;
    invalidate_inward_cache();
    st.mouse_dragging = 0;
    st.mouse_drag_moved = 0;

    i = 0;
    while i < MAX_DELTAS {
        st.deltas[i].used = 0;
        i = i + 1;
    }
    i = 0;
    while i < MAX_MARKERS {
        st.markers[i].used = 0;
        st.markers[i].pos_cnt = 0;
        st.markers[i].neg_cnt = 0;
        i = i + 1;
    }
    st.delta_head = 0;
    st.active_marker = -1;

    st.depth = 0;
    st.max_depth_reached = 0;
    st.min_depth_reached = 0;
    set_frame(0, ScaleFrame {
        bx: 8, by: 7, bz: 8,
        biome: BIOME_TUTORIAL, parent_block: BLK_YING_PLANET, seed: 0x5841525f54555430
    });

    // Spawn inside the Tutorial Hall facing the Black Cube (+Z) and in-place Green Ring
    st.px = 8.5;
    st.py = 3.2;
    st.pz = 5.2;
    st.vx = 0.0; st.vy = 0.0; st.vz = 0.0;
    st.yaw = HALF_PI;
    st.pitch = -0.04;
    st.roll = 0.0;
    st.yaw_vel = 0.0;
    st.pitch_vel = 0.0;
    st.turning_ms = 0;
    st.true_up = 1;
    st.rocket_mode = 0;

    st.hp = 100;
    st.max_hp = 100;
    st.hp_regen = 1;
    st.regen_accum_ms = 0;
    st.armor = 50;
    st.max_armor = 100;
    st.gold = 40;
    st.keys = 0;
    st.kills = 0;
    st.deaths = 0;
    st.quasar_drive = 0;
    st.k_rescued = 0;
    st.telekinesis_ms = 0;

    st.dmg_lvl = 1;
    st.rof_lvl = 1;
    st.spd_lvl = 1;
    st.ammo_cap_lvl = 1;
    set_default_ammo_caps();

    st.weapon = WEP_PLASMA;
    i = 0;
    while i < NUM_WEAPONS {
        st.wep_unlocked[i] = if i == WEP_PLASMA || st.genesis_mode != 0 { 1 } else { 0 };
        i = i + 1;
    }
    st.ammo[WEP_PLASMA] = 9999;
    st.ammo[WEP_CANNON] = 24;
    st.ammo[WEP_LASER] = 45;
    st.ammo[WEP_ROCKET] = 12;
    st.ammo[WEP_HOMING] = 10;
    st.ammo[WEP_MINIGUN] = 140;
    st.ammo[WEP_RAILGUN] = 12;
    st.ammo[WEP_EMP] = 8;
    st.ammo[WEP_NUKE] = 2;
    st.ammo[WEP_DARKHOLE] = 2;

    st.fire_cd_ms = 0;
    st.ring_cd_ms = 300;
    st.beam_timer_ms = 0;
    st.flash_ms = 0;
    st.near_ring_kind = ENT_NONE;
    st.near_prompt_len = 0;
    st.target_name_len = 0;
    st.tome_id = 0;

    load_current_chunk();
    if st.genesis_mode != 0 {
        set_status_msg("Genesis Mode: Press [B] to shrink 16x and fly through 3D wall holes!", 4200);
    } else {
        set_status_msg("Tutorial: Solid walls! Press [B] to shrink 16x, then fly into Black Cube hole!", 4200);
    }
}

fn respawn_at_tutorial_preserving_progress() {
    // Authentic FBW death rule: lose 30 gold, keep weapons/upgrades/markers/deltas, respawn at Tutorial!
    st.deaths = st.deaths + 1;
    st.gold = if st.gold >= DEATH_GOLD_PENALTY { st.gold - DEATH_GOLD_PENALTY } else { 0 };
    st.hp = st.max_hp;
    st.armor = clamp_i(st.armor, st.max_armor / 2, st.max_armor);
    st.depth = 0;
    set_frame(0, ScaleFrame {
        bx: 8, by: 7, bz: 8,
        biome: BIOME_TUTORIAL, parent_block: BLK_YING_PLANET, seed: 0x5841525f54555430
    });
    load_current_chunk();
    st.px = 8.5;
    st.py = 3.2;
    st.pz = 5.2;
    st.vx = 0.0; st.vy = 0.0; st.vz = 0.0;
    st.yaw = HALF_PI;
    st.pitch = -0.04;
    st.roll = 0.0;
    st.yaw_vel = 0.0;
    st.pitch_vel = 0.0;
    st.turning_ms = 0;
    st.ring_cd_ms = 400;
    st.flash_ms = 320;
    st.flash_rgb = pack_rgb(220, 40, 60);
    set_status_msg("Hull destroyed! Respawned at Tutorial (-30 Gold, upgrades preserved).", 3600);
}

// ---------------------------------------------------------------------------
// Physics, Upgrades, Stations, Markers & Combat
// ---------------------------------------------------------------------------
fn point_collides(x: f64, y: f64, z: f64) -> i32 {
    let rad: f64 = 0.24;
    var dz: i32 = -1;
    while dz <= 1 {
        var dy: i32 = -1;
        while dy <= 1 {
            var dx: i32 = -1;
            while dx <= 1 {
                let bx = ffloor(x + dx * rad);
                let by = ffloor(y + dy * rad);
                let bz = ffloor(z + dz * rad);
                let blk = get_block(bx, by, bz);
                if is_block_solid(blk) != 0 {
                    return 1;
                }
                dx = dx + 1;
            }
            dy = dy + 1;
        }
        dz = dz + 1;
    }
    return 0;
}

fn collect_upgrade_block(bx: i32, by: i32, bz: i32, blk: u8) {
    set_block(bx, by, bz, BLK_AIR);
    record_block_delta(bx, by, bz, BLK_AIR);
    spawn_burst(bx + 0.5, by + 0.5, bz + 0.5, block_base_rgb(blk), 12);
    st.flash_ms = 180;
    st.flash_rgb = block_base_rgb(blk);

    if blk == BLK_UPG_HP {
        st.max_hp = st.max_hp + 20;
        st.hp = st.max_hp;
        set_status_msg("UPGRADE: +20 Max Health & Full Heal!", 2200);
    } else if blk == BLK_UPG_REGEN {
        st.hp_regen = st.hp_regen + 1;
        set_status_msg("UPGRADE: +1 Health Regen!", 2200);
    } else if blk == BLK_UPG_ARMOR {
        st.max_armor = st.max_armor + 25;
        st.armor = st.max_armor;
        set_status_msg("UPGRADE: +25 Max Armor & Refill!", 2200);
    } else if blk == BLK_UPG_DMG {
        st.dmg_lvl = st.dmg_lvl + 1;
        set_status_msg("UPGRADE: +20% Weapon Damage!", 2200);
    } else if blk == BLK_UPG_ROF {
        st.rof_lvl = st.rof_lvl + 1;
        set_status_msg("UPGRADE: +15% Fire Rate!", 2200);
    } else if blk == BLK_UPG_AMMO {
        st.ammo_cap_lvl = st.ammo_cap_lvl + 1;
        set_default_ammo_caps();
        set_status_msg("UPGRADE: +35% Max Ammo Capacity!", 2200);
    } else if blk == BLK_UPG_SPEED {
        st.spd_lvl = st.spd_lvl + 1;
        set_status_msg("UPGRADE: +12% Flight Thrust!", 2200);
    } else if blk == BLK_KEY_BLOCK {
        st.keys = st.keys + 1;
        set_status_msg("Picked up Vault Key!", 2000);
    } else if blk == BLK_UPG_WEP {
        let cb = cur_biome();
        if cb == BIOME_YING_FOREST {
            st.wep_unlocked[WEP_CANNON] = 1;
            st.wep_unlocked[WEP_LASER] = 1;
            set_status_msg("WEAPON MODULE: Unlocked 2:Cannon & 3:Laser!", 2400);
        } else if cb == BIOME_WHITE_FLOWER {
            st.wep_unlocked[WEP_MINIGUN] = 1;
            set_status_msg("WEAPON MODULE: Unlocked 6:Minigun!", 2400);
        } else if cb == BIOME_YELLOW_FLOWER {
            st.wep_unlocked[WEP_ROCKET] = 1;
            st.wep_unlocked[WEP_HOMING] = 1;
            set_status_msg("WEAPON MODULE: Unlocked 4:Rocket & 5:Homing!", 2400);
        } else if cb == BIOME_MYLANTIS {
            st.wep_unlocked[WEP_RAILGUN] = 1;
            st.wep_unlocked[WEP_EMP] = 1;
            set_status_msg("WEAPON MODULE: Unlocked 7:Railgun & 8:EMP!", 2400);
        } else {
            st.wep_unlocked[WEP_NUKE] = 1;
            st.wep_unlocked[WEP_DARKHOLE] = 1;
            set_status_msg("WEAPON MODULE: Unlocked 9:Nuke & 0:DarkHole!", 2400);
        }
    }
}

fn check_touch_special_block(tx: f64, ty: f64, tz: f64) -> i32 {
    let bx = ffloor(tx);
    let by = ffloor(ty);
    let bz = ffloor(tz);
    let blk = get_block(bx, by, bz);
    if is_block_upgrade(blk) != 0 {
        collect_upgrade_block(bx, by, bz, blk);
        return 1;
    }
    if st.shrink_any != 0 && is_block_solid(blk) != 0 && st.ring_cd_ms <= 0 {
        shrink_into_ex(bx, by, bz, blk, -1, 1, st.px, st.py, st.pz);
        return 2;
    }
    if is_block_subdivisible(blk) != 0 && st.msg_ms <= 0 {
        set_status_msg("Solid wall! Press [B] to shrink 16x and fly through its 3D holes.", 1400);
    }
    return 0;
}

fn apply_thrust(ax: f64, ay: f64, az: f64) {
    let mul = 1.0 + 0.12 * ((st.spd_lvl - 1) as f64);
    let boost = if st.rocket_mode != 0 { 1.35 } else { 1.0 };
    st.vx = st.vx + ax * mul * boost;
    st.vy = st.vy + ay * mul * boost;
    st.vz = st.vz + az * mul * boost;
}

fn apply_turn_impulse(dyaw: f64, dpitch: f64) {
    st.yaw_vel = fclamp(st.yaw_vel + dyaw, -2.8, 2.8);
    st.pitch_vel = fclamp(st.pitch_vel + dpitch, -2.0, 2.0);
    st.turning_ms = 140;
}

fn apply_brake() {
    st.vx = st.vx * 0.18;
    st.vy = st.vy * 0.18;
    st.vz = st.vz * 0.18;
    st.yaw_vel = st.yaw_vel * 0.15;
    st.pitch_vel = st.pitch_vel * 0.15;
}

fn scratch_point_collides(x: f64, y: f64, z: f64) -> i32 {
    let rad: f64 = 0.24;
    var dz: i32 = -1;
    while dz <= 1 {
        var dy: i32 = -1;
        while dy <= 1 {
            var dx: i32 = -1;
            while dx <= 1 {
                let bx = ffloor(x + dx * rad);
                let by = ffloor(y + dy * rad);
                let bz = ffloor(z + dz * rad);
                if bx >= 0 && bx < CHUNK_DIM && by >= 0 && by < CHUNK_DIM && bz >= 0 && bz < CHUNK_DIM {
                    let blk = st.scratch_blocks[b_idx(bx, by, bz)];
                    if is_block_solid(blk) != 0 {
                        return 1;
                    }
                }
                dx = dx + 1;
            }
            dy = dy + 1;
        }
        dz = dz + 1;
    }
    return 0;
}

fn step_air_single_axis(axis: i32, sdir: i32, cand_x: f64, cand_y: f64, cand_z: f64) -> i32 {
    let sdx: i32 = if axis == 0 { sdir } else { 0 };
    let sdy: i32 = if axis == 1 { sdir } else { 0 };
    let sdz: i32 = if axis == 2 { sdir } else { 0 };

    // Pass 1: Propagate carry/borrow upward across boundaries to locate in-bounds ancestor voxel
    var cur_d: i32 = st.depth;
    var cx: i32 = sdx;
    var cy: i32 = sdy;
    var cz: i32 = sdz;
    var anc_d: i32 = st.depth - 1;
    var target_bx: i32 = 0;
    var target_by: i32 = 0;
    var target_bz: i32 = 0;

    loop {
        let f = get_frame(cur_d);
        let nbx = f.bx + cx;
        let nby = f.by + cy;
        let nbz = f.bz + cz;
        if nbx >= 0 && nbx < CHUNK_DIM && nby >= 0 && nby < CHUNK_DIM && nbz >= 0 && nbz < CHUNK_DIM {
            anc_d = cur_d - 1;
            target_bx = nbx;
            target_by = nby;
            target_bz = nbz;
            break;
        }
        cx = if nbx < 0 { -1 } else if nbx >= CHUNK_DIM { 1 } else { 0 };
        cy = if nby < 0 { -1 } else if nby >= CHUNK_DIM { 1 } else { 0 };
        cz = if nbz < 0 { -1 } else if nbz >= CHUNK_DIM { 1 } else { 0 };
        cur_d = cur_d - 1;
        if cur_d <= MAX_NEG_DEPTH {
            set_status_msg("Outer Cosmic Boundary of Xar reached!", 1500);
            return 0;
        }
        ensure_neg_frame_seed(cur_d);
    }

    ensure_neg_frame_seed(anc_d);
    let anc_f = get_frame(anc_d);
    let anc_air_d = compute_air_depth(anc_d);
    generate_chunk_blocks_to(3, anc_d, anc_f.biome, anc_f.parent_block, anc_f.seed, anc_air_d);
    let tblk = dst_get_block(3, target_bx, target_by, target_bz);

    let nx_w = fclamp(if axis == 0 { cand_x - sdir * 16.0 } else { cand_x }, 0.04, 15.96);
    let ny_w = fclamp(if axis == 1 { cand_y - sdir * 16.0 } else { cand_y }, 0.04, 15.96);
    let nz_w = fclamp(if axis == 2 { cand_z - sdir * 16.0 } else { cand_z }, 0.04, 15.96);

    if tblk == BLK_AIR {
        var run_seed: u64 = hash_block_seed(anc_f.seed, target_bx, target_by, target_bz, cur_d);
        var run_bio: i32 = anc_f.biome;
        var run_air_d: i32 = anc_air_d + 1;
        var wd: i32 = cur_d + 1;
        while wd <= st.depth {
            let wf = get_frame(wd);
            let wbx = (wf.bx + sdx + CHUNK_DIM) & 15;
            let wby = (wf.by + sdy + CHUNK_DIM) & 15;
            let wbz = (wf.bz + sdz + CHUNK_DIM) & 15;
            run_seed = hash_block_seed(run_seed, wbx, wby, wbz, wd);
            run_air_d = run_air_d + 1;
            wd = wd + 1;
        }

        generate_chunk_blocks_to(3, st.depth, run_bio, BLK_AIR, run_seed, run_air_d);
        if scratch_point_collides(nx_w, ny_w, nz_w) != 0 {
            return 0;
        }

        // Atomic Commit Pass 2: keep st.depth unchanged!
        var cseed = hash_block_seed(anc_f.seed, target_bx, target_by, target_bz, cur_d);
        set_frame(cur_d, ScaleFrame {
            bx: target_bx, by: target_by, bz: target_bz,
            biome: anc_f.biome, parent_block: BLK_AIR, seed: cseed
        });
        wd = cur_d + 1;
        while wd <= st.depth {
            let wf = get_frame(wd);
            let wbx = (wf.bx + sdx + CHUNK_DIM) & 15;
            let wby = (wf.by + sdy + CHUNK_DIM) & 15;
            let wbz = (wf.bz + sdz + CHUNK_DIM) & 15;
            cseed = hash_block_seed(cseed, wbx, wby, wbz, wd);
            set_frame(wd, ScaleFrame {
                bx: wbx, by: wby, bz: wbz,
                biome: anc_f.biome, parent_block: BLK_AIR, seed: cseed
            });
            wd = wd + 1;
        }

        load_current_chunk();
        st.px = nx_w;
        st.py = ny_w;
        st.pz = nz_w;
        return 1;
    }

    // Neighbor macro voxel is SOLID: allow physical flight through its 3D tunnel holes!
    if is_block_subdivisible(tblk) != 0 || (st.shrink_any != 0 && st.ring_cd_ms <= 0) {
        let is_tut_crown = if anc_d == -1 && target_bx == 8 && target_by == 7 && target_bz == 8 && tblk == BLK_YING_PLANET { 1 } else { 0 };
        var top_seed: u64 =
            if is_tut_crown != 0 { 0x5841525f54555430 }
            else { hash_block_seed(anc_f.seed, target_bx, target_by, target_bz, cur_d) };
        var top_bio: i32 =
            if is_tut_crown != 0 { BIOME_TUTORIAL }
            else { pick_biome_for_entry(cur_d, tblk, -1, top_seed, anc_f.biome) };

        if cur_d == st.depth {
            generate_chunk_blocks_to(3, st.depth, top_bio, tblk, top_seed, 0);
            if scratch_point_collides(nx_w, ny_w, nz_w) == 0 {
                set_frame(cur_d, ScaleFrame {
                    bx: target_bx, by: target_by, bz: target_bz,
                    biome: top_bio, parent_block: tblk, seed: top_seed
                });
                load_current_chunk();
                st.px = nx_w;
                st.py = ny_w;
                st.pz = nz_w;
                st.flash_ms = 120;
                st.flash_rgb = pack_rgb(40, 235, 130);
                set_status_msg("Entered 3D fractal tunnel!", 1400);
                return 1;
            } else if st.shrink_any != 0 && st.ring_cd_ms <= 0 {
                set_frame(cur_d, ScaleFrame {
                    bx: target_bx, by: target_by, bz: target_bz,
                    biome: top_bio, parent_block: tblk, seed: top_seed
                });
                load_current_chunk();
                var sx: f64 = 8.0;
                var sy: f64 = 8.0;
                var sz: f64 = 8.0;
                find_clear_air_pos(nx_w, ny_w, nz_w, sx, sy, sz);
                st.px = sx;
                st.py = sy;
                st.pz = sz;
                st.ring_cd_ms = 180;
                set_status_msg("ShrinkAny passed through solid wall!", 1400);
                return 1;
            }
        } else {
            var rseed = top_seed;
            var rbio = top_bio;
            var rair: i32 = 0;
            var wd = cur_d + 1;
            while wd <= st.depth {
                let wf = get_frame(wd);
                let wbx = (wf.bx + sdx + CHUNK_DIM) & 15;
                let wby = (wf.by + sdy + CHUNK_DIM) & 15;
                let wbz = (wf.bz + sdz + CHUNK_DIM) & 15;
                generate_chunk_blocks_to(3, wd - 1, rbio, if wd == cur_d + 1 { tblk } else { BLK_AIR }, rseed, rair);
                if dst_get_block(3, wbx, wby, wbz) != BLK_AIR {
                    return 0;
                }
                rseed = hash_block_seed(rseed, wbx, wby, wbz, wd);
                rair = rair + 1;
                wd = wd + 1;
            }
            generate_chunk_blocks_to(3, st.depth, rbio, BLK_AIR, rseed, rair);
            if scratch_point_collides(nx_w, ny_w, nz_w) == 0 {
                var cseed = top_seed;
                set_frame(cur_d, ScaleFrame {
                    bx: target_bx, by: target_by, bz: target_bz,
                    biome: top_bio, parent_block: tblk, seed: cseed
                });
                wd = cur_d + 1;
                while wd <= st.depth {
                    let wf = get_frame(wd);
                    let wbx = (wf.bx + sdx + CHUNK_DIM) & 15;
                    let wby = (wf.by + sdy + CHUNK_DIM) & 15;
                    let wbz = (wf.bz + sdz + CHUNK_DIM) & 15;
                    cseed = hash_block_seed(cseed, wbx, wby, wbz, wd);
                    set_frame(wd, ScaleFrame {
                        bx: wbx, by: wby, bz: wbz,
                        biome: top_bio, parent_block: BLK_AIR, seed: cseed
                    });
                    wd = wd + 1;
                }
                load_current_chunk();
                st.px = nx_w;
                st.py = ny_w;
                st.pz = nz_w;
                return 1;
            }
        }
    }

    if st.msg_ms <= 0 {
        set_status_msg("Solid wall jamb — steer into the 3D hole or press [B] to shrink!", 1200);
    }
    return 0;
}

fn move_player_vec(dx: f64, dy: f64, dz: f64) {
    let can_cross_x = if cur_parent_block() == BLK_AIR || st.depth >= 1 { 1 } else { 0 };
    let nx = st.px + dx;
    if can_cross_x != 0 && (nx < 0.0 || nx >= 16.0) {
        let sdir: i32 = if nx < 0.0 { -1 } else { 1 };
        if step_air_single_axis(0, sdir, nx, st.py, st.pz) == 0 {
            st.px = fclamp(st.px, 0.25, 15.75);
            st.vx = 0.0;
        }
    } else if point_collides(nx, st.py, st.pz) == 0 {
        st.px = nx;
    } else {
        if check_touch_special_block(nx + (if dx > 0.0 { 0.25 } else { -0.25 }), st.py, st.pz) == 2 { return; }
        st.vx = 0.0;
    }

    let can_cross_y = if cur_parent_block() == BLK_AIR || st.depth >= 1 { 1 } else { 0 };
    let ny = st.py + dy;
    if can_cross_y != 0 && (ny < 0.0 || ny >= 16.0) {
        let sdir: i32 = if ny < 0.0 { -1 } else { 1 };
        if step_air_single_axis(1, sdir, st.px, ny, st.pz) == 0 {
            st.py = fclamp(st.py, 0.25, 15.75);
            st.vy = 0.0;
        }
    } else if point_collides(st.px, ny, st.pz) == 0 {
        st.py = ny;
    } else {
        if check_touch_special_block(st.px, ny + (if dy > 0.0 { 0.25 } else { -0.25 }), st.pz) == 2 { return; }
        st.vy = 0.0;
    }

    let can_cross_z = if cur_parent_block() == BLK_AIR || st.depth >= 1 { 1 } else { 0 };
    let nz = st.pz + dz;
    if can_cross_z != 0 && (nz < 0.0 || nz >= 16.0) {
        let sdir: i32 = if nz < 0.0 { -1 } else { 1 };
        if step_air_single_axis(2, sdir, st.px, st.py, nz) == 0 {
            st.pz = fclamp(st.pz, 0.25, 15.75);
            st.vz = 0.0;
        }
    } else if point_collides(st.px, st.py, nz) == 0 {
        st.pz = nz;
    } else {
        if check_touch_special_block(st.px, st.py, nz + (if dz > 0.0 { 0.25 } else { -0.25 })) == 2 { return; }
        st.vz = 0.0;
    }

    // At root depths (<= 0, Tutorial Island / Space), exiting past 0..16 grows 16x outward into Outer Space
    if st.depth <= 0 && cur_parent_block() != BLK_AIR {
        if st.px < 0.0 || st.px >= 16.0 || st.py < 0.0 || st.py >= 16.0 || st.pz < 0.0 || st.pz >= 16.0 {
            grow_out_axis(st.px, st.py, st.pz);
        }
    }
}

fn damage_player(dmg_in: i32) {
    if st.screen != SCREEN_PLAY { return; }
    var dmg: i32 = dmg_in;
    if st.armor > 0 {
        let absorbed = if st.armor >= (dmg * 2) / 3 { (dmg * 2) / 3 } else { st.armor };
        st.armor = st.armor - absorbed;
        dmg = dmg - absorbed;
    }
    st.hp = st.hp - dmg;
    st.flash_ms = 180;
    st.flash_rgb = pack_rgb(220, 28, 38);
    if st.hp <= 0 {
        respawn_at_tutorial_preserving_progress();
    }
}

fn break_block_at(bx: i32, by: i32, bz: i32) {
    let b = get_block(bx, by, bz);
    if is_block_destructible(b) == 0 { return; }
    set_block(bx, by, bz, BLK_AIR);
    record_block_delta(bx, by, bz, BLK_AIR);
    let cx = (bx as f64) + 0.5;
    let cy = (by as f64) + 0.5;
    let cz = (bz as f64) + 0.5;
    spawn_burst(cx, cy, cz, block_base_rgb(b), 12);
    if b == BLK_CRATE {
        let _ = spawn_entity(ENT_GOLD, cx, cy, cz, 1, -1, 0);
        let _ = spawn_entity(ENT_AMMO, cx + 0.25, cy, cz, 1, -1, 0);
        set_status_msg("Crate smashed! Gold & Ammo dropped.", 1400);
    } else if b == BLK_GOLD_ORE {
        let _ = spawn_entity(ENT_GOLD, cx, cy, cz, 1, -1, 0);
        add_gold(15);
        set_status_msg("Gold Ore mined! +15 Gold!", 1400);
    } else if b == BLK_SPAWNER {
        let _ = spawn_entity(ENT_GOLD, cx, cy, cz, 1, -1, 0);
        let _ = spawn_entity(ENT_ARMOR, cx, cy + 0.2, cz, 1, -1, 0);
        st.kills = st.kills + 1;
        set_status_msg("Spawner destroyed!", 1500);
    }
}

fn damage_entity(idx: i32, dmg: i32, stun_ms: i32) {
    if st.entities[idx].active == 0 { return; }
    let k = st.entities[idx].kind;
    if k < ENT_RAT || k > ENT_SINGULARITY { return; }
    if stun_ms > st.entities[idx].freeze_ms {
        st.entities[idx].freeze_ms = stun_ms;
    }
    st.entities[idx].hp = st.entities[idx].hp - dmg;
    spawn_burst(st.entities[idx].x, st.entities[idx].y, st.entities[idx].z, pack_rgb(255, 110, 60), 6);
    if st.entities[idx].hp <= 0 {
        st.entities[idx].active = 0;
        st.kills = st.kills + 1;
        let ex = st.entities[idx].x;
        let ey = st.entities[idx].y;
        let ez = st.entities[idx].z;
        spawn_burst(ex, ey, ez, pack_rgb(255, 210, 70), 14);
        let _ = spawn_entity(ENT_GOLD, ex, ey, ez, 1, -1, 0);
        if k == ENT_GOON || k == ENT_MARINE || k == ENT_PIRATE {
            let _ = spawn_entity(ENT_AMMO, ex + 0.25, ey, ez, 1, -1, 0);
        }
        if k == ENT_SINGULARITY {
            st.quasar_drive = 1;
            add_gold(500);
            let _ = spawn_entity(ENT_ARMOR, ex + 0.4, ey, ez, 1, -1, 0);
            let _ = spawn_entity(ENT_HEALTH, ex - 0.4, ey, ez, 1, -1, 0);
            set_status_msg("THE SINGULARITY DEFEATED! Quasar Drive unlocked for Weapon 0! Approach K [F]!", 4800);
        } else if (rng_u32() % 3) == 0 {
            let _ = spawn_entity(ENT_HEALTH, ex + 0.3, ey, ez, 1, -1, 0);
        }
    }
}

fn explosion_at(x: f64, y: f64, z: f64, rad: f64, dmg: i32, stun_ms: i32, pull_in: i32, rgb: u32) {
    spawn_burst(x, y, z, rgb, 18);
    var i: i32 = 0;
    while i < MAX_ENTITIES {
        if st.entities[i].active != 0 && st.entities[i].kind >= ENT_RAT && st.entities[i].kind <= ENT_SINGULARITY {
            let dx = st.entities[i].x - x;
            let dy = st.entities[i].y - y;
            let dz = st.entities[i].z - z;
            let d = fsqrt(dx * dx + dy * dy + dz * dz);
            if d <= rad {
                if pull_in != 0 && d > 0.35 {
                    st.entities[i].x = st.entities[i].x - dx * 0.55;
                    st.entities[i].y = st.entities[i].y - dy * 0.55;
                    st.entities[i].z = st.entities[i].z - dz * 0.55;
                }
                damage_entity(i, dmg, stun_ms);
            }
        }
        i = i + 1;
    }
    let ir = (rad + 0.6) as! i32;
    let cx = ffloor(x);
    let cy = ffloor(y);
    let cz = ffloor(z);
    var bz: i32 = cz - ir;
    while bz <= cz + ir {
        var by: i32 = cy - ir;
        while by <= cy + ir {
            var bx: i32 = cx - ir;
            while bx <= cx + ir {
                if is_block_destructible(get_block(bx, by, bz)) != 0 {
                    break_block_at(bx, by, bz);
                }
                bx = bx + 1;
            }
            by = by + 1;
        }
        bz = bz + 1;
    }
}

fn camera_forward(fx: f64&, fy: f64&, fz: f64&) {
    let cp = fcos(st.pitch);
    fx = cp * fcos(st.yaw);
    fy = fsin(st.pitch);
    fz = cp * fsin(st.yaw);
}

fn fire_weapon(secondary: i32) {
    if st.fire_cd_ms > 0 { return; }
    let w = st.weapon;
    if st.wep_unlocked[w] == 0 {
        set_status_msg("Weapon locked! Find Weapon Module or Buy Station to unlock.", 1400);
        return;
    }
    let cost: i32 = if w == WEP_PLASMA { 0 } else if secondary != 0 && (w == WEP_HOMING || w == WEP_NUKE) { 2 } else { 1 };
    if w != WEP_PLASMA && st.ammo[w] < cost {
        st.weapon = WEP_PLASMA;
        set_status_msg("Out of ammo — switched to 1:Plasma!", 1200);
        return;
    }
    if w != WEP_PLASMA { st.ammo[w] = st.ammo[w] - cost; }

    var dx: f64 = 0.0;
    var dy: f64 = 0.0;
    var dz: f64 = 0.0;
    camera_forward(dx, dy, dz);

    let rof_mul = 1.0 / (1.0 + 0.15 * ((st.rof_lvl - 1) as f64));
    let dmg_mul = 1.0 + 0.20 * ((st.dmg_lvl - 1) as f64);

    if w == WEP_PLASMA {
        if secondary != 0 {
            st.fire_cd_ms = (320.0 * rof_mul) as! i32;
            let dmg = (14.0 * dmg_mul) as! i32;
            var s: i32 = -1;
            while s <= 1 {
                let syaw = st.yaw + s * 0.12;
                let cp = fcos(st.pitch);
                let sx = cp * fcos(syaw);
                let sz = cp * fsin(syaw);
                spawn_shot(1, w, 1, st.px + sx * 0.4, st.py + dy * 0.4, st.pz + sz * 0.4,
                    sx * 16.0, dy * 16.0, sz * 16.0, dmg, 1300, pack_rgb(64, 232, 255));
                s = s + 1;
            }
        } else {
            st.fire_cd_ms = (190.0 * rof_mul) as! i32;
            let dmg = (20.0 * dmg_mul) as! i32;
            spawn_shot(1, w, 0, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 17.0, dy * 17.0, dz * 17.0, dmg, 1400, pack_rgb(56, 224, 255));
        }
    } else if w == WEP_CANNON {
        st.fire_cd_ms = ((if secondary != 0 { 190.0 } else { 380.0 }) * rof_mul) as! i32;
        let dmg = ((if secondary != 0 { 32.0 } else { 48.0 }) * dmg_mul) as! i32;
        let spd = if secondary != 0 { 19.0 } else { 15.0 };
        spawn_shot(1, w, secondary, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
            dx * spd, dy * spd, dz * spd, dmg, 1600, pack_rgb(255, 160, 48));
    } else if w == WEP_LASER {
        if secondary != 0 {
            // Laser Secondary: Cryo-Freeze burst + Shield Recharge (+8 Armor)!
            st.fire_cd_ms = (480.0 * rof_mul) as! i32;
            st.armor = clamp_i(st.armor + 8, 0, st.max_armor);
            explosion_at(st.px + dx * 3.0, st.py + dy * 3.0, st.pz + dz * 3.0, 4.5, (20.0 * dmg_mul) as! i32, 3500, 0, pack_rgb(80, 220, 255));
            set_status_msg("Laser Pulse: Enemies frozen +8 Armor!", 1200);
        } else {
            st.fire_cd_ms = (250.0 * rof_mul) as! i32;
            let dmg = (34.0 * dmg_mul) as! i32;
            let col = pack_rgb(255, 68, 86);
            var t: f64 = 0.4;
            var end_x = st.px + dx * 18.0;
            var end_y = st.py + dy * 18.0;
            var end_z = st.pz + dz * 18.0;
            while t < 20.0 {
                let hx = st.px + dx * t;
                let hy = st.py + dy * t;
                let hz = st.pz + dz * t;
                let bx = ffloor(hx);
                let by = ffloor(hy);
                let bz = ffloor(hz);
                if bx < 0 || bx >= 16 || by < 0 || by >= 16 || bz < 0 || bz >= 16 {
                    end_x = hx; end_y = hy; end_z = hz; break;
                }
                let blk = get_block(bx, by, bz);
                if is_block_solid(blk) != 0 {
                    end_x = hx; end_y = hy; end_z = hz;
                    if is_block_destructible(blk) != 0 { break_block_at(bx, by, bz); }
                    else { spawn_burst(hx, hy, hz, col, 6); }
                    break;
                }
                var ei: i32 = 0;
                while ei < MAX_ENTITIES {
                    if st.entities[ei].active != 0 && st.entities[ei].kind >= ENT_RAT && st.entities[ei].kind <= ENT_SINGULARITY {
                        let ex = st.entities[ei].x - hx;
                        let ey = st.entities[ei].y - hy;
                        let ez = st.entities[ei].z - hz;
                        if (ex * ex + ey * ey + ez * ez) < 0.42 {
                            damage_entity(ei, dmg, 0);
                            end_x = hx; end_y = hy; end_z = hz;
                            t = 99.0;
                            break;
                        }
                    }
                    ei = ei + 1;
                }
                t = t + 0.25;
            }
            st.beam_timer_ms = 140;
            st.beam_rgb = col;
            st.beam_x1 = st.px + dx * 0.45;
            st.beam_y1 = st.py + dy * 0.45 - 0.12;
            st.beam_z1 = st.pz + dz * 0.45;
            st.beam_x2 = end_x; st.beam_y2 = end_y; st.beam_z2 = end_z;
        }
    } else if w == WEP_ROCKET {
        st.fire_cd_ms = (460.0 * rof_mul) as! i32;
        let dmg = ((if secondary != 0 { 72.0 } else { 58.0 }) * dmg_mul) as! i32;
        let spd = if secondary != 0 { 16.0 } else { 12.5 };
        spawn_shot(1, w, secondary, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
            dx * spd, dy * spd, dz * spd, dmg, 1900, pack_rgb(255, 118, 36));
    } else if w == WEP_HOMING {
        st.fire_cd_ms = (420.0 * rof_mul) as! i32;
        let dmg = (44.0 * dmg_mul) as! i32;
        spawn_shot(1, w, secondary, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
            dx * 11.0, dy * 11.0, dz * 11.0, dmg, 2600, pack_rgb(244, 114, 248));
        if secondary != 0 {
            spawn_shot(1, w, secondary, st.px + dx * 0.4 + 0.2, st.py + dy * 0.4 + 0.15, st.pz + dz * 0.4,
                dx * 10.5, dy * 10.5, dz * 10.5, dmg, 2600, pack_rgb(244, 114, 248));
        }
    } else if w == WEP_MINIGUN {
        st.fire_cd_ms = ((if secondary != 0 { 55.0 } else { 80.0 }) * rof_mul) as! i32;
        let dmg = (12.0 * dmg_mul) as! i32;
        let spread = if secondary != 0 { 0.11 } else { 0.045 };
        let jx = dx + (rng_f01() - 0.5) * spread;
        let jy = dy + (rng_f01() - 0.5) * spread;
        let jz = dz + (rng_f01() - 0.5) * spread;
        spawn_shot(1, w, secondary, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
            jx * 22.0, jy * 22.0, jz * 22.0, dmg, 1000, pack_rgb(255, 215, 72));
    } else if w == WEP_RAILGUN {
        // Piercing hitscan + Recoil Boost!
        st.fire_cd_ms = (640.0 * rof_mul) as! i32;
        let dmg = ((if secondary != 0 { 110.0 } else { 78.0 }) * dmg_mul) as! i32;
        let recoil = if secondary != 0 { 9.5 } else { 5.2 };
        st.vx = st.vx - dx * recoil;
        st.vy = st.vy - dy * recoil;
        st.vz = st.vz - dz * recoil;

        let col = pack_rgb(196, 86, 255);
        var t: f64 = 0.4;
        var end_x = st.px + dx * 20.0;
        var end_y = st.py + dy * 20.0;
        var end_z = st.pz + dz * 20.0;
        while t < 22.0 {
            let hx = st.px + dx * t;
            let hy = st.py + dy * t;
            let hz = st.pz + dz * t;
            let bx = ffloor(hx);
            let by = ffloor(hy);
            let bz = ffloor(hz);
            if bx < 0 || bx >= 16 || by < 0 || by >= 16 || bz < 0 || bz >= 16 {
                end_x = hx; end_y = hy; end_z = hz; break;
            }
            let blk = get_block(bx, by, bz);
            if is_block_solid(blk) != 0 {
                end_x = hx; end_y = hy; end_z = hz;
                if is_block_destructible(blk) != 0 { break_block_at(bx, by, bz); }
                else { spawn_burst(hx, hy, hz, col, 7); }
                break;
            }
            var ei: i32 = 0;
            while ei < MAX_ENTITIES {
                if st.entities[ei].active != 0 && st.entities[ei].kind >= ENT_RAT && st.entities[ei].kind <= ENT_SINGULARITY {
                    let ex = st.entities[ei].x - hx;
                    let ey = st.entities[ei].y - hy;
                    let ez = st.entities[ei].z - hz;
                    if (ex * ex + ey * ey + ez * ez) < 0.48 {
                        damage_entity(ei, dmg, 0);
                    }
                }
                ei = ei + 1;
            }
            t = t + 0.30;
        }
        st.beam_timer_ms = 175;
        st.beam_rgb = col;
        st.beam_x1 = st.px + dx * 0.45;
        st.beam_y1 = st.py + dy * 0.45 - 0.12;
        st.beam_z1 = st.pz + dz * 0.45;
        st.beam_x2 = end_x; st.beam_y2 = end_y; st.beam_z2 = end_z;
    } else if w == WEP_EMP {
        if secondary != 0 {
            st.fire_cd_ms = (650.0 * rof_mul) as! i32;
            explosion_at(st.px, st.py, st.pz, 6.5, (28.0 * dmg_mul) as! i32, 4800, 0, pack_rgb(96, 165, 250));
            set_status_msg("EMP Shockwave released! Nearby enemies stunned.", 1400);
        } else {
            st.fire_cd_ms = (480.0 * rof_mul) as! i32;
            let dmg = (24.0 * dmg_mul) as! i32;
            spawn_shot(1, w, 0, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 15.0, dy * 15.0, dz * 15.0, dmg, 1500, pack_rgb(59, 130, 246));
        }
    } else if w == WEP_NUKE {
        // Nuclear Pulse Propulsion Recoil Boost!
        st.fire_cd_ms = (950.0 * rof_mul) as! i32;
        let dmg = ((if secondary != 0 { 220.0 } else { 150.0 }) * dmg_mul) as! i32;
        st.vx = st.vx - dx * 8.2;
        st.vy = st.vy - dy * 8.2;
        st.vz = st.vz - dz * 8.2;
        spawn_shot(1, w, secondary, st.px + dx * 0.5, st.py + dy * 0.5, st.pz + dz * 0.5,
            dx * 9.5, dy * 9.5, dz * 9.5, dmg, 1900, pack_rgb(163, 230, 53));
    } else if w == WEP_DARKHOLE {
        // Dark Hole / Quasar Drive + Recoil Boost!
        st.fire_cd_ms = (880.0 * rof_mul) as! i32;
        let qmul = if st.quasar_drive != 0 { 2.0 } else { 1.0 };
        let dmg = (170.0 * dmg_mul * qmul) as! i32;
        st.vx = st.vx - dx * 7.5;
        st.vy = st.vy - dy * 7.5;
        st.vz = st.vz - dz * 7.5;
        let col = if st.quasar_drive != 0 { pack_rgb(255, 224, 112) } else { pack_rgb(218, 62, 255) };
        spawn_shot(1, w, secondary, st.px + dx * 0.5, st.py + dy * 0.5, st.pz + dz * 0.5,
            dx * 8.5, dy * 8.5, dz * 8.5, dmg, 2100, col);
    }
}

fn trigger_telekinesis() {
    st.telekinesis_ms = 420;
    var pulled: i32 = 0;
    var i: i32 = 0;
    while i < MAX_ENTITIES {
        if st.entities[i].active != 0 && st.entities[i].kind >= ENT_GOLD && st.entities[i].kind <= ENT_KEY {
            let dx = st.px - st.entities[i].x;
            let dy = st.py - st.entities[i].y;
            let dz = st.pz - st.entities[i].z;
            let d = fsqrt(dx * dx + dy * dy + dz * dz);
            if d > 0.2 && d < 14.0 {
                st.entities[i].x = st.px - (dx / d) * 0.4;
                st.entities[i].y = st.py - (dy / d) * 0.4;
                st.entities[i].z = st.pz - (dz / d) * 0.4;
                pulled = pulled + 1;
            }
        }
        i = i + 1;
    }
    if pulled > 0 {
        set_status_msg("Telekinesis pulled nearby pickups!", 1200);
    } else {
        set_status_msg("Telekinesis pulse — no loose pickups in range.", 1000);
    }
}

fn push_marker_frame(f: ScaleFrame) {
    let idx = st.marker_frames_len;
    if idx < (st.marker_frames.len as! i32) {
        st.marker_frames[idx] = f;
    } else {
        st.marker_frames.push(f);
    }
    st.marker_frames_len = idx + 1;
}

fn drop_marker(is_long: i32) {
    var slot: i32 = 0;
    if is_long == 0 {
        // Short marker uses slot 0 so pressing M replaces your quick breadcrumb
        slot = 0;
    } else {
        slot = 1;
        while slot < MAX_MARKERS && st.markers[slot].used != 0 {
            slot = slot + 1;
        }
        if slot >= MAX_MARKERS { slot = 1; }
    }
    let pos_cnt = if st.depth >= 0 { st.depth + 1 } else { 1 };
    let neg_cnt = if st.depth < 0 { -st.depth } else { 0 };
    let pos_off = st.marker_frames_len;
    var wi: i32 = 0;
    while wi < pos_cnt {
        push_marker_frame(get_frame(wi));
        wi = wi + 1;
    }
    let neg_off = st.marker_frames_len;
    wi = 1;
    while wi <= neg_cnt {
        push_marker_frame(get_frame(-wi));
        wi = wi + 1;
    }

    st.markers[slot].used = 1;
    st.markers[slot].is_long = is_long;
    st.markers[slot].depth = st.depth;
    st.markers[slot].px = st.px;
    st.markers[slot].py = st.py;
    st.markers[slot].pz = st.pz;
    st.markers[slot].biome = cur_biome();
    st.markers[slot].pos_off = pos_off;
    st.markers[slot].pos_cnt = pos_cnt;
    st.markers[slot].neg_off = neg_off;
    st.markers[slot].neg_cnt = neg_cnt;
    st.active_marker = slot;
    if is_long != 0 {
        set_status_msg("Long Tracking Marker placed! View & warp via [F4].", 1800);
    } else {
        set_status_msg("Short Marker dropped! Press [F4] to track or warp back.", 1600);
    }
}

fn warp_to_marker(slot: i32) -> i32 {
    if slot < 0 || slot >= MAX_MARKERS || st.markers[slot].used == 0 { return 0; }
    var wi: i32 = 0;
    while wi < st.markers[slot].pos_cnt {
        set_frame(wi, st.marker_frames[st.markers[slot].pos_off + wi]);
        wi = wi + 1;
    }
    wi = 0;
    while wi < st.markers[slot].neg_cnt {
        set_frame(-(wi + 1), st.marker_frames[st.markers[slot].neg_off + wi]);
        wi = wi + 1;
    }
    st.depth = st.markers[slot].depth;
    load_current_chunk();
    st.px = st.markers[slot].px;
    st.py = st.markers[slot].py;
    st.pz = st.markers[slot].pz;
    st.vx = 0.0; st.vy = 0.0; st.vz = 0.0;
    st.flash_ms = 240;
    st.flash_rgb = pack_rgb(74, 222, 128);
    set_status_msg("Warped to Marker!", 1600);
    return 1;
}

fn shrink_targeted_block() {
    st.ring_cd_ms = 0;
    if st.shrink_any != 0 {
        var fx: f64 = 0.0;
        var fy: f64 = 0.0;
        var fz: f64 = 0.0;
        camera_forward(fx, fy, fz);
        var t: f64 = 0.4;
        while t <= 4.5 {
            let hx = st.px + fx * t;
            let hy = st.py + fy * t;
            let hz = st.pz + fz * t;
            let bx = ffloor(hx);
            let by = ffloor(hy);
            let bz = ffloor(hz);
            let b = get_block(bx, by, bz);
            if b != BLK_AIR {
                shrink_into_ex(bx, by, bz, b, -1, 1, hx - fx * 0.35, hy - fy * 0.35, hz - fz * 0.35);
                return;
            }
            t = t + 0.35;
        }
    }
    // Always shrink YOU 16x in-place in open air so surrounding blocks become giant 3D walls with visible holes!
    let pbx = clamp_i(ffloor(st.px), 0, 15);
    let pby = clamp_i(ffloor(st.py), 0, 15);
    let pbz = clamp_i(ffloor(st.pz), 0, 15);
    shrink_into_ex(pbx, pby, pbz, BLK_AIR, -1, 1, st.px, st.py, st.pz);
}

fn use_nearest() {
    // 1) Check Friend K, Rings (strictly matching the HUD [F] Ring prompt radius < 2.4)
    var i: i32 = 0;
    var best_ring: i32 = -1;
    var best_d: f64 = 2.4;
    while i < MAX_ENTITIES {
        if st.entities[i].active != 0 {
            let k = st.entities[i].kind;
            let dx = st.entities[i].x - st.px;
            let dy = st.entities[i].y - st.py;
            let dz = st.entities[i].z - st.pz;
            let d = fsqrt(dx * dx + dy * dy + dz * dz);
            if k == ENT_FRIEND_K && d < 2.6 {
                st.k_rescued = 1;
                st.entities[i].active = 0;
                add_gold(500);
                st.screen = SCREEN_VICTORY;
                return;
            }
            if k >= ENT_RING_GREEN && k <= ENT_RING_PINK && d < best_d {
                best_d = d;
                best_ring = i;
            }
        }
        i = i + 1;
    }

    // 2) Ray-probe ahead up to 2.5 units for Station / Tome / Locked Door / Fractal Block hint
    var fx: f64 = 0.0;
    var fy: f64 = 0.0;
    var fz: f64 = 0.0;
    camera_forward(fx, fy, fz);
    var t: f64 = 0.4;
    while t <= 2.6 {
        let bx = ffloor(st.px + fx * t);
        let by = ffloor(st.py + fy * t);
        let bz = ffloor(st.pz + fz * t);
        let b = get_block(bx, by, bz);
        if b == BLK_BUY_STATION { st.screen = SCREEN_BUY; return; }
        if b == BLK_SELL_STATION { st.screen = SCREEN_SELL; return; }
        if b == BLK_BLACK_MARKET { st.screen = SCREEN_BLACK_MARKET; return; }
        if b == BLK_TOME {
            st.tome_id = cur_biome();
            st.screen = SCREEN_TOME;
            return;
        }
        if b == BLK_LOCKED_DOOR {
            if st.keys > 0 {
                st.keys = st.keys - 1;
                set_block(bx, by, bz, BLK_AIR);
                record_block_delta(bx, by, bz, BLK_AIR);
                set_status_msg("Unlocked Vault Door using 1 Key!", 1800);
            } else {
                set_status_msg("Locked Vault Door — requires a Key!", 1600);
            }
            return;
        }
        if is_block_shrinkable(b) != 0 && (best_ring < 0 || best_d >= 1.6) {
            set_status_msg("Solid block! Press [B] to shrink 16x and fly through its 3D hole!", 1600);
            return;
        }
        t = t + 0.35;
    }

    // 3) If a Ring is within activation distance (matching the HUD [F] Ring prompt), activate it immediately!
    if best_ring >= 0 {
        st.ring_cd_ms = 0;
        let k = st.entities[best_ring].kind;
        let rx = clamp_i(ffloor(st.entities[best_ring].x), 0, 15);
        let ry = clamp_i(ffloor(st.entities[best_ring].y), 0, 15);
        let rz = clamp_i(ffloor(st.entities[best_ring].z), 0, 15);
        let tb = st.entities[best_ring].target_block;
        let tbio = st.entities[best_ring].target_biome;
        if k == ENT_RING_RED { grow_out_axis(st.px, st.py, st.pz); }
        else if k == ENT_RING_PINK { shrink_into_ex(rx, ry, rz, tb, tbio, 2, st.px, st.py, st.pz); }
        else { shrink_into_ex(rx, ry, rz, tb, tbio, 1, st.px, st.py, st.pz); }
        return;
    }

    // 4) Check adjacent interactive block in immediate 3x3x3 neighborhood
    let pbx = ffloor(st.px);
    let pby = ffloor(st.py);
    let pbz = ffloor(st.pz);
    var dz2: i32 = -1;
    while dz2 <= 1 {
        var dy2: i32 = -1;
        while dy2 <= 1 {
            var dx2: i32 = -1;
            while dx2 <= 1 {
                let nb = get_block(pbx + dx2, pby + dy2, pbz + dz2);
                if nb == BLK_BUY_STATION { st.screen = SCREEN_BUY; return; }
                if nb == BLK_SELL_STATION { st.screen = SCREEN_SELL; return; }
                if nb == BLK_BLACK_MARKET { st.screen = SCREEN_BLACK_MARKET; return; }
                if nb == BLK_TOME {
                    st.tome_id = cur_biome();
                    st.screen = SCREEN_TOME;
                    return;
                }
                dx2 = dx2 + 1;
            }
            dy2 = dy2 + 1;
        }
        dz2 = dz2 + 1;
    }

    set_status_msg("Nothing interactive right ahead. Aim at a Station, Tome, or Fractal Block and press [F]!", 1600);
}

fn handle_buy_action(choice: i32) {
    // Buy Station items (authentic FBW Gold economy; also unlocks purchased munitions tier)
    if choice == 1 && st.gold >= 15 {
        st.gold = st.gold - 15;
        st.hp = clamp_i(st.hp + 50, 0, st.max_hp);
        set_status_msg("Bought +50 HP!", 1400);
    } else if choice == 2 && st.gold >= 20 {
        st.gold = st.gold - 20;
        st.armor = clamp_i(st.armor + 50, 0, st.max_armor);
        set_status_msg("Bought +50 Armor!", 1400);
    } else if choice == 3 && st.gold >= 25 {
        st.gold = st.gold - 25;
        st.wep_unlocked[WEP_CANNON] = 1;
        st.wep_unlocked[WEP_LASER] = 1;
        st.wep_unlocked[WEP_MINIGUN] = 1;
        st.ammo[WEP_CANNON] = clamp_i(st.ammo[WEP_CANNON] + 20, 0, st.max_ammo[WEP_CANNON]);
        st.ammo[WEP_LASER] = clamp_i(st.ammo[WEP_LASER] + 30, 0, st.max_ammo[WEP_LASER]);
        st.ammo[WEP_MINIGUN] = clamp_i(st.ammo[WEP_MINIGUN] + 80, 0, st.max_ammo[WEP_MINIGUN]);
        set_status_msg("Unlocked & stocked Cannon / Laser / Minigun!", 1500);
    } else if choice == 4 && st.gold >= 40 {
        st.gold = st.gold - 40;
        st.wep_unlocked[WEP_ROCKET] = 1;
        st.wep_unlocked[WEP_HOMING] = 1;
        st.wep_unlocked[WEP_RAILGUN] = 1;
        st.wep_unlocked[WEP_EMP] = 1;
        st.ammo[WEP_ROCKET] = clamp_i(st.ammo[WEP_ROCKET] + 10, 0, st.max_ammo[WEP_ROCKET]);
        st.ammo[WEP_HOMING] = clamp_i(st.ammo[WEP_HOMING] + 8, 0, st.max_ammo[WEP_HOMING]);
        st.ammo[WEP_RAILGUN] = clamp_i(st.ammo[WEP_RAILGUN] + 8, 0, st.max_ammo[WEP_RAILGUN]);
        st.ammo[WEP_EMP] = clamp_i(st.ammo[WEP_EMP] + 5, 0, st.max_ammo[WEP_EMP]);
        set_status_msg("Unlocked & stocked Rocket / Homing / Railgun / EMP!", 1500);
    } else if choice == 5 && st.gold >= 60 {
        st.gold = st.gold - 60;
        st.wep_unlocked[WEP_NUKE] = 1;
        st.wep_unlocked[WEP_DARKHOLE] = 1;
        st.ammo[WEP_NUKE] = clamp_i(st.ammo[WEP_NUKE] + 2, 0, st.max_ammo[WEP_NUKE]);
        st.ammo[WEP_DARKHOLE] = clamp_i(st.ammo[WEP_DARKHOLE] + 2, 0, st.max_ammo[WEP_DARKHOLE]);
        set_status_msg("Unlocked & stocked Nuke & Dark Hole!", 1500);
    } else if choice == 6 && st.gold >= 50 {
        st.gold = st.gold - 50;
        st.keys = st.keys + 1;
        set_status_msg("Bought 1 Vault Key!", 1400);
    }
}

fn handle_sell_action(choice: i32) {
    // Sell Station: convert excess HP / Armor / Key into Gold!
    if choice == 1 && st.hp > 25 {
        st.hp = st.hp - 25;
        add_gold(20);
        set_status_msg("Sold 25 HP for +20 Gold!", 1400);
    } else if choice == 2 && st.armor >= 25 {
        st.armor = st.armor - 25;
        add_gold(18);
        set_status_msg("Sold 25 Armor for +18 Gold!", 1400);
    } else if choice == 3 && st.ammo[WEP_MINIGUN] >= 50 {
        st.ammo[WEP_MINIGUN] = st.ammo[WEP_MINIGUN] - 50;
        add_gold(15);
        set_status_msg("Sold 50 Minigun rounds for +15 Gold!", 1400);
    } else if choice == 4 && st.keys >= 1 {
        st.keys = st.keys - 1;
        add_gold(40);
        set_status_msg("Sold 1 Vault Key for +40 Gold!", 1400);
    }
}

fn handle_black_market_action(choice: i32) {
    // Black Market: discounted high-tier Railgun, EMP, Nuke, Dark Hole!
    if choice == 1 && st.gold >= 20 {
        st.gold = st.gold - 20;
        st.wep_unlocked[WEP_RAILGUN] = 1;
        st.ammo[WEP_RAILGUN] = clamp_i(st.ammo[WEP_RAILGUN] + 12, 0, st.max_ammo[WEP_RAILGUN]);
        set_status_msg("Black Market: +12 Railgun Slugs!", 1400);
    } else if choice == 2 && st.gold >= 18 {
        st.gold = st.gold - 18;
        st.wep_unlocked[WEP_EMP] = 1;
        st.ammo[WEP_EMP] = clamp_i(st.ammo[WEP_EMP] + 8, 0, st.max_ammo[WEP_EMP]);
        set_status_msg("Black Market: +8 EMP Charges!", 1400);
    } else if choice == 3 && st.gold >= 30 {
        st.gold = st.gold - 30;
        st.wep_unlocked[WEP_NUKE] = 1;
        st.ammo[WEP_NUKE] = clamp_i(st.ammo[WEP_NUKE] + 3, 0, st.max_ammo[WEP_NUKE]);
        set_status_msg("Black Market: +3 Nukes!", 1400);
    } else if choice == 4 && st.gold >= 35 {
        st.gold = st.gold - 35;
        st.wep_unlocked[WEP_DARKHOLE] = 1;
        st.ammo[WEP_DARKHOLE] = clamp_i(st.ammo[WEP_DARKHOLE] + 3, 0, st.max_ammo[WEP_DARKHOLE]);
        set_status_msg("Black Market: +3 Dark Holes!", 1400);
    }
}

fn step_simulation(dt_ms: i32) {
    if st.screen != SCREEN_PLAY { return; }
    let dt = (dt_ms as f64) / 1000.0;

    if st.fire_cd_ms > 0 { st.fire_cd_ms = st.fire_cd_ms - dt_ms; if st.fire_cd_ms < 0 { st.fire_cd_ms = 0; } }
    if st.ring_cd_ms > 0 { st.ring_cd_ms = st.ring_cd_ms - dt_ms; if st.ring_cd_ms < 0 { st.ring_cd_ms = 0; } }
    if st.beam_timer_ms > 0 { st.beam_timer_ms = st.beam_timer_ms - dt_ms; if st.beam_timer_ms < 0 { st.beam_timer_ms = 0; } }
    if st.flash_ms > 0 { st.flash_ms = st.flash_ms - dt_ms; if st.flash_ms < 0 { st.flash_ms = 0; } }
    if st.msg_ms > 0 { st.msg_ms = st.msg_ms - dt_ms; if st.msg_ms < 0 { st.msg_ms = 0; } }
    if st.telekinesis_ms > 0 { st.telekinesis_ms = st.telekinesis_ms - dt_ms; if st.telekinesis_ms < 0 { st.telekinesis_ms = 0; } }
    if st.turning_ms > 0 { st.turning_ms = st.turning_ms - dt_ms; if st.turning_ms < 0 { st.turning_ms = 0; } }

    // Smooth Angular Velocity Looking (matching jet mode flight inertia)
    if fabs(st.yaw_vel) > 0.0005 || fabs(st.pitch_vel) > 0.0005 {
        st.yaw = wrap_angle(st.yaw + st.yaw_vel * dt);
        st.pitch = fclamp(st.pitch + st.pitch_vel * dt, -1.25, 1.25);
        if fabs(st.pitch) >= 1.249 { st.pitch_vel = 0.0; }
        let turn_decay = fclamp(1.0 - 9.2 * dt, 0.08, 0.96);
        st.yaw_vel = st.yaw_vel * turn_decay;
        st.pitch_vel = st.pitch_vel * turn_decay;
        if fabs(st.yaw_vel) < 0.002 { st.yaw_vel = 0.0; }
        if fabs(st.pitch_vel) < 0.002 { st.pitch_vel = 0.0; }
    }

    // True Up smoothly levels camera roll
    if st.true_up != 0 && fabs(st.roll) > 0.001 {
        st.roll = st.roll * 0.72;
        if fabs(st.roll) < 0.01 { st.roll = 0.0; }
    }

    // Passive Health Regeneration
    if st.hp_regen > 0 && st.hp < st.max_hp {
        st.regen_accum_ms = st.regen_accum_ms + dt_ms;
        if st.regen_accum_ms >= 2000 {
            st.regen_accum_ms = st.regen_accum_ms - 2000;
            st.hp = clamp_i(st.hp + st.hp_regen, 0, st.max_hp);
        }
    }

    // 6-DOF Velocity integration & air drag (Rocket Mode vs Standard)
    let speed_sq = st.vx * st.vx + st.vy * st.vy + st.vz * st.vz;
    if speed_sq > 0.0001 {
        move_player_vec(st.vx * dt, st.vy * dt, st.vz * dt);
        let drag_rate = if st.rocket_mode != 0 { 0.85 } else { 7.2 };
        let decay = fclamp(1.0 - drag_rate * dt, 0.05, 0.99);
        st.vx = st.vx * decay;
        st.vy = st.vy * decay;
        st.vz = st.vz * decay;
    }

    // Probe block directly in front for HUD context prompt
    st.near_prompt_len = 0;
    var fx: f64 = 0.0;
    var fy: f64 = 0.0;
    var fz: f64 = 0.0;
    camera_forward(fx, fy, fz);
    var pt: f64 = 0.5;
    while pt <= 2.4 {
        let blk = get_block(ffloor(st.px + fx * pt), ffloor(st.py + fy * pt), ffloor(st.pz + fz * pt));
        if blk != BLK_AIR {
            let lbl = block_label(blk);
            if lbl.len > 0 { set_near_prompt(lbl); }
            break;
        }
        pt = pt + 0.4;
    }

    // Update entities
    st.near_ring_kind = ENT_NONE;
    var i: i32 = 0;
    while i < MAX_ENTITIES {
        if st.entities[i].active == 0 {
            i = i + 1;
            continue;
        }
        let k = st.entities[i].kind;
        if st.entities[i].freeze_ms > 0 {
            st.entities[i].freeze_ms = st.entities[i].freeze_ms - dt_ms;
            if st.entities[i].freeze_ms < 0 { st.entities[i].freeze_ms = 0; }
        }
        let dx = st.px - st.entities[i].x;
        let dy = st.py - st.entities[i].y;
        let dz = st.pz - st.entities[i].z;
        let dist = fsqrt(dx * dx + dy * dy + dz * dz);

        if k >= ENT_RING_GREEN && k <= ENT_RING_PINK {
            // Rings activate explicitly with [F] (never auto-warp on touch/proximity)
            if dist < 2.4 { st.near_ring_kind = k; }
        } else if k == ENT_FRIEND_K {
            if dist < 1.15 {
                st.k_rescued = 1;
                st.entities[i].active = 0;
                add_gold(500);
                st.screen = SCREEN_VICTORY;
                return;
            }
        } else if k >= ENT_GOLD && k <= ENT_KEY {
            if dist < 1.15 {
                st.entities[i].active = 0;
                if k == ENT_GOLD {
                    let gain = 15 + (if st.depth > 0 { st.depth * 8 } else { 0 });
                    add_gold(gain);
                    set_status_msg("+Gold collected!", 900);
                } else if k == ENT_HEALTH {
                    st.hp = clamp_i(st.hp + 25, 0, st.max_hp);
                    set_status_msg("+25 Health restored!", 900);
                } else if k == ENT_ARMOR {
                    st.armor = clamp_i(st.armor + 25, 0, st.max_armor);
                    set_status_msg("+25 Armor!", 900);
                } else if k == ENT_KEY {
                    st.keys = st.keys + 1;
                    set_status_msg("+1 Vault Key collected!", 1100);
                } else if k == ENT_AMMO {
                    st.ammo[WEP_CANNON] = clamp_i(st.ammo[WEP_CANNON] + 10, 0, st.max_ammo[WEP_CANNON]);
                    st.ammo[WEP_LASER] = clamp_i(st.ammo[WEP_LASER] + 15, 0, st.max_ammo[WEP_LASER]);
                    st.ammo[WEP_ROCKET] = clamp_i(st.ammo[WEP_ROCKET] + 5, 0, st.max_ammo[WEP_ROCKET]);
                    st.ammo[WEP_HOMING] = clamp_i(st.ammo[WEP_HOMING] + 4, 0, st.max_ammo[WEP_HOMING]);
                    st.ammo[WEP_MINIGUN] = clamp_i(st.ammo[WEP_MINIGUN] + 45, 0, st.max_ammo[WEP_MINIGUN]);
                    st.ammo[WEP_RAILGUN] = clamp_i(st.ammo[WEP_RAILGUN] + 4, 0, st.max_ammo[WEP_RAILGUN]);
                    st.ammo[WEP_EMP] = clamp_i(st.ammo[WEP_EMP] + 2, 0, st.max_ammo[WEP_EMP]);
                    st.ammo[WEP_NUKE] = clamp_i(st.ammo[WEP_NUKE] + 1, 0, st.max_ammo[WEP_NUKE]);
                    st.ammo[WEP_DARKHOLE] = clamp_i(st.ammo[WEP_DARKHOLE] + 1, 0, st.max_ammo[WEP_DARKHOLE]);
                    set_status_msg("+Ammo Pack collected!", 1000);
                }
            }
        } else if k >= ENT_RAT && k <= ENT_SINGULARITY {
            if st.entities[i].freeze_ms > 0 {
                // Frozen by EMP or Laser Secondary!
                i = i + 1;
                continue;
            }
            if dist > 0.2 && dist < 13.0 {
                let spd =
                    if k == ENT_RAT { 2.8 }
                    else if k == ENT_SPIDER { 2.4 }
                    else if k == ENT_GOON { 1.8 }
                    else if k == ENT_MARINE { 1.5 }
                    else if k == ENT_PIRATE { 2.1 }
                    else if k == ENT_YINYANG { 1.6 }
                    else if k == ENT_MENACE { 0.8 }
                    else if k == ENT_DEMON { 1.9 }
                    else if k == ENT_GUARDIAN { 1.2 }
                    else { 1.45 };
                if dist > 1.35 {
                    let nx = st.entities[i].x + (dx / dist) * spd * dt;
                    let ny = st.entities[i].y + (dy / dist) * spd * 0.75 * dt;
                    let nz = st.entities[i].z + (dz / dist) * spd * dt;
                    if is_block_solid(get_block(ffloor(nx), ffloor(st.entities[i].y), ffloor(st.entities[i].z))) == 0 {
                        st.entities[i].x = nx;
                    }
                    if is_block_solid(get_block(ffloor(st.entities[i].x), ffloor(ny), ffloor(st.entities[i].z))) == 0 {
                        st.entities[i].y = ny;
                    }
                    if is_block_solid(get_block(ffloor(st.entities[i].x), ffloor(st.entities[i].y), ffloor(nz))) == 0 {
                        st.entities[i].z = nz;
                    }
                }

                st.entities[i].cooldown = st.entities[i].cooldown - dt_ms;
                if st.entities[i].cooldown <= 0 {
                    if dist < 1.4 {
                        damage_player(6 + (if st.depth > 0 { st.depth * 2 } else { 0 }));
                        st.entities[i].cooldown = 850;
                    } else if dist < 11.5 && k != ENT_RAT {
                        let sspd = if k == ENT_SINGULARITY { 9.5 } else { 7.5 };
                        let edmg = 6 + (if st.depth > 0 { st.depth * 2 } else { 0 }) + (if k == ENT_SINGULARITY { 10 } else { 0 });
                        let ergb = if k == ENT_SINGULARITY { pack_rgb(255, 64, 210) } else { pack_rgb(255, 92, 64) };
                        spawn_shot(0, 0, 0, st.entities[i].x, st.entities[i].y, st.entities[i].z,
                            (dx / dist) * sspd, (dy / dist) * sspd, (dz / dist) * sspd, edmg, 1750, ergb);
                        st.entities[i].cooldown = if k == ENT_SINGULARITY { 650 } else if k == ENT_MENACE { 1100 } else { 1550 };
                    }
                }
            }
        }
        i = i + 1;
    }

    // Update projectiles (including Homing steering & Dark Hole gravity pull!)
    i = 0;
    while i < MAX_SHOTS {
        if st.shots[i].active == 0 {
            i = i + 1;
            continue;
        }
        st.shots[i].ttl_ms = st.shots[i].ttl_ms - dt_ms;

        // Homing guidance for WEP_HOMING
        if st.shots[i].from_player != 0 && st.shots[i].wep == WEP_HOMING {
            var best_e: i32 = -1;
            var best_ed: f64 = 12.0;
            var ei: i32 = 0;
            while ei < MAX_ENTITIES {
                if st.entities[ei].active != 0 && st.entities[ei].kind >= ENT_RAT && st.entities[ei].kind <= ENT_SINGULARITY {
                    let hx = st.entities[ei].x - st.shots[i].x;
                    let hy = st.entities[ei].y - st.shots[i].y;
                    let hz = st.entities[ei].z - st.shots[i].z;
                    let hd = fsqrt(hx * hx + hy * hy + hz * hz);
                    if hd < best_ed { best_ed = hd; best_e = ei; }
                }
                ei = ei + 1;
            }
            if best_e >= 0 && best_ed > 0.1 {
                let tx = ((st.entities[best_e].x - st.shots[i].x) / best_ed) * 12.0;
                let ty = ((st.entities[best_e].y - st.shots[i].y) / best_ed) * 12.0;
                let tz = ((st.entities[best_e].z - st.shots[i].z) / best_ed) * 12.0;
                st.shots[i].vx = st.shots[i].vx * 0.82 + tx * 0.18;
                st.shots[i].vy = st.shots[i].vy * 0.82 + ty * 0.18;
                st.shots[i].vz = st.shots[i].vz * 0.82 + tz * 0.18;
            }
        }

        if st.shots[i].ttl_ms <= 0 {
            if st.shots[i].from_player != 0 {
                let sw = st.shots[i].wep;
                if sw == WEP_ROCKET || sw == WEP_HOMING || sw == WEP_EMP || sw == WEP_NUKE || sw == WEP_DARKHOLE {
                    let rad = if sw == WEP_NUKE { 5.2 } else if sw == WEP_DARKHOLE { if st.quasar_drive != 0 { 6.2 } else { 4.5 } } else if sw == WEP_EMP { 4.2 } else { 2.6 };
                    let stun: i32 = if sw == WEP_EMP { 4500 } else { 0 };
                    let pull: i32 = if sw == WEP_DARKHOLE { 1 } else { 0 };
                    explosion_at(st.shots[i].x, st.shots[i].y, st.shots[i].z, rad, st.shots[i].dmg, stun, pull, st.shots[i].rgb);
                }
            }
            st.shots[i].active = 0;
            i = i + 1;
            continue;
        }

        let nx = st.shots[i].x + st.shots[i].vx * dt;
        let ny = st.shots[i].y + st.shots[i].vy * dt;
        let nz = st.shots[i].z + st.shots[i].vz * dt;
        let bx = ffloor(nx);
        let by = ffloor(ny);
        let bz = ffloor(nz);
        if bx < 0 || bx >= 16 || by < 0 || by >= 16 || bz < 0 || bz >= 16 {
            st.shots[i].active = 0;
            i = i + 1;
            continue;
        }
        let blk = get_block(bx, by, bz);
        if is_block_solid(blk) != 0 {
            if st.shots[i].from_player != 0 {
                let sw = st.shots[i].wep;
                if sw == WEP_ROCKET || sw == WEP_HOMING || sw == WEP_EMP || sw == WEP_NUKE || sw == WEP_DARKHOLE {
                    let rad = if sw == WEP_NUKE { 5.2 } else if sw == WEP_DARKHOLE { if st.quasar_drive != 0 { 6.2 } else { 4.5 } } else if sw == WEP_EMP { 4.2 } else { 2.6 };
                    let stun: i32 = if sw == WEP_EMP { 4500 } else { 0 };
                    let pull: i32 = if sw == WEP_DARKHOLE { 1 } else { 0 };
                    explosion_at(nx, ny, nz, rad, st.shots[i].dmg, stun, pull, st.shots[i].rgb);
                } else {
                    spawn_burst(nx, ny, nz, st.shots[i].rgb, 5);
                    if is_block_destructible(blk) != 0 { break_block_at(bx, by, bz); }
                }
            }
            st.shots[i].active = 0;
            i = i + 1;
            continue;
        }

        st.shots[i].x = nx;
        st.shots[i].y = ny;
        st.shots[i].z = nz;

        if st.shots[i].from_player != 0 {
            var ei: i32 = 0;
            while ei < MAX_ENTITIES {
                if st.entities[ei].active != 0 && st.entities[ei].kind >= ENT_RAT && st.entities[ei].kind <= ENT_SINGULARITY {
                    let ex = st.entities[ei].x - nx;
                    let ey = st.entities[ei].y - ny;
                    let ez = st.entities[ei].z - nz;
                    if (ex * ex + ey * ey + ez * ez) < 0.45 {
                        let sw = st.shots[i].wep;
                        if sw == WEP_ROCKET || sw == WEP_HOMING || sw == WEP_EMP || sw == WEP_NUKE || sw == WEP_DARKHOLE {
                            let rad = if sw == WEP_NUKE { 5.2 } else if sw == WEP_DARKHOLE { if st.quasar_drive != 0 { 6.2 } else { 4.5 } } else if sw == WEP_EMP { 4.2 } else { 2.6 };
                            let stun: i32 = if sw == WEP_EMP { 4500 } else { 0 };
                            let pull: i32 = if sw == WEP_DARKHOLE { 1 } else { 0 };
                            explosion_at(nx, ny, nz, rad, st.shots[i].dmg, stun, pull, st.shots[i].rgb);
                        } else {
                            damage_entity(ei, st.shots[i].dmg, 0);
                        }
                        st.shots[i].active = 0;
                        break;
                    }
                }
                ei = ei + 1;
            }
        } else {
            let ex = st.px - nx;
            let ey = st.py - ny;
            let ez = st.pz - nz;
            if (ex * ex + ey * ey + ez * ez) < 0.38 {
                damage_player(st.shots[i].dmg);
                st.shots[i].active = 0;
            }
        }
        i = i + 1;
    }

    // Update particles
    i = 0;
    while i < MAX_PARTICLES {
        if st.particles[i].active != 0 {
            st.particles[i].ttl_ms = st.particles[i].ttl_ms - dt_ms;
            if st.particles[i].ttl_ms <= 0 {
                st.particles[i].active = 0;
            } else {
                st.particles[i].x = st.particles[i].x + st.particles[i].vx * dt;
                st.particles[i].y = st.particles[i].y + st.particles[i].vy * dt;
                st.particles[i].z = st.particles[i].z + st.particles[i].vz * dt;
            }
        }
        i = i + 1;
    }
}
