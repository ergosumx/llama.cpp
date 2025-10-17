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
    Write-Host "Please install Vulkan SDK from: https://vulkan.lunarg.com/sdk/home#windows"
    exit 1
}
Write-Host "Vulkan SDK: $env:VULKAN_SDK"

$glslc = Get-Command glslc -ErrorAction SilentlyContinue
if (-not $glslc) {
    Write-Host "WARNING: glslc not found in PATH. Looking in Vulkan SDK..."
    $glslcPath = Join-Path $env:VULKAN_SDK "Bin\glslc.exe"
    if (Test-Path $glslcPath) {
        Write-Host "Found: $glslcPath"
    } else {
        Write-Host "ERROR: glslc not found. Vulkan SDK installation may be incomplete."
        exit 1
    }
} else {
    Write-Host "glslc: $($glslc.Source)"
}

# Clean previous build
if (Test-Path $BuildDir) {
    Remove-Item -Recurse -Force $BuildDir
}
New-Item -ItemType Directory -Path $BuildDir | Out-Null

# Configure CMake
Set-Location $ProjectRoot
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
