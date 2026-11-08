// CHANGES: 2025-11-08 Working rawdrawandroid + Goose calculator + crash reporter (fixed)
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include "os_generic.h"
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <android_native_app_glue.h>
#include <android/log.h>
#include <android/sensor.h>
#include "CNFGAndroid.h"
#include "crash.h"
#include "calc_main.h"

#define CNFG_IMPLEMENTATION
#include "CNFG.h"

volatile int suspended = 0;

extern struct android_app * gapp;

// === Crash reporter state (global so Goose can access) ===
static char g_crash_text[4096];
static int  g_crash_len = 0;
static const char* g_data_path = "";

// === Bridge functions for Goose FFI (must be visible for dynamic linking) ===
__attribute__((visibility("default"))) int get_CNFGPenX(void) { return CNFGPenX; }
__attribute__((visibility("default"))) void set_CNFGPenX(int x) { CNFGPenX = x; }
__attribute__((visibility("default"))) int get_CNFGPenY(void) { return CNFGPenY; }
__attribute__((visibility("default"))) void set_CNFGPenY(int y) { CNFGPenY = y; }
__attribute__((visibility("default"))) int get_android_width(void) { return android_width; }
__attribute__((visibility("default"))) int get_android_height(void) { return android_height; }

__attribute__((visibility("default"))) const char* get_data_path(void) { return g_data_path; }
__attribute__((visibility("default"))) const char* get_crash_text(void) { return g_crash_text; }
__attribute__((visibility("default"))) int get_crash_len(void) { return g_crash_len; }
// Dismisses the crash BANNER only. Must NOT unlink the active log file:
// crash_reporter_init already holds g_fd open on it — unlinking would make a
// later crash this session write to an unlinked inode, silently losing the
// report. Log deletion happens solely via crash_clear() on clean exit.
__attribute__((visibility("default"))) void clear_crash(void) { g_crash_len = 0; g_crash_text[0] = 0; }

// Workaround for Goose f32 FFI bug on ARM64
__attribute__((visibility("default"))) void goose_draw_rect(int x1, int y1, int x2, int y2) {
    CNFGTackRectangle((float)x1, (float)y1, (float)x2, (float)y2);
}

// i32-only text crossing. No pointers, no slices cross the FFI boundary.
// Goose calls: goose_text_clear(); goose_text_append(c); ... ; goose_text_draw(x, y, scale);
// Font: font8x8 (public domain IBM VGA bitmap font), baked at compile time.
// Each set bit renders as a scale×scale filled rectangle. Monospace-free:
// per-glyph advance = rightmost set column + 2 cells (proportional look).
#include "font8x8.h"

// === Click sound via OpenSLES (already linked) ===
#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_Android.h>

static SLObjectItf g_sl_engine_obj = NULL;
static SLObjectItf g_sl_mix_obj = NULL;
static SLObjectItf g_sl_player_obj = NULL;
static SLPlayItf g_sl_play = NULL;
static SLBufferQueueItf g_sl_queue = NULL;
static int g_sound_ready = 0;

#define CLICK_RATE     44100
#define CLICK_MS       60
#define CLICK_SAMPLES  (CLICK_RATE * CLICK_MS / 1000)
static short g_click_pcm[CLICK_SAMPLES];

