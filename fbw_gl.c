#include "fbw_gl.h"

#include <GLES3/gl3.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifndef FBW_VIS_DEFAULT
#define FBW_VIS_DEFAULT __attribute__((visibility("default")))
#endif

// Block IDs matching fbw_core.goose
#define BLK_AIR           0
#define BLK_WALL_TUT      1
#define BLK_GRASS         2
#define BLK_DIRT          3
#define BLK_WOOD          4
#define BLK_LEAVES        5
#define BLK_PETAL_Y       6
#define BLK_POLLEN        7
#define BLK_PETAL_W       8
#define BLK_MYLANTIS      9
#define BLK_ICE           10
#define BLK_SAND          11
#define BLK_GLASS         12
#define BLK_STONE         13
#define BLK_GOLD_ORE      14
#define BLK_CRATE         15
#define BLK_SPAWNER       16
#define BLK_LOCKED_DOOR   17

#define BLK_MYSTERY_Q     18
#define BLK_HAZARD_NUKE   19

#define BLK_BLACK_CUBE    20
#define BLK_WHITE_FLOWER  21
#define BLK_ALPHA_CUBE    22
#define BLK_FLOWER_Y_CORE 23
#define BLK_MYLANTIS_M    24
#define BLK_YING_PLANET   25
#define BLK_ICE_WORLD     26
#define BLK_DESERT_WORLD  27
#define BLK_CORE_GATE     28
#define BLK_TOPAZ_CHECK   29
#define BLK_INFINITY_RED  30
#define BLK_TEXT_BLOCK    31

#define BLK_BUY_STATION   32
#define BLK_SELL_STATION  33
#define BLK_BLACK_MARKET  34
#define BLK_TOME          35
#define BLK_UPG_HP        36
#define BLK_UPG_REGEN     37
#define BLK_UPG_ARMOR     38
#define BLK_UPG_DMG       39
#define BLK_UPG_ROF       40
#define BLK_UPG_AMMO      41
#define BLK_UPG_SPEED     42
#define BLK_KEY_BLOCK     43
#define BLK_UPG_WEP       44

// Entity kinds matching fbw_core.goose
#define ENT_RING_GREEN    1
#define ENT_RING_RED      2
#define ENT_RING_BLUE     3
#define ENT_RING_PINK     4
#define ENT_RAT           5
#define ENT_SPIDER        6
#define ENT_GOON          7
#define ENT_MARINE        8
#define ENT_PIRATE        9
#define ENT_YINYANG       10
#define ENT_MENACE        11
#define ENT_DEMON         12
#define ENT_GUARDIAN      13
#define ENT_SINGULARITY   14
#define ENT_GOLD          15
#define ENT_HEALTH        16
#define ENT_ARMOR         17
#define ENT_AMMO          18
#define ENT_KEY           19
#define ENT_FRIEND_K      20
#define ENT_RING_DANGER   21
#define ENT_MARKER_BEACON 22

#define CHUNK_DIM         16
#define CHUNK_VOL         4096
#define MAX_LAYERS        6
#define MAX_PARENTS       5
#define MAX_NEIGHBORS     342
#define NEIGH_MAP_DIM     7   /* offsets -3..3 encoded base-7 */
#define NEIGH_MAP_SIZE    (NEIGH_MAP_DIM * NEIGH_MAP_DIM * NEIGH_MAP_DIM)
#define MAX_INWARD_SLOTS    256
#define MAX_L1_INWARD_SLOTS 64
#define MAX_BAND1_INIT      131072
#define MAX_BAND1_HARD_CAP  4194304
#define MAX_SLOT_SCRATCH    65536
#define MAX_BAND2_VERTS   65536
#define MAX_BAND3_VERTS   65536
#define MAX_DYN_VERTS     32768
#define MAX_ENTS          96
#define MAX_SHOTS         72
#define MAX_PARTS         72

typedef struct {
    float x, y, z;
    float u, v, light, style;
    uint8_t r, g, b, a;
} FbwVert;

typedef struct {
    int kind;
    float x, y, z;
    int hp, max_hp, freeze_ms;
} FbwEnt;

typedef struct {
    float x, y, z;
    uint32_t rgb;
} FbwPt;

// Chunk + 5-parent layer + 10-neighbor storage
static uint8_t g_chunks[MAX_LAYERS][CHUNK_VOL];
static int g_parent_valid[MAX_PARENTS] = {0, 0, 0, 0, 0};
static int g_parent_bx[MAX_PARENTS] = {0, 0, 0, 0, 0};
static int g_parent_by[MAX_PARENTS] = {0, 0, 0, 0, 0};
static int g_parent_bz[MAX_PARENTS] = {0, 0, 0, 0, 0};
static int g_parent_biome[MAX_PARENTS] = {0, 0, 0, 0, 0};

static uint8_t g_neighbors[MAX_NEIGHBORS][CHUNK_VOL];
static int g_neighbor_valid[MAX_NEIGHBORS] = {0};
static int g_neighbor_dx[MAX_NEIGHBORS] = {0};
static int g_neighbor_dy[MAX_NEIGHBORS] = {0};
static int g_neighbor_dz[MAX_NEIGHBORS] = {0};
static int g_neighbor_biome[MAX_NEIGHBORS] = {0};
static int g_chunks_dirty = 1;

// Inward 1/16x LOD slots + incremental per-slot VBO cache
static uint8_t g_inward[MAX_INWARD_SLOTS][CHUNK_VOL];
static int g_inward_valid[MAX_INWARD_SLOTS];
static int g_inward_bx[MAX_INWARD_SLOTS];
static int g_inward_by[MAX_INWARD_SLOTS];
static int g_inward_bz[MAX_INWARD_SLOTS];
static int g_inward_biome[MAX_INWARD_SLOTS];
static int g_inward_grid[CHUNK_VOL];
static GLuint g_inw_vbos[MAX_INWARD_SLOTS];
static int g_inw_vcnt[MAX_INWARD_SLOTS];
static uint8_t g_inw_vbo_dirty[MAX_INWARD_SLOTS];

static uint8_t g_l1_inward[MAX_L1_INWARD_SLOTS][CHUNK_VOL];
static int g_l1_inward_valid[MAX_L1_INWARD_SLOTS];
static int g_l1_inward_bx[MAX_L1_INWARD_SLOTS];
static int g_l1_inward_by[MAX_L1_INWARD_SLOTS];
static int g_l1_inward_bz[MAX_L1_INWARD_SLOTS];
static int g_l1_inward_biome[MAX_L1_INWARD_SLOTS];
static int g_l1_inward_grid[CHUNK_VOL];
static GLuint g_l1_inw_vbos[MAX_L1_INWARD_SLOTS];
static int g_l1_inw_vcnt[MAX_L1_INWARD_SLOTS];
static uint8_t g_l1_inw_vbo_dirty[MAX_L1_INWARD_SLOTS];

static int g_inward_tier[MAX_INWARD_SLOTS];
static int g_l1_inward_tier[MAX_L1_INWARD_SLOTS];
static int g_disable_lod = 0;
static int g_lod_dist_level = 4;
static int g_inward_dirty = 1;
static int g_shell_dirty = 1;

static int g_vp_w = 1280, g_vp_h = 720;
static int g_depth = 0, g_biome = 1;
static int g_flash_rgb = 0, g_flash_ms = 0;
static float g_cam_x = 8.0f, g_cam_y = 2.5f, g_cam_z = 2.5f;
static float g_yaw = 1.5708f, g_pitch = 0.0f, g_roll = 0.0f;
static int g_anim_ms = 0;

static FbwEnt g_ents[MAX_ENTS];
static int g_ent_cnt = 0;
static FbwPt g_shots[MAX_SHOTS];
static int g_shot_cnt = 0;
static FbwPt g_parts[MAX_PARTS];
static int g_part_cnt = 0;
static int g_beam_active = 0;
static float g_beam_x1, g_beam_y1, g_beam_z1, g_beam_x2, g_beam_y2, g_beam_z2;
static uint32_t g_beam_rgb = 0;

static FbwVert *g_band1_verts = NULL;
static int g_band1_cap = 0;
static int g_band1_cnt = 0;
static FbwVert *g_slot_verts = NULL;
static int g_slot_cap = 0;
static FbwVert g_band2_verts[MAX_BAND2_VERTS];
static int g_band2_cnt = 0;
static FbwVert g_band3_verts[MAX_BAND3_VERTS];
static int g_band3_cnt = 0;
static FbwVert g_dyn_verts[MAX_DYN_VERTS];
static int g_dyn_vert_cnt = 0;

static int g_gl_ready = 0;
static GLuint g_prog_sky = 0;
static GLuint g_prog_world = 0;
static GLuint g_vbo_sky = 0;
static GLuint g_vbo_band1 = 0;
static GLuint g_vbo_band2 = 0;
static GLuint g_vbo_band3 = 0;
static GLuint g_vbo_dyn = 0;

// Uniform locations
static GLint g_u_sky_top = -1, g_u_sky_bot = -1, g_u_sky_star = -1, g_u_sky_time = -1;
static GLint g_u_sky_fwd = -1, g_u_sky_right = -1, g_u_sky_up = -1, g_u_sky_aspect = -1;
static GLint g_u_mvp = -1, g_u_cam = -1, g_u_fog_col = -1, g_u_fog_params = -1;
static GLint g_u_time = -1, g_u_flash = -1, g_u_fog_max = -1;

// Strictly GLSL ES 1.00 compatible for rawdrawandroid's ES 2.0 EGL context
static const char *SKY_VS =
    "attribute vec2 a_pos;\n"
    "varying vec2 v_ndc;\n"
    "void main() {\n"
    "  v_ndc = a_pos;\n"
    "  gl_Position = vec4(a_pos, 0.999, 1.0);\n"
    "}\n";

static const char *SKY_FS =
    "#ifdef GL_FRAGMENT_PRECISION_HIGH\n"
    "precision highp float;\n"
    "#else\n"
    "precision mediump float;\n"
    "#endif\n"
    "varying vec2 v_ndc;\n"
    "uniform vec3 u_top;\n"
    "uniform vec3 u_bot;\n"
    "uniform float u_star;\n"
    "uniform float u_time;\n"
    "uniform vec3 u_fwd;\n"
    "uniform vec3 u_right;\n"
    "uniform vec3 u_up;\n"
    "uniform float u_aspect;\n"
    "float hash31(vec3 p) {\n"
    "  p = fract(p * vec3(123.34, 456.21, 789.18));\n"
    "  p += dot(p, p.yzx + 45.32);\n"
    "  return fract((p.x + p.y) * p.z);\n"
    "}\n"
    "void main() {\n"
    "  vec3 dir = normalize(u_fwd + v_ndc.x * u_aspect * 0.74 * u_right + v_ndc.y * 0.74 * u_up);\n"
    "  float h_band = clamp(dir.y * 0.78 + 0.36, 0.0, 1.0);\n"
    "  vec3 col = mix(u_bot, u_top, pow(h_band, 0.85));\n"
    "  float horizon_glow = exp(-abs(dir.y) * 5.5) * 0.16;\n"
    "  col += u_bot * horizon_glow;\n"
    "  if (u_star > 0.5) {\n"
    "    vec3 cell = floor(dir * 96.0);\n"
    "    float h = hash31(cell);\n"
    "    if (h > 0.992) {\n"
    "      float tw = 0.65 + 0.35 * sin(u_time * 3.0 + h * 90.0);\n"
    "      col += vec3(0.86, 0.94, 1.0) * tw * u_star;\n"
    "    }\n"
    "  } else if (dir.y > 0.04) {\n"
    "    vec2 c_uv = dir.xz / max(dir.y + 0.25, 0.25) * 1.4 + vec2(u_time * 0.015, 0.0);\n"
    "    float cn = hash31(vec3(floor(c_uv * 2.5), 1.0));\n"
    "    if (cn > 0.72) {\n"
    "      col = mix(col, vec3(0.96, 0.98, 1.0), 0.18 * smoothstep(0.04, 0.35, dir.y));\n"
    "    }\n"
    "  }\n"
    "  gl_FragColor = vec4(col, 1.0);\n"
    "}\n";

static const char *WORLD_VS =
    "attribute vec3 a_pos;\n"
    "attribute vec4 a_meta;\n"
    "attribute vec4 a_col;\n"
    "uniform mat4 u_mvp;\n"
    "varying vec3 v_pos;\n"
    "varying vec4 v_meta;\n"
    "varying vec4 v_col;\n"
    "void main() {\n"
    "  v_pos = a_pos;\n"
    "  v_meta = a_meta;\n"
    "  v_col = a_col;\n"
    "  gl_Position = u_mvp * vec4(a_pos, 1.0);\n"
    "}\n";

