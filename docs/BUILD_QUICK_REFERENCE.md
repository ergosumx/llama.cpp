# Quick Reference: Build System Changes

## What Changed?

### ❌ Removed

-   **macOS Vulkan Support** - MoltenVK adds complexity, use Metal instead

### ✅ Added (3 new build jobs)

1. **Linux ARM32 CPU** - Embedded devices (Raspberry Pi, BeagleBone)
2. **Android ARM64 CPU** - Mobile devices without GPU
3. **Android ARM64 Vulkan** - Mobile devices with GPU acceleration

## Build Matrix (13 Total Jobs)

```
Linux:
  ├── x64
  │   ├── CPU ✓
  │   ├── Vulkan ✓
  │   └── OpenCL ✓
  ├── ARM64
  │   └── CPU ✓
  └── ARM32 (NEW) ⭐
      └── CPU ✓

Android (NEW): ⭐
  └── ARM64
      ├── CPU ✓
      └── Vulkan ✓

Windows:
  └── x64
      ├── CPU ✓
      ├── Vulkan ✓
      └── OpenCL ✓

macOS:
  ├── ARM64
  │   ├── CPU ✓
  │   └── Metal ✓
  └── x64
      └── CPU ✓
```

## Viability Assessment

### Linux ARM32 - ✅ VIABLE

-   **Architecture**: ARMv7-A with NEON
-   **Target**: Raspberry Pi 2/3/4, embedded devices
-   **Performance**: 2-5 tokens/sec (small models)
-   **Memory**: Suitable for 1-3B models
-   **Use Cases**: Edge AI, IoT, embedded systems

### Android ARM64 CPU - ✅ VIABLE

-   **Architecture**: ARM64-v8a
-   **Target**: All modern Android devices (API 28+)
-   **Performance**: 5-10 tokens/sec (mid-range devices)
-   **Memory**: Suitable for 1-7B models
-   **Use Cases**: Mobile apps, CPU fallback

### Android ARM64 Vulkan - ✅ HIGHLY VIABLE

-   **Architecture**: ARM64-v8a with GPU
-   **Target**: Android 9.0+ with Vulkan support
-   **Performance**: 15-30 tokens/sec (flagship devices)
-   **Memory**: Suitable for 1-13B models
-   **Use Cases**: High-performance mobile AI
-   **Note**: Vulkan is part of Android NDK, no separate SDK needed

## Key Technical Decisions

### Why ARM32?

-   Large installed base of embedded devices
-   NEON SIMD provides good performance
-   Low-cost hardware (Raspberry Pi ~$35-75)
-   Perfect for edge AI applications

### Why Android?

-   Massive mobile market (3+ billion devices)
-   Native Vulkan support (no translation layer)
-   Modern devices have capable GPUs
-   Growing demand for on-device AI

### Why NOT macOS Vulkan?

-   Requires MoltenVK (Vulkan→Metal translation)
-   Native Metal backend is faster
-   Additional complexity for marginal benefit
-   Apple recommends Metal for GPU work

## CMake Configuration Quick Reference

### Linux ARM32

```cmake
-DCMAKE_SYSTEM_PROCESSOR=arm
-DGGML_CPU_ARM_ARCH=armv7-a
-DCMAKE_C_FLAGS="-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -Os"
```

### Android (both CPU and Vulkan)

```cmake
-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake
-DANDROID_ABI=arm64-v8a
-DANDROID_PLATFORM=android-28
-DGGML_OPENMP=OFF
-DGGML_LLAMAFILE=OFF
```

Add for Vulkan:

```cmake
-DGGML_VULKAN=ON
```

## Artifacts Generated

| Platform       | Files                                              | Size (approx) |
| -------------- | -------------------------------------------------- | ------------- |
| Linux ARM32    | `libllama.so`, `libggml-base.so`, `libggml-cpu.so` | ~5 MB         |
| Android CPU    | `libllama.so`, `libggml-base.so`, `libggml-cpu.so` | ~12 MB        |
| Android Vulkan | Above + `libggml-vulkan.so`                        | ~20 MB        |

## Testing Commands

### Linux ARM32 (on Raspberry Pi)

```bash
file libllama.so  # Should show: ARM, hard-float ABI
ldd libllama.so   # Check dependencies
```

### Android

