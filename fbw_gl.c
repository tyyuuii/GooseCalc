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

#define BLK_BLACK_CUBE    20
#define BLK_WHITE_FLOWER  21
#define BLK_ALPHA_CUBE    22
#define BLK_FLOWER_Y_CORE 23
#define BLK_MYLANTIS_M    24
#define BLK_YING_PLANET   25
#define BLK_ICE_WORLD     26
#define BLK_DESERT_WORLD  27
#define BLK_CORE_GATE     28

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

#define CHUNK_DIM 16
#define CHUNK_VOL 4096
#define MAX_LAYERS 4
#define MAX_ENTS 96
#define MAX_SHOTS 72
#define MAX_PARTS 72
#define MAX_CHUNK_VERTS 98304
#define MAX_DYN_VERTS   32768

typedef struct {
    float x, y, z;
    float u, v, light, kind;
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

static uint8_t g_chunks[MAX_LAYERS][CHUNK_VOL];
static int g_parent_valid[3] = {0, 0, 0};
static int g_parent_bx[3] = {0, 0, 0};
static int g_parent_by[3] = {0, 0, 0};
static int g_parent_bz[3] = {0, 0, 0};
static int g_parent_biome[3] = {0, 0, 0};
static int g_chunks_dirty = 1;

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

static FbwVert g_chunk_verts[MAX_CHUNK_VERTS];
static int g_chunk_vert_cnt = 0;
static FbwVert g_dyn_verts[MAX_DYN_VERTS];
static int g_dyn_vert_cnt = 0;

static int g_gl_ready = 0;
static GLuint g_prog_sky = 0;
static GLuint g_prog_world = 0;
static GLuint g_vbo_sky = 0;
static GLuint g_vbo_chunk = 0;
static GLuint g_vbo_dyn = 0;

// Uniform locations
static GLint g_u_sky_top = -1, g_u_sky_bot = -1, g_u_sky_star = -1, g_u_sky_time = -1;
static GLint g_u_sky_yaw = -1, g_u_sky_pitch = -1;
static GLint g_u_mvp = -1, g_u_cam = -1, g_u_fog_col = -1, g_u_fog_params = -1;
static GLint g_u_time = -1, g_u_flash = -1;

static const char *SKY_VS =
    "attribute vec2 a_pos;\n"
    "varying vec2 v_uv;\n"
    "void main() {\n"
    "  v_uv = a_pos * 0.5 + 0.5;\n"
    "  gl_Position = vec4(a_pos, 0.999, 1.0);\n"
    "}\n";

static const char *SKY_FS =
    "precision highp float;\n"
    "varying vec2 v_uv;\n"
    "uniform vec3 u_top;\n"
    "uniform vec3 u_bot;\n"
    "uniform float u_star;\n"
    "uniform float u_time;\n"
    "uniform float u_yaw;\n"
    "uniform float u_pitch;\n"
    "float hash21(vec2 p) {\n"
    "  p = fract(p * vec2(123.34, 456.21));\n"
    "  p += dot(p, p + 45.32);\n"
    "  return fract(p.x * p.y);\n"
    "}\n"
    "void main() {\n"
    "  vec3 col = mix(u_bot, u_top, clamp(v_uv.y, 0.0, 1.0));\n"
    "  if (u_star > 0.5 && v_uv.y > 0.25) {\n"
    "    vec2 grid = floor((v_uv + vec2(u_yaw * 0.16, u_pitch * 0.16)) * vec2(140.0, 80.0));\n"
    "    float h = hash21(grid);\n"
    "    if (h > 0.991) {\n"
    "      float tw = 0.65 + 0.35 * sin(u_time * 3.0 + h * 90.0);\n"
    "      col += vec3(0.85, 0.92, 1.0) * tw * u_star;\n"
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
    "precision highp float;\n"
    "varying vec3 v_pos;\n"
    "varying vec4 v_meta;\n"
    "varying vec4 v_col;\n"
    "uniform vec3 u_cam;\n"
    "uniform vec3 u_fog_col;\n"
    "uniform vec2 u_fog_params;\n"
    "uniform float u_time;\n"
    "uniform vec4 u_flash;\n"
    "void main() {\n"
    "  vec2 uv = v_meta.xy;\n"
    "  float light = v_meta.z;\n"
    "  float kind = v_meta.w;\n"
    "  vec3 base = v_col.rgb;\n"
    "  float e = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));\n"
    "  if (kind < 0.5) {\n"
    "    if (e < 0.055) base *= 0.62;\n"
    "    else if (e < 0.095) base *= 1.12;\n"
    "  } else if (kind < 1.5) {\n"
    "    float d = max(abs(uv.x - 0.5), abs(uv.y - 0.5)) * 2.0;\n"
    "    float ring = fract(d * 3.0 - u_time * 0.45);\n"
    "    if (e < 0.09) {\n"
    "      base = mix(base, vec3(0.95, 0.98, 1.0), 0.38);\n"
    "    } else if (ring < 0.22) {\n"
    "      base = mix(base * 0.35, vec3(0.25, 0.95, 1.0), 0.55);\n"
    "    } else {\n"
    "      base *= (0.35 + 0.55 * (1.0 - d));\n"
    "    }\n"
    "    light = max(light, 0.92);\n"
    "  } else if (kind < 2.5) {\n"
    "    float pulse = 0.85 + 0.22 * sin(u_time * 4.2);\n"
    "    if (e < 0.08) base *= 1.3;\n"
    "    base *= pulse;\n"
    "    light = 1.05;\n"
    "  } else {\n"
    "    if (e < 0.06) base = mix(base, vec3(1.0), 0.35);\n"
    "  }\n"
    "  vec3 lit = clamp(base * light, 0.0, 1.0);\n"
    "  float dist = length(v_pos - u_cam);\n"
    "  float fog_t = clamp((dist - u_fog_params.x) / max(u_fog_params.y, 1.0), 0.0, 0.88);\n"
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
    g_u_sky_yaw = glGetUniformLocation(g_prog_sky, "u_yaw");
    g_u_sky_pitch = glGetUniformLocation(g_prog_sky, "u_pitch");

    g_u_mvp = glGetUniformLocation(g_prog_world, "u_mvp");
    g_u_cam = glGetUniformLocation(g_prog_world, "u_cam");
    g_u_fog_col = glGetUniformLocation(g_prog_world, "u_fog_col");
    g_u_fog_params = glGetUniformLocation(g_prog_world, "u_fog_params");
    g_u_time = glGetUniformLocation(g_prog_world, "u_time");
    g_u_flash = glGetUniformLocation(g_prog_world, "u_flash");

    static const float sky_quad[12] = {
        -1.f, -1.f,  1.f, -1.f,  1.f,  1.f,
        -1.f, -1.f,  1.f,  1.f, -1.f,  1.f
    };
    glGenBuffers(1, &g_vbo_sky);
    glBindBuffer(GL_ARRAY_BUFFER, g_vbo_sky);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sky_quad), sky_quad, GL_STATIC_DRAW);

    glGenBuffers(1, &g_vbo_chunk);
    glGenBuffers(1, &g_vbo_dyn);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    g_gl_ready = 1;
}