static const char *WORLD_FS =
    "#ifdef GL_FRAGMENT_PRECISION_HIGH\n"
    "precision highp float;\n"
    "#else\n"
    "precision mediump float;\n"
    "#endif\n"
    "varying vec3 v_pos;\n"
    "varying vec4 v_meta;\n"
    "varying vec4 v_col;\n"
    "uniform vec3 u_cam;\n"
    "uniform vec3 u_fog_col;\n"
    "uniform vec2 u_fog_params;\n"
    "uniform float u_fog_max;\n"
    "uniform float u_time;\n"
    "uniform vec4 u_flash;\n"
    "float h21(vec2 p) {\n"
    "  p = fract(p * vec2(234.34, 435.345));\n"
    "  p += dot(p, p + 34.23);\n"
    "  return fract(p.x * p.y);\n"
    "}\n"
    "void main() {\n"
    "  vec2 uv = v_meta.xy;\n"
    "  float light = v_meta.z;\n"
    "  float raw_style = v_meta.w;\n"
    "  float tier = floor(raw_style / 16.0);\n"
    "  float style = raw_style - tier * 16.0;\n"
    "  vec3 base = v_col.rgb;\n"
    "  vec2 puv = fract(uv * 16.0);\n"
    "  float cell_n = h21(floor(uv * 8.0));\n"
    "  float e = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));\n"
    "  float d_cen = max(abs(uv.x - 0.5), abs(uv.y - 0.5)) * 2.0;\n"
    "  float outline_w = (tier > 1.5) ? 0.025 : ((tier > 0.5) ? 0.036 : 0.048);\n"
    "  if (style < 0.5) {\n"
    "    // Stone / Tutorial / Sand / Dirt crisp Steam FBW voxel outline + subtle stone grain\n"
    "    float grain = 0.92 + 0.14 * h21(floor(uv * 12.0));\n"
    "    base *= grain;\n"
    "    if (e < outline_w) base *= 0.22;\n"
    "    else if (e < outline_w + 0.035) base *= 1.08;\n"
    "  } else if (style < 1.5) {\n"
    "    // Black Cube / Menger Sponge: crisp grey stone trusses + diagonal X-brace + hollow cavity\n"
    "    float diag = min(abs(uv.x - uv.y), abs(uv.x + uv.y - 1.0));\n"
    "    if (e < 0.055) {\n"
    "      base = vec3(0.08, 0.09, 0.12);\n"
    "    } else if (d_cen > 0.58 || diag < 0.065) {\n"
    "      base *= (0.94 + 0.12 * cell_n);\n"
    "    } else {\n"
    "      base = mix(base * 0.24, vec3(0.18, 0.72, 0.92), step(0.84, fract(d_cen * 3.0 - u_time * 0.25)) * 0.45);\n"
    "    }\n"
    "    light = max(light, 0.92);\n"
    "  } else if (style < 2.5) {\n"
    "    // Stations / Upgrades / Tome / Spawner: crisp frame + glowing animated center emblem\n"
    "    float pulse = 0.88 + 0.16 * sin(u_time * 4.0);\n"
    "    float icon = step(0.18, d_cen) * (1.0 - step(0.46, d_cen));\n"
    "    if (e < 0.065) base = vec3(0.08, 0.10, 0.14);\n"
    "    else if (e < 0.105) base = mix(base, vec3(1.0), 0.45);\n"
    "    else if (icon > 0.5) base = mix(base, vec3(1.0, 0.96, 0.72), 0.55);\n"
    "    else base *= 0.85;\n"
    "    base *= pulse;\n"
    "    light = max(light, 0.98);\n"
    "  } else if (style < 3.5) {\n"
    "    // Ice & Glass crystal prism\n"
    "    float sheen = smoothstep(0.62, 0.98, fract(uv.x * 0.75 + uv.y * 0.85));\n"
    "    base = mix(base, vec3(0.92, 0.99, 1.0), sheen * 0.45);\n"
    "    if (e < outline_w) base *= 0.45;\n"
    "  } else if (style < 4.5) {\n"
    "    // Grass & Leaves: vibrant foliage speckles + crisp voxel edge\n"
    "    float dapple = 0.82 + 0.32 * h21(floor(uv * 10.0));\n"
    "    base *= dapple;\n"
    "    if (e < outline_w) base *= 0.32;\n"
    "  } else if (style < 5.5) {\n"
    "    // Wood bark grain\n"
    "    float bark = 0.84 + 0.24 * sin(uv.x * 28.0 + cell_n * 3.1);\n"
    "    base *= bark;\n"
    "    if (e < outline_w) base *= 0.28;\n"
    "  } else if (style < 6.5) {\n"
    "    // Alpha Cube / White Flower / Mylantis circuit lattice\n"
    "    float trace = step(0.84, max(puv.x, puv.y));\n"
    "    if (e < 0.055) base *= 0.24;\n"
    "    else if (trace > 0.5) base *= 1.24;\n"
    "    else base *= (0.88 + 0.14 * cell_n);\n"
    "  } else if (style < 7.5) {\n"
    "    // Yellow Flower / Pollen / Desert World: striated radiant bands\n"
    "    float strata = 0.88 + 0.20 * sin(uv.y * 18.0 + sin(uv.x * 6.0));\n"
    "    base *= strata;\n"
    "    if (e < outline_w) base *= 0.28;\n"
    "  } else if (style < 8.5) {\n"
    "    // Gold Ore / Crate / Vault Door: metallic rivet & ore flecks\n"
    "    float fleck = step(0.78, cell_n);\n"
    "    if (e < 0.065) base *= 0.25;\n"
    "    else if (fleck > 0.5) base = mix(base, vec3(1.0, 0.94, 0.55), 0.55);\n"
    "  } else if (style < 9.5) {\n"
    "    // Dynamic entities / rings / shots: luminous smooth shading\n"
    "    float rim = smoothstep(0.55, 0.98, d_cen);\n"
    "    base = mix(base, vec3(1.0), rim * 0.22);\n"
    "  } else if (style < 10.5) {\n"
    "    // BLK_MYSTERY_Q: Vibrant electric blue tile with glowing white '?' glyph\n"
    "    base = vec3(0.10, 0.34, 0.92);\n"
    "    vec2 q = floor(uv * 8.0);\n"
    "    float qm = 0.0;\n"
    "    if (q.y == 6.0 && q.x >= 2.0 && q.x <= 5.0) qm = 1.0;\n"
    "    if (q.y == 5.0 && (q.x == 2.0 || q.x == 5.0)) qm = 1.0;\n"
    "    if (q.y == 4.0 && q.x == 5.0) qm = 1.0;\n"
    "    if (q.y == 3.0 && (q.x == 3.0 || q.x == 4.0)) qm = 1.0;\n"
    "    if (q.y == 2.0 && q.x == 3.0) qm = 1.0;\n"
    "    if (q.y == 0.0 && q.x == 3.0) qm = 1.0;\n"
    "    if (e < 0.06) base = vec3(0.04, 0.10, 0.28);\n"
    "    else if (qm > 0.5) base = vec3(1.0, 0.98, 0.85);\n"
    "    light = max(light, 0.96);\n"
    "  } else if (style < 11.5) {\n"
    "    // BLK_HAZARD_NUKE: Diagonal yellow & black industrial stripes\n"
    "    float stripe = step(0.5, fract((uv.x + uv.y) * 3.0));\n"
    "    base = mix(vec3(0.08, 0.09, 0.11), vec3(0.98, 0.82, 0.12), stripe);\n"
    "    if (e < 0.06) base = vec3(0.04, 0.04, 0.05);\n"
    "    light = max(light, 0.92);\n"
    "  } else if (style < 12.5) {\n"
    "    // BLK_INFINITY_RED: Red fractal cube with crisp white infinity loop\n"
    "    base = vec3(0.84, 0.12, 0.18);\n"
    "    float dL = length(uv - vec2(0.32, 0.5));\n"
    "    float dR = length(uv - vec2(0.68, 0.5));\n"
    "    float inf = step(abs(dL - 0.16), 0.05) + step(abs(dR - 0.16), 0.05);\n"
    "    if (e < 0.06) base = vec3(0.14, 0.03, 0.05);\n"
    "    else if (inf > 0.5) base = vec3(1.0);\n"
    "    light = max(light, 0.95);\n"
    "  } else if (style < 13.5) {\n"
    "    // BLK_TOPAZ_CHECK: Crisp cyan/teal mineral checkerboard\n"
    "    vec2 chk = floor(uv * 4.0);\n"
    "    float parity = mod(chk.x + chk.y, 2.0);\n"
    "    base = mix(vec3(0.08, 0.52, 0.58), vec3(0.34, 0.95, 0.90), parity);\n"
    "    if (e < 0.055) base *= 0.25;\n"
    "    light = max(light, 0.92);\n"
    "  } else {\n"
    "    // BLK_TEXT_BLOCK: Glowing cyan holographic log lines\n"
    "    base = vec3(0.08, 0.24, 0.34);\n"
    "    float row_bar = step(0.55, fract(uv.y * 5.0)) * step(0.14, uv.x) * step(uv.x, 0.86);\n"
    "    if (e < 0.06) base = vec3(0.03, 0.08, 0.12);\n"
    "    else if (row_bar > 0.5) base = vec3(0.32, 0.96, 1.0);\n"
    "    light = max(light, 0.98);\n"
    "  }\n"
    "  vec3 lit = clamp(base * light, 0.0, 1.0);\n"
    "  float dist = length(v_pos - u_cam);\n"
    "  float fog_t = clamp((dist - u_fog_params.x) / max(u_fog_params.y, 1.0), 0.0, u_fog_max);\n"
    "  vec3 out_col = mix(lit, u_fog_col, fog_t);\n"
    "  out_col = mix(out_col, u_flash.rgb, u_flash.a);\n"
    "  gl_FragColor = vec4(out_col, v_col.a);\n"
    "}\n";

static GLuint compile_shader(GLenum type, const char *src) {
    GLuint s = glCreateShader(type);
    if (!s) return 0;
    glShaderSource(s, 1, &src, NULL);
    glCompileShader(s);
    GLint ok = 0;
    glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        glDeleteShader(s);
        return 0;
    }
    return s;
}

static GLuint link_program(const char *vs_src, const char *fs_src, int bind_world_attribs) {
    GLuint vs = compile_shader(GL_VERTEX_SHADER, vs_src);
    GLuint fs = compile_shader(GL_FRAGMENT_SHADER, fs_src);
    if (!vs || !fs) {
        if (vs) glDeleteShader(vs);
        if (fs) glDeleteShader(fs);
        return 0;
    }
    GLuint p = glCreateProgram();
    glAttachShader(p, vs);
    glAttachShader(p, fs);
    glBindAttribLocation(p, 0, "a_pos");
    if (bind_world_attribs) {
        glBindAttribLocation(p, 1, "a_meta");
        glBindAttribLocation(p, 2, "a_col");
    }
    glLinkProgram(p);
    glDeleteShader(vs);
    glDeleteShader(fs);
    GLint ok = 0;
    glGetProgramiv(p, GL_LINK_STATUS, &ok);
    if (!ok) {
        glDeleteProgram(p);
        return 0;
    }
    return p;
}

static void init_gl_resources(void) {
    if (g_gl_ready) return;
    g_prog_sky = link_program(SKY_VS, SKY_FS, 0);
    g_prog_world = link_program(WORLD_VS, WORLD_FS, 1);
    if (!g_prog_sky || !g_prog_world) return;

    g_u_sky_top = glGetUniformLocation(g_prog_sky, "u_top");
    g_u_sky_bot = glGetUniformLocation(g_prog_sky, "u_bot");
    g_u_sky_star = glGetUniformLocation(g_prog_sky, "u_star");
    g_u_sky_time = glGetUniformLocation(g_prog_sky, "u_time");
    g_u_sky_fwd = glGetUniformLocation(g_prog_sky, "u_fwd");
    g_u_sky_right = glGetUniformLocation(g_prog_sky, "u_right");
    g_u_sky_up = glGetUniformLocation(g_prog_sky, "u_up");
    g_u_sky_aspect = glGetUniformLocation(g_prog_sky, "u_aspect");

    g_u_mvp = glGetUniformLocation(g_prog_world, "u_mvp");
    g_u_cam = glGetUniformLocation(g_prog_world, "u_cam");
    g_u_fog_col = glGetUniformLocation(g_prog_world, "u_fog_col");
    g_u_fog_params = glGetUniformLocation(g_prog_world, "u_fog_params");
    g_u_fog_max = glGetUniformLocation(g_prog_world, "u_fog_max");
    g_u_time = glGetUniformLocation(g_prog_world, "u_time");
    g_u_flash = glGetUniformLocation(g_prog_world, "u_flash");

    static const float sky_quad[12] = {
        -1.f, -1.f,  1.f, -1.f,  1.f,  1.f,
        -1.f, -1.f,  1.f,  1.f, -1.f,  1.f
    };
    glGenBuffers(1, &g_vbo_sky);
    glBindBuffer(GL_ARRAY_BUFFER, g_vbo_sky);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sky_quad), sky_quad, GL_STATIC_DRAW);

    glGenBuffers(1, &g_vbo_band1);
    glGenBuffers(1, &g_vbo_band2);
    glGenBuffers(1, &g_vbo_band3);
    glGenBuffers(1, &g_vbo_dyn);
    glGenBuffers(MAX_INWARD_SLOTS, g_inw_vbos);
    glGenBuffers(MAX_L1_INWARD_SLOTS, g_l1_inw_vbos);
    for (int i = 0; i < MAX_INWARD_SLOTS; i++) {
        g_inw_vcnt[i] = 0;
        g_inw_vbo_dirty[i] = 1;
    }
    for (int i = 0; i < MAX_L1_INWARD_SLOTS; i++) {
        g_l1_inw_vcnt[i] = 0;
        g_l1_inw_vbo_dirty[i] = 1;
    }
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    g_gl_ready = 1;
}

