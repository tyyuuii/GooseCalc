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
const MAX_DELTAS: i32 = 2048;
const MAX_MARKERS: i32 = 16;

const MAX_GOLD: i32 = 1000000;
const DEATH_GOLD_PENALTY: i32 = 30;
const SHORT_MARKER_TTL_MS: i64 = 10800000; // 3 hours game time

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
const SCREEN_UPGRADE: i32 = 13;
const SCREEN_EDIT_UI: i32 = 14;
const SCREEN_ARCADE: i32 = 15;

// Biomes (Authentic Steam Xar Progression 0..23)
const BIOME_SPACE: i32 = 0;          // Outer Space Level 0 (depth < 0)
const BIOME_TUTORIAL: i32 = 1;       // Tutorial Room & Tutorial Island (depth == 0)
const BIOME_YING_FOREST: i32 = 2;    // Ying Forest (Ying Trees, Totems, Flowers)
const BIOME_WHITE_FLOWER: i32 = 3;   // Small White Flower / Alpha Cube
const BIOME_YELLOW_FLOWER: i32 = 4;  // Small & Jumbo Yellow Flower Labyrinths
const BIOME_MYLANTIS: i32 = 5;       // Mylantis Crust & Caves
const BIOME_BLACK_CUBE: i32 = 6;     // Black Cube / I1 / I2 / I3 Menger Lattice
const BIOME_INNER_CORE: i32 = 7;     // The Core / Singularity & K
const BIOME_ICE_WORLD: i32 = 8;      // Glacial Spire & Ice Caves
const BIOME_DESERT_WORLD: i32 = 9;   // Sandstone Pyramid & Gold Tomb
const BIOME_NOOB_FLOWER: i32 = 10;   // Noob Flower Sanctuary
const BIOME_YING_LIBRARY: i32 = 11;  // Ying Library & Tome Archives
const BIOME_BOTANY_LAB: i32 = 12;    // Botany Lab Bio-Domed Tanks
const BIOME_BETA_CUBE: i32 = 13;     // Beta Cube Checkerboard Vault
const BIOME_RED_CAVES: i32 = 14;     // Deep Red Caverns
const BIOME_I1_LIGHTHOUSE: i32 = 15; // I1 Beacon & Crystal Lighthouse
const BIOME_I2_MOUNTAINS: i32 = 16;  // I2 Ridge & Lunar Highlands
const BIOME_BURLINGTON: i32 = 17;    // Burlington Citadel
const BIOME_I3_ROOTS: i32 = 18;      // I3 Subterranean Root Matrix
const BIOME_PURPLE_HOUSE: i32 = 19;  // Oblivion Purple House
const BIOME_SINGLETON: i32 = 20;     // The Singleton Paradox
const BIOME_ARCADE: i32 = 21;        // Neon Grid Arcade
const BIOME_TON618: i32 = 22;        // TON 618 Supermassive Abyss
const BIOME_SOLAR_SYSTEM: i32 = 23;  // Solar Corona & Planetary Orbits
const NUM_BIOMES: i32 = 24;

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
const BLK_MYSTERY_Q: u8 = 18;
const BLK_HAZARD_NUKE: u8 = 19;

// Shrinkable Fractal Portal Blocks (fly into or press SHRK to shrink 16x deeper!)
const BLK_BLACK_CUBE: u8 = 20;
const BLK_WHITE_FLOWER: u8 = 21;
const BLK_ALPHA_CUBE: u8 = 22;
const BLK_FLOWER_Y_CORE: u8 = 23;
const BLK_MYLANTIS_M: u8 = 24;
const BLK_YING_PLANET: u8 = 25;
const BLK_ICE_WORLD: u8 = 26;
const BLK_DESERT_WORLD: u8 = 27;
const BLK_CORE_GATE: u8 = 28;
const BLK_TOPAZ_CHECK: u8 = 29;
const BLK_INFINITY_RED: u8 = 30;
const BLK_TEXT_BLOCK: u8 = 31;

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
const BLK_UPGRADE_STATION: u8 = 45;
const BLK_QUICKSAND: u8 = 46;
const BLK_SOLAR_PLASMA: u8 = 47;
const BLK_LUNAR_REGOLITH: u8 = 48;
const BLK_CRYSTAL_CYAN: u8 = 49;
const BLK_CRYSTAL_PURPLE: u8 = 50;
const BLK_BOOKSHELF: u8 = 51;
const BLK_NEON_GRID: u8 = 52;
const BLK_EVENT_HORIZON: u8 = 53;
const BLK_BETA_TILE: u8 = 54;
const BLK_MYLANTIS_RED: u8 = 55;
const BLK_OBLIVION_BRICK: u8 = 56;
const BLK_ROOT_SOIL: u8 = 57;
const BLK_BOTANY_TANK: u8 = 58;
const BLK_ARCADE_CAB: u8 = 59;

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
const ENT_GUARDIAN: i32 = 13;   // Pool Ball / Guardian (freezable by Laser Cold Beam / EMP!)
const ENT_SINGULARITY: i32 = 14; // Core Boss

// Pickups, NPC & Special Rings
const ENT_GOLD: i32 = 15;
const ENT_HEALTH: i32 = 16;
const ENT_ARMOR: i32 = 17;
const ENT_AMMO: i32 = 18;
const ENT_KEY: i32 = 19;
const ENT_FRIEND_K: i32 = 20;
const ENT_RING_DANGER: i32 = 21;    // High-risk 256x danger dive ring
const ENT_MARKER_BEACON: i32 = 22;  // Visual beacon for Short Marker
const ENT_FLARE: i32 = 23;          // Active dynamic illumination flare
// Extended Monster Manual Enemies (Steam FBW)
const ENT_TWEEDLE: i32 = 24;
const ENT_GNAT: i32 = 25;
const ENT_BABY_SPIDER: i32 = 26;
const ENT_LAMPREY: i32 = 27;
const ENT_BURLY: i32 = 28;
const ENT_BEHOLDER: i32 = 29;
const ENT_SLIVER: i32 = 30;
const ENT_VULCAN: i32 = 31;
const ENT_GROWER: i32 = 32;
const ENT_SHRINKER: i32 = 33;
const ENT_ROCKET_SPIDER: i32 = 34;
const ENT_HYDRA: i32 = 35;
const ENT_TON618_BOSS: i32 = 36;
const ENT_HEX_SENTRY: i32 = 37;
const ENT_ARCADE_DRONE: i32 = 38;

// Audio SFX IDs (synthesized in main.c OpenSL ES sound bank)
const SFX_CLICK: i32 = 0;
const SFX_PLASMA: i32 = 1;
const SFX_LASER: i32 = 2;
const SFX_EXPLODE: i32 = 3;
const SFX_WARP: i32 = 4;
const SFX_PICKUP: i32 = 5;
const SFX_HURT: i32 = 6;
const SFX_EMP: i32 = 7;
const SFX_CANNON: i32 = 8;
const SFX_MINIGUN: i32 = 9;
const SFX_RAILGUN: i32 = 10;
const SFX_NUKE: i32 = 11;
const SFX_LEVEL_UP: i32 = 12;

const MAX_NEIGHBORS: i32 = 342; // ring-ordered sibling set (radius 3 = 7^3-1); Xar kilochunk-scale visibility
const MAX_CLEARED_CHUNKS: i32 = 256;

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
    poison_ms: i32,      // minigun poison duration (ms)
    poison_acc: i32,     // poison damage accumulator (dmg*ms)
    poison_dps: i32,     // poison damage per second
    target_biome: i32,
    target_block: u8,
    slot_id: i32,
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
    created_ms: i64,
}

root struct fbw_state {
    // Viewport & mode flags
    pw: i32,
    ph: i32,
    screen: i32,
    show_minimap: i32,
    genesis_mode: i32, // 1 = Peaceful Genesis Mode (no monsters)
    shrink_any: i32,   // 1 = Shrink into ANY touched block (Xar 'shrinkany')
    disable_lod: i32,  // 1 = Disable LOD optimization (load all on-screen interiors across all scales)
    lod_dist_level: i32, // 1..7 LOD distance slider level (default 4)
    view_chunk_radius: i32, // 1..3 sibling-chunk visibility radius (Xar kilochunk slider; default 2)

    // Unbounded recursive 16x16x16 world stack (-128..3000) + 10 sibling neighbor chunks
    blocks: u8[CHUNK_VOL],
    parent_blocks: u8[20480], // MAX_PARENT_VIS (5) * CHUNK_VOL
    scratch_blocks: u8[CHUNK_VOL],
    neighbor_blocks: u8[1400832], // MAX_NEIGHBORS (342) * CHUNK_VOL
    neighbor_valid: i32[342],
    neighbor_dx: i32[342],
    neighbor_dy: i32[342],
    neighbor_dz: i32[342],
    neighbor_biome: i32[342],
    neighbor_fill: i32[342],  // non-air block count per neighbor slot (sync culling)
    neighbor_dirty: i32[342], // slot needs GL re-push (streaming sync)
    neighbor_map: i32[343],   // 7x7x7 (dx,dy,dz in -3..3) -> slot or -1
    inward_blocks: u8[1048576], // 256-slot * CHUNK_VOL multi-layer 3D sub-voxel cache
    inward_seeds: u64[256],
    inward_blks: u8[256],
    inward_depths: i32[256],
    inward_used: i32[256],
    inward_next: i32,
    chunk_rev: i32,
    parent_bx: i32[5],
    parent_by: i32[5],
    parent_bz: i32[5],
    parent_biome: i32[5],
    parent_depth: i32[5],
    parent_seed: u64[5],
    parent_valid: i32[5],
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

    // Player stats, shields, trophies & economy
    hp: i32,
    max_hp: i32,
    hp_regen: i32,    // HP restored per 2 seconds
    regen_accum_ms: i32,
    shields: i32,
    max_shields: i32,
    shield_regen: i32,
    shield_accum_ms: i32,
    armor: i32,
    max_armor: i32,
    gold: i32,
    keys: i32,
    kills: i32,
    deaths: i32,
    score_xp: i32,
    trophies: i32,
    trophy_mask: i32,
    singularity_defeated: i32,
    quasar_drive: i32, // Unlocked by defeating The Singularity
    k_rescued: i32,
    telekinesis_ms: i32,
    black_hole_drive_ms: i32,
    quasar_drive_ms: i32,
    tome_read_mask: i32,

    // 10 Weapons, Firing Modes & Upgrade levels
    weapon: i32,
    wep_unlocked: i32[NUM_WEAPONS],
    ammo: i32[NUM_WEAPONS],
    max_ammo: i32[NUM_WEAPONS],
    wep_mode: i32[NUM_WEAPONS],
    wep_mode_max: i32[NUM_WEAPONS],
    dmg_lvl: i32,
    rof_lvl: i32,
    spd_lvl: i32,
    ammo_cap_lvl: i32,
    plasma_regen_ms: i32,
    fire_cd_ms: i32,
    ring_cd_ms: i32,
    spawner_timer_ms: i32,
    pending_sfx: i32,

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

    // Persistent cleared entity/pickup bitmasks per chunk seed
    cleared_seeds: u64[MAX_CLEARED_CHUNKS],
    cleared_masks: u32[MAX_CLEARED_CHUNKS],
    cleared_head: i32,

    // Simulation arrays
    entities: Entity[MAX_ENTITIES],
    shots: Shot[MAX_SHOTS],
    particles: Particle[MAX_PARTICLES],
    deltas: BlockDelta[MAX_DELTAS],
    delta_head: i32,

    // PRNG, DPS & Timing
    rng: u64,
    tick_ms: i64,
    play_ms: i64,
    dps_val: i32,
    dps_accum: i32,
    dps_timer_ms: i32,
    fps: i32,
    frame_cnt: i32,
    fps_last_ms: i64,
    anim_ms: i64,
    level: i32,          // player level (max 500); grants upgrades on level-up
    xp: i32,             // experience toward next level
    // Per-weapon upgrades & extra mechanics
    wep_dmg_lvl: i32[NUM_WEAPONS],
    wep_rof_lvl: i32[NUM_WEAPONS],
    wep_cap_lvl: i32[NUM_WEAPONS],
    wep_vel_lvl: i32[NUM_WEAPONS],
    plasma_regen_lvl: i32,
    emp_rad_lvl: i32,
    shield_cap_lvl: i32,
    enemy_kills: i32[40],
    icarus_mode: i32,
    mut_double_monsters: i32,
    mut_no_singleton: i32,
    mut_inf_markers: i32,
    show_chunk_grid: i32,
    hazard_cd_ms: i32,
    // Arcade cabinet minigame state
    arcade_score: i32,
    arcade_best: i32,
    arcade_timer_ms: i32,
    arcade_target: i32,
    arcade_hits: i32,
    arcade_active: i32,
    // Multi-hit destructible block HP ring buffer
    blk_hp_x: i32[32],
    blk_hp_y: i32[32],
    blk_hp_z: i32[32],
    blk_hp_val: i32[32],
    blk_hp_seed: u64[32],
    blk_hp_head: i32,
    autosave_dirty: i32, // set when progress/world state changes cleanly
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
    st.chunk_rev = st.chunk_rev + 1;
}

fn dst_set_block(dst_layer: i32, x: i32, y: i32, z: i32, b: u8) {
    if x < 0 || x >= CHUNK_DIM || y < 0 || y >= CHUNK_DIM || z < 0 || z >= CHUNK_DIM {
        return;
    }
    let idx = b_idx(x, y, z);
    if dst_layer < 0 {
        st.blocks[idx] = b;
    } else if dst_layer == 5 {
        st.scratch_blocks[idx] = b;
    } else if dst_layer >= 1000 {
        let nb = dst_layer - 1000;
        if nb >= 0 && nb < MAX_NEIGHBORS {
            st.neighbor_blocks[nb * CHUNK_VOL + idx] = b;
            if b != BLK_AIR { st.neighbor_fill[nb] = st.neighbor_fill[nb] + 1; }
        }
    } else if dst_layer >= 10 {
        let slot = dst_layer - 10;
        if slot >= 0 && slot < 256 {
            st.inward_blocks[slot * CHUNK_VOL + idx] = b;
        }
    } else if dst_layer >= 0 && dst_layer < 5 {
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
    } else if dst_layer == 5 {
        return st.scratch_blocks[idx];
    } else if dst_layer >= 1000 {
        let nb = dst_layer - 1000;
        if nb >= 0 && nb < MAX_NEIGHBORS {
            return st.neighbor_blocks[nb * CHUNK_VOL + idx];
        }
        return BLK_AIR;
    } else if dst_layer >= 10 {
        let slot = dst_layer - 10;
        if slot >= 0 && slot < 256 {
            return st.inward_blocks[slot * CHUNK_VOL + idx];
        }
        return BLK_AIR;
    } else if dst_layer >= 0 && dst_layer < 5 {
        return st.parent_blocks[dst_layer * CHUNK_VOL + idx];
    }
    return BLK_AIR;
}

fn queue_sfx(kind: i32) {
    if kind > st.pending_sfx {
        st.pending_sfx = kind;
    }
}

fn award_trophy_id(tid: i32, msg: const u8[:]) {
    if tid < 0 || tid >= 32 { return; }
    let mask_u: u32 = st.trophy_mask as! u32;
    let bit_u: u32 = (1 as! u32) << (tid as! u32);
    if (mask_u & bit_u) != 0 { return; }
    st.trophy_mask = (mask_u | bit_u) as! i32;
    st.trophies = st.trophies + 1;
    st.score_xp = st.score_xp + 250;
    st.autosave_dirty = 1;
    queue_sfx(SFX_PICKUP);
    set_status_msg(msg, 3200);
}

fn award_trophy(bit: i32, msg: const u8[:]) {
    var tid: i32 = 0;
    var v: u32 = bit as! u32;
    while v > 1 && tid < 31 {
        v = v >> 1;
        tid = tid + 1;
    }
    award_trophy_id(tid, msg);
}

fn is_enemy_kind(k: i32) -> i32 {
    if (k >= ENT_RAT && k <= ENT_SINGULARITY) || (k >= ENT_TWEEDLE && k <= ENT_ARCADE_DRONE) {
        return 1;
    }
    return 0;
}

fn is_enemy_freeze_immune(k: i32) -> i32 {
    if k == ENT_SLIVER || k == ENT_VULCAN || k == ENT_HEX_SENTRY || k == ENT_TON618_BOSS {
        return 1;
    }
    return 0;
}

fn is_enemy_mystical(k: i32) -> i32 {
    if k == ENT_BEHOLDER || k == ENT_HYDRA || k == ENT_TON618_BOSS {
        return 1;
    }
    return 0;
}

fn is_entity_cleared(seed: u64, slot_id: i32) -> i32 {
    if slot_id < 0 || slot_id >= 32 { return 0; }
    let bit: u32 = (1 as! u32) << (slot_id as! u32);
    var i: i32 = 0;
    while i < MAX_CLEARED_CHUNKS {
        if st.cleared_seeds[i] == seed {
            return if (st.cleared_masks[i] & bit) != 0 { 1 } else { 0 };
        }
        i = i + 1;
    }
    return 0;
}

fn mark_entity_cleared(seed: u64, slot_id: i32) {
    if slot_id < 0 || slot_id >= 32 { return; }
    let bit: u32 = (1 as! u32) << (slot_id as! u32);
    st.autosave_dirty = 1;
    var i: i32 = 0;
    while i < MAX_CLEARED_CHUNKS {
        if st.cleared_seeds[i] == seed {
            st.cleared_masks[i] = st.cleared_masks[i] | bit;
            return;
        }
        i = i + 1;
    }
    let idx = st.cleared_head;
    st.cleared_seeds[idx] = seed;
    st.cleared_masks[idx] = bit;
    st.cleared_head = (idx + 1) % MAX_CLEARED_CHUNKS;
}

fn get_parent_block(layer: i32, x: i32, y: i32, z: i32) -> u8 {
    if layer < 0 || layer >= 5 { return BLK_AIR; }
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
    st.chunk_rev = st.chunk_rev + 1;
    st.autosave_dirty = 1;
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
       b == BLK_ICE_WORLD || b == BLK_DESERT_WORLD || b == BLK_CORE_GATE ||
       b == BLK_INFINITY_RED {
        return 1;
    }
    return 0;
}

fn is_block_subdivisible(b: u8) -> i32 {
    if is_block_shrinkable(b) != 0 { return 1; }
    if b == BLK_WALL_TUT || b == BLK_GRASS || b == BLK_DIRT || b == BLK_WOOD ||
       b == BLK_LEAVES || b == BLK_PETAL_Y || b == BLK_POLLEN || b == BLK_PETAL_W ||
       b == BLK_MYLANTIS || b == BLK_ICE || b == BLK_SAND || b == BLK_GLASS ||
       b == BLK_STONE || b == BLK_GOLD_ORE || b == BLK_CRATE || b == BLK_SPAWNER ||
       b == BLK_LOCKED_DOOR || b == BLK_MYSTERY_Q || b == BLK_HAZARD_NUKE ||
       b == BLK_TOPAZ_CHECK || b == BLK_BUY_STATION || b == BLK_SELL_STATION ||
       b == BLK_BLACK_MARKET || b == BLK_UPGRADE_STATION || b == BLK_TOME || b == BLK_TEXT_BLOCK ||
       (b >= BLK_QUICKSAND && b <= BLK_ARCADE_CAB) {
        return 1;
    }
    return 0;
}

fn is_block_molecular(b: u8) -> i32 {
    if b == BLK_STONE || b == BLK_DIRT || b == BLK_GOLD_ORE ||
       b == BLK_CRATE || b == BLK_LOCKED_DOOR || b == BLK_SPAWNER ||
       b == BLK_HAZARD_NUKE || b == BLK_TOPAZ_CHECK ||
       b == BLK_LUNAR_REGOLITH || b == BLK_MYLANTIS_RED ||
       b == BLK_OBLIVION_BRICK || b == BLK_ROOT_SOIL {
        return 1;
    }
    return 0;
}

fn is_block_upgrade(b: u8) -> i32 {
    if b >= BLK_UPG_HP && b <= BLK_UPG_WEP { return 1; }
    return 0;
}

fn is_block_destructible(b: u8) -> i32 {
    if b == BLK_CRATE || b == BLK_SPAWNER || b == BLK_GOLD_ORE ||
       b == BLK_MYSTERY_Q || b == BLK_HAZARD_NUKE || b == BLK_TOPAZ_CHECK ||
       b == BLK_CRYSTAL_CYAN || b == BLK_CRYSTAL_PURPLE {
        return 1;
    }
    return 0;
}

fn is_block_hazard(b: u8) -> i32 {
    if b == BLK_QUICKSAND || b == BLK_SOLAR_PLASMA || b == BLK_EVENT_HORIZON { return 1; }
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
    if biome == BIOME_ICE_WORLD { return "Glacial Spire"; }
    if biome == BIOME_DESERT_WORLD { return "Desert Pyramid"; }
    if biome == BIOME_NOOB_FLOWER { return "Noob Flower"; }
    if biome == BIOME_YING_LIBRARY { return "Ying Library"; }
    if biome == BIOME_BOTANY_LAB { return "Botany Lab"; }
    if biome == BIOME_BETA_CUBE { return "Beta Cube"; }
    if biome == BIOME_RED_CAVES { return "Red Caves"; }
    if biome == BIOME_I1_LIGHTHOUSE { return "I1 Lighthouse"; }
    if biome == BIOME_I2_MOUNTAINS { return "I2 Mountains"; }
    if biome == BIOME_BURLINGTON { return "Burlington"; }
    if biome == BIOME_I3_ROOTS { return "I3 Root Matrix"; }
    if biome == BIOME_PURPLE_HOUSE { return "Purple House"; }
    if biome == BIOME_SINGLETON { return "The Singleton"; }
    if biome == BIOME_ARCADE { return "Neon Arcade"; }
    if biome == BIOME_TON618 { return "TON 618 Abyss"; }
    if biome == BIOME_SOLAR_SYSTEM { return "Solar System"; }
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

fn weapon_mode_name(w: i32, m: i32) -> const u8[:] {
    if w == WEP_PLASMA {
        if m == 1 { return "Rapid 8x"; }
        if m == 2 { return "Shotgun 20x"; }
        if m == 3 { return "Hyper Rapid"; }
        if m == 4 { return "Lightning Rifle"; }
        if m == 5 { return "Flare"; }
        return "High-DPA";
    }
    if w == WEP_CANNON {
        if m == 1 { return "Blunderbuss"; }
        if m == 2 { return "Tommy Gun"; }
        if m == 3 { return "The Sheriff"; }
        if m == 4 { return "The Judge"; }
        return "Chaining Ball";
    }
    if w == WEP_LASER {
        if m == 1 { return "Cold Beam"; }
        if m == 2 { return "Freeze Ray"; }
        if m == 3 { return "Laser Disco"; }
        return "Ice Laser";
    }
    if w == WEP_ROCKET {
        if m == 1 { return "Hi-Velocity"; }
        if m == 2 { return "Big Radius"; }
        if m == 3 { return "Kinetic"; }
        if m == 4 { return "Progressive"; }
        return "Basic";
    }
    if w == WEP_HOMING {
        if m == 1 { return "Swarm 20x"; }
        return "Seeker";
    }
    if w == WEP_MINIGUN {
        if m == 1 { return "Poison Dart"; }
        return "Standard";
    }
    if w == WEP_RAILGUN {
        if m == 1 { return "Rapid"; }
        if m == 2 { return "Vampire"; }
        if m == 3 { return "Super Vampire"; }
        return "Classic";
    }
    if w == WEP_EMP {
        if m == 1 { return "Shockwave"; }
        return "Stun Pulse";
    }
    if w == WEP_NUKE {
        if m == 1 { return "Hi-Vel 2xRad"; }
        if m == 2 { return "Pulse Drive"; }
        return "High Damage";
    }
    if m == 1 { return "Exchange HP"; }
    if m == 2 { return "BH Drive"; }
    if m == 3 { return "Quasar Drive"; }
    return "Singularity";
}

fn block_label(b: u8) -> const u8[:] {
    if is_block_shrinkable(b) != 0 {
        return "Fractal World Block (SHRK & fly into 3D hole)";
    }
    if b == BLK_MYSTERY_Q { return "Mystery [?] Pillar (Shoot or USE)"; }
    if b == BLK_HAZARD_NUKE { return "Nuke Hazard Crate (Break for Ammo)"; }
    if b == BLK_TOPAZ_CHECK { return "Topaz Mineral Vein (Break for Gold)"; }
    if b == BLK_TEXT_BLOCK { return "Floating TEXT Log [USE]"; }
    if b == BLK_UPG_WEP { return "Weapon Arsenal Module"; }
    if b == BLK_BUY_STATION { return "Buy Station [USE]"; }
    if b == BLK_SELL_STATION { return "Sell Station [USE]"; }
    if b == BLK_BLACK_MARKET { return "Black Market [USE]"; }
    if b == BLK_UPGRADE_STATION { return "Upgrade Station [USE]"; }
    if b == BLK_TOME { return "Xar Manual Tome [USE]"; }
    if b == BLK_LOCKED_DOOR { return "Locked Vault Door [USE: Key]"; }
    if b == BLK_ARCADE_CAB { return "Neon Arcade Cabinet [USE]"; }
    if b == BLK_QUICKSAND { return "Quicksand Trap (Slows & Damages!)"; }
    if b == BLK_SOLAR_PLASMA { return "Solar Corona Plasma (Hazardous Heat!)"; }
    if b == BLK_EVENT_HORIZON { return "TON 618 Event Horizon (Singularity Pull!)"; }
    if b == BLK_CRYSTAL_CYAN { return "Cyan Crystal Cluster (Mineable)"; }
    if b == BLK_CRYSTAL_PURPLE { return "Amethyst Crystal (Mineable)"; }
    if b == BLK_BOOKSHELF { return "Ying Library Archive Shelf"; }
    if b == BLK_BOTANY_TANK { return "Botanical Specimen Vat"; }
    if st.shrink_any != 0 { return "Solid Block (ShrinkAny ON: Fly/SHRK)"; }
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
    if b == BLK_MYSTERY_Q { return pack_rgb(238, 246, 255); }
    if b == BLK_HAZARD_NUKE { return pack_rgb(248, 208, 32); }
    if b == BLK_BLACK_CUBE { return pack_rgb(112, 118, 128); }
    if b == BLK_WHITE_FLOWER { return pack_rgb(248, 250, 255); }
    if b == BLK_ALPHA_CUBE { return pack_rgb(236, 72, 153); }
    if b == BLK_FLOWER_Y_CORE { return pack_rgb(255, 214, 48); }
    if b == BLK_MYLANTIS_M { return pack_rgb(249, 115, 22); }
    if b == BLK_YING_PLANET { return pack_rgb(52, 211, 102); }
    if b == BLK_ICE_WORLD { return pack_rgb(96, 218, 255); }
    if b == BLK_DESERT_WORLD { return pack_rgb(234, 179, 82); }
    if b == BLK_CORE_GATE { return pack_rgb(244, 63, 184); }
    if b == BLK_TOPAZ_CHECK { return pack_rgb(38, 208, 202); }
    if b == BLK_INFINITY_RED { return pack_rgb(218, 38, 48); }
    if b == BLK_TEXT_BLOCK { return pack_rgb(64, 224, 255); }
    if b == BLK_BUY_STATION { return pack_rgb(34, 197, 94); }
    if b == BLK_SELL_STATION { return pack_rgb(56, 189, 248); }
    if b == BLK_BLACK_MARKET { return pack_rgb(147, 51, 234); }
    if b == BLK_UPGRADE_STATION { return pack_rgb(255, 140, 40); }
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
    if b == BLK_QUICKSAND { return pack_rgb(206, 172, 92); }
    if b == BLK_SOLAR_PLASMA { return pack_rgb(255, 132, 28); }
    if b == BLK_LUNAR_REGOLITH { return pack_rgb(154, 162, 178); }
    if b == BLK_CRYSTAL_CYAN { return pack_rgb(56, 240, 255); }
    if b == BLK_CRYSTAL_PURPLE { return pack_rgb(192, 92, 255); }
    if b == BLK_BOOKSHELF { return pack_rgb(156, 98, 54); }
    if b == BLK_NEON_GRID { return pack_rgb(24, 244, 198); }
    if b == BLK_EVENT_HORIZON { return pack_rgb(36, 12, 62); }
    if b == BLK_BETA_TILE { return pack_rgb(84, 152, 248); }
    if b == BLK_MYLANTIS_RED { return pack_rgb(204, 46, 58); }
    if b == BLK_OBLIVION_BRICK { return pack_rgb(108, 42, 168); }
    if b == BLK_ROOT_SOIL { return pack_rgb(88, 62, 42); }
    if b == BLK_BOTANY_TANK { return pack_rgb(52, 224, 168); }
    if b == BLK_ARCADE_CAB { return pack_rgb(255, 72, 212); }
    return pack_rgb(128, 128, 140);
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
        st.entities[i].slot_id = -1;
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

fn spawn_entity_ex(kind: i32, x: f64, y: f64, z: f64, hp: i32, target_biome: i32, target_blk: u8, slot_id: i32) -> i32 {
    if slot_id >= 0 && is_entity_cleared(cur_seed(), slot_id) != 0 {
        return -1;
    }
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
            st.entities[i].poison_ms = 0;
            st.entities[i].poison_acc = 0;
            st.entities[i].poison_dps = 0;
            st.entities[i].target_biome = target_biome;
            st.entities[i].target_block = target_blk;
            st.entities[i].slot_id = slot_id;
            return i;
        }
        i = i + 1;
    }
    return -1;
}

