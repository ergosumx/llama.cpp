#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Build Script: Linux x64 Vulkan
# ============================================================================
# Purpose: Build llama.cpp shared libraries for Linux x64 with Vulkan support
# Output: .publish/linux-x64/vulkan/
# Requirements:
#   - Vulkan SDK (headers and runtime)
#   - glslc compiler
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-linux-vulkan"
PUBLISH_DIR="$PROJECT_ROOT/.publish/linux-x64/vulkan"

echo "============================================================================"
echo "Building Linux x64 Vulkan Backend"
echo "============================================================================"
echo "Project Root: $PROJECT_ROOT"
echo "Build Dir:    $BUILD_DIR"
echo "Publish Dir:  $PUBLISH_DIR"
echo "============================================================================"

# Verify Vulkan installation
echo "Verifying Vulkan installation..."
if ! command -v glslc &> /dev/null; then
    echo "WARNING: glslc not found. Installing Vulkan development packages..."
    # Use Ubuntu's native Vulkan packages for better compatibility
    sudo apt-get update
    sudo apt-get install -y \
        libvulkan-dev \
        vulkan-tools \
        glslang-tools \
        spirv-tools

    echo "Installed Vulkan packages:"
    dpkg -l | grep vulkan || true
    echo "glslc location: $(which glslc || echo 'not found in PATH')"
fi

if command -v glslc &> /dev/null; then
    glslc --version
else
    echo "WARNING: glslc still not available. Build may fail if Vulkan shaders need compilation."
fi

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Configure CMake
cd "$PROJECT_ROOT"
cmake -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DGGML_BUILD_TESTS=OFF \
    -DGGML_BUILD_EXAMPLES=OFF \
    -DGGML_BUILD_TOOLS=OFF \
    -DGGML_VULKAN=ON \
    -DLLAMA_CURL=OFF \
    -DCMAKE_C_FLAGS="-Os" \
    -DCMAKE_CXX_FLAGS="-Os"

# Build
echo ""
echo "Building..."
cmake --build "$BUILD_DIR" -j$(nproc)

# Strip binaries
echo ""
echo "Stripping binaries..."
find "$BUILD_DIR/bin" -name "*.so" -type f -exec strip --strip-unneeded {} \;

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