static void block_color(uint8_t blk, uint8_t *r, uint8_t *g, uint8_t *b, float *style) {
    *style = 0.0f;
    switch (blk) {
        case BLK_WALL_TUT:      *r = 166; *g = 176; *b = 198; *style = 0.0f; break;
        case BLK_GRASS:         *r = 46;  *g = 176; *b = 82;  *style = 4.0f; break;
        case BLK_DIRT:          *r = 120; *g = 82;  *b = 52;  *style = 0.0f; break;
        case BLK_WOOD:          *r = 128; *g = 78;  *b = 44;  *style = 5.0f; break;
        case BLK_LEAVES:        *r = 34;  *g = 148; *b = 76;  *style = 4.0f; break;
        case BLK_PETAL_Y:       *r = 248; *g = 204; *b = 38;  *style = 7.0f; break;
        case BLK_POLLEN:        *r = 255; *g = 164; *b = 36;  *style = 7.0f; break;
        case BLK_PETAL_W:       *r = 236; *g = 242; *b = 252; *style = 6.0f; break;
        case BLK_MYLANTIS:      *r = 38;  *g = 178; *b = 172; *style = 6.0f; break;
        case BLK_ICE:           *r = 112; *g = 218; *b = 250; *style = 3.0f; break;
        case BLK_SAND:          *r = 226; *g = 192; *b = 116; *style = 7.0f; break;
        case BLK_GLASS:         *r = 148; *g = 230; *b = 248; *style = 3.0f; break;
        case BLK_STONE:         *r = 104; *g = 112; *b = 128; *style = 0.0f; break;
        case BLK_GOLD_ORE:      *r = 248; *g = 204; *b = 46;  *style = 8.0f; break;
        case BLK_CRATE:         *r = 196; *g = 134; *b = 52;  *style = 8.0f; break;
        case BLK_SPAWNER:       *r = 196; *g = 38;  *b = 76;  *style = 2.0f; break;
        case BLK_LOCKED_DOOR:   *r = 218; *g = 158; *b = 44;  *style = 8.0f; break;
        case BLK_MYSTERY_Q:     *r = 46;  *g = 118; *b = 244; *style = 10.0f; break;
        case BLK_HAZARD_NUKE:   *r = 248; *g = 208; *b = 32;  *style = 11.0f; break;

        case BLK_BLACK_CUBE:    *r = 116; *g = 122; *b = 134; *style = 1.0f; break;
        case BLK_WHITE_FLOWER:  *r = 242; *g = 246; *b = 255; *style = 6.0f; break;
        case BLK_ALPHA_CUBE:    *r = 236; *g = 76;  *b = 166; *style = 6.0f; break;
        case BLK_FLOWER_Y_CORE: *r = 255; *g = 218; *b = 48;  *style = 1.0f; break;
        case BLK_MYLANTIS_M:    *r = 248; *g = 116; *b = 32;  *style = 6.0f; break;
        case BLK_YING_PLANET:   *r = 52;  *g = 212; *b = 122; *style = 4.0f; break;
        case BLK_ICE_WORLD:     *r = 100; *g = 222; *b = 255; *style = 3.0f; break;
        case BLK_DESERT_WORLD:  *r = 238; *g = 186; *b = 88;  *style = 7.0f; break;
        case BLK_CORE_GATE:     *r = 248; *g = 64;  *b = 188; *style = 1.0f; break;
        case BLK_TOPAZ_CHECK:   *r = 38;  *g = 208; *b = 202; *style = 13.0f; break;
        case BLK_INFINITY_RED:  *r = 218; *g = 38;  *b = 48;  *style = 12.0f; break;
        case BLK_TEXT_BLOCK:    *r = 56;  *g = 224; *b = 255; *style = 14.0f; break;

        case BLK_BUY_STATION:   *r = 46;  *g = 218; *b = 122; *style = 2.0f; break;
        case BLK_SELL_STATION:  *r = 56;  *g = 192; *b = 248; *style = 2.0f; break;
        case BLK_BLACK_MARKET:  *r = 182; *g = 64;  *b = 236; *style = 2.0f; break;
        case BLK_TOME:          *r = 250; *g = 204; *b = 36;  *style = 2.0f; break;
        case BLK_UPG_HP:        *r = 244; *g = 68;  *b = 92;  *style = 2.0f; break;
        case BLK_UPG_REGEN:     *r = 248; *g = 114; *b = 148; *style = 2.0f; break;
        case BLK_UPG_ARMOR:     *r = 68;  *g = 178; *b = 250; *style = 2.0f; break;
        case BLK_UPG_DMG:       *r = 252; *g = 116; *b = 42;  *style = 2.0f; break;
        case BLK_UPG_ROF:       *r = 252; *g = 178; *b = 42;  *style = 2.0f; break;
        case BLK_UPG_AMMO:      *r = 176; *g = 92;  *b = 248; *style = 2.0f; break;
        case BLK_UPG_SPEED:     *r = 56;  *g = 236; *b = 216; *style = 2.0f; break;
        case BLK_KEY_BLOCK:     *r = 255; *g = 228; *b = 72;  *style = 2.0f; break;
        case BLK_UPG_WEP:       *r = 48;  *g = 236; *b = 152; *style = 2.0f; break;
        default:                *r = 128; *g = 128; *b = 140; *style = 0.0f; break;
    }
}

static int ensure_vert_cap(FbwVert **pbuf, int *cap, int need, int allow_grow) {
    if (need <= *cap && *pbuf != NULL) return 1;
    if (!allow_grow) return 0;
    int new_cap = (*cap > 0) ? *cap : MAX_BAND1_INIT;
    while (new_cap < need) {
        if (new_cap >= MAX_BAND1_HARD_CAP) return 0;
        new_cap *= 2;
    }
    if (new_cap > MAX_BAND1_HARD_CAP) new_cap = MAX_BAND1_HARD_CAP;
    if (need > new_cap) return 0;
    FbwVert *nb = (FbwVert *)realloc(*pbuf, (size_t)new_cap * sizeof(FbwVert));
    if (!nb) return 0;
    *pbuf = nb;
    *cap = new_cap;
    return 1;
}

static void push_quad_ao_dyn(FbwVert **pbuf, int *cnt, int *max_v, int allow_grow,
                             float x0, float y0, float z0,
                             float x1, float y1, float z1,
                             float x2, float y2, float z2,
                             float x3, float y3, float z3,
                             float l0, float l1, float l2, float l3,
                             float style, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    if (!ensure_vert_cap(pbuf, max_v, *cnt + 6, allow_grow)) return;
    FbwVert *buf = *pbuf;
    FbwVert v0 = { x0, y0, z0, 0.f, 0.f, l0, style, r, g, b, a };
    FbwVert v1 = { x1, y1, z1, 1.f, 0.f, l1, style, r, g, b, a };
    FbwVert v2 = { x2, y2, z2, 1.f, 1.f, l2, style, r, g, b, a };
    FbwVert v3 = { x3, y3, z3, 0.f, 1.f, l3, style, r, g, b, a };
    if (l0 + l2 >= l1 + l3) {
        buf[(*cnt)++] = v0;
        buf[(*cnt)++] = v1;
        buf[(*cnt)++] = v2;
        buf[(*cnt)++] = v0;
        buf[(*cnt)++] = v2;
        buf[(*cnt)++] = v3;
    } else {
        buf[(*cnt)++] = v1;
        buf[(*cnt)++] = v2;
        buf[(*cnt)++] = v3;
        buf[(*cnt)++] = v1;
        buf[(*cnt)++] = v3;
        buf[(*cnt)++] = v0;
    }
}

static void push_quad_ao(FbwVert *buf, int *cnt, int max_v,
                         float x0, float y0, float z0,
                         float x1, float y1, float z1,
                         float x2, float y2, float z2,
                         float x3, float y3, float z3,
                         float l0, float l1, float l2, float l3,
                         float style, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    push_quad_ao_dyn(&buf, cnt, &max_v, 0,
                     x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3,
                     l0, l1, l2, l3, style, r, g, b, a);
}

static void push_quad_dyn(FbwVert **pbuf, int *cnt, int *max_v, int allow_grow,
                          float x0, float y0, float z0,
                          float x1, float y1, float z1,
                          float x2, float y2, float z2,
                          float x3, float y3, float z3,
                          float light, float style, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow,
                     x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3,
                     light, light, light, light, style, r, g, b, a);
}

static void push_quad(FbwVert *buf, int *cnt, int max_v,
                      float x0, float y0, float z0,
                      float x1, float y1, float z1,
                      float x2, float y2, float z2,
                      float x3, float y3, float z3,
                      float light, float style, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    push_quad_ao(buf, cnt, max_v, x0,y0,z0, x1,y1,z1, x2,y2,z2, x3,y3,z3,
                 light, light, light, light, style, r, g, b, a);
}

static void emit_cube(FbwVert *buf, int *cnt, int max_v,
                      float cx, float cy, float cz, float hs,
                      uint8_t r, uint8_t g, uint8_t b, uint8_t a, float style) {
    float x0 = cx - hs, x1 = cx + hs;
    float y0 = cy - hs, y1 = cy + hs;
    float z0 = cz - hs, z1 = cz + hs;
    push_quad(buf, cnt, max_v, x0,y1,z1, x1,y1,z1, x1,y1,z0, x0,y1,z0, 1.05f, style, r, g, b, a);
    push_quad(buf, cnt, max_v, x0,y0,z0, x1,y0,z0, x1,y0,z1, x0,y0,z1, 0.62f, style, r, g, b, a);
    push_quad(buf, cnt, max_v, x1,y0,z1, x1,y0,z0, x1,y1,z0, x1,y1,z1, 0.90f, style, r, g, b, a);
    push_quad(buf, cnt, max_v, x0,y0,z0, x0,y0,z1, x0,y1,z1, x0,y1,z0, 0.78f, style, r, g, b, a);
    push_quad(buf, cnt, max_v, x0,y0,z1, x1,y0,z1, x1,y1,z1, x0,y1,z1, 0.96f, style, r, g, b, a);
    push_quad(buf, cnt, max_v, x1,y0,z0, x0,y0,z0, x0,y1,z0, x1,y1,z0, 0.72f, style, r, g, b, a);
}

static inline uint8_t chunk_at(int layer, int x, int y, int z);
/* Any non-air block in a stride-sized cell anchored at world (wx,wy,wz)? */
static inline int cell_occ_world(int stride, int wx, int wy, int wz) {
    int dx, dy, dz;
    for (dy = 0; dy < stride; dy++)
        for (dz = 0; dz < stride; dz++)
            for (dx = 0; dx < stride; dx++)
                if (chunk_at(0, wx + dx, wy + dy, wz + dz) != BLK_AIR) return 1;
    return 0;
}

/* offset (dx,dy,dz) in -3..3 -> neighbor slot + 1 (0 = none); O(1) for kilochunk meshing */
static int g_neighbor_map[NEIGH_MAP_SIZE];

static void neighbor_map_rebuild(void) {
    memset(g_neighbor_map, 0, sizeof(g_neighbor_map));
    for (int s = 0; s < MAX_NEIGHBORS; s++) {
        if (!g_neighbor_valid[s]) continue;
        int dx = g_neighbor_dx[s], dy = g_neighbor_dy[s], dz = g_neighbor_dz[s];
        if (dx < -3 || dx > 3 || dy < -3 || dy > 3 || dz < -3 || dz > 3) continue;
        g_neighbor_map[((dx + 3) * NEIGH_MAP_DIM + (dy + 3)) * NEIGH_MAP_DIM + (dz + 3)] = s + 1;
    }
}

static inline int neighbor_slot_at_offset(int ox, int oy, int oz) {
    if (ox < -3 || ox > 3 || oy < -3 || oy > 3 || oz < -3 || oz > 3) return -1;
    int s = g_neighbor_map[((ox + 3) * NEIGH_MAP_DIM + (oy + 3)) * NEIGH_MAP_DIM + (oz + 3)] - 1;
    if (s < 0 || s >= MAX_NEIGHBORS || !g_neighbor_valid[s]) return -1;
    return s;
}

static inline uint8_t neighbor_at_offset(int ox, int oy, int oz, int lx, int ly, int lz) {
    if (lx < 0 || lx >= 16 || ly < 0 || ly >= 16 || lz < 0 || lz >= 16) return BLK_AIR;
    int s = neighbor_slot_at_offset(ox, oy, oz);
    if (s < 0) return BLK_AIR;
    return g_neighbors[s][(ly << 8) | (lz << 4) | lx];
}

static inline int is_l1_covered_by_neighbor(int x, int y, int z) {
    if (!g_parent_valid[0]) return 0;
    int dx = x - g_parent_bx[0];
    int dy = y - g_parent_by[0];
    int dz = z - g_parent_bz[0];
    return neighbor_slot_at_offset(dx, dy, dz) >= 0 ? 1 : 0;
}

static inline uint8_t chunk_at(int layer, int x, int y, int z) {
    if (x >= 0 && x < 16 && y >= 0 && y < 16 && z >= 0 && z < 16) {
        return g_chunks[layer][(y << 8) | (z << 4) | x];
    }
    if (layer == 0 && x >= -48 && x < 64 && y >= -48 && y < 64 && z >= -48 && z < 64) {
        int ox = (x < 0) ? -1 : ((x >= 16) ? 1 : 0);
        int oy = (y < 0) ? -1 : ((y >= 16) ? 1 : 0);
        int oz = (z < 0) ? -1 : ((z >= 16) ? 1 : 0);
        return neighbor_at_offset(ox, oy, oz, x - ox * 16, y - oy * 16, z - oz * 16);
    }
    return BLK_AIR;
}

static inline int chunk_occ(int layer, int x, int y, int z) {
    return chunk_at(layer, x, y, z) != BLK_AIR ? 1 : 0;
}

static inline int nb_chunk_occ(int nb_slot, int x, int y, int z) {
    if (x >= 0 && x < 16 && y >= 0 && y < 16 && z >= 0 && z < 16) {
        return g_neighbors[nb_slot][(y << 8) | (z << 4) | x] != BLK_AIR ? 1 : 0;
    }
    int wx = g_neighbor_dx[nb_slot] * 16 + x;
    int wy = g_neighbor_dy[nb_slot] * 16 + y;
    int wz = g_neighbor_dz[nb_slot] * 16 + z;
    if (wx >= 0 && wx < 16 && wy >= 0 && wy < 16 && wz >= 0 && wz < 16) {
        if (g_inward_grid[(wy << 8) | (wz << 4) | wx] >= 0) return 0;
    }
    return chunk_at(0, wx, wy, wz) != BLK_AIR ? 1 : 0;
}

static inline float corner_ao(int s1, int s2, int c) {
    int lv = (s1 && s2) ? 0 : (3 - (s1 + s2 + c));
    return 0.64f + 0.12f * (float)lv;
}

static inline int inward_occ(int layer, int slot, int lx, int ly, int lz,
                             int ix, int iy, int iz,
                             int hole_x, int hole_y, int hole_z, int skip_hole) {
    if (ix >= 0 && ix < 16 && iy >= 0 && iy < 16 && iz >= 0 && iz < 16) {
        const uint8_t *arr = (layer == 0) ? g_inward[slot] : g_l1_inward[slot];
        return arr[(iy << 8) | (iz << 4) | ix] != BLK_AIR ? 1 : 0;
    }
    int nx = lx + (ix < 0 ? -1 : (ix >= 16 ? 1 : 0));
    int ny = ly + (iy < 0 ? -1 : (iy >= 16 ? 1 : 0));
    int nz = lz + (iz < 0 ? -1 : (iz >= 16 ? 1 : 0));
    if (skip_hole && nx == hole_x && ny == hole_y && nz == hole_z) {
        return 0;
    }
    if (layer == 1 && skip_hole && nx >= 0 && nx < 16 && ny >= 0 && ny < 16 && nz >= 0 && nz < 16) {
        if (is_l1_covered_by_neighbor(nx, ny, nz)) return 0;
    }
    uint8_t nb = chunk_at(layer, nx, ny, nz);
    if (nb == BLK_AIR) return 0;
    if (nx >= 0 && nx < 16 && ny >= 0 && ny < 16 && nz >= 0 && nz < 16) {
        const int *grid = (layer == 0) ? g_inward_grid : g_l1_inward_grid;
        if (grid[(ny << 8) | (nz << 4) | nx] >= 0) return 0;
    }
    return 1;
}

static void apply_depth_tint(uint8_t *r, uint8_t *g, uint8_t *b) {
    if (g_depth >= 500) {
        int d256 = 256 - ((g_depth - 500) * 144) / 1500;
        if (d256 < 104) d256 = 104;
        *r = (uint8_t)((*r * d256) >> 8);
        *g = (uint8_t)((*g * d256) >> 8);
        *b = (uint8_t)((*b * d256) >> 8);
    }
}