fn spawn_entity(kind: i32, x: f64, y: f64, z: f64, hp: i32, target_biome: i32, target_blk: u8) -> i32 {
    return spawn_entity_ex(kind, x, y, z, hp, target_biome, target_blk, -1);
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

fn xp_to_next(lvl: i32) -> i32 {
    return 100 + (lvl - 1) * 40;
}

// Authentic XP flow: kills grant XP; each level (up to 500) grants +1 damage
// upgrade for every weapon, +1 max health upgrade and +1 health regen upgrade.
fn award_xp(amount: i32) {
    if amount <= 0 { return; }
    st.score_xp = st.score_xp + amount;
    st.xp = st.xp + amount;
    while st.level < 500 && st.xp >= xp_to_next(st.level) {
        st.xp = st.xp - xp_to_next(st.level);
        st.level = st.level + 1;
        st.dmg_lvl = st.dmg_lvl + 1;
        st.max_hp = st.max_hp + 20;
        st.hp_regen = st.hp_regen + 1;
        refresh_derived();
        st.hp = st.max_hp;
        st.shields = st.max_shields;
        st.autosave_dirty = 1;
        queue_sfx(SFX_LEVEL_UP);
        set_status_msg("LEVEL UP! +1 Dmg (all weapons), +20 MaxHP, +1 Regen", 2400);
    }
    if st.level >= 500 { st.xp = 0; }
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
    if parent_blk == BLK_CORE_GATE {
        let cr = (splitmix64(seed) % 3) as! i32;
        if cr == 1 { return BIOME_TON618; }
        if cr == 2 && st.mut_no_singleton == 0 { return BIOME_SINGLETON; }
        return BIOME_INNER_CORE;
    }
    if parent_blk == BLK_WHITE_FLOWER {
        if (splitmix64(seed) % 3) == 0 { return BIOME_NOOB_FLOWER; }
        return BIOME_WHITE_FLOWER;
    }
    if parent_blk == BLK_ALPHA_CUBE {
        if (splitmix64(seed) % 2) == 0 { return BIOME_BETA_CUBE; }
        return BIOME_WHITE_FLOWER;
    }
    if parent_blk == BLK_FLOWER_Y_CORE { return BIOME_YELLOW_FLOWER; }
    if parent_blk == BLK_YING_PLANET {
        let yr = (splitmix64(seed) % 4) as! i32;
        if yr == 1 { return BIOME_YING_LIBRARY; }
        if yr == 2 { return BIOME_BOTANY_LAB; }
        return BIOME_YING_FOREST;
    }
    if parent_blk == BLK_MYLANTIS_M {
        if (splitmix64(seed) % 3) == 0 { return BIOME_RED_CAVES; }
        return BIOME_MYLANTIS;
    }
    if parent_blk == BLK_ICE_WORLD {
        if (splitmix64(seed) % 2) == 0 { return BIOME_I1_LIGHTHOUSE; }
        return BIOME_ICE_WORLD;
    }
    if parent_blk == BLK_DESERT_WORLD {
        if (splitmix64(seed) % 2) == 0 { return BIOME_BURLINGTON; }
        return BIOME_DESERT_WORLD;
    }
    if parent_blk == BLK_INFINITY_RED {
        let ir = (splitmix64(seed) % 4) as! i32;
        if ir == 0 { return BIOME_I2_MOUNTAINS; }
        if ir == 1 { return BIOME_I3_ROOTS; }
        if ir == 2 { return BIOME_ARCADE; }
        return BIOME_SOLAR_SYSTEM;
    }
    if parent_blk == BLK_BLACK_CUBE {
        if depth == 1 { return BIOME_YING_FOREST; }
        if (splitmix64(seed) % 4) == 0 { return BIOME_PURPLE_HOUSE; }
        return BIOME_BLACK_CUBE;
    }
    if depth == 1 { return BIOME_YING_FOREST; }
    let r = (splitmix64(seed) % 19) as! i32;
    if r == 0 { return BIOME_YING_FOREST; }
    if r == 1 { return BIOME_YELLOW_FLOWER; }
    if r == 2 { return BIOME_MYLANTIS; }
    if r == 3 { return BIOME_ICE_WORLD; }
    if r == 4 { return BIOME_DESERT_WORLD; }
    if r == 5 { return BIOME_NOOB_FLOWER; }
    if r == 6 { return BIOME_YING_LIBRARY; }
    if r == 7 { return BIOME_BOTANY_LAB; }
    if r == 8 { return BIOME_BETA_CUBE; }
    if r == 9 { return BIOME_RED_CAVES; }
    if r == 10 { return BIOME_I1_LIGHTHOUSE; }
    if r == 11 { return BIOME_I2_MOUNTAINS; }
    if r == 12 { return BIOME_BURLINGTON; }
    if r == 13 { return BIOME_I3_ROOTS; }
    if r == 14 { return BIOME_PURPLE_HOUSE; }
    if r == 15 && st.mut_no_singleton == 0 { return BIOME_SINGLETON; }
    if r == 16 { return BIOME_ARCADE; }
    if r == 17 { return BIOME_SOLAR_SYSTEM; }
    return BIOME_BLACK_CUBE;
}

fn resolve_child_frame_seed(parent_seed: u64, parent_depth: i32, bx: i32, by: i32, bz: i32, blk: u8) -> u64 {
    if parent_depth == -1 && bx == 8 && by == 7 && bz == 8 && blk == BLK_YING_PLANET {
        return 0x5841525f54555430;
    }
    return hash_block_seed(parent_seed, bx, by, bz, parent_depth + 1);
}

fn resolve_child_frame_biome(
    parent_seed: u64, parent_depth: i32, parent_biome: i32,
    bx: i32, by: i32, bz: i32, blk: u8, forced_biome: i32
) -> i32 {
    if forced_biome >= 0 { return forced_biome; }
    if parent_depth == -1 && bx == 8 && by == 7 && bz == 8 && blk == BLK_YING_PLANET {
        return BIOME_TUTORIAL;
    }
    let cseed = resolve_child_frame_seed(parent_seed, parent_depth, bx, by, bz, blk);
    return pick_biome_for_entry(parent_depth + 1, blk, -1, cseed, parent_biome);
}

fn dst_fill_box(dst: i32, x0: i32, y0: i32, z0: i32, x1: i32, y1: i32, z1: i32, blk: u8) {
    var y: i32 = y0;
    while y <= y1 {
        var z: i32 = z0;
        while z <= z1 {
            var x: i32 = x0;
            while x <= x1 {
                dst_set_block(dst, x, y, z, blk);
                x = x + 1;
            }
            z = z + 1;
        }
        y = y + 1;
    }
}

fn build_ying_tree_to(dst: i32, tx: i32, tz: i32, base_y: i32, h: i32, has_fruit: i32) {
    var y: i32 = 0;
    while y < h {
        dst_set_block(dst, tx, base_y + y, tz, if y == 1 && has_fruit != 0 { BLK_INFINITY_RED } else { BLK_WOOD });
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

fn build_colossal_ying_tree_to(dst: i32, tx: i32, tz: i32, base_y: i32, h: i32) {
    var y: i32 = 0;
    while y < h {
        dst_set_block(dst, tx, base_y + y, tz, BLK_WOOD);
        dst_set_block(dst, tx + 1, base_y + y, tz, BLK_WOOD);
        dst_set_block(dst, tx, base_y + y, tz + 1, BLK_WOOD);
        dst_set_block(dst, tx + 1, base_y + y, tz + 1, BLK_WOOD);
        if (y % 3) == 1 {
            dst_set_block(dst, tx, base_y + y, tz, BLK_INFINITY_RED);
        }
        y = y + 1;
    }
    let cy = base_y + h;
    var dy: i32 = -1;
    while dy <= 2 {
        let rad: i32 = if dy == 2 { 1 } else if dy == 1 { 2 } else { 3 };
        var dz: i32 = -rad;
        while dz <= rad + 1 {
            var dx: i32 = -rad;
            while dx <= rad + 1 {
                let cx2 = dx * 2 - 1;
                let cz2 = dz * 2 - 1;
                let r2 = cx2 * cx2 + cz2 * cz2;
                if r2 <= (rad * 2 + 1) * (rad * 2 + 1) {
                    if dy == 0 && dx == 0 && dz == 0 {
                        dst_set_block(dst, tx, cy, tz, BLK_FLOWER_Y_CORE);
                    } else if dy == 0 && dx == 1 && dz == 1 {
                        dst_set_block(dst, tx + 1, cy, tz + 1, BLK_WHITE_FLOWER);
                    } else {
                        dst_set_block(dst, tx + dx, cy + dy, tz + dz, BLK_LEAVES);
                    }
                }
                dx = dx + 1;
            }
            dz = dz + 1;
        }
        dy = dy + 1;
    }
}

fn generate_space_blocks(dst: i32) {
    // 1. Ying World Planetoid (stepped green/emerald world sphere; (8,7,8) holds Tutorial Island!)
    var dy: i32 = -2;
    while dy <= 1 {
        var dz: i32 = -2;
        while dz <= 2 {
            var dx: i32 = -2;
            while dx <= 2 {
                let r2 = dx * dx + dy * dy + dz * dz;
                if r2 <= 5 {
                    let bx = 8 + dx;
                    let by = 6 + dy;
                    let bz = 8 + dz;
                    if bx == 8 && by == 7 && bz == 8 {
                        dst_set_block(dst, bx, by, bz, BLK_YING_PLANET);
                    } else if dy == 1 && (dx != 0 || dz != 0) {
                        if ((dx + dz) & 1) == 0 { dst_set_block(dst, bx, by, bz, BLK_LEAVES); }
                    } else if r2 == 5 && dy == -1 {
                        dst_set_block(dst, bx, by, bz, BLK_LEAVES);
                    } else {
                        dst_set_block(dst, bx, by, bz, BLK_YING_PLANET);
                    }
                }
                dx = dx + 1;
            }
            dz = dz + 1;
        }
        dy = dy + 1;
    }
    dst_set_block(dst, 8, 7, 8, BLK_YING_PLANET);
    dst_set_block(dst, 6, 6, 8, BLK_WHITE_FLOWER);
    dst_set_block(dst, 10, 6, 8, BLK_FLOWER_Y_CORE);

    // 2. Iconic Giant Orange Mylantis 'M' Citadel in Outer Space (Blue Ring sits at 13.5, 10.2, 12.5)
    dst_fill_box(dst, 12, 6, 12, 12, 9, 13, BLK_MYLANTIS_M);
    dst_fill_box(dst, 15, 6, 12, 15, 9, 13, BLK_MYLANTIS_M);
    dst_set_block(dst, 13, 8, 12, BLK_MYLANTIS_M);
    dst_set_block(dst, 14, 8, 12, BLK_MYLANTIS_M);
    dst_set_block(dst, 13, 9, 12, BLK_MYLANTIS_M);
    dst_set_block(dst, 14, 9, 12, BLK_MYLANTIS_M);
    dst_set_block(dst, 13, 7, 12, BLK_TOPAZ_CHECK);
    dst_set_block(dst, 14, 7, 12, BLK_TOPAZ_CHECK);

    // 3. Glacial Spire World Planetoid (crystalline blue ice cluster)
    dst_fill_box(dst, 2, 8, 11, 4, 9, 13, BLK_ICE);
    dst_set_block(dst, 3, 9, 12, BLK_ICE_WORLD);
    dst_set_block(dst, 3, 9, 13, BLK_ICE_WORLD);
    dst_set_block(dst, 3, 10, 12, BLK_ICE_WORLD);
    dst_set_block(dst, 2, 10, 11, BLK_GLASS);
    dst_set_block(dst, 4, 10, 13, BLK_GLASS);
    dst_set_block(dst, 3, 11, 12, BLK_GLASS);

    // 4. Desert Pyramid World Planetoid (stepped golden sandstone pyramid)
    dst_fill_box(dst, 2, 3, 3, 4, 3, 5, BLK_SAND);
    dst_set_block(dst, 3, 4, 4, BLK_DESERT_WORLD);
    dst_set_block(dst, 4, 4, 4, BLK_DESERT_WORLD);
    dst_set_block(dst, 2, 4, 4, BLK_GOLD_ORE);
    dst_set_block(dst, 3, 5, 4, BLK_DESERT_WORLD);

    // 5. Cosmic Black Cube (3x3x3 hollow Menger lattice frame)
    var cy: i32 = 3;
    while cy <= 5 {
        var cz: i32 = 3;
        while cz <= 5 {
            var cx: i32 = 11;
            while cx <= 13 {
                let mid = (if cx == 12 { 1 } else { 0 }) + (if cy == 4 { 1 } else { 0 }) + (if cz == 4 { 1 } else { 0 });
                if mid < 2 {
                    dst_set_block(dst, cx, cy, cz, BLK_BLACK_CUBE);
                }
                cx = cx + 1;
            }
            cz = cz + 1;
        }
        cy = cy + 1;
    }
    dst_set_block(dst, 12, 4, 4, BLK_BLACK_CUBE);
    dst_set_block(dst, 12, 5, 4, BLK_BLACK_CUBE);
    dst_set_block(dst, 12, 3, 4, BLK_CORE_GATE);

    // 6. Cosmic Asteroids & Alpha Relic
    dst_set_block(dst, 2, 13, 2, BLK_ALPHA_CUBE);
    dst_set_block(dst, 3, 13, 2, BLK_GOLD_ORE);
    dst_set_block(dst, 14, 2, 14, BLK_INFINITY_RED);
    dst_set_block(dst, 2, 2, 13, BLK_TOPAZ_CHECK);
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
    // 1. Open Terraced Tutorial Island base (y=0 dirt, y=1 grass) + corner glacial pond & shore steps
    var z: i32 = 0;
    while z < CHUNK_DIM {
        var x: i32 = 0;
        while x < CHUNK_DIM {
            dst_set_block(dst, x, 0, z, BLK_DIRT);
            let is_pond = if x >= 1 && x <= 3 && z >= 12 && z <= 14 { 1 } else { 0 };
            dst_set_block(dst, x, 1, z, if is_pond != 0 { BLK_ICE } else { BLK_GRASS });
            x = x + 1;
        }
        z = z + 1;
    }

    // Grassy outer rim terraces (clear of doorway & flowers)
    dst_fill_box(dst, 0, 2, 0, 1, 2, 3, BLK_GRASS);
    dst_fill_box(dst, 14, 2, 12, 15, 2, 15, BLK_GRASS);
    dst_set_block(dst, 0, 3, 0, BLK_LEAVES);
    dst_set_block(dst, 15, 3, 15, BLK_LEAVES);

    // 2. Iconic Tutorial Hall (x=4..12, y=2..7, z=2..12) with 2-voxel walls, wide east doorway, north/west/south arches & skylight
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
                           (rz <= 3 && rx >= 7 && rx <= 9 && ry >= 2 && ry <= 4) ||
                           (rz >= 11 && rx >= 7 && rx <= 9 && ry >= 3 && ry <= 5) { 1 } else { 0 };
                    let is_sky = if ry >= 6 && rx >= 7 && rx <= 9 && rz >= 5 && rz <= 9 { 1 } else { 0 };
                    if is_door == 0 && is_win == 0 && is_sky == 0 {
                        let trim = if ry == 7 && (rx == 4 || rx == 12) && (rz == 2 || rz == 12) { 1 } else { 0 };
                        dst_set_block(dst, rx, ry, rz, if trim != 0 { BLK_GOLD_ORE } else { BLK_WALL_TUT });
                    }
                }
                rx = rx + 1;
            }
            rz = rz + 1;
        }
        ry = ry + 1;
    }

    // Embedded 2-level micro-hole alcoves inside Tutorial Hall walls
    dst_set_block(dst, 5, 3, 4, BLK_AIR);
    dst_set_block(dst, 4, 3, 4, BLK_ALPHA_CUBE);
    dst_set_block(dst, 11, 3, 10, BLK_AIR);
    dst_set_block(dst, 12, 3, 10, BLK_BLACK_CUBE);
    dst_set_block(dst, 12, 4, 10, BLK_GOLD_ORE);

    // 3. Inside Tutorial Hall (spawn at 8.5, 3.2, 5.2 facing +Z toward Black Cube at (8, 2..3, 9))
    dst_set_block(dst, 8, 2, 9, BLK_BLACK_CUBE);
    dst_set_block(dst, 8, 3, 9, BLK_BLACK_CUBE);
    dst_set_block(dst, 6, 2, 7, BLK_TOME);
    dst_set_block(dst, 10, 2, 7, BLK_BUY_STATION);
    dst_set_block(dst, 10, 2, 5, BLK_UPGRADE_STATION);
    dst_set_block(dst, 6, 2, 9, BLK_CRATE);

    // 4. Sculpted 3D Small White Flower Garden (east of hall, keeping (13.5, 5.2, 8.5) clear for Green Ring!)
    dst_set_block(dst, 13, 2, 9, BLK_WOOD);
    dst_set_block(dst, 13, 3, 9, BLK_POLLEN);
    dst_set_block(dst, 12, 3, 9, BLK_PETAL_W);
    dst_set_block(dst, 14, 3, 9, BLK_PETAL_W);
    dst_set_block(dst, 13, 3, 8, BLK_PETAL_W);
    dst_set_block(dst, 13, 3, 10, BLK_PETAL_W);
    dst_set_block(dst, 13, 4, 9, BLK_WHITE_FLOWER);

    // 5. Sculpted 3D Small Yellow Flower & Ying Sapling (west courtyard)
    dst_set_block(dst, 2, 2, 10, BLK_WOOD);
    dst_set_block(dst, 2, 3, 10, BLK_POLLEN);
    dst_set_block(dst, 1, 3, 10, BLK_PETAL_Y);
    dst_set_block(dst, 3, 3, 10, BLK_PETAL_Y);
    dst_set_block(dst, 2, 3, 9, BLK_PETAL_Y);
    dst_set_block(dst, 2, 3, 11, BLK_PETAL_Y);
    dst_set_block(dst, 2, 4, 10, BLK_FLOWER_Y_CORE);

    // 6. Watchtower & Courtyard Landmarks
    dst_set_block(dst, 2, 2, 2, BLK_STONE);
    dst_set_block(dst, 2, 3, 2, BLK_WALL_TUT);
    dst_set_block(dst, 2, 4, 2, BLK_STONE);
    dst_set_block(dst, 2, 5, 2, BLK_UPG_HP);
    dst_set_block(dst, 2, 2, 4, BLK_MYSTERY_Q);
    dst_set_block(dst, 2, 3, 4, BLK_MYSTERY_Q);
    dst_set_block(dst, 2, 2, 7, BLK_HAZARD_NUKE);

    // South Observation Deck & Sell/Mining Practice
    dst_set_block(dst, 11, 2, 14, BLK_PETAL_Y);
    dst_set_block(dst, 11, 3, 14, BLK_TEXT_BLOCK);
    dst_set_block(dst, 14, 2, 2, BLK_SELL_STATION);
    dst_set_block(dst, 13, 2, 13, BLK_TOPAZ_CHECK);
    dst_set_block(dst, 14, 2, 13, BLK_GOLD_ORE);
}

fn populate_tutorial_entities() {
    let _ = spawn_entity(ENT_RING_GREEN, 9.5, 3.2, 6.2, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_GREEN, 13.5, 5.2, 8.5, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_RED, 8.5, 11.5, 7.5, 1, BIOME_SPACE, BLK_AIR);
    let _ = spawn_entity(ENT_RING_DANGER, 14.2, 4.5, 14.2, 1, BIOME_BLACK_CUBE, BLK_BLACK_CUBE);
    let _ = spawn_entity_ex(ENT_GOLD, 8.5, 2.5, 6.5, 1, -1, 0, 0);
}

fn generate_ying_forest_blocks(dst: i32, seed: u64) {
    var ls = splitmix64(seed ^ 0x59494e47);
    let arch = (ls % 4) as! i32;

    // Seamless open-horizon meadow floor across all 16x16 edges + soft undulating corner hillocks
    var z: i32 = 0;
    while z < CHUNK_DIM {
        var x: i32 = 0;
        while x < CHUNK_DIM {
            dst_set_block(dst, x, 0, z, BLK_DIRT);
            var floor_blk: u8 = BLK_GRASS;
            if arch == 1 && x >= 5 && x <= 9 && z >= 11 && z <= 14 {
                floor_blk = BLK_ICE;
            } else if arch == 0 && x >= 2 && x <= 4 && z >= 11 && z <= 13 {
                floor_blk = BLK_ICE;
            } else if arch == 2 && x >= 2 && x <= 4 && z >= 11 && z <= 13 {
                floor_blk = if ((x + z) & 1) == 0 { BLK_TOPAZ_CHECK } else { BLK_STONE };
            }
            dst_set_block(dst, x, 1, z, floor_blk);

            let is_corner = if (x <= 1 || x >= 14) && (z <= 1 || z >= 14) { 1 } else { 0 };
            if is_corner != 0 {
                dst_set_block(dst, x, 2, z, BLK_GRASS);
                if (x == 0 || x == 15) && (z == 0 || z == 15) {
                    dst_set_block(dst, x, 3, z, BLK_WOOD);
                    dst_set_block(dst, x, 4, z, BLK_LEAVES);
                }
            }
            x = x + 1;
        }
        z = z + 1;
    }

    // Scattered natural meadow shrubs away from cardinal paths & entity clearing (x=5..11, z=5..10)
    var sh: i32 = 0;
    while sh < 4 {
        ls = splitmix64(ls);
        let sx = 2 + ((ls % 12) as! i32);
        ls = splitmix64(ls);
        let sz = 2 + ((ls % 12) as! i32);
        if (sx < 4 || sx > 11) && (sz < 5 || sz > 10) {
            dst_set_block(dst, sx, 2, sz, BLK_GRASS);
            if (ls & 2) != 0 { dst_set_block(dst, sx, 3, sz, BLK_LEAVES); }
        }
        sh = sh + 1;
    }

    if arch == 0 {
        // Archetype 0: Classic Ying Flower Clearing & Altar
        build_ying_tree_to(dst, 3, 12, 2, 5, 1);
        build_ying_tree_to(dst, 12, 11, 2, 4, 0);
        build_ying_tree_to(dst, 12, 3, 2, 5, 1);

        // Giant 3D Yellow Flower Altar (centered at 8, 12 so (6,3,10) & (10,2,10) stay clear)
        dst_set_block(dst, 8, 2, 12, BLK_WOOD);
        var fz: i32 = 10;
        while fz <= 14 {
            var fx: i32 = 6;
            while fx <= 10 {
                let dx = fx - 8;
                let dz = fz - 12;
                let r2 = dx * dx + dz * dz;
                if r2 <= 4 {
                    if r2 <= 1 { dst_set_block(dst, fx, 3, fz, BLK_POLLEN); }
                    else { dst_set_block(dst, fx, 4, fz, BLK_PETAL_Y); }
                }
                fx = fx + 1;
            }
            fz = fz + 1;
        }
        dst_set_block(dst, 8, 4, 12, BLK_FLOWER_Y_CORE);
        dst_set_block(dst, 8, 6, 12, BLK_TEXT_BLOCK);

        // Totem Shrine
        dst_set_block(dst, 2, 2, 4, BLK_WOOD);
        dst_set_block(dst, 2, 3, 4, BLK_STONE);
        dst_set_block(dst, 2, 4, 4, BLK_WOOD);
        dst_set_block(dst, 2, 5, 4, BLK_UPG_REGEN);
        dst_set_block(dst, 4, 2, 3, BLK_MYSTERY_Q);
        dst_set_block(dst, 4, 3, 3, BLK_MYSTERY_Q);
        dst_set_block(dst, 5, 2, 4, BLK_WHITE_FLOWER);
        dst_set_block(dst, 13, 2, 9, BLK_BLACK_CUBE);
        dst_set_block(dst, 13, 3, 9, BLK_BLACK_CUBE);
    } else if arch == 1 {
        // Archetype 1: Twin Colossal 2x2 Ying Trees + Sky-Canopy Bridge & Frozen Pond
        build_colossal_ying_tree_to(dst, 2, 11, 2, 6);
        build_colossal_ying_tree_to(dst, 12, 11, 2, 6);
        // Canopy walkway linking both giant canopies at y=8
        var bx: i32 = 4;
        while bx <= 11 {
            dst_set_block(dst, bx, 8, 12, BLK_WOOD);
            if bx == 7 || bx == 8 { dst_set_block(dst, bx, 9, 12, BLK_ALPHA_CUBE); }
            bx = bx + 1;
        }
        dst_set_block(dst, 7, 2, 13, BLK_WHITE_FLOWER);
        dst_set_block(dst, 12, 2, 3, BLK_BLACK_CUBE);
        dst_set_block(dst, 12, 3, 3, BLK_BLACK_CUBE);
        build_ying_tree_to(dst, 3, 3, 2, 4, 1);
    } else if arch == 2 {
        // Archetype 2: Ying Totem Ruins & Topaz Quarry Pavilion
        dst_fill_box(dst, 11, 2, 11, 14, 2, 14, BLK_STONE);
        dst_fill_box(dst, 11, 3, 11, 11, 5, 11, BLK_WOOD);
        dst_fill_box(dst, 14, 3, 11, 14, 5, 11, BLK_WOOD);
        dst_fill_box(dst, 11, 3, 14, 11, 5, 14, BLK_WOOD);
        dst_fill_box(dst, 14, 3, 14, 14, 5, 14, BLK_WOOD);
        dst_fill_box(dst, 11, 6, 11, 14, 6, 14, BLK_LEAVES);
        dst_set_block(dst, 12, 3, 12, BLK_MYLANTIS_M);
        dst_set_block(dst, 13, 3, 13, BLK_UPG_REGEN);

        dst_set_block(dst, 2, 2, 12, BLK_TOPAZ_CHECK);
        dst_set_block(dst, 3, 2, 13, BLK_GOLD_ORE);
        build_ying_tree_to(dst, 3, 3, 2, 5, 1);
        build_ying_tree_to(dst, 12, 3, 2, 4, 0);
        dst_set_block(dst, 5, 2, 3, BLK_WHITE_FLOWER);
    } else {
        // Archetype 3: Black Cube Monolith Terrace & Twin Flower Sanctuary
        dst_fill_box(dst, 11, 2, 11, 14, 2, 14, BLK_GRASS);
        dst_fill_box(dst, 12, 3, 12, 13, 4, 13, BLK_BLACK_CUBE);
        dst_set_block(dst, 12, 5, 12, BLK_CORE_GATE);
        dst_set_block(dst, 13, 5, 13, BLK_GOLD_ORE);

        // Twin White + Yellow Flowers in NW meadow
        dst_set_block(dst, 3, 2, 3, BLK_WOOD);
        dst_set_block(dst, 3, 3, 3, BLK_POLLEN);
        dst_set_block(dst, 2, 3, 3, BLK_PETAL_W);
        dst_set_block(dst, 4, 3, 3, BLK_PETAL_W);
        dst_set_block(dst, 3, 4, 3, BLK_WHITE_FLOWER);

        dst_set_block(dst, 3, 2, 12, BLK_WOOD);
        dst_set_block(dst, 3, 3, 12, BLK_POLLEN);
        dst_set_block(dst, 2, 3, 12, BLK_PETAL_Y);
        dst_set_block(dst, 4, 3, 12, BLK_PETAL_Y);
        dst_set_block(dst, 3, 4, 12, BLK_FLOWER_Y_CORE);

        build_ying_tree_to(dst, 12, 3, 2, 5, 1);
        dst_set_block(dst, 2, 2, 6, BLK_MYSTERY_Q);
    }

    // Consistent mineral pockets & interactive stations placed clear of all entity spawns
    dst_set_block(dst, 2, 1, 2, BLK_TOPAZ_CHECK);
    dst_set_block(dst, 13, 1, 13, BLK_GOLD_ORE);
    dst_set_block(dst, 10, 2, 6, BLK_BUY_STATION);
    dst_set_block(dst, 12, 2, 6, BLK_UPGRADE_STATION);
    dst_set_block(dst, 13, 2, 6, BLK_SELL_STATION);
    dst_set_block(dst, 6, 2, 8, BLK_CRATE);
    dst_set_block(dst, 5, 2, 8, BLK_HAZARD_NUKE);
    dst_set_block(dst, 11, 2, 8, BLK_UPG_DMG);
    dst_set_block(dst, 7, 2, 5, BLK_UPG_WEP);
    dst_set_block(dst, 9, 2, 5, BLK_TOME);
}

fn populate_ying_forest_entities(depth: i32, seed: u64) {
    let _ = spawn_entity(ENT_RING_GREEN, 7.5, 3.2, 7.5, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_PINK, 11.5, 3.2, 5.5, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_BLUE, 3.5, 3.2, 8.5, 1, BIOME_MYLANTIS, BLK_MYLANTIS_M);
    let _ = spawn_entity(ENT_RING_RED, 8.5, 12.5, 8.5, 1, -1, BLK_AIR);

    if depth >= 3 && st.genesis_mode == 0 {
        let hp_scale = 35 + depth * 12;
        let _ = spawn_entity_ex(ENT_YINYANG, 6.5, 3.2, 10.5, hp_scale + 10, -1, 0, 1);
        let _ = spawn_entity_ex(ENT_GOBLIN, 10.5, 2.6, 10.5, hp_scale, -1, 0, 2);
        if (seed & 1) == 0 {
            let _ = spawn_entity_ex(ENT_SPIDER, 4.5, 2.5, 7.5, hp_scale - 6, -1, 0, 3);
        }
    }
    let _ = spawn_entity_ex(ENT_GOLD, 8.5, 2.6, 7.5, 1, -1, 0, 4);
    let _ = spawn_entity_ex(ENT_AMMO, 5.5, 2.6, 8.5, 1, -1, 0, 5);
}