static void block_color(uint8_t blk, uint8_t *r, uint8_t *g, uint8_t *b, float *kind) {
    *kind = 0.0f;
    switch (blk) {
        case BLK_WALL_TUT:      *r = 74;  *g = 116; *b = 196; break;
        case BLK_GRASS:         *r = 56;  *g = 178; *b = 76;  break;
        case BLK_DIRT:          *r = 128; *g = 86;  *b = 54;  break;
        case BLK_WOOD:          *r = 112; *g = 72;  *b = 42;  break;
        case BLK_LEAVES:        *r = 42;  *g = 148; *b = 94;  break;
        case BLK_PETAL_Y:       *r = 248; *g = 204; *b = 34;  break;
        case BLK_POLLEN:        *r = 255; *g = 146; *b = 24;  break;
        case BLK_PETAL_W:       *r = 236; *g = 242; *b = 252; break;
        case BLK_MYLANTIS:      *r = 152; *g = 58;  *b = 194; break;
        case BLK_ICE:           *r = 112; *g = 218; *b = 250; *kind = 3.0f; break;
        case BLK_SAND:          *r = 228; *g = 196; *b = 120; break;
        case BLK_GLASS:         *r = 132; *g = 226; *b = 244; *kind = 3.0f; break;
        case BLK_STONE:         *r = 114; *g = 122; *b = 138; break;
        case BLK_GOLD_ORE:      *r = 250; *g = 206; *b = 44;  *kind = 2.0f; break;
        case BLK_CRATE:         *r = 178; *g = 124; *b = 64;  break;
        case BLK_SPAWNER:       *r = 188; *g = 36;  *b = 74;  *kind = 2.0f; break;
        case BLK_LOCKED_DOOR:   *r = 220; *g = 156; *b = 48;  break;

        case BLK_BLACK_CUBE:    *r = 32;  *g = 40;  *b = 64;  *kind = 1.0f; break;
        case BLK_WHITE_FLOWER:  *r = 236; *g = 244; *b = 255; *kind = 1.0f; break;
        case BLK_ALPHA_CUBE:    *r = 96;  *g = 184; *b = 255; *kind = 1.0f; break;
        case BLK_FLOWER_Y_CORE: *r = 255; *g = 216; *b = 46;  *kind = 1.0f; break;
        case BLK_MYLANTIS_M:    *r = 192; *g = 68;  *b = 240; *kind = 1.0f; break;
        case BLK_YING_PLANET:   *r = 58;  *g = 210; *b = 132; *kind = 1.0f; break;
        case BLK_ICE_WORLD:     *r = 104; *g = 224; *b = 255; *kind = 1.0f; break;
        case BLK_DESERT_WORLD:  *r = 242; *g = 192; *b = 98;  *kind = 1.0f; break;
        case BLK_CORE_GATE:     *r = 248; *g = 64;  *b = 188; *kind = 1.0f; break;

        case BLK_BUY_STATION:   *r = 46;  *g = 218; *b = 122; *kind = 2.0f; break;
        case BLK_SELL_STATION:  *r = 250; *g = 198; *b = 42;  *kind = 2.0f; break;
        case BLK_BLACK_MARKET:  *r = 216; *g = 64;  *b = 228; *kind = 2.0f; break;
        case BLK_TOME:          *r = 78;  *g = 196; *b = 255; *kind = 2.0f; break;
        case BLK_UPG_HP:        *r = 244; *g = 68;  *b = 92;  *kind = 2.0f; break;
        case BLK_UPG_REGEN:     *r = 248; *g = 114; *b = 148; *kind = 2.0f; break;
        case BLK_UPG_ARMOR:     *r = 68;  *g = 178; *b = 250; *kind = 2.0f; break;
        case BLK_UPG_DMG:       *r = 252; *g = 116; *b = 42;  *kind = 2.0f; break;
        case BLK_UPG_ROF:       *r = 252; *g = 178; *b = 42;  *kind = 2.0f; break;
        case BLK_UPG_AMMO:      *r = 220; *g = 160; *b = 64;  *kind = 2.0f; break;
        case BLK_UPG_SPEED:     *r = 64;  *g = 240; *b = 216; *kind = 2.0f; break;
        case BLK_KEY_BLOCK:     *r = 255; *g = 228; *b = 72;  *kind = 2.0f; break;
        case BLK_UPG_WEP:       *r = 168; *g = 96;  *b = 255; *kind = 2.0f; break;
        default:                *r = 128; *g = 128; *b = 140; break;
    }
}

