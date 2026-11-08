#ifndef CRASH_H
#define CRASH_H
void crash_reporter_init(const char* internal_dir);
int  crash_read(char* out, int cap);
void crash_clear(void);
#endif