fn generate_white_flower_alpha_blocks(dst: i32, seed: u64, parent_blk: u8) {
    var ls = seed;
    if parent_blk == BLK_ALPHA_CUBE {
        // Alpha Cube Hyper-Sanctuary: magenta & crystal glass outer frame + suspended diamond platform
        var y: i32 = 0;
        while y < CHUNK_DIM {
            var z: i32 = 0;
            while z < CHUNK_DIM {
                var x: i32 = 0;
                while x < CHUNK_DIM {
                    let on_edge_x = if x <= 1 || x >= 14 { 1 } else { 0 };
                    let on_edge_y = if y <= 1 || y >= 14 { 1 } else { 0 };
                    let on_edge_z = if z <= 1 || z >= 14 { 1 } else { 0 };
                    if y <= 1 {
                        let ring = if (x + z) % 3 == 0 { BLK_GLASS } else { BLK_ALPHA_CUBE };
                        dst_set_block(dst, x, y, z, if x >= 6 && x <= 9 && z >= 6 && z <= 9 { BLK_TOPAZ_CHECK } else { ring });
                    } else if (on_edge_x + on_edge_y + on_edge_z) >= 2 {
                        dst_set_block(dst, x, y, z, if ((x + y + z) & 1) == 0 { BLK_ALPHA_CUBE } else { BLK_GLASS });
                    }
                    x = x + 1;
                }
                z = z + 1;
            }
            y = y + 1;
        }
        // Floating crystalline cross-bridge at y=6
        var b: i32 = 2;
        while b <= 13 {
            if b != 8 {
                dst_set_block(dst, b, 6, 8, BLK_GLASS);
                dst_set_block(dst, 8, 6, b, BLK_GLASS);
            }
            b = b + 1;
        }
        dst_set_block(dst, 8, 2, 8, BLK_BLACK_CUBE);
        dst_set_block(dst, 8, 3, 8, BLK_ALPHA_CUBE);
        dst_set_block(dst, 8, 5, 8, BLK_TEXT_BLOCK);
    } else {
        // White Flower Cathedral: luminous pearl & glass floor, golden pollen halo, sweeping corner petal ribs
        var z: i32 = 0;
        while z < CHUNK_DIM {
            var x: i32 = 0;
            while x < CHUNK_DIM {
                let dx = x - 7;
                let dz = z - 7;
                let r2 = dx * dx + dz * dz;
                dst_set_block(dst, x, 0, z, BLK_PETAL_W);
                let top_b: u8 =
                    if r2 >= 18 && r2 <= 26 { BLK_POLLEN }
                    else if ((x + z) % 3) == 0 { BLK_GLASS }
                    else { BLK_PETAL_W };
                dst_set_block(dst, x, 1, z, top_b);
                if (x <= 1 || x >= 14) && (z <= 1 || z >= 14) {
                    var cy: i32 = 2;
                    while cy <= 9 {
                        dst_set_block(dst, x, cy, z, if (cy % 3) == 0 { BLK_GLASS } else { BLK_PETAL_W });
                        cy = cy + 1;
                    }
                }
                x = x + 1;
            }
            z = z + 1;
        }
        // Overhead inward-curving white petal arches at y=10..12
        dst_fill_box(dst, 2, 10, 2, 3, 11, 3, BLK_PETAL_W);
        dst_fill_box(dst, 12, 10, 2, 13, 11, 3, BLK_PETAL_W);
        dst_fill_box(dst, 2, 10, 12, 3, 11, 13, BLK_PETAL_W);
        dst_fill_box(dst, 12, 10, 12, 13, 11, 13, BLK_PETAL_W);

        dst_set_block(dst, 8, 2, 8, BLK_ALPHA_CUBE);
        dst_set_block(dst, 8, 3, 8, BLK_ALPHA_CUBE);
        dst_set_block(dst, 8, 5, 8, BLK_TEXT_BLOCK);
    }

    dst_set_block(dst, 5, 2, 8, BLK_UPG_HP);
    dst_set_block(dst, 11, 2, 8, BLK_UPG_ARMOR);
    dst_set_block(dst, 5, 2, 11, BLK_UPG_WEP);
    dst_set_block(dst, 8, 2, 11, BLK_SELL_STATION);
    dst_set_block(dst, 10, 2, 11, BLK_UPGRADE_STATION);
    dst_set_block(dst, 8, 2, 4, BLK_TOME);
    dst_set_block(dst, 3, 2, 8, BLK_MYSTERY_Q);

    var p: i32 = 0;
    while p < 4 {
        ls = splitmix64(ls);
        let px = 3 + ((ls % 10) as! i32);
        ls = splitmix64(ls);
        let pz = 3 + ((ls % 10) as! i32);
        if (px != 8 || pz != 8) && (px != 6 || pz != 6) && (px != 11 || pz != 5) && (px != 4 || pz != 5) && (px != 11 || pz != 11) {
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
        let _ = spawn_entity_ex(ENT_RAT, 4.5, 3.0, 5.5, hp_scale, -1, 0, 1);
        let _ = spawn_entity_ex(ENT_GOBLIN, 11.5, 3.0, 11.5, hp_scale + 12, -1, 0, 2);
    }
    let _ = spawn_entity_ex(ENT_GOLD, 6.5, 3.0, 9.5, 1, -1, 0, 3);
    let _ = spawn_entity_ex(ENT_HEALTH, 9.5, 3.0, 6.5, 1, -1, 0, 4);
}

fn generate_yellow_flower_blocks(dst: i32, depth: i32, seed: u64) {
    var ls = splitmix64(seed ^ 0x59454c4c);
    let variant = (ls % 3) as! i32;

    // 1. Golden petal floor with concentric pollen diamond pattern
    var z: i32 = 0;
    while z < CHUNK_DIM {
        var x: i32 = 0;
        while x < CHUNK_DIM {
            let man = (if x > 7 { x - 7 } else { 7 - x }) + (if z > 7 { z - 7 } else { 7 - z });
            dst_set_block(dst, x, 0, z, BLK_PETAL_Y);
            dst_set_block(dst, x, 1, z, if man == 4 || man == 8 { BLK_POLLEN } else { BLK_PETAL_Y });
            x = x + 1;
        }
        z = z + 1;
    }

    // 2. Labyrinth perimeter walls (y=2..5) with wide 4-block cardinal tunnels at 6..9 for seamless multi-chunk maze
    var y: i32 = 2;
    while y <= 5 {
        var i: i32 = 0;
        while i < CHUNK_DIM {
            if i < 6 || i > 9 {
                dst_set_block(dst, i, y, 0, if (y == 5) { BLK_POLLEN } else { BLK_PETAL_Y });
                dst_set_block(dst, i, y, 15, if (y == 5) { BLK_POLLEN } else { BLK_PETAL_Y });
                dst_set_block(dst, 0, y, i, if (y == 5) { BLK_POLLEN } else { BLK_PETAL_Y });
                dst_set_block(dst, 15, y, i, if (y == 5) { BLK_POLLEN } else { BLK_PETAL_Y });
            }
            i = i + 1;
        }
        y = y + 1;
    }

    // Interior golden maze partitions (keeping entity & center ring corridors completely clear)
    var p: i32 = 2;
    while p <= 5 {
        dst_set_block(dst, 4, p, 3, BLK_PETAL_Y);
        dst_set_block(dst, 4, p, 4, BLK_PETAL_Y);
        dst_set_block(dst, 3, p, 4, BLK_PETAL_Y);
        if variant != 1 {
            dst_set_block(dst, 11, p, 11, BLK_PETAL_Y);
            dst_set_block(dst, 11, p, 12, BLK_PETAL_Y);
            dst_set_block(dst, 12, p, 11, BLK_PETAL_Y);
        }
        p = p + 1;
    }

    // Locked Nectar Vault in NE corner (x=12..14, z=2..4) with Locked Door at (12,2,3)
    dst_fill_box(dst, 12, 2, 1, 14, 4, 4, BLK_PETAL_Y);
    dst_fill_box(dst, 13, 2, 2, 13, 3, 3, BLK_AIR);
    dst_set_block(dst, 12, 2, 3, BLK_LOCKED_DOOR);
    dst_set_block(dst, 12, 3, 3, BLK_POLLEN);
    dst_set_block(dst, 13, 2, 2, BLK_UPG_WEP);
    dst_set_block(dst, 13, 2, 3, BLK_GOLD_ORE);

    // 3. Upper Pollen Balcony Ring (y=8) + Overhead Petal Crown (y=12..13)
    var bz: i32 = 2;
    while bz <= 13 {
        var bx: i32 = 2;
        while bx <= 13 {
            let rim = if (bx == 2 || bx == 13 || bz == 2 || bz == 13) && (bx < 6 || bx > 9) && (bz < 6 || bz > 9) { 1 } else { 0 };
            if rim != 0 { dst_set_block(dst, bx, 8, bz, BLK_POLLEN); }
            bx = bx + 1;
        }
        bz = bz + 1;
    }
    dst_fill_box(dst, 0, 12, 0, 2, 13, 2, BLK_PETAL_Y);
    dst_fill_box(dst, 13, 12, 0, 15, 13, 2, BLK_PETAL_Y);
    dst_fill_box(dst, 0, 12, 13, 2, 13, 15, BLK_PETAL_Y);
    dst_fill_box(dst, 13, 12, 13, 15, 13, 15, BLK_PETAL_Y);

    // Stations & Key Landmarks
    dst_set_block(dst, 5, 2, 8, BLK_BUY_STATION);
    dst_set_block(dst, 11, 2, 8, BLK_SELL_STATION);
    dst_set_block(dst, 3, 2, 8, BLK_UPGRADE_STATION);
    dst_set_block(dst, 8, 2, 4, BLK_UPG_HP);
    dst_set_block(dst, 8, 2, 12, BLK_KEY_BLOCK);
    dst_set_block(dst, 4, 2, 12, BLK_MYLANTIS_M);
    dst_set_block(dst, 8, 2, 10, BLK_FLOWER_Y_CORE);
    dst_set_block(dst, 8, 4, 10, BLK_TEXT_BLOCK);
    dst_set_block(dst, 6, 2, 13, BLK_TOME);
    dst_set_block(dst, 10, 2, 13, BLK_CRATE);
    if depth >= 3 { dst_set_block(dst, 11, 2, 13, BLK_SPAWNER); }
}

fn generate_mylantis_blocks(dst: i32, depth: i32, seed: u64) {
    var ls = splitmix64(seed ^ 0x4d594c41);
    let cvar = (ls % 3) as! i32;

    // 1. Subterranean Turquoise Cavern Floor (y=0..2) with Crystal Ice Streams & Topaz Seams
    var z: i32 = 0;
    while z < CHUNK_DIM {
        var x: i32 = 0;
        while x < CHUNK_DIM {
            dst_set_block(dst, x, 0, z, BLK_MYLANTIS);
            let is_stream = if (x == 7 && z >= 10) || (z == 13 && x >= 3 && x <= 7) { 1 } else { 0 };
            let is_ledge = if (x <= 2 || x >= 13) && (z <= 2 || z >= 13) { 1 } else { 0 };
            if is_stream != 0 {
                dst_set_block(dst, x, 1, z, BLK_ICE);
            } else {
                dst_set_block(dst, x, 1, z, if ((x * 3 + z) % 7) == 0 { BLK_TOPAZ_CHECK } else { BLK_MYLANTIS });
                if is_ledge != 0 { dst_set_block(dst, x, 2, z, BLK_MYLANTIS); }
            }
            x = x + 1;
        }
        z = z + 1;
    }

    // 2. Cavern Pillars & Organic Roof Vault (y=12..14 with open central sky shaft x=5..10, z=5..10)
    var y: i32 = 12;
    while y <= 14 {
        var cz: i32 = 0;
        while cz < CHUNK_DIM {
            var cx: i32 = 0;
            while cx < CHUNK_DIM {
                let is_hole = if (cx >= 5 && cx <= 10 && cz >= 5 && cz <= 10) { 1 } else { 0 };
                let is_border = if (cx <= 2 || cx >= 13 || cz <= 2 || cz >= 13) { 1 } else { 0 };
                if is_hole == 0 && (y >= 13 || is_border != 0) {
                    dst_set_block(dst, cx, y, cz, if ((cx + y + cz) % 5) == 0 { BLK_TOPAZ_CHECK } else { BLK_MYLANTIS });
                }
                cx = cx + 1;
            }
            cz = cz + 1;
        }
        y = y + 1;
    }
    // Hanging Ice Stalactites
    dst_fill_box(dst, 3, 10, 3, 3, 12, 3, BLK_ICE);
    dst_fill_box(dst, 12, 10, 3, 12, 12, 3, BLK_ICE);
    dst_fill_box(dst, 3, 10, 12, 3, 12, 12, BLK_ICE);
    dst_fill_box(dst, 12, 10, 12, 12, 12, 12, BLK_ICE);

    // 3. Corner Stalagmites & Cavern Sky-Bridge (keeping entity spawns at (4.5,3,11.5), (5.5,5.5,5.5), (11.5,3.5,11.5) clear)
    var py: i32 = 2;
    while py <= 11 {
        dst_set_block(dst, 2, py, 2, BLK_MYLANTIS);
        dst_set_block(dst, 13, py, 2, BLK_MYLANTIS);
        dst_set_block(dst, 2, py, 13, BLK_MYLANTIS);
        dst_set_block(dst, 13, py, 13, BLK_MYLANTIS);
        py = py + 1;
    }
    if cvar != 2 {
        var bx: i32 = 3;
        while bx <= 12 {
            dst_set_block(dst, bx, 7, 13, BLK_TOPAZ_CHECK);
            bx = bx + 1;
        }
    }

    // 4. Stations, Smuggler Black Market & Locked Vault
    dst_set_block(dst, 5, 2, 8, BLK_BUY_STATION);
    dst_set_block(dst, 11, 2, 8, BLK_SELL_STATION);
    dst_set_block(dst, 3, 2, 8, BLK_UPGRADE_STATION);
    dst_set_block(dst, 4, 2, 12, BLK_BLACK_MARKET);
    dst_set_block(dst, 12, 2, 12, BLK_LOCKED_DOOR);
    dst_set_block(dst, 13, 2, 12, BLK_UPG_AMMO);
    dst_set_block(dst, 6, 2, 11, BLK_HAZARD_NUKE);
    dst_set_block(dst, 3, 2, 5, BLK_MYSTERY_Q);
    dst_set_block(dst, 8, 2, 4, BLK_UPG_ROF);
    dst_set_block(dst, 8, 2, 12, BLK_UPG_SPEED);
    dst_set_block(dst, 4, 2, 10, BLK_UPG_WEP);
    dst_set_block(dst, 4, 2, 8, BLK_BLACK_CUBE);
    dst_set_block(dst, 9, 2, 11, BLK_MYLANTIS_M);
    dst_set_block(dst, 8, 2, 8, BLK_TOME);
    dst_set_block(dst, 11, 2, 4, BLK_TOPAZ_CHECK);
    if depth >= 3 { dst_set_block(dst, 10, 2, 11, BLK_SPAWNER); }
}

fn generate_inner_core_blocks(dst: i32, depth: i32, seed: u64) {
    let _ = seed;
    // Imperial Magenta & Gold Core Arena where The Singularity Boss & Friend 'K' reside
    var y: i32 = 0;
    while y <= 13 {
        var z: i32 = 0;
        while z < CHUNK_DIM {
            var x: i32 = 0;
            while x < CHUNK_DIM {
                if y <= 1 {
                    let dx = x - 7;
                    let dz = z - 7;
                    let r2 = dx * dx + dz * dz;
                    let blk: u8 =
                        if r2 <= 6 { BLK_STONE }
                        else if (x == 8 || z == 8) { BLK_GOLD_ORE }
                        else { BLK_CORE_GATE };
                    dst_set_block(dst, x, y, z, blk);
                } else if x <= 1 || x >= 14 || z <= 1 || z >= 14 {
                    let arch_x = if (z <= 1 || z >= 14) && (x >= 6 && x <= 9 && y >= 2 && y <= 8) { 1 } else { 0 };
                    let arch_z = if (x <= 1 || x >= 14) && (z >= 6 && z <= 9 && y >= 2 && y <= 8) { 1 } else { 0 };
                    if arch_x == 0 && arch_z == 0 {
                        let trim = if ((x + y + z) % 4) == 0 { BLK_GOLD_ORE } else if (y == 7) { BLK_INFINITY_RED } else { BLK_CORE_GATE };
                        dst_set_block(dst, x, y, z, trim);
                    }
                }
                x = x + 1;
            }
            z = z + 1;
        }
        y = y + 1;
    }

    // Four Towering Power Pylons + Overhead Cross-Halo Ribs (y=12..13)
    dst_fill_box(dst, 3, 2, 3, 3, 11, 3, BLK_CORE_GATE);
    dst_fill_box(dst, 12, 2, 3, 12, 11, 3, BLK_CORE_GATE);
    dst_fill_box(dst, 3, 2, 12, 3, 11, 12, BLK_CORE_GATE);
    dst_fill_box(dst, 12, 2, 12, 12, 11, 12, BLK_CORE_GATE);
    dst_set_block(dst, 3, 12, 3, BLK_INFINITY_RED);
    dst_set_block(dst, 12, 12, 3, BLK_INFINITY_RED);
    dst_set_block(dst, 3, 12, 12, BLK_INFINITY_RED);
    dst_set_block(dst, 12, 12, 12, BLK_INFINITY_RED);

    var r: i32 = 3;
    while r <= 12 {
        dst_set_block(dst, r, 13, 3, BLK_CORE_GATE);
        dst_set_block(dst, r, 13, 12, BLK_CORE_GATE);
        dst_set_block(dst, 3, 13, r, BLK_CORE_GATE);
        dst_set_block(dst, 12, 13, r, BLK_CORE_GATE);
        r = r + 1;
    }

    // Friend 'K' Sealed Sanctuary Frame at (x=6..10, z=13..15) leaving (8.0, 3.0, 13.6) open inside!
    dst_fill_box(dst, 6, 2, 13, 6, 5, 14, BLK_GLASS);
    dst_fill_box(dst, 10, 2, 13, 10, 5, 14, BLK_GLASS);
    dst_fill_box(dst, 6, 5, 13, 10, 5, 14, BLK_GOLD_ORE);

    // Core Stations & Arsenal
    dst_set_block(dst, 5, 2, 8, BLK_BUY_STATION);
    dst_set_block(dst, 11, 2, 8, BLK_SELL_STATION);
    dst_set_block(dst, 3, 2, 8, BLK_UPGRADE_STATION);
    dst_set_block(dst, 12, 2, 8, BLK_BLACK_MARKET);
    dst_set_block(dst, 8, 2, 4, BLK_UPG_ARMOR);
    dst_set_block(dst, 8, 2, 11, BLK_UPG_HP);
    dst_set_block(dst, 4, 2, 8, BLK_BLACK_CUBE);
    dst_set_block(dst, 8, 2, 8, BLK_UPG_WEP);
    dst_set_block(dst, 10, 2, 5, BLK_TOME);
    dst_set_block(dst, 4, 2, 4, BLK_CRATE);
    if depth >= 3 { dst_set_block(dst, 11, 2, 10, BLK_SPAWNER); }
}

fn generate_black_cube_blocks(dst: i32, depth: i32, seed: u64) {
    // Authentic 3D Menger Sponge Lattice (I1 / I2 / I3) — crisp grey/charcoal beams & open cross-shafts
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
                    if depth >= 5 && (x == 0 || x == 15) && (y == 0 || y == 15) && (z == 0 || z == 15) {
                        dst_set_block(dst, x, y, z, BLK_INFINITY_RED);
                    } else if is_frame != 0 && ((x + y + z) % 7 == 0) {
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

    dst_set_block(dst, 1, 4, 14, BLK_ALPHA_CUBE);
    dst_set_block(dst, 14, 4, 1, BLK_TOPAZ_CHECK);

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
    dst_set_block(dst, 12, 1, 8, BLK_UPGRADE_STATION);
    dst_set_block(dst, 8, 1, 5, BLK_UPG_DMG);
    dst_set_block(dst, 8, 1, 10, BLK_TOME);
    dst_set_block(dst, 6, 1, 6, BLK_UPG_WEP);
    dst_set_block(dst, 4, 2, 8, BLK_CORE_GATE);
    dst_set_block(dst, 11, 2, 8, BLK_CORE_GATE);
    dst_set_block(dst, 9, 1, 6, BLK_HAZARD_NUKE);
    if depth >= 3 { dst_set_block(dst, 10, 1, 10, BLK_SPAWNER); }
}

fn generate_ice_world_blocks(dst: i32, seed: u64) {
    var ls = splitmix64(seed ^ 0x49434557);
    let ivar = (ls & 1) as! i32;
    // Contoured Glacial Tundra with Towering Hollow Ice Spires & Sky Bridges
    var z: i32 = 0;
    while z < CHUNK_DIM {
        var x: i32 = 0;
        while x < CHUNK_DIM {
            dst_set_block(dst, x, 0, z, BLK_ICE);
            let is_ridge = if (x <= 2 || x >= 13) && (z <= 2 || z >= 13) { 1 } else { 0 };
            dst_set_block(dst, x, 1, z, if ((x + z) & 1) == 0 { BLK_ICE } else { BLK_GLASS });
            if is_ridge != 0 {
                let h = if (x == 0 || x == 15) && (z == 0 || z == 15) { 11 } else if (x <= 1 || x >= 14) && (z <= 1 || z >= 14) { 8 } else { 4 };
                var py: i32 = 2;
                while py <= h {
                    dst_set_block(dst, x, py, z, if (py % 3) == 0 { BLK_PETAL_W } else if (py % 2) == 0 { BLK_ICE } else { BLK_GLASS });
                    py = py + 1;
                }
            }
            x = x + 1;
        }
        z = z + 1;
    }

    // Crystal Sky-Bridges connecting the corner glacial spires at y=7
    if ivar == 0 {
        var b: i32 = 2;
        while b <= 13 {
            dst_set_block(dst, b, 7, 2, BLK_GLASS);
            dst_set_block(dst, b, 7, 13, BLK_GLASS);
            b = b + 1;
        }
    } else {
        var b: i32 = 2;
        while b <= 13 {
            dst_set_block(dst, 2, 7, b, BLK_GLASS);
            dst_set_block(dst, 13, 7, b, BLK_GLASS);
            b = b + 1;
        }
    }

    var c: i32 = 0;
    while c < 4 {
        ls = splitmix64(ls);
        let sx = 3 + ((ls % 10) as! i32);
        ls = splitmix64(ls);
        let sz = 3 + ((ls % 10) as! i32);
        if (sx < 5 || sx > 10) && (sz < 5 || sz > 10) {
            dst_set_block(dst, sx, 2, sz, BLK_ICE);
            dst_set_block(dst, sx, 3, sz, BLK_GLASS);
            dst_set_block(dst, sx, 4, sz, BLK_ICE_WORLD);
        }
        c = c + 1;
    }
    dst_set_block(dst, 8, 2, 10, BLK_ICE_WORLD);
    dst_set_block(dst, 5, 2, 8, BLK_BUY_STATION);
    dst_set_block(dst, 12, 2, 8, BLK_UPGRADE_STATION);
    dst_set_block(dst, 11, 2, 8, BLK_UPG_SPEED);
    dst_set_block(dst, 8, 2, 4, BLK_UPG_ARMOR);
    dst_set_block(dst, 5, 2, 11, BLK_UPG_WEP);
    dst_set_block(dst, 10, 2, 5, BLK_TOME);
    dst_set_block(dst, 13, 2, 3, BLK_MYSTERY_Q);
}

fn generate_desert_world_blocks(dst: i32, seed: u64) {
    var ls = splitmix64(seed ^ 0x44455354);
    let dvar = (ls % 2) as! i32;
    // Open Sandstone Terrace + Hollow Stepped Pharaoh Pyramid & Corner Obelisks
    var z: i32 = 0;
    while z < CHUNK_DIM {
        var x: i32 = 0;
        while x < CHUNK_DIM {
            dst_set_block(dst, x, 0, z, BLK_SAND);
            dst_set_block(dst, x, 1, z, if (x == 8 || z == 8) { BLK_GOLD_ORE } else { BLK_SAND });
            if (x <= 1 || x >= 14) && (z <= 1 || z >= 14) {
                var py: i32 = 2;
                while py <= 8 {
                    dst_set_block(dst, x, py, z, if (py % 3) == 0 || py == 8 { BLK_GOLD_ORE } else { BLK_SAND });
                    py = py + 1;
                }
            }
            x = x + 1;
        }
        z = z + 1;
    }

    // Hollow Stepped Sandstone Pyramid (x=3..12, z=3..12, y=2..6) with 4 cardinal entrances (6..9)
    if dvar == 0 {
        var tier: i32 = 0;
        while tier < 4 {
            let y = 2 + tier;
            let lo = 3 + tier;
            let hi = 12 - tier;
            var pz: i32 = lo;
            while pz <= hi {
                var px: i32 = lo;
                while px <= hi {
                    let shell = if px == lo || px == hi || pz == lo || pz == hi { 1 } else { 0 };
                    let gate = if tier <= 2 && ((px >= 7 && px <= 8) || (pz >= 7 && pz <= 8)) { 1 } else { 0 };
                    if shell != 0 && gate == 0 {
                        dst_set_block(dst, px, y, pz, if tier == 3 { BLK_GOLD_ORE } else { BLK_SAND });
                    }
                    px = px + 1;
                }
                pz = pz + 1;
            }
            tier = tier + 1;
        }
        dst_set_block(dst, 7, 6, 7, BLK_DESERT_WORLD);
        dst_set_block(dst, 8, 6, 8, BLK_DESERT_WORLD);
    } else {
        var p: i32 = 0;
        while p < 3 {
            ls = splitmix64(ls);
            let px = 4 + ((ls % 8) as! i32);
            ls = splitmix64(ls);
            let pz = 4 + ((ls % 8) as! i32);
            if px != 8 || pz != 8 {
                dst_set_block(dst, px, 2, pz, BLK_SAND);
                dst_set_block(dst, px, 3, pz, BLK_DESERT_WORLD);
            }
            p = p + 1;
        }
    }

    dst_set_block(dst, 8, 2, 11, BLK_DESERT_WORLD);
    dst_set_block(dst, 5, 2, 8, BLK_SELL_STATION);
    dst_set_block(dst, 11, 2, 8, BLK_BLACK_MARKET);
    dst_set_block(dst, 13, 2, 8, BLK_UPGRADE_STATION);
    dst_set_block(dst, 8, 2, 4, BLK_KEY_BLOCK);
    dst_set_block(dst, 11, 2, 4, BLK_LOCKED_DOOR);
    dst_set_block(dst, 12, 2, 4, BLK_UPG_DMG);
    dst_set_block(dst, 5, 2, 11, BLK_HAZARD_NUKE);
}

fn generate_ext_biome_blocks(dst: i32, biome: i32, depth: i32, seed: u64) {
    let _ = depth;
    var ls = splitmix64(seed ^ ((biome as u64) * 0x9e3779b9));
    // Outer shell with axial portals so neighboring sibling chunks stay traversable
    var shell: u8 = BLK_STONE;
    var floor_b: u8 = BLK_STONE;
    var pillar_b: u8 = BLK_CRYSTAL_CYAN;
    if biome == BIOME_NOOB_FLOWER {
        shell = BLK_LEAVES; floor_b = BLK_GRASS; pillar_b = BLK_PETAL_W;
    } else if biome == BIOME_YING_LIBRARY {
        shell = BLK_BOOKSHELF; floor_b = BLK_WOOD; pillar_b = BLK_BOOKSHELF;
    } else if biome == BIOME_BOTANY_LAB {
        shell = BLK_GLASS; floor_b = BLK_ROOT_SOIL; pillar_b = BLK_BOTANY_TANK;
    } else if biome == BIOME_BETA_CUBE {
        shell = BLK_BETA_TILE; floor_b = BLK_ALPHA_CUBE; pillar_b = BLK_CRYSTAL_PURPLE;
    } else if biome == BIOME_RED_CAVES {
        shell = BLK_MYLANTIS_RED; floor_b = BLK_MYLANTIS_RED; pillar_b = BLK_CRYSTAL_PURPLE;
    } else if biome == BIOME_I1_LIGHTHOUSE {
        shell = BLK_WALL_TUT; floor_b = BLK_GLASS; pillar_b = BLK_CRYSTAL_CYAN;
    } else if biome == BIOME_I2_MOUNTAINS {
        shell = BLK_LUNAR_REGOLITH; floor_b = BLK_STONE; pillar_b = BLK_ICE;
    } else if biome == BIOME_BURLINGTON {
        shell = BLK_SAND; floor_b = BLK_QUICKSAND; pillar_b = BLK_WALL_TUT;
    } else if biome == BIOME_I3_ROOTS {
        shell = BLK_ROOT_SOIL; floor_b = BLK_ROOT_SOIL; pillar_b = BLK_WOOD;
    } else if biome == BIOME_PURPLE_HOUSE {
        shell = BLK_OBLIVION_BRICK; floor_b = BLK_OBLIVION_BRICK; pillar_b = BLK_CRYSTAL_PURPLE;
    } else if biome == BIOME_SINGLETON {
        shell = BLK_NEON_GRID; floor_b = BLK_BLACK_CUBE; pillar_b = BLK_CORE_GATE;
    } else if biome == BIOME_ARCADE {
        shell = BLK_NEON_GRID; floor_b = BLK_BETA_TILE; pillar_b = BLK_ARCADE_CAB;
    } else if biome == BIOME_TON618 {
        shell = BLK_EVENT_HORIZON; floor_b = BLK_EVENT_HORIZON; pillar_b = BLK_CRYSTAL_PURPLE;
    } else if biome == BIOME_SOLAR_SYSTEM {
        shell = BLK_GLASS; floor_b = BLK_SOLAR_PLASMA; pillar_b = BLK_SOLAR_PLASMA;
    }

    var y: i32 = 0;
    while y < CHUNK_DIM {
        var z: i32 = 0;
        while z < CHUNK_DIM {
            var x: i32 = 0;
            while x < CHUNK_DIM {
                let on_shell = x == 0 || x == 15 || y == 0 || y == 15 || z == 0 || z == 15;
                let portal = (x >= 6 && x <= 9 && y >= 6 && y <= 9) ||
                             (y >= 6 && y <= 9 && z >= 6 && z <= 9) ||
                             (x >= 6 && x <= 9 && z >= 6 && z <= 9);
                if on_shell && portal == false {
                    dst_set_block(dst, x, y, z, shell);
                } else if y == 1 && (x >= 2 && x <= 13) && (z >= 2 && z <= 13) {
                    if biome == BIOME_BURLINGTON && ((x + z) % 5) == 0 {
                        dst_set_block(dst, x, y, z, BLK_QUICKSAND);
                    } else if biome == BIOME_SOLAR_SYSTEM && ((x * z) % 7) == 0 {
                        dst_set_block(dst, x, y, z, BLK_SOLAR_PLASMA);
                    } else if biome == BIOME_BETA_CUBE && ((x + z) & 1) == 0 {
                        dst_set_block(dst, x, y, z, BLK_WHITE_FLOWER);
                    } else {
                        dst_set_block(dst, x, y, z, floor_b);
                    }
                }
                x = x + 1;
            }
            z = z + 1;
        }
        y = y + 1;
    }

    // Corner architectural pillars & treasures
    var p_y: i32 = 2;
    while p_y <= 11 {
        dst_set_block(dst, 3, p_y, 3, pillar_b);
        dst_set_block(dst, 12, p_y, 3, pillar_b);
        dst_set_block(dst, 3, p_y, 12, pillar_b);
        dst_set_block(dst, 12, p_y, 12, pillar_b);
        p_y = p_y + 1;
    }

    // Biome-specific centerpiece & interactive blocks
    dst_set_block(dst, 8, 2, 13, BLK_TOME);
    dst_set_block(dst, 5, 2, 12, BLK_MYSTERY_Q);
    dst_set_block(dst, 10, 2, 12, BLK_UPG_WEP);
    if biome == BIOME_ARCADE {
        dst_set_block(dst, 8, 2, 8, BLK_ARCADE_CAB);
        dst_set_block(dst, 6, 2, 8, BLK_BUY_STATION);
        dst_set_block(dst, 10, 2, 8, BLK_UPGRADE_STATION);
    } else if biome == BIOME_YING_LIBRARY {
        dst_set_block(dst, 6, 2, 6, BLK_BOOKSHELF);
        dst_set_block(dst, 9, 2, 6, BLK_SELL_STATION);
        dst_set_block(dst, 8, 2, 10, BLK_UPG_DMG);
    } else if biome == BIOME_BOTANY_LAB {
        dst_set_block(dst, 7, 2, 8, BLK_BOTANY_TANK);
        dst_set_block(dst, 9, 2, 8, BLK_UPG_REGEN);
        dst_set_block(dst, 8, 2, 6, BLK_UPG_HP);
    } else if biome == BIOME_RED_CAVES {
        dst_set_block(dst, 8, 2, 8, BLK_TOPAZ_CHECK);
        dst_set_block(dst, 6, 2, 10, BLK_SPAWNER);
        dst_set_block(dst, 11, 2, 7, BLK_BLACK_MARKET);
    } else if biome == BIOME_TON618 {
        dst_set_block(dst, 8, 2, 10, BLK_CORE_GATE);
        dst_set_block(dst, 5, 2, 5, BLK_HAZARD_NUKE);
        dst_set_block(dst, 11, 2, 5, BLK_UPG_ROF);
    } else if biome == BIOME_SINGLETON {
        dst_set_block(dst, 8, 5, 8, BLK_ALPHA_CUBE);
        dst_set_block(dst, 4, 2, 8, BLK_UPGRADE_STATION);
        dst_set_block(dst, 12, 2, 8, BLK_BLACK_MARKET);
    } else {
        dst_set_block(dst, 8, 2, 8, BLK_INFINITY_RED);
        dst_set_block(dst, 4, 2, 6, BLK_UPG_SPEED);
        dst_set_block(dst, 12, 2, 6, BLK_UPG_ARMOR);
    }
    if (ls & 1) == 0 {
        dst_set_block(dst, 4, 2, 10, BLK_GOLD_ORE);
        dst_set_block(dst, 11, 2, 10, BLK_CRATE);
    } else {
        dst_set_block(dst, 4, 2, 10, BLK_TOPAZ_CHECK);
        dst_set_block(dst, 11, 2, 10, BLK_KEY_BLOCK);
    }
}

fn generate_interior_biome_blocks(dst: i32, biome: i32, depth: i32, seed: u64) {
    if biome == BIOME_BLACK_CUBE {
        generate_black_cube_blocks(dst, depth, seed);
        return;
    }
    if biome == BIOME_ICE_WORLD {
        generate_ice_world_blocks(dst, seed);
        return;
    }
    if biome == BIOME_DESERT_WORLD {
        generate_desert_world_blocks(dst, seed);
        return;
    }
    if biome == BIOME_YELLOW_FLOWER {
        generate_yellow_flower_blocks(dst, depth, seed);
        return;
    }
    if biome == BIOME_MYLANTIS {
        generate_mylantis_blocks(dst, depth, seed);
        return;
    }
    if biome == BIOME_INNER_CORE {
        generate_inner_core_blocks(dst, depth, seed);
        return;
    }
    generate_ext_biome_blocks(dst, biome, depth, seed);
}

fn populate_interior_biome_entities(biome: i32, depth: i32) {
    let _ = spawn_entity(ENT_RING_RED, 8.0, 12.2, 8.0, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_GREEN, 6.2, 3.5, 8.0, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_PINK, 10.2, 3.5, 6.2, 1, -1, BLK_AIR);
    if biome == BIOME_SOLAR_SYSTEM || biome == BIOME_I1_LIGHTHOUSE {
        let _ = spawn_entity(ENT_RING_BLUE, 4.2, 4.0, 4.2, 1, BIOME_ARCADE, BLK_INFINITY_RED);
    } else if biome == BIOME_ARCADE {
        let _ = spawn_entity(ENT_RING_DANGER, 12.2, 4.0, 12.2, 1, BIOME_TON618, BLK_CORE_GATE);
    }
    if st.genesis_mode == 0 {
        let d_cap = clamp_i(depth, 1, 40);
        let scale_hp = 30 + d_cap * 18;
        if biome == BIOME_YELLOW_FLOWER {
            let _ = spawn_entity_ex(ENT_GOBLIN, 4.5, 3.0, 11.5, scale_hp, -1, 0, 1);
            let _ = spawn_entity_ex(ENT_RAT, 11.5, 3.0, 4.5, scale_hp - 8, -1, 0, 2);
            let _ = spawn_entity_ex(ENT_YINYANG, 8.0, 5.5, 11.5, scale_hp + 20, -1, 0, 3);
        } else if biome == BIOME_MYLANTIS {
            let _ = spawn_entity_ex(ENT_MENACE, 4.5, 3.0, 11.5, scale_hp + 25, -1, 0, 1);
            let _ = spawn_entity_ex(ENT_SPIDER, 11.5, 3.0, 4.5, scale_hp, -1, 0, 2);
            let _ = spawn_entity_ex(ENT_BABY_SPIDER, 6.5, 3.0, 10.0, scale_hp / 2 + 12, -1, 0, 3);
        } else if biome == BIOME_ICE_WORLD {
            let _ = spawn_entity_ex(ENT_YINYANG, 4.5, 3.0, 11.5, scale_hp, -1, 0, 1);
            let _ = spawn_entity_ex(ENT_MARINE, 5.5, 5.5, 5.5, scale_hp + 15, -1, 0, 2);
            let _ = spawn_entity_ex(ENT_DEMON, 11.5, 3.5, 11.5, scale_hp + 30, -1, 0, 3);
        } else if biome == BIOME_DESERT_WORLD {
            let _ = spawn_entity_ex(ENT_PIRATE, 4.5, 3.0, 11.5, scale_hp + 10, -1, 0, 1);
            let _ = spawn_entity_ex(ENT_MENACE, 11.5, 6.0, 11.5, scale_hp + 20, -1, 0, 2);
        } else if biome == BIOME_BLACK_CUBE {
            let _ = spawn_entity_ex(ENT_GUARDIAN, 6.5, 5.0, 9.5, scale_hp + 85, -1, 0, 1);
            let _ = spawn_entity_ex(ENT_DEMON, 9.5, 3.5, 6.5, scale_hp + 45, -1, 0, 2);
            let _ = spawn_entity_ex(ENT_MENACE, 12.0, 8.5, 12.0, scale_hp + 30, -1, 0, 3);
        } else if biome == BIOME_NOOB_FLOWER || biome == BIOME_BOTANY_LAB {
            let _ = spawn_entity_ex(ENT_TWEEDLE, 4.8, 3.5, 10.5, scale_hp, -1, 0, 1);
            let _ = spawn_entity_ex(ENT_GNAT, 11.2, 6.2, 5.2, scale_hp - 10, -1, 0, 2);
            let _ = spawn_entity_ex(ENT_GROWER, 8.0, 4.5, 11.0, scale_hp + 30, -1, 0, 3);
        } else if biome == BIOME_YING_LIBRARY || biome == BIOME_BETA_CUBE {
            let _ = spawn_entity_ex(ENT_BEHOLDER, 5.5, 6.0, 10.5, scale_hp + 40, -1, 0, 1);
            let _ = spawn_entity_ex(ENT_SLIVER, 10.5, 3.8, 10.5, scale_hp + 25, -1, 0, 2);
            let _ = spawn_entity_ex(ENT_SHRINKER, 5.0, 4.0, 5.0, scale_hp + 10, -1, 0, 3);
        } else if biome == BIOME_RED_CAVES || biome == BIOME_BURLINGTON {
            let _ = spawn_entity_ex(ENT_LAMPREY, 5.2, 3.8, 11.2, scale_hp + 20, -1, 0, 1);
            let _ = spawn_entity_ex(ENT_BURLY, 10.8, 3.5, 11.0, scale_hp + 60, -1, 0, 2);
            let _ = spawn_entity_ex(ENT_ROCKET_SPIDER, 8.0, 5.0, 12.0, scale_hp + 50, -1, 0, 3);
        } else if biome == BIOME_I1_LIGHTHOUSE || biome == BIOME_I2_MOUNTAINS || biome == BIOME_I3_ROOTS {
            let _ = spawn_entity_ex(ENT_HEX_SENTRY, 5.0, 6.5, 10.5, scale_hp + 55, -1, 0, 1);
            let _ = spawn_entity_ex(ENT_HYDRA, 10.5, 4.5, 10.5, scale_hp + 95, -1, 0, 2);
        } else if biome == BIOME_PURPLE_HOUSE || biome == BIOME_SINGLETON || biome == BIOME_SOLAR_SYSTEM {
            let _ = spawn_entity_ex(ENT_VULCAN, 5.0, 4.5, 11.0, scale_hp + 80, -1, 0, 1);
            let _ = spawn_entity_ex(ENT_BEHOLDER, 11.0, 7.0, 11.0, scale_hp + 55, -1, 0, 2);
        } else if biome == BIOME_ARCADE {
            let _ = spawn_entity_ex(ENT_ARCADE_DRONE, 5.0, 5.0, 10.5, scale_hp + 30, -1, 0, 1);
            let _ = spawn_entity_ex(ENT_ARCADE_DRONE, 11.0, 6.0, 10.5, scale_hp + 30, -1, 0, 2);
        } else if biome == BIOME_TON618 {
            let _ = spawn_entity_ex(ENT_TON618_BOSS, 8.0, 7.0, 11.5, 460 + d_cap * 48, -1, 0, 10);
            let _ = spawn_entity_ex(ENT_BEHOLDER, 4.2, 4.2, 10.5, scale_hp + 70, -1, 0, 11);
        } else {
            let _ = spawn_entity_ex(ENT_SINGULARITY, 8.0, 6.8, 11.8, 320 + d_cap * 35, -1, 0, 10);
            let _ = spawn_entity_ex(ENT_GUARDIAN, 4.2, 3.2, 11.5, scale_hp + 70, -1, 0, 11);
        }
        if st.mut_double_monsters != 0 {
            let _ = spawn_entity_ex(ENT_GNAT, 6.0, 7.5, 11.0, scale_hp, -1, 0, 14);
            let _ = spawn_entity_ex(ENT_BURLY, 10.0, 3.2, 11.5, scale_hp + 45, -1, 0, 15);
        }
    }
    if biome == BIOME_INNER_CORE && st.k_rescued == 0 {
        let _ = spawn_entity(ENT_FRIEND_K, 8.0, 3.0, 13.6, 1, -1, 0);
    }
    let _ = spawn_entity_ex(ENT_GOLD, 6.5, 3.0, 5.5, 1, -1, 0, 6);
    let _ = spawn_entity_ex(ENT_AMMO, 4.0, 3.0, 8.0, 1, -1, 0, 7);
    let _ = spawn_entity_ex(ENT_HEALTH, 8.0, 3.0, 3.5, 1, -1, 0, 8);
}

fn generate_generic_hollow_block(dst: i32, blk: u8, depth: i32, seed: u64) {
    let _ = depth;
    var ls = splitmix64(seed ^ ((blk as u64) * 0x517cc1b7));
    let thick: i32 = 2 + ((ls & 1) as! i32);

    if blk == BLK_LEAVES {
        var y: i32 = 0;
        while y < CHUNK_DIM {
            var z: i32 = 0;
            while z < CHUNK_DIM {
                var x: i32 = 0;
                while x < CHUNK_DIM {
                    let shell = if x <= 1 || x >= 14 || y <= 1 || y >= 14 || z <= 1 || z >= 14 { 1 } else { 0 };
                    let hole = if (x >= 5 && x <= 10 && y >= 5 && y <= 10) ||
                                  (y >= 5 && y <= 10 && z >= 5 && z <= 10) ||
                                  (x >= 5 && x <= 10 && z >= 5 && z <= 10) ||
                                  (x >= 2 && x <= 3 && y >= 2 && y <= 3) ||
                                  (y >= 12 && y <= 13 && z >= 12 && z <= 13) ||
                                  (x >= 12 && x <= 13 && z >= 2 && z <= 3) { 1 } else { 0 };
                    if shell != 0 && hole == 0 {
                        let hv = splitmix64(ls ^ ((x * 911 + y * 353 + z * 197) as u64));
                        if (hv % 5) != 0 {
                            dst_set_block(dst, x, y, z, if (hv % 13) == 0 { BLK_PETAL_W } else { BLK_LEAVES });
                        }
                    }
                    x = x + 1;
                }
                z = z + 1;
            }
            y = y + 1;
        }
        var b: i32 = 2;
        while b <= 13 {
            dst_set_block(dst, b, 4, 8, BLK_WOOD);
            dst_set_block(dst, 8, 4, b, BLK_WOOD);
            b = b + 1;
        }
        dst_set_block(dst, 8, 5, 8, BLK_FLOWER_Y_CORE);
        dst_set_block(dst, 3, 2, 3, BLK_WHITE_FLOWER);
        dst_set_block(dst, 13, 2, 13, BLK_GOLD_ORE);
        return;
    }

    if blk == BLK_WOOD {
        var y: i32 = 0;
        while y < CHUNK_DIM {
            var z: i32 = 0;
            while z < CHUNK_DIM {
                var x: i32 = 0;
                while x < CHUNK_DIM {
                    let dx = x - 7;
                    let dz = z - 7;
                    let r2 = dx * dx + dz * dz;
                    if r2 >= 28 && r2 <= 58 {
                        let doorway = if (y >= 5 && y <= 10 && (x >= 6 && x <= 9 || z >= 6 && z <= 9)) ||
                                         (y >= 2 && y <= 3 && (x == 3 || z == 12)) ||
                                         (y >= 12 && y <= 13 && (x == 12 || z == 3)) { 1 } else { 0 };
                        if doorway == 0 {
                            dst_set_block(dst, x, y, z, if (y % 4) == 0 { BLK_GRASS } else { BLK_WOOD });
                        }
                    } else if y <= 1 && r2 < 28 {
                        let shaft = if (x >= 7 && x <= 8 && z >= 7 && z <= 8) || (x >= 3 && x <= 4 && z >= 11 && z <= 12) { 1 } else { 0 };
                        if shaft == 0 { dst_set_block(dst, x, y, z, BLK_DIRT); }
                    }
                    x = x + 1;
                }
                z = z + 1;
            }
            y = y + 1;
        }
        dst_set_block(dst, 8, 2, 8, BLK_GOLD_ORE);
        dst_set_block(dst, 5, 2, 8, BLK_CRATE);
        dst_set_block(dst, 10, 2, 8, BLK_ALPHA_CUBE);
        dst_set_block(dst, 12, 2, 4, BLK_INFINITY_RED);
        return;
    }

    if blk == BLK_ICE || blk == BLK_GLASS {
        var y: i32 = 0;
        while y < CHUNK_DIM {
            var z: i32 = 0;
            while z < CHUNK_DIM {
                var x: i32 = 0;
                while x < CHUNK_DIM {
                    let rim = if x <= 1 || x >= 14 || z <= 1 || z >= 14 || y <= 1 || y >= 14 { 1 } else { 0 };
                    let win = if (x >= 5 && x <= 10 && y >= 5 && y <= 10) ||
                                 (z >= 5 && z <= 10 && y >= 5 && y <= 10) ||
                                 (x >= 5 && x <= 10 && z >= 5 && z <= 10) ||
                                 (x >= 2 && x <= 3 && y >= 12 && y <= 13) ||
                                 (z >= 12 && z <= 13 && y >= 2 && y <= 3) ||
                                 (x >= 12 && x <= 13 && z >= 12 && z <= 13) { 1 } else { 0 };
                    if rim != 0 && win == 0 {
                        dst_set_block(dst, x, y, z, if ((x + y + z) & 1) == 0 { BLK_ICE } else { BLK_GLASS });
                    }
                    x = x + 1;
                }
                z = z + 1;
            }
            y = y + 1;
        }
        dst_set_block(dst, 8, 3, 8, BLK_ICE_WORLD);
        dst_set_block(dst, 4, 2, 4, BLK_ALPHA_CUBE);
        dst_set_block(dst, 11, 2, 11, BLK_UPG_ARMOR);
        dst_set_block(dst, 13, 2, 2, BLK_GOLD_ORE);
        return;
    }

    let is_mol = is_block_molecular(blk);
    let trim_blk: u8 =
        if blk == BLK_WALL_TUT || blk == BLK_STONE { BLK_STONE }
        else if blk == BLK_GRASS || blk == BLK_DIRT { BLK_WOOD }
        else if blk == BLK_PETAL_Y || blk == BLK_POLLEN { BLK_POLLEN }
        else if blk == BLK_PETAL_W { BLK_ICE }
        else if blk == BLK_MYLANTIS || blk == BLK_TOPAZ_CHECK { BLK_ICE }
        else if blk == BLK_GOLD_ORE || blk == BLK_CRATE || blk == BLK_HAZARD_NUKE { BLK_GOLD_ORE }
        else if blk == BLK_INFINITY_RED { BLK_CORE_GATE }
        else { BLK_SAND };

    let off_a: i32 = 2 + (((ls >> 3) % 2) as! i32);
    let off_b: i32 = 12 + (((ls >> 5) % 2) as! i32);
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
                    let c_lo: i32 = if is_mol != 0 { 6 } else { 5 };
                    let c_hi: i32 = if is_mol != 0 { 9 } else { 10 };
                    let tunnel_z = if ((x >= c_lo && x <= c_hi && y >= c_lo && y <= c_hi) ||
                                       (x >= off_a && x <= off_a + 1 && y >= off_a && y <= off_a + 1) ||
                                       (x >= off_b && x <= off_b + 1 && y >= off_b && y <= off_b + 1)) &&
                                      in_x_wall == 0 && in_y_bot == 0 && in_y_top == 0 { 1 } else { 0 };
                    let tunnel_x = if ((z >= c_lo && z <= c_hi && y >= c_lo && y <= c_hi) ||
                                       (z >= off_b && z <= off_b + 1 && y >= off_a && y <= off_a + 1) ||
                                       (z >= off_a && z <= off_a + 1 && y >= off_b && y <= off_b + 1)) &&
                                      in_z_wall == 0 && in_y_bot == 0 && in_y_top == 0 { 1 } else { 0 };
                    let sky_hole = if in_y_top != 0 && ((x >= c_lo && x <= c_hi && z >= c_lo && z <= c_hi) ||
                                                        (x >= off_a && x <= off_a + 1 && z >= off_a && z <= off_a + 1) ||
                                                        (x >= off_b && x <= off_b + 1 && z >= off_b && z <= off_b + 1)) { 1 } else { 0 };
                    let pit_hole = if in_y_bot != 0 && ((x >= 7 && x <= 8 && z >= 7 && z <= 8) ||
                                                        (x >= off_b && x <= off_b + 1 && z >= off_a && z <= off_a + 1)) { 1 } else { 0 };
                    let pocket_a = if z == 0 && x >= 11 && x <= 12 && y >= 2 && y <= 3 { 1 } else { 0 };
                    let pocket_b = if x == 15 && z >= 2 && z <= 3 && y >= 11 && y <= 12 { 1 } else { 0 };

                    if tunnel_z == 0 && tunnel_x == 0 && sky_hole == 0 && pit_hole == 0 && pocket_a == 0 && pocket_b == 0 {
                        let inner_skin = if x == thick - 1 || x == CHUNK_DIM - thick || z == thick - 1 || z == CHUNK_DIM - thick || y == thick - 1 { 1 } else { 0 };
                        dst_set_block(dst, x, y, z, if inner_skin != 0 && ((x + y + z) % 3) == 0 { trim_blk } else { blk });
                    }
                }
                x = x + 1;
            }
            z = z + 1;
        }
        y = y + 1;
    }

    dst_set_block(dst, 11, 2, 1, BLK_GOLD_ORE);
    dst_set_block(dst, 14, 11, 2, BLK_TOPAZ_CHECK);

    let variant = (ls % 3) as! i32;
    if variant == 0 {
        var b: i32 = thick;
        while b <= 15 - thick {
            dst_set_block(dst, b, 4, 5, trim_blk);
            dst_set_block(dst, b, 4, 10, trim_blk);
            b = b + 1;
        }
    } else if variant == 1 {
        var py: i32 = thick;
        while py <= 11 {
            dst_set_block(dst, 4, py, 4, trim_blk);
            dst_set_block(dst, 11, py, 4, trim_blk);
            dst_set_block(dst, 4, py, 11, trim_blk);
            dst_set_block(dst, 11, py, 11, trim_blk);
            py = py + 1;
        }
    } else {
        dst_set_block(dst, 6, thick, 6, trim_blk);
        dst_set_block(dst, 9, thick, 6, trim_blk);
        dst_set_block(dst, 6, thick, 9, trim_blk);
        dst_set_block(dst, 9, thick, 9, trim_blk);
    }

    if blk == BLK_GOLD_ORE || blk == BLK_CRATE || blk == BLK_LOCKED_DOOR || blk == BLK_HAZARD_NUKE {
        dst_set_block(dst, 8, thick, 8, BLK_KEY_BLOCK);
        dst_set_block(dst, 8, thick + 1, 8, BLK_GOLD_ORE);
        dst_set_block(dst, 5, thick, 8, BLK_CRATE);
        dst_set_block(dst, 10, thick, 8, BLK_BLACK_CUBE);
    } else if blk == BLK_SPAWNER {
        dst_set_block(dst, 8, thick, 8, BLK_CORE_GATE);
    } else {
        dst_set_block(dst, 8, thick, 8, BLK_GOLD_ORE);
    }
    dst_set_block(dst, 2, 2, 1, BLK_ALPHA_CUBE);
    dst_set_block(dst, 14, 12, 12, BLK_BLACK_CUBE);
}