static int is_accent_or_portal_blk(uint8_t b) {
    if (b >= BLK_BLACK_CUBE && b <= BLK_TEXT_BLOCK) return 1;
    if (b >= BLK_BUY_STATION && b <= BLK_UPG_WEP) return 1;
    if (b == BLK_GOLD_ORE || b == BLK_CRATE || b == BLK_MYSTERY_Q || b == BLK_HAZARD_NUKE ||
        b == BLK_PETAL_Y || b == BLK_PETAL_W || b == BLK_WOOD) return 1;
    return 0;
}

static int compute_slot_tier(int layer, int lx, int ly, int lz,
                             float scale, float px_off, float py_off, float pz_off,
                             int prev_tier) {
    if (g_disable_lod) return 1;
    float cx = px_off + ((float)lx + 0.5f) * scale;
    float cy = py_off + ((float)ly + 0.5f) * scale;
    float cz = pz_off + ((float)lz + 0.5f) * scale;
    float dx = cx - g_cam_x;
    float dy = cy - g_cam_y;
    float dz = cz - g_cam_z;
    float d = sqrtf(dx * dx + dy * dy + dz * dz);
    float L = (float)g_lod_dist_level;
    float r16 = (layer == 0) ? (1.6f + 0.90f * L) : (18.0f + 9.5f * L);
    float r8  = (layer == 0) ? (3.8f + 1.95f * L) : (38.0f + 19.0f * L);
    float h16 = (layer == 0) ? 0.55f : 4.0f;
    float h8  = (layer == 0) ? 0.95f : 8.0f;

    if (prev_tier == 1) {
        if (d <= r16 + h16) return 1;
        return (d <= r8 + h8) ? 2 : 4;
    } else if (prev_tier == 2) {
        if (d <= r16 - h16) return 1;
        return (d <= r8 + h8) ? 2 : 4;
    } else if (prev_tier == 4) {
        if (d <= r16 - h16) return 1;
        return (d <= r8 - h8) ? 2 : 4;
    }
    if (d <= r16) return 1;
    return (d <= r8) ? 2 : 4;
}

static inline int pooled_occ(const uint8_t *pooled, int dim,
                             int layer, int lx, int ly, int lz,
                             int px, int py, int pz,
                             int hole_x, int hole_y, int hole_z, int skip_hole) {
    if (px >= 0 && px < dim && py >= 0 && py < dim && pz >= 0 && pz < dim) {
        return pooled[(py * dim + pz) * dim + px] != BLK_AIR ? 1 : 0;
    }
    int nx = lx + (px < 0 ? -1 : (px >= dim ? 1 : 0));
    int ny = ly + (py < 0 ? -1 : (py >= dim ? 1 : 0));
    int nz = lz + (pz < 0 ? -1 : (pz >= dim ? 1 : 0));
    if (skip_hole && nx == hole_x && ny == hole_y && nz == hole_z) return 0;
    if (layer == 1 && skip_hole && nx >= 0 && nx < 16 && ny >= 0 && ny < 16 && nz >= 0 && nz < 16) {
        if (is_l1_covered_by_neighbor(nx, ny, nz)) return 0;
    }
    uint8_t nb = chunk_at(layer, nx, ny, nz);
    if (nb == BLK_AIR) return 0;
    if (nx >= 0 && nx < 16 && ny >= 0 && ny < 16 && nz >= 0 && nz < 16) {
        const int *grid = (layer == 0) ? g_inward_grid : g_l1_inward_grid;
        if (grid[(ny << 8) | (nz << 4) | nx] >= 0) return 0;
    }
    return 1;
}

static void mesh_inward_slot_pooled(int layer, int slot, int lx, int ly, int lz,
                                    float parent_scale, float px_off, float py_off, float pz_off,
                                    int hole_x, int hole_y, int hole_z, int skip_hole,
                                    float sub_tier_offset, int step,
                                    FbwVert **pbuf, int *cnt, int *max_v, int allow_grow) {
    const int dim = (step == 2) ? 8 : 4;
    const float sc = parent_scale / (float)dim;
    const float ox = px_off + (float)lx * parent_scale;
    const float oy = py_off + (float)ly * parent_scale;
    const float oz = pz_off + (float)lz * parent_scale;
    const uint8_t *arr = (layer == 0) ? g_inward[slot] : g_l1_inward[slot];
    const int thresh = (step == 2) ? 2 : 12;

    uint8_t pooled[512];
    int py, pz, px;
    for (py = 0; py < dim; py++) {
        for (pz = 0; pz < dim; pz++) {
            for (px = 0; px < dim; px++) {
                int solid_cnt = 0;
                uint8_t best_blk = BLK_AIR;
                int best_accent = 0;
                int dy, dz, dx;
                for (dy = 0; dy < step; dy++) {
                    int sy = py * step + dy;
                    for (dz = 0; dz < step; dz++) {
                        int sz = pz * step + dz;
                        for (dx = 0; dx < step; dx++) {
                            int sx = px * step + dx;
                            uint8_t b = arr[(sy << 8) | (sz << 4) | sx];
                            if (b != BLK_AIR) {
                                solid_cnt++;
                                int acc = is_accent_or_portal_blk(b);
                                if (best_blk == BLK_AIR || (acc && !best_accent)) {
                                    best_blk = b;
                                    best_accent = acc;
                                }
                            }
                        }
                    }
                }
                pooled[(py * dim + pz) * dim + px] =
                    (solid_cnt >= thresh || (solid_cnt >= 1 && best_accent)) ? best_blk : BLK_AIR;
            }
        }
    }

    for (py = 0; py < dim; py++) {
        for (pz = 0; pz < dim; pz++) {
            for (px = 0; px < dim; px++) {
                uint8_t blk = pooled[(py * dim + pz) * dim + px];
                if (blk == BLK_AIR) continue;

                uint8_t r, g, b;
                float style;
                block_color(blk, &r, &g, &b, &style);
                apply_depth_tint(&r, &g, &b);
                style += sub_tier_offset;

                float wx0 = ox + (float)px * sc, wx1 = wx0 + sc;
                float wy0 = oy + (float)py * sc, wy1 = wy0 + sc;
                float wz0 = oz + (float)pz * sc, wz1 = wz0 + sc;

                if (!pooled_occ(pooled, dim, layer, lx, ly, lz, px, py + 1, pz, hole_x, hole_y, hole_z, skip_hole)) {
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy1,wz1, wx1,wy1,wz1, wx1,wy1,wz0, wx0,wy1,wz0,
                                  1.00f, style, r, g, b, 255);
                }
                if (!pooled_occ(pooled, dim, layer, lx, ly, lz, px, py - 1, pz, hole_x, hole_y, hole_z, skip_hole)) {
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz0, wx1,wy0,wz0, wx1,wy0,wz1, wx0,wy0,wz1,
                                  0.60f, style, r, g, b, 255);
                }
                if (!pooled_occ(pooled, dim, layer, lx, ly, lz, px + 1, py, pz, hole_x, hole_y, hole_z, skip_hole)) {
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx1,wy0,wz1, wx1,wy0,wz0, wx1,wy1,wz0, wx1,wy1,wz1,
                                  0.88f, style, r, g, b, 255);
                }
                if (!pooled_occ(pooled, dim, layer, lx, ly, lz, px - 1, py, pz, hole_x, hole_y, hole_z, skip_hole)) {
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz0, wx0,wy0,wz1, wx0,wy1,wz1, wx0,wy1,wz0,
                                  0.76f, style, r, g, b, 255);
                }
                if (!pooled_occ(pooled, dim, layer, lx, ly, lz, px, py, pz + 1, hole_x, hole_y, hole_z, skip_hole)) {
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz1, wx1,wy0,wz1, wx1,wy1,wz1, wx0,wy1,wz1,
                                  0.95f, style, r, g, b, 255);
                }
                if (!pooled_occ(pooled, dim, layer, lx, ly, lz, px, py, pz - 1, hole_x, hole_y, hole_z, skip_hole)) {
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx1,wy0,wz0, wx0,wy0,wz0, wx0,wy1,wz0, wx1,wy1,wz0,
                                  0.70f, style, r, g, b, 255);
                }
            }
        }
    }
}

static void mesh_inward_slot(int layer, int slot, int lx, int ly, int lz,
                             float parent_scale, float px_off, float py_off, float pz_off,
                             int hole_x, int hole_y, int hole_z, int skip_hole,
                             float sub_tier_offset,
                             FbwVert **pbuf, int *cnt, int *max_v, int allow_grow) {
    const float sc = parent_scale * 0.0625f;
    const float ox = px_off + (float)lx * parent_scale;
    const float oy = py_off + (float)ly * parent_scale;
    const float oz = pz_off + (float)lz * parent_scale;
    const uint8_t *arr = (layer == 0) ? g_inward[slot] : g_l1_inward[slot];
    int y, z, x;
    for (y = 0; y < CHUNK_DIM; y++) {
        for (z = 0; z < CHUNK_DIM; z++) {
            for (x = 0; x < CHUNK_DIM; x++) {
                uint8_t blk = arr[(y << 8) | (z << 4) | x];
                if (blk == BLK_AIR) continue;

                uint8_t r, g, b;
                float style;
                block_color(blk, &r, &g, &b, &style);
                apply_depth_tint(&r, &g, &b);
                style += sub_tier_offset;

                float wx0 = ox + (float)x * sc, wx1 = wx0 + sc;
                float wy0 = oy + (float)y * sc, wy1 = wy0 + sc;
                float wz0 = oz + (float)z * sc, wz1 = wz0 + sc;

                // +Y
                if (!inward_occ(layer, slot, lx, ly, lz, x, y + 1, z, hole_x, hole_y, hole_z, skip_hole)) {
                    float a0 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y + 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y + 1, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y + 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    float a1 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y + 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y + 1, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y + 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    float a2 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y + 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y + 1, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y + 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    float a3 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y + 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y + 1, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y + 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy1,wz1, wx1,wy1,wz1, wx1,wy1,wz0, wx0,wy1,wz0,
                                     1.05f * a0, 1.05f * a1, 1.05f * a2, 1.05f * a3, style, r, g, b, 255);
                }
                // -Y
                if (!inward_occ(layer, slot, lx, ly, lz, x, y - 1, z, hole_x, hole_y, hole_z, skip_hole)) {
                    float a0 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y - 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y - 1, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y - 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    float a1 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y - 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y - 1, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y - 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    float a2 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y - 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y - 1, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y - 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    float a3 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y - 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y - 1, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y - 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz0, wx1,wy0,wz0, wx1,wy0,wz1, wx0,wy0,wz1,
                                     0.60f * a0, 0.60f * a1, 0.60f * a2, 0.60f * a3, style, r, g, b, 255);
                }
                // +X
                if (!inward_occ(layer, slot, lx, ly, lz, x + 1, y, z, hole_x, hole_y, hole_z, skip_hole)) {
                    float a0 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y - 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y - 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    float a1 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y - 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y - 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    float a2 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y + 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y + 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    float a3 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y + 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y + 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx1,wy0,wz1, wx1,wy0,wz0, wx1,wy1,wz0, wx1,wy1,wz1,
                                     0.88f * a0, 0.88f * a1, 0.88f * a2, 0.88f * a3, style, r, g, b, 255);
                }
                // -X
                if (!inward_occ(layer, slot, lx, ly, lz, x - 1, y, z, hole_x, hole_y, hole_z, skip_hole)) {
                    float a0 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y - 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y - 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    float a1 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y - 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y - 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    float a2 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y + 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y + 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    float a3 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y + 1, z, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y + 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz0, wx0,wy0,wz1, wx0,wy1,wz1, wx0,wy1,wz0,
                                     0.76f * a0, 0.76f * a1, 0.76f * a2, 0.76f * a3, style, r, g, b, 255);
                }
                // +Z
                if (!inward_occ(layer, slot, lx, ly, lz, x, y, z + 1, hole_x, hole_y, hole_z, skip_hole)) {
                    float a0 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y - 1, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y - 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    float a1 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y - 1, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y - 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    float a2 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y + 1, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y + 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    float a3 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y + 1, z + 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y + 1, z + 1, hole_x, hole_y, hole_z, skip_hole));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz1, wx1,wy0,wz1, wx1,wy1,wz1, wx0,wy1,wz1,
                                     0.95f * a0, 0.95f * a1, 0.95f * a2, 0.95f * a3, style, r, g, b, 255);
                }
                // -Z
                if (!inward_occ(layer, slot, lx, ly, lz, x, y, z - 1, hole_x, hole_y, hole_z, skip_hole)) {
                    float a0 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y - 1, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y - 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    float a1 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y - 1, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y - 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    float a2 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x - 1, y, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y + 1, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x - 1, y + 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    float a3 = corner_ao(inward_occ(layer, slot, lx, ly, lz, x + 1, y, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x, y + 1, z - 1, hole_x, hole_y, hole_z, skip_hole),
                                         inward_occ(layer, slot, lx, ly, lz, x + 1, y + 1, z - 1, hole_x, hole_y, hole_z, skip_hole));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx1,wy0,wz0, wx0,wy0,wz0, wx0,wy1,wz0, wx1,wy1,wz0,
                                     0.70f * a0, 0.70f * a1, 0.70f * a2, 0.70f * a3, style, r, g, b, 255);
                }
            }
        }
    }
}

/* Distance-tiered neighbor meshing: ring 1 = full per-block detail (exact
 * previous path), ring 2 = 2x2x2 decimated cells (1/8 the cubes), ring 3 =
 * 4x4x4 cells (1/64). Cell faces are culled cell-to-cell and across chunk
 * borders through the neighbor map. */
