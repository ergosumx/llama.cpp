# ARM32 and Android Build Research for llama.cpp

## Executive Summary

### ARM32 (ARMv7) Support - ✅ VIABLE AND FEASIBLE

**Conclusion**: llama.cpp fully supports ARM32 (ARMv7) embedded devices with optimized NEON acceleration.

**Key Findings**:

-   ARMv7-A with NEON is fully supported and tested
-   Official documentation exists for cross-compilation
-   Used successfully on Raspberry Pi 2/3/4, BeagleBone, and other embedded devices
-   Performance optimizations available via NEON SIMD instructions
-   Hard-float ABI (armhf) recommended for best performance

**Recommended Configuration**:

```cmake
-DCMAKE_SYSTEM_PROCESSOR=arm
-DGGML_CPU_ARM_ARCH=armv7-a
-DCMAKE_C_FLAGS="-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -Os"
-DCMAKE_CXX_FLAGS="-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -Os"
```

**Toolchain**: `arm-linux-gnueabihf-gcc` / `arm-linux-gnueabihf-g++`

### Android ARM64 + Vulkan - ✅ VIABLE AND FEASIBLE

**Conclusion**: Android supports both ARM64 builds and Vulkan GPU acceleration.

**Key Findings**:

-   Android NDK officially supported by llama.cpp
-   ARM64-v8a is the primary target architecture
-   Vulkan support available on Android API 28+ (Android 9.0+)
-   Official documentation in `docs/android.md`
-   Most modern Android devices (2018+) support Vulkan

**Recommended Configuration for Android + Vulkan**:

```cmake
-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake
-DANDROID_ABI=arm64-v8a
-DANDROID_PLATFORM=android-28  # Or higher for better Vulkan support
-DGGML_VULKAN=ON
-DCMAKE_C_FLAGS="-march=armv8.7a"
-DCMAKE_CXX_FLAGS="-march=armv8.7a"
-DGGML_OPENMP=OFF
-DGGML_LLAMAFILE=OFF
```

**Vulkan SDK for Android**: The Vulkan SDK includes Android support, and Vulkan headers/libraries are part of the Android NDK.

### macOS Vulkan - ❌ NOT RECOMMENDED (MoltenVK Complications)

**Conclusion**: Vulkan on macOS requires MoltenVK (Vulkan-to-Metal translation layer) which adds complexity and potential performance overhead.

**Reasons for Exclusion**:

-   macOS uses Metal as native GPU API, not Vulkan
-   MoltenVK translation layer adds overhead and complexity
-   Metal backend (`GGML_METAL=ON`) is the recommended path for macOS
-   Native Metal support provides better performance and integration
-   Apple Silicon optimized via ARM NEON and Accelerate framework

**Recommended for macOS**: Use Metal backend instead

```cmake
-DGGML_METAL=ON  # Native Apple GPU acceleration
```

## Detailed Technical Analysis

### 1. ARM32 (ARMv7) for Embedded Linux

#### Hardware Targets

-   **Raspberry Pi**: Models 2, 3, 4 (32-bit OS)
-   **BeagleBone**: Black, AI, X15
-   **Embedded SBCs**: ODROID, NanoPi, Orange Pi
-   **Industrial**: Various ARM Cortex-A7/A9/A15 based systems

#### Performance Characteristics

-   **NEON SIMD**: Essential for performance (4x-8x speedup)
-   **Memory**: Minimum 1GB RAM, 2GB+ recommended
-   **Model Size**: Suitable for quantized models (Q4_0, Q4_K_M)
-   **Inference Speed**:
    -   Small models (1B-3B): 2-10 tokens/sec
    -   Medium models (7B): 0.5-2 tokens/sec (with heavy quantization)

#### Build Optimizations

-   Use `-Os` for size optimization (embedded storage constraints)
-   Enable NEON via `-mfpu=neon-vfpv4`
-   Hard-float ABI for better performance
-   Static linking or careful .so management for deployment

#### Limitations

