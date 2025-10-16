#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Build Script: Linux x64 OpenCL
# ============================================================================
# Purpose: Build llama.cpp shared libraries for Linux x64 with OpenCL support
# Output: .publish/linux-x64/opencl/
# Requirements:
#   - OpenCL headers and ICD loader
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-linux-opencl"
PUBLISH_DIR="$PROJECT_ROOT/.publish/linux-x64/opencl"

echo "============================================================================"
echo "Building Linux x64 OpenCL Backend"
echo "============================================================================"
echo "Project Root: $PROJECT_ROOT"
echo "Build Dir:    $BUILD_DIR"
echo "Publish Dir:  $PUBLISH_DIR"
echo "============================================================================"

# Verify OpenCL installation
echo "Checking OpenCL dependencies..."
if ! dpkg -l | grep -q opencl-headers; then
    echo "Installing OpenCL dependencies..."
    sudo apt update
    sudo apt install -y opencl-headers ocl-icd-opencl-dev clinfo
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
    -DGGML_OPENCL=ON \
    -DLLAMA_CURL=OFF

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