static void mesh_neighbor_to(FbwVert **pbuf, int *cnt, int *max_v, int allow_grow, int nb, int stride) {
    float ox = (float)(g_neighbor_dx[nb] * 16);
    float oy = (float)(g_neighbor_dy[nb] * 16);
    float oz = (float)(g_neighbor_dz[nb] * 16);
    int y, z, x;
    if (stride <= 1) {
    for (y = 0; y < CHUNK_DIM; y++) {
        for (z = 0; z < CHUNK_DIM; z++) {
            for (x = 0; x < CHUNK_DIM; x++) {
                uint8_t blk = g_neighbors[nb][(y << 8) | (z << 4) | x];
                if (blk == BLK_AIR) continue;
                uint8_t r, g, b;
                float style;
                block_color(blk, &r, &g, &b, &style);
                apply_depth_tint(&r, &g, &b);
                float wx0 = ox + (float)x, wx1 = wx0 + 1.0f;
                float wy0 = oy + (float)y, wy1 = wy0 + 1.0f;
                float wz0 = oz + (float)z, wz1 = wz0 + 1.0f;
                if (!nb_chunk_occ(nb, x, y + 1, z))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy1,wz1, wx1,wy1,wz1, wx1,wy1,wz0, wx0,wy1,wz0, 1.00f, style, r, g, b, 255);
                if (!nb_chunk_occ(nb, x, y - 1, z))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz0, wx1,wy0,wz0, wx1,wy0,wz1, wx0,wy0,wz1, 0.60f, style, r, g, b, 255);
                if (!nb_chunk_occ(nb, x + 1, y, z))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx1,wy0,wz1, wx1,wy0,wz0, wx1,wy1,wz0, wx1,wy1,wz1, 0.88f, style, r, g, b, 255);
                if (!nb_chunk_occ(nb, x - 1, y, z))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz0, wx0,wy0,wz1, wx0,wy1,wz1, wx0,wy1,wz0, 0.76f, style, r, g, b, 255);
                if (!nb_chunk_occ(nb, x, y, z + 1))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz1, wx1,wy0,wz1, wx1,wy1,wz1, wx0,wy1,wz1, 0.95f, style, r, g, b, 255);
                if (!nb_chunk_occ(nb, x, y, z - 1))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx1,wy0,wz0, wx0,wy0,wz0, wx0,wy1,wz0, wx1,wy1,wz0, 0.70f, style, r, g, b, 255);
            }
        }
    }
    return;
    }

    /* Decimated path: emit stride-sized cubes for occupied cells */
    for (y = 0; y < CHUNK_DIM; y += stride) {
        for (z = 0; z < CHUNK_DIM; z += stride) {
            for (x = 0; x < CHUNK_DIM; x += stride) {
                uint8_t blk = BLK_AIR;
                int occ = 0, dx, dy, dz;
                for (dy = 0; dy < stride && !occ; dy++) {
                    for (dz = 0; dz < stride && !occ; dz++) {
                        for (dx = 0; dx < stride && !occ; dx++) {
                            uint8_t cb = g_neighbors[nb][((y + dy) << 8) | ((z + dz) << 4) | (x + dx)];
                            if (cb != BLK_AIR) { blk = cb; occ = 1; }
                        }
                    }
                }
                if (!occ) continue;
                uint8_t r, g, b;
                float style;
                block_color(blk, &r, &g, &b, &style);
                apply_depth_tint(&r, &g, &b);
                float wx0 = ox + (float)x, wx1 = wx0 + (float)stride;
                float wy0 = oy + (float)y, wy1 = wy0 + (float)stride;
                float wz0 = oz + (float)z, wz1 = wz0 + (float)stride;
                /* adjacent-cell occupancy probed in world space (works across
                 * chunk borders through the neighbor map) */
                int ax0 = g_neighbor_dx[nb] * 16 + x, ay0 = g_neighbor_dy[nb] * 16 + y, az0 = g_neighbor_dz[nb] * 16 + z;
                if (!cell_occ_world(stride, ax0, ay0 + stride, az0))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy1,wz1, wx1,wy1,wz1, wx1,wy1,wz0, wx0,wy1,wz0, 1.00f, style, r, g, b, 255);
                if (!cell_occ_world(stride, ax0, ay0 - stride, az0))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz0, wx1,wy0,wz0, wx1,wy0,wz1, wx0,wy0,wz1, 0.60f, style, r, g, b, 255);
                if (!cell_occ_world(stride, ax0 + stride, ay0, az0))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx1,wy0,wz1, wx1,wy0,wz0, wx1,wy1,wz0, wx1,wy1,wz1, 0.88f, style, r, g, b, 255);
                if (!cell_occ_world(stride, ax0 - stride, ay0, az0))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz0, wx0,wy0,wz1, wx0,wy1,wz1, wx0,wy1,wz0, 0.76f, style, r, g, b, 255);
                if (!cell_occ_world(stride, ax0, ay0, az0 + stride))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz1, wx1,wy0,wz1, wx1,wy1,wz1, wx0,wy1,wz1, 0.95f, style, r, g, b, 255);
                if (!cell_occ_world(stride, ax0, ay0, az0 - stride))
                    push_quad_dyn(pbuf, cnt, max_v, allow_grow, wx1,wy0,wz0, wx0,wy0,wz0, wx0,wy1,wz0, wx1,wy1,wz0, 0.70f, style, r, g, b, 255);
            }
        }
    }
}

static inline int mesh_layer_occ(int layer, int x, int y, int z,
                                 int hole_x, int hole_y, int hole_z, int skip_hole,
                                 int skip_inward) {
    if (skip_hole && x == hole_x && y == hole_y && z == hole_z) return 0;
    if (layer == 1 && skip_hole && x >= 0 && x < 16 && y >= 0 && y < 16 && z >= 0 && z < 16) {
        if (is_l1_covered_by_neighbor(x, y, z)) return 0;
    }
    if (skip_inward && (layer == 0 || layer == 1) &&
        x >= 0 && x < 16 && y >= 0 && y < 16 && z >= 0 && z < 16) {
        int slot = (layer == 0) ? g_inward_grid[(y << 8) | (z << 4) | x]
                                : g_l1_inward_grid[(y << 8) | (z << 4) | x];
        if (slot >= 0) return 0;
    }
    return chunk_occ(layer, x, y, z);
}

static void mesh_layer_to(FbwVert **pbuf, int *cnt, int *max_v, int allow_grow,
                          int layer, float scale, float ox, float oy, float oz,
                          int hole_x, int hole_y, int hole_z, int skip_hole,
                          float tier_offset, int skip_inward) {
    int y, z, x;
    for (y = 0; y < CHUNK_DIM; y++) {
        for (z = 0; z < CHUNK_DIM; z++) {
            for (x = 0; x < CHUNK_DIM; x++) {
                uint8_t blk = g_chunks[layer][(y << 8) | (z << 4) | x];
                if (blk == BLK_AIR) continue;
                if (skip_hole && x == hole_x && y == hole_y && z == hole_z) continue;
                if (layer == 1 && skip_hole && is_l1_covered_by_neighbor(x, y, z)) continue;

                if (skip_inward && (layer == 0 || layer == 1)) {
                    int slot = (layer == 0) ? g_inward_grid[(y << 8) | (z << 4) | x]
                                            : g_l1_inward_grid[(y << 8) | (z << 4) | x];
                    if (slot >= 0) continue;
                }

                uint8_t r, g, b;
                float style;
                block_color(blk, &r, &g, &b, &style);
                apply_depth_tint(&r, &g, &b);
                style += tier_offset;

                float wx0 = ox + (float)x * scale;
                float wx1 = wx0 + scale;
                float wy0 = oy + (float)y * scale;
                float wy1 = wy0 + scale;
                float wz0 = oz + (float)z * scale;
                float wz1 = wz0 + scale;

                // +Y with smooth corner AO
                if (!mesh_layer_occ(layer, x, y + 1, z, hole_x, hole_y, hole_z, skip_hole, skip_inward)) {
                    float a0 = corner_ao(chunk_occ(layer, x - 1, y + 1, z),
                                         chunk_occ(layer, x, y + 1, z + 1),
                                         chunk_occ(layer, x - 1, y + 1, z + 1));
                    float a1 = corner_ao(chunk_occ(layer, x + 1, y + 1, z),
                                         chunk_occ(layer, x, y + 1, z + 1),
                                         chunk_occ(layer, x + 1, y + 1, z + 1));
                    float a2 = corner_ao(chunk_occ(layer, x + 1, y + 1, z),
                                         chunk_occ(layer, x, y + 1, z - 1),
                                         chunk_occ(layer, x + 1, y + 1, z - 1));
                    float a3 = corner_ao(chunk_occ(layer, x - 1, y + 1, z),
                                         chunk_occ(layer, x, y + 1, z - 1),
                                         chunk_occ(layer, x - 1, y + 1, z - 1));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy1,wz1, wx1,wy1,wz1, wx1,wy1,wz0, wx0,wy1,wz0,
                                     1.05f * a0, 1.05f * a1, 1.05f * a2, 1.05f * a3, style, r, g, b, 255);
                }
                // -Y
                if (!mesh_layer_occ(layer, x, y - 1, z, hole_x, hole_y, hole_z, skip_hole, skip_inward)) {
                    float a0 = corner_ao(chunk_occ(layer, x - 1, y - 1, z),
                                         chunk_occ(layer, x, y - 1, z - 1),
                                         chunk_occ(layer, x - 1, y - 1, z - 1));
                    float a1 = corner_ao(chunk_occ(layer, x + 1, y - 1, z),
                                         chunk_occ(layer, x, y - 1, z - 1),
                                         chunk_occ(layer, x + 1, y - 1, z - 1));
                    float a2 = corner_ao(chunk_occ(layer, x + 1, y - 1, z),
                                         chunk_occ(layer, x, y - 1, z + 1),
                                         chunk_occ(layer, x + 1, y - 1, z + 1));
                    float a3 = corner_ao(chunk_occ(layer, x - 1, y - 1, z),
                                         chunk_occ(layer, x, y - 1, z + 1),
                                         chunk_occ(layer, x - 1, y - 1, z + 1));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz0, wx1,wy0,wz0, wx1,wy0,wz1, wx0,wy0,wz1,
                                     0.60f * a0, 0.60f * a1, 0.60f * a2, 0.60f * a3, style, r, g, b, 255);
                }
                // +X
                if (!mesh_layer_occ(layer, x + 1, y, z, hole_x, hole_y, hole_z, skip_hole, skip_inward)) {
                    float a0 = corner_ao(chunk_occ(layer, x + 1, y - 1, z),
                                         chunk_occ(layer, x + 1, y, z + 1),
                                         chunk_occ(layer, x + 1, y - 1, z + 1));
                    float a1 = corner_ao(chunk_occ(layer, x + 1, y - 1, z),
                                         chunk_occ(layer, x + 1, y, z - 1),
                                         chunk_occ(layer, x + 1, y - 1, z - 1));
                    float a2 = corner_ao(chunk_occ(layer, x + 1, y + 1, z),
                                         chunk_occ(layer, x + 1, y, z - 1),
                                         chunk_occ(layer, x + 1, y + 1, z - 1));
                    float a3 = corner_ao(chunk_occ(layer, x + 1, y + 1, z),
                                         chunk_occ(layer, x + 1, y, z + 1),
                                         chunk_occ(layer, x + 1, y + 1, z + 1));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx1,wy0,wz1, wx1,wy0,wz0, wx1,wy1,wz0, wx1,wy1,wz1,
                                     0.88f * a0, 0.88f * a1, 0.88f * a2, 0.88f * a3, style, r, g, b, 255);
                }
                // -X
                if (!mesh_layer_occ(layer, x - 1, y, z, hole_x, hole_y, hole_z, skip_hole, skip_inward)) {
                    float a0 = corner_ao(chunk_occ(layer, x - 1, y - 1, z),
                                         chunk_occ(layer, x - 1, y, z - 1),
                                         chunk_occ(layer, x - 1, y - 1, z - 1));
                    float a1 = corner_ao(chunk_occ(layer, x - 1, y - 1, z),
                                         chunk_occ(layer, x - 1, y, z + 1),
                                         chunk_occ(layer, x - 1, y - 1, z + 1));
                    float a2 = corner_ao(chunk_occ(layer, x - 1, y + 1, z),
                                         chunk_occ(layer, x - 1, y, z + 1),
                                         chunk_occ(layer, x - 1, y + 1, z + 1));
                    float a3 = corner_ao(chunk_occ(layer, x - 1, y + 1, z),
                                         chunk_occ(layer, x - 1, y, z - 1),
                                         chunk_occ(layer, x - 1, y + 1, z - 1));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz0, wx0,wy0,wz1, wx0,wy1,wz1, wx0,wy1,wz0,
                                     0.76f * a0, 0.76f * a1, 0.76f * a2, 0.76f * a3, style, r, g, b, 255);
                }
                // +Z
                if (!mesh_layer_occ(layer, x, y, z + 1, hole_x, hole_y, hole_z, skip_hole, skip_inward)) {
                    float a0 = corner_ao(chunk_occ(layer, x - 1, y, z + 1),
                                         chunk_occ(layer, x, y - 1, z + 1),
                                         chunk_occ(layer, x - 1, y - 1, z + 1));
                    float a1 = corner_ao(chunk_occ(layer, x + 1, y, z + 1),
                                         chunk_occ(layer, x, y - 1, z + 1),
                                         chunk_occ(layer, x + 1, y - 1, z + 1));
                    float a2 = corner_ao(chunk_occ(layer, x + 1, y, z + 1),
                                         chunk_occ(layer, x, y + 1, z + 1),
                                         chunk_occ(layer, x + 1, y + 1, z + 1));
                    float a3 = corner_ao(chunk_occ(layer, x - 1, y, z + 1),
                                         chunk_occ(layer, x, y + 1, z + 1),
                                         chunk_occ(layer, x - 1, y + 1, z + 1));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx0,wy0,wz1, wx1,wy0,wz1, wx1,wy1,wz1, wx0,wy1,wz1,
                                     0.95f * a0, 0.95f * a1, 0.95f * a2, 0.95f * a3, style, r, g, b, 255);
                }
                // -Z
                if (!mesh_layer_occ(layer, x, y, z - 1, hole_x, hole_y, hole_z, skip_hole, skip_inward)) {
                    float a0 = corner_ao(chunk_occ(layer, x + 1, y, z - 1),
                                         chunk_occ(layer, x, y - 1, z - 1),
                                         chunk_occ(layer, x + 1, y - 1, z - 1));
                    float a1 = corner_ao(chunk_occ(layer, x - 1, y, z - 1),
                                         chunk_occ(layer, x, y - 1, z - 1),
                                         chunk_occ(layer, x - 1, y - 1, z - 1));
                    float a2 = corner_ao(chunk_occ(layer, x - 1, y, z - 1),
                                         chunk_occ(layer, x, y + 1, z - 1),
                                         chunk_occ(layer, x - 1, y + 1, z - 1));
                    float a3 = corner_ao(chunk_occ(layer, x + 1, y, z - 1),
                                         chunk_occ(layer, x, y + 1, z - 1),
                                         chunk_occ(layer, x + 1, y + 1, z - 1));
                    push_quad_ao_dyn(pbuf, cnt, max_v, allow_grow, wx1,wy0,wz0, wx0,wy0,wz0, wx0,wy1,wz0, wx1,wy1,wz0,
                                     0.70f * a0, 0.70f * a1, 0.70f * a2, 0.70f * a3, style, r, g, b, 255);
                }
            }
        }
    }
}

