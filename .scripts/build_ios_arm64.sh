#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Build Script: iOS ARM64 CPU
# ============================================================================
# Purpose: Build llama.cpp shared libraries for iOS ARM64 (iPhone/iPad) CPU backend
# Output: .publish/ios-arm64/cpu/
# Requirements:
#   - Xcode Command Line Tools
#   - CMake 3.18+
#   - macOS host system
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build-ios-arm64"
PUBLISH_DIR="$PROJECT_ROOT/.publish/ios-arm64/cpu"

echo "============================================================================"
echo "Building iOS ARM64 CPU Backend"
echo "============================================================================"
echo "Project Root: $PROJECT_ROOT"
echo "Build Dir:    $BUILD_DIR"
echo "Publish Dir:  $PUBLISH_DIR"
echo "============================================================================"

# Verify we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "ERROR: iOS builds require macOS"
    exit 1
fi

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "ERROR: Xcode Command Line Tools not found"
    echo "Install with: xcode-select --install"
    exit 1
fi

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# iOS SDK paths
IOS_SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
IOS_DEPLOYMENT_TARGET="13.0"  # iOS 13.0 minimum

echo "iOS SDK Path: $IOS_SDK_PATH"
echo "Deployment Target: $IOS_DEPLOYMENT_TARGET"

# Configure CMake for iOS
cd "$PROJECT_ROOT"
cmake -B "$BUILD_DIR" \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET" \
    -DCMAKE_OSX_SYSROOT="$IOS_SDK_PATH" \
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
    -DGGML_METAL=OFF \
    -DLLAMA_CURL=OFF \
    -DGGML_MACHINE_SUPPORTS_dotprod_EXITCODE=0 \
    -DGGML_MACHINE_SUPPORTS_dotprod_EXITCODE__TRYRUN_OUTPUT="" \
    -DGGML_MACHINE_SUPPORTS_i8mm_EXITCODE=0 \
    -DGGML_MACHINE_SUPPORTS_i8mm_EXITCODE__TRYRUN_OUTPUT="" \
    -DGGML_MACHINE_SUPPORTS_sve_EXITCODE=0 \
    -DGGML_MACHINE_SUPPORTS_sve_EXITCODE__TRYRUN_OUTPUT="" \
    -DCMAKE_C_FLAGS="-arch arm64 -mios-version-min=$IOS_DEPLOYMENT_TARGET" \
    -DCMAKE_CXX_FLAGS="-arch arm64 -mios-version-min=$IOS_DEPLOYMENT_TARGET"

# Build
echo ""
echo "Building..."
cmake --build "$BUILD_DIR" --target llama ggml-base ggml-cpu -j$(sysctl -n hw.ncpu)

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
echo "To use in iOS project:"
echo "  1. Add .dylib files to your Xcode project"
echo "  2. Add to 'Frameworks, Libraries, and Embedded Content'"
echo "  3. Set 'Embed & Sign' or 'Do Not Embed' as needed"
echo "  4. Import in Swift: import llama (if using module map)"
echo "============================================================================"