static void push_quad(FbwVert *buf, int *cnt, int max_v,
                      float x0, float y0, float z0,
                      float x1, float y1, float z1,
                      float x2, float y2, float z2,
                      float x3, float y3, float z3,
                      float light, float kind, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    if (*cnt + 6 > max_v) return;
    FbwVert v0 = { x0, y0, z0, 0.f, 0.f, light, kind, r, g, b, a };
    FbwVert v1 = { x1, y1, z1, 1.f, 0.f, light, kind, r, g, b, a };
    FbwVert v2 = { x2, y2, z2, 1.f, 1.f, light, kind, r, g, b, a };
    FbwVert v3 = { x3, y3, z3, 0.f, 1.f, light, kind, r, g, b, a };
    buf[(*cnt)++] = v0;
    buf[(*cnt)++] = v1;
    buf[(*cnt)++] = v2;
    buf[(*cnt)++] = v0;
    buf[(*cnt)++] = v2;
    buf[(*cnt)++] = v3;
}

static void emit_cube(FbwVert *buf, int *cnt, int max_v,
                      float cx, float cy, float cz, float hs,
                      uint8_t r, uint8_t g, uint8_t b, uint8_t a, float kind) {
    float x0 = cx - hs, x1 = cx + hs;
    float y0 = cy - hs, y1 = cy + hs;
    float z0 = cz - hs, z1 = cz + hs;
    // +Y, -Y, +X, -X, +Z, -Z (CCW outside)
    push_quad(buf, cnt, max_v, x0,y1,z1, x1,y1,z1, x1,y1,z0, x0,y1,z0, 1.05f, kind, r, g, b, a);
    push_quad(buf, cnt, max_v, x0,y0,z0, x1,y0,z0, x1,y0,z1, x0,y0,z1, 0.62f, kind, r, g, b, a);
    push_quad(buf, cnt, max_v, x1,y0,z1, x1,y0,z0, x1,y1,z0, x1,y1,z1, 0.90f, kind, r, g, b, a);
    push_quad(buf, cnt, max_v, x0,y0,z0, x0,y0,z1, x0,y1,z1, x0,y1,z0, 0.78f, kind, r, g, b, a);
    push_quad(buf, cnt, max_v, x0,y0,z1, x1,y0,z1, x1,y1,z1, x0,y1,z1, 0.96f, kind, r, g, b, a);
    push_quad(buf, cnt, max_v, x1,y0,z0, x0,y0,z0, x0,y1,z0, x1,y1,z0, 0.72f, kind, r, g, b, a);
}