static void refresh_inward_grid(void) {
    int i;
    for (i = 0; i < CHUNK_VOL; i++) {
        g_inward_grid[i] = -1;
        g_l1_inward_grid[i] = -1;
    }
    for (i = 0; i < MAX_INWARD_SLOTS; i++) {
        if (g_inward_valid[i] &&
            g_inward_bx[i] >= 0 && g_inward_bx[i] < 16 &&
            g_inward_by[i] >= 0 && g_inward_by[i] < 16 &&
            g_inward_bz[i] >= 0 && g_inward_bz[i] < 16) {
            g_inward_grid[(g_inward_by[i] << 8) | (g_inward_bz[i] << 4) | g_inward_bx[i]] = i;
        }
    }
    for (i = 0; i < MAX_L1_INWARD_SLOTS; i++) {
        if (g_l1_inward_valid[i] &&
            g_l1_inward_bx[i] >= 0 && g_l1_inward_bx[i] < 16 &&
            g_l1_inward_by[i] >= 0 && g_l1_inward_by[i] < 16 &&
            g_l1_inward_bz[i] >= 0 && g_l1_inward_bz[i] < 16) {
            g_l1_inward_grid[(g_l1_inward_by[i] << 8) | (g_l1_inward_bz[i] << 4) | g_l1_inward_bx[i]] = i;
        }
    }
}

static void compute_parent_origins(double ox_out[MAX_PARENTS], double oy_out[MAX_PARENTS], double oz_out[MAX_PARENTS]) {
    double acc_x = 0.0, acc_y = 0.0, acc_z = 0.0;
    double pscale = 16.0;
    int p;
    for (p = 0; p < MAX_PARENTS; p++) {
        if (!g_parent_valid[p]) {
            ox_out[p] = oy_out[p] = oz_out[p] = 0.0;
        } else {
            acc_x -= (double)g_parent_bx[p] * pscale;
            acc_y -= (double)g_parent_by[p] * pscale;
            acc_z -= (double)g_parent_bz[p] * pscale;
            ox_out[p] = acc_x;
            oy_out[p] = acc_y;
            oz_out[p] = acc_z;
        }
        pscale *= 16.0;
    }
}

static void rebuild_band1_shell(const double ox[MAX_PARENTS], const double oy[MAX_PARENTS], const double oz[MAX_PARENTS]) {
    refresh_inward_grid();
    g_band1_cnt = 0;

    // Layer 0 (1x non-inward shells)
    mesh_layer_to(&g_band1_verts, &g_band1_cnt, &g_band1_cap, 1,
                  0, 1.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0, 0, 0.0f, 1);

    // Sibling neighbor chunks around Layer 0 — distance-tiered LOD:
    // ring 1 full detail, ring 2 = 2x decimated, ring 3 = 4x decimated
    for (int nb = 0; nb < MAX_NEIGHBORS; nb++) {
        if (g_neighbor_valid[nb]) {
            int ax = abs(g_neighbor_dx[nb]), ay = abs(g_neighbor_dy[nb]), az = abs(g_neighbor_dz[nb]);
            int ring = (ax >= ay && ax >= az) ? ax : ((ay >= az) ? ay : az);
            int stride = (ring <= 1) ? 1 : ((ring == 2) ? 2 : 4);
            mesh_neighbor_to(&g_band1_verts, &g_band1_cnt, &g_band1_cap, 1, nb, stride);
        }
    }

    // Layer 1 (16x parent walls surrounding Layer 0, excluding inward slots & player parent hole)
    if (g_parent_valid[0]) {
        mesh_layer_to(&g_band1_verts, &g_band1_cnt, &g_band1_cap, 1,
                      1, 16.0f, (float)ox[0], (float)oy[0], (float)oz[0],
                      g_parent_bx[0], g_parent_by[0], g_parent_bz[0], 1, 32.0f, 1);
    }

    if (g_gl_ready && g_band1_cnt > 0 && g_band1_verts != NULL) {
        glBindBuffer(GL_ARRAY_BUFFER, g_vbo_band1);
        glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)(g_band1_cnt * sizeof(FbwVert)),
                     g_band1_verts, GL_DYNAMIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    g_shell_dirty = 0;
}

static void rebuild_dirty_inward_slots(const double ox[MAX_PARENTS], const double oy[MAX_PARENTS], const double oz[MAX_PARENTS]) {
    int si;
    for (si = 0; si < MAX_INWARD_SLOTS; si++) {
        if (!g_inward_valid[si]) {
            g_inw_vcnt[si] = 0;
            g_inw_vbo_dirty[si] = 0;
            continue;
        }
        int tier = compute_slot_tier(0, g_inward_bx[si], g_inward_by[si], g_inward_bz[si],
                                     1.0f, 0.0f, 0.0f, 0.0f, g_inward_tier[si]);
        if (tier != g_inward_tier[si]) {
            g_inward_tier[si] = tier;
            g_inw_vbo_dirty[si] = 1;
        }
        if (g_inw_vbo_dirty[si]) {
            int cnt = 0;
            if (tier == 1) {
                mesh_inward_slot(0, si, g_inward_bx[si], g_inward_by[si], g_inward_bz[si],
                                 1.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0, 0,
                                 16.0f, &g_slot_verts, &cnt, &g_slot_cap, 1);
            } else {
                mesh_inward_slot_pooled(0, si, g_inward_bx[si], g_inward_by[si], g_inward_bz[si],
                                        1.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0, 0,
                                        16.0f, tier, &g_slot_verts, &cnt, &g_slot_cap, 1);
            }
            g_inw_vcnt[si] = cnt;
            if (g_gl_ready && cnt > 0 && g_slot_verts != NULL) {
                glBindBuffer(GL_ARRAY_BUFFER, g_inw_vbos[si]);
                glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)(cnt * sizeof(FbwVert)), g_slot_verts, GL_DYNAMIC_DRAW);
            }
            g_inw_vbo_dirty[si] = 0;
        }
    }

    float l1ox = g_parent_valid[0] ? (float)ox[0] : 0.0f;
    float l1oy = g_parent_valid[0] ? (float)oy[0] : 0.0f;
    float l1oz = g_parent_valid[0] ? (float)oz[0] : 0.0f;
    for (si = 0; si < MAX_L1_INWARD_SLOTS; si++) {
        if (!g_l1_inward_valid[si] || !g_parent_valid[0] ||
            is_l1_covered_by_neighbor(g_l1_inward_bx[si], g_l1_inward_by[si], g_l1_inward_bz[si])) {
            g_l1_inw_vcnt[si] = 0;
            g_l1_inw_vbo_dirty[si] = 0;
            continue;
        }
        int tier = compute_slot_tier(1, g_l1_inward_bx[si], g_l1_inward_by[si], g_l1_inward_bz[si],
                                     16.0f, l1ox, l1oy, l1oz, g_l1_inward_tier[si]);
        if (tier != g_l1_inward_tier[si]) {
            g_l1_inward_tier[si] = tier;
            g_l1_inw_vbo_dirty[si] = 1;
        }
        if (g_l1_inw_vbo_dirty[si]) {
            int cnt = 0;
            if (tier == 1) {
                mesh_inward_slot(1, si, g_l1_inward_bx[si], g_l1_inward_by[si], g_l1_inward_bz[si],
                                 16.0f, l1ox, l1oy, l1oz,
                                 g_parent_bx[0], g_parent_by[0], g_parent_bz[0], 1,
                                 0.0f, &g_slot_verts, &cnt, &g_slot_cap, 1);
            } else {
                mesh_inward_slot_pooled(1, si, g_l1_inward_bx[si], g_l1_inward_by[si], g_l1_inward_bz[si],
                                        16.0f, l1ox, l1oy, l1oz,
                                        g_parent_bx[0], g_parent_by[0], g_parent_bz[0], 1,
                                        0.0f, tier, &g_slot_verts, &cnt, &g_slot_cap, 1);
            }
            g_l1_inw_vcnt[si] = cnt;
            if (g_gl_ready && cnt > 0 && g_slot_verts != NULL) {
                glBindBuffer(GL_ARRAY_BUFFER, g_l1_inw_vbos[si]);
                glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)(cnt * sizeof(FbwVert)), g_slot_verts, GL_DYNAMIC_DRAW);
            }
            g_l1_inw_vbo_dirty[si] = 0;
        }
    }
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

static void rebuild_macro_bands(const double ox[MAX_PARENTS], const double oy[MAX_PARENTS], const double oz[MAX_PARENTS]) {
    // Band 2: Layers 2 (256x) & 3 (4096x) divided by 16.0
    g_band2_cnt = 0;
    FbwVert *b2 = g_band2_verts;
    int cap2 = MAX_BAND2_VERTS;
    if (g_parent_valid[1]) {
        mesh_layer_to(&b2, &g_band2_cnt, &cap2, 0,
                      2, 16.0f, (float)(ox[1] / 16.0), (float)(oy[1] / 16.0), (float)(oz[1] / 16.0),
                      g_parent_bx[1], g_parent_by[1], g_parent_bz[1], 1, 32.0f, 0);
    }
    if (g_parent_valid[2]) {
        mesh_layer_to(&b2, &g_band2_cnt, &cap2, 0,
                      3, 256.0f, (float)(ox[2] / 16.0), (float)(oy[2] / 16.0), (float)(oz[2] / 16.0),
                      g_parent_bx[2], g_parent_by[2], g_parent_bz[2], 1, 32.0f, 0);
    }
    if (g_gl_ready && g_band2_cnt > 0) {
        glBindBuffer(GL_ARRAY_BUFFER, g_vbo_band2);
        glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)(g_band2_cnt * sizeof(FbwVert)),
                     g_band2_verts, GL_DYNAMIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    // Band 3: Layers 4 (65536x) & 5 (1048576x) divided by 4096.0
    g_band3_cnt = 0;
    FbwVert *b3 = g_band3_verts;
    int cap3 = MAX_BAND3_VERTS;
    if (g_parent_valid[3]) {
        mesh_layer_to(&b3, &g_band3_cnt, &cap3, 0,
                      4, 16.0f, (float)(ox[3] / 4096.0), (float)(oy[3] / 4096.0), (float)(oz[3] / 4096.0),
                      g_parent_bx[3], g_parent_by[3], g_parent_bz[3], 1, 32.0f, 0);
    }
    if (g_parent_valid[4]) {
        mesh_layer_to(&b3, &g_band3_cnt, &cap3, 0,
                      5, 256.0f, (float)(ox[4] / 4096.0), (float)(oy[4] / 4096.0), (float)(oz[4] / 4096.0),
                      g_parent_bx[4], g_parent_by[4], g_parent_bz[4], 1, 32.0f, 0);
    }
    if (g_gl_ready && g_band3_cnt > 0) {
        glBindBuffer(GL_ARRAY_BUFFER, g_vbo_band3);
        glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)(g_band3_cnt * sizeof(FbwVert)),
                     g_band3_verts, GL_DYNAMIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
}

static void emit_ring_3d(float cx, float cy, float cz, float rad, float spin,
                         uint8_t r, uint8_t g, uint8_t b) {
    const int segs = 14;
    float thick = rad * 0.22f;
    int i;
    for (i = 0; i < segs; i++) {
        float a0 = spin + (float)i * 6.2831853f / (float)segs;
        float a1 = spin + (float)(i + 1) * 6.2831853f / (float)segs;
        float c0 = cosf(a0), s0 = sinf(a0);
        float c1 = cosf(a1), s1 = sinf(a1);
        float x0 = cx + c0 * rad, y0 = cy + s0 * rad;
        float x1 = cx + c1 * rad, y1 = cy + s1 * rad;
        float ix0 = cx + c0 * (rad - thick), iy0 = cy + s0 * (rad - thick);
        float ix1 = cx + c1 * (rad - thick), iy1 = cy + s1 * (rad - thick);
        // Front face, back face, outer rim, inner rim
        push_quad(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                  ix0, iy0, cz + 0.09f, x0, y0, cz + 0.09f, x1, y1, cz + 0.09f, ix1, iy1, cz + 0.09f,
                  1.06f, 9.0f, r, g, b, 255);
        push_quad(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                  ix1, iy1, cz - 0.09f, x1, y1, cz - 0.09f, x0, y0, cz - 0.09f, ix0, iy0, cz - 0.09f,
                  0.85f, 9.0f, r, g, b, 255);
        push_quad(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                  x0, y0, cz - 0.09f, x1, y1, cz - 0.09f, x1, y1, cz + 0.09f, x0, y0, cz + 0.09f,
                  0.96f, 9.0f, r, g, b, 255);
    }
}

