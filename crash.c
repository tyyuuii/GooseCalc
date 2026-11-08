#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <ucontext.h>

static int  g_fd = -1;
static char g_logpath[256];

// strlen is not guaranteed async-signal-safe — use a bounded local scan.
static size_t slen(const char* s) { size_t n = 0; while (s[n]) n++; return n; }
static void w(const char* s, size_t n) { if (g_fd >= 0) write(g_fd, s, n); }
static void ws(const char* s) { w(s, slen(s)); }
static void whex(uint64_t v) {
    char b[19]; b[0]='0'; b[1]='x';
    for (int i=0;i<16;i++){int d=(v>>(60-i*4))&0xF;b[2+i]=d<10?'0'+d:'a'+d-10;}
    b[18]='\n'; w(b,19);
}

static void handler(int sig, siginfo_t* info, void* uc_) {
    ucontext_t* uc = (ucontext_t*)uc_;
    ws("signal: ");
    switch (sig) {
        case SIGSEGV: ws("SIGSEGV\n"); break;
        case SIGABRT: ws("SIGABRT\n"); break;
        case SIGBUS:  ws("SIGBUS\n");  break;
        case SIGFPE:  ws("SIGFPE\n");  break;
        case SIGILL:  ws("SIGILL\n");  break;
        default:      ws("UNKNOWN\n"); break;
    }
    ws("fault: "); whex((uint64_t)info->si_addr);
    ws("pc:    "); whex((uint64_t)uc->uc_mcontext.pc);
    ws("lr:    "); whex((uint64_t)uc->uc_mcontext.regs[30]);
    ws("sp:    "); whex((uint64_t)uc->uc_mcontext.sp);
    signal(sig, SIG_DFL);
    raise(sig);
}

void crash_reporter_init(const char* internal_dir) {
    if (!internal_dir || !internal_dir[0]) return;

    snprintf(g_logpath, sizeof g_logpath, "%s/crash.log", internal_dir);
    g_fd = open(g_logpath, O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (g_fd < 0) return;

    // Write startup marker
    ws("=== goosecalc startup ===\n");
    ws("path: "); ws(internal_dir); ws("\n");

    struct sigaction sa = {0};
    sa.sa_sigaction = handler;
    sa.sa_flags = SA_SIGINFO | SA_RESETHAND;
    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGABRT, &sa, NULL);
    sigaction(SIGBUS,  &sa, NULL);
    sigaction(SIGFPE,  &sa, NULL);
    sigaction(SIGILL,  &sa, NULL);
}

// Returns length of crash log, or 0 if none. Reads into caller's buffer.
int crash_read(char* out, int cap) {
    if (cap <= 1) return 0;               // guard: cap - 1 would underflow
    if (!out) return 0;
    if (!g_logpath[0]) return 0;
    int fd = open(g_logpath, O_RDONLY);
    if (fd < 0) return 0;
    int n = read(fd, out, cap - 1);
    close(fd);
    if (n <= 0) { unlink(g_logpath); return 0; }
    out[n] = 0;
    return n;
}

// Called ONLY on clean exit (main loop end). Removes this session's
// startup-marker-only log so the next launch does not show a false crash.
// Never call this to dismiss the crash banner — that must keep the active
// log intact so a later crash this session is still recorded.
void crash_clear(void) {
    if (g_logpath[0]) unlink(g_logpath);
}