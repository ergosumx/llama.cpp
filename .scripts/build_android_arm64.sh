#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Build Script: Android ARM64 CPU
# ============================================================================
# Purpose: Build llama.cpp shared libraries for Android ARM64 CPU backend
# Output: .publish/android-arm64/cpu/
# Requirements:
#   - Android NDK r26 or later
#   - CMake 3.18+
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-android-arm64"
PUBLISH_DIR="$PROJECT_ROOT/.publish/android-arm64/cpu"

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
echo "Building Android ARM64 CPU Backend"
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
    -DGGML_NATIVE=OFF \
    -DLLAMA_CURL=OFF \
    -DCMAKE_C_FLAGS="-Os" \
    -DCMAKE_CXX_FLAGS="-Os"

# Build
echo ""
echo "Building..."
cmake --build "$BUILD_DIR" --target llama ggml-base ggml-cpu -j$(nproc)

# Strip binaries
echo ""
echo "Stripping binaries..."
find "$BUILD_DIR/bin" -name "*.so" -type f -exec "$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" --strip-unneeded {} \;

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
echo "To use in Android project:"
echo "  1. Copy .so files to: app/src/main/jniLibs/arm64-v8a/"
echo "  2. Add to build.gradle: ndk { abiFilters 'arm64-v8a' }"
echo "  3. Load library: System.loadLibrary(\"llama\")"
echo "============================================================================"
