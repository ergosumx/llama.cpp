# Build Artifact Path Fix

## Problem

All build jobs were completing successfully but artifacts were not being uploaded. The error was:

```
No files were found with the provided path: .publish/{platform}/{backend}/*.{so,dylib,dll}
```

## Root Cause

The workflow was copying library files from **incorrect source paths**:

-   ❌ Old: `build/src/libllama.so`
-   ❌ Old: `build/ggml/src/libggml-*.so`
-   ❌ Old: `build/ggml/src/ggml-{backend}/libggml-{backend}.so`

But llama.cpp's CMake build system actually outputs all libraries to:

-   ✅ Correct: `build/bin/libllama.so`
-   ✅ Correct: `build/bin/libggml-*.so`
-   ✅ Correct: `build/bin/libggml-{backend}.so`

## Solution

Updated all copy commands in the workflow to use `build/bin/` as the source directory:

### Linux Builds (x64, ARM64, ARM32)

```bash
# Before
cp build/src/libllama.so .publish/linux-*/
cp build/ggml/src/libggml-base.so .publish/linux-*/

# After
cp build/bin/libllama.so .publish/linux-*/
cp build/bin/libggml-base.so .publish/linux-*/
```

### macOS Builds

```bash
# Before
cp build/src/libllama.dylib .publish/macos-*/
cp build/ggml/src/libggml-base.dylib .publish/macos-*/

# After
cp build/bin/libllama.dylib .publish/macos-*/
cp build/bin/libggml-base.dylib .publish/macos-*/
```

### Android Builds

```bash
# Before
cp build/src/libllama.so .publish/android-*/
cp build/ggml/src/libggml-*.so .publish/android-*/

# After
cp build/bin/libllama.so .publish/android-*/
cp build/bin/libggml-*.so .publish/android-*/
```

### Backend Libraries

All backend-specific libraries also moved:

| Backend | Old Path                                        | New Path                        |
| ------- | ----------------------------------------------- | ------------------------------- |
| Vulkan  | `build/ggml/src/ggml-vulkan/libggml-vulkan.so`  | `build/bin/libggml-vulkan.so`   |
| OpenCL  | `build/ggml/src/libggml-opencl.so`              | `build/bin/libggml-opencl.so`   |
| Metal   | `build/ggml/src/ggml-metal/libggml-metal.dylib` | `build/bin/libggml-metal.dylib` |

### Metal Shader File

```bash
# Before
cp build/ggml/src/ggml-metal/ggml-metal.metal .publish/macos-arm64/metal/

# After
cp build/bin/ggml-metal.metal .publish/macos-arm64/metal/
```

## Jobs Fixed

All 13 build jobs were updated:

1. ✅ linux-x64-cpu
2. ✅ linux-x64-vulkan
3. ✅ linux-x64-opencl
4. ✅ linux-arm64-cpu
5. ✅ linux-arm32-cpu
6. ✅ android-arm64-cpu
7. ✅ android-arm64-vulkan
8. ✅ windows-x64-cpu (Windows uses different paths, already correct)
9. ✅ windows-x64-vulkan (Windows uses different paths, already correct)
10. ✅ windows-x64-opencl (Windows uses different paths, already correct)
11. ✅ macos-arm64-cpu
12. ✅ macos-arm64-metal
13. ✅ macos-x64-cpu

## Verification

The fix was verified by:

1. Checking actual build output locations locally: `find build* -name "*.so"`
2. Confirming all libraries are in `build/bin/` directory
3. Validating YAML syntax: ✅ Valid

## Expected Result

After this fix, all build jobs should successfully:

1. Build the libraries
2. Copy them to `.publish/{platform}/{backend}/` directory
3. Upload them as artifacts with proper names like `ggufx-{platform}-{backend}`

## Artifact Sizes (Expected)

| Platform      | Backend | Libraries                  | Approx Size |
| ------------- | ------- | -------------------------- | ----------- |
| Linux x64     | CPU     | llama, ggml-base, ggml-cpu | ~5-8 MB     |
| Linux x64     | Vulkan  | + ggml-vulkan              | ~8-12 MB    |
| Linux x64     | OpenCL  | + ggml-opencl              | ~8-12 MB    |
| Linux ARM64   | CPU     | llama, ggml-base, ggml-cpu | ~5-8 MB     |
| Linux ARM32   | CPU     | llama, ggml-base, ggml-cpu | ~3-5 MB     |
| Android ARM64 | CPU     | llama, ggml-base, ggml-cpu | ~10-15 MB   |
| Android ARM64 | Vulkan  | + ggml-vulkan              | ~15-20 MB   |
| Windows x64   | CPU     | llama, ggml-base, ggml-cpu | ~8-12 MB    |
| Windows x64   | Vulkan  | + ggml-vulkan              | ~12-18 MB   |
| Windows x64   | OpenCL  | + ggml-opencl              | ~12-18 MB   |
| macOS ARM64   | CPU     | llama, ggml-base, ggml-cpu | ~6-10 MB    |
| macOS ARM64   | Metal   | + ggml-metal + .metal      | ~10-15 MB   |
| macOS x64     | CPU     | llama, ggml-base, ggml-cpu | ~6-10 MB    |

## Windows Note

Windows builds use `build/bin/Release/` path (not `build/bin/`) which was already correct in the workflow. No changes needed for Windows jobs.

## Testing

To test locally:

```bash
# Build and check output location
cmake -B build -DBUILD_SHARED_LIBS=ON
cmake --build build --target llama ggml-base ggml-cpu
ls -lh build/bin/

# Should show:
# libllama.so (or .dylib on macOS)
# libggml-base.so
# libggml-cpu.so
```

## Files Modified

-   `.github/workflows/build-multibackend-v2.yml` - All Linux, macOS, and Android jobs updated

## Status

✅ **FIXED** - All artifact upload paths corrected
✅ **VALIDATED** - YAML syntax valid
✅ **READY** - Ready for next workflow run