static inline uint8_t chunk_at(int layer, int x, int y, int z) {
    if (x < 0 || x >= 16 || y < 0 || y >= 16 || z < 0 || z >= 16) return BLK_AIR;
    return g_chunks[layer][(y << 8) | (z << 4) | x];
}

static void mesh_layer(int layer, float scale, float ox, float oy, float oz,
                       int hole_x, int hole_y, int hole_z, int skip_hole) {
    int y, z, x;
    for (y = 0; y < CHUNK_DIM; y++) {
        for (z = 0; z < CHUNK_DIM; z++) {
            for (x = 0; x < CHUNK_DIM; x++) {
                uint8_t blk = g_chunks[layer][(y << 8) | (z << 4) | x];
                if (blk == BLK_AIR) continue;
                if (skip_hole && x == hole_x && y == hole_y && z == hole_z) continue;

                uint8_t r, g, b;
                float kind;
                block_color(blk, &r, &g, &b, &kind);

                // Subtle deep-depth darkening matching fbw.goose
                if (g_depth >= 500) {
                    int d256 = 256 - ((g_depth - 500) * 160) / 1500;
                    if (d256 < 96) d256 = 96;
                    r = (uint8_t)((r * d256) >> 8);
                    g = (uint8_t)((g * d256) >> 8);
                    b = (uint8_t)((b * d256) >> 8);
                }

                float wx0 = ox + x * scale;
                float wx1 = wx0 + scale;
                float wy0 = oy + y * scale;
                float wy1 = wy0 + scale;
                float wz0 = oz + z * scale;
                float wz1 = wz0 + scale;

                // +Y
                if (chunk_at(layer, x, y + 1, z) == BLK_AIR)
                    push_quad(g_chunk_verts, &g_chunk_vert_cnt, MAX_CHUNK_VERTS,
                              wx0,wy1,wz1, wx1,wy1,wz1, wx1,wy1,wz0, wx0,wy1,wz0, 1.04f, kind, r, g, b, 255);
                // -Y
                if (chunk_at(layer, x, y - 1, z) == BLK_AIR)
                    push_quad(g_chunk_verts, &g_chunk_vert_cnt, MAX_CHUNK_VERTS,
                              wx0,wy0,wz0, wx1,wy0,wz0, wx1,wy0,wz1, wx0,wy0,wz1, 0.58f, kind, r, g, b, 255);
                // +X
                if (chunk_at(layer, x + 1, y, z) == BLK_AIR)
                    push_quad(g_chunk_verts, &g_chunk_vert_cnt, MAX_CHUNK_VERTS,
                              wx1,wy0,wz1, wx1,wy0,wz0, wx1,wy1,wz0, wx1,wy1,wz1, 0.88f, kind, r, g, b, 255);
                // -X
                if (chunk_at(layer, x - 1, y, z) == BLK_AIR)
                    push_quad(g_chunk_verts, &g_chunk_vert_cnt, MAX_CHUNK_VERTS,
                              wx0,wy0,wz0, wx0,wy0,wz1, wx0,wy1,wz1, wx0,wy1,wz0, 0.74f, kind, r, g, b, 255);
                // +Z
                if (chunk_at(layer, x, y, z + 1) == BLK_AIR)
                    push_quad(g_chunk_verts, &g_chunk_vert_cnt, MAX_CHUNK_VERTS,
                              wx0,wy0,wz1, wx1,wy0,wz1, wx1,wy1,wz1, wx0,wy1,wz1, 0.94f, kind, r, g, b, 255);
                // -Z
                if (chunk_at(layer, x, y, z - 1) == BLK_AIR)
                    push_quad(g_chunk_verts, &g_chunk_vert_cnt, MAX_CHUNK_VERTS,
                              wx1,wy0,wz0, wx0,wy0,wz0, wx0,wy1,wz0, wx1,wy1,wz0, 0.68f, kind, r, g, b, 255);
            }
        }
    }
}

