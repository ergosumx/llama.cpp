# llama.cpp Build Scripts

This directory contains standalone build scripts for compiling llama.cpp shared libraries across multiple platforms and backends.

## Overview

These scripts build **shared libraries only** with all unnecessary components disabled (tests, examples, servers, tools). Each script:

-   ✅ Verifies dependencies and auto-installs where possible
-   ✅ Configures CMake with optimized settings
-   ✅ Builds in parallel for maximum speed
-   ✅ Strips binaries to reduce size
-   ✅ Publishes artifacts to `.publish/<platform>/<backend>/`

## Available Scripts

### Linux x64

-   `build_linux_x64.sh` - CPU backend (native optimizations)
-   `build_linux_cuda.sh` - CUDA backend (NVIDIA GPUs)
-   `build_linux_vulkan.sh` - Vulkan backend (cross-vendor GPU)
-   `build_linux_opencl.sh` - OpenCL backend (cross-vendor GPU)

### Linux ARM64

-   `build_linux_arm64.sh` - CPU backend (ARM native)
-   `build_linux_arm64_vulkan.sh` - Vulkan backend (ARM GPUs)

### Windows x64

-   `build_windows_x64.ps1` - CPU backend (native optimizations)
-   `build_windows_cuda.ps1` - CUDA backend (NVIDIA GPUs)
-   `build_windows_vulkan.ps1` - Vulkan backend (cross-vendor GPU)
-   `build_windows_opencl.ps1` - OpenCL backend (cross-vendor GPU)

### Windows ARM64

-   `build_windows_arm64.ps1` - CPU backend (ARM native)

### macOS

-   `build_macos_x64.sh` - CPU backend (Intel Macs)
-   `build_macos_metal.sh` - Metal backend (Apple Silicon)

## Quick Start

### Linux

```bash
# Make scripts executable
chmod +x .scripts/*.sh

# Build CPU backend
./.scripts/build_linux_x64.sh

# Build CUDA backend (requires CUDA Toolkit)
./.scripts/build_linux_cuda.sh

# Build Vulkan backend (auto-installs Vulkan SDK)
./.scripts/build_linux_vulkan.sh
```

### Windows

```powershell
# Run from PowerShell (may need to set execution policy)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Build CPU backend
.\.scripts\build_windows_x64.ps1

# Build CUDA backend (requires CUDA Toolkit)
.\.scripts\build_windows_cuda.ps1

# Build Vulkan backend (requires Vulkan SDK)
.\.scripts\build_windows_vulkan.ps1
```

### macOS

```bash
# Make scripts executable
chmod +x .scripts/*.sh

# Build for Intel Macs
./.scripts/build_macos_x64.sh

# Build for Apple Silicon with Metal
./.scripts/build_macos_metal.sh
```

## Output Structure

All built artifacts are published to:

```
.publish/
├── linux-x64/
│   ├── cpu/       # libllama.so, libggml.so
│   ├── cuda/      # libllama.so, libggml-cuda.so
│   ├── vulkan/    # libllama.so, libggml-vulkan.so
│   └── opencl/    # libllama.so, libggml-opencl.so
├── linux-arm64/
│   ├── cpu/       # libllama.so, libggml.so
│   └── vulkan/    # libllama.so, libggml-vulkan.so
├── windows-x64/
│   ├── cpu/       # llama.dll, ggml.dll
│   ├── cuda/      # llama.dll, ggml-cuda.dll
│   ├── vulkan/    # llama.dll, ggml-vulkan.dll
│   └── opencl/    # llama.dll, ggml-opencl.dll
├── windows-arm64/
│   └── cpu/       # llama.dll, ggml.dll
└── macos-arm64/
    └── metal/     # libllama.dylib, libggml-metal.dylib, ggml-metal.metal
```

## Requirements by Platform

### Linux

-   **All builds**: CMake 3.18+, GCC 12+, G++ 12+
-   **CUDA**: CUDA Toolkit 12.2+, NVIDIA drivers
-   **Vulkan**: Vulkan SDK (auto-installed by script)
-   **OpenCL**: OpenCL headers and ICD loader

### Windows

-   **All builds**: Visual Studio 2022 with C++ tools, CMake 3.18+
-   **CUDA**: CUDA Toolkit 12.2+, NVIDIA drivers
-   **Vulkan**: Vulkan SDK from LunarG
-   **OpenCL**: Intel/AMD/NVIDIA OpenCL SDK

### macOS

-   **All builds**: Xcode Command Line Tools, CMake 3.18+
-   **Metal**: macOS 11+ (Big Sur or later)

## CMake Configuration Reference

All scripts use these standardized flags:

### Required Flags

```cmake
-DCMAKE_BUILD_TYPE=Release        # Optimized release build
-DBUILD_SHARED_LIBS=ON            # Build shared libraries (.so/.dll/.dylib)
-DLLAMA_CURL=OFF                  # Disable CURL (not needed for library builds)
```

