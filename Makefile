APPNAME=goosecalc
RAWDRAWANDROID=rawdrawandroid
CFLAGS:=-I. -ffunction-sections -Os -fvisibility=hidden -Isrc
GOOSE_CFLAGS:=-I. -ffunction-sections -Os -Isrc
LDFLAGS:=-Wl,--build-id
PACKAGENAME?=com.goosecalc.app
SRC:=main.c crash.c

ANDROIDVERSION?=29
ANDROIDTARGET?=29
MINSDKVERSION?=23

TARGETS:=makecapk/lib/arm64-v8a/lib$(APPNAME).so

# NDK/SDK paths come from environment (Termux: ANDROID_NDK_HOME/ANDROID_HOME;
# GitHub Actions: set via workflow env). rawdrawandroid/Makefile detects them
# with ?= so environment values take precedence.
include rawdrawandroid/Makefile

# Override AFTER include — allow env/make override for the clang path
CC_ARM64 ?= $(NDK)/toolchains/llvm/prebuilt/$(OS_NAME)/bin/aarch64-linux-android$(ANDROIDVERSION)-clang

# Goose compilation - compile with default visibility so exports are visible
GOOSE ?= goose
GOOSE_ROOT := src/calc_main.goose
GOOSE_C := calc_main.c
GOOSE_O := $(BUILD_DIR)/makecapk/lib/arm64-v8a/calc_main.o

$(GOOSE_C): $(GOOSE_ROOT) src/*.goose
	$(GOOSE) --standalone --header calc_main.h -o $@ $<

$(GOOSE_O): $(GOOSE_C)
	mkdir -p $(BUILD_DIR)/makecapk/lib/arm64-v8a
	$(CC_ARM64) $(GOOSE_CFLAGS) $(CFLAGS_ARM64) -c $< -o $@

# Override arm64 build to include Goose object with default visibility
# CRITICAL: Use ANDROIDSRCS (what rawdrawandroid actually compiles), not SOURCES
$(BUILD_DIR)/makecapk/lib/arm64-v8a/lib$(APPNAME).so : $(ANDROIDSRCS) $(GOOSE_O)
	mkdir -p $(BUILD_DIR)/makecapk/lib/arm64-v8a
	$(CC_ARM64) $(CFLAGS) $(CFLAGS_ARM64) -o $@ $(filter-out $(GOOSE_C),$(ANDROIDSRCS)) $(GOOSE_O) -L$(NDK)/toolchains/llvm/prebuilt/$(OS_NAME)/sysroot/usr/lib/aarch64-linux-android/$(ANDROIDVERSION) $(LDFLAGS)