static void rebuild_chunk_meshes(void) {
    g_chunk_vert_cnt = 0;
    // Layer 0 (1x active chunk at [0..16]^3)
    mesh_layer(0, 1.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0, 0);

    // Outward recursive parent scales (16x, 256x, 4096x) centered around current cell
    float acc_ox = 0.0f, acc_oy = 0.0f, acc_oz = 0.0f;
    float pscale = 16.0f;
    int p;
    for (p = 0; p < 3; p++) {
        if (!g_parent_valid[p]) break;
        acc_ox -= (float)g_parent_bx[p] * pscale;
        acc_oy -= (float)g_parent_by[p] * pscale;
        acc_oz -= (float)g_parent_bz[p] * pscale;
        mesh_layer(p + 1, pscale, acc_ox, acc_oy, acc_oz,
                   g_parent_bx[p], g_parent_by[p], g_parent_bz[p], 1);
        pscale *= 16.0f;
    }

    if (g_gl_ready && g_chunk_vert_cnt > 0) {
        glBindBuffer(GL_ARRAY_BUFFER, g_vbo_chunk);
        glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)(g_chunk_vert_cnt * sizeof(FbwVert)),
                     g_chunk_verts, GL_DYNAMIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    g_chunks_dirty = 0;
}

static void emit_ring_3d(float cx, float cy, float cz, float rad, float spin,
                         uint8_t r, uint8_t g, uint8_t b) {
    const int segs = 10;
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
        push_quad(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                  ix0, iy0, cz + 0.08f, x0, y0, cz + 0.08f, x1, y1, cz + 0.08f, ix1, iy1, cz + 0.08f,
                  1.0f, 2.0f, r, g, b, 255);
        push_quad(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                  ix1, iy1, cz - 0.08f, x1, y1, cz - 0.08f, x0, y0, cz - 0.08f, ix0, iy0, cz - 0.08f,
                  0.85f, 2.0f, r, g, b, 255);
    }
}

