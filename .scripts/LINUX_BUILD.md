# Linux Build Guide for llama.cpp Shared Libraries

This guide provides comprehensive instructions for building llama.cpp shared libraries on Linux (x64 and ARM64) with various acceleration backends.

## Table of Contents

-   [Prerequisites](#prerequisites)
-   [Quick Start](#quick-start)
-   [Backend-Specific Builds](#backend-specific-builds)
    -   [CPU Backend](#cpu-backend)
    -   [CUDA Backend](#cuda-backend)
    -   [Vulkan Backend](#vulkan-backend)
    -   [OpenCL Backend](#opencl-backend)
-   [Manual Build Instructions](#manual-build-instructions)
-   [Troubleshooting](#troubleshooting)
-   [Verification](#verification)

## Prerequisites

### All Builds

```bash
# Update package lists
sudo apt update

# Install essential build tools
sudo apt install -y build-essential cmake git

# GCC/G++ 12+ (required for CUDA compatibility)
sudo apt install -y gcc-12 g++-12
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100
```

### CUDA Backend (NVIDIA GPUs)

```bash
# Install CUDA Toolkit 12.2 or later
# Download from: https://developer.nvidia.com/cuda-downloads

# For Ubuntu 22.04 example:
wget https://developer.download.nvidia.com/compute/cuda/12.2.0/local_installers/cuda_12.2.0_535.54.03_linux.run
sudo sh cuda_12.2.0_535.54.03_linux.run

# Add to PATH (add to ~/.bashrc for persistence)
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Verify installation
nvcc --version
nvidia-smi
```

### Vulkan Backend (Cross-Vendor GPUs)

**Note**: The build script auto-installs this, but you can pre-install:

```bash
# Add LunarG repository
wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc
sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-jammy.list https://packages.lunarg.com/vulkan/lunarg-vulkan-jammy.list

# Install Vulkan SDK
sudo apt update
sudo apt install -y vulkan-sdk

# Verify installation
glslc --version
vulkaninfo | head -n 20
```

### OpenCL Backend (Cross-Vendor GPUs)

```bash
# Install OpenCL headers and ICD loader
sudo apt update
sudo apt install -y opencl-headers ocl-icd-opencl-dev clinfo

# Install vendor-specific OpenCL runtime:
# - NVIDIA: Installed with CUDA Toolkit
# - AMD: Install ROCm or amdgpu-pro
# - Intel: Install intel-opencl-icd

# Verify installation
clinfo
```

## Quick Start

### x64 CPU Build (Recommended First Build)

```bash
cd /path/to/llama.cpp
chmod +x .scripts/*.sh
./.scripts/build_linux_x64.sh
```

Expected output:

```
============================================================================
Building Linux x64 CPU Backend
============================================================================
...
Build Complete!
============================================================================
libggml.so      2.5 MB
libllama.so     12.3 MB
============================================================================
```

Artifacts will be in: `.publish/linux-x64/cpu/`

### ARM64 CPU Build

```bash
./.scripts/build_linux_arm64.sh
```

Artifacts will be in: `.publish/linux-arm64/cpu/`

## Backend-Specific Builds

### CPU Backend

#### x64 with Native Optimizations

**Script**: `.scripts/build_linux_x64.sh`

**Features**:

-   Native CPU optimizations (-march=native)
-   AVX/AVX2/FMA support (if available)
-   Multi-threaded matrix operations

**Requirements**:

-   GCC 12+
-   CMake 3.18+

**Build**:

```bash
./.scripts/build_linux_x64.sh
```

**Output**: `.publish/linux-x64/cpu/`

-   `libllama.so` - Main llama.cpp library
-   `libggml.so` - GGML computation backend

#### ARM64 with Native Optimizations

**Script**: `.scripts/build_linux_arm64.sh`

**Features**:

-   Native ARM64 optimizations
-   NEON SIMD support
-   Multi-threaded operations

**Requirements**:

-   ARM64 processor (e.g., Raspberry Pi 4/5, AWS Graviton)
-   GCC 12+
-   CMake 3.18+

**Build**:

```bash
./.scripts/build_linux_arm64.sh
```

**Output**: `.publish/linux-arm64/cpu/`

---

### CUDA Backend

**Script**: `.scripts/build_linux_cuda.sh`

**Features**:

-   GPU-accelerated inference
-   Supports CUDA architectures from Kepler (6.1) to Hopper (9.0)
-   Optimized with -Os flags for reduced size

**Requirements**:

-   NVIDIA GPU with CUDA support
-   CUDA Toolkit 12.2+
-   NVIDIA drivers 535+
-   GCC 12+ (required by CUDA)

**Build**:

```bash
# Ensure CUDA is in PATH
export PATH=/usr/local/cuda/bin:$PATH

# Run build script
./.scripts/build_linux_cuda.sh
```

**Script will verify**:

-   CUDA compiler (`nvcc`) is available
-   NVIDIA GPU is detected (`nvidia-smi`)
-   GCC 12 is installed

**Output**: `.publish/linux-x64/cuda/`

-   `libllama.so` - Main library
-   `libggml-cuda.so` - CUDA-accelerated GGML backend

**Supported CUDA Architectures**:

-   61: GeForce GTX 10 series (Pascal)
-   70: Tesla V100 (Volta)
-   75: GeForce RTX 20 series (Turing)
-   80: GeForce RTX 30 series (Ampere)
-   86: GeForce RTX 30 laptop (Ampere)
-   89: GeForce RTX 40 laptop (Ada Lovelace)
-   90: GeForce RTX 40 series (Ada Lovelace), H100 (Hopper)

---

### Vulkan Backend

**Script**: `.scripts/build_linux_vulkan.sh`

**Features**:

-   Cross-vendor GPU acceleration (NVIDIA, AMD, Intel)
-   Automatic Vulkan SDK installation
-   No vendor-specific driver requirements

**Requirements**:

-   Vulkan-capable GPU (NVIDIA, AMD, Intel)
-   Updated graphics drivers
-   Vulkan SDK (auto-installed by script)

**Build**:

```bash
# Script will auto-install Vulkan SDK if not found
./.scripts/build_linux_vulkan.sh
```

**Script will**:

1. Check for `glslc` compiler
2. If not found, add LunarG repository and install Vulkan SDK
3. Configure and build with Vulkan support

**Output**: `.publish/linux-x64/vulkan/`

-   `libllama.so` - Main library
-   `libggml-vulkan.so` - Vulkan-accelerated GGML backend

#### ARM64 Vulkan

**Script**: `.scripts/build_linux_arm64_vulkan.sh`

**Use case**: ARM devices with Vulkan-capable GPUs (e.g., Mali, Adreno)

**Build**:

```bash
./.scripts/build_linux_arm64_vulkan.sh
```

**Output**: `.publish/linux-arm64/vulkan/`

---

### OpenCL Backend

**Script**: `.scripts/build_linux_opencl.sh`

**Features**:

-   Cross-vendor GPU acceleration
-   Works with NVIDIA, AMD, Intel GPUs
-   Broad hardware compatibility

**Requirements**:

-   OpenCL-capable GPU
-   OpenCL headers and ICD loader
-   Vendor-specific OpenCL runtime

**Build**:

```bash
# Script will auto-install OpenCL headers if not found
./.scripts/build_linux_opencl.sh
```

**Output**: `.publish/linux-x64/opencl/`

-   `libllama.so` - Main library
-   `libggml-opencl.so` - OpenCL-accelerated GGML backend

---

## Manual Build Instructions

If you prefer not to use the automated scripts:

### CPU x64 Manual Build

```bash
cd /path/to/llama.cpp

# Create build directory
mkdir -p build-manual-cpu
cd build-manual-cpu

# Configure
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DGGML_BUILD_TESTS=OFF \
    -DGGML_BUILD_EXAMPLES=OFF \
    -DGGML_NATIVE=ON \
    -DLLAMA_CURL=OFF

# Build
cmake --build . -j$(nproc)

# Strip binaries
find bin -name "*.so" -exec strip --strip-unneeded {} \;

# Libraries are in: bin/libllama.so, bin/libggml.so
```

### CUDA Manual Build

```bash
cd /path/to/llama.cpp
mkdir -p build-manual-cuda
cd build-manual-cuda

# Set compilers
export CC=gcc-12
export CXX=g++-12
export CUDAHOSTCXX=g++-12

# Configure
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_CUDA=ON \
    -DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86;89;90" \
    -DCMAKE_CUDA_FLAGS="-Os" \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DGGML_BUILD_TESTS=OFF \
    -DGGML_BUILD_EXAMPLES=OFF \
    -DLLAMA_CURL=OFF

# Build
cmake --build . -j$(nproc)

# Strip binaries
find bin -name "*.so" -exec strip --strip-unneeded {} \;
```

### Vulkan Manual Build

```bash
cd /path/to/llama.cpp
mkdir -p build-manual-vulkan
cd build-manual-vulkan

# Configure
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_VULKAN=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DGGML_BUILD_TESTS=OFF \
    -DGGML_BUILD_EXAMPLES=OFF \
    -DLLAMA_CURL=OFF

# Build
cmake --build . -j$(nproc)

# Strip binaries
find bin -name "*.so" -exec strip --strip-unneeded {} \;
```

## Troubleshooting

### Issue: "CUDA not found" despite CUDA being installed

**Solution**:

```bash
# Ensure CUDA is in PATH
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Verify
nvcc --version
```

Add to `~/.bashrc` for persistence:

```bash
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

---

### Issue: "Could NOT find CURL"

**Solution**: This should not happen with our scripts (we use `-DLLAMA_CURL=OFF`). If you see this:

```bash
# In your cmake command, ensure you have:
-DLLAMA_CURL=OFF
```

---

### Issue: "nvcc fatal: Unsupported gpu architecture 'compute_90'"

**Solution**: Your CUDA Toolkit is too old. Update to CUDA 12.2+, or reduce architectures:

```bash
# Edit script and change:
-DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86;89;90"
# To:
-DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86"
```

---

### Issue: "glslc: command not found" (Vulkan)

**Solution**: Let the script auto-install, or manually:

```bash
wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc
sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-jammy.list https://packages.lunarg.com/vulkan/lunarg-vulkan-jammy.list
sudo apt update
sudo apt install -y vulkan-sdk
```

---

### Issue: Build succeeds but libraries are huge

**Solution**: Ensure you're building with Release mode and stripping binaries:

```bash
# Check CMake configuration
-DCMAKE_BUILD_TYPE=Release

# Strip after build
find build/bin -name "*.so" -exec strip --strip-unneeded {} \;
```

---

### Issue: "undefined reference to `std::\_\_throw_bad_array_new_length'"

**Solution**: GCC version mismatch. Ensure consistent GCC version:

```bash
# Use GCC 12 consistently
export CC=gcc-12
export CXX=g++-12

# For CUDA builds, also set:
export CUDAHOSTCXX=g++-12
```

---

### Issue: CUDA build gets stuck or hangs

**Solution**:

1. Reduce parallel jobs: `cmake --build . -j4` instead of `-j$(nproc)`
2. Check GPU memory: `nvidia-smi` (may be out of memory)
3. Kill stuck processes: `pkill -9 nvcc`

---

## Verification

### Verify Shared Libraries

```bash
# Check architecture
file .publish/linux-x64/cpu/libllama.so
# Expected: ELF 64-bit LSB shared object, x86-64

# Check dynamic dependencies
ldd .publish/linux-x64/cpu/libllama.so

# Check symbols (should show lots of llama/ggml symbols)
nm -D .publish/linux-x64/cpu/libllama.so | grep llama_

# Check size (stripped binaries are much smaller)
ls -lh .publish/linux-x64/cpu/
```

### Verify CUDA Libraries

```bash
# Check CUDA dependencies
ldd .publish/linux-x64/cuda/libggml-cuda.so | grep cuda

# Should show links to CUDA libraries:
# libcudart.so
# libcublas.so
# libcublasLt.so
```

### Verify Vulkan Libraries

```bash
# Check Vulkan dependencies
ldd .publish/linux-x64/vulkan/libggml-vulkan.so | grep vulkan

# Should show link to:
# libvulkan.so.1
```

### Run Simple Test

```bash
# If you have a GGUF model, you can test (requires llama-cli example)
# Note: Our scripts don't build examples, so this requires a separate build

# Quick symbol check instead:
nm -D .publish/linux-x64/cpu/libllama.so | grep -E 'llama_load_model|llama_new_context'

# Both should return results if library is valid
```

## Performance Tips

1. **Use the right backend for your hardware**:

    - NVIDIA GPU: Use CUDA (fastest)
    - AMD/Intel GPU: Use Vulkan or OpenCL
    - CPU only: Use CPU backend with native optimizations

2. **Enable native optimizations**: Scripts use `-DGGML_NATIVE=ON` for CPU builds

3. **Reduce binary size**: All scripts strip binaries with `--strip-unneeded`

4. **Parallel builds**: Scripts use `-j$(nproc)` for maximum parallelization

## Next Steps

-   See **WINDOWS_BUILD.md** for Windows build instructions
-   See **.scripts/README.md** for script documentation
-   See **llama.cpp/README.md** for library usage examples

## Support

For build issues:

1. Check script output (shows detailed errors)
2. Review this troubleshooting section
3. Check CMake cache: `cat build-*/CMakeCache.txt | grep -i error`
4. Check llama.cpp GitHub issues: https://github.com/ggerganov/llama.cpp/issues
