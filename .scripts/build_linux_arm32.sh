#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Build Script: Linux ARM32 (Embedded)
# ============================================================================
# Purpose: Build llama.cpp shared libraries for Linux ARM32 (embedded devices)
# Output: .publish/linux-arm32/cpu/
# Requirements:
#   - ARM32 cross-compilation toolchain (arm-linux-gnueabihf)
#   - CMake 3.18+
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-linux-arm32"
PUBLISH_DIR="$PROJECT_ROOT/.publish/linux-arm32/cpu"

echo "============================================================================"
echo "Building Linux ARM32 (Embedded) CPU Backend"
echo "============================================================================"
echo "Project Root: $PROJECT_ROOT"
echo "Build Dir:    $BUILD_DIR"
echo "Publish Dir:  $PUBLISH_DIR"
echo "============================================================================"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Check for ARM32 toolchain
if ! command -v arm-linux-gnueabihf-gcc &> /dev/null; then
    echo "ERROR: ARM32 cross-compiler not found"
    echo "Install with: sudo apt-get install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf"
    exit 1
fi

echo "ARM32 toolchain found:"
arm-linux-gnueabihf-gcc --version | head -1

# Configure CMake with ARM32 cross-compilation
cd "$PROJECT_ROOT"
cmake -B "$BUILD_DIR" \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=arm \
    -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc \
    -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DLLAMA_BUILD_TOOLS=OFF \
    -DGGML_BUILD_TESTS=OFF \
    -DGGML_BUILD_EXAMPLES=OFF \
    -DGGML_BUILD_TOOLS=OFF \
    -DGGML_NATIVE=OFF \
    -DGGML_CPU_ARM_ARCH=armv7-a \
    -DLLAMA_CURL=OFF \
    -DCMAKE_C_FLAGS="-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -Os" \
    -DCMAKE_CXX_FLAGS="-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -Os"

# Build
echo ""
echo "Building..."
cmake --build "$BUILD_DIR" --target llama ggml-base ggml-cpu -j$(nproc)

# Strip binaries
echo ""
echo "Stripping binaries..."
find "$BUILD_DIR/bin" -name "*.so" -type f -exec arm-linux-gnueabihf-strip --strip-unneeded {} \;

# Create publish directory
mkdir -p "$PUBLISH_DIR"

# Copy artifacts
echo ""
echo "Copying artifacts to publish directory..."
cp -v "$BUILD_DIR/bin/"*.so "$PUBLISH_DIR/"

# Display results
echo ""
echo "============================================================================"
echo "Build Complete!"
echo "============================================================================"
ls -lh "$PUBLISH_DIR"
echo "============================================================================"
echo "Total size: $(du -sh "$PUBLISH_DIR" | cut -f1)"
echo "============================================================================"
echo ""
echo "Target: ARM32 (armv7-a with NEON)"
echo "ABI: hard-float (armhf)"
echo "Suitable for: Raspberry Pi 2/3/4, BeagleBone, embedded Linux devices"
echo "============================================================================"