static void build_dynamic_verts(void) {
    g_dyn_vert_cnt = 0;
    float t = (float)g_anim_ms * 0.001f;
    int i;

    for (i = 0; i < g_ent_cnt; i++) {
        FbwEnt *e = &g_ents[i];
        int k = e->kind;
        if ((k >= ENT_RING_GREEN && k <= ENT_RING_PINK) || k == ENT_RING_DANGER) {
            uint8_t r = 48, g = 255, b = 118;
            if (k == ENT_RING_RED)    { r = 255; g = 68;  b = 68;  }
            if (k == ENT_RING_BLUE)   { r = 64;  g = 174; b = 255; }
            if (k == ENT_RING_PINK)   { r = 255; g = 92;  b = 224; }
            if (k == ENT_RING_DANGER) { r = 255; g = 52;  b = 42;  }
            emit_ring_3d(e->x, e->y, e->z, 0.58f, t * 2.2f + i * 0.7f, r, g, b);
            emit_ring_3d(e->x, e->y, e->z, 0.34f, -t * 3.1f,
                         255, (uint8_t)(k == ENT_RING_DANGER ? 204 : 255), (uint8_t)(k == ENT_RING_DANGER ? 48 : 255));
            continue;
        }
        if (k == ENT_MARKER_BEACON) {
            float bob_m = sinf(t * 4.0f) * 0.10f;
            emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                      e->x, e->y + bob_m, e->z, 0.24f, 74, 245, 128, 255, 2.0f);
            emit_ring_3d(e->x, e->y + bob_m, e->z, 0.44f, t * 3.5f, 74, 245, 128);
            continue;
        }

        float hs = (k == ENT_SINGULARITY) ? 0.62f :
                   (k == ENT_GUARDIAN || k == ENT_DEMON) ? 0.42f :
                   (k >= ENT_GOLD) ? 0.21f : 0.33f;
        float bob = (k >= ENT_GOLD) ? sinf(t * 3.5f + i) * 0.12f : 0.0f;
        uint8_t r = 200, g = 200, b = 200;
        float style = (k >= ENT_GOLD) ? 2.0f : 9.0f;

        if (k == ENT_RAT)         { r = 168; g = 132; b = 92; }
        else if (k == ENT_SPIDER) { r = 128; g = 48;  b = 164; }
        else if (k == ENT_GOON)   { r = 98;  g = 220; b = 74; }
        else if (k == ENT_MARINE) { r = 64;  g = 152; b = 240; }
        else if (k == ENT_PIRATE) { r = 234; g = 88;  b = 62; }
        else if (k == ENT_YINYANG){ r = 235; g = 240; b = 250; }
        else if (k == ENT_MENACE) { r = 245; g = 158; b = 11; }
        else if (k == ENT_DEMON)  { r = 210; g = 32;  b = 68; }
        else if (k == ENT_GUARDIAN){r = 250; g = 204; b = 21; }
        else if (k == ENT_SINGULARITY) { r = 244; g = 63; b = 184; style = 1.0f; }
        else if (k == ENT_GOLD)   { r = 255; g = 215; b = 42; }
        else if (k == ENT_HEALTH) { r = 248; g = 72;  b = 92; }
        else if (k == ENT_ARMOR)  { r = 72;  g = 196; b = 255; }
        else if (k == ENT_AMMO)   { r = 255; g = 168; b = 56; }
        else if (k == ENT_KEY)    { r = 253; g = 224; b = 71; }
        else if (k == ENT_FRIEND_K) { r = 255; g = 248; b = 128; }

        if (e->freeze_ms > 0 && k >= ENT_RAT && k <= ENT_SINGULARITY) {
            r = (uint8_t)((r + 96 * 2) / 3);
            g = (uint8_t)((g + 240 * 2) / 3);
            b = 255;
        }

        // Core torso
        emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                  e->x, e->y + bob, e->z, hs, r, g, b, 255, style);

        // Multi-part stylized silhouette
        if (k >= ENT_RAT && k <= ENT_SINGULARITY) {
            float wing = sinf(t * 6.0f + i) * hs * 0.35f;
            uint8_t er = (uint8_t)(e->freeze_ms > 0 ? 186 : 255);
            uint8_t eg = (uint8_t)(e->freeze_ms > 0 ? 250 : 52);
            uint8_t eb = (uint8_t)(e->freeze_ms > 0 ? 255 : 72);
            // Glowing head/eye crest
            emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                      e->x, e->y + hs * 1.15f, e->z, hs * 0.45f, er, eg, eb, 255, 9.0f);
            // Flanking appendages / wings
            emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                      e->x - hs * 1.25f, e->y + wing, e->z, hs * 0.36f, r, g, b, 255, 9.0f);
            emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                      e->x + hs * 1.25f, e->y - wing, e->z, hs * 0.36f, r, g, b, 255, 9.0f);
            if (k == ENT_SINGULARITY || k == ENT_GUARDIAN) {
                emit_ring_3d(e->x, e->y, e->z, hs * 1.95f, t * 3.0f, 255, 96, 220);
            }
        } else if (k == ENT_FRIEND_K) {
            emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                      e->x, e->y + bob + hs * 1.35f, e->z, hs * 0.55f,
                      255, 255, 200, 255, 2.0f);
            emit_ring_3d(e->x, e->y + bob, e->z, hs * 1.8f, t * 1.8f, 255, 240, 110);
        } else if (k >= ENT_GOLD) {
            // Orbiting sparkle crystal for pickups
            float ox = cosf(t * 4.0f + i) * hs * 1.45f;
            float oz = sinf(t * 4.0f + i) * hs * 1.45f;
            emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                      e->x + ox, e->y + bob + 0.14f, e->z + oz, hs * 0.38f, 255, 255, 255, 255, 9.0f);
        }
    }

    for (i = 0; i < g_shot_cnt; i++) {
        uint32_t c = g_shots[i].rgb;
        emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                  g_shots[i].x, g_shots[i].y, g_shots[i].z, 0.14f,
                  (uint8_t)((c >> 16) & 0xff), (uint8_t)((c >> 8) & 0xff), (uint8_t)(c & 0xff),
                  255, 9.0f);
    }

    for (i = 0; i < g_part_cnt; i++) {
        uint32_t c = g_parts[i].rgb;
        emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                  g_parts[i].x, g_parts[i].y, g_parts[i].z, 0.085f,
                  (uint8_t)((c >> 16) & 0xff), (uint8_t)((c >> 8) & 0xff), (uint8_t)(c & 0xff),
                  255, 9.0f);
    }

    if (g_beam_active) {
        uint32_t c = g_beam_rgb;
        uint8_t br = (uint8_t)((c >> 16) & 0xff);
        uint8_t bg = (uint8_t)((c >> 8) & 0xff);
        uint8_t bb = (uint8_t)(c & 0xff);
        int steps = 16;
        for (i = 1; i <= steps; i++) {
            float u = (float)i / (float)steps;
            float bx = g_beam_x1 + (g_beam_x2 - g_beam_x1) * u;
            float by = g_beam_y1 + (g_beam_y2 - g_beam_y1) * u;
            float bz = g_beam_z1 + (g_beam_z2 - g_beam_z1) * u;
            emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                      bx, by, bz, 0.07f, br, bg, bb, 255, 9.0f);
        }
    }
}

static void biome_sky_colors(int biome, float *tr, float *tg, float *tb,
                             float *br, float *bg, float *bb) {
    switch (biome) {
        case 0: *tr=0.02f; *tg=0.04f; *tb=0.09f; *br=0.05f; *bg=0.09f; *bb=0.18f; break;
        case 1: *tr=0.08f; *tg=0.22f; *tb=0.45f; *br=0.40f; *bg=0.70f; *bb=0.92f; break;
        case 2: *tr=0.05f; *tg=0.24f; *tb=0.28f; *br=0.22f; *bg=0.60f; *bb=0.52f; break;
        case 3: *tr=0.16f; *tg=0.30f; *tb=0.56f; *br=0.66f; *bg=0.80f; *bb=0.95f; break;
        case 4: *tr=0.30f; *tg=0.21f; *tb=0.06f; *br=0.74f; *bg=0.58f; *bb=0.22f; break;
        case 5: *tr=0.15f; *tg=0.05f; *tb=0.26f; *br=0.46f; *bg=0.18f; *bb=0.56f; break;
        case 6: *tr=0.03f; *tg=0.05f; *tb=0.10f; *br=0.10f; *bg=0.14f; *bb=0.24f; break;
        case 8: *tr=0.10f; *tg=0.32f; *tb=0.54f; *br=0.58f; *bg=0.86f; *bb=0.98f; break;
        case 9: *tr=0.36f; *tg=0.18f; *tb=0.07f; *br=0.86f; *bg=0.62f; *bb=0.28f; break;
        default:*tr=0.18f; *tg=0.03f; *tb=0.20f; *br=0.42f; *bg=0.09f; *bb=0.36f; break;
    }
    if (g_depth >= 500) {
        float sc = 1.0f - ((float)(g_depth - 500) / 1500.0f) * 0.70f;
        if (sc < 0.30f) sc = 0.30f;
        *tr *= sc; *tg *= sc; *tb *= sc;
        *br *= sc; *bg *= sc; *bb *= sc;
    }
}

static void build_mvp_band(float *m, float aspect, float cam_x, float cam_y, float cam_z,
                           float znear, float zfar) {
    float cp = cosf(g_pitch), sp = sinf(g_pitch);
    float cy = cosf(g_yaw),   sy = sinf(g_yaw);
    float cr = cosf(g_roll),  sr = sinf(g_roll);

    float fx = cp * cy, fy = sp, fz = cp * sy;
    float rx0 = -sy, rz0 = cy;
    float ux0 = -sp * cy, uy0 = cp, uz0 = -sp * sy;

    float rx = rx0 * cr + ux0 * sr;
    float ry = uy0 * sr;
    float rz = rz0 * cr + uz0 * sr;

    float ux = ux0 * cr - rx0 * sr;
    float uy = uy0 * cr;
    float uz = uz0 * cr - rz0 * sr;

    const float fov_scale = 0.74f;
    float f = 1.0f / fov_scale;
    float p00 = f / aspect;
    float p11 = f;
    float p22 = (zfar + znear) / (znear - zfar);
    float p23 = (2.0f * zfar * znear) / (znear - zfar);

    float vx = -(rx * cam_x + ry * cam_y + rz * cam_z);
    float vy = -(ux * cam_x + uy * cam_y + uz * cam_z);
    float vz =  (fx * cam_x + fy * cam_y + fz * cam_z);

    m[0]  = p00 * rx;  m[1]  = p11 * ux;  m[2]  = p22 * (-fx);  m[3]  = fx;
    m[4]  = p00 * ry;  m[5]  = p11 * uy;  m[6]  = p22 * (-fy);  m[7]  = fy;
    m[8]  = p00 * rz;  m[9]  = p11 * uz;  m[10] = p22 * (-fz);  m[11] = fz;
    m[12] = p00 * vx;  m[13] = p11 * vy;  m[14] = p22 * vz + p23; m[15] = -vz;
}

static void draw_vert_buffer(GLuint vbo, int vert_cnt) {
    if (vert_cnt <= 0) return;
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(FbwVert), (const void *)0);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, sizeof(FbwVert), (const void *)12);
    glVertexAttribPointer(2, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(FbwVert), (const void *)28);
    glDrawArrays(GL_TRIANGLES, 0, vert_cnt);
}

// === Exported C API called from Goose (integer-only FFI) ===

FBW_VIS_DEFAULT void fbw_gl_set_viewport(int w, int h, int depth, int biome, int flash_rgb, int flash_ms) {
    g_vp_w = (w > 1) ? w : 1280;
    g_vp_h = (h > 1) ? h : 720;
    g_depth = depth;
    g_biome = biome;
    g_flash_rgb = flash_rgb;
    g_flash_ms = flash_ms;
}

FBW_VIS_DEFAULT void fbw_gl_set_camera(int px_mm, int py_mm, int pz_mm,
                                       int yaw_mrad, int pitch_mrad, int roll_mrad, int anim_ms) {
    g_cam_x = (float)px_mm * 0.001f;
    g_cam_y = (float)py_mm * 0.001f;
    g_cam_z = (float)pz_mm * 0.001f;
    g_yaw   = (float)yaw_mrad * 0.001f;
    g_pitch = (float)pitch_mrad * 0.001f;
    g_roll  = (float)roll_mrad * 0.001f;
    g_anim_ms = anim_ms;
}

FBW_VIS_DEFAULT void fbw_gl_set_parent_meta(int layer, int valid, int bx, int by, int bz, int biome) {
    if (layer < 0 || layer >= MAX_PARENTS) return;
    g_parent_valid[layer] = valid;
    g_parent_bx[layer] = bx;
    g_parent_by[layer] = by;
    g_parent_bz[layer] = bz;
    g_parent_biome[layer] = biome;
}

FBW_VIS_DEFAULT void fbw_gl_push_chunk_quad(int layer, int qidx, int packed4) {
    if (layer < 0 || layer >= MAX_LAYERS || qidx < 0 || qidx >= 1024) return;
    uint32_t u = (uint32_t)packed4;
    int base = qidx * 4;
    g_chunks[layer][base + 0] = (uint8_t)(u & 0xffu);
    g_chunks[layer][base + 1] = (uint8_t)((u >> 8) & 0xffu);
    g_chunks[layer][base + 2] = (uint8_t)((u >> 16) & 0xffu);
    g_chunks[layer][base + 3] = (uint8_t)((u >> 24) & 0xffu);
}

FBW_VIS_DEFAULT void fbw_gl_set_neighbor_meta(int nb, int valid, int dx, int dy, int dz, int biome) {
    if (nb < 0 || nb >= MAX_NEIGHBORS) return;
    memset(g_neighbors[nb], BLK_AIR, CHUNK_VOL);  /* stale-clear: zero-quad pushes may be skipped */
    g_neighbor_valid[nb] = valid;
    g_neighbor_dx[nb] = dx;
    g_neighbor_dy[nb] = dy;
    g_neighbor_dz[nb] = dz;
    g_neighbor_biome[nb] = biome;
    neighbor_map_rebuild();
}

FBW_VIS_DEFAULT void fbw_gl_push_neighbor_quad(int nb, int qidx, int packed4) {
    if (nb < 0 || nb >= MAX_NEIGHBORS || qidx < 0 || qidx >= 1024) return;
    uint32_t u = (uint32_t)packed4;
    int base = qidx * 4;
    g_neighbors[nb][base + 0] = (uint8_t)(u & 0xffu);
    g_neighbors[nb][base + 1] = (uint8_t)((u >> 8) & 0xffu);
    g_neighbors[nb][base + 2] = (uint8_t)((u >> 16) & 0xffu);
    g_neighbors[nb][base + 3] = (uint8_t)((u >> 24) & 0xffu);
}

FBW_VIS_DEFAULT void fbw_gl_mark_chunks_dirty(void) {
    g_chunks_dirty = 1;
    g_shell_dirty = 1;
}

FBW_VIS_DEFAULT void fbw_gl_set_inward_meta(int slot, int valid, int bx, int by, int bz, int biome) {
    if (slot < 0 || slot >= MAX_INWARD_SLOTS) return;
    if (g_inward_valid[slot] != valid || g_inward_bx[slot] != bx || g_inward_by[slot] != by || g_inward_bz[slot] != bz) {
        g_shell_dirty = 1;
    }
    g_inward_valid[slot] = valid;
    g_inward_bx[slot] = bx;
    g_inward_by[slot] = by;
    g_inward_bz[slot] = bz;
    g_inward_biome[slot] = biome;
    g_inward_tier[slot] = 0;
    g_inw_vbo_dirty[slot] = 1;
}