-   32-bit address space limits model size
-   No GPU acceleration available (CPU only)
-   Lower performance compared to ARM64
-   Legacy architecture (most new devices are ARM64)

### 2. Android ARM64 with Vulkan

#### Device Compatibility

-   **Android Version**: 9.0+ (API 28+) for stable Vulkan support
-   **Architecture**: ARM64-v8a (all modern Android devices)
-   **GPU Support**: Most Qualcomm, Mali, Adreno GPUs from 2018+

#### Vulkan Implementation

Android's Vulkan support is native and well-integrated:

-   Part of Android NDK (no separate SDK needed)
-   Hardware abstraction via Vulkan drivers
-   Good performance on mobile GPUs
-   Lower power consumption than OpenCL

#### Build Approach

Two methods available:

1. **Cross-compilation** (recommended for CI/CD):

    - Use Android NDK on Linux host
    - Full control over build configuration
    - Suitable for automated builds

2. **Native compilation** (Termux):
    - Build directly on Android device
    - Easier for development/testing
    - Slower build times

#### Android-Specific Considerations

-   **OpenMP**: Not fully supported, set `-DGGML_OPENMP=OFF`
-   **llamafile**: Not compatible with Android
-   **Storage**: Use `/data/local/tmp/` or app-specific directories
-   **ADB**: Required for deployment and testing
-   **Permissions**: May need storage permissions for model files

#### Performance Expectations

With Vulkan on modern Android devices:

-   **Small models** (1B-3B): 5-20 tokens/sec
-   **Medium models** (7B): 2-8 tokens/sec
-   **Large models** (13B+): 0.5-3 tokens/sec (with quantization)

### 3. Cross-Platform Build Strategy

#### Recommended Build Matrix

| Platform | Architecture | Backend    | Viability | Priority   |
| -------- | ------------ | ---------- | --------- | ---------- |
| Linux    | x64          | CPU        | ✅ High   | High       |
| Linux    | x64          | Vulkan     | ✅ High   | High       |
| Linux    | x64          | OpenCL     | ✅ High   | Medium     |
| Linux    | ARM64        | CPU        | ✅ High   | High       |
| Linux    | **ARM32**    | CPU        | ✅ Medium | **Medium** |
| Android  | ARM64        | CPU        | ✅ High   | High       |
| Android  | **ARM64**    | **Vulkan** | ✅ High   | **High**   |
| Windows  | x64          | CPU        | ✅ High   | High       |
| Windows  | x64          | Vulkan     | ✅ High   | High       |
| Windows  | x64          | OpenCL     | ✅ High   | Medium     |
| macOS    | ARM64        | CPU        | ✅ High   | High       |
| macOS    | ARM64        | Metal      | ✅ High   | High       |
| macOS    | x64          | CPU        | ✅ Medium | Low        |
| macOS    | ~~Vulkan~~   | ~~Vulkan~~ | ❌ Low    | **None**   |

## Implementation Recommendations

### GitHub Actions Workflow Changes

1. **Remove macOS Vulkan**:

    - Delete `macos-*-vulkan` jobs
    - Keep `macos-*-metal` for GPU acceleration
    - Simplifies build matrix

2. **Add Linux ARM32**:

    - New job: `linux-arm32-cpu`
    - Use Ubuntu 22.04 with cross-compilation toolchain
    - Target embedded devices and legacy hardware

3. **Add Android ARM64 + Vulkan**:
    - New job: `android-arm64-cpu`
    - New job: `android-arm64-vulkan`
    - Use Android NDK 25 or later
    - No separate Vulkan SDK needed (included in NDK)

### Toolchain Requirements

#### Linux ARM32

```bash
sudo apt-get install -y \
  gcc-arm-linux-gnueabihf \
  g++-arm-linux-gnueabihf \
  binutils-arm-linux-gnueabihf
```

#### Android NDK

```bash
# NDK is typically installed via GitHub Actions android-ndk action
# Or download from: https://developer.android.com/ndk/downloads
export ANDROID_NDK=/path/to/ndk
export ANDROID_NDK_VERSION=25.2.9519653  # Or latest
```

