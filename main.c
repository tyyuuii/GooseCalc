// CHANGES: 2025-11-08 Working rawdrawandroid + Goose calculator + crash reporter (fixed)
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>
#include "os_generic.h"
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <android_native_app_glue.h>
#include <android/log.h>
#include <android/sensor.h>
#include <jni.h>
#include "CNFGAndroid.h"
#include "crash.h"
#include "calc_main.h"
#include "fbw_gl.h"

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
#define SFX_COUNT      8
#define SFX_MAX_MS     220
#define SFX_MAX_SAMP   (CLICK_RATE * SFX_MAX_MS / 1000)

static short g_sfx_pcm[SFX_COUNT][SFX_MAX_SAMP];
static int g_sfx_len[SFX_COUNT] = {
    CLICK_RATE * 60 / 1000,   // 0: SFX_CLICK
    CLICK_RATE * 90 / 1000,   // 1: SFX_PLASMA
    CLICK_RATE * 130 / 1000,  // 2: SFX_LASER
    CLICK_RATE * 220 / 1000,  // 3: SFX_EXPLODE
    CLICK_RATE * 200 / 1000,  // 4: SFX_WARP
    CLICK_RATE * 120 / 1000,  // 5: SFX_PICKUP
    CLICK_RATE * 140 / 1000,  // 6: SFX_HURT
    CLICK_RATE * 200 / 1000   // 7: SFX_EMP
};

static short clamp_pcm(double v) {
    if (v > 32000.0) return 32000;
    if (v < -32000.0) return -32000;
    return (short)v;
}

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

    unsigned int rng = 0x13579BDFu;
    double lp = 0.0;
    double ph_plasma = 0.0;
    double ph_laser = 0.0;
    double ph_warp = 0.0;
    double ph_emp = 0.0;

    for (int i = 0; i < SFX_MAX_SAMP; i++) {
        double t = (double)i / CLICK_RATE;
        double att = (i < 44) ? ((double)i / 44.0) : 1.0;

        // 0: SFX_CLICK (60ms tactile 1800 Hz UI click)
        if (i < g_sfx_len[0]) {
            double env = exp(-t * 55.0);
            double s = sin(2.0 * M_PI * 1800.0 * t) * env * att;
            g_sfx_pcm[0][i] = clamp_pcm(s * 12000.0);
        }

        // 1: SFX_PLASMA (90ms swept 980 -> 320 Hz crisp blaster)
        if (i < g_sfx_len[1]) {
            double p = (double)i / (double)g_sfx_len[1];
            double freq = 980.0 - 660.0 * p;
            ph_plasma += 2.0 * M_PI * freq / CLICK_RATE;
            double env = exp(-t * 28.0) * (1.0 - p * 0.25);
            double s = (sin(ph_plasma) + 0.35 * sin(2.0 * ph_plasma)) * env * att;
            g_sfx_pcm[1][i] = clamp_pcm(s * 11500.0);
        }

        // 2: SFX_LASER (130ms resonant swept FM 640 -> 1520 Hz beam)
        if (i < g_sfx_len[2]) {
            double p = (double)i / (double)g_sfx_len[2];
            double freq = 640.0 + 880.0 * p;
            ph_laser += 2.0 * M_PI * freq / CLICK_RATE;
            double mod = sin(2.0 * M_PI * 95.0 * t) * 0.7;
            double env = exp(-t * 16.0);
            double s = sin(ph_laser + mod) * env * att;
            g_sfx_pcm[2][i] = clamp_pcm(s * 12000.0);
        }

        // 3: SFX_EXPLODE (220ms low-pass noise + sub-bass thump)
        rng = rng * 1664525u + 1013904223u;
        double wn = ((double)((int)(rng >> 16) & 0x7FFF) / 16384.0) - 1.0;
        lp = lp * 0.86 + wn * 0.14;
        if (i < g_sfx_len[3]) {
            double p = (double)i / (double)g_sfx_len[3];
            double env = exp(-t * 12.5);
            double sub = sin(2.0 * M_PI * (96.0 - 54.0 * p) * t);
            double s = (lp * 1.45 + sub * 0.65) * env * att;
            g_sfx_pcm[3][i] = clamp_pcm(s * 15000.0);
        }

        // 4: SFX_WARP (200ms fractal scale harmonic 320 -> 960 Hz)
        if (i < g_sfx_len[4]) {
            double p = (double)i / (double)g_sfx_len[4];
            double freq = 320.0 + 640.0 * sin(p * M_PI * 0.85);
            ph_warp += 2.0 * M_PI * freq / CLICK_RATE;
            double env = sin(p * M_PI) * exp(-t * 4.5);
            double s = (sin(ph_warp) + 0.5 * sin(1.5 * ph_warp)) * env * att;
            g_sfx_pcm[4][i] = clamp_pcm(s * 12500.0);
        }

        // 5: SFX_PICKUP (120ms bright dual-tone chime 880 -> 1320 Hz)
        if (i < g_sfx_len[5]) {
            double f = (i < g_sfx_len[5] / 2) ? 880.0 : 1320.0;
            double env = exp(-t * 19.0);
            double s = (sin(2.0 * M_PI * f * t) + 0.3 * sin(4.0 * M_PI * f * t)) * env * att;
            g_sfx_pcm[5][i] = clamp_pcm(s * 11500.0);
        }

        // 6: SFX_HURT (140ms harsh low crunch 190 -> 88 Hz)
        if (i < g_sfx_len[6]) {
            double p = (double)i / (double)g_sfx_len[6];
            double freq = 190.0 - 102.0 * p;
            double w = sin(2.0 * M_PI * freq * t) + 0.6 * lp;
            double env = exp(-t * 17.0);
            double s = tanh(w * 1.8) * env * att;
            g_sfx_pcm[6][i] = clamp_pcm(s * 13500.0);
        }

        // 7: SFX_EMP (200ms shimmering ring-mod zap 520 -> 140 Hz)
        if (i < g_sfx_len[7]) {
            double p = (double)i / (double)g_sfx_len[7];
            double freq = 520.0 - 380.0 * p;
            ph_emp += 2.0 * M_PI * freq / CLICK_RATE;
            double ring = sin(2.0 * M_PI * 46.0 * t);
            double env = exp(-t * 11.0);
            double s = sin(ph_emp) * (0.4 + 0.6 * ring) * env * att;
            g_sfx_pcm[7][i] = clamp_pcm(s * 13000.0);
        }
    }
    g_sound_ready = 1;
}