FBW_VIS_DEFAULT void fbw_gl_push_inward_quad(int slot, int qidx, int packed4) {
    if (slot < 0 || slot >= MAX_INWARD_SLOTS || qidx < 0 || qidx >= 1024) return;
    uint32_t u = (uint32_t)packed4;
    int base = qidx * 4;
    g_inward[slot][base + 0] = (uint8_t)(u & 0xffu);
    g_inward[slot][base + 1] = (uint8_t)((u >> 8) & 0xffu);
    g_inward[slot][base + 2] = (uint8_t)((u >> 16) & 0xffu);
    g_inward[slot][base + 3] = (uint8_t)((u >> 24) & 0xffu);
    g_inw_vbo_dirty[slot] = 1;
}

FBW_VIS_DEFAULT void fbw_gl_set_l1_inward_meta(int slot, int valid, int bx, int by, int bz, int biome) {
    if (slot < 0 || slot >= MAX_L1_INWARD_SLOTS) return;
    if (g_l1_inward_valid[slot] != valid || g_l1_inward_bx[slot] != bx || g_l1_inward_by[slot] != by || g_l1_inward_bz[slot] != bz) {
        g_shell_dirty = 1;
    }
    g_l1_inward_valid[slot] = valid;
    g_l1_inward_bx[slot] = bx;
    g_l1_inward_by[slot] = by;
    g_l1_inward_bz[slot] = bz;
    g_l1_inward_biome[slot] = biome;
    g_l1_inward_tier[slot] = 0;
    g_l1_inw_vbo_dirty[slot] = 1;
}

FBW_VIS_DEFAULT void fbw_gl_push_l1_inward_quad(int slot, int qidx, int packed4) {
    if (slot < 0 || slot >= MAX_L1_INWARD_SLOTS || qidx < 0 || qidx >= 1024) return;
    uint32_t u = (uint32_t)packed4;
    int base = qidx * 4;
    g_l1_inward[slot][base + 0] = (uint8_t)(u & 0xffu);
    g_l1_inward[slot][base + 1] = (uint8_t)((u >> 8) & 0xffu);
    g_l1_inward[slot][base + 2] = (uint8_t)((u >> 16) & 0xffu);
    g_l1_inward[slot][base + 3] = (uint8_t)((u >> 24) & 0xffu);
    g_l1_inw_vbo_dirty[slot] = 1;
}

FBW_VIS_DEFAULT void fbw_gl_set_lod_config(int disable_lod, int lod_dist_level) {
    int dl = (disable_lod != 0) ? 1 : 0;
    int lv = lod_dist_level;
    if (lv < 1) lv = 1;
    if (lv > 7) lv = 7;
    if (dl != g_disable_lod || lv != g_lod_dist_level) {
        g_disable_lod = dl;
        g_lod_dist_level = lv;
        g_inward_dirty = 1;
    }
}

FBW_VIS_DEFAULT void fbw_gl_mark_inward_dirty(void) {
    g_inward_dirty = 1;
}

FBW_VIS_DEFAULT void fbw_gl_clear_dynamic(void) {
    g_ent_cnt = 0;
    g_shot_cnt = 0;
    g_part_cnt = 0;
    g_beam_active = 0;
}

FBW_VIS_DEFAULT void fbw_gl_push_entity(int kind, int x_mm, int y_mm, int z_mm, int hp, int max_hp, int freeze_ms) {
    if (g_ent_cnt >= MAX_ENTS) return;
    FbwEnt *e = &g_ents[g_ent_cnt++];
    e->kind = kind;
    e->x = (float)x_mm * 0.001f;
    e->y = (float)y_mm * 0.001f;
    e->z = (float)z_mm * 0.001f;
    e->hp = hp;
    e->max_hp = max_hp;
    e->freeze_ms = freeze_ms;
}

FBW_VIS_DEFAULT void fbw_gl_push_shot(int x_mm, int y_mm, int z_mm, int rgb) {
    if (g_shot_cnt >= MAX_SHOTS) return;
    FbwPt *p = &g_shots[g_shot_cnt++];
    p->x = (float)x_mm * 0.001f;
    p->y = (float)y_mm * 0.001f;
    p->z = (float)z_mm * 0.001f;
    p->rgb = (uint32_t)rgb;
}

FBW_VIS_DEFAULT void fbw_gl_push_particle(int x_mm, int y_mm, int z_mm, int rgb) {
    if (g_part_cnt >= MAX_PARTS) return;
    FbwPt *p = &g_parts[g_part_cnt++];
    p->x = (float)x_mm * 0.001f;
    p->y = (float)y_mm * 0.001f;
    p->z = (float)z_mm * 0.001f;
    p->rgb = (uint32_t)rgb;
}

FBW_VIS_DEFAULT void fbw_gl_push_beam(int active, int x1_mm, int y1_mm, int z1_mm,
                                      int x2_mm, int y2_mm, int z2_mm, int rgb) {
    g_beam_active = active;
    g_beam_x1 = (float)x1_mm * 0.001f;
    g_beam_y1 = (float)y1_mm * 0.001f;
    g_beam_z1 = (float)z1_mm * 0.001f;
    g_beam_x2 = (float)x2_mm * 0.001f;
    g_beam_y2 = (float)y2_mm * 0.001f;
    g_beam_z2 = (float)z2_mm * 0.001f;
    g_beam_rgb = (uint32_t)rgb;
}

FBW_VIS_DEFAULT void fbw_gl_render_3d(void) {
    if (g_gl_ready && (!glIsProgram(g_prog_sky) || !glIsProgram(g_prog_world))) {
        g_gl_ready = 0;
        g_chunks_dirty = 1;
        g_shell_dirty = 1;
        g_inward_dirty = 1;
    }
    init_gl_resources();
    if (!g_gl_ready) return;

    if (!g_chunks_dirty && !g_inward_dirty && !g_disable_lod) {
        int si;
        for (si = 0; si < MAX_INWARD_SLOTS && !g_inward_dirty; si++) {
            if (g_inward_valid[si]) {
                int nt = compute_slot_tier(0, g_inward_bx[si], g_inward_by[si], g_inward_bz[si],
                                           1.0f, 0.0f, 0.0f, 0.0f, g_inward_tier[si]);
                if (nt != g_inward_tier[si]) g_inward_dirty = 1;
            }
        }
        if (!g_inward_dirty && g_parent_valid[0]) {
            float l1ox = -(float)g_parent_bx[0] * 16.0f;
            float l1oy = -(float)g_parent_by[0] * 16.0f;
            float l1oz = -(float)g_parent_bz[0] * 16.0f;
            for (si = 0; si < MAX_L1_INWARD_SLOTS && !g_inward_dirty; si++) {
                if (g_l1_inward_valid[si]) {
                    int nt = compute_slot_tier(1, g_l1_inward_bx[si], g_l1_inward_by[si], g_l1_inward_bz[si],
                                               16.0f, l1ox, l1oy, l1oz, g_l1_inward_tier[si]);
                    if (nt != g_l1_inward_tier[si]) g_inward_dirty = 1;
                }
            }
        }
    }

    if (g_chunks_dirty || g_shell_dirty || g_inward_dirty) {
        double ox[MAX_PARENTS], oy[MAX_PARENTS], oz[MAX_PARENTS];
        compute_parent_origins(ox, oy, oz);
        if (g_chunks_dirty) {
            rebuild_macro_bands(ox, oy, oz);
        }
        if (g_chunks_dirty || g_shell_dirty) {
            rebuild_band1_shell(ox, oy, oz);
        }
        if (g_chunks_dirty || g_inward_dirty) {
            rebuild_dirty_inward_slots(ox, oy, oz);
        }
        g_chunks_dirty = 0;
        g_inward_dirty = 0;
    }
    build_dynamic_verts();

    float tr, tg, tb, br, bg, bb;
    biome_sky_colors(g_biome, &tr, &tg, &tb, &br, &bg, &bb);
    float time_s = (float)g_anim_ms * 0.001f;
    float star = (g_biome == 0 || g_biome == 1 || g_biome == 6 || g_biome == 7) ? 1.0f : 0.0f;

    float aspect = (float)g_vp_w / (float)g_vp_h;
    float cp = cosf(g_pitch), sp = sinf(g_pitch);
    float cy = cosf(g_yaw),   sy = sinf(g_yaw);
    float cr = cosf(g_roll),  sr = sinf(g_roll);
    float fx = cp * cy, fy = sp, fz = cp * sy;
    float rx0 = -sy, rz0 = cy;
    float ux0 = -sp * cy, uy0 = cp, uz0 = -sp * sy;
    float rx = rx0 * cr + ux0 * sr, ry = uy0 * sr, rz = rz0 * cr + uz0 * sr;
    float ux = ux0 * cr - rx0 * sr, uy = uy0 * cr, uz = uz0 * cr - rz0 * sr;

    glViewport(0, 0, g_vp_w, g_vp_h);

    // 1. 3D-projected Sky dome pass (no depth write, zero +/-PI wrap seam)
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    glDisable(GL_CULL_FACE);
    glDisable(GL_BLEND);

    glUseProgram(g_prog_sky);
    glUniform3f(g_u_sky_top, tr, tg, tb);
    glUniform3f(g_u_sky_bot, br, bg, bb);
    glUniform1f(g_u_sky_star, star);
    glUniform1f(g_u_sky_time, time_s);
    glUniform3f(g_u_sky_fwd, fx, fy, fz);
    glUniform3f(g_u_sky_right, rx, ry, rz);
    glUniform3f(g_u_sky_up, ux, uy, uz);
    glUniform1f(g_u_sky_aspect, aspect);

    glBindBuffer(GL_ARRAY_BUFFER, g_vbo_sky);
    glEnableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDisableVertexAttribArray(2);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, (const void *)0);
    glDrawArrays(GL_TRIANGLES, 0, 6);

    // Shared 3D shader uniforms
    glEnable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    float fog_r = br * 0.7f + tr * 0.3f;
    float fog_g = bg * 0.7f + tg * 0.3f;
    float fog_b = bb * 0.7f + tb * 0.3f;

    float flash_a = 0.0f;
    if (g_flash_ms > 0) {
        flash_a = (float)g_flash_ms / 460.0f;
        if (flash_a > 0.42f) flash_a = 0.42f;
    }
    float fl_r = (float)((g_flash_rgb >> 16) & 0xff) / 255.0f;
    float fl_g = (float)((g_flash_rgb >> 8) & 0xff) / 255.0f;
    float fl_b = (float)(g_flash_rgb & 0xff) / 255.0f;

    glUseProgram(g_prog_world);
    glUniform3f(g_u_fog_col, fog_r, fog_g, fog_b);
    glUniform1f(g_u_time, time_s);
    glUniform4f(g_u_flash, fl_r, fl_g, fl_b, flash_a);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);

    float mvp[16];

    // 2. Band 3: Colossal Macro Parents (65,536x & 1,048,576x in 1/4096 scale)
    if (g_band3_cnt > 0) {
        glClear(GL_DEPTH_BUFFER_BIT);
        float c3x = g_cam_x * (1.0f / 4096.0f);
        float c3y = g_cam_y * (1.0f / 4096.0f);
        float c3z = g_cam_z * (1.0f / 4096.0f);
        build_mvp_band(mvp, aspect, c3x, c3y, c3z, 0.25f, 8192.0f);
        glUniformMatrix4fv(g_u_mvp, 1, GL_FALSE, mvp);
        glUniform3f(g_u_cam, c3x, c3y, c3z);
        glUniform2f(g_u_fog_params, 260.0f, 3800.0f);
        glUniform1f(g_u_fog_max, 0.56f);
        draw_vert_buffer(g_vbo_band3, g_band3_cnt);
    }

    // 3. Band 2: Outer Macro Parents (256x & 4,096x in 1/16 scale)
    if (g_band2_cnt > 0) {
        glClear(GL_DEPTH_BUFFER_BIT);
        float c2x = g_cam_x * 0.0625f;
        float c2y = g_cam_y * 0.0625f;
        float c2z = g_cam_z * 0.0625f;
        build_mvp_band(mvp, aspect, c2x, c2y, c2z, 0.25f, 8192.0f);
        glUniformMatrix4fv(g_u_mvp, 1, GL_FALSE, mvp);
        glUniform3f(g_u_cam, c2x, c2y, c2z);
        glUniform2f(g_u_fog_params, 160.0f, 3200.0f);
        glUniform1f(g_u_fog_max, 0.60f);
        draw_vert_buffer(g_vbo_band2, g_band2_cnt);
    }

    // 4. Band 1: Active 1x + 10 Neighbors + Per-Slot Inward 1/16x LOD + Layer 1 (16x) + Entities
    glClear(GL_DEPTH_BUFFER_BIT);
    build_mvp_band(mvp, aspect, g_cam_x, g_cam_y, g_cam_z, 0.08f, 280.0f);
    glUniformMatrix4fv(g_u_mvp, 1, GL_FALSE, mvp);
    glUniform3f(g_u_cam, g_cam_x, g_cam_y, g_cam_z);
    glUniform2f(g_u_fog_params, 32.0f, 260.0f);
    glUniform1f(g_u_fog_max, 0.64f);

    if (g_band1_cnt > 0) {
        draw_vert_buffer(g_vbo_band1, g_band1_cnt);
    }
    for (int si = 0; si < MAX_INWARD_SLOTS; si++) {
        if (g_inward_valid[si] && g_inw_vcnt[si] > 0) {
            draw_vert_buffer(g_inw_vbos[si], g_inw_vcnt[si]);
        }
    }
    if (g_parent_valid[0]) {
        for (int si = 0; si < MAX_L1_INWARD_SLOTS; si++) {
            if (g_l1_inward_valid[si] && g_l1_inw_vcnt[si] > 0 &&
                !is_l1_covered_by_neighbor(g_l1_inward_bx[si], g_l1_inward_by[si], g_l1_inward_bz[si])) {
                draw_vert_buffer(g_l1_inw_vbos[si], g_l1_inw_vcnt[si]);
            }
        }
    }

    if (g_dyn_vert_cnt > 0) {
        glBindBuffer(GL_ARRAY_BUFFER, g_vbo_dyn);
        glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)(g_dyn_vert_cnt * sizeof(FbwVert)),
                     g_dyn_verts, GL_STREAM_DRAW);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(FbwVert), (const void *)0);
        glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, sizeof(FbwVert), (const void *)12);
        glVertexAttribPointer(2, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(FbwVert), (const void *)28);
        glDrawArrays(GL_TRIANGLES, 0, g_dyn_vert_cnt);
    }

    // 5. Cleanly restore OpenGL state expected by rawdraw CNFGOGL.c
    glDisableVertexAttribArray(2);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    glDisable(GL_CULL_FACE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glUseProgram(0);
}
