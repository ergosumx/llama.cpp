# Windows Build Guide for llama.cpp Shared Libraries

This guide provides comprehensive instructions for building llama.cpp shared libraries on Windows (x64 and ARM64) with various acceleration backends.

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

1. **Visual Studio 2022** with C++ Development Tools

    - Download: https://visualstudio.microsoft.com/downloads/
    - During installation, select "Desktop development with C++"
    - Ensure C++ CMake tools are installed

2. **CMake 3.18 or later**

    - Download: https://cmake.org/download/
    - Add to PATH during installation

3. **Git for Windows** (if cloning repository)
    - Download: https://git-scm.com/download/win

**Verify installation**:

```powershell
# Open PowerShell and check:
cmake --version
# Should show CMake 3.18 or later

# Check Visual Studio
& "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
cl
# Should show Microsoft C/C++ Compiler
```

### CUDA Backend (NVIDIA GPUs)

1. **CUDA Toolkit 12.2 or later**

    - Download: https://developer.nvidia.com/cuda-downloads
    - Choose Windows x86_64, exe (local) installer
    - Install with default options

2. **NVIDIA Drivers** 535+ (usually comes with CUDA Toolkit)

**Verify installation**:

```powershell
nvcc --version
# Should show CUDA 12.2 or later

nvidia-smi
# Should show your GPU and driver version
```

### Vulkan Backend (Cross-Vendor GPUs)

1. **Vulkan SDK from LunarG**
    - Download: https://vulkan.lunarg.com/sdk/home#windows
    - Install with default options
    - SDK will set `VULKAN_SDK` environment variable

**Verify installation**:

```powershell
echo $env:VULKAN_SDK
# Should show C:\VulkanSDK\<version>

glslc --version
# Should show glslc compiler version

vulkaninfo
# Should show your GPU and Vulkan capabilities
```

### OpenCL Backend (Cross-Vendor GPUs)

**Option 1: NVIDIA GPUs** - OpenCL comes with CUDA Toolkit

**Option 2: AMD GPUs** - Install AMD drivers (includes OpenCL)

**Option 3: Intel GPUs** - Install Intel OpenCL runtime

-   Download: https://www.intel.com/content/www/us/en/developer/articles/tool/opencl-drivers.html

**Option 4: vcpkg (Universal)**:

```powershell
# Install vcpkg
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat

# Install OpenCL
.\vcpkg install opencl:x64-windows
```

## Quick Start

### PowerShell Execution Policy

Before running any scripts, you may need to allow script execution:

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify
Get-ExecutionPolicy -List
```

### x64 CPU Build (Recommended First Build)

```powershell
cd C:\path\to\llama.cpp
.\.scripts\build_windows_x64.ps1
```

Expected output:

```
============================================================================
Building Windows x64 CPU Backend
============================================================================
...
Build Complete!
============================================================================
ggml.dll                                   2.5 MB
llama.dll                                 12.3 MB
============================================================================
```

Artifacts will be in: `.publish\windows-x64\cpu\`

### ARM64 CPU Build (Windows on ARM)

```powershell
.\.scripts\build_windows_arm64.ps1
```

Artifacts will be in: `.publish\windows-arm64\cpu\`

## Backend-Specific Builds

### CPU Backend

#### x64 with Native Optimizations

**Script**: `.scripts\build_windows_x64.ps1`

**Features**:

-   Native CPU optimizations
-   AVX/AVX2/FMA support (if available)
-   Multi-threaded matrix operations

**Requirements**:

-   Visual Studio 2022 with C++ tools
-   CMake 3.18+

**Build**:

```powershell
.\.scripts\build_windows_x64.ps1
```

**Output**: `.publish\windows-x64\cpu\`

-   `llama.dll` - Main llama.cpp library
-   `ggml.dll` - GGML computation backend

#### ARM64 with Native Optimizations

**Script**: `.scripts\build_windows_arm64.ps1`

**Features**:

-   Native ARM64 optimizations
-   NEON SIMD support
-   Multi-threaded operations

**Requirements**:

-   Windows on ARM device (Surface Pro X, Dev Kit 2023)
-   Visual Studio 2022 with ARM64 build tools
-   CMake 3.18+

**Build**:

```powershell
.\.scripts\build_windows_arm64.ps1
```

**Output**: `.publish\windows-arm64\cpu\`

---

### CUDA Backend

**Script**: `.scripts\build_windows_cuda.ps1`

**Features**:

-   GPU-accelerated inference
-   Supports CUDA architectures from Kepler (6.1) to Hopper (9.0)
-   Visual Studio 2022 compiler integration

**Requirements**:

-   NVIDIA GPU with CUDA support
-   CUDA Toolkit 12.2+
-   NVIDIA drivers 535+
-   Visual Studio 2022 with C++ tools

**Build**:

```powershell
# Ensure CUDA is in PATH (usually automatic after install)
# If not, add manually:
$env:PATH = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.2\bin;$env:PATH"