static void build_dynamic_verts(void) {
    g_dyn_vert_cnt = 0;
    float t = (float)g_anim_ms * 0.001f;
    int i;

    for (i = 0; i < g_ent_cnt; i++) {
        FbwEnt *e = &g_ents[i];
        int k = e->kind;
        if (k >= ENT_RING_GREEN && k <= ENT_RING_PINK) {
            uint8_t r = 48, g = 255, b = 118;
            if (k == ENT_RING_RED)   { r = 255; g = 68;  b = 68;  }
            if (k == ENT_RING_BLUE)  { r = 64;  g = 174; b = 255; }
            if (k == ENT_RING_PINK)  { r = 255; g = 92;  b = 224; }
            emit_ring_3d(e->x, e->y, e->z, 0.56f, t * 2.2f + i * 0.7f, r, g, b);
            continue;
        }

        float hs = (k == ENT_SINGULARITY) ? 0.65f :
                   (k == ENT_GUARDIAN || k == ENT_DEMON) ? 0.44f :
                   (k >= ENT_GOLD) ? 0.22f : 0.34f;
        float bob = (k >= ENT_GOLD) ? sinf(t * 3.5f + i) * 0.12f : 0.0f;
        uint8_t r = 200, g = 200, b = 200;
        float kind = (k >= ENT_GOLD) ? 2.0f : 0.0f;

        if (k == ENT_RAT)         { r = 168; g = 132; b = 92; }
        else if (k == ENT_SPIDER) { r = 128; g = 48;  b = 164; }
        else if (k == ENT_GOON)   { r = 98;  g = 220; b = 74; }
        else if (k == ENT_MARINE) { r = 64;  g = 152; b = 240; }
        else if (k == ENT_PIRATE) { r = 234; g = 88;  b = 62; }
        else if (k == ENT_YINYANG){ r = 235; g = 240; b = 250; }
        else if (k == ENT_MENACE) { r = 245; g = 158; b = 11; }
        else if (k == ENT_DEMON)  { r = 210; g = 32;  b = 68; }
        else if (k == ENT_GUARDIAN){r = 250; g = 204; b = 21; }
        else if (k == ENT_SINGULARITY) { r = 244; g = 63; b = 184; kind = 2.0f; }
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

        // Main body
        emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                  e->x, e->y + bob, e->z, hs, r, g, b, 255, kind);

        // Secondary head/crest silhouette for monsters & Friend K
        if (k >= ENT_RAT && k <= ENT_SINGULARITY) {
            emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                      e->x, e->y + hs * 1.15f, e->z, hs * 0.48f,
                      (uint8_t)(e->freeze_ms > 0 ? 186 : 255),
                      (uint8_t)(e->freeze_ms > 0 ? 250 : 48),
                      (uint8_t)(e->freeze_ms > 0 ? 255 : 64),
                      255, 2.0f);
        } else if (k == ENT_FRIEND_K) {
            emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                      e->x, e->y + bob + hs * 1.35f, e->z, hs * 0.55f,
                      255, 255, 200, 255, 2.0f);
        }
    }

    for (i = 0; i < g_shot_cnt; i++) {
        uint32_t c = g_shots[i].rgb;
        emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                  g_shots[i].x, g_shots[i].y, g_shots[i].z, 0.14f,
                  (uint8_t)((c >> 16) & 0xff), (uint8_t)((c >> 8) & 0xff), (uint8_t)(c & 0xff),
                  255, 2.0f);
    }

    for (i = 0; i < g_part_cnt; i++) {
        uint32_t c = g_parts[i].rgb;
        emit_cube(g_dyn_verts, &g_dyn_vert_cnt, MAX_DYN_VERTS,
                  g_parts[i].x, g_parts[i].y, g_parts[i].z, 0.085f,
                  (uint8_t)((c >> 16) & 0xff), (uint8_t)((c >> 8) & 0xff), (uint8_t)(c & 0xff),
                  255, 2.0f);
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
                      bx, by, bz, 0.07f, br, bg, bb, 255, 2.0f);
        }
    }
}