fn populate_generic_hollow_entities(depth: i32) {
    let _ = spawn_entity(ENT_RING_GREEN, 8.0, 8.0, 4.8, 1, -1, BLK_AIR);
    let _ = spawn_entity(ENT_RING_RED, 8.0, 12.2, 8.0, 1, -1, BLK_AIR);
    let _ = spawn_entity_ex(ENT_GOLD, 8.0, 8.0, 11.2, 1, -1, 0, 0);
    if depth >= 3 && st.genesis_mode == 0 {
        let _ = spawn_entity_ex(ENT_RAT, 5.5, 4.5, 10.5, 24 + depth * 6, -1, 0, 1);
    }
}

fn generate_air_subchunk_blocks(dst: i32, biome: i32, seed: u64, air_depth: i32) {
    var ls = splitmix64(seed);
    let mote_blk: u8 =
        if biome == BIOME_TUTORIAL || biome == BIOME_YING_FOREST { BLK_GOLD_ORE }
        else if biome == BIOME_WHITE_FLOWER { BLK_ALPHA_CUBE }
        else if biome == BIOME_YELLOW_FLOWER { BLK_POLLEN }
        else if biome == BIOME_ICE_WORLD { BLK_ICE_WORLD }
        else if biome == BIOME_DESERT_WORLD { BLK_DESERT_WORLD }
        else if biome == BIOME_MYLANTIS { BLK_ICE }
        else { BLK_BLACK_CUBE };

    if air_depth <= 1 {
        let ox: i32 = if (ls & 1) != 0 { 13 } else { 2 };
        ls = splitmix64(ls);
        let oy: i32 = if (ls & 1) != 0 { 12 } else { 2 };
        ls = splitmix64(ls);
        let oz: i32 = if (ls & 1) != 0 { 13 } else { 2 };
        dst_set_block(dst, ox, oy, oz, mote_blk);
        if biome != BIOME_SPACE {
            dst_set_block(dst, 15 - ox, 4, 15 - oz, BLK_GOLD_ORE);
        }
        return;
    }

    let num_clusters = clamp_i(2 + air_depth, 3, 5);
    var c: i32 = 0;
    while c < num_clusters {
        ls = splitmix64(ls);
        let cx = 2 + ((ls % 11) as! i32);
        ls = splitmix64(ls);
        let cy = 2 + ((ls % 11) as! i32);
        ls = splitmix64(ls);
        let cz = 2 + ((ls % 11) as! i32);

        if cx >= 6 && cx <= 9 && cy >= 6 && cy <= 9 && cz >= 6 && cz <= 9 {
            c = c + 1;
            continue;
        }

        let core_blk: u8 =
            if c == 0 { mote_blk }
            else if (c % 3) == 1 { BLK_BLACK_CUBE }
            else if (c % 3) == 2 { BLK_ALPHA_CUBE }
            else { BLK_GLASS };

        dst_set_block(dst, cx, cy, cz, core_blk);
        if air_depth >= 3 {
            let shell_blk: u8 = if (c & 1) == 0 { BLK_GLASS } else { BLK_STONE };
            dst_set_block(dst, cx + 1, cy, cz, shell_blk);
            dst_set_block(dst, cx, cy + 1, cz, shell_blk);
            if air_depth >= 4 {
                dst_set_block(dst, cx - 1, cy, cz, shell_blk);
                dst_set_block(dst, cx, cy, cz + 1, mote_blk);
            }
        }
        c = c + 1;
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
    find_clear_air_pos(gx, 8.0, gz, rx, ry, rz);
    let _ = spawn_entity(ENT_RING_GREEN, rx, ry, rz, 1, -1, BLK_AIR);
    find_clear_air_pos(3.2, 6.0, 12.2, rx, ry, rz);
    let _ = spawn_entity(ENT_RING_PINK, rx, ry, rz, 1, -1, BLK_AIR);
    find_clear_air_pos(12.5, 11.5, 3.5, rx, ry, rz);
    let _ = spawn_entity(ENT_RING_RED, rx, ry, rz, 1, -1, BLK_AIR);
    find_clear_air_pos(8.0, 5.5, 8.0, rx, ry, rz);
    let _ = spawn_entity_ex(ENT_GOLD, rx, ry, rz, 1, -1, 0, 0);
    if depth >= 4 && st.genesis_mode == 0 && (seed % 3) == 0 {
        find_clear_air_pos(4.5, 4.5, 4.5, rx, ry, rz);
        let _ = spawn_entity_ex(ENT_RAT, rx, ry, rz, 18 + depth * 4, -1, 0, 1);
    }
}

fn generate_chunk_blocks_to(dst_layer: i32, depth: i32, biome: i32, parent_blk: u8, seed: u64, air_depth: i32) {
    var i: i32 = 0;
    if dst_layer < 0 {
        while i < CHUNK_VOL { st.blocks[i] = BLK_AIR; i = i + 1; }
    } else if dst_layer == 5 {
        while i < CHUNK_VOL { st.scratch_blocks[i] = BLK_AIR; i = i + 1; }
    } else if dst_layer >= 1000 {
        let nb = dst_layer - 1000;
        if nb >= 0 && nb < MAX_NEIGHBORS {
            st.neighbor_fill[nb] = 0;
            let base = nb * CHUNK_VOL;
            while i < CHUNK_VOL { st.neighbor_blocks[base + i] = BLK_AIR; i = i + 1; }
        }
    } else if dst_layer >= 10 {
        let slot = dst_layer - 10;
        if slot >= 0 && slot < 256 {
            let base = slot * CHUNK_VOL;
            while i < CHUNK_VOL { st.inward_blocks[base + i] = BLK_AIR; i = i + 1; }
        }
    } else if dst_layer >= 0 && dst_layer < 5 {
        let base = dst_layer * CHUNK_VOL;
        while i < CHUNK_VOL { st.parent_blocks[base + i] = BLK_AIR; i = i + 1; }
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
        generate_ying_forest_blocks(dst_layer, seed);
    } else if biome == BIOME_WHITE_FLOWER {
        generate_white_flower_alpha_blocks(dst_layer, seed, parent_blk);
    } else {
        generate_interior_biome_blocks(dst_layer, biome, depth, seed);
    }

    if st.delta_head != 0 || st.deltas[0].used != 0 {
        i = 0;
        while i < MAX_DELTAS {
            if st.deltas[i].used == 0 { break; }
            if st.deltas[i].seed == seed {
                dst_set_block(dst_layer, st.deltas[i].bx, st.deltas[i].by, st.deltas[i].bz, st.deltas[i].blk);
            }
            i = i + 1;
        }
    }
}

fn get_subchunk_biome(
    parent_seed: u64, parent_depth: i32, parent_biome: i32,
    mx: i32, my: i32, mz: i32, blk: u8
) -> i32 {
    return resolve_child_frame_biome(parent_seed, parent_depth, parent_biome, mx, my, mz, blk, -1);
}

fn resolve_subchunk_slot(
    parent_seed: u64, parent_depth: i32, parent_biome: i32,
    mx: i32, my: i32, mz: i32, blk: u8
) -> i32 {
    let child_d = parent_depth + 1;
    let cseed = resolve_child_frame_seed(parent_seed, parent_depth, mx, my, mz, blk);
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
    let cbio = resolve_child_frame_biome(parent_seed, parent_depth, parent_biome, mx, my, mz, blk, -1);
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

fn axis_step_at(d: i32, top_d: i32, delta: i32, axis: i32) -> i32 {
    if delta == 0 { return 0; }
    var k: i32 = d + 1;
    while k <= top_d {
        let f = get_frame(k);
        let v = if axis == 0 { f.bx } else if axis == 1 { f.by } else { f.bz };
        if (delta < 0 && v != 0) || (delta > 0 && v != 15) {
            return 0;
        }
        k = k + 1;
    }
    return delta;
}

fn resolve_neighbor_chunk(slot: i32, dx: i32, dy: i32, dz: i32) {
    st.neighbor_valid[slot] = 0;
    st.neighbor_dx[slot] = dx;
    st.neighbor_dy[slot] = dy;
    st.neighbor_dz[slot] = dz;
    st.neighbor_dirty[slot] = 1;

    var cur_d: i32 = st.depth;
    var anc_d: i32 = st.depth - 1;
    var tbx: i32 = 0;
    var tby: i32 = 0;
    var tbz: i32 = 0;
    var cx: i32 = dx;
    var cy: i32 = dy;
    var cz: i32 = dz;
    var pbx: i32[64] = [0; 64];
    var pby: i32[64] = [0; 64];
    var pbz: i32[64] = [0; 64];
    var steps_up: i32 = 0;

    loop {
        let f = get_frame(cur_d);
        let sx = f.bx + cx;
        let sy = f.by + cy;
        let sz = f.bz + cz;
        let nbx = sx & 15;
        let nby = sy & 15;
        let nbz = sz & 15;
        cx = if sx >= 0 { sx >> 4 } else { -(((-sx) + 15) >> 4) };
        cy = if sy >= 0 { sy >> 4 } else { -(((-sy) + 15) >> 4) };
        cz = if sz >= 0 { sz >> 4 } else { -(((-sz) + 15) >> 4) };
        pbx[steps_up] = nbx;
        pby[steps_up] = nby;
        pbz[steps_up] = nbz;
        if cx == 0 && cy == 0 && cz == 0 {
            anc_d = cur_d - 1;
            tbx = nbx;
            tby = nby;
            tbz = nbz;
            break;
        }
        steps_up = steps_up + 1;
        cur_d = cur_d - 1;
        if cur_d <= MAX_NEG_DEPTH || steps_up >= 64 {
            // Cosmic boundary: mark attempted so the streaming resolver won't retry
            st.neighbor_dx[slot] = 0;
            st.neighbor_dy[slot] = 0;
            st.neighbor_dz[slot] = 0;
            st.neighbor_dirty[slot] = 0;
            return;
        }
        ensure_neg_frame_seed(cur_d);
    }

    ensure_neg_frame_seed(anc_d);
    let anc_f = get_frame(anc_d);
    let anc_air_d = compute_air_depth(anc_d);
    let p_off = st.depth - 1 - anc_d;
    var tblk: u8 = BLK_AIR;
    if p_off >= 0 && p_off < 5 && st.parent_valid[p_off] != 0 {
        tblk = st.parent_blocks[p_off * CHUNK_VOL + b_idx(tbx, tby, tbz)];
    } else {
        generate_chunk_blocks_to(5, anc_d, anc_f.biome, anc_f.parent_block, anc_f.seed, anc_air_d);
        tblk = dst_get_block(5, tbx, tby, tbz);
    }

    var rseed: u64 = resolve_child_frame_seed(anc_f.seed, anc_d, tbx, tby, tbz, tblk);
    var rbio: i32 = resolve_child_frame_biome(anc_f.seed, anc_d, anc_f.biome, tbx, tby, tbz, tblk, -1);
    var rblk: u8 = tblk;
    var rair: i32 = if tblk == BLK_AIR { anc_air_d + 1 } else { 0 };

    var step: i32 = steps_up - 1;
    var wd: i32 = cur_d + 1;
    while step >= 0 {
        let wbx = pbx[step];
        let wby = pby[step];
        let wbz = pbz[step];
        if rblk != BLK_AIR {
            generate_chunk_blocks_to(5, wd - 1, rbio, rblk, rseed, rair);
            rblk = dst_get_block(5, wbx, wby, wbz);
        }
        let nbio = resolve_child_frame_biome(rseed, wd - 1, rbio, wbx, wby, wbz, rblk, -1);
        rseed = resolve_child_frame_seed(rseed, wd - 1, wbx, wby, wbz, rblk);
        rbio = nbio;
        rair = if rblk == BLK_AIR { rair + 1 } else { 0 };
        wd = wd + 1;
        step = step - 1;
    }

    generate_chunk_blocks_to(1000 + slot, st.depth, rbio, rblk, rseed, rair);
    st.neighbor_valid[slot] = 1;
    st.neighbor_biome[slot] = rbio;
    st.neighbor_dirty[slot] = 1;
    if dx >= -3 && dx <= 3 && dy >= -3 && dy <= 3 && dz >= -3 && dz <= 3 {
        st.neighbor_map[((dx + 3) * 7 + (dy + 3)) * 7 + (dz + 3)] = slot;
    }
}

fn neighbor_slot_at_rel(dx: i32, dy: i32, dz: i32) -> i32 {
    if dx < -3 || dx > 3 || dy < -3 || dy > 3 || dz < -3 || dz > 3 { return -1; }
    let s = st.neighbor_map[((dx + 3) * 7 + (dy + 3)) * 7 + (dz + 3)];
    if s >= 0 && s < MAX_NEIGHBORS && st.neighbor_valid[s] != 0 &&
       st.neighbor_dx[s] == dx && st.neighbor_dy[s] == dy && st.neighbor_dz[s] == dz {
        return s;
    }
    return -1;
}

fn world_block_rel(bx: i32, by: i32, bz: i32) -> u8 {
    if bx >= 0 && bx < CHUNK_DIM && by >= 0 && by < CHUNK_DIM && bz >= 0 && bz < CHUNK_DIM {
        return st.blocks[b_idx(bx, by, bz)];
    }
    if bx < -48 || bx >= 64 || by < -48 || by >= 64 || bz < -48 || bz >= 64 {
        return BLK_AIR;
    }
    let ox: i32 = if bx >= 48 { 3 } else if bx >= 32 { 2 } else if bx >= CHUNK_DIM { 1 } else if bx >= 0 { 0 } else if bx >= -16 { -1 } else if bx >= -32 { -2 } else { -3 };
    let oy: i32 = if by >= 48 { 3 } else if by >= 32 { 2 } else if by >= CHUNK_DIM { 1 } else if by >= 0 { 0 } else if by >= -16 { -1 } else if by >= -32 { -2 } else { -3 };
    let oz: i32 = if bz >= 48 { 3 } else if bz >= 32 { 2 } else if bz >= CHUNK_DIM { 1 } else if bz >= 0 { 0 } else if bz >= -16 { -1 } else if bz >= -32 { -2 } else { -3 };
    let s = neighbor_slot_at_rel(ox, oy, oz);
    if s >= 0 {
        return st.neighbor_blocks[s * CHUNK_VOL + b_idx(bx - ox * 16, by - oy * 16, bz - oz * 16)];
    }
    return BLK_AIR;
}

fn load_current_chunk_impl(use_shift: i32, sdx: i32, sdy: i32, sdz: i32) {
    clear_entities_and_shots();
    invalidate_inward_cache();
    st.chunk_rev = st.chunk_rev + 1;
    st.spawner_timer_ms = 2400;

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


    // Populate 5 outward parent visibility layers (16x .. 1,048,576x) first so neighbor
    // resolution can fast-path reads directly from cached parent_blocks
    var pl: i32 = 0;
    while pl < 5 {
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

    var mi: i32 = 0;
    while mi < 343 {
        st.neighbor_map[mi] = -1;
        mi = mi + 1;
    }

    let vr = clamp_i(st.view_chunk_radius, 1, 3);
    if use_shift != 0 {
        // Preserve already-loaded chunks in-place across same-depth chunk crossings!
        var si: i32 = 0;
        while si < MAX_NEIGHBORS {
            if st.neighbor_valid[si] != 0 {
                let ndx = st.neighbor_dx[si] - sdx;
                let ndy = st.neighbor_dy[si] - sdy;
                let ndz = st.neighbor_dz[si] - sdz;
                let ax = if ndx < 0 { -ndx } else { ndx };
                let ay = if ndy < 0 { -ndy } else { ndy };
                let az = if ndz < 0 { -ndz } else { ndz };
                let mx = if ax >= ay && ax >= az { ax } else if ay >= az { ay } else { az };
                if mx >= 1 && mx <= vr {
                    st.neighbor_dx[si] = ndx;
                    st.neighbor_dy[si] = ndy;
                    st.neighbor_dz[si] = ndz;
                    st.neighbor_dirty[si] = 1;
                    st.neighbor_map[((ndx + 3) * 7 + (ndy + 3)) * 7 + (ndz + 3)] = si;
                } else {
                    st.neighbor_valid[si] = 0;
                    st.neighbor_fill[si] = 0;
                    st.neighbor_dirty[si] = 0;
                    st.neighbor_dx[si] = 0;
                    st.neighbor_dy[si] = 0;
                    st.neighbor_dz[si] = 0;
                }
            } else {
                st.neighbor_fill[si] = 0;
                st.neighbor_dirty[si] = 0;
                st.neighbor_dx[si] = 0;
                st.neighbor_dy[si] = 0;
                st.neighbor_dz[si] = 0;
            }
            si = si + 1;
        }
    } else {
        var si: i32 = 0;
        while si < MAX_NEIGHBORS {
            st.neighbor_valid[si] = 0;
            st.neighbor_fill[si] = 0;
            st.neighbor_dirty[si] = 0;
            st.neighbor_dx[si] = 0;
            st.neighbor_dy[si] = 0;
            st.neighbor_dz[si] = 0;
            si = si + 1;
        }
    }

    // Collect missing neighbor coordinates sorted by ring (1..vr) and Euclidean d2 ascending
    var mdx: i32[343] = [0; 343];
    var mdy: i32[343] = [0; 343];
    var mdz: i32[343] = [0; 343];
    var md2: i32[343] = [0; 343];
    var mring: i32[343] = [0; 343];
    var m_cnt: i32 = 0;

    var ring: i32 = 1;
    while ring <= vr {
        var odx: i32 = -ring;
        while odx <= ring {
            var ody: i32 = -ring;
            while ody <= ring {
                var odz: i32 = -ring;
                while odz <= ring {
                    let ax = if odx < 0 { -odx } else { odx };
                    let ay = if ody < 0 { -ody } else { ody };
                    let az = if odz < 0 { -odz } else { odz };
                    let mx = if ax >= ay && ax >= az { ax } else if ay >= az { ay } else { az };
                    if mx == ring {
                        let existing = st.neighbor_map[((odx + 3) * 7 + (ody + 3)) * 7 + (odz + 3)];
                        if existing < 0 && m_cnt < MAX_NEIGHBORS {
                            mdx[m_cnt] = odx;
                            mdy[m_cnt] = ody;
                            mdz[m_cnt] = odz;
                            md2[m_cnt] = odx * odx + ody * ody + odz * odz;
                            mring[m_cnt] = ring;
                            m_cnt = m_cnt + 1;
                        }
                    }
                    odz = odz + 1;
                }
                ody = ody + 1;
            }
            odx = odx + 1;
        }
        ring = ring + 1;
    }

    // Insertion sort missing slots by (ring, d2) ascending for radial loading
    var k: i32 = 1;
    while k < m_cnt {
        let kx = mdx[k];
        let ky = mdy[k];
        let kz = mdz[k];
        let kd = md2[k];
        let kr = mring[k];
        let kkey = kr * 100 + kd;
        var p: i32 = k - 1;
        while p >= 0 && (mring[p] * 100 + md2[p]) > kkey {
            mdx[p + 1] = mdx[p];
            mdy[p + 1] = mdy[p];
            mdz[p + 1] = mdz[p];
            md2[p + 1] = md2[p];
            mring[p + 1] = mring[p];
            p = p - 1;
        }
        mdx[p + 1] = kx;
        mdy[p + 1] = ky;
        mdz[p + 1] = kz;
        md2[p + 1] = kd;
        mring[p + 1] = kr;
        k = k + 1;
    }

    // Assign missing coordinates into free neighbor slots
    var free_scan: i32 = 0;
    k = 0;
    while k < m_cnt {
        while free_scan < MAX_NEIGHBORS && st.neighbor_valid[free_scan] != 0 {
            free_scan = free_scan + 1;
        }
        if free_scan >= MAX_NEIGHBORS { break; }
        if mring[k] == 1 {
            resolve_neighbor_chunk(free_scan, mdx[k], mdy[k], mdz[k]);
        } else {
            st.neighbor_valid[free_scan] = 0;
            st.neighbor_dx[free_scan] = mdx[k];
            st.neighbor_dy[free_scan] = mdy[k];
            st.neighbor_dz[free_scan] = mdz[k];
            st.neighbor_fill[free_scan] = 0;
            st.neighbor_dirty[free_scan] = 0;
        }
        free_scan = free_scan + 1;
        k = k + 1;
    }
}

fn load_current_chunk() {
    load_current_chunk_impl(0, 0, 0, 0);
}

fn load_current_chunk_shifted(sdx: i32, sdy: i32, sdz: i32) {
    load_current_chunk_impl(1, sdx, sdy, sdz);
}

// ---------------------------------------------------------------------------
// Camera-forward + radial streaming resolver for queued far-ring neighbors.
// ---------------------------------------------------------------------------
fn resolve_pending_neighbors(max_n: i32) -> i32 {
    let lim = clamp_i(max_n, 1, 24);
    let cp = fcos(st.pitch);
    let fx = cp * fcos(st.yaw);
    let fy = fsin(st.pitch);
    let fz = cp * fsin(st.yaw);

    var best_s: i32[24] = [-1; 24];
    var best_sc: f64[24] = [1.0e18; 24];
    var pick_cnt: i32 = 0;

    var s: i32 = 0;
    while s < MAX_NEIGHBORS {
        if st.neighbor_valid[s] == 0 {
            let dx = st.neighbor_dx[s];
            let dy = st.neighbor_dy[s];
            let dz = st.neighbor_dz[s];
            if dx != 0 || dy != 0 || dz != 0 {
                let ax = if dx < 0 { -dx } else { dx };
                let ay = if dy < 0 { -dy } else { dy };
                let az = if dz < 0 { -dz } else { dz };
                let rmax = if ax >= ay && ax >= az { ax } else if ay >= az { ay } else { az };
                let d2 = dx * dx + dy * dy + dz * dz;
                let inv_len = 1.0 / fsqrt(d2 as f64);
                let fdot = ((dx as f64) * fx + (dy as f64) * fy + (dz as f64) * fz) * inv_len;
                let sc = (rmax as f64) * 18.0 + (d2 as f64) * 1.5 - fdot * 16.0;
                if pick_cnt < lim {
                    var p: i32 = pick_cnt - 1;
                    while p >= 0 && best_sc[p] > sc {
                        best_s[p + 1] = best_s[p];
                        best_sc[p + 1] = best_sc[p];
                        p = p - 1;
                    }
                    best_s[p + 1] = s;
                    best_sc[p + 1] = sc;
                    pick_cnt = pick_cnt + 1;
                } else if sc < best_sc[lim - 1] {
                    var p: i32 = lim - 2;
                    while p >= 0 && best_sc[p] > sc {
                        best_s[p + 1] = best_s[p];
                        best_sc[p + 1] = best_sc[p];
                        p = p - 1;
                    }
                    best_s[p + 1] = s;
                    best_sc[p + 1] = sc;
                }
            }
        }
        s = s + 1;
    }

    var i: i32 = 0;
    while i < pick_cnt {
        let slot = best_s[i];
        resolve_neighbor_chunk(slot, st.neighbor_dx[slot], st.neighbor_dy[slot], st.neighbor_dz[slot]);
        i = i + 1;
    }
    return pick_cnt;
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
        let nseed = resolve_child_frame_seed(pf.seed, st.depth, cur_bx, cur_by, cur_bz, cur_blk);
        let nbio = resolve_child_frame_biome(pf.seed, st.depth, pf.biome, cur_bx, cur_by, cur_bz, cur_blk, cur_forced);
        st.depth = next_depth;
        if st.depth > st.max_depth_reached { st.max_depth_reached = st.depth; }
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
                generate_chunk_blocks_to(5, next_depth, nbio, cur_blk, nseed, 0);
                cur_bx = 8; cur_by = 8; cur_bz = 8;
                let probe = dst_get_block(5, cur_bx, cur_by, cur_bz);
                cur_blk = if probe != BLK_AIR { probe } else { BLK_BLACK_CUBE };
            }
            cur_forced = -1;
        }
        d = d + 1;
    }

    load_current_chunk();

    // Preserve the exact proportional entry path: search nearby open sub-voxels around
    // the entry coordinate first before falling back inward toward the chamber interior.
    if point_collides(new_px, new_py, new_pz) != 0 {
        var found_near: i32 = 0;
        var rad: i32 = 1;
        while rad <= 4 && found_near == 0 {
            let off_s = (rad as f64) * 0.85;
            var dy_i: i32 = -1;
            while dy_i <= 1 && found_near == 0 {
                var dz_i: i32 = -1;
                while dz_i <= 1 && found_near == 0 {
                    var dx_i: i32 = -1;
                    while dx_i <= 1 && found_near == 0 {
                        let tx = fclamp(new_px + (dx_i as f64) * off_s, 0.4, 15.6);
                        let ty = fclamp(new_py + (dy_i as f64) * off_s, 0.4, 15.6);
                        let tz = fclamp(new_pz + (dz_i as f64) * off_s, 0.4, 15.6);
                        if point_collides(tx, ty, tz) == 0 {
                            new_px = tx; new_py = ty; new_pz = tz;
                            found_near = 1;
                        }
                        dx_i = dx_i + 1;
                    }
                    dz_i = dz_i + 1;
                }
                dy_i = dy_i + 1;
            }
            rad = rad + 1;
        }
        if found_near == 0 {
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
                    new_px = 8.5; new_py = 9.5; new_pz = 8.5;
                }
                if point_collides(new_px, new_py, new_pz) != 0 {
                    var found_clr: i32 = 0;
                    var cy_c: i32 = 2;
                    while cy_c <= 13 && found_clr == 0 {
                        var cz_c: i32 = 2;
                        while cz_c <= 13 && found_clr == 0 {
                            var cx_c: i32 = 2;
                            while cx_c <= 13 && found_clr == 0 {
                                let tx = (cx_c as f64) + 0.5;
                                let ty = (cy_c as f64) + 0.5;
                                let tz = (cz_c as f64) + 0.5;
                                if point_collides(tx, ty, tz) == 0 {
                                    new_px = tx; new_py = ty; new_pz = tz;
                                    found_clr = 1;
                                }
                                cx_c = cx_c + 1;
                            }
                            cz_c = cz_c + 1;
                        }
                        cy_c = cy_c + 1;
                    }
                }
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
    st.autosave_dirty = 1;
    queue_sfx(SFX_WARP);
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
    if st.ring_cd_ms > 0 {
        st.px = fclamp(st.px, 0.25, 15.75);
        st.py = fclamp(st.py, 0.25, 15.75);
        st.pz = fclamp(st.pz, 0.25, 15.75);
        return;
    }
    let next_depth = st.depth - 1;
    if next_depth < MAX_NEG_DEPTH {
        st.px = fclamp(exit_x, 0.25, 15.75);
        st.py = fclamp(exit_y, 0.25, 15.75);
        st.pz = fclamp(exit_z, 0.25, 15.75);
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
        if point_collides(st.px, st.py, st.pz) != 0 {
            var found_g: i32 = 0;
            var cy_g: i32 = 2;
            while cy_g <= 13 && found_g == 0 {
                var cz_g: i32 = 2;
                while cz_g <= 13 && found_g == 0 {
                    var cx_g: i32 = 2;
                    while cx_g <= 13 && found_g == 0 {
                        let tx = (cx_g as f64) + 0.5;
                        let ty = (cy_g as f64) + 0.5;
                        let tz = (cz_g as f64) + 0.5;
                        if point_collides(tx, ty, tz) == 0 {
                            st.px = tx; st.py = ty; st.pz = tz;
                            found_g = 1;
                        }
                        cx_g = cx_g + 1;
                    }
                    cz_g = cz_g + 1;
                }
                cy_g = cy_g + 1;
            }
        }
    }

    if was_air != 0 {
        st.vx = st.vx * 0.35; st.vy = st.vy * 0.35; st.vz = st.vz * 0.35;
    } else {
        st.vx = 0.0; st.vy = 0.0; st.vz = 0.0;
    }
    st.ring_cd_ms = 260;
    st.flash_ms = 200;
    st.flash_rgb = pack_rgb(245, 70, 70);
    st.autosave_dirty = 1;
    queue_sfx(SFX_WARP);
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
    // Authentic Xar caps (manual section 9): base + global + per-weapon capacity bonuses.
    let l = st.ammo_cap_lvl - 1;
    st.max_ammo[WEP_PLASMA] = 40 + 10 * (l + st.wep_cap_lvl[WEP_PLASMA]);
    st.max_ammo[WEP_CANNON] = 100 + 5 * (l + st.wep_cap_lvl[WEP_CANNON]);
    st.max_ammo[WEP_LASER] = 32 + 8 * (l + st.wep_cap_lvl[WEP_LASER]);
    st.max_ammo[WEP_ROCKET] = 20 + 4 * (l + st.wep_cap_lvl[WEP_ROCKET]);
    st.max_ammo[WEP_HOMING] = 200 + 10 * (l + st.wep_cap_lvl[WEP_HOMING]);
    st.max_ammo[WEP_MINIGUN] = 48 + 12 * (l + st.wep_cap_lvl[WEP_MINIGUN]);
    st.max_ammo[WEP_RAILGUN] = 48 + 12 * (l + st.wep_cap_lvl[WEP_RAILGUN]);
    st.max_ammo[WEP_EMP] = 2 + l + st.wep_cap_lvl[WEP_EMP];
    st.max_ammo[WEP_NUKE] = 1 + l + st.wep_cap_lvl[WEP_NUKE];
    st.max_ammo[WEP_DARKHOLE] = 1 + l + st.wep_cap_lvl[WEP_DARKHOLE];
    var wi: i32 = 0;
    while wi < NUM_WEAPONS {
        if st.ammo[wi] > st.max_ammo[wi] { st.ammo[wi] = st.max_ammo[wi]; }
        wi = wi + 1;
    }
}

// Derived caps from B (= basic max health): max shield 25 + health level + shield_cap_lvl,
// max armor 10B. Call after any max_hp change.
fn refresh_derived() {
    st.max_shields = 25 + ((st.max_hp - 100) / 4) + st.shield_cap_lvl * 10;
    st.max_armor = 10 * st.max_hp;
    if st.shields > st.max_shields { st.shields = st.max_shields; }
    if st.armor > st.max_armor { st.armor = st.max_armor; }
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
    i = 0;
    while i < MAX_CLEARED_CHUNKS {
        st.cleared_seeds[i] = 0;
        st.cleared_masks[i] = 0;
        i = i + 1;
    }
    st.cleared_head = 0;
    st.delta_head = 0;
    st.active_marker = -1;

    st.depth = 0;
    st.max_depth_reached = 0;
    st.min_depth_reached = 0;
    set_frame(0, ScaleFrame {
        bx: 8, by: 7, bz: 8,
        biome: BIOME_TUTORIAL, parent_block: BLK_YING_PLANET, seed: 0x5841525f54555430
    });

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
    st.hp_regen = 0;            // health regen level X (manual: starts at 0)
    st.regen_accum_ms = 0;
    st.shields = 25;            // max shield = 25 + health level (25 at start)
    st.max_shields = 25;
    st.shield_regen = 0;        // reused as overheal-decay accumulator
    st.shield_accum_ms = 0;
    st.armor = 0;               // armor is only gained from pickups/buys
    st.max_armor = 1000;        // max armor = 10B (B = 100 at start)
    st.level = 1;
    st.xp = 0;
    st.gold = 40;
    st.keys = 0;
    st.kills = 0;
    st.deaths = 0;
    st.score_xp = 0;
    st.trophies = 1;
    st.trophy_mask = 1;
    st.singularity_defeated = 0;
    st.quasar_drive = 0;
    st.k_rescued = 0;
    st.telekinesis_ms = 0;
    st.black_hole_drive_ms = 0;
    st.quasar_drive_ms = 0;
    st.tome_read_mask = 0;

    st.dmg_lvl = 1;
    st.rof_lvl = 1;
    st.spd_lvl = 1;
    st.ammo_cap_lvl = 1;
    i = 0;
    while i < NUM_WEAPONS {
        st.wep_dmg_lvl[i] = 0;
        st.wep_rof_lvl[i] = 0;
        st.wep_cap_lvl[i] = 0;
        st.wep_vel_lvl[i] = 0;
        i = i + 1;
    }
    st.plasma_regen_lvl = 0;
    st.emp_rad_lvl = 0;
    st.shield_cap_lvl = 0;
    i = 0;
    while i < 40 { st.enemy_kills[i] = 0; i = i + 1; }
    st.hazard_cd_ms = 0;
    st.arcade_score = 0;
    st.arcade_timer_ms = 0;
    st.arcade_target = 0;
    st.arcade_hits = 0;
    st.arcade_active = 0;
    i = 0;
    while i < 32 { st.blk_hp_seed[i] = 0; st.blk_hp_val[i] = 0; i = i + 1; }
    st.blk_hp_head = 0;
    set_default_ammo_caps();

    st.weapon = WEP_PLASMA;
    let mode_caps: i32[10] = [ 6, 5, 4, 5, 2, 2, 4, 2, 3, 4 ];
    i = 0;
    while i < NUM_WEAPONS {
        st.wep_unlocked[i] = if i == WEP_PLASMA || st.genesis_mode != 0 { 1 } else { 0 };
        st.wep_mode[i] = 0;
        st.wep_mode_max[i] = mode_caps[i];
        i = i + 1;
    }
    st.ammo[WEP_PLASMA] = st.max_ammo[WEP_PLASMA];
    st.ammo[WEP_CANNON] = 0;    // Authentic: only plasma usable at start; other
    st.ammo[WEP_LASER] = 0;     // weapons unlock via their first upgrade & ammo
    st.ammo[WEP_ROCKET] = 0;    // comes from pickups/stations.
    st.ammo[WEP_HOMING] = 0;
    st.ammo[WEP_MINIGUN] = 0;
    st.ammo[WEP_RAILGUN] = 0;
    st.ammo[WEP_EMP] = 0;
    st.ammo[WEP_NUKE] = 0;
    st.ammo[WEP_DARKHOLE] = 0;

    st.plasma_regen_ms = 0;
    st.fire_cd_ms = 0;
    st.ring_cd_ms = 300;
    st.spawner_timer_ms = 2400;
    st.pending_sfx = -1;
    st.beam_timer_ms = 0;
    st.flash_ms = 0;
    st.near_ring_kind = ENT_NONE;
    st.near_prompt_len = 0;
    st.target_name_len = 0;
    st.tome_id = 0;
    st.play_ms = 0;
    st.dps_val = 0;
    st.dps_accum = 0;
    st.dps_timer_ms = 0;
    st.autosave_dirty = 0;

    load_current_chunk();
    if st.genesis_mode != 0 {
        set_status_msg("Genesis Mode: Shrink into any block or fly freely!", 4200);
    } else {
        set_status_msg("Tutorial: Shrink via Green Ring, or fly to the Black Cube & press [SHRK]!", 4200);
    }
}

fn respawn_at_tutorial_preserving_progress() {
    if st.icarus_mode != 0 {
        let keep_grid = st.show_chunk_grid;
        let keep_mut_m = st.mut_double_monsters;
        let keep_mut_s = st.mut_no_singleton;
        let keep_mut_k = st.mut_inf_markers;
        let keep_best = st.arcade_best;
        init_new_game();
        st.icarus_mode = 1;
        st.show_chunk_grid = keep_grid;
        st.mut_double_monsters = keep_mut_m;
        st.mut_no_singleton = keep_mut_s;
        st.mut_inf_markers = keep_mut_k;
        st.arcade_best = keep_best;
        st.deaths = 1;
        st.flash_ms = 500;
        st.flash_rgb = pack_rgb(240, 30, 40);
        queue_sfx(SFX_HURT);
        set_status_msg("ICARUS PERMADEATH: Hull lost! Entire run reset!", 4000);
        return;
    }
    // Authentic FBW death rule: lose 30 gold & Short Marker, keep armor as-is (no free grant), keep Long Markers/weapons!
    st.deaths = st.deaths + 1;
    st.gold = if st.gold >= DEATH_GOLD_PENALTY { st.gold - DEATH_GOLD_PENALTY } else { 0 };
    st.hp = st.max_hp;
    st.shields = st.max_shields;
    st.armor = 0;               // Authentic: you lose ALL armor on death
    var wi: i32 = 0;            // ...and ALL ammo except plasma (refilled)
    while wi < NUM_WEAPONS {
        st.ammo[wi] = if wi == WEP_PLASMA { st.max_ammo[WEP_PLASMA] } else { 0 };
        wi = wi + 1;
    }
    st.markers[0].used = 0;
    if st.active_marker == 0 { st.active_marker = -1; }
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
    st.autosave_dirty = 1;
    queue_sfx(SFX_HURT);
    set_status_msg("Hull destroyed! Respawned: -30 Gold, armor & ammo lost (plasma refilled).", 3600);
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
                let blk = world_block_rel(bx, by, bz);
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
    st.score_xp = st.score_xp + 50;
    queue_sfx(SFX_PICKUP);

    if blk == BLK_UPG_HP {
        st.max_hp = st.max_hp + 20;
        st.hp = st.max_hp;
        refresh_derived();
        st.shields = st.max_shields;
        set_status_msg("UPGRADE: +20 Max Health, +Shield cap & Full Heal!", 2200);
    } else if blk == BLK_UPG_REGEN {
        st.hp_regen = st.hp_regen + 1;
        st.shield_regen = st.shield_regen + 1;
        set_status_msg("UPGRADE: +1 HP & Shield Regen!", 2200);
    } else if blk == BLK_UPG_ARMOR {
        // Authentic: armor pickups bring armor UP TO a fraction of B.
        st.armor = st.max_hp;
        refresh_derived();
        st.shields = st.max_shields;
        set_status_msg("UPGRADE: Armor topped to 100% & Shields recharged!", 2200);
    } else if blk == BLK_UPG_DMG {
        let bonus: i32 = if st.depth >= 12 { 2 } else { 1 };
        st.dmg_lvl = st.dmg_lvl + bonus;
        st.wep_dmg_lvl[st.weapon] = st.wep_dmg_lvl[st.weapon] + 1;
        set_status_msg(if bonus > 1 { "BEYOND MAX UPGRADE: +40% Dmg & +Active Wep Dmg!" } else { "UPGRADE: +20% Weapon Damage!" }, 2200);
    } else if blk == BLK_UPG_ROF {
        st.rof_lvl = st.rof_lvl + 1;
        st.wep_rof_lvl[st.weapon] = st.wep_rof_lvl[st.weapon] + 1;
        set_status_msg("UPGRADE: +15% Fire Rate & Active Wep RoF!", 2200);
    } else if blk == BLK_UPG_AMMO {
        st.ammo_cap_lvl = st.ammo_cap_lvl + 1;
        st.plasma_regen_lvl = st.plasma_regen_lvl + 1;
        set_default_ammo_caps();
        st.ammo[WEP_PLASMA] = st.max_ammo[WEP_PLASMA];
        set_status_msg("UPGRADE: +Max Ammo & Faster Plasma Recharge!", 2200);
    } else if blk == BLK_UPG_SPEED {
        st.spd_lvl = st.spd_lvl + 1;
        st.wep_vel_lvl[st.weapon] = st.wep_vel_lvl[st.weapon] + 1;
        set_status_msg("UPGRADE: +12% Thrust & Projectile Velocity!", 2200);
    } else if blk == BLK_KEY_BLOCK {
        st.keys = st.keys + 1;
        set_status_msg("Picked up Vault Key!", 2000);
    } else if blk == BLK_UPG_WEP {
        let cb = cur_biome();
        if cb == BIOME_YING_FOREST || cb == BIOME_NOOB_FLOWER {
            st.wep_unlocked[WEP_CANNON] = 1;
            st.wep_unlocked[WEP_LASER] = 1;
            award_trophy_id(1, "TROPHY: Ying Forest Arsenal (Cannon & Laser)!");
        } else if cb == BIOME_WHITE_FLOWER || cb == BIOME_BETA_CUBE || cb == BIOME_YING_LIBRARY || cb == BIOME_BOTANY_LAB {
            st.wep_unlocked[WEP_MINIGUN] = 1;
            award_trophy_id(2, "TROPHY: Alpha/Botany Arsenal (6:Minigun)!");
        } else if cb == BIOME_YELLOW_FLOWER || cb == BIOME_ARCADE {
            st.wep_unlocked[WEP_ROCKET] = 1;
            st.wep_unlocked[WEP_HOMING] = 1;
            award_trophy_id(3, "TROPHY: Yellow Flower Arsenal (Rocket & Homing)!");
        } else if cb == BIOME_MYLANTIS || cb == BIOME_ICE_WORLD || cb == BIOME_DESERT_WORLD ||
                  cb == BIOME_RED_CAVES || cb == BIOME_I1_LIGHTHOUSE || cb == BIOME_BURLINGTON {
            st.wep_unlocked[WEP_RAILGUN] = 1;
            st.wep_unlocked[WEP_EMP] = 1;
            award_trophy_id(4, "TROPHY: Deep Caves Arsenal (Railgun & EMP)!");
        } else if (cb == BIOME_BLACK_CUBE || cb == BIOME_I2_MOUNTAINS || cb == BIOME_I3_ROOTS) && st.depth < 6 {
            st.wep_unlocked[WEP_RAILGUN] = 1;
            st.wep_unlocked[WEP_EMP] = 1;
            set_status_msg("MENGER MODULE: Unlocked 7:Railgun & 8:EMP!", 2400);
        } else {
            st.wep_unlocked[WEP_NUKE] = 1;
            st.wep_unlocked[WEP_DARKHOLE] = 1;
            st.wep_dmg_lvl[WEP_NUKE] = st.wep_dmg_lvl[WEP_NUKE] + 1;
            st.wep_dmg_lvl[WEP_DARKHOLE] = st.wep_dmg_lvl[WEP_DARKHOLE] + 1;
            set_status_msg("BEYOND MAX CORE ARSENAL: Unlocked Nuke & DarkHole!", 2400);
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
    var boost = if st.rocket_mode != 0 { 1.35 } else { 1.0 };
    if st.quasar_drive_ms > 0 { boost = boost * 1.85; }
    else if st.black_hole_drive_ms > 0 { boost = boost * 1.50; }
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

fn settle_post_cross_clearance(axis: i32) {
    if point_collides(st.px, st.py, st.pz) == 0 { return; }
    var tx = st.px;
    var ty = st.py;
    var tz = st.pz;
    if axis != 0 {
        if tx < 0.25 { tx = 0.26; }
        else if tx > 15.75 { tx = 15.74; }
    }
    if axis != 1 {
        if ty < 0.25 { ty = 0.26; }
        else if ty > 15.75 { ty = 15.74; }
    }
    if axis != 2 {
        if tz < 0.25 { tz = 0.26; }
        else if tz > 15.75 { tz = 15.74; }
    }
    if point_collides(tx, ty, tz) == 0 {
        st.px = tx; st.py = ty; st.pz = tz;
    }
}

fn step_air_single_axis(axis: i32, sdir: i32, cand_x: f64, cand_y: f64, cand_z: f64) -> i32 {
    let sdx: i32 = if axis == 0 { sdir } else { 0 };
    let sdy: i32 = if axis == 1 { sdir } else { 0 };
    let sdz: i32 = if axis == 2 { sdir } else { 0 };

    // Pass 1: Locate in-bounds ancestor voxel using exact axis_step_at carry/borrow
    var cur_d: i32 = st.depth;
    var anc_d: i32 = st.depth - 1;
    var target_bx: i32 = 0;
    var target_by: i32 = 0;
    var target_bz: i32 = 0;

    loop {
        let f = get_frame(cur_d);
        let nbx = f.bx + axis_step_at(cur_d, st.depth, sdx, 0);
        let nby = f.by + axis_step_at(cur_d, st.depth, sdy, 1);
        let nbz = f.bz + axis_step_at(cur_d, st.depth, sdz, 2);
        if nbx >= 0 && nbx < CHUNK_DIM && nby >= 0 && nby < CHUNK_DIM && nbz >= 0 && nbz < CHUNK_DIM {
            anc_d = cur_d - 1;
            target_bx = nbx;
            target_by = nby;
            target_bz = nbz;
            break;
        }
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
    generate_chunk_blocks_to(5, anc_d, anc_f.biome, anc_f.parent_block, anc_f.seed, anc_air_d);
    let tblk = dst_get_block(5, target_bx, target_by, target_bz);

    let nx_w = fclamp(if axis == 0 { cand_x - sdir * 16.0 } else { cand_x }, 0.04, 15.96);
    let ny_w = fclamp(if axis == 1 { cand_y - sdir * 16.0 } else { cand_y }, 0.04, 15.96);
    let nz_w = fclamp(if axis == 2 { cand_z - sdir * 16.0 } else { cand_z }, 0.04, 15.96);

    if tblk == BLK_AIR {
        var run_seed: u64 = resolve_child_frame_seed(anc_f.seed, anc_d, target_bx, target_by, target_bz, BLK_AIR);
        var run_bio: i32 = resolve_child_frame_biome(anc_f.seed, anc_d, anc_f.biome, target_bx, target_by, target_bz, BLK_AIR, -1);
        var run_air_d: i32 = anc_air_d + 1;
        var wd: i32 = cur_d + 1;
        while wd <= st.depth {
            let wf = get_frame(wd);
            let wbx = (wf.bx + axis_step_at(wd, st.depth, sdx, 0) + CHUNK_DIM) & 15;
            let wby = (wf.by + axis_step_at(wd, st.depth, sdy, 1) + CHUNK_DIM) & 15;
            let wbz = (wf.bz + axis_step_at(wd, st.depth, sdz, 2) + CHUNK_DIM) & 15;
            let nbio = resolve_child_frame_biome(run_seed, wd - 1, run_bio, wbx, wby, wbz, BLK_AIR, -1);
            run_seed = resolve_child_frame_seed(run_seed, wd - 1, wbx, wby, wbz, BLK_AIR);
            run_bio = nbio;
            run_air_d = run_air_d + 1;
            wd = wd + 1;
        }

        generate_chunk_blocks_to(5, st.depth, run_bio, BLK_AIR, run_seed, run_air_d);
        if scratch_point_collides(nx_w, ny_w, nz_w) != 0 {
            return 0;
        }

        // Atomic Commit Pass 2 preserving per-level biome & seed hierarchy
        var cseed: u64 = resolve_child_frame_seed(anc_f.seed, anc_d, target_bx, target_by, target_bz, BLK_AIR);
        var cbio: i32 = resolve_child_frame_biome(anc_f.seed, anc_d, anc_f.biome, target_bx, target_by, target_bz, BLK_AIR, -1);
        set_frame(cur_d, ScaleFrame {
            bx: target_bx, by: target_by, bz: target_bz,
            biome: cbio, parent_block: BLK_AIR, seed: cseed
        });
        wd = cur_d + 1;
        while wd <= st.depth {
            let wf = get_frame(wd);
            let wbx = (wf.bx + axis_step_at(wd, st.depth, sdx, 0) + CHUNK_DIM) & 15;
            let wby = (wf.by + axis_step_at(wd, st.depth, sdy, 1) + CHUNK_DIM) & 15;
            let wbz = (wf.bz + axis_step_at(wd, st.depth, sdz, 2) + CHUNK_DIM) & 15;
            let nbio = resolve_child_frame_biome(cseed, wd - 1, cbio, wbx, wby, wbz, BLK_AIR, -1);
            cseed = resolve_child_frame_seed(cseed, wd - 1, wbx, wby, wbz, BLK_AIR);
            cbio = nbio;
            set_frame(wd, ScaleFrame {
                bx: wbx, by: wby, bz: wbz,
                biome: cbio, parent_block: BLK_AIR, seed: cseed
            });
            wd = wd + 1;
        }

        load_current_chunk_shifted(sdx, sdy, sdz);
        st.px = nx_w;
        st.py = ny_w;
        st.pz = nz_w;
        settle_post_cross_clearance(axis);
        return 1;
    }

    let scale_diff = st.depth - anc_d;
    let mol_locked = if is_block_molecular(tblk) != 0 && st.shrink_any == 0 && scale_diff < 2 { 1 } else { 0 };
    if is_block_subdivisible(tblk) != 0 || (st.shrink_any != 0 && st.ring_cd_ms <= 0) {
        var top_seed: u64 = resolve_child_frame_seed(anc_f.seed, anc_d, target_bx, target_by, target_bz, tblk);
        var top_bio: i32 = resolve_child_frame_biome(anc_f.seed, anc_d, anc_f.biome, target_bx, target_by, target_bz, tblk, -1);

        if cur_d == st.depth {
            generate_chunk_blocks_to(5, st.depth, top_bio, tblk, top_seed, 0);
            if scratch_point_collides(nx_w, ny_w, nz_w) == 0 {
                set_frame(cur_d, ScaleFrame {
                    bx: target_bx, by: target_by, bz: target_bz,
                    biome: top_bio, parent_block: tblk, seed: top_seed
                });
                load_current_chunk_shifted(sdx, sdy, sdz);
                st.px = nx_w;
                st.py = ny_w;
                st.pz = nz_w;
                settle_post_cross_clearance(axis);
                st.flash_ms = 120;
                st.flash_rgb = pack_rgb(40, 235, 130);
                set_status_msg("Crossed into adjacent fractal chunk!", 1200);
                return 1;
            } else if mol_locked != 0 {
                if st.msg_ms <= 0 {
                    set_status_msg("Molecular block! Shrink smaller (SHRK) to reveal inner paths.", 1500);
                }
                return 0;
            }
            if st.shrink_any != 0 && st.ring_cd_ms <= 0 {
                set_frame(cur_d, ScaleFrame {
                    bx: target_bx, by: target_by, bz: target_bz,
                    biome: top_bio, parent_block: tblk, seed: top_seed
                });
                load_current_chunk_shifted(sdx, sdy, sdz);
                var sx: f64 = 8.0;
                var sy: f64 = 8.0;
                var sz: f64 = 8.0;
                find_clear_air_pos(nx_w, ny_w, nz_w, sx, sy, sz);
                st.px = sx;
                st.py = sy;
                st.pz = sz;
                settle_post_cross_clearance(axis);
                st.ring_cd_ms = 180;
                set_status_msg("ShrinkAny passed through solid wall!", 1400);
                return 1;
            }
        } else {
            var rseed: u64 = top_seed;
            var rbio: i32 = top_bio;
            var rblk: u8 = tblk;
            var rair: i32 = 0;
            var wd: i32 = cur_d + 1;
            while wd <= st.depth {
                let wf = get_frame(wd);
                let wbx = (wf.bx + axis_step_at(wd, st.depth, sdx, 0) + CHUNK_DIM) & 15;
                let wby = (wf.by + axis_step_at(wd, st.depth, sdy, 1) + CHUNK_DIM) & 15;
                let wbz = (wf.bz + axis_step_at(wd, st.depth, sdz, 2) + CHUNK_DIM) & 15;
                if rblk != BLK_AIR {
                    generate_chunk_blocks_to(5, wd - 1, rbio, rblk, rseed, rair);
                    rblk = dst_get_block(5, wbx, wby, wbz);
                }
                let nbio = resolve_child_frame_biome(rseed, wd - 1, rbio, wbx, wby, wbz, rblk, -1);
                rseed = resolve_child_frame_seed(rseed, wd - 1, wbx, wby, wbz, rblk);
                rbio = nbio;
                rair = if rblk == BLK_AIR { rair + 1 } else { 0 };
                wd = wd + 1;
            }
            generate_chunk_blocks_to(5, st.depth, rbio, rblk, rseed, rair);
            let clear_dst = scratch_point_collides(nx_w, ny_w, nz_w) == 0;
            if clear_dst || (st.shrink_any != 0 && st.ring_cd_ms <= 0) {
                var cseed: u64 = top_seed;
                var cbio: i32 = top_bio;
                var cblk: u8 = tblk;
                var cair: i32 = 0;
                set_frame(cur_d, ScaleFrame {
                    bx: target_bx, by: target_by, bz: target_bz,
                    biome: cbio, parent_block: tblk, seed: cseed
                });
                wd = cur_d + 1;
                while wd <= st.depth {
                    let wf = get_frame(wd);
                    let wbx = (wf.bx + axis_step_at(wd, st.depth, sdx, 0) + CHUNK_DIM) & 15;
                    let wby = (wf.by + axis_step_at(wd, st.depth, sdy, 1) + CHUNK_DIM) & 15;
                    let wbz = (wf.bz + axis_step_at(wd, st.depth, sdz, 2) + CHUNK_DIM) & 15;
                    if cblk != BLK_AIR {
                        generate_chunk_blocks_to(5, wd - 1, cbio, cblk, cseed, cair);
                        cblk = dst_get_block(5, wbx, wby, wbz);
                    }
                    let nbio = resolve_child_frame_biome(cseed, wd - 1, cbio, wbx, wby, wbz, cblk, -1);
                    cseed = resolve_child_frame_seed(cseed, wd - 1, wbx, wby, wbz, cblk);
                    cbio = nbio;
                    cair = if cblk == BLK_AIR { cair + 1 } else { 0 };
                    set_frame(wd, ScaleFrame {
                        bx: wbx, by: wby, bz: wbz,
                        biome: cbio, parent_block: cblk, seed: cseed
                    });
                    wd = wd + 1;
                }
                load_current_chunk_shifted(sdx, sdy, sdz);
                if clear_dst {
                    st.px = nx_w;
                    st.py = ny_w;
                    st.pz = nz_w;
                } else {
                    var sx: f64 = 8.0;
                    var sy: f64 = 8.0;
                    var sz: f64 = 8.0;
                    find_clear_air_pos(nx_w, ny_w, nz_w, sx, sy, sz);
                    st.px = sx;
                    st.py = sy;
                    st.pz = sz;
                    st.ring_cd_ms = 180;
                    set_status_msg("ShrinkAny passed through solid wall!", 1400);
                }
                settle_post_cross_clearance(axis);
                return 1;
            }
        }
    }

    if st.msg_ms <= 0 {
        set_status_msg("Solid wall jamb — steer into a 3D hole or press [SHRK]!", 1200);
    }
    return 0;
}

fn move_player_vec(dx: f64, dy: f64, dz: f64) {
    let max_d = fmax(fabs(dx), fmax(fabs(dy), fabs(dz)));
    let n_steps = clamp_i(((max_d / 0.18) as! i32) + 1, 1, 32);
    let sx = dx / (n_steps as f64);
    let sy = dy / (n_steps as f64);
    let sz = dz / (n_steps as f64);

    let start_depth = st.depth;
    let start_seed = cur_seed();
    var step_i: i32 = 0;

    while step_i < n_steps {
        // Xar: leaving a structure NEVER forces a size change — the world extends laterally
        // at the same scale (growing after the Tutorial is optional; rings are the only
        // size-change mechanism), so boundary shifts are allowed at every depth.
        let can_cross: i32 = 1;
        let nx = st.px + sx;
        if can_cross != 0 && (nx < 0.0 || nx >= 16.0) {
            let sdir: i32 = if nx < 0.0 { -1 } else { 1 };
            if step_air_single_axis(0, sdir, nx, st.py, st.pz) != 0 { return; }
            let clx = fclamp(st.px, 0.25, 15.75);
            if point_collides(clx, st.py, st.pz) == 0 { st.px = clx; }
            st.vx = 0.0;
        } else if point_collides(nx, st.py, st.pz) == 0 {
            st.px = nx;
        } else {
            if check_touch_special_block(nx + (if sx > 0.0 { 0.25 } else { -0.25 }), st.py, st.pz) == 2 { return; }
            st.vx = 0.0;
        }

        let ny = st.py + sy;
        if can_cross != 0 && (ny < 0.0 || ny >= 16.0) {
            let sdir: i32 = if ny < 0.0 { -1 } else { 1 };
            if step_air_single_axis(1, sdir, st.px, ny, st.pz) != 0 { return; }
            let cly = fclamp(st.py, 0.25, 15.75);
            if point_collides(st.px, cly, st.pz) == 0 { st.py = cly; }
            st.vy = 0.0;
        } else if point_collides(st.px, ny, st.pz) == 0 {
            st.py = ny;
        } else {
            if check_touch_special_block(st.px, ny + (if sy > 0.0 { 0.25 } else { -0.25 }), st.pz) == 2 { return; }
            st.vy = 0.0;
        }

        let nz = st.pz + sz;
        if can_cross != 0 && (nz < 0.0 || nz >= 16.0) {
            let sdir: i32 = if nz < 0.0 { -1 } else { 1 };
            if step_air_single_axis(2, sdir, st.px, st.py, nz) != 0 { return; }
            let clz = fclamp(st.pz, 0.25, 15.75);
            if point_collides(st.px, st.py, clz) == 0 { st.pz = clz; }
            st.vz = 0.0;
        } else if point_collides(st.px, st.py, nz) == 0 {
            st.pz = nz;
        } else {
            if check_touch_special_block(st.px, st.py, nz + (if sz > 0.0 { 0.25 } else { -0.25 })) == 2 { return; }
            st.vz = 0.0;
        }

        if st.depth != start_depth || cur_seed() != start_seed {
            return;
        }
        if st.depth <= 0 && cur_parent_block() != BLK_AIR {
            if st.px < 0.0 || st.px >= 16.0 || st.py < 0.0 || st.py >= 16.0 || st.pz < 0.0 || st.pz >= 16.0 {
                // Safety net only (Xar never force-grows at a boundary): squeeze back in-bounds
                st.px = fclamp(st.px, 0.25, 15.75);
                st.py = fclamp(st.py, 0.25, 15.75);
                st.pz = fclamp(st.pz, 0.25, 15.75);
                st.vx = 0.0; st.vy = 0.0; st.vz = 0.0;
                return;
            }
        }
        step_i = step_i + 1;
    }
}

fn damage_player(dmg_in: i32) {
    if st.screen != SCREEN_PLAY { return; }
    var dmg: i32 = dmg_in;
    queue_sfx(SFX_HURT);
    if st.shields > 0 && dmg > 0 {
        let sab = if st.shields >= dmg { dmg } else { st.shields };
        st.shields = st.shields - sab;
        dmg = dmg - sab;
    }
    if dmg > 0 {
        // Authentic split (manual 7.4): shield first, then 75% armor / 25% health
        // while health <= basic max; 100% health when overhealed above basic max.
        var to_health: i32 = (dmg + 3) / 4;
        var to_armor: i32 = dmg - to_health;
        if st.hp > st.max_hp {
            to_armor = 0;
            to_health = dmg;
        }
        let absorbed = if st.armor >= to_armor { to_armor } else { st.armor };
        st.armor = st.armor - absorbed;
        dmg = to_health + to_armor - absorbed;
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
        let _ = spawn_entity(ENT_AMMO, cx + 0.25, cy, cz, WEP_PLASMA + 1, -1, 0);   // plasma refill box
        st.score_xp = st.score_xp + 20;
        queue_sfx(SFX_EXPLODE);
        set_status_msg("Crate smashed! Gold & Ammo dropped.", 1400);
    } else if b == BLK_GOLD_ORE {
        let _ = spawn_entity(ENT_GOLD, cx, cy, cz, 1, -1, 0);
        add_gold(15);
        st.score_xp = st.score_xp + 30;
        queue_sfx(SFX_PICKUP);
        set_status_msg("Gold Ore mined! +15 Gold!", 1400);
    } else if b == BLK_SPAWNER {
        let _ = spawn_entity(ENT_GOLD, cx, cy, cz, 1, -1, 0);
        let _ = spawn_entity(ENT_ARMOR, cx, cy + 0.2, cz, 1, -1, 0);
        st.kills = st.kills + 1;
        st.score_xp = st.score_xp + 100;
        queue_sfx(SFX_EXPLODE);
        set_status_msg("Spawner destroyed! +100 XP", 1500);
    } else if b == BLK_MYSTERY_Q {
        st.score_xp = st.score_xp + 80;
        queue_sfx(SFX_PICKUP);
        let roll = rng_u32() % 4;
        if roll == 0 {
            let _ = spawn_entity(ENT_KEY, cx, cy, cz, 1, -1, 0);
            set_status_msg("Mystery [?] revealed a Vault Key!", 1600);
        } else {
            add_gold(25);
            let _ = spawn_entity(ENT_AMMO, cx, cy, cz, WEP_PLASMA + 1, -1, 0);   // plasma refill
            let _ = spawn_entity(ENT_HEALTH, cx + 0.2, cy, cz, 2, -1, 0);        // medium health
            set_status_msg("Mystery [?] Prize! +25 Gold & Supplies!", 1600);
        }
    } else if b == BLK_HAZARD_NUKE {
        st.score_xp = st.score_xp + 60;
        queue_sfx(SFX_PICKUP);
        st.wep_unlocked[WEP_ROCKET] = 1;
        st.ammo[WEP_ROCKET] = clamp_i(st.ammo[WEP_ROCKET] + 4, 0, st.max_ammo[WEP_ROCKET]);
        if cur_biome() == BIOME_INNER_CORE || (cur_biome() == BIOME_BLACK_CUBE && st.depth >= 6) {
            st.wep_unlocked[WEP_NUKE] = 1;
            st.ammo[WEP_NUKE] = clamp_i(st.ammo[WEP_NUKE] + 1, 0, st.max_ammo[WEP_NUKE]);
            set_status_msg("Hazard Cache: +1 Nuke & +4 Rockets!", 1600);
        } else {
            let _ = spawn_entity(ENT_AMMO, cx, cy, cz, WEP_ROCKET + 1, -1, 0);   // rocket box
            set_status_msg("Hazard Cache: +4 Rockets & Ammo!", 1600);
        }
    } else if b == BLK_TOPAZ_CHECK {
        st.score_xp = st.score_xp + 120;
        add_gold(25);
        let _ = spawn_entity(ENT_GOLD, cx, cy, cz, 1, -1, 0);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Topaz Mineral mined! +25 Gold & +120 XP!", 1600);
    } else if b == BLK_CRYSTAL_CYAN || b == BLK_CRYSTAL_PURPLE {
        st.score_xp = st.score_xp + 75;
        add_gold(18);
        let _ = spawn_entity(ENT_HEALTH, cx, cy, cz, 6, -1, 0); // shield charge
        queue_sfx(SFX_PICKUP);
        set_status_msg("Crystal cluster harvested! +18 Gold & Shield orb!", 1400);
    }
}

fn damage_block_at(bx: i32, by: i32, bz: i32, dmg_in: i32) {
    let b = get_block(bx, by, bz);
    if is_block_destructible(b) == 0 { return; }
    if b != BLK_TOPAZ_CHECK && b != BLK_SPAWNER {
        break_block_at(bx, by, bz);
        return;
    }
    let sd = cur_seed();
    var slot: i32 = -1;
    var i: i32 = 0;
    while i < 32 {
        if st.blk_hp_seed[i] == sd && st.blk_hp_x[i] == bx && st.blk_hp_y[i] == by && st.blk_hp_z[i] == bz && st.blk_hp_val[i] > 0 {
            slot = i;
            break;
        }
        i = i + 1;
    }
    if slot < 0 {
        slot = st.blk_hp_head;
        st.blk_hp_head = (st.blk_hp_head + 1) % 32;
        st.blk_hp_seed[slot] = sd;
        st.blk_hp_x[slot] = bx;
        st.blk_hp_y[slot] = by;
        st.blk_hp_z[slot] = bz;
        st.blk_hp_val[slot] = if b == BLK_TOPAZ_CHECK { 120 } else { 80 };
    }
    let eff = if dmg_in > 0 { dmg_in } else { 24 };
    st.blk_hp_val[slot] = st.blk_hp_val[slot] - eff;
    spawn_burst((bx as f64) + 0.5, (by as f64) + 0.5, (bz as f64) + 0.5, block_base_rgb(b), 5);
    if st.blk_hp_val[slot] <= 0 {
        st.blk_hp_val[slot] = 0;
        st.blk_hp_seed[slot] = 0;
        break_block_at(bx, by, bz);
    } else {
        queue_sfx(SFX_CLICK);
    }
}

fn damage_entity(idx: i32, dmg: i32, stun_ms: i32) {
    if st.entities[idx].active == 0 { return; }
    let k = st.entities[idx].kind;
    if is_enemy_kind(k) == 0 { return; }
    st.dps_accum = st.dps_accum + dmg;
    if stun_ms > 0 && is_enemy_freeze_immune(k) == 0 {
        let eff_stun = if st.entities[idx].freeze_ms > 0 { stun_ms / 2 } else { stun_ms };
        if eff_stun > st.entities[idx].freeze_ms {
            st.entities[idx].freeze_ms = eff_stun;
        }
    }
    st.entities[idx].hp = st.entities[idx].hp - dmg;
    spawn_burst(st.entities[idx].x, st.entities[idx].y, st.entities[idx].z, pack_rgb(255, 110, 60), 6);
    if st.entities[idx].hp <= 0 {
        st.entities[idx].active = 0;
        st.kills = st.kills + 1;
        if k >= 0 && k < 40 {
            st.enemy_kills[k] = st.enemy_kills[k] + 1;
        }
        let base_xp: i32 =
            if k == ENT_SINGULARITY { 2000 }
            else if k == ENT_TON618_BOSS { 3500 }
            else if k == ENT_HYDRA { 180 }
            else if k == ENT_GUARDIAN || k == ENT_VULCAN { 120 }
            else if k == ENT_BURLY || k == ENT_ROCKET_SPIDER { 85 }
            else if k == ENT_HEX_SENTRY || k == ENT_BEHOLDER { 70 }
            else if k == ENT_MENACE { 60 }
            else if k == ENT_DEMON || k == ENT_SLIVER { 45 }
            else if k == ENT_YINYANG || k == ENT_GROWER { 32 }
            else if k == ENT_PIRATE || k == ENT_LAMPREY { 26 }
            else if k == ENT_MARINE || k == ENT_ARCADE_DRONE { 24 }
            else if k == ENT_GOON || k == ENT_TWEEDLE { 16 }
            else if k == ENT_SPIDER || k == ENT_SHRINKER { 14 }
            else { 12 };
        award_xp(base_xp + (if st.depth > 0 { st.depth * 5 } else { 0 }));
        mark_entity_cleared(cur_seed(), st.entities[idx].slot_id);
        let ex = st.entities[idx].x;
        let ey = st.entities[idx].y;
        let ez = st.entities[idx].z;
        spawn_burst(ex, ey, ez, pack_rgb(255, 210, 70), 14);
        let _ = spawn_entity(ENT_GOLD, ex, ey, ez, 1, -1, 0);
        if k == ENT_GOON || k == ENT_MARINE || k == ENT_PIRATE || k == ENT_HEX_SENTRY || k == ENT_ARCADE_DRONE {
            let _ = spawn_entity(ENT_AMMO, ex + 0.25, ey, ez, 1 + ((rng_u32() % 6) as! i32), -1, 0);
        }
        if k == ENT_SINGULARITY {
            st.singularity_defeated = 1;
            st.quasar_drive = 1;
            st.autosave_dirty = 1;
            add_gold(500);
            let _ = spawn_entity(ENT_ARMOR, ex + 0.4, ey, ez, 3, -1, 0);   // gold armor (2B)
            let _ = spawn_entity(ENT_HEALTH, ex - 0.4, ey, ez, 4, -1, 0);  // health to 2B
            award_trophy_id(5, "TROPHY: THE SINGULARITY DEFEATED! Quasar Drive Unlocked — Rescue [K]!");
        } else if k == ENT_TON618_BOSS {
            st.quasar_drive = 1;
            st.autosave_dirty = 1;
            add_gold(1200);
            let _ = spawn_entity(ENT_ARMOR, ex + 0.4, ey, ez, 5, -1, 0);   // jade armor (10B)
            let _ = spawn_entity(ENT_HEALTH, ex - 0.4, ey, ez, 5, -1, 0);  // megahealth (5B)
            award_trophy_id(7, "TROPHY: TON 618 SUPERMASSIVE CONQUERED! Jade Armor & Quasar!");
        } else if (rng_u32() % 3) == 0 {
            let tier = 1 + (rng_u32() % 3) as! i32;   // small / medium / to-full
            let _ = spawn_entity(ENT_HEALTH, ex + 0.3, ey, ez, tier, -1, 0);
        }
    }
}

// Freeze Ray style stacking freeze (manual 9.4: re-hits extend freeze time).
fn stack_freeze(idx: i32, add_ms: i32) {
    if is_enemy_freeze_immune(st.entities[idx].kind) != 0 { return; }
    st.entities[idx].freeze_ms = clamp_i(st.entities[idx].freeze_ms + add_ms, 0, 20000);
}

// Unified shot detonation (manual 9.5-9.11). Returns 1 if an AoE consumed the
// shot, 0 when the weapon has no explosion (shot fizzles / direct damage only).
fn shot_explode(x: f64, y: f64, z: f64, sw: i32, smode: i32, sdmg: i32, rgb: u32, exclude_idx: i32) -> i32 {
    if sw == WEP_ROCKET {
        if smode == 3 || smode == 4 { return 0; }   // Kinetic & Progressive: no explosion
        let rad = if smode == 2 { 5.2 } else { 2.6 };
        explosion_at(x, y, z, rad, sdmg / 2, 0, 0, rgb, exclude_idx, 0);   // splash = 1/2 direct dmg
        return 1;
    }
    if sw == WEP_HOMING {
        explosion_at(x, y, z, 2.6, sdmg / 2, 0, 0, rgb, exclude_idx, 0);
        return 1;
    }
    if sw == WEP_EMP {
        explosion_at(x, y, z, 7.0 + (st.emp_rad_lvl as f64) * 1.2, sdmg, 4000, 0, rgb, exclude_idx, 0);
        return 1;
    }
    if sw == WEP_NUKE {
        let rad = if smode == 1 { 10.4 } else { 5.2 };
        explosion_at(x, y, z, rad, sdmg, 0, 0, rgb, exclude_idx, 0);
        return 1;
    }
    if sw == WEP_DARKHOLE {
        explosion_at(x, y, z, 6.5, sdmg, 0, 1, rgb, exclude_idx, 1);   // 2D, D/2, D/3... + pull
        return 1;
    }
    return 0;
}

fn explosion_at(x: f64, y: f64, z: f64, rad: f64, dmg: i32, stun_ms: i32, pull_in: i32, rgb: u32, exclude_idx: i32, dark_chain: i32) {
    spawn_burst(x, y, z, rgb, 18);
    queue_sfx(if stun_ms > 0 { SFX_EMP } else { SFX_EXPLODE });
    var i: i32 = 0;
    while i < MAX_ENTITIES {
        if i != exclude_idx && st.entities[i].active != 0 && is_enemy_kind(st.entities[i].kind) != 0 {
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
                var eff_dmg: i32 = dmg;
                if dark_chain != 0 {
                    // Dark Hole chain (manual 9.11): direct 2D, then D/2, D/3, D/4 ...
                    var rank: i32 = 0;
                    var j: i32 = 0;
                    while j < MAX_ENTITIES {
                        if j != i && st.entities[j].active != 0 && is_enemy_kind(st.entities[j].kind) != 0 {
                            let jx = st.entities[j].x - x;
                            let jy = st.entities[j].y - y;
                            let jz = st.entities[j].z - z;
                            let jd = fsqrt(jx * jx + jy * jy + jz * jz);
                            if jd <= d { rank = rank + 1; }
                        }
                        j = j + 1;
                    }
                    eff_dmg = if rank == 0 { dmg * 2 } else { ((dmg as f64) / ((rank + 1) as f64)) as! i32 };
                }
                damage_entity(i, eff_dmg, stun_ms);
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
                if bx >= 0 && bx < 16 && by >= 0 && by < 16 && bz >= 0 && bz < 16 {
                    if is_block_destructible(get_block(bx, by, bz)) != 0 {
                        damage_block_at(bx, by, bz, if dmg > 0 { dmg } else { 50 });
                    }
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

fn cycle_weapon_mode() {
    let w = st.weapon;
    if st.wep_unlocked[w] == 0 {
        set_status_msg("Weapon locked!", 1200);
        return;
    }
    let mmax = if st.wep_mode_max[w] > 0 { st.wep_mode_max[w] } else { 1 };
    st.wep_mode[w] = (st.wep_mode[w] + 1) % mmax;
    queue_sfx(SFX_CLICK);
    set_status_msg(weapon_mode_name(w, st.wep_mode[w]), 1200);
}

fn fire_weapon(secondary: i32) {
    if st.fire_cd_ms > 0 { return; }
    let w = st.weapon;
    if st.wep_unlocked[w] == 0 {
        set_status_msg("Weapon locked! Get any upgrade for it (pickups / Upgrade Station).", 1400);
        return;
    }
    let mmax = if st.wep_mode_max[w] > 0 { st.wep_mode_max[w] } else { 1 };
    let mode = if secondary != 0 { (st.wep_mode[w] + 1) % mmax } else { st.wep_mode[w] };

    var dx: f64 = 0.0;
    var dy: f64 = 0.0;
    var dz: f64 = 0.0;
    camera_forward(dx, dy, dz);

    let rof_mul = 1.0 / (1.0 + 0.15 * (((st.rof_lvl - 1) + st.wep_rof_lvl[w]) as f64));
    let dmg_mul = 1.0 + 0.20 * (((st.dmg_lvl - 1) + st.wep_dmg_lvl[w]) as f64);
    let vel_mul = 1.0 + 0.15 * (st.wep_vel_lvl[w] as f64);

    // Per-weapon per-mode ammo cost (authentic Xar manual, section 9).
    var cost: i32 = 1;
    if w == WEP_PLASMA {
        cost = if mode == 1 { 8 } else if mode == 2 { 100 } else if mode == 3 { 48 } else if mode == 4 { 200 } else if mode == 5 { 50 } else { 1 };
    } else if w == WEP_LASER {
        cost = if mode == 3 { 8 } else if mode == 0 { 1 } else { 2 };
    } else if w == WEP_ROCKET {
        cost = if mode == 1 { 3 } else if mode == 2 { 2 } else if mode == 4 { 3 } else { 1 };
    } else if w == WEP_HOMING {
        cost = if mode == 0 { 20 } else { 10 };
    } else if w == WEP_RAILGUN {
        cost = if mode == 1 { 2 } else { 1 };
    } else if w == WEP_DARKHOLE {
        cost = if mode == 2 { 20 } else if mode == 3 { 60 } else { 1 };
    }
    if st.ammo[w] < cost {
        set_status_msg("Not enough ammo for that mode!", 1000);
        return;
    }
    st.ammo[w] = st.ammo[w] - cost;

    if w == WEP_PLASMA {
        if mode == 1 {
            // Rapid Fire: 8 shots at once, each 1/2 the Basic damage.
            st.fire_cd_ms = (190.0 * rof_mul) as! i32;
            queue_sfx(SFX_PLASMA);
            let dmg = (12.0 * dmg_mul) as! i32;
            var s: i32 = 0;
            while s < 8 {
                let syaw = st.yaw + ((s as f64) - 3.5) * 0.055;
                let spitch = st.pitch + ((if (s & 1) == 0 { 1 } else { -1 }) as f64) * 0.02;
                let cp = fcos(spitch);
                let sx = cp * fcos(syaw);
                let sy = fsin(spitch);
                let sz = cp * fsin(syaw);
                spawn_shot(1, w, 1, st.px + sx * 0.4, st.py + sy * 0.4, st.pz + sz * 0.4,
                    sx * 20.0, sy * 20.0, sz * 20.0, dmg, 1100, pack_rgb(96, 245, 255));
                s = s + 1;
            }
        } else if mode == 2 {
            // Plasma Shotgun: 20 pellets, each 5x the Basic damage (100x total).
            st.fire_cd_ms = (1500.0 * rof_mul) as! i32;
            queue_sfx(SFX_PLASMA);
            let dmg = (120.0 * dmg_mul) as! i32;
            var s: i32 = 0;
            while s < 20 {
                let syaw = st.yaw + ((s as f64) - 9.5) * 0.05;
                let spitch = st.pitch + ((if (s & 1) == 0 { 1 } else { -1 }) as f64) * 0.03;
                let cp = fcos(spitch);
                let sx = cp * fcos(syaw);
                let sy = fsin(spitch);
                let sz = cp * fsin(syaw);
                spawn_shot(1, w, 2, st.px + sx * 0.4, st.py + sy * 0.4, st.pz + sz * 0.4,
                    sx * 35.0, sy * 35.0, sz * 35.0, dmg, 1100, pack_rgb(64, 236, 255));
                s = s + 1;
            }
        } else if mode == 3 {
            // Hyper Rapid Fire: 4 shots, each 4x the Basic damage (high DPS, low DPA).
            st.fire_cd_ms = (190.0 * rof_mul) as! i32;
            queue_sfx(SFX_PLASMA);
            let dmg = (96.0 * dmg_mul) as! i32;
            var s: i32 = 0;
            while s < 4 {
                let syaw = st.yaw + ((s as f64) - 1.5) * 0.07;
                let cp = fcos(st.pitch);
                let sx = cp * fcos(syaw);
                let sy = fsin(st.pitch);
                let sz = cp * fsin(syaw);
                spawn_shot(1, w, 3, st.px + sx * 0.4, st.py + sy * 0.4, st.pz + sz * 0.4,
                    sx * 52.0, sy * 52.0, sz * 52.0, dmg, 1000, pack_rgb(180, 250, 255));
                s = s + 1;
            }
        } else if mode == 4 {
            // Lightning Rifle: hitscan, 25x the Basic damage, effectively instant.
            st.fire_cd_ms = (1500.0 * rof_mul) as! i32;
            queue_sfx(SFX_LASER);
            let dmg = (600.0 * dmg_mul) as! i32;
            let col = pack_rgb(112, 232, 255);
            var t: f64 = 0.4;
            var end_x = st.px + dx * 30.0;
            var end_y = st.py + dy * 30.0;
            var end_z = st.pz + dz * 30.0;
            while t < 30.0 {
                let hx = st.px + dx * t;
                let hy = st.py + dy * t;
                let hz = st.pz + dz * t;
                let bx = ffloor(hx);
                let by = ffloor(hy);
                let bz = ffloor(hz);
                if bx < -16 || bx >= 32 || by < -16 || by >= 32 || bz < -16 || bz >= 32 {
                    end_x = hx; end_y = hy; end_z = hz; break;
                }
                let blk = world_block_rel(bx, by, bz);
                if is_block_solid(blk) != 0 {
                    end_x = hx; end_y = hy; end_z = hz;
                    if bx >= 0 && bx < 16 && by >= 0 && by < 16 && bz >= 0 && bz < 16 && is_block_destructible(blk) != 0 {
                        damage_block_at(bx, by, bz, dmg);
                    } else {
                        spawn_burst(hx, hy, hz, col, 5);
                    }
                    break;
                }
                var ei: i32 = 0;
                while ei < MAX_ENTITIES {
                    if st.entities[ei].active != 0 && is_enemy_kind(st.entities[ei].kind) != 0 {
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
                t = t + 0.28;
            }
            st.beam_timer_ms = 110;
            st.beam_rgb = col;
            st.beam_x1 = st.px + dx * 0.45;
            st.beam_y1 = st.py + dy * 0.45 - 0.10;
            st.beam_z1 = st.pz + dz * 0.45;
            st.beam_x2 = end_x; st.beam_y2 = end_y; st.beam_z2 = end_z;
        } else if mode == 5 {
            // Flare: launches a glowing light projectile that sticks as an ENT_FLARE beacon!
            st.fire_cd_ms = (250.0 * rof_mul) as! i32;
            queue_sfx(SFX_PLASMA);
            spawn_shot(1, w, 5, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 22.0 * vel_mul, dy * 22.0 * vel_mul, dz * 22.0 * vel_mul, 0, 2600, pack_rgb(255, 236, 150));
        } else {
            // Basic High DPA
            st.fire_cd_ms = (190.0 * rof_mul) as! i32;
            queue_sfx(SFX_PLASMA);
            let dmg = (24.0 * dmg_mul) as! i32;
            spawn_shot(1, w, 0, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 17.5 * vel_mul, dy * 17.5 * vel_mul, dz * 17.5 * vel_mul, dmg, 1450, pack_rgb(56, 224, 255));
        }
        return;
    }

    // Dark Hole mode 1 = Exchange Health for Ammo (manual 9.11: +1 ammo, 100 dmg).
    if w == WEP_DARKHOLE && mode == 1 {
        st.fire_cd_ms = 450;
        damage_player(100);
        st.ammo[WEP_DARKHOLE] = clamp_i(st.ammo[WEP_DARKHOLE] + 1, 0, st.max_ammo[WEP_DARKHOLE]);
        st.flash_ms = 200;
        st.flash_rgb = pack_rgb(196, 40, 220);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Dark Hole: traded 100 HP for +1 Dark Hole!", 1600);
        return;
    }

    if w == WEP_CANNON {
        if mode == 1 {
            // Blunderbuss: 4-ball spread volley
            st.fire_cd_ms = (420.0 * rof_mul) as! i32;
            queue_sfx(SFX_CANNON);
            let dmg = (19.0 * dmg_mul) as! i32;
            var s: i32 = 0;
            while s < 4 {
                let syaw = st.yaw + ((s as f64) - 1.5) * 0.085;
                let cp = fcos(st.pitch);
                let sx = cp * fcos(syaw);
                let sz = cp * fsin(syaw);
                spawn_shot(1, w, 1, st.px + sx * 0.4, st.py + dy * 0.4, st.pz + sz * 0.4,
                    sx * 16.5 * vel_mul, dy * 16.5 * vel_mul, sz * 16.5 * vel_mul, dmg, 1300, pack_rgb(255, 184, 68));
                s = s + 1;
            }
        } else if mode == 2 {
            // Tommy Gun: twice the Blunderbuss rate, ball = 3x the volley total.
            st.fire_cd_ms = (210.0 * rof_mul) as! i32;
            queue_sfx(SFX_CANNON);
            let dmg = (228.0 * dmg_mul) as! i32;
            spawn_shot(1, w, 2, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 21.0 * vel_mul, dy * 21.0 * vel_mul, dz * 21.0 * vel_mul, dmg, 1500, pack_rgb(255, 198, 72));
        } else if mode == 3 {
            // The Sheriff: 10x damage, 1 shot per second, chains on kill.
            st.fire_cd_ms = (1000.0 * rof_mul) as! i32;
            queue_sfx(SFX_CANNON);
            let dmg = (500.0 * dmg_mul) as! i32;
            spawn_shot(1, w, 3, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 16.5 * vel_mul, dy * 16.5 * vel_mul, dz * 16.5 * vel_mul, dmg, 1600, pack_rgb(255, 120, 40));
        } else if mode == 4 {
            // The Judge: 100x damage, 1 shot per 5 seconds, chains on kill.
            st.fire_cd_ms = (5000.0 * rof_mul) as! i32;
            queue_sfx(SFX_CANNON);
            let dmg = (5000.0 * dmg_mul) as! i32;
            spawn_shot(1, w, 4, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 8.25 * vel_mul, dy * 8.25 * vel_mul, dz * 8.25 * vel_mul, dmg, 2200, pack_rgb(255, 60, 20));
        } else {
            // Chaining Cannon Ball: 1/2 damage, 2x velocity, chains on kill.
            st.fire_cd_ms = (360.0 * rof_mul) as! i32;
            queue_sfx(SFX_CANNON);
            let dmg = (50.0 * dmg_mul) as! i32;
            spawn_shot(1, w, 0, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 31.0 * vel_mul, dy * 31.0 * vel_mul, dz * 31.0 * vel_mul, dmg, 1600, pack_rgb(255, 160, 48));
        }
    } else if w == WEP_LASER {
        // Authentic: firing ANY laser mode fully recharges your shield (manual 9.4).
        st.shields = st.max_shields;
        st.fire_cd_ms = (250.0 * rof_mul) as! i32;
        if mode == 3 {
            // Laser Disco: 32x damage beam, 50 self-damage; kills splash Ice Lasers.
            queue_sfx(SFX_LASER);
            damage_player(50);
            let dmg = (1152.0 * dmg_mul) as! i32;
            let col = pack_rgb(255, 105, 220);
            var t: f64 = 0.4;
            var end_x = st.px + dx * 30.0;
            var end_y = st.py + dy * 30.0;
            var end_z = st.pz + dz * 30.0;
            var killed: i32 = 0;
            while t < 30.0 {
                let hx = st.px + dx * t;
                let hy = st.py + dy * t;
                let hz = st.pz + dz * t;
                let bx = ffloor(hx);
                let by = ffloor(hy);
                let bz = ffloor(hz);
                if bx < -16 || bx >= 32 || by < -16 || by >= 32 || bz < -16 || bz >= 32 {
                    end_x = hx; end_y = hy; end_z = hz; break;
                }
                let blk = world_block_rel(bx, by, bz);
                if is_block_solid(blk) != 0 {
                    end_x = hx; end_y = hy; end_z = hz;
                    if bx >= 0 && bx < 16 && by >= 0 && by < 16 && bz >= 0 && bz < 16 && is_block_destructible(blk) != 0 {
                        damage_block_at(bx, by, bz, dmg);
                    } else {
                        spawn_burst(hx, hy, hz, col, 6);
                    }
                    break;
                }
                var ei: i32 = 0;
                while ei < MAX_ENTITIES {
                    if st.entities[ei].active != 0 && is_enemy_kind(st.entities[ei].kind) != 0 {
                        let ex = st.entities[ei].x - hx;
                        let ey = st.entities[ei].y - hy;
                        let ez = st.entities[ei].z - hz;
                        if (ex * ex + ey * ey + ez * ez) < 0.44 {
                            let before = st.entities[ei].hp;
                            damage_entity(ei, dmg, 0);
                            if st.entities[ei].active == 0 && before > 0 { killed = 1; }
                            end_x = hx; end_y = hy; end_z = hz;
                            t = 99.0;
                            break;
                        }
                    }
                    ei = ei + 1;
                }
                t = t + 0.25;
            }
            if killed != 0 {
                // Disco chain: ice beams at up to 4 nearby monsters of the same size.
                var launched: i32 = 0;
                var ei2: i32 = 0;
                while ei2 < MAX_ENTITIES && launched < 4 {
                    if st.entities[ei2].active != 0 && is_enemy_kind(st.entities[ei2].kind) != 0 {
                        let ex2 = st.entities[ei2].x - st.px;
                        let ey2 = st.entities[ei2].y - st.py;
                        let ez2 = st.entities[ei2].z - st.pz;
                        let d2 = fsqrt(ex2 * ex2 + ey2 * ey2 + ez2 * ez2);
                        if d2 > 0.5 && d2 < 14.0 {
                            spawn_shot(1, w, 0, st.px, st.py, st.pz,
                                (ex2 / d2) * 17.5, (ey2 / d2) * 17.5, (ez2 / d2) * 17.5,
                                (36.0 * dmg_mul) as! i32, 1200, pack_rgb(255, 68, 86));
                            launched = launched + 1;
                        }
                    }
                    ei2 = ei2 + 1;
                }
            }
            st.beam_timer_ms = 160;
            st.beam_rgb = col;
            st.beam_x1 = st.px + dx * 0.45;
            st.beam_y1 = st.py + dy * 0.45 - 0.12;
            st.beam_z1 = st.pz + dz * 0.45;
            st.beam_x2 = end_x; st.beam_y2 = end_y; st.beam_z2 = end_z;
        } else {
            // Ice Laser / Cold Beam / Freeze Ray
            let is_cold = if mode == 1 { 1 } else { 0 };
            let is_freeze = if mode == 2 { 1 } else { 0 };
            queue_sfx(SFX_LASER);
            let dmg = ((if is_cold != 0 { 144.0 } else if is_freeze != 0 { 216.0 } else { 36.0 }) * dmg_mul) as! i32;
            let freeze_d: i32 = if is_cold != 0 { 6250 } else if is_freeze != 0 { 2500 } else { 2500 };
            let col = if is_freeze != 0 { pack_rgb(170, 120, 255) } else if is_cold != 0 { pack_rgb(96, 232, 255) } else { pack_rgb(255, 68, 86) };
            var t: f64 = 0.4;
            var end_x = st.px + dx * 28.0;
            var end_y = st.py + dy * 28.0;
            var end_z = st.pz + dz * 28.0;
            while t < 28.0 {
                let hx = st.px + dx * t;
                let hy = st.py + dy * t;
                let hz = st.pz + dz * t;
                let bx = ffloor(hx);
                let by = ffloor(hy);
                let bz = ffloor(hz);
                if bx < -16 || bx >= 32 || by < -16 || by >= 32 || bz < -16 || bz >= 32 {
                    end_x = hx; end_y = hy; end_z = hz; break;
                }
                let blk = world_block_rel(bx, by, bz);
                if is_block_solid(blk) != 0 {
                    end_x = hx; end_y = hy; end_z = hz;
                    if bx >= 0 && bx < 16 && by >= 0 && by < 16 && bz >= 0 && bz < 16 && is_block_destructible(blk) != 0 {
                        damage_block_at(bx, by, bz, dmg);
                    } else {
                        spawn_burst(hx, hy, hz, col, 6);
                    }
                    break;
                }
                var ei: i32 = 0;
                while ei < MAX_ENTITIES {
                    if st.entities[ei].active != 0 && is_enemy_kind(st.entities[ei].kind) != 0 {
                        let ex = st.entities[ei].x - hx;
                        let ey = st.entities[ei].y - hy;
                        let ez = st.entities[ei].z - hz;
                        if (ex * ex + ey * ey + ez * ez) < 0.44 {
                            damage_entity(ei, dmg, freeze_d);
                            if is_freeze != 0 && st.entities[ei].active != 0 {
                                stack_freeze(ei, 2500);   // Freeze Ray stacking
                            }
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
        st.fire_cd_ms = (450.0 * rof_mul) as! i32;
        queue_sfx(SFX_PLASMA);
        let base = (60.0 * dmg_mul) as! i32;
        if mode == 1 {
            // High Velocity Rocket: 3x speed, 2x damage.
            spawn_shot(1, w, 1, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 36.0, dy * 36.0, dz * 36.0, base * 2, 1600, pack_rgb(255, 118, 36));
        } else if mode == 2 {
            // Big Radius Rocket: 2x damage, double explosion radius, 1/4 speed.
            spawn_shot(1, w, 2, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 3.2, dy * 3.2, dz * 3.2, base * 2, 5000, pack_rgb(255, 150, 40));
        } else if mode == 3 {
            // Kinetic Rocket: 4x damage, no explosion, 1/8 speed.
            spawn_shot(1, w, 3, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 4.2, dy * 4.2, dz * 4.2, base * 4, 4000, pack_rgb(255, 200, 60));
        } else if mode == 4 {
            // Progressive Rocket: 18x damage, no explosion, very slow (accelerating in Xar; approximated).
            spawn_shot(1, w, 4, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 1.6, dy * 1.6, dz * 1.6, base * 18, 9000, pack_rgb(255, 80, 30));
        } else {
            // Basic Rocket
            spawn_shot(1, w, 0, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 12.5, dy * 12.5, dz * 12.5, base, 1900, pack_rgb(255, 118, 36));
        }
    } else if w == WEP_HOMING {
        let dmg = (44.0 * dmg_mul) as! i32;
        if mode == 0 {
            // Primary seeker (costs 20 ammo): locks on + free minigun bullets at nearby monsters.
            st.fire_cd_ms = (1000.0 * rof_mul) as! i32;
            queue_sfx(SFX_PLASMA);
            spawn_shot(1, w, 0, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 11.0, dy * 11.0, dz * 11.0, dmg, 2600, pack_rgb(244, 114, 248));
            var used_flags: i32[96] = [0; 96];
            var launched: i32 = 0;
            while launched < 8 {
                var best_e: i32 = -1;
                var best_d: f64 = 12.0;
                var ei: i32 = 0;
                while ei < MAX_ENTITIES {
                    if used_flags[ei] == 0 && st.entities[ei].active != 0 && is_enemy_kind(st.entities[ei].kind) != 0 {
                        let ex = st.entities[ei].x - st.px;
                        let ey = st.entities[ei].y - st.py;
                        let ez = st.entities[ei].z - st.pz;
                        let d = fsqrt(ex * ex + ey * ey + ez * ez);
                        if d < best_d { best_d = d; best_e = ei; }
                    }
                    ei = ei + 1;
                }
                if best_e < 0 { break; }
                used_flags[best_e] = 1;
                let ex = st.entities[best_e].x - st.px;
                let ey = st.entities[best_e].y - st.py;
                let ez = st.entities[best_e].z - st.pz;
                let d = fsqrt(ex * ex + ey * ey + ez * ez);
                spawn_shot(1, WEP_MINIGUN, 0, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                    (ex / d) * 22.0, (ey / d) * 22.0, (ez / d) * 22.0,
                    (12.0 * dmg_mul) as! i32, 700, pack_rgb(255, 215, 72));
                launched = launched + 1;
            }
        } else {
            // Secondary swarm: 20 rockets (each 1/2 damage) for 10 ammo.
            st.fire_cd_ms = (660.0 * rof_mul) as! i32;
            queue_sfx(SFX_PLASMA);
            var s: i32 = 0;
            while s < 20 {
                let syaw = st.yaw + ((s as f64) - 9.5) * 0.06;
                let spitch = st.pitch + ((if (s & 1) == 0 { 1 } else { -1 }) as f64) * 0.04;
                let cp = fcos(spitch);
                let sx = cp * fcos(syaw);
                let sy = fsin(spitch);
                let sz = cp * fsin(syaw);
                spawn_shot(1, w, 1, st.px + sx * 0.4, st.py + sy * 0.4, st.pz + sz * 0.4,
                    sx * 10.0, sy * 10.0, sz * 10.0, dmg / 2, 2400, pack_rgb(244, 114, 248));
                s = s + 1;
            }
        }
    } else if w == WEP_MINIGUN {
        if mode == 1 {
            // Poison dart: no impact damage; poison = 20 primary shots over 10s (stacking duration).
            st.fire_cd_ms = (250.0 * rof_mul) as! i32;
            queue_sfx(SFX_MINIGUN);
            let pdps = (32.0 * dmg_mul) as! i32;
            spawn_shot(1, w, 1, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                dx * 14.0 * vel_mul, dy * 14.0 * vel_mul, dz * 14.0 * vel_mul, pdps, 1400, pack_rgb(134, 239, 172));
        } else {
            st.fire_cd_ms = (78.0 * rof_mul) as! i32;
            queue_sfx(SFX_MINIGUN);
            let dmg = (16.0 * dmg_mul) as! i32;
            let spread = 0.042;
            let jx = dx + (rng_f01() - 0.5) * spread;
            let jy = dy + (rng_f01() - 0.5) * spread;
            let jz = dz + (rng_f01() - 0.5) * spread;
            spawn_shot(1, w, 0, st.px + dx * 0.4, st.py + dy * 0.4, st.pz + dz * 0.4,
                jx * 22.0 * vel_mul, jy * 22.0 * vel_mul, jz * 22.0 * vel_mul, dmg, 1000, pack_rgb(255, 215, 72));
        }
    } else if w == WEP_RAILGUN {
        // Piercing hitscan; Vampire modes steal 1/4 of damage dealt as health (manual 9.8).
        st.fire_cd_ms = ((if mode == 1 { 155.0 } else { 620.0 }) * rof_mul) as! i32;
        queue_sfx(SFX_RAILGUN);
        let base = (90.0 * dmg_mul) as! i32;
        let dmg = if mode == 1 { base * 2 } else if mode == 2 { base / 2 } else { base };
        let vamp = if mode == 2 || mode == 3 { 1 } else { 0 };
        let recoil = if mode == 1 { 3.8 } else { 6.2 };
        st.vx = st.vx - dx * recoil;
        st.vy = st.vy - dy * recoil;
        st.vz = st.vz - dz * recoil;

        var hit_flags: i32[96] = [0; 96];
        let col = if vamp != 0 { pack_rgb(244, 63, 94) } else { pack_rgb(196, 86, 255) };
        var t: f64 = 0.4;
        var end_x = st.px + dx * 28.0;
        var end_y = st.py + dy * 28.0;
        var end_z = st.pz + dz * 28.0;
        while t < 30.0 {
            let hx = st.px + dx * t;
            let hy = st.py + dy * t;
            let hz = st.pz + dz * t;
            let bx = ffloor(hx);
            let by = ffloor(hy);
            let bz = ffloor(hz);
            if bx < -16 || bx >= 32 || by < -16 || by >= 32 || bz < -16 || bz >= 32 {
                end_x = hx; end_y = hy; end_z = hz; break;
            }
            let blk = world_block_rel(bx, by, bz);
            if is_block_solid(blk) != 0 {
                end_x = hx; end_y = hy; end_z = hz;
                if bx >= 0 && bx < 16 && by >= 0 && by < 16 && bz >= 0 && bz < 16 && is_block_destructible(blk) != 0 {
                    damage_block_at(bx, by, bz, dmg);
                } else {
                    spawn_burst(hx, hy, hz, col, 7);
                }
                break;
            }
            var ei: i32 = 0;
            while ei < MAX_ENTITIES {
                if hit_flags[ei] == 0 && st.entities[ei].active != 0 &&
                   is_enemy_kind(st.entities[ei].kind) != 0 {
                    let ex = st.entities[ei].x - hx;
                    let ey = st.entities[ei].y - hy;
                    let ez = st.entities[ei].z - hz;
                    if (ex * ex + ey * ey + ez * ez) < 0.50 {
                        hit_flags[ei] = 1;
                        damage_entity(ei, dmg, 0);
                        if vamp != 0 {
                            st.hp = clamp_i(st.hp + dmg / 4, 0, st.max_hp * 2);
                        }
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
        st.fire_cd_ms = (1000.0 * rof_mul) as! i32;
        queue_sfx(SFX_EMP);
        let emp_rad = 7.0 + (st.emp_rad_lvl as f64) * 1.2;
        if mode == 1 {
            // Secondary: stun + damage pulse, but 100 recoil damage to you (manual 9.9).
            explosion_at(st.px, st.py, st.pz, emp_rad, (28.0 * dmg_mul) as! i32, 4000, 0, pack_rgb(96, 165, 250), -1, 0);
            damage_player(100);
            set_status_msg("EMP Shockwave! (100 recoil damage taken)", 1400);
        } else {
            // Primary: pure stun pulse, no damage.
            explosion_at(st.px, st.py, st.pz, emp_rad, 0, 4000, 0, pack_rgb(96, 165, 250), -1, 0);
            set_status_msg("EMP Pulse: enemies stunned!", 1200);
        }
    } else if w == WEP_NUKE {
        if mode == 2 {
            // Nuclear Pulse Propulsion: detonate a High Damage nuke at your position + propel.
            st.fire_cd_ms = (650.0 * rof_mul) as! i32;
            queue_sfx(SFX_NUKE);
            st.vx = st.vx + dx * 13.5;
            st.vy = st.vy + dy * 13.5;
            st.vz = st.vz + dz * 13.5;
            explosion_at(st.px, st.py, st.pz, 5.2, (160.0 * dmg_mul) as! i32, 0, 0, pack_rgb(163, 230, 53), -1, 0);
            set_status_msg("Nuclear Pulse Propulsion Boost!", 1200);
        } else if mode == 1 {
            // High Velocity & Radius: 3x speed, 2x radius, 1/2 damage.
            st.fire_cd_ms = (750.0 * rof_mul) as! i32;
            queue_sfx(SFX_NUKE);
            st.vx = st.vx - dx * 7.5;
            st.vy = st.vy - dy * 7.5;
            st.vz = st.vz - dz * 7.5;
            spawn_shot(1, w, 1, st.px + dx * 0.5, st.py + dy * 0.5, st.pz + dz * 0.5,
                dx * 28.5 * vel_mul, dy * 28.5 * vel_mul, dz * 28.5 * vel_mul, (80.0 * dmg_mul) as! i32, 1600, pack_rgb(163, 230, 53));
        } else {
            // High Damage nuke.
            st.fire_cd_ms = (950.0 * rof_mul) as! i32;
            queue_sfx(SFX_NUKE);
            st.vx = st.vx - dx * 7.5;
            st.vy = st.vy - dy * 7.5;
            st.vz = st.vz - dz * 7.5;
            spawn_shot(1, w, 0, st.px + dx * 0.5, st.py + dy * 0.5, st.pz + dz * 0.5,
                dx * 9.5, dy * 9.5, dz * 9.5, (160.0 * dmg_mul) as! i32, 1900, pack_rgb(163, 230, 53));
        }
    } else if w == WEP_DARKHOLE {
        if mode == 2 {
            // Black Hole Drive (20 ammo): decreased air drag for 30 SECONDS (manual 9.11).
            st.fire_cd_ms = 600;
            queue_sfx(SFX_WARP);
            st.black_hole_drive_ms = 30000;
            set_status_msg("BLACK HOLE DRIVE ENGAGED (30s Flight Boost)!", 2200);
        } else if mode == 3 {
            // Quasar Drive (60 ammo): decreased drag for 30s, faster than BH Drive.
            if st.quasar_drive == 0 {
                set_status_msg("Quasar Drive requires The Singularity's core!", 1600);
                st.ammo[w] = st.ammo[w] + 60;
            } else {
                st.fire_cd_ms = 600;
                queue_sfx(SFX_WARP);
                st.quasar_drive_ms = 30000;
                set_status_msg("QUASAR DRIVE ENGAGED (30s High-Speed Flight)!", 2200);
            }
        } else {
            // Standard Fire: heavy singularity shot that pulls and chains (2D, D/2, D/3...).
            st.fire_cd_ms = (880.0 * rof_mul) as! i32;
            queue_sfx(SFX_EXPLODE);
            let qmul = if st.quasar_drive != 0 { 2.0 } else { 1.0 };
            let dmg = (175.0 * dmg_mul * qmul) as! i32;
            st.vx = st.vx - dx * 7.5;
            st.vy = st.vy - dy * 7.5;
            st.vz = st.vz - dz * 7.5;
            let col = if st.quasar_drive != 0 { pack_rgb(255, 224, 112) } else { pack_rgb(218, 62, 255) };
            spawn_shot(1, w, 0, st.px + dx * 0.5, st.py + dy * 0.5, st.pz + dz * 0.5,
                dx * 8.5, dy * 8.5, dz * 8.5, dmg, 2100, col);
        }
    }
}

fn entity_label(k: i32) -> const u8[:] {
    if k == ENT_RAT { return "Space Rat"; }
    if k == ENT_SPIDER { return "Void Spider"; }
    if k == ENT_GOON { return "Ying Goon"; }
    if k == ENT_MARINE { return "Slime Marine"; }
    if k == ENT_PIRATE { return "Space Pirate"; }
    if k == ENT_YINYANG { return "Yin-Yang"; }
    if k == ENT_MENACE { return "Menace Cube"; }
    if k == ENT_DEMON { return "Core Demon"; }
    if k == ENT_GUARDIAN { return "Pool Ball Guardian"; }
    if k == ENT_SINGULARITY { return "THE SINGULARITY BOSS"; }
    if k == ENT_TWEEDLE { return "Tweedle"; }
    if k == ENT_GNAT { return "Swarm Gnat"; }
    if k == ENT_BABY_SPIDER { return "Baby Spider"; }
    if k == ENT_LAMPREY { return "Cave Lamprey"; }
    if k == ENT_BURLY { return "Burly Sentinel"; }
    if k == ENT_BEHOLDER { return "Mystical Beholder"; }
    if k == ENT_SLIVER { return "Cryo Sliver"; }
    if k == ENT_VULCAN { return "Vulcan Core"; }
    if k == ENT_GROWER { return "Mutating Grower"; }
    if k == ENT_SHRINKER { return "Phase Shrinker"; }
    if k == ENT_ROCKET_SPIDER { return "Rocket Spider"; }
    if k == ENT_HYDRA { return "Regenerating Hydra"; }
    if k == ENT_TON618_BOSS { return "TON 618 SUPERMASSIVE"; }
    if k == ENT_HEX_SENTRY { return "Hex Sentry"; }
    if k == ENT_ARCADE_DRONE { return "Arcade Drone"; }
    if k == ENT_FLARE { return "Plasma Flare Beacon"; }
    if k == ENT_FRIEND_K { return "Friend 'K' [USE]"; }
    if k == ENT_RING_GREEN { return "Green Shrink Ring (16x) [USE]"; }
    if k == ENT_RING_RED { return "Red Grow Ring (16x) [USE]"; }
    if k == ENT_RING_BLUE { return "Blue Biome Portal [USE]"; }
    if k == ENT_RING_PINK { return "Pink Deep Ring (256x) [USE]"; }
    if k == ENT_RING_DANGER { return "Danger Rift Ring (256x) [USE]"; }
    return "";
}

fn update_crosshair_target() {
    st.target_name_len = 0;
    st.target_hp = 0;
    st.target_max_hp = 0;

    var fx: f64 = 0.0;
    var fy: f64 = 0.0;
    var fz: f64 = 0.0;
    camera_forward(fx, fy, fz);

    var best_et: f64 = 20.0;
    var best_ei: i32 = -1;
    var ei: i32 = 0;
    while ei < MAX_ENTITIES {
        if st.entities[ei].active != 0 {
            let k = st.entities[ei].kind;
            if (k >= ENT_RING_GREEN && k <= ENT_RING_PINK) ||
               is_enemy_kind(k) != 0 ||
               k == ENT_FRIEND_K || k == ENT_RING_DANGER || k == ENT_FLARE {
                let vx = st.entities[ei].x - st.px;
                let vy = st.entities[ei].y - st.py;
                let vz = st.entities[ei].z - st.pz;
                let proj = vx * fx + vy * fy + vz * fz;
                if proj > 0.35 && proj < best_et {
                    let px = vx - fx * proj;
                    let py = vy - fy * proj;
                    let pz = vz - fz * proj;
                    let rad2 = if k == ENT_SINGULARITY || k == ENT_TON618_BOSS { 0.85 } else { 0.42 };
                    if (px * px + py * py + pz * pz) <= rad2 {
                        best_et = proj;
                        best_ei = ei;
                    }
                }
            }
        }
        ei = ei + 1;
    }

    var hit_blk: u8 = BLK_AIR;
    var blk_t: f64 = 99.0;
    var t: f64 = 0.4;
    while t <= best_et && t <= 18.0 {
        let bx = ffloor(st.px + fx * t);
        let by = ffloor(st.py + fy * t);
        let bz = ffloor(st.pz + fz * t);
        let blk = world_block_rel(bx, by, bz);
        if is_block_solid(blk) != 0 {
            hit_blk = blk;
            blk_t = t;
            break;
        }
        t = t + 0.35;
    }

    if best_ei >= 0 && best_et < blk_t {
        let ek = st.entities[best_ei].kind;
        let lbl = entity_label(ek);
        if lbl.len > 0 {
            if is_enemy_kind(ek) != 0 {
                set_target_name(lbl, st.entities[best_ei].hp, st.entities[best_ei].max_hp);
            } else {
                set_target_name(lbl, 0, 0);
            }
        }
        return;
    }

    if hit_blk != BLK_AIR {
        let blbl = block_label(hit_blk);
        if blbl.len > 0 {
            set_target_name(blbl, 0, 0);
        }
    }
}

fn tome_title(biome: i32) -> const u8[:] {
    if biome == BIOME_TUTORIAL { return "XAR MANUAL: TUTORIAL ISLAND"; }
    if biome == BIOME_YING_FOREST { return "XAR LORE: YING FOREST"; }
    if biome == BIOME_WHITE_FLOWER { return "XAR LORE: ALPHA CUBE"; }
    if biome == BIOME_YELLOW_FLOWER { return "XAR LORE: YELLOW FLOWER"; }
    if biome == BIOME_MYLANTIS { return "XAR LORE: MYLANTIS CAVES"; }
    if biome == BIOME_BLACK_CUBE { return "XAR LORE: MENGER LATTICE"; }
    if biome == BIOME_ICE_WORLD { return "XAR LORE: GLACIAL SPIRE"; }
    if biome == BIOME_DESERT_WORLD { return "XAR LORE: DESERT PYRAMID"; }
    if biome == BIOME_NOOB_FLOWER { return "XAR LORE: NOOB FLOWER"; }
    if biome == BIOME_YING_LIBRARY { return "XAR LORE: YING LIBRARY"; }
    if biome == BIOME_BOTANY_LAB { return "XAR LORE: BOTANY LAB"; }
    if biome == BIOME_BETA_CUBE { return "XAR LORE: BETA CUBE"; }
    if biome == BIOME_RED_CAVES { return "XAR LORE: RED CAVES"; }
    if biome == BIOME_I1_LIGHTHOUSE { return "XAR LORE: I1 LIGHTHOUSE"; }
    if biome == BIOME_I2_MOUNTAINS { return "XAR LORE: I2 MOUNTAINS"; }
    if biome == BIOME_BURLINGTON { return "XAR LORE: BURLINGTON CITADEL"; }
    if biome == BIOME_I3_ROOTS { return "XAR LORE: I3 ROOT MATRIX"; }
    if biome == BIOME_PURPLE_HOUSE { return "XAR LORE: PURPLE HOUSE"; }
    if biome == BIOME_SINGLETON { return "XAR LORE: THE SINGLETON"; }
    if biome == BIOME_ARCADE { return "XAR LORE: NEON ARCADE"; }
    if biome == BIOME_TON618 { return "XAR LORE: TON 618 ABYSS"; }
    if biome == BIOME_SOLAR_SYSTEM { return "XAR LORE: SOLAR CORONA"; }
    return "XAR LORE: THE INNER CORE";
}

fn tome_body_line(biome: i32, row: i32) -> const u8[:] {
    if biome == BIOME_TUTORIAL {
        if row == 0 { return "Every block in Xar holds a 16x16x16 universe inside."; }
        if row == 1 { return "Shoot Green/White blocks or use SHRK / Rings to dive 16x."; }
        if row == 2 { return "Drop Short Markers [MRK] before diving (costs 5g past LVL 0)."; }
        return "Plasma [1] destroys your Short Marker & regenerates energy.";
    }
    if biome == BIOME_YING_FOREST {
        if row == 0 { return "Ying Forest canopies hide Buy Stations & White Flowers."; }
        if row == 1 { return "Unlock Cannon [2] & Laser [3] inside forest arsenals."; }
        if row == 2 { return "Mystery [?] Pillars yield Gold, Ammo, or Vault Keys."; }
        return "Watch for Pink 256x Rings to leap deeper toward Mylantis.";
    }
    if biome == BIOME_WHITE_FLOWER || biome == BIOME_YELLOW_FLOWER {
        if row == 0 { return "Petal towers spiral around golden Pollen Upgrade vaults."; }
        if row == 1 { return "Collect +HP, +Regen, +Armor/Shields & Minigun/Rocket tech."; }
        if row == 2 { return "Spawners continuously summon waves — destroy them for +100 XP!"; }
        return "Follow Topaz veins & Black Cubes to reach Mylantis Crust.";
    }
    if biome == BIOME_MYLANTIS || biome == BIOME_ICE_WORLD || biome == BIOME_DESERT_WORLD {
        if row == 0 { return "Deep strata hold Black Markets, Railguns [7] & EMP [8]."; }
        if row == 1 { return "Laser Cold Beam & EMP stun Pool Ball Guardians (half on repeat)."; }
        if row == 2 { return "Topaz Mineral blocks mine for Gold; Nuke Crates restock Rockets."; }
        return "Seek Purple Core Gates or Infinity Blocks to reach Menger Lattice.";
    }
    if biome == BIOME_BLACK_CUBE {
        if row == 0 { return "Welcome to I2 / I3 recursive Menger Sponge architecture."; }
        if row == 1 { return "Open 3D arches connect sibling chunks infinitely in every axis."; }
        if row == 2 { return "Collect Damage, RoF & Nuke modules before entering Core Gates."; }
        return "Deep Core Gates (LVL >= 6) unlock Nuke [9] & Dark Hole [0].";
    }
    if biome >= BIOME_NOOB_FLOWER && biome <= BIOME_BURLINGTON {
        if row == 0 { return "Deep outer/middle strata hold Library Books, Vats & Quicksand."; }
        if row == 1 { return "Plasma Mode 6 (Flare) lights dark caves; Telekinesis pulls UPG!"; }
        if row == 2 { return "Short Markers expire after 3h; use Long Markers for safehouses."; }
        return "Watch out for Cryo Slivers (freeze-immune) & Beholders (phase)!";
    }
    if biome >= BIOME_I3_ROOTS && biome <= BIOME_SOLAR_SYSTEM {
        if row == 0 { return "Extreme strata: TON 618, Arcade Cabinets, Solar Plasma & Roots."; }
        if row == 1 { return "Play Neon Arcade cabinets [USE] for Gold & Leaderboard trophies."; }
        if row == 2 { return "Beyond Max upgrades scale active weapons & Push past LVL 12."; }
        return "Defeat TON 618 or The Singularity to claim Jade Armor & Quasar!";
    }
    if row == 0 { return "The Inner Core houses The Singularity and imprisoned Friend 'K'."; }
    if row == 1 { return "Defeat The Singularity to unlock Quasar Drive for Weapon [0]."; }
    if row == 2 { return "Use Dark Hole Blood Pact (-75 HP -> +2 Ammo) in emergencies."; }
    return "Once The Singularity falls, touch Friend 'K' [USE] to win!";
}

fn has_clear_los(x0: f64, y0: f64, z0: f64, x1: f64, y1: f64, z1: f64) -> i32 {
    let dx = x1 - x0;
    let dy = y1 - y0;
    let dz = z1 - z0;
    let d = fsqrt(dx * dx + dy * dy + dz * dz);
    if d <= 0.35 { return 1; }
    let inv_d = 1.0 / d;
    let rx = dx * inv_d;
    let ry = dy * inv_d;
    let rz = dz * inv_d;
    var t: f64 = 0.25;
    let limit = d - 0.20;
    while t < limit {
        let bx = ffloor(x0 + rx * t);
        let by = ffloor(y0 + ry * t);
        let bz = ffloor(z0 + rz * t);
        if world_block_rel(bx, by, bz) != BLK_AIR {
            return 0;
        }
        t = t + 0.20;
    }
    return 1;
}

fn has_clear_los_to_block(x0: f64, y0: f64, z0: f64, tbx: i32, tby: i32, tbz: i32) -> i32 {
    let x1 = (tbx as f64) + 0.5;
    let y1 = (tby as f64) + 0.5;
    let z1 = (tbz as f64) + 0.5;
    let dx = x1 - x0;
    let dy = y1 - y0;
    let dz = z1 - z0;
    let d = fsqrt(dx * dx + dy * dy + dz * dz);
    if d <= 0.35 { return 1; }
    let inv_d = 1.0 / d;
    let rx = dx * inv_d;
    let ry = dy * inv_d;
    let rz = dz * inv_d;
    var t: f64 = 0.25;
    let limit = d - 0.15;
    while t < limit {
        let bx = ffloor(x0 + rx * t);
        let by = ffloor(y0 + ry * t);
        let bz = ffloor(z0 + rz * t);
        if !(bx == tbx && by == tby && bz == tbz) && world_block_rel(bx, by, bz) != BLK_AIR {
            return 0;
        }
        t = t + 0.20;
    }
    return 1;
}

fn trigger_telekinesis() {
    if st.screen != SCREEN_PLAY || st.hp <= 0 || st.telekinesis_ms > 0 {
        return;
    }
    var pulled: i32 = 0;
    var blocked: i32 = 0;
    var i: i32 = 0;
    while i < MAX_ENTITIES {
        if st.entities[i].active != 0 && st.entities[i].kind >= ENT_GOLD && st.entities[i].kind <= ENT_KEY {
            let ex = st.entities[i].x;
            let ey = st.entities[i].y;
            let ez = st.entities[i].z;
            let dx = st.px - ex;
            let dy = st.py - ey;
            let dz = st.pz - ez;
            let d = fsqrt(dx * dx + dy * dy + dz * dz);
            if d > 0.25 && d <= 11.5 {
                if has_clear_los(st.px, st.py, st.pz, ex, ey, ez) != 0 {
                    let tx = st.px - (dx / d) * 0.45;
                    let ty = st.py - (dy / d) * 0.45;
                    let tz = st.pz - (dz / d) * 0.45;
                    if world_block_rel(ffloor(tx), ffloor(ty), ffloor(tz)) == BLK_AIR {
                        st.entities[i].x = tx;
                        st.entities[i].y = ty;
                        st.entities[i].z = tz;
                    } else {
                        st.entities[i].x = st.px;
                        st.entities[i].y = st.py;
                        st.entities[i].z = st.pz;
                    }
                    pulled = pulled + 1;
                } else {
                    blocked = blocked + 1;
                }
            }
        }
        i = i + 1;
    }
    // Telekinesis also harvests visible Upgrade blocks & Mystery [?] blocks in range!
    let pbx = clamp_i(ffloor(st.px), 0, 15);
    let pby = clamp_i(ffloor(st.py), 0, 15);
    let pbz = clamp_i(ffloor(st.pz), 0, 15);
    var bz: i32 = clamp_i(pbz - 5, 0, 15);
    let max_z = clamp_i(pbz + 5, 0, 15);
    while bz <= max_z {
        var by: i32 = clamp_i(pby - 5, 0, 15);
        let max_y = clamp_i(pby + 5, 0, 15);
        while by <= max_y {
            var bx: i32 = clamp_i(pbx - 5, 0, 15);
            let max_x = clamp_i(pbx + 5, 0, 15);
            while bx <= max_x {
                let tb = get_block(bx, by, bz);
                if is_block_upgrade(tb) != 0 || tb == BLK_MYSTERY_Q {
                    if has_clear_los_to_block(st.px, st.py, st.pz, bx, by, bz) != 0 {
                        if tb == BLK_MYSTERY_Q {
                            break_block_at(bx, by, bz);
                        } else {
                            collect_upgrade_block(bx, by, bz, tb);
                        }
                        pulled = pulled + 1;
                    }
                }
                bx = bx + 1;
            }
            by = by + 1;
        }
        bz = bz + 1;
    }
    st.telekinesis_ms = if pulled > 0 { 800 } else { 420 };
    if pulled > 0 {
        queue_sfx(SFX_PICKUP);
        set_status_msg("Telekinesis pulled nearby pickups!", 1200);
    } else if blocked > 0 {
        set_status_msg("Telekinesis blocked — clear line of sight required.", 1100);
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
        if st.depth > 0 && st.genesis_mode == 0 && st.mut_inf_markers == 0 {
            if st.gold < 10 {
                set_status_msg("Need 10 Gold to drop Short Marker past LVL 0!", 1500);
                return;
            }
            st.gold = st.gold - 10;
        }
        slot = 0;
    } else {
        if st.mut_inf_markers == 0 {
            if st.gold < 20 {
                set_status_msg("Need 20 Gold to drop a Long Marker!", 1500);
                return;
            }
            st.gold = st.gold - 20;
        }
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
    st.markers[slot].created_ms = st.play_ms;
    st.active_marker = slot;
    st.autosave_dirty = 1;
    queue_sfx(SFX_PICKUP);
    if is_long != 0 {
        set_status_msg("Long Tracking Marker placed! View & warp via [INFO/F4].", 1800);
    } else {
        set_status_msg(if st.depth > 0 && st.genesis_mode == 0 { "Short Marker dropped (-10g)! Shoot w/ Plasma to clear." } else { "Short Marker dropped! Shoot w/ Plasma to clear." }, 1600);
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
    st.autosave_dirty = 1;
    queue_sfx(SFX_WARP);
    set_status_msg("Warped to Marker!", 1600);
    return 1;
}

fn shrink_targeted_block() {
    if st.ring_cd_ms > 0 { return; }
    var fx: f64 = 0.0;
    var fy: f64 = 0.0;
    var fz: f64 = 0.0;
    camera_forward(fx, fy, fz);
    // Xar: you shrink into blocks you are TOUCHING (ShrinkAny widens WHICH
    // blocks qualify, never the reach). Was 4.5/2.4 — allowed far-teleports.
    let max_t: f64 = 1.45;
    var t: f64 = 0.4;
    while t <= max_t {
        let hx = st.px + fx * t;
        let hy = st.py + fy * t;
        let hz = st.pz + fz * t;
        let bx = ffloor(hx);
        let by = ffloor(hy);
        let bz = ffloor(hz);
        let b = get_block(bx, by, bz);
        if b != BLK_AIR {
            if st.shrink_any != 0 || (is_block_subdivisible(b) != 0 && (is_block_molecular(b) == 0 || st.depth >= 1)) {
                shrink_into_ex(bx, by, bz, b, -1, 1, hx - fx * 0.35, hy - fy * 0.35, hz - fz * 0.35);
                return;
            }
            set_status_msg("Molecular solid! Target a Fractal Block or Ring to shrink.", 1400);
            return;
        }
        t = t + 0.35;
    }

    // Also allow SHRK near a shrink/portal ring
    var i: i32 = 0;
    while i < MAX_ENTITIES {
        if st.entities[i].active != 0 {
            let k = st.entities[i].kind;
            if k == ENT_RING_GREEN || k == ENT_RING_BLUE || k == ENT_RING_PINK || k == ENT_RING_DANGER {
                let dx = st.entities[i].x - st.px;
                let dy = st.entities[i].y - st.py;
                let dz = st.entities[i].z - st.pz;
                if (dx * dx + dy * dy + dz * dz) < 1.44 {
                    let rx = clamp_i(ffloor(st.entities[i].x), 0, 15);
                    let ry = clamp_i(ffloor(st.entities[i].y), 0, 15);
                    let rz = clamp_i(ffloor(st.entities[i].z), 0, 15);
                    let steps: i32 = if k == ENT_RING_PINK || k == ENT_RING_DANGER { 2 } else { 1 };
                    shrink_into_ex(rx, ry, rz, st.entities[i].target_block, st.entities[i].target_biome, steps, st.px, st.py, st.pz);
                    return;
                }
            }
        }
        i = i + 1;
    }

    // Xar never shrinks in-place with nothing near — not even with ShrinkAny
    // (which only widens WHICH touched blocks qualify). Was: free in-place
    // shrink anywhere under ShrinkAny/Genesis (far-teleport exploit).
    set_status_msg("Fly to a Fractal Block or Ring to shrink 16x!", 1500);
}

fn use_nearest() {
    var i: i32 = 0;
    var best_ring: i32 = -1;
    var best_d: f64 = 1.2;
    while i < MAX_ENTITIES {
        if st.entities[i].active != 0 {
            let k = st.entities[i].kind;
            let dx = st.entities[i].x - st.px;
            let dy = st.entities[i].y - st.py;
            let dz = st.entities[i].z - st.pz;
            let d = fsqrt(dx * dx + dy * dy + dz * dz);
            if k == ENT_FRIEND_K && d < 2.6 {
                if st.singularity_defeated == 0 && st.genesis_mode == 0 {
                    set_status_msg("Friend 'K' is sealed! Defeat The Singularity Boss first!", 2000);
                    return;
                }
                st.k_rescued = 1;
                st.entities[i].active = 0;
                add_gold(500);
                award_trophy(64, "TROPHY: FRIEND 'K' RESCUED!");
                st.screen = SCREEN_VICTORY;
                return;
            }
            if ((k >= ENT_RING_GREEN && k <= ENT_RING_PINK) || k == ENT_RING_DANGER) && d < best_d {
                best_d = d;
                best_ring = i;
            }
        }
        i = i + 1;
    }

    var fx: f64 = 0.0;
    var fy: f64 = 0.0;
    var fz: f64 = 0.0;
    camera_forward(fx, fy, fz);
    var t: f64 = 0.4;
    while t <= 2.0 {
        let bx = ffloor(st.px + fx * t);
        let by = ffloor(st.py + fy * t);
        let bz = ffloor(st.pz + fz * t);
        let b = get_block(bx, by, bz);
        if b == BLK_BUY_STATION { st.screen = SCREEN_BUY; queue_sfx(SFX_CLICK); return; }
        if b == BLK_SELL_STATION { st.screen = SCREEN_SELL; queue_sfx(SFX_CLICK); return; }
        if b == BLK_BLACK_MARKET { st.screen = SCREEN_BLACK_MARKET; queue_sfx(SFX_CLICK); return; }
        if b == BLK_UPGRADE_STATION { st.screen = SCREEN_UPGRADE; queue_sfx(SFX_CLICK); return; }
        if b == BLK_ARCADE_CAB {
            st.arcade_active = 1;
            st.arcade_score = 0;
            st.arcade_hits = 0;
            st.arcade_timer_ms = 20000;
            st.arcade_target = (rng_u32() % 12) as! i32;
            queue_sfx(SFX_CLICK);
            st.screen = SCREEN_ARCADE;
            return;
        }
        if b == BLK_TOME || b == BLK_TEXT_BLOCK {
            let cb = cur_biome();
            st.tome_id = cb;
            let bit: i32 = (1 as! i32) << clamp_i(cb, 0, 23);
            if (st.tome_read_mask & bit) == 0 {
                st.tome_read_mask = st.tome_read_mask | bit;
                st.score_xp = st.score_xp + 40;
            }
            queue_sfx(SFX_PICKUP);
            st.screen = SCREEN_TOME;
            return;
        }
        if b == BLK_MYSTERY_Q {
            break_block_at(bx, by, bz);
            return;
        }
        if b == BLK_LOCKED_DOOR {
            if st.keys > 0 {
                st.keys = st.keys - 1;
                set_block(bx, by, bz, BLK_AIR);
                record_block_delta(bx, by, bz, BLK_AIR);
                queue_sfx(SFX_PICKUP);
                set_status_msg("Unlocked Vault Door using 1 Key!", 1800);
            } else {
                set_status_msg("Locked Vault Door — requires a Key!", 1600);
            }
            return;
        }
        if is_block_shrinkable(b) != 0 && (best_ring < 0 || best_d >= 1.6) {
            set_status_msg("Fractal Block! Press [SHRK] or fly into its 3D hole!", 1600);
            return;
        }
        t = t + 0.35;
    }

    if best_ring >= 0 {
        if st.ring_cd_ms > 0 { return; }
        let k = st.entities[best_ring].kind;
        let rx = clamp_i(ffloor(st.entities[best_ring].x), 0, 15);
        let ry = clamp_i(ffloor(st.entities[best_ring].y), 0, 15);
        let rz = clamp_i(ffloor(st.entities[best_ring].z), 0, 15);
        let tb = st.entities[best_ring].target_block;
        let tbio = st.entities[best_ring].target_biome;
        if k == ENT_RING_RED { grow_out_axis(st.px, st.py, st.pz); }
        else if k == ENT_RING_PINK || k == ENT_RING_DANGER { shrink_into_ex(rx, ry, rz, tb, tbio, 2, st.px, st.py, st.pz); }
        else { shrink_into_ex(rx, ry, rz, tb, tbio, 1, st.px, st.py, st.pz); }
        return;
    }

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
                if nb == BLK_BUY_STATION { st.screen = SCREEN_BUY; queue_sfx(SFX_CLICK); return; }
                if nb == BLK_SELL_STATION { st.screen = SCREEN_SELL; queue_sfx(SFX_CLICK); return; }
                if nb == BLK_BLACK_MARKET { st.screen = SCREEN_BLACK_MARKET; queue_sfx(SFX_CLICK); return; }
                if nb == BLK_UPGRADE_STATION { st.screen = SCREEN_UPGRADE; queue_sfx(SFX_CLICK); return; }
                if nb == BLK_ARCADE_CAB {
                    st.arcade_active = 1;
                    st.arcade_score = 0;
                    st.arcade_hits = 0;
                    st.arcade_timer_ms = 20000;
                    st.arcade_target = (rng_u32() % 12) as! i32;
                    queue_sfx(SFX_CLICK);
                    st.screen = SCREEN_ARCADE;
                    return;
                }
                if nb == BLK_TOME || nb == BLK_TEXT_BLOCK {
                    let cb = cur_biome();
                    st.tome_id = cb;
                    let bit: i32 = (1 as! i32) << clamp_i(cb, 0, 23);
                    if (st.tome_read_mask & bit) == 0 {
                        st.tome_read_mask = st.tome_read_mask | bit;
                        st.score_xp = st.score_xp + 40;
                    }
                    queue_sfx(SFX_PICKUP);
                    st.screen = SCREEN_TOME;
                    return;
                }
                if nb == BLK_MYSTERY_Q {
                    break_block_at(pbx + dx2, pby + dy2, pbz + dz2);
                    return;
                }
                dx2 = dx2 + 1;
            }
            dy2 = dy2 + 1;
        }
        dz2 = dz2 + 1;
    }

    set_status_msg("Nothing interactive ahead. Aim at a Station, Tome, [?], or Ring!", 1600);
}

fn handle_buy_action(choice: i32) {
    // Authentic Xar buy station menu (manual 8.4). Health/armor options bring
    // you UP TO the specified amount.
    let B = st.max_hp;
    if choice == 1 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.ammo[WEP_CANNON] = clamp_i(st.ammo[WEP_CANNON] + 20, 0, st.max_ammo[WEP_CANNON]);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Bought 20 Cannon ammo!", 1400);
    } else if choice == 2 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.ammo[WEP_LASER] = clamp_i(st.ammo[WEP_LASER] + 100, 0, st.max_ammo[WEP_LASER]);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Bought 100 Laser ammo!", 1400);
    } else if choice == 3 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.ammo[WEP_ROCKET] = clamp_i(st.ammo[WEP_ROCKET] + 50, 0, st.max_ammo[WEP_ROCKET]);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Bought 50 Rocket ammo!", 1400);
    } else if choice == 4 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.ammo[WEP_HOMING] = clamp_i(st.ammo[WEP_HOMING] + 1000, 0, st.max_ammo[WEP_HOMING]);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Bought 1000 Homing ammo!", 1400);
    } else if choice == 5 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.ammo[WEP_MINIGUN] = clamp_i(st.ammo[WEP_MINIGUN] + 100, 0, st.max_ammo[WEP_MINIGUN]);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Bought 100 Minigun ammo!", 1400);
    } else if choice == 6 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.ammo[WEP_RAILGUN] = clamp_i(st.ammo[WEP_RAILGUN] + 20, 0, st.max_ammo[WEP_RAILGUN]);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Bought 20 Railgun ammo!", 1400);
    } else if choice == 7 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.ammo[WEP_EMP] = clamp_i(st.ammo[WEP_EMP] + 1, 0, st.max_ammo[WEP_EMP]);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Bought 1 EMP charge!", 1400);
    } else if choice == 8 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.hp = clamp_i(B * 2, B, B * 2);
        queue_sfx(SFX_PICKUP);
        set_status_msg("200% Health!", 1400);
    } else if choice == 9 && st.gold >= 100 {
        st.gold = st.gold - 100;
        if st.armor < B { st.armor = B; }
        queue_sfx(SFX_PICKUP);
        set_status_msg("100% Armor!", 1400);
    } else if choice == 10 && st.gold >= 150 {
        st.gold = st.gold - 150;
        let want = (B * 3) / 2;
        if st.armor < want { st.armor = want; }
        queue_sfx(SFX_PICKUP);
        set_status_msg("150% Armor!", 1400);
    } else if choice == 11 && st.gold >= 200 {
        st.gold = st.gold - 200;
        let want = B * 2;
        if st.armor < want { st.armor = want; }
        queue_sfx(SFX_PICKUP);
        set_status_msg("200% Armor!", 1400);
    } else {
        set_status_msg("Not enough gold!", 1000);
        return;
    }
    st.autosave_dirty = 1;
}

fn handle_sell_action(choice: i32) {
    // Authentic: sell surplus ammo for gold (prices fixed here; Xar rolls them
    // per station color).
    if choice == 1 && st.ammo[WEP_LASER] >= 100 {
        st.ammo[WEP_LASER] = st.ammo[WEP_LASER] - 100;
        add_gold(40);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Sold 100 Laser ammo for +40 Gold!", 1400);
    } else if choice == 2 && st.ammo[WEP_CANNON] >= 50 {
        st.ammo[WEP_CANNON] = st.ammo[WEP_CANNON] - 50;
        add_gold(40);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Sold 50 Cannon ammo for +40 Gold!", 1400);
    } else if choice == 3 && st.ammo[WEP_ROCKET] >= 50 {
        st.ammo[WEP_ROCKET] = st.ammo[WEP_ROCKET] - 50;
        add_gold(40);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Sold 50 Rocket ammo for +40 Gold!", 1400);
    } else if choice == 4 && st.ammo[WEP_MINIGUN] >= 200 {
        st.ammo[WEP_MINIGUN] = st.ammo[WEP_MINIGUN] - 200;
        add_gold(40);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Sold 200 Minigun rounds for +40 Gold!", 1400);
    } else if choice == 5 && st.ammo[WEP_RAILGUN] >= 20 {
        st.ammo[WEP_RAILGUN] = st.ammo[WEP_RAILGUN] - 20;
        add_gold(60);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Sold 20 Railgun slugs for +60 Gold!", 1400);
    } else if choice == 6 && st.ammo[WEP_NUKE] >= 1 {
        st.ammo[WEP_NUKE] = st.ammo[WEP_NUKE] - 1;
        add_gold(80);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Sold 1 Nuke for +80 Gold!", 1400);
    } else {
        set_status_msg("Not enough surplus to sell!", 1000);
        return;
    }
    st.autosave_dirty = 1;
}

fn handle_black_market_action(choice: i32) {
    // Authentic menu (manual 8.5): cheaper railgun / EMP / nuke ammo.
    if choice == 1 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.ammo[WEP_RAILGUN] = clamp_i(st.ammo[WEP_RAILGUN] + 50, 0, st.max_ammo[WEP_RAILGUN]);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Black Market: 50 Railgun slugs!", 1400);
    } else if choice == 2 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.ammo[WEP_EMP] = clamp_i(st.ammo[WEP_EMP] + 2, 0, st.max_ammo[WEP_EMP]);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Black Market: 2 EMP charges!", 1400);
    } else if choice == 3 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.ammo[WEP_NUKE] = clamp_i(st.ammo[WEP_NUKE] + 2, 0, st.max_ammo[WEP_NUKE]);
        queue_sfx(SFX_PICKUP);
        set_status_msg("Black Market: 2 Nukes!", 1400);
    } else {
        set_status_msg("Not enough gold!", 1000);
        return;
    }
    st.autosave_dirty = 1;
}

// Upgrade Station (manual 8.6): the main gold sink. Buying a weapon's damage
// upgrade also unlocks that weapon ("any upgrade unlocks the weapon").
fn handle_upgrade_action(choice: i32) {
    if choice == 1 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.wep_dmg_lvl[WEP_PLASMA] = st.wep_dmg_lvl[WEP_PLASMA] + 1;
        st.plasma_regen_lvl = st.plasma_regen_lvl + 1;
        st.wep_unlocked[WEP_PLASMA] = 1;
        queue_sfx(SFX_PICKUP);
        set_status_msg("Plasma damage & recharge upgraded!", 1400);
    } else if choice == 2 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.wep_dmg_lvl[WEP_CANNON] = st.wep_dmg_lvl[WEP_CANNON] + 1;
        st.wep_vel_lvl[WEP_CANNON] = st.wep_vel_lvl[WEP_CANNON] + 1;
        st.wep_unlocked[WEP_CANNON] = 1;
        queue_sfx(SFX_PICKUP);
        set_status_msg("Cannon damage & velocity upgraded!", 1400);
    } else if choice == 3 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.wep_dmg_lvl[WEP_LASER] = st.wep_dmg_lvl[WEP_LASER] + 1;
        st.shield_cap_lvl = st.shield_cap_lvl + 1;
        refresh_derived();
        st.shields = st.max_shields;
        st.wep_unlocked[WEP_LASER] = 1;
        queue_sfx(SFX_PICKUP);
        set_status_msg("Laser damage & +10 Shield Cap upgraded!", 1400);
    } else if choice == 4 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.wep_dmg_lvl[WEP_ROCKET] = st.wep_dmg_lvl[WEP_ROCKET] + 1;
        st.wep_cap_lvl[WEP_ROCKET] = st.wep_cap_lvl[WEP_ROCKET] + 1;
        set_default_ammo_caps();
        st.wep_unlocked[WEP_ROCKET] = 1;
        queue_sfx(SFX_PICKUP);
        set_status_msg("Rocket damage & capacity upgraded!", 1400);
    } else if choice == 5 && st.gold >= 200 {
        st.gold = st.gold - 200;
        st.wep_dmg_lvl[WEP_RAILGUN] = st.wep_dmg_lvl[WEP_RAILGUN] + 1;
        st.wep_rof_lvl[WEP_RAILGUN] = st.wep_rof_lvl[WEP_RAILGUN] + 1;
        st.wep_unlocked[WEP_RAILGUN] = 1;
        queue_sfx(SFX_PICKUP);
        set_status_msg("Railgun damage & RoF upgraded!", 1400);
    } else if choice == 6 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.wep_dmg_lvl[WEP_EMP] = st.wep_dmg_lvl[WEP_EMP] + 1;
        st.emp_rad_lvl = st.emp_rad_lvl + 1;
        st.wep_unlocked[WEP_EMP] = 1;
        queue_sfx(SFX_PICKUP);
        set_status_msg("EMP damage & shockwave radius upgraded!", 1400);
    } else if choice == 7 && st.gold >= 200 {
        st.gold = st.gold - 200;
        st.wep_dmg_lvl[WEP_NUKE] = st.wep_dmg_lvl[WEP_NUKE] + 1;
        st.wep_cap_lvl[WEP_NUKE] = st.wep_cap_lvl[WEP_NUKE] + 1;
        set_default_ammo_caps();
        st.wep_unlocked[WEP_NUKE] = 1;
        queue_sfx(SFX_PICKUP);
        set_status_msg("Nuke damage & max capacity upgraded!", 1400);
    } else if choice == 8 && st.gold >= 300 {
        st.gold = st.gold - 300;
        st.wep_dmg_lvl[WEP_DARKHOLE] = st.wep_dmg_lvl[WEP_DARKHOLE] + 1;
        st.wep_cap_lvl[WEP_DARKHOLE] = st.wep_cap_lvl[WEP_DARKHOLE] + 1;
        set_default_ammo_caps();
        st.wep_unlocked[WEP_DARKHOLE] = 1;
        queue_sfx(SFX_PICKUP);
        set_status_msg("Dark Hole damage & capacity upgraded!", 1400);
    } else if choice == 9 && st.gold >= 200 {
        st.gold = st.gold - 200;
        st.max_hp = st.max_hp + 20;
        st.hp = st.max_hp;
        refresh_derived();
        st.shields = st.max_shields;
        queue_sfx(SFX_PICKUP);
        set_status_msg("Health capacity upgraded! (+Shield too)", 1400);
    } else if choice == 10 && st.gold >= 100 {
        st.gold = st.gold - 100;
        st.hp_regen = st.hp_regen + 1;
        queue_sfx(SFX_PICKUP);
        set_status_msg("Health regen upgraded! (Shield & HP regen faster)", 1400);
    } else {
        set_status_msg("Not enough gold!", 1000);
        return;
    }
    st.autosave_dirty = 1;
}

fn handle_arcade_tap(cell: i32) {
    if st.arcade_active == 0 { return; }
    if cell == st.arcade_target {
        st.arcade_hits = st.arcade_hits + 1;
        st.arcade_score = st.arcade_score + 100;
        add_gold(15);
        award_xp(25);
        if st.arcade_score > st.arcade_best {
            st.arcade_best = st.arcade_score;
        }
        if st.arcade_score >= 600 {
            award_trophy_id(6, "TROPHY: ARCADE MASTER! (+600 Score)");
        }
        st.arcade_target = ((st.arcade_target + 1 + ((rng_u32() % 11) as! i32)) % 12);
        queue_sfx(SFX_PICKUP);
    } else {
        queue_sfx(SFX_CLICK);
    }
}

fn step_simulation(dt_ms: i32) {
    if st.screen != SCREEN_PLAY { return; }
    st.anim_ms = st.anim_ms + (dt_ms as i64);
    st.play_ms = st.play_ms + (dt_ms as i64);
    let dt = (dt_ms as f64) / 1000.0;

    if st.fire_cd_ms > 0 { st.fire_cd_ms = st.fire_cd_ms - dt_ms; if st.fire_cd_ms < 0 { st.fire_cd_ms = 0; } }
    if st.ring_cd_ms > 0 { st.ring_cd_ms = st.ring_cd_ms - dt_ms; if st.ring_cd_ms < 0 { st.ring_cd_ms = 0; } }
    if st.beam_timer_ms > 0 { st.beam_timer_ms = st.beam_timer_ms - dt_ms; if st.beam_timer_ms < 0 { st.beam_timer_ms = 0; } }
    if st.flash_ms > 0 { st.flash_ms = st.flash_ms - dt_ms; if st.flash_ms < 0 { st.flash_ms = 0; } }
    if st.msg_ms > 0 { st.msg_ms = st.msg_ms - dt_ms; if st.msg_ms < 0 { st.msg_ms = 0; } }
    if st.telekinesis_ms > 0 { st.telekinesis_ms = st.telekinesis_ms - dt_ms; if st.telekinesis_ms < 0 { st.telekinesis_ms = 0; } }
    if st.turning_ms > 0 { st.turning_ms = st.turning_ms - dt_ms; if st.turning_ms < 0 { st.turning_ms = 0; } }
    if st.black_hole_drive_ms > 0 { st.black_hole_drive_ms = st.black_hole_drive_ms - dt_ms; if st.black_hole_drive_ms < 0 { st.black_hole_drive_ms = 0; } }
    if st.quasar_drive_ms > 0 { st.quasar_drive_ms = st.quasar_drive_ms - dt_ms; if st.quasar_drive_ms < 0 { st.quasar_drive_ms = 0; } }
    if st.hazard_cd_ms > 0 { st.hazard_cd_ms = st.hazard_cd_ms - dt_ms; if st.hazard_cd_ms < 0 { st.hazard_cd_ms = 0; } }
    // Short Marker 3-hour (10,800,000 ms) expiration rule
    if st.markers[0].used != 0 && st.mut_inf_markers == 0 && (st.play_ms - st.markers[0].created_ms) >= SHORT_MARKER_TTL_MS {
        st.markers[0].used = 0;
        if st.active_marker == 0 { st.active_marker = -1; }
        set_status_msg("Short Marker expired after 3h!", 1800);
    }

    // 1-second rolling DPS meter
    st.dps_timer_ms = st.dps_timer_ms + dt_ms;
    if st.dps_timer_ms >= 1000 {
        st.dps_val = st.dps_accum;
        st.dps_accum = 0;
        st.dps_timer_ms = st.dps_timer_ms - 1000;
    }

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

    // Authentic regeneration (manual section 7), X = health regen level:
    //   shield  (1 + X/4) points/sec    health (1 + X/4)/2 points/sec
    //   plasma  0.5 ammo/sec
    // Overhealed health (> basic max) drains 1 hp/sec.
    let rl = st.hp_regen;
    if st.shields < st.max_shields {
        st.shield_accum_ms = st.shield_accum_ms + dt_ms;
        let per: i32 = 4000 / (4 + rl);
        while st.shield_accum_ms >= per && st.shields < st.max_shields {
            st.shield_accum_ms = st.shield_accum_ms - per;
            st.shields = st.shields + 1;
        }
        if st.shields >= st.max_shields { st.shield_accum_ms = 0; }
    } else {
        st.shield_accum_ms = 0;
    }
    if st.hp < st.max_hp {
        st.regen_accum_ms = st.regen_accum_ms + dt_ms;
        let per: i32 = 8000 / (4 + rl);
        while st.regen_accum_ms >= per && st.hp < st.max_hp {
            st.regen_accum_ms = st.regen_accum_ms - per;
            st.hp = st.hp + 1;
        }
        if st.hp >= st.max_hp { st.regen_accum_ms = 0; }
    }
    if st.hp > st.max_hp * 2 {
        st.shield_regen = st.shield_regen + dt_ms;   // overheal decay accumulator
        while st.shield_regen >= 1000 && st.hp > st.max_hp * 2 {
            st.shield_regen = st.shield_regen - 1000;
            st.hp = st.hp - 1;
        }
    } else {
        st.shield_regen = 0;
    }
    if st.ammo[WEP_PLASMA] < st.max_ammo[WEP_PLASMA] {
        st.plasma_regen_ms = st.plasma_regen_ms + dt_ms;
        let p_period = clamp_i(2000 - st.plasma_regen_lvl * 220, 450, 2000);
        while st.plasma_regen_ms >= p_period {
            st.plasma_regen_ms = st.plasma_regen_ms - p_period;
            if st.ammo[WEP_PLASMA] < st.max_ammo[WEP_PLASMA] {
                st.ammo[WEP_PLASMA] = st.ammo[WEP_PLASMA] + 1;
            }
        }
    } else {
        st.plasma_regen_ms = 0;
    }

    // Environmental Hazard check (Quicksand, Solar Corona Plasma, Event Horizon)
    let hblk = world_block_rel(ffloor(st.px), ffloor(st.py - 0.35), ffloor(st.pz));
    if hblk == BLK_QUICKSAND {
        st.vx = st.vx * 0.55;
        st.vz = st.vz * 0.55;
        if st.hazard_cd_ms <= 0 {
            damage_player(4);
            st.hazard_cd_ms = 750;
        }
    } else if hblk == BLK_SOLAR_PLASMA || hblk == BLK_EVENT_HORIZON {
        if st.hazard_cd_ms <= 0 {
            damage_player(if hblk == BLK_EVENT_HORIZON { 14 } else { 9 });
            st.hazard_cd_ms = 650;
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

    // Active Spawner Hives: periodically spawn enemy waves when monster population < 10
    if st.genesis_mode == 0 {
        st.spawner_timer_ms = st.spawner_timer_ms - dt_ms;
        if st.spawner_timer_ms <= 0 {
            st.spawner_timer_ms = 3200;
            var mon_cnt: i32 = 0;
            var mi: i32 = 0;
            let mon_cap = if st.mut_double_monsters != 0 { 18 } else { 10 };
            while mi < MAX_ENTITIES {
                if st.entities[mi].active != 0 &&
                   is_enemy_kind(st.entities[mi].kind) != 0 {
                    mon_cnt = mon_cnt + 1;
                }
                mi = mi + 1;
            }
            if mon_cnt < mon_cap {
                var spawned: i32 = 0;
                var sy: i32 = 1;
                while sy < 15 && spawned == 0 {
                    var sz: i32 = 1;
                    while sz < 15 && spawned == 0 {
                        var sx: i32 = 1;
                        while sx < 15 && spawned == 0 {
                            if get_block(sx, sy, sz) == BLK_SPAWNER {
                                if get_block(sx, sy + 1, sz) == BLK_AIR {
                                    let cb = cur_biome();
                                    let sk = if cb == BIOME_INNER_CORE || cb == BIOME_TON618 { ENT_DEMON }
                                             else if cb == BIOME_BLACK_CUBE { ENT_MENACE }
                                             else if cb == BIOME_YING_FOREST { ENT_GOON }
                                             else if cb == BIOME_RED_CAVES { ENT_LAMPREY }
                                             else if cb == BIOME_ARCADE { ENT_ARCADE_DRONE }
                                             else if cb == BIOME_BOTANY_LAB { ENT_GROWER }
                                             else { ENT_SPIDER };
                                    let shp = 34 + (if st.depth > 0 { st.depth * 18 } else { 0 });
                                    let _ = spawn_entity(sk, (sx as f64) + 0.5, (sy as f64) + 1.5, (sz as f64) + 0.5, shp, -1, 0);
                                    spawn_burst((sx as f64) + 0.5, (sy as f64) + 1.5, (sz as f64) + 0.5, pack_rgb(230, 56, 86), 8);
                                    spawned = 1;
                                }
                            }
                            sx = sx + 1;
                        }
                        sz = sz + 1;
                    }
                    sy = sy + 1;
                }
            }
        }
    }

    // Probe block directly in front for HUD context prompt
    st.near_prompt_len = 0;
    var fx: f64 = 0.0;
    var fy: f64 = 0.0;
    var fz: f64 = 0.0;
    camera_forward(fx, fy, fz);
    var pt: f64 = 0.5;
    while pt <= 2.4 {
        let blk = world_block_rel(ffloor(st.px + fx * pt), ffloor(st.py + fy * pt), ffloor(st.pz + fz * pt));
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
        // Minigun poison: damage over time, ignores freeze (manual 9.7).
        if st.entities[i].poison_ms > 0 {
            st.entities[i].poison_ms = st.entities[i].poison_ms - dt_ms;
            if st.entities[i].poison_ms < 0 { st.entities[i].poison_ms = 0; }
            st.entities[i].poison_acc = st.entities[i].poison_acc + st.entities[i].poison_dps * dt_ms;
            if st.entities[i].poison_acc >= 4000 {
                let pd = st.entities[i].poison_acc / 1000;
                st.entities[i].poison_acc = st.entities[i].poison_acc - pd * 1000;
                damage_entity(i, pd, 0);
                if st.entities[i].active == 0 { i = i + 1; continue; }
            }
        }
        let dx = st.px - st.entities[i].x;
        let dy = st.py - st.entities[i].y;
        let dz = st.pz - st.entities[i].z;
        let dist = fsqrt(dx * dx + dy * dy + dz * dz);

        if (k >= ENT_RING_GREEN && k <= ENT_RING_PINK) || k == ENT_RING_DANGER {
            if dist < 2.6 { st.near_ring_kind = k; }
        } else if k == ENT_FRIEND_K {
            if dist < 1.25 {
                if st.singularity_defeated == 0 && st.genesis_mode == 0 {
                    if st.msg_ms <= 0 {
                        set_status_msg("Friend 'K' is sealed! Defeat The Singularity Boss first!", 1800);
                    }
                } else {
                    st.k_rescued = 1;
                    st.entities[i].active = 0;
                    add_gold(500);
                    award_trophy(64, "TROPHY: FRIEND 'K' RESCUED!");
                    st.screen = SCREEN_VICTORY;
                    return;
                }
            }
        } else if k >= ENT_GOLD && k <= ENT_KEY {
            if dist < 1.15 {
                st.entities[i].active = 0;
                award_xp(15);
                mark_entity_cleared(cur_seed(), st.entities[i].slot_id);
                queue_sfx(SFX_PICKUP);
                if k == ENT_GOLD {
                    let gain = 15 + (if st.depth > 0 { st.depth * 8 } else { 0 });
                    add_gold(gain);
                    set_status_msg("+Gold collected!", 900);
                } else if k == ENT_HEALTH {
                    // Authentic health tiers (manual 7.2), B = basic max health.
                    // hp: 1 small +B/10 (<=2B), 2 med +B/4 (<=B), 3 to-B, 4 to-2B, 5 mega +B (<=5B), 6 shield box.
                    let B = st.max_hp;
                    let tier = st.entities[i].hp;
                    if tier == 6 {
                        st.shields = st.max_shields;
                        set_status_msg("Shield fully recharged!", 900);
                    } else if tier == 2 {
                        st.hp = clamp_i(st.hp + B / 4, 0, B);
                        set_status_msg("+Health restored!", 900);
                    } else if tier == 3 {
                        if st.hp < B { st.hp = B; }
                        set_status_msg("Health restored to 100%!", 900);
                    } else if tier == 4 {
                        st.hp = clamp_i(st.hp + B, 0, B * 2);
                        set_status_msg("Health restored to 200%!", 1000);
                    } else if tier == 5 {
                        st.hp = clamp_i(st.hp + B, 0, B * 5);
                        set_status_msg("MEGAHEALTH!", 1100);
                    } else {
                        st.hp = clamp_i(st.hp + (B + 9) / 10, 0, B * 2);
                        set_status_msg("+Health restored!", 900);
                    }
                } else if k == ENT_ARMOR {
                    // Authentic armor tiers (manual 7.3).
                    // hp: 1 bronze ->B, 2 silver ->1.5B, 3 gold ->2B, 4 ivory ->6B, 5 jade ->10B, 6 shard +B/20, 7 shard +B/10.
                    let B = st.max_hp;
                    let tier = st.entities[i].hp;
                    if tier == 2 {
                        let want = (B * 3) / 2;
                        if st.armor < want { st.armor = want; }
                        set_status_msg("Silver Armor!", 900);
                    } else if tier == 3 {
                        let want = B * 2;
                        if st.armor < want { st.armor = want; }
                        set_status_msg("Gold Armor!", 900);
                    } else if tier == 4 {
                        let want = B * 6;
                        if st.armor < want { st.armor = want; }
                        set_status_msg("Ivory Armor!", 900);
                    } else if tier == 5 {
                        let want = B * 10;
                        if st.armor < want { st.armor = want; }
                        set_status_msg("JADE ARMOR (oh yeah)!", 1100);
                    } else if tier == 6 {
                        st.armor = clamp_i(st.armor + B / 20, 0, B * 2);
                        set_status_msg("+Armor shards!", 900);
                    } else if tier == 7 {
                        st.armor = clamp_i(st.armor + B / 10, 0, st.max_armor);
                        set_status_msg("+Armor shards!", 900);
                    } else {
                        if st.armor < B { st.armor = B; }
                        set_status_msg("Bronze Armor!", 900);
                    }
                } else if k == ENT_KEY {
                    st.keys = st.keys + 1;
                    set_status_msg("+1 Vault Key collected!", 1100);
                } else if k == ENT_AMMO {
                    // Authentic per-weapon ammo boxes (manual section 9). hp = weapon+1.
                    let wi = st.entities[i].hp - 1;
                    if wi == WEP_PLASMA {
                        st.ammo[WEP_PLASMA] = st.max_ammo[WEP_PLASMA];
                        set_status_msg("Plasma ammo refilled!", 900);
                    } else if wi == WEP_CANNON {
                        st.ammo[WEP_CANNON] = clamp_i(st.ammo[WEP_CANNON] + 5, 0, st.max_ammo[WEP_CANNON]);
                        set_status_msg("+5 Cannon ammo!", 900);
                    } else if wi == WEP_LASER {
                        st.ammo[WEP_LASER] = clamp_i(st.ammo[WEP_LASER] + 8, 0, st.max_ammo[WEP_LASER]);
                        set_status_msg("+8 Laser ammo!", 900);
                    } else if wi == WEP_ROCKET {
                        st.ammo[WEP_ROCKET] = clamp_i(st.ammo[WEP_ROCKET] + 5, 0, st.max_ammo[WEP_ROCKET]);
                        set_status_msg("+5 Rocket ammo!", 900);
                    } else if wi == WEP_HOMING {
                        st.ammo[WEP_HOMING] = clamp_i(st.ammo[WEP_HOMING] + 10, 0, st.max_ammo[WEP_HOMING]);
                        set_status_msg("+10 Homing ammo!", 900);
                    } else if wi == WEP_MINIGUN {
                        st.ammo[WEP_MINIGUN] = clamp_i(st.ammo[WEP_MINIGUN] + 12, 0, st.max_ammo[WEP_MINIGUN]);
                        set_status_msg("+12 Minigun ammo!", 900);
                    } else if wi == WEP_RAILGUN {
                        st.ammo[WEP_RAILGUN] = clamp_i(st.ammo[WEP_RAILGUN] + 10, 0, st.max_ammo[WEP_RAILGUN]);
                        set_status_msg("+10 Railgun ammo!", 900);
                    } else if wi == WEP_EMP {
                        st.ammo[WEP_EMP] = clamp_i(st.ammo[WEP_EMP] + 1, 0, st.max_ammo[WEP_EMP]);
                        set_status_msg("+1 EMP charge!", 900);
                    } else if wi == WEP_NUKE {
                        st.ammo[WEP_NUKE] = clamp_i(st.ammo[WEP_NUKE] + 1, 0, st.max_ammo[WEP_NUKE]);
                        set_status_msg("+1 Nuke!", 900);
                    } else {
                        st.ammo[WEP_DARKHOLE] = st.max_ammo[WEP_DARKHOLE];
                        set_status_msg("Dark Hole ammo refilled!", 900);
                    }
                }
            }
        } else if k == ENT_FLARE {
            st.entities[i].cooldown = st.entities[i].cooldown - dt_ms;
            if st.entities[i].cooldown <= 0 {
                st.entities[i].active = 0;
            }
        } else if is_enemy_kind(k) != 0 {
            if st.entities[i].freeze_ms > 0 {
                i = i + 1;
                continue;
            }
            // Special entity abilities: Hydra regen, Grower scale up, Shrinker scale down
            if k == ENT_HYDRA && st.entities[i].hp < st.entities[i].max_hp {
                st.entities[i].hp = clamp_i(st.entities[i].hp + (dt_ms / 180 + 1), 1, st.entities[i].max_hp);
            } else if k == ENT_GROWER && st.entities[i].max_hp < 420 && ((st.anim_ms % 500) < (dt_ms as i64)) {
                st.entities[i].max_hp = st.entities[i].max_hp + 2;
                st.entities[i].hp = st.entities[i].hp + 2;
            } else if k == ENT_SHRINKER && st.entities[i].hp > 18 && ((st.anim_ms % 600) < (dt_ms as i64)) {
                st.entities[i].hp = st.entities[i].hp - 1;
            }
            if dist > 0.2 && dist < 14.0 {
                let spd =
                    if k == ENT_RAT || k == ENT_GNAT || k == ENT_BABY_SPIDER { 2.9 }
                    else if k == ENT_SPIDER || k == ENT_SHRINKER { 2.4 }
                    else if k == ENT_GOON || k == ENT_TWEEDLE { 1.8 }
                    else if k == ENT_MARINE || k == ENT_LAMPREY { 1.6 }
                    else if k == ENT_PIRATE || k == ENT_ARCADE_DRONE { 2.15 }
                    else if k == ENT_YINYANG || k == ENT_BEHOLDER { 1.65 }
                    else if k == ENT_MENACE || k == ENT_HEX_SENTRY { 0.85 }
                    else if k == ENT_DEMON || k == ENT_SLIVER || k == ENT_ROCKET_SPIDER { 1.95 }
                    else if k == ENT_BURLY || k == ENT_GROWER { 1.15 }
                    else if k == ENT_GUARDIAN || k == ENT_VULCAN || k == ENT_HYDRA { 1.25 }
                    else { 1.55 };
                if dist > 1.35 {
                    let nx = st.entities[i].x + (dx / dist) * spd * dt;
                    let ny = st.entities[i].y + (dy / dist) * spd * 0.75 * dt;
                    let nz = st.entities[i].z + (dz / dist) * spd * dt;
                    let mystical = is_enemy_mystical(k);
                    if mystical != 0 || is_block_solid(get_block(ffloor(nx), ffloor(st.entities[i].y), ffloor(st.entities[i].z))) == 0 {
                        st.entities[i].x = fclamp(nx, 0.5, 15.5);
                    }
                    if mystical != 0 || is_block_solid(get_block(ffloor(st.entities[i].x), ffloor(ny), ffloor(st.entities[i].z))) == 0 {
                        st.entities[i].y = fclamp(ny, 0.5, 15.5);
                    }
                    if mystical != 0 || is_block_solid(get_block(ffloor(st.entities[i].x), ffloor(st.entities[i].y), ffloor(nz))) == 0 {
                        st.entities[i].z = fclamp(nz, 0.5, 15.5);
                    }
                }
                st.entities[i].cooldown = st.entities[i].cooldown - dt_ms;
                if st.entities[i].cooldown <= 0 {
                    if dist < 1.4 {
                        damage_player(6 + (if st.depth > 0 { st.depth * 2 } else { 0 }));
                        st.entities[i].cooldown = 850;
                    } else if dist < 12.5 && k != ENT_RAT && k != ENT_BABY_SPIDER {
                        let is_boss = (k == ENT_SINGULARITY || k == ENT_TON618_BOSS);
                        let low_hp = is_boss && st.entities[i].hp * 2 < st.entities[i].max_hp;
                        let sspd = if k == ENT_TON618_BOSS { 10.5 } else if k == ENT_SINGULARITY { 9.5 } else if k == ENT_ROCKET_SPIDER { 8.5 } else { 7.5 };
                        let edmg = 6 + (if st.depth > 0 { st.depth * 2 } else { 0 }) + (if is_boss { 12 } else if k == ENT_ROCKET_SPIDER || k == ENT_VULCAN { 6 } else { 0 });
                        let ergb = if k == ENT_TON618_BOSS { pack_rgb(255, 140, 40) } else if k == ENT_SINGULARITY { pack_rgb(255, 64, 210) } else { pack_rgb(255, 92, 64) };
                        spawn_shot(0, 0, 0, st.entities[i].x, st.entities[i].y, st.entities[i].z,
                            (dx / dist) * sspd, (dy / dist) * sspd, (dz / dist) * sspd, edmg, 1750, ergb);
                        if low_hp {
                            // Phase-2 multi-shot radial spread on bosses
                            spawn_shot(0, 0, 0, st.entities[i].x, st.entities[i].y, st.entities[i].z,
                                (-dz / dist) * sspd * 0.85, (dy / dist) * sspd * 0.85, (dx / dist) * sspd * 0.85, edmg, 1500, ergb);
                            spawn_shot(0, 0, 0, st.entities[i].x, st.entities[i].y, st.entities[i].z,
                                (dz / dist) * sspd * 0.85, (dy / dist) * sspd * 0.85, (-dx / dist) * sspd * 0.85, edmg, 1500, ergb);
                        }
                        st.entities[i].cooldown = if is_boss { if low_hp { 480 } else { 650 } } else if k == ENT_MENACE || k == ENT_HEX_SENTRY { 1050 } else { 1500 };
                    }
                }
            }
        }
        i = i + 1;
    }

    // Update projectiles (with cross-neighbor chunk collision & Short Marker Plasma destruction!)
    i = 0;
    while i < MAX_SHOTS {
        if st.shots[i].active == 0 {
            i = i + 1;
            continue;
        }
        st.shots[i].ttl_ms = st.shots[i].ttl_ms - dt_ms;

        if st.shots[i].from_player != 0 && st.shots[i].wep == WEP_HOMING {
            var best_e: i32 = -1;
            var best_ed: f64 = 12.0;
            var ei: i32 = 0;
            while ei < MAX_ENTITIES {
                if st.entities[ei].active != 0 && is_enemy_kind(st.entities[ei].kind) != 0 {
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
                if st.shots[i].wep == WEP_PLASMA && st.shots[i].secondary == 5 {
                    let fi = spawn_entity(ENT_FLARE, st.shots[i].x, st.shots[i].y, st.shots[i].z, 1, -1, 0);
                    if fi >= 0 { st.entities[fi].cooldown = 25000; }
                } else {
                    let _ = shot_explode(st.shots[i].x, st.shots[i].y, st.shots[i].z,
                        st.shots[i].wep, st.shots[i].secondary, st.shots[i].dmg, st.shots[i].rgb, -1);
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
        if bx < -16 || bx >= 32 || by < -16 || by >= 32 || bz < -16 || bz >= 32 {
            st.shots[i].active = 0;
            i = i + 1;
            continue;
        }
        let blk = world_block_rel(bx, by, bz);
        if is_block_solid(blk) != 0 {
            if st.shots[i].from_player != 0 {
                let sw = st.shots[i].wep;
                let smode = st.shots[i].secondary;
                if sw == WEP_PLASMA && smode == 5 {
                    let fi = spawn_entity(ENT_FLARE, st.shots[i].x, st.shots[i].y, st.shots[i].z, 1, -1, 0);
                    if fi >= 0 { st.entities[fi].cooldown = 30000; }
                    spawn_burst(st.shots[i].x, st.shots[i].y, st.shots[i].z, pack_rgb(255, 236, 150), 8);
                } else {
                    let exploded = shot_explode(nx, ny, nz, sw, smode, st.shots[i].dmg, st.shots[i].rgb, -1);
                    if exploded == 0 {
                        spawn_burst(nx, ny, nz, st.shots[i].rgb, 5);
                        if bx >= 0 && bx < 16 && by >= 0 && by < 16 && bz >= 0 && bz < 16 && is_block_destructible(blk) != 0 {
                            damage_block_at(bx, by, bz, st.shots[i].dmg);
                        }
                    }
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
            // Allow shooting Short Marker with Weapon 1 (Plasma) to destroy it cleanly
            if st.shots[i].wep == WEP_PLASMA && st.markers[0].used != 0 && st.markers[0].depth == st.depth {
                let mdx = st.markers[0].px - nx;
                let mdy = st.markers[0].py - ny;
                let mdz = st.markers[0].pz - nz;
                if (mdx * mdx + mdy * mdy + mdz * mdz) < 0.45 {
                    st.markers[0].used = 0;
                    if st.active_marker == 0 { st.active_marker = -1; }
                    spawn_burst(st.markers[0].px, st.markers[0].py, st.markers[0].pz, pack_rgb(74, 222, 128), 12);
                    queue_sfx(SFX_PICKUP);
                    set_status_msg("Short Marker cleared!", 1200);
                    st.shots[i].active = 0;
                    i = i + 1;
                    continue;
                }
            }

            var ei: i32 = 0;
            while ei < MAX_ENTITIES {
                if st.entities[ei].active != 0 && is_enemy_kind(st.entities[ei].kind) != 0 {
                    let ex = st.entities[ei].x - nx;
                    let ey = st.entities[ei].y - ny;
                    let ez = st.entities[ei].z - nz;
                    if (ex * ex + ey * ey + ez * ez) < 0.45 {
                        let sw = st.shots[i].wep;
                        let smode = st.shots[i].secondary;
                        if sw == WEP_MINIGUN && smode == 1 {
                            // Poison dart: no impact damage; applies/extends poison.
                            st.entities[ei].poison_ms = clamp_i(st.entities[ei].poison_ms + 10000, 0, 40000);
                            st.entities[ei].poison_dps = st.shots[i].dmg;
                            st.entities[ei].poison_acc = 0;
                            spawn_burst(nx, ny, nz, pack_rgb(134, 239, 172), 4);
                        } else if st.shots[i].dmg > 0 {
                            damage_entity(ei, st.shots[i].dmg, 0);
                            let killed = st.entities[ei].active == 0;
                            if sw == WEP_CANNON && (smode == 0 || smode == 3 || smode == 4) && killed {
                                // Chaining effect: retarget the next closest monster.
                                var best_e: i32 = -1;
                                var best_d: f64 = 28.0;
                                var cj: i32 = 0;
                                while cj < MAX_ENTITIES {
                                    if cj != ei && st.entities[cj].active != 0 && is_enemy_kind(st.entities[cj].kind) != 0 {
                                        let cx = st.entities[cj].x - st.entities[ei].x;
                                        let cy = st.entities[cj].y - st.entities[ei].y;
                                        let cz = st.entities[cj].z - st.entities[ei].z;
                                        let cd = fsqrt(cx * cx + cy * cy + cz * cz);
                                        if cd < best_d { best_d = cd; best_e = cj; }
                                    }
                                    cj = cj + 1;
                                }
                                if best_e >= 0 {
                                    let cx = st.entities[best_e].x - st.entities[ei].x;
                                    let cy = st.entities[best_e].y - st.entities[ei].y;
                                    let cz = st.entities[best_e].z - st.entities[ei].z;
                                    let cd = fsqrt(cx * cx + cy * cy + cz * cz);
                                    if cd > 0.05 {
                                        spawn_shot(1, sw, smode, st.entities[ei].x, st.entities[ei].y, st.entities[ei].z,
                                            (cx / cd) * 22.0, (cy / cd) * 22.0, (cz / cd) * 22.0,
                                            st.shots[i].dmg, 1500, st.shots[i].rgb);
                                    }
                                }
                            }
                        }
                        let _ = shot_explode(nx, ny, nz, sw, smode, st.shots[i].dmg, st.shots[i].rgb, ei);
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

    update_crosshair_target();
}