## Performance Comparison

### Inference Speed (tokens/second) - TinyLlama 1.1B Q4_K_M

| Platform                | Backend    | ~Speed    | Notes              |
| ----------------------- | ---------- | --------- | ------------------ |
| Linux x64 (Modern CPU)  | CPU        | 15-25     | AVX2/AVX512        |
| Linux x64 (Modern GPU)  | Vulkan     | 30-60     | Dedicated GPU      |
| Linux ARM64 (Server)    | CPU        | 10-20     | AWS Graviton       |
| **Linux ARM32 (RPi 4)** | **CPU**    | **2-5**   | **NEON optimized** |
| **Android (Flagship)**  | **Vulkan** | **15-30** | **2023+ devices**  |
| Android (Mid-range)     | CPU        | 5-10      | 2020+ devices      |
| macOS M1/M2             | Metal      | 40-80     | Apple Silicon      |

### Memory Requirements

| Model Size | Quantization | RAM Required | ARM32 Viable?             |
| ---------- | ------------ | ------------ | ------------------------- |
| 1B         | Q4_K_M       | ~1 GB        | ✅ Yes                    |
| 3B         | Q4_K_M       | ~2.5 GB      | ✅ Yes (2GB+ devices)     |
| 7B         | Q4_K_M       | ~5 GB        | ⚠️ Marginal (swap needed) |
| 13B        | Q4_K_M       | ~9 GB        | ❌ No (32-bit limit)      |

## Security and Compatibility Considerations

### ARM32 Security

-   ✅ Active security updates for embedded Linux distros
-   ⚠️ Ensure recent toolchain (GCC 9.0+)
-   ✅ No special security concerns for inference workloads

### Android Security

-   ✅ App sandboxing provides isolation
-   ✅ Storage permissions required for model access
-   ⚠️ Consider using app-specific storage
-   ✅ Vulkan is stable and well-sandboxed

### Code Signing

-   ARM32: Standard Linux binary signing
-   Android: APK signing required for distribution
-   NDK builds can run via ADB without signing (development)

## Conclusion and Next Steps

### Recommended Actions

1. **Remove macOS Vulkan Support**:

    - Eliminate MoltenVK complexity
    - Focus on native Metal backend
    - Reduces maintenance burden

2. **Add Linux ARM32 Support**:

    - Target embedded and legacy devices
    - Low complexity, proven toolchain
    - Good for IoT and edge deployment

3. **Add Android ARM64 + Vulkan Support**:
    - Large mobile market opportunity
    - Native Vulkan support (no translation layer)
    - Excellent performance on modern devices

### Build Time Estimates

| Platform       | Clean Build | Cached Build |
| -------------- | ----------- | ------------ |
| Linux ARM32    | ~8-12 min   | ~3-5 min     |
| Android CPU    | ~6-10 min   | ~2-4 min     |
| Android Vulkan | ~12-18 min  | ~5-8 min     |

### Artifact Sizes (Compressed)

| Platform      | CPU Only | With GPU Backend   |
| ------------- | -------- | ------------------ |
| Linux ARM32   | ~3-5 MB  | N/A (CPU only)     |
| Android ARM64 | ~8-12 MB | ~15-20 MB (Vulkan) |

### Priority Ranking

1. **High Priority**: Android ARM64 + Vulkan (largest user base)
2. **Medium Priority**: Linux ARM32 CPU (embedded/IoT use cases)
3. **Low Priority**: Remove macOS Vulkan (technical debt)

## References

-   llama.cpp Android Documentation: `docs/android.md`
-   llama.cpp Build Documentation: `docs/build.md`
-   Android NDK: https://developer.android.com/ndk
-   Vulkan on Android: https://developer.android.com/ndk/guides/graphics/getting-started
-   ARM NEON Intrinsics: https://developer.arm.com/architectures/instruction-sets/intrinsics/
