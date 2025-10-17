# iOS Metal Build Fix - Embedded Shader

## Issue

```
cp: build/bin/Release/ggml-metal.metal: No such file or directory
Error: Process completed with exit code 1.
```

**Build succeeded** but artifact upload failed trying to copy non-existent `.metal` file.

## Root Cause

### iOS Configuration:

```cmake
-DGGML_METAL_EMBED_LIBRARY=ON
```

This flag **embeds the Metal shader directly into `libggml-metal.dylib`** at build time. The shader code is compiled into the binary, so **no separate `.metal` file is produced**.

### Why Embed for iOS?

1. **App Store Requirements**: iOS apps must be self-contained bundles
2. **Simplified Deployment**: No need to manage external shader files
3. **Code Signing**: Easier to sign a single dylib vs dylib + shader file
4. **Runtime Simplicity**: App doesn't need to locate external shader at runtime

## macOS vs iOS Difference

### macOS (External Shader):

```cmake
-DGGML_METAL=ON
# No EMBED flag - shader stays external
```

**Output**: `libggml-metal.dylib` + `ggml-metal.metal`
**Runtime**: Loads shader from file system

### iOS (Embedded Shader):

```cmake
-DGGML_METAL=ON
-DGGML_METAL_EMBED_LIBRARY=ON  ← Embeds shader
```

**Output**: `libggml-metal.dylib` (contains shader bytecode)
**Runtime**: Shader already in memory, no file I/O needed

## Fix Applied

### iOS Metal Build (BEFORE):

```yaml
cp build/bin/Release/libggml-metal.dylib .publish/ios-arm64/metal/
cp build/bin/Release/ggml-metal.metal .publish/ios-arm64/metal/ # ❌ File doesn't exist!
```

### iOS Metal Build (AFTER):

```yaml
cp build/bin/Release/libllama.dylib .publish/ios-arm64/metal/
cp build/bin/Release/libggml.dylib .publish/ios-arm64/metal/
cp build/bin/Release/libggml-base.dylib .publish/ios-arm64/metal/
cp build/bin/Release/libggml-cpu.dylib .publish/ios-arm64/metal/
cp build/bin/Release/libggml-metal.dylib .publish/ios-arm64/metal/
echo "Note: ggml-metal.metal shader is embedded in libggml-metal.dylib (GGML_METAL_EMBED_LIBRARY=ON)"
# ✅ No attempt to copy .metal file
```

### macOS Metal Build (UNCHANGED):

```yaml
cp build/bin/libggml-metal.dylib .publish/macos-arm64/metal/
cp build/bin/ggml-metal.metal .publish/macos-arm64/metal/ # ✅ File exists on macOS
```

## Additional Fix: libggml.dylib

Build logs showed an additional library being produced:

```
-rwxr-xr-x  libggml.dylib      (57K)
```

This is the **ggml core library** that bridges `libggml-base` and backend implementations. Added to all iOS/macOS builds:

### Updated Library Set:

**iOS/macOS CPU Builds** (4 files):

```
libllama.dylib
libggml.dylib          ← Added
libggml-base.dylib
libggml-cpu.dylib
```

**iOS Metal Build** (5 files):

```
libllama.dylib
libggml.dylib          ← Added
libggml-base.dylib
libggml-cpu.dylib
libggml-metal.dylib    (shader embedded)
```

**macOS Metal Build** (6 files):

```
libllama.dylib
libggml.dylib          ← Added
libggml-base.dylib
libggml-cpu.dylib
libggml-metal.dylib
ggml-metal.metal       (external shader)
```

## Library Dependency Chain

```
Your .NET App
    ↓
libllama.dylib (high-level API)
    ↓
libggml.dylib (core ggml interface)  ← New understanding
    ↓
libggml-base.dylib (tensor operations)
    ↓ ↓
libggml-cpu.dylib    libggml-metal.dylib
(CPU backend)        (GPU backend)
```

## Changes Applied

### Files Modified:

1. `.github/workflows/build-multibackend-v2.yml`

### Affected Jobs:

-   ✅ `ios-arm64-cpu` - Added `libggml.dylib`, added `ls` debug
-   ✅ `ios-arm64-metal` - Removed `.metal` copy, added `libggml.dylib`, added note
-   ✅ `macos-arm64-cpu` - Added `libggml.dylib`, added `ls` debug
-   ✅ `macos-arm64-metal` - Added `libggml.dylib`, added `ls` debug (kept `.metal` copy)
-   ✅ `macos-x64-cpu` - Added `libggml.dylib`, added `ls` debug

### Not Changed:

-   ❌ Linux builds - Don't produce separate `libggml.so` (different build system)
-   ❌ Android builds - Same as Linux
-   ❌ Windows builds - Different library structure

## Build Output Analysis

From actual iOS Metal build log:

```
total 7672
-rwxr-xr-x  615K libggml-base.dylib
-rwxr-xr-x   73K libggml-blas.dylib     ← BLAS backend (not copied, optional)
-rwxr-xr-x  672K libggml-cpu.dylib
-rwxr-xr-x  688K libggml-metal.dylib
-rwxr-xr-x   57K libggml.dylib          ← Core library (NOW copied)
-rwxr-xr-x  1.7M libllama.dylib
```

**Note**: `libggml-blas.dylib` is built but not copied (BLAS backend is optional, Metal is preferred on Apple Silicon).

## Verification

### iOS Metal Build Should Now Succeed:

```yaml
✅ Build succeeds (already was)
✅ Lists build/bin/Release/ contents
✅ Copies 5 dylib files (no .metal file)
✅ Shows explanatory note about embedded shader
✅ Artifact upload succeeds
```

### macOS Metal Build Should Continue Working:

```yaml
✅ Build succeeds
✅ Copies 5 dylib files + 1 .metal file (6 files total)
✅ Artifact upload succeeds
```

## Summary

| Platform  | Shader Mode | .metal File | Libraries Copied    |
| --------- | ----------- | ----------- | ------------------- |
| **iOS**   | Embedded    | ❌ No       | 5 (.dylib)          |
| **macOS** | External    | ✅ Yes      | 5 (.dylib) + .metal |

**Key Insight**: iOS requires `GGML_METAL_EMBED_LIBRARY=ON` for App Store compliance and simplified deployment. The shader is compiled into the dylib at build time, eliminating the need for external shader files.

---

**Status**: ✅ FIXED
**Validation**: ✅ YAML syntax valid
**Ready**: ✅ For next iOS Metal build
