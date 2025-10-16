#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Build Script: Linux ARM64 Vulkan
# ============================================================================
# Purpose: Build llama.cpp shared libraries for Linux ARM64 with Vulkan support
# Output: .publish/linux-arm64/vulkan/
# Requirements:
#   - Vulkan SDK (headers and runtime)
#   - glslc compiler
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-linux-arm64-vulkan"
PUBLISH_DIR="$PROJECT_ROOT/.publish/linux-arm64/vulkan"

echo "============================================================================"
echo "Building Linux ARM64 Vulkan Backend"
echo "============================================================================"
echo "Project Root: $PROJECT_ROOT"
echo "Build Dir:    $BUILD_DIR"
echo "Publish Dir:  $PUBLISH_DIR"
echo "============================================================================"

# Verify Vulkan installation
echo "Verifying Vulkan installation..."
if ! command -v glslc &> /dev/null; then
    echo "WARNING: glslc not found. Attempting to install Vulkan SDK..."
    echo "Adding LunarG repository..."
    wget -qO - https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo apt-key add -
    sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-jammy.list \
        https://packages.lunarg.com/vulkan/lunarg-vulkan-jammy.list
    sudo apt update
    sudo apt install -y vulkan-sdk
fi

glslc --version

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