# Run build script
.\.scripts\build_windows_cuda.ps1
```

**Script will verify**:

-   CUDA compiler (`nvcc.exe`) is available
-   NVIDIA GPU is detected (`nvidia-smi.exe`)

**Output**: `.publish\windows-x64\cuda\`

-   `llama.dll` - Main library
-   `ggml-cuda.dll` - CUDA-accelerated GGML backend
-   `ggml_shared.dll` - Additional CUDA dependencies

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

**Script**: `.scripts\build_windows_vulkan.ps1`

**Features**:

-   Cross-vendor GPU acceleration (NVIDIA, AMD, Intel)
-   No vendor-specific driver requirements beyond graphics drivers
-   Works with integrated and discrete GPUs

**Requirements**:

-   Vulkan-capable GPU (NVIDIA, AMD, Intel)
-   Updated graphics drivers
-   Vulkan SDK from LunarG

**Build**:

```powershell
# Ensure VULKAN_SDK is set (automatic after SDK install)
# Verify:
echo $env:VULKAN_SDK

# Run build script
.\.scripts\build_windows_vulkan.ps1
```

**Script will verify**:

-   `VULKAN_SDK` environment variable is set
-   `glslc.exe` compiler is available

**Output**: `.publish\windows-x64\vulkan\`

-   `llama.dll` - Main library
-   `ggml-vulkan.dll` - Vulkan-accelerated GGML backend
-   `ggml_shared.dll` - Additional dependencies

---

### OpenCL Backend

**Script**: `.scripts\build_windows_opencl.ps1`

**Features**:

-   Cross-vendor GPU acceleration
-   Works with NVIDIA, AMD, Intel GPUs
-   Broad hardware compatibility

**Requirements**:

-   OpenCL-capable GPU
-   OpenCL runtime (from GPU vendor or vcpkg)

**Build**:

```powershell
# If using vcpkg, add to CMAKE_TOOLCHAIN_FILE
# Otherwise, ensure OpenCL.dll is in PATH

# Run build script
.\.scripts\build_windows_opencl.ps1
```

**Output**: `.publish\windows-x64\opencl\`

-   `llama.dll` - Main library
-   `ggml-opencl.dll` - OpenCL-accelerated GGML backend

---

## Manual Build Instructions

If you prefer not to use the automated scripts:

### CPU x64 Manual Build

```powershell
cd C:\path\to\llama.cpp

# Create build directory
mkdir build-manual-cpu
cd build-manual-cpu

# Configure
cmake .. `
    -G "Visual Studio 17 2022" `
    -A x64 `
    -DCMAKE_BUILD_TYPE=Release `
    -DBUILD_SHARED_LIBS=ON `
    -DLLAMA_BUILD_TESTS=OFF `
    -DLLAMA_BUILD_EXAMPLES=OFF `
    -DLLAMA_BUILD_SERVER=OFF `
    -DGGML_BUILD_TESTS=OFF `
    -DGGML_BUILD_EXAMPLES=OFF `
    -DGGML_NATIVE=ON `
    -DLLAMA_CURL=OFF

# Build
cmake --build . --config Release -j

# DLLs are in: bin\Release\llama.dll, bin\Release\ggml.dll
```

