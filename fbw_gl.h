#ifndef FBW_GL_H
#define FBW_GL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Lifecycle & viewport
void fbw_gl_set_viewport(int w, int h, int depth, int biome, int flash_rgb, int flash_ms);
void fbw_gl_set_camera(int px_mm, int py_mm, int pz_mm,
                       int yaw_mrad, int pitch_mrad, int roll_mrad, int anim_ms);

// Chunk & multi-scale parent synchronization (4 u8 blocks packed per u32)
void fbw_gl_set_parent_meta(int layer, int valid, int bx, int by, int bz, int biome);
void fbw_gl_push_chunk_quad(int layer, int qidx, int packed4);
void fbw_gl_mark_chunks_dirty(void);

// Dynamic per-frame geometry
void fbw_gl_clear_dynamic(void);
void fbw_gl_push_entity(int kind, int x_mm, int y_mm, int z_mm, int hp, int max_hp, int freeze_ms);
void fbw_gl_push_shot(int x_mm, int y_mm, int z_mm, int rgb);
void fbw_gl_push_particle(int x_mm, int y_mm, int z_mm, int rgb);
void fbw_gl_push_beam(int active, int x1_mm, int y1_mm, int z1_mm,
                      int x2_mm, int y2_mm, int z2_mm, int rgb);

// Render 3D scene and cleanly restore GL state for CNFG 2D HUD overlay
void fbw_gl_render_3d(void);

#ifdef __cplusplus
}
#endif

#endif