static void biome_sky_colors(int biome, float *tr, float *tg, float *tb,
                             float *br, float *bg, float *bb) {
    switch (biome) {
        case 0: *tr=0.02f; *tg=0.04f; *tb=0.09f; *br=0.05f; *bg=0.09f; *bb=0.18f; break;
        case 1: *tr=0.08f; *tg=0.19f; *tb=0.39f; *br=0.38f; *bg=0.66f; *bb=0.88f; break;
        case 2: *tr=0.05f; *tg=0.22f; *tb=0.25f; *br=0.22f; *bg=0.58f; *bb=0.50f; break;
        case 3: *tr=0.14f; *tg=0.28f; *tb=0.52f; *br=0.62f; *bg=0.78f; *bb=0.92f; break;
        case 4: *tr=0.28f; *tg=0.20f; *tb=0.06f; *br=0.72f; *bg=0.58f; *bb=0.22f; break;
        case 5: *tr=0.15f; *tg=0.05f; *tb=0.24f; *br=0.45f; *bg=0.16f; *bb=0.54f; break;
        case 6: *tr=0.03f; *tg=0.04f; *tb=0.08f; *br=0.10f; *bg=0.12f; *bb=0.22f; break;
        default:*tr=0.16f; *tg=0.03f; *tb=0.18f; *br=0.40f; *bg=0.09f; *bb=0.34f; break;
    }
    if (g_depth >= 500) {
        float sc = 1.0f - ((float)(g_depth - 500) / 1500.0f) * 0.72f;
        if (sc < 0.28f) sc = 0.28f;
        *tr *= sc; *tg *= sc; *tb *= sc;
        *br *= sc; *bg *= sc; *bb *= sc;
    }
}

