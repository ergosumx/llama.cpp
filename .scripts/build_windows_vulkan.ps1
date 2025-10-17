# ============================================================================
# Build Script: Windows x64 Vulkan
# ============================================================================
# Purpose: Build llama.cpp shared libraries for Windows x64 with Vulkan support
# Output: .publish/windows-x64/vulkan/
# Requirements:
#   - Visual Studio 2022 with C++ tools
#   - Vulkan SDK from LunarG
#   - CMake 3.18+
# ============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BuildDir = Join-Path $ProjectRoot "build-windows-vulkan"
$PublishDir = Join-Path $ProjectRoot ".publish\windows-x64\vulkan"

Write-Host "============================================================================"
Write-Host "Building Windows x64 Vulkan Backend"
Write-Host "============================================================================"
Write-Host "Project Root: $ProjectRoot"
Write-Host "Build Dir:    $BuildDir"
Write-Host "Publish Dir:  $PublishDir"
Write-Host "============================================================================"

# Verify Vulkan SDK installation
Write-Host "Checking Vulkan SDK..."
if (-not $env:VULKAN_SDK) {
    Write-Host "ERROR: Vulkan SDK not found. VULKAN_SDK environment variable is not set."
    exit 1
}
Write-Host "Vulkan SDK: $env:VULKAN_SDK"

# Check for glslc shader compiler (required for Vulkan build)
Write-Host "Checking for glslc shader compiler..."
$glslcPath = Join-Path $env:VULKAN_SDK "Bin\glslc.exe"

if (Test-Path $glslcPath) {
    Write-Host "Found glslc: $glslcPath"
    $env:PATH = "$env:VULKAN_SDK\Bin;$env:PATH"
    & $glslcPath --version
} else {
    Write-Host "ERROR: glslc not found in Vulkan SDK"
    Write-Host "Expected location: $glslcPath"
    Write-Host "Please ensure Vulkan SDK is installed with Glslang component"
    exit 1
}

# Clean previous build
if (Test-Path $BuildDir) {
    Remove-Item -Recurse -Force $BuildDir
}

# Configure CMake
Set-Location $ProjectRoot

Write-Host "Configuring CMake..."
cmake -B $BuildDir `
    -G "Visual Studio 17 2022" `
    -A x64 `
    -DCMAKE_BUILD_TYPE=Release `
    -DBUILD_SHARED_LIBS=ON `
    -DLLAMA_BUILD_TESTS=OFF `
    -DLLAMA_BUILD_EXAMPLES=OFF `
    -DLLAMA_BUILD_SERVER=OFF `
    -DLLAMA_BUILD_TOOLS=OFF `
    -DGGML_BUILD_TESTS=OFF `
    -DGGML_BUILD_EXAMPLES=OFF `
    -DGGML_BUILD_TOOLS=OFF `
    -DGGML_VULKAN=ON `
    -DGGML_VULKAN_RUN_TESTS=OFF `
    -DLLAMA_CURL=OFF

# Build
Write-Host ""
Write-Host "Building..."
# Only build necessary libraries to avoid linking issues
cmake --build $BuildDir --config Release --target llama ggml-base ggml-cpu ggml-vulkan -j

# Create publish directory
if (-not (Test-Path $PublishDir)) {
    New-Item -ItemType Directory -Path $PublishDir | Out-Null
}

# Copy artifacts
Write-Host ""
Write-Host "Copying artifacts to publish directory..."
Copy-Item "$BuildDir\bin\Release\*.dll" $PublishDir -Verbose

# Display results
Write-Host ""
Write-Host "============================================================================"
Write-Host "Build Complete!"
Write-Host "============================================================================"
Get-ChildItem $PublishDir | ForEach-Object {
    Write-Host ("{0,-40} {1,10}" -f $_.Name, ("{0:N2} MB" -f ($_.Length / 1MB)))
}
Write-Host "============================================================================"
$TotalSize = (Get-ChildItem $PublishDir | Measure-Object -Property Length -Sum).Sum
Write-Host "Total size: $("{0:N2} MB" -f ($TotalSize / 1MB))"
Write-Host "============================================================================"