static void sound_init(void) {
    SLEngineItf engine = NULL;
    SLresult r;

    r = slCreateEngine(&g_sl_engine_obj, 0, NULL, 0, NULL, NULL);
    if (r != SL_RESULT_SUCCESS) return;
    r = (*g_sl_engine_obj)->Realize(g_sl_engine_obj, SL_BOOLEAN_FALSE);
    if (r != SL_RESULT_SUCCESS) return;
    r = (*g_sl_engine_obj)->GetInterface(g_sl_engine_obj, SL_IID_ENGINE, &engine);
    if (r != SL_RESULT_SUCCESS) return;

    r = (*engine)->CreateOutputMix(engine, &g_sl_mix_obj, 0, NULL, NULL);
    if (r != SL_RESULT_SUCCESS) return;
    r = (*g_sl_mix_obj)->Realize(g_sl_mix_obj, SL_BOOLEAN_FALSE);
    if (r != SL_RESULT_SUCCESS) return;

    SLDataLocator_AndroidSimpleBufferQueue loc_bq =
        { SL_DATALOCATOR_ANDROIDSIMPLEBUFFERQUEUE, 2 };
    SLDataFormat_PCM fmt = {
        SL_DATAFORMAT_PCM, 1, SL_SAMPLINGRATE_44_1,
        SL_PCMSAMPLEFORMAT_FIXED_16, SL_PCMSAMPLEFORMAT_FIXED_16,
        SL_SPEAKER_FRONT_CENTER, SL_BYTEORDER_LITTLEENDIAN };
    SLDataSource src = { &loc_bq, &fmt };
    SLDataLocator_OutputMix loc_out = { SL_DATALOCATOR_OUTPUTMIX, g_sl_mix_obj };
    SLDataSink sink = { &loc_out, NULL };
    SLInterfaceID ids[1] = { SL_IID_BUFFERQUEUE };
    SLboolean reqs[1] = { SL_BOOLEAN_TRUE };

    r = (*engine)->CreateAudioPlayer(engine, &g_sl_player_obj, &src, &sink, 1, ids, reqs);
    if (r != SL_RESULT_SUCCESS) return;
    r = (*g_sl_player_obj)->Realize(g_sl_player_obj, SL_BOOLEAN_FALSE);
    if (r != SL_RESULT_SUCCESS) return;
    r = (*g_sl_player_obj)->GetInterface(g_sl_player_obj, SL_IID_PLAY, &g_sl_play);
    if (r != SL_RESULT_SUCCESS) return;
    r = (*g_sl_player_obj)->GetInterface(g_sl_player_obj, SL_IID_BUFFERQUEUE, &g_sl_queue);
    if (r != SL_RESULT_SUCCESS) return;

    // 60ms click: 1800 Hz sine, exponential decay, 1ms attack ramp (no pop)
    for (int i = 0; i < CLICK_SAMPLES; i++) {
        double t = (double)i / CLICK_RATE;
        double env = exp(-t * 55.0);
        double att = (i < 44) ? ((double)i / 44.0) : 1.0;
        double s = sin(2.0 * M_PI * 1800.0 * t) * env * att;
        g_click_pcm[i] = (short)(s * 12000.0);
    }
    g_sound_ready = 1;
}

void sound_click(void) {
    if (!g_sound_ready) return;
    if (g_sl_queue) {
        (*g_sl_queue)->Clear(g_sl_queue);
        (*g_sl_queue)->Enqueue(g_sl_queue, g_click_pcm, sizeof(g_click_pcm));
    }
    if (g_sl_play) {
        (*g_sl_play)->SetPlayState(g_sl_play, SL_PLAYSTATE_PLAYING);
    }
}

// Staging buffer sized for the full crash diagnostic (crash overlay draws up
// to 511 chars; append cap keeps one byte for the terminator).
static char g_text_buf[640];

// Draw one glyph at (x, y) top-left. Returns advance in pixels.
static int draw_char_bmp(int x, int y, int scale, char c) {
    unsigned char ch = (unsigned char)c;
    if (ch > 127) return 3 * scale;             // non-ASCII: skip
    const unsigned char *glyph = font8x8_basic[ch];
    int maxcol = -1;
    for (int row = 0; row < 8; row++) {
        unsigned char bits = glyph[row];
        if (!bits) continue;
        for (int col = 0; col < 8; col++) {
            if ((bits >> col) & 1) {
                if (col > maxcol) maxcol = col;
                CNFGTackRectangle(
                    (short)(x + col * scale), (short)(y + row * scale),
                    (short)(x + (col + 1) * scale), (short)(y + (row + 1) * scale));
            }
        }
    }
    return (maxcol + 2) * scale;                // glyph width + 1 cell gap
}

// Total pixel width of a string at given scale (advances summed).
static int text_width_bmp(const char *s, int scale) {
    int w = 0;
    for (; *s; s++) {
        unsigned char ch = (unsigned char)*s;
        if (ch == '\n') break;                  // width = first line only
        if (ch > 127) { w += 3 * scale; continue; }
        const unsigned char *glyph = font8x8_basic[ch];
        int maxcol = -1;
        for (int row = 0; row < 8; row++) {
            unsigned char bits = glyph[row];
            if (!bits) continue;
            for (int col = 7; col > maxcol; col--) {
                if ((bits >> col) & 1) { maxcol = col; break; }
            }
        }
        w += (maxcol + 2) * scale;
    }
    return w;
}

