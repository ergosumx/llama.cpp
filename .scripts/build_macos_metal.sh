#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Build Script: macOS ARM64 Metal
# ============================================================================
# Purpose: Build llama.cpp shared libraries for macOS ARM64 (Apple Silicon) with Metal support
# Output: .publish/macos-arm64/metal/
# Requirements:
#   - Xcode Command Line Tools
#   - CMake 3.18+
#   - macOS 11+ (Big Sur or later)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-macos-metal"
PUBLISH_DIR="$PROJECT_ROOT/.publish/macos-arm64/metal"

echo "============================================================================"
echo "Building macOS ARM64 (Apple Silicon) Metal Backend"
echo "============================================================================"
echo "Project Root: $PROJECT_ROOT"
echo "Build Dir:    $BUILD_DIR"
echo "Publish Dir:  $PUBLISH_DIR"
echo "============================================================================"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Configure CMake
cd "$PROJECT_ROOT"
cmake -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DBUILD_SHARED_LIBS=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DGGML_BUILD_TESTS=OFF \
    -DGGML_BUILD_EXAMPLES=OFF \
    -DGGML_BUILD_TOOLS=OFF \
    -DGGML_METAL=ON \
    -DLLAMA_CURL=OFF

# Build
echo ""
echo "Building..."
cmake --build "$BUILD_DIR" -j$(sysctl -n hw.ncpu)

# Strip binaries
echo ""
echo "Stripping binaries..."
find "$BUILD_DIR/bin" -name "*.dylib" -type f -exec strip -x {} \;

# Create publish directory
mkdir -p "$PUBLISH_DIR"

# Copy artifacts
echo ""
echo "Copying artifacts to publish directory..."
cp -v "$BUILD_DIR/bin/"*.dylib "$PUBLISH_DIR/"
if [ -f "$BUILD_DIR/bin/ggml-metal.metal" ]; then
    cp -v "$BUILD_DIR/bin/ggml-metal.metal" "$PUBLISH_DIR/"
fi

# Display results
echo ""
echo "============================================================================"
echo "Build Complete!"
echo "============================================================================"
ls -lh "$PUBLISH_DIR"
echo "============================================================================"
echo "Total size: $(du -sh "$PUBLISH_DIR" | cut -f1)"
echo "============================================================================"