### CUDA Manual Build

```powershell
cd C:\path\to\llama.cpp
mkdir build-manual-cuda
cd build-manual-cuda

# Configure
cmake .. `
    -G "Visual Studio 17 2022" `
    -A x64 `
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

# Build
cmake --build . --config Release -j

# DLLs are in: bin\Release\
```

### Vulkan Manual Build

```powershell
cd C:\path\to\llama.cpp
mkdir build-manual-vulkan
cd build-manual-vulkan

# Configure
cmake .. `
    -G "Visual Studio 17 2022" `
    -A x64 `
    -DCMAKE_BUILD_TYPE=Release `
    -DBUILD_SHARED_LIBS=ON `
    -DGGML_VULKAN=ON `
    -DLLAMA_BUILD_TESTS=OFF `
    -DLLAMA_BUILD_EXAMPLES=OFF `
    -DLLAMA_BUILD_SERVER=OFF `
    -DGGML_BUILD_TESTS=OFF `
    -DGGML_BUILD_EXAMPLES=OFF `
    -DLLAMA_CURL=OFF

# Build
cmake --build . --config Release -j

# DLLs are in: bin\Release\
```

## Troubleshooting

### Issue: "PowerShell script execution is disabled"

**Solution**:

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify
Get-ExecutionPolicy
# Should show "RemoteSigned" or "Unrestricted"
```

**Alternative** (if you can't change policy):

```powershell
# Run script with bypass flag
powershell -ExecutionPolicy Bypass -File .\.scripts\build_windows_x64.ps1
```

---

### Issue: "CUDA not found" despite CUDA being installed

**Solution**:

```powershell
# Check if CUDA is in PATH
echo $env:PATH | Select-String "CUDA"

# If not, add it:
$env:PATH = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.2\bin;$env:PATH"

# Make permanent (System Properties → Environment Variables → PATH)
# Or add to PowerShell profile:
notepad $PROFILE
# Add: $env:PATH = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.2\bin;$env:PATH"
```

---

### Issue: "VULKAN_SDK environment variable not set"

**Solution**:

1. Reinstall Vulkan SDK (should set automatically)
2. Or set manually:

```powershell
# Temporary
$env:VULKAN_SDK = "C:\VulkanSDK\1.3.280.0"

# Permanent: System Properties → Environment Variables → New System Variable
# Variable name: VULKAN_SDK
# Variable value: C:\VulkanSDK\1.3.280.0
```

---

### Issue: "Could NOT find CURL"

**Solution**: This should not happen with our scripts (we use `-DLLAMA_CURL=OFF`). If you see this:

```powershell
# In your cmake command, ensure you have:
-DLLAMA_CURL=OFF
```

---

### Issue: "Visual Studio 17 2022 not found"

**Solution**:

1. Install Visual Studio 2022 (any edition)
2. Ensure "Desktop development with C++" workload is installed
3. Or use Visual Studio 2019:

```powershell
# In script, change generator:
-G "Visual Studio 16 2019"
```

---

### Issue: Build succeeds but DLLs are missing

**Solution**: Check the correct output directory:

```powershell
# DLLs are in bin\Release\, not bin\
dir build-*\bin\Release\*.dll
```

---

### Issue: "nvcc fatal: Unsupported gpu architecture 'compute_90'"

**Solution**: Your CUDA Toolkit is too old. Update to CUDA 12.2+, or reduce architectures:

```powershell
# Edit script and change:
-DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86;89;90"
# To:
-DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86"
```

---

### Issue: DLLs crash on load or "entry point not found"

**Solution**: Runtime mismatch. Ensure you're using Release build:

```powershell
# Check CMake configuration
-DCMAKE_BUILD_TYPE=Release