// Draw a full string starting at (x, y). Handles '\n' (new line, 9 cells tall).
static void draw_text_bmp(int x, int y, int scale, const char *s) {
    int cx = x, cy = y;
    for (; *s; s++) {
        if (*s == '\n') { cx = x; cy += 9 * scale; continue; }
        cx += draw_char_bmp(cx, cy, scale, *s);
    }
}

__attribute__((visibility("default"))) void goose_text_clear(void) {
    g_text_buf[0] = 0;
}

__attribute__((visibility("default"))) void goose_text_append(int c) {
    size_t n = strlen(g_text_buf);
    if (n < 638) {
        g_text_buf[n] = (char)(c & 0xFF);
        g_text_buf[n + 1] = 0;
    }
}

__attribute__((visibility("default"))) void goose_text_draw(int x, int y, int scale) {
    draw_text_bmp(x, y, scale, g_text_buf);
}

// Pixel width of the currently staged text (for Goose-side centering).
__attribute__((visibility("default"))) int goose_text_width(int scale) {
    return text_width_bmp(g_text_buf, scale);
}

int HandleDestroy() { return 0; }
void HandleSuspend() { suspended = 1; }
void HandleResume() {
    if (gapp && gapp->window != NULL) {
        suspended = 0;
        goose_force_resize();
    }
}

void HandleKey( int keycode, int bDown )
{
    if( keycode == 4 ) {
        if (!goose_handle_back()) {
            ANativeActivity_finish(gapp->activity);
        }
    }
}

void HandleButton( int x, int y, int button, int bDown )
{
    if (bDown) {
        sound_click();
        goose_handle_touch(x, y, 1);
    }
}

void HandleMotion( int x, int y, int mask )
{
    // unused - rawdrawandroid calls this but we only use HandleButton
    (void)x; (void)y; (void)mask;
}

int main(int argc, char** argv)
{
    // 1. Read previous crash log FIRST (before crash_reporter_init truncates it)
    if (gapp && gapp->activity) {
        // Use externalDataPath so crash.log is visible in file manager
        const char* ext_path = gapp->activity->externalDataPath;
        if (ext_path && ext_path[0]) {
            g_data_path = ext_path;
        } else {
            g_data_path = gapp->activity->internalDataPath;
        }
        
        // Read existing crash log
        char logpath[256];
        snprintf(logpath, sizeof(logpath), "%s/crash.log", g_data_path);
        int fd = open(logpath, O_RDONLY);
        if (fd >= 0) {
            int n = read(fd, g_crash_text, sizeof(g_crash_text) - 1);
            close(fd);
            if (n > 0) {
                g_crash_text[n] = 0;
                g_crash_len = n;
            }
        }
    }

    // 2. Initialize crash reporter (will truncate log for THIS session)
    crash_reporter_init(g_data_path);

    // 3. Initialize Goose runtime
    goose_init(argc, argv);

    // 4. Setup graphics
    CNFGBGColor = 0x101010FF;
    CNFGSetupFullscreen( "GooseCalc", 0 );

    // Initialize audio (click feedback) — lazy-fail: app runs fine without it
    sound_init();

    // 5. Event/render loop (test.c pattern)
    double ThisTime;
    double LastFPSTime = OGGetAbsoluteTime();
    int frames = 0;
    short screenx, screeny;

    while(1)
    {
        // Exit cleanly when Android requests destroy (prevents crash on exit)
        if (gapp && gapp->destroyRequested) break;
        // Don't render if window not ready (e.g. during rotation)
        if (gapp && gapp->window == NULL) { usleep(10000); continue; }

        CNFGHandleInput();

        if( suspended ) { usleep(50000); continue; }

        CNFGClearFrame();
        CNFGGetDimensions( &screenx, &screeny );

        // Draw Goose calculator
        goose_draw();

        frames++;
        CNFGSwapBuffers();

        ThisTime = OGGetAbsoluteTime();
        if( ThisTime > LastFPSTime + 1 )
        {
            // FPS logging removed - no stdout without ADB
            frames = 0;
            LastFPSTime+=1;
        }
    }

    crash_clear(); // Clear log on clean exit
    goose_exit();
    return(0);
}