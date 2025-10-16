#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Build Script: Linux x64 CUDA
# ============================================================================
# Purpose: Build llama.cpp shared libraries for Linux x64 with CUDA support
# Output: .publish/linux-x64/cuda/
# Requirements:
#   - CUDA Toolkit 12.2+ installed
#   - gcc-12 and g++-12
#   - NVIDIA drivers
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-linux-cuda"
PUBLISH_DIR="$PROJECT_ROOT/.publish/linux-x64/cuda"

echo "============================================================================"
echo "Building Linux x64 CUDA Backend"
echo "============================================================================"
echo "Project Root: $PROJECT_ROOT"
echo "Build Dir:    $BUILD_DIR"
echo "Publish Dir:  $PUBLISH_DIR"
echo "============================================================================"

# Verify CUDA installation
echo "Verifying CUDA installation..."
if ! command -v nvcc &> /dev/null; then
    echo "ERROR: nvcc not found. Please install CUDA Toolkit 12.2+"
    exit 1
fi

nvcc --version
nvidia-smi || echo "Warning: nvidia-smi not available (may be OK for build-only)"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Configure CMake
cd "$PROJECT_ROOT"
export CC=gcc-12
export CXX=g++-12
export CUDAHOSTCXX=g++-12

cmake -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DGGML_BUILD_TESTS=OFF \
    -DGGML_BUILD_EXAMPLES=OFF \
    -DGGML_CUDA=ON \
    -DLLAMA_CURL=OFF \
    -DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86;89;90" \
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