static void build_mvp(float *m, float aspect) {
    float cp = cosf(g_pitch), sp = sinf(g_pitch);
    float cy = cosf(g_yaw),   sy = sinf(g_yaw);
    float cr = cosf(g_roll),  sr = sinf(g_roll);

    // Forward, Right, Up matching fbw_core / fbw.goose orthonormal basis
    float fx = cp * cy, fy = sp, fz = cp * sy;
    float rx0 = -sy, rz0 = cy;
    float ux0 = -sp * cy, uy0 = cp, uz0 = -sp * sy;

    float rx = rx0 * cr + ux0 * sr;
    float ry = uy0 * sr;
    float rz = rz0 * cr + uz0 * sr;

    float ux = ux0 * cr - rx0 * sr;
    float uy = uy0 * cr;
    float uz = uz0 * cr - rz0 * sr;

    // Perspective projection matching fov_scale = 0.74
    const float fov_scale = 0.74f;
    const float znear = 0.08f;
    const float zfar  = 1800.0f;
    float f = 1.0f / fov_scale;
    float p00 = f / aspect;
    float p11 = f;
    float p22 = (zfar + znear) / (znear - zfar);
    float p23 = (2.0f * zfar * znear) / (znear - zfar);

    // View matrix (column-major): row0=R, row1=U, row2=-F
    float vx = -(rx * g_cam_x + ry * g_cam_y + rz * g_cam_z);
    float vy = -(ux * g_cam_x + uy * g_cam_y + uz * g_cam_z);
    float vz =  (fx * g_cam_x + fy * g_cam_y + fz * g_cam_z);

    // M = P * V (column-major)
    m[0]  = p00 * rx;  m[1]  = p11 * ux;  m[2]  = p22 * (-fx);  m[3]  = fx;
    m[4]  = p00 * ry;  m[5]  = p11 * uy;  m[6]  = p22 * (-fy);  m[7]  = fy;
    m[8]  = p00 * rz;  m[9]  = p11 * uz;  m[10] = p22 * (-fz);  m[11] = fz;
    m[12] = p00 * vx;  m[13] = p11 * vy;  m[14] = p22 * vz + p23; m[15] = -vz;
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
    if (layer < 0 || layer >= 3) return;
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

FBW_VIS_DEFAULT void fbw_gl_mark_chunks_dirty(void) {
    g_chunks_dirty = 1;
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
    init_gl_resources();
    if (!g_gl_ready) return;

    if (g_chunks_dirty) {
        rebuild_chunk_meshes();
    }
    build_dynamic_verts();

    float tr, tg, tb, br, bg, bb;
    biome_sky_colors(g_biome, &tr, &tg, &tb, &br, &bg, &bb);
    float time_s = (float)g_anim_ms * 0.001f;
    float star = (g_biome == 0 || g_biome == 1 || g_biome == 6 || g_biome == 7) ? 1.0f : 0.0f;

    glViewport(0, 0, g_vp_w, g_vp_h);

    // 1. Sky dome pass (no depth write)
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    glDisable(GL_CULL_FACE);
    glDisable(GL_BLEND);

    glUseProgram(g_prog_sky);
    glUniform3f(g_u_sky_top, tr, tg, tb);
    glUniform3f(g_u_sky_bot, br, bg, bb);
    glUniform1f(g_u_sky_star, star);
    glUniform1f(g_u_sky_time, time_s);
    glUniform1f(g_u_sky_yaw, g_yaw);
    glUniform1f(g_u_sky_pitch, g_pitch);

    glBindBuffer(GL_ARRAY_BUFFER, g_vbo_sky);
    glEnableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDisableVertexAttribArray(2);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, (const void *)0);
    glDrawArrays(GL_TRIANGLES, 0, 6);

    // 2. 3D World + Entities pass
    glEnable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);
    glClear(GL_DEPTH_BUFFER_BIT);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    float mvp[16];
    float aspect = (float)g_vp_w / (float)g_vp_h;
    build_mvp(mvp, aspect);

    float fog_r = br * 0.7f + tr * 0.3f;
    float fog_g = bg * 0.7f + tg * 0.3f;
    float fog_b = bb * 0.7f + tb * 0.3f;
    float fog_scale = (g_parent_valid[0]) ? 3.8f : 1.0f;

    float flash_a = 0.0f;
    if (g_flash_ms > 0) {
        flash_a = (float)g_flash_ms / 460.0f;
        if (flash_a > 0.42f) flash_a = 0.42f;
    }
    float fl_r = (float)((g_flash_rgb >> 16) & 0xff) / 255.0f;
    float fl_g = (float)((g_flash_rgb >> 8) & 0xff) / 255.0f;
    float fl_b = (float)(g_flash_rgb & 0xff) / 255.0f;

    glUseProgram(g_prog_world);
    glUniformMatrix4fv(g_u_mvp, 1, GL_FALSE, mvp);
    glUniform3f(g_u_cam, g_cam_x, g_cam_y, g_cam_z);
    glUniform3f(g_u_fog_col, fog_r, fog_g, fog_b);
    glUniform2f(g_u_fog_params, 9.0f * fog_scale, 36.0f * fog_scale);
    glUniform1f(g_u_time, time_s);
    glUniform4f(g_u_flash, fl_r, fl_g, fl_b, flash_a);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);

    if (g_chunk_vert_cnt > 0) {
        glBindBuffer(GL_ARRAY_BUFFER, g_vbo_chunk);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(FbwVert), (const void *)0);
        glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, sizeof(FbwVert), (const void *)12);
        glVertexAttribPointer(2, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(FbwVert), (const void *)28);
        glDrawArrays(GL_TRIANGLES, 0, g_chunk_vert_cnt);
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

    // 3. Cleanly restore OpenGL state expected by rawdraw CNFGOGL.c
    glDisableVertexAttribArray(2);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    glDisable(GL_CULL_FACE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glUseProgram(0);
}
