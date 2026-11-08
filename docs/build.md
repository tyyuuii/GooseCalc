# Build System

GooseCalc uses GNU Make with the Android NDK to cross-compile a shared library (`.so`) packaged into an APK via rawdrawandroid's build pipeline.

## Prerequisites

| Tool | Source | Purpose |
|------|--------|---------|
| Android NDK | Termux: `/data/data/com.termux/files/usr` | ARM64 cross-compiler (clang) |
| Android SDK | `~/Android/Sdk` | `aapt`, `zipalign`, `apksigner` |
| Goose compiler | `goose` (in PATH) | Compiles `.goose` → `.c` |
| GNU Make | System | Build orchestration |
| `envsubst` | `gettext-base` | Template substitution for `AndroidManifest.xml` |

## Build Command

```bash
make \
  ANDROID_SDK_ROOT=~/Android/Sdk \
  ANDROID_HOME=~/Android/Sdk \
  ANDROID_NDK_HOME=/data/data/com.termux/files/usr \
  NDK=/data/data/com.termux/files/usr \
  BUILD_TOOLS=/data/data/com.termux/files/usr/bin \
  OS_NAME=linux-x86_64 \
  CC_ARM64=/data/data/com.termux/files/usr/bin/aarch64-linux-android-clang \
  ANDROIDVERSION=29 \
  ANDROIDTARGET=29 \
  CFLAGS_ARM64="-target aarch64-linux-android29"
```

## Build Pipeline

```
1. Goose compilation:
   src/calc_main.goose  ──goose──>  calc_main.c  ──clang -c──>  calc_main.o

2. C compilation:
   main.c crash.c  ──clang──>  object files

3. Link:
   all C objects + calc_main.o  ──clang──>  libgoosecalc.so
       (linked into makecapk/lib/arm64-v8a/)

4. APK packaging (rawdrawandroid Makefile):
   libgoosecalc.so + assets + res + AndroidManifest.xml  ──zip──>  makecapk.apk

5. Alignment:
   makecapk.apk  ──zipalign 4──>  goosecalc.apk

6. Signing:
   goosecalc.apk  ──apksigner (v1+v2+v3)──>  signed goosecalc.apk
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make` (default) | Build `goosecalc.apk` |
| `make clean` | Remove all build artifacts |
| `make push` | Push APK to device via ADB |
| `make run` | Build, push, and launch |

## Key Makefile Rules

### Goose compilation
```make
$(GOOSE_C): $(GOOSE_ROOT) src/*.goose
	$(GOOSE) --standalone --header calc_main.h -o $@ $<

$(GOOSE_O): $(GOOSE_C)
	$(CC_ARM64) $(GOOSE_CFLAGS) $(CFLAGS_ARM64) -c $< -o $@
```

### Shared library link (critical override)
```make
$(BUILD_DIR)/makecapk/lib/arm64-v8a/lib$(APPNAME).so : $(ANDROIDSRCS) $(GOOSE_O)
	$(CC_ARM64) $(CFLAGS) $(CFLAGS_ARM64) -o $@ \
		$(filter-out $(GOOSE_C),$(ANDROIDSRCS)) $(GOOSE_O) \
		-L$(NDK)/toolchains/llvm/prebuilt/$(OS_NAME)/sysroot/usr/lib/aarch64-linux-android/$(ANDROIDVERSION) $(LDFLAGS)
```
- Uses `ANDROIDSRCS` (what rawdrawandroid actually compiles), not `SOURCES`
- Links `calc_main.o` with default visibility so Goose exports are visible in the `.so`

### AndroidManifest.xml (envsubst)
```make
VERSIONCODE=$$(cat VERSION | tr -d '.' | sed 's/^0*//') \
    VERSIONNAME=$$(cat VERSION) \
    envsubst '$$VERSIONCODE $$VERSIONNAME $$ANDROIDTARGET $$ANDROIDVERSION $$APPNAME $$PACKAGENAME $$LABEL' \
    < AndroidManifest.xml.template > $(BUILD_DIR)/AndroidManifest.xml
```

## Signing

APK is signed with `apksigner` using `my-release-key.keystore`:
- **v1 scheme** (JAR signing): always enabled
- **v2 scheme** (APK Signature Scheme v2): enabled
- **v3 scheme** (APK Signature Scheme v3): enabled
- Keystore alias: `standkey`
- Store pass / key pass: `password`

⚠️ **Important:** The same keystore must be used for all updates. A different keystore will cause "App not installed" errors when upgrading over an existing installation.

## Output

| Artifact | Path | Description |
|----------|------|-------------|
| Shared library | `makecapk/lib/arm64-v8a/libgoosecalc.so` | Contains all Goose + C symbols |
| Signed APK | `goosecalc.apk` | Installable Android package |
| Versioned APK | `goosecalc-<version>.apk` | Copy with version name for device install |
| Latest APK | `goosecalc-latest.apk` | Copy for easy device install |
| Bundle | `bundle-android.txt` | All source files |

## Verification

```bash
# Verify APK signature
apksigner verify --verbose goosecalc.apk

# Check symbols in packaged .so
unzip -p goosecalc.apk lib/arm64-v8a/libgoosecalc.so > /tmp/lib.so
nm -D /tmp/lib.so | grep " T "

# Check no .o files leaked into APK
unzip -l goosecalc.apk | grep "\.o"

# Verify zip alignment
zipalign -c -v 4 goosecalc.apk
```

## CI/CD

GitHub Actions workflow (`.github/workflows/build.yml`):
- Downloads prebuilt Goose compiler from aardappel/goose releases
- Uses system Android SDK at `/usr/local/lib/android/sdk`
- Vendored rawdrawandroid (no submodules)
- Builds for arm64-v8a / API 29
- Creates GitHub release with APK artifact