__attribute__((visibility("default"))) void fbw_sound_fx(int kind) {
    if (!g_sound_ready) return;
    if (kind < 0 || kind >= SFX_COUNT) kind = 0;
    if (g_sl_queue) {
        (*g_sl_queue)->Clear(g_sl_queue);
        (*g_sl_queue)->Enqueue(g_sl_queue, g_sfx_pcm[kind], (SLuint32)(g_sfx_len[kind] * (int)sizeof(short)));
    }
    if (g_sl_play) {
        (*g_sl_play)->SetPlayState(g_sl_play, SL_PLAYSTATE_PLAYING);
    }
}

void sound_click(void) {
    fbw_sound_fx(0);
}

static struct timespec g_boot_ts;
static int g_boot_ts_init = 0;

__attribute__((visibility("default"))) int fbw_now_ms(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    if (!g_boot_ts_init) {
        g_boot_ts = now;
        g_boot_ts_init = 1;
        return 0;
    }
    long sec = (long)(now.tv_sec - g_boot_ts.tv_sec);
    long nsec = (long)(now.tv_nsec - g_boot_ts.tv_nsec);
    return (int)(sec * 1000L + nsec / 1000000L);
}

// Safely switch Android NativeActivity orientation via JNI:
// landscape != 0 -> SCREEN_ORIENTATION_SENSOR_LANDSCAPE (6)
// landscape == 0 -> SCREEN_ORIENTATION_UNSPECIFIED (-1)
__attribute__((visibility("default"))) void fbw_set_orientation(int landscape) {
    if (!gapp || !gapp->activity || !gapp->activity->vm || !gapp->activity->clazz) return;
    JavaVM *vm = gapp->activity->vm;
    JNIEnv *env = NULL;
    int attached = 0;
    jint res = (*vm)->GetEnv(vm, (void **)&env, JNI_VERSION_1_6);
    if (res == JNI_EDETACHED) {
        if ((*vm)->AttachCurrentThread(vm, &env, NULL) != JNI_OK) return;
        attached = 1;
    } else if (res != JNI_OK) {
        return;
    }
    if (env) {
        jclass cls = (*env)->GetObjectClass(env, gapp->activity->clazz);
        if (cls) {
            jmethodID mid = (*env)->GetMethodID(env, cls, "setRequestedOrientation", "(I)V");
            if (mid) {
                jint mode = landscape ? 6 : -1;
                (*env)->CallVoidMethod(env, gapp->activity->clazz, mid, mode);
            }
            (*env)->DeleteLocalRef(env, cls);
        }
        if ((*env)->ExceptionCheck(env)) {
            (*env)->ExceptionClear(env);
        }
    }
    if (attached) {
        (*vm)->DetachCurrentThread(vm);
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
    if( keycode == 4 && bDown ) {
        if (!goose_handle_back()) {
            ANativeActivity_finish(gapp->activity);
        }
    }
}

void HandleButton( int x, int y, int button, int bDown )
{
    if (bDown) {
        sound_click();
        goose_handle_pointer(x, y, button, 1);
    } else {
        goose_handle_pointer(x, y, button, 0);
    }
}

void HandleMotion( int x, int y, int mask )
{
    goose_handle_pointer(x, y, mask, 2);
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

        // ALWAYS drain the ALooper — this delivers APP_CMD_INIT_WINDOW,
        // APP_CMD_RESUME, APP_CMD_STOP, APP_CMD_PAUSE. Skipping it while
        // window == NULL caused the background->foreground freeze: the
        // glue's UI-thread callbacks block waiting for the looper to be
        // drained, and the looper can only be drained by CNFGHandleInput().
        // CNFGHandleInput() is non-blocking (pollOnce timeout 0), so this
        // is safe while backgrounded or during rotation.
        CNFGHandleInput();

        // Render only when the window is actually ready
        if (gapp && gapp->window == NULL) { usleep(10000); continue; }
        if (suspended)                    { usleep(50000); continue; }

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