```bash
# Check ABI
file libllama.so  # Should show: ARM aarch64

# Deploy and test
adb push *.so /data/local/tmp/llama/
adb shell "cd /data/local/tmp/llama && export LD_LIBRARY_PATH=. && ./your_test"

# Check Vulkan support
adb shell getprop ro.hardware.vulkan
```

## Performance Expectations

### TinyLlama 1.1B (Q4_K_M) - Tokens/Second

| Platform    | Backend | Performance | Device Example      |
| ----------- | ------- | ----------- | ------------------- |
| Linux ARM32 | CPU     | 2-5         | Raspberry Pi 4      |
| Android     | CPU     | 5-10        | Pixel 6, Galaxy S21 |
| Android     | Vulkan  | 15-30       | Pixel 8, Galaxy S24 |

### Llama 2 7B (Q4_K_M) - Tokens/Second

| Platform    | Backend | Performance | Device Example          |
| ----------- | ------- | ----------- | ----------------------- |
| Linux ARM32 | CPU     | 0.5-1 ⚠️    | Marginal on 4GB devices |
| Android     | CPU     | 2-5         | High-end devices only   |
| Android     | Vulkan  | 5-15        | Flagship 2023+          |

⚠️ = Not recommended due to performance constraints

## Deployment Checklist

### Linux ARM32

-   [ ] Cross-compile with `arm-linux-gnueabihf` toolchain
-   [ ] Verify hard-float ABI
-   [ ] Test NEON instructions availability
-   [ ] Check glibc version compatibility
-   [ ] Test on target hardware

### Android CPU

-   [ ] Build with Android NDK r26d+
-   [ ] Set minimum API level to 28
-   [ ] Disable OpenMP and llamafile
-   [ ] Strip symbols for smaller size
-   [ ] Test on emulator and real device

### Android Vulkan

-   [ ] All Android CPU checklist items
-   [ ] Verify Vulkan headers in NDK
-   [ ] Test on Vulkan-capable device
-   [ ] Implement CPU fallback
-   [ ] Check GPU memory limits

## Common Issues & Solutions

### ARM32: "Illegal instruction"

-   **Cause**: Target device doesn't support NEON or hard-float
-   **Solution**: Use older ARMv6 flags or soft-float ABI

### Android: "Library not found"

-   **Cause**: Missing `LD_LIBRARY_PATH` or wrong ABI
-   **Solution**: Set `LD_LIBRARY_PATH=.` and verify arm64-v8a

### Android Vulkan: Slower than CPU

-   **Cause**: Old GPU drivers or incompatible device
-   **Solution**: Update drivers or fall back to CPU backend

## Files Modified

```
✅ .github/workflows/build-multibackend-v2.yml
   - Added linux-arm32-cpu job
   - Added android-arm64-cpu job
   - Added android-arm64-vulkan job

✅ docs/ARM32_RESEARCH.md (NEW)
   - Comprehensive research on ARM32 and Android viability

✅ docs/BUILD_UPDATES_ARM32_ANDROID.md (NEW)
   - Detailed documentation of changes

✅ docs/BUILD_QUICK_REFERENCE.md (THIS FILE)
   - Quick reference guide

❌ .github/actions/macos-setup-vulkan/ (REMOVED)
   - Not needed, macOS uses Metal
```

## Next Actions

1. **Push Changes**: Commit and push to trigger CI/CD
2. **Monitor Builds**: Check GitHub Actions for all 13 jobs
3. **Download Artifacts**: Test libraries on target platforms
4. **Update Documentation**: Add platform support to README
5. **NuGet Package**: Include new runtimes in package

## Support Matrix

| Platform    | Min OS Version | Min Hardware | GPU Support |
| ----------- | -------------- | ------------ | ----------- |
| Linux ARM32 | Ubuntu 20.04   | ARMv7 + NEON | ❌ CPU only |
| Android     | 9.0 (API 28)   | ARM64        | ✅ Vulkan   |

## Estimated Build Times

-   **First Run**: ~2 hours (NDK download + all builds)
-   **With Caching**: ~45-60 minutes
-   **Single Platform**: ~10-20 minutes per job

## Documentation Links

-   Full Research: `docs/ARM32_RESEARCH.md`
-   Detailed Updates: `docs/BUILD_UPDATES_ARM32_ANDROID.md`
-   Workflow File: `.github/workflows/build-multibackend-v2.yml`
-   Android NDK: https://github.com/nttld/setup-ndk
-   llama.cpp Android: `docs/android.md`
