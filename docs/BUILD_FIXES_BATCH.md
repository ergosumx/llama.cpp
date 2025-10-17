# Build Workflow Fixes - Batch Update

## Issues Found

### 1. **Artifacts Only Copying One Library**
**Root Cause**: Using `--target` in cmake build limits what gets built. CMake targets have dependencies, but specifying them explicitly sometimes doesn't trigger all dependency builds properly.

**Solution**: Remove `--target` specification and build ALL targets (default behavior)

### 2. **Silent Failures with `2>/dev/null || true`**
**Root Cause**: Copy commands fail silently, hiding actual problems

**Solution**: Remove error suppression to see real failures

### 3. **Android ARM Architecture Too New**
**Root Cause**: `-march=armv8.7a` is not supported by Android NDK r26d

**Solution**: Use `-march=armv8.2-a+dotprod` (Snapdragon 845+, 2018 devices)

## Changes Applied

### Pattern Changes (All Builds):

**BEFORE:**
```bash
cmake --build build --config Release --target llama ggml-base ggml-cpu -j $(nproc)
cp build/bin/libllama.so .publish/path/ 2>/dev/null || true
cp build/bin/libggml-base.so .publish/path/ 2>/dev/null || true
```

**AFTER:**
```bash
cmake --build build --config Release -j $(nproc)
ls -lh build/bin/  # Verify what was built
cp build/bin/libllama.so .publish/path/
cp build/bin/libggml-base.so .publish/path/
```

### Architecture Fix (Android):

**BEFORE:**
```cmake
-DCMAKE_C_FLAGS="-march=armv8.7a"
```

**AFTER:**
```cmake
-DCMAKE_C_FLAGS="-march=armv8.2-a+dotprod"
```

## Builds Fixed

✅ Linux x64 - CPU
✅ Linux x64 - Vulkan
✅ Linux x64 - OpenCL
✅ Linux ARM64 - CPU
✅ Linux ARM32 - CPU (armhf)
✅ Android ARM64 - CPU (arch fixed)
✅ Android ARM64 - Vulkan (arch fixed)
⏳ iOS ARM64 - CPU (pending)
⏳ iOS ARM64 - Metal (pending)
⏳ Windows x64 - CPU (pending)
⏳ Windows x64 - Vulkan (pending)
⏳ Windows x64 - OpenCL (pending)
⏳ Windows x64 - ROCm (pending)
⏳ Linux x64 - ROCm (pending)
⏳ macOS ARM64 - CPU (pending)
⏳ macOS ARM64 - Metal (pending)
⏳ macOS x64 - CPU (pending)

## Expected Results

Each artifact should now contain:

**CPU-only builds (3 files):**
- libllama.{so|dll|dylib}
- libggml-base.{so|dll|dylib}
- libggml-cpu.{so|dll|dylib}

**GPU builds (4 files):**
- libllama.{so|dll|dylib}
- libggml-base.{so|dll|dylib}
- libggml-cpu.{so|dll|dylib}
- libggml-{vulkan|opencl|metal|hip}.{so|dll|dylib}

**Metal builds (4-5 files):**
- Same as GPU + optional ggml-metal.metal (if not embedded)

## Testing Verification

After fixes, each job log should show:
```
ls -lh build/bin/
-rwxr-xr-x libllama.so
-rwxr-xr-x libggml-base.so  
-rwxr-xr-x libggml-cpu.so
[backend libs if applicable]

ls -lh .publish/platform/backend/
-rwxr-xr-x libllama.so
-rwxr-xr-x libggml-base.so
-rwxr-xr-x libggml-cpu.so
[backend libs if applicable]
```

## Android NDK Architecture Support

| Architecture | Android NDK r26d | Target Devices |
|--------------|------------------|----------------|
| armv8.2-a    | ✅ Supported     | All ARM64 (2017+) |
| armv8.2-a+dotprod | ✅ Supported | Snapdragon 845+ (2018+) |
| armv8.5-a    | ✅ Supported     | Limited (2020+) |
| armv8.7-a    | ❌ **NOT SUPPORTED** | N/A |

**Chosen**: `armv8.2-a+dotprod` - Best balance of performance and compatibility