### Build Disabling Flags (reduce build time by ~60%)

```cmake
-DLLAMA_BUILD_TESTS=OFF           # No tests
-DLLAMA_BUILD_EXAMPLES=OFF        # No examples
-DLLAMA_BUILD_SERVER=OFF          # No server
-DGGML_BUILD_TESTS=OFF            # No GGML tests
-DGGML_BUILD_EXAMPLES=OFF         # No GGML examples
```

### Backend-Specific Flags

```cmake
# CPU
-DGGML_NATIVE=ON                  # Native CPU optimizations

# CUDA
-DGGML_CUDA=ON                    # Enable CUDA
-DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86;89;90"  # Support Kepler to Hopper

# Vulkan
-DGGML_VULKAN=ON                  # Enable Vulkan

# OpenCL
-DGGML_OPENCL=ON                  # Enable OpenCL

# Metal (macOS)
-DGGML_METAL=ON                   # Enable Metal
-DCMAKE_OSX_ARCHITECTURES=arm64   # Apple Silicon
```

## Manual Build Instructions

If you prefer to build manually without scripts:

### Linux CPU Example

```bash
cd /path/to/llama.cpp
mkdir -p build-manual
cmake -B build-manual \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_SERVER=OFF \
  -DGGML_BUILD_TESTS=OFF \
  -DGGML_BUILD_EXAMPLES=OFF \
  -DGGML_NATIVE=ON \
  -DLLAMA_CURL=OFF
cmake --build build-manual -j$(nproc)
```

### Windows CUDA Example

```powershell
cd C:\path\to\llama.cpp
cmake -B build-manual `
  -G "Visual Studio 17 2022" -A x64 `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=ON `
  -DGGML_CUDA=ON `
  -DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86;89;90" `
  -DLLAMA_BUILD_TESTS=OFF `
  -DLLAMA_BUILD_EXAMPLES=OFF `
  -DLLAMA_BUILD_SERVER=OFF `
  -DGGML_BUILD_TESTS=OFF `
  -DGGML_BUILD_EXAMPLES=OFF `
  -DLLAMA_CURL=OFF
cmake --build build-manual --config Release -j
```

## Platform/Backend Compatibility Matrix

| Platform      | CPU | CUDA | Vulkan | OpenCL | Metal |
| ------------- | --- | ---- | ------ | ------ | ----- |
| Linux x64     | ✅  | ✅   | ✅     | ✅     | ❌    |
| Linux ARM64   | ✅  | ❌   | ✅     | ❌     | ❌    |
| Windows x64   | ✅  | ✅   | ✅     | ✅     | ❌    |
| Windows ARM64 | ✅  | ❌   | ❌     | ❌     | ❌    |
| macOS x64     | ✅  | ❌   | ❌     | ❌     | ❌    |
| macOS ARM64   | ✅  | ❌   | ❌     | ❌     | ✅    |

## Troubleshooting

### Linux: "CUDA not found" despite having CUDA installed

Ensure `nvcc` is in your PATH:

```bash
export PATH=/usr/local/cuda/bin:$PATH
```

### Linux: "Vulkan SDK not found"

The script will auto-install, but you can manually install:

```bash
wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc
sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-jammy.list https://packages.lunarg.com/vulkan/lunarg-vulkan-jammy.list
sudo apt update
sudo apt install vulkan-sdk
```

### Windows: "PowerShell script execution is disabled"

Run PowerShell as Administrator and execute:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Windows: "VULKAN_SDK environment variable not set"

Install Vulkan SDK from https://vulkan.lunarg.com/sdk/home#windows and restart your terminal.

### All Platforms: "Could NOT find CURL"

This should not happen with our scripts (we use `-DLLAMA_CURL=OFF`). If you see this, ensure the flag is in your CMake command.

## Advanced Usage

### Build with Debug Symbols

Edit the script and change:

```bash
-DCMAKE_BUILD_TYPE=Release
```

to:

```bash
-DCMAKE_BUILD_TYPE=RelWithDebInfo
```

### Build Static Libraries Instead

Edit the script and change:

```bash
-DBUILD_SHARED_LIBS=ON
```

to:

```bash
-DBUILD_SHARED_LIBS=OFF
```

### Customize CUDA Architectures

Edit CUDA scripts and modify:

```bash
-DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86;89;90"
```

to only the architectures you need (e.g., `"75;80;86"` for Turing/Ampere/Ada).

## Related Documentation

-   **LINUX_BUILD.md** - Detailed Linux build guide with step-by-step instructions
-   **WINDOWS_BUILD.md** - Detailed Windows build guide with step-by-step instructions
-   **llama.cpp/README.md** - Official llama.cpp documentation

## Support

For issues specific to these build scripts, check:

1. Script output (shows detailed error messages)
2. CMake cache files in build directories
3. This README's troubleshooting section

For llama.cpp itself:

-   GitHub: https://github.com/ggerganov/llama.cpp
-   Issues: https://github.com/ggerganov/llama.cpp/issues