# Ensure you're copying from Release folder:
Copy-Item "$BuildDir\bin\Release\*.dll" $PublishDir
```

---

### Issue: CUDA build fails with "cl.exe not found"

**Solution**: Visual Studio command-line tools not in PATH:

```powershell
# Run from "Developer Command Prompt for VS 2022"
# Or initialize manually:
& "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
```

---

## Verification

### Verify DLL Architecture

```powershell
# Use dumpbin (from VS Developer Command Prompt)
dumpbin /headers .publish\windows-x64\cpu\llama.dll | Select-String "machine"
# Should show: x64

# Check dependencies
dumpbin /dependents .publish\windows-x64\cpu\llama.dll
# Should show ggml.dll
```

### Verify CUDA DLLs

```powershell
# Check CUDA dependencies
dumpbin /dependents .publish\windows-x64\cuda\ggml-cuda.dll | Select-String "cuda"

# Should show:
# cudart64_12.dll
# cublas64_12.dll
# cublasLt64_12.dll
```

### Verify Vulkan DLLs

```powershell
# Check Vulkan dependencies
dumpbin /dependents .publish\windows-x64\vulkan\ggml-vulkan.dll | Select-String "vulkan"

# Should show:
# vulkan-1.dll
```

### Check DLL Sizes

```powershell
# CPU build (Release, optimized)
Get-ChildItem .publish\windows-x64\cpu\*.dll | Format-Table Name, @{Label="Size(MB)"; Expression={"{0:N2}" -f ($_.Length/1MB)}}

# Expected sizes (approximate):
# ggml.dll:   2-3 MB
# llama.dll: 10-15 MB
```

### Test DLL Loading

```powershell
# Quick test: Use PowerShell to check if DLL is valid
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class LlamaTest {
    [DllImport("llama.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr llama_model_default_params();
}
"@ -PassThru -ReferencedAssemblies @(".publish\windows-x64\cpu\llama.dll")

# If no error, DLL is valid
```

## Performance Tips

1. **Use the right backend for your hardware**:

    - NVIDIA GPU: Use CUDA (fastest)
    - AMD/Intel GPU: Use Vulkan or OpenCL
    - CPU only: Use CPU backend with native optimizations

2. **Enable native optimizations**: Scripts use `-DGGML_NATIVE=ON` for CPU builds

3. **Parallel builds**: Scripts use `-j` for maximum parallelization

4. **Release builds**: Always use Release (not Debug) for deployment

## Advanced Configuration

### Build with Custom CUDA Architectures

Edit `.scripts\build_windows_cuda.ps1`:

```powershell
# Change this line:
-DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86;89;90"

# To only your GPU's architecture (faster build):
-DCMAKE_CUDA_ARCHITECTURES="86"  # For RTX 3060 laptop
```

### Build with vcpkg Dependencies

```powershell
# In CMake configuration, add:
-DCMAKE_TOOLCHAIN_FILE="C:\vcpkg\scripts\buildsystems\vcpkg.cmake"
```

### Build Static Libraries Instead

Edit scripts and change:

```powershell
-DBUILD_SHARED_LIBS=ON
# To:
-DBUILD_SHARED_LIBS=OFF
```

Output will be `.lib` files instead of `.dll`.

## Next Steps

-   See **LINUX_BUILD.md** for Linux build instructions
-   See **.scripts\README.md** for script documentation
-   See **llama.cpp\README.md** for library usage examples

## Support

For build issues:

1. Check script output (shows detailed errors)
2. Review this troubleshooting section
3. Check CMake cache: `type build-*\CMakeCache.txt | findstr ERROR`
4. Check Visual Studio build logs in `build-*\`
5. Check llama.cpp GitHub issues: https://github.com/ggerganov/llama.cpp/issues
