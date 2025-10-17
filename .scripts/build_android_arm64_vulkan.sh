#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Build Script: Android ARM64 Vulkan
# ============================================================================
# Purpose: Build llama.cpp shared libraries for Android ARM64 with Vulkan support
# Output: .publish/android-arm64/vulkan/
# Requirements:
#   - Android NDK r26 or later
#   - CMake 3.18+
#   - Vulkan SDK (NDK includes Vulkan headers)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-android-arm64-vulkan"
PUBLISH_DIR="$PROJECT_ROOT/.publish/android-arm64/vulkan"

# Android NDK path (default location or from environment)
# Remove /wrap.sh suffix if present (GitHub Actions artifact issue)
ANDROID_NDK="${ANDROID_NDK%/wrap.sh}"
ANDROID_NDK="${ANDROID_NDK:-$HOME/Android/Sdk/ndk}"

# Check if NDK directory downloaded to project root
if [ -d "$PROJECT_ROOT/android-ndk-r26d" ]; then
    ANDROID_NDK="$PROJECT_ROOT/android-ndk-r26d"
elif [ -d "$ANDROID_NDK" ]; then
    # Find latest NDK version
    ANDROID_NDK_VERSION=$(ls -1 "$ANDROID_NDK" | sort -V | tail -1)
    if [ -n "$ANDROID_NDK_VERSION" ] && [ -d "$ANDROID_NDK/$ANDROID_NDK_VERSION" ]; then
        ANDROID_NDK="$ANDROID_NDK/$ANDROID_NDK_VERSION"
    fi
fi

# Fallback to common NDK locations
if [ ! -d "$ANDROID_NDK" ]; then
    if [ -d "/opt/android-ndk" ]; then
        ANDROID_NDK="/opt/android-ndk"
    elif [ -d "$HOME/android-ndk" ]; then
        ANDROID_NDK="$HOME/android-ndk"
    fi
fi

echo "============================================================================"
echo "Building Android ARM64 Vulkan Backend"
echo "============================================================================"
echo "Project Root: $PROJECT_ROOT"
echo "Build Dir:    $BUILD_DIR"
echo "Publish Dir:  $PUBLISH_DIR"
echo "Android NDK:  $ANDROID_NDK"
echo "============================================================================"

# Verify Android NDK
if [ ! -d "$ANDROID_NDK" ]; then
    echo "ERROR: Android NDK not found at: $ANDROID_NDK"
    echo ""
    echo "Please set ANDROID_NDK environment variable or install NDK to:"
    echo "  - $HOME/Android/Sdk/ndk/<version>"
    echo "  - /opt/android-ndk"
    echo "  - $HOME/android-ndk"
    echo ""
    echo "Download from: https://developer.android.com/ndk/downloads"
    exit 1
fi

# Verify NDK toolchain file
TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake"
if [ ! -f "$TOOLCHAIN_FILE" ]; then
    echo "ERROR: NDK toolchain file not found: $TOOLCHAIN_FILE"
    exit 1
fi

echo "Using Android NDK: $ANDROID_NDK"
echo "Toolchain file: $TOOLCHAIN_FILE"

# Android build settings
ANDROID_ABI="arm64-v8a"
ANDROID_PLATFORM="android-24"  # Android 7.0 minimum
ANDROID_STL="c++_shared"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Configure CMake with Android toolchain
cd "$PROJECT_ROOT"

# Check if glslc is available (needed for shader compilation)
if command -v glslc &> /dev/null; then
    echo "Found glslc: $(which glslc)"
    glslc --version
    GLSLC_PATH=$(which glslc)
    echo "Using system glslc for shader compilation"
elif command -v glslangValidator &> /dev/null; then
    echo "Found glslangValidator: $(which glslangValidator)"
    glslangValidator --version
    GLSLC_PATH=$(which glslangValidator)
else
    echo "WARNING: No shader compiler found (glslc or glslangValidator)"
    echo "Creating dummy glslc for build process (runtime compilation will be used)..."

    # Create dummy glslc as fallback
    mkdir -p "$BUILD_DIR/dummy_tools"
    echo '#!/bin/bash' > "$BUILD_DIR/dummy_tools/glslc"
    echo 'exit 0' >> "$BUILD_DIR/dummy_tools/glslc"
    chmod +x "$BUILD_DIR/dummy_tools/glslc"
    export PATH="$BUILD_DIR/dummy_tools:$PATH"
    GLSLC_PATH="$BUILD_DIR/dummy_tools/glslc"
    echo "Created dummy glslc at: $GLSLC_PATH"
fi

cmake -B "$BUILD_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DANDROID_ABI="$ANDROID_ABI" \
    -DANDROID_PLATFORM="$ANDROID_PLATFORM" \
    -DANDROID_STL="$ANDROID_STL" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DLLAMA_BUILD_TOOLS=OFF \
    -DGGML_BUILD_TESTS=OFF \
    -DGGML_BUILD_EXAMPLES=OFF \
    -DGGML_BUILD_TOOLS=OFF \
    -DGGML_VULKAN=ON \
    -DGGML_VULKAN_RUN_TESTS=OFF \
    -DLLAMA_CURL=OFF \
    -DVulkan_GLSLC_EXECUTABLE="$GLSLC_PATH"

# Build
echo ""
echo "Building for Android ARM64 with Vulkan..."
# Only build necessary libraries to avoid linking issues
cmake --build "$BUILD_DIR" --target llama ggml-base ggml-cpu ggml-vulkan -j$(nproc)

# Strip binaries
echo ""
echo "Stripping binaries..."
NDK_STRIP="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"
if [ -f "$NDK_STRIP" ]; then
    find "$BUILD_DIR/bin" -name "*.so" -type f -exec "$NDK_STRIP" --strip-unneeded {} \;
else
    echo "Warning: llvm-strip not found, skipping binary stripping"
fi

# Create publish directory
mkdir -p "$PUBLISH_DIR"

# Copy artifacts
echo ""
echo "Copying artifacts to publish directory..."
cp -v "$BUILD_DIR/bin/"*.so "$PUBLISH_DIR/" 2>/dev/null || echo "No .so files found in bin/"

# Display results
echo ""
echo "============================================================================"
echo "Build Complete!"
echo "============================================================================"
if [ "$(ls -A "$PUBLISH_DIR" 2>/dev/null)" ]; then
    ls -lh "$PUBLISH_DIR"
    echo "============================================================================"
    echo "Total size: $(du -sh "$PUBLISH_DIR" | cut -f1)"
else
    echo "WARNING: No artifacts were copied to publish directory"
    echo "Check build output above for errors"
fi
echo "============================================================================"
echo ""
echo "Integration Notes:"
echo "  - Add libggml-vulkan.so to your Android app's jniLibs/arm64-v8a/"
echo "  - Add libllama.so to your Android app's jniLibs/arm64-v8a/"
echo "  - Minimum Android version: 7.0 (API 24)"
echo "  - Requires device with Vulkan support"
echo "============================================================================"
