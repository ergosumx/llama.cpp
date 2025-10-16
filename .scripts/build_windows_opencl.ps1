# ============================================================================
# Build Script: Windows x64 OpenCL
# ============================================================================
# Purpose: Build llama.cpp shared libraries for Windows x64 with OpenCL support
# Output: .publish/windows-x64/opencl/
# Requirements:
#   - Visual Studio 2022 with C++ tools
#   - OpenCL SDK (Intel, AMD, or NVIDIA)
#   - CMake 3.18+
# ============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BuildDir = Join-Path $ProjectRoot "build-windows-opencl"
$PublishDir = Join-Path $ProjectRoot ".publish\windows-x64\opencl"

Write-Host "============================================================================"
Write-Host "Building Windows x64 OpenCL Backend"
Write-Host "============================================================================"
Write-Host "Project Root: $ProjectRoot"
Write-Host "Build Dir:    $BuildDir"
Write-Host "Publish Dir:  $PublishDir"
Write-Host "============================================================================"

# Note: OpenCL headers and libraries are typically installed via vcpkg or GPU vendor SDKs
Write-Host "NOTE: Ensure OpenCL SDK is installed (Intel, AMD, or NVIDIA OpenCL)"

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
    -DGGML_BUILD_TESTS=OFF `
    -DGGML_BUILD_EXAMPLES=OFF `
    -DGGML_BUILD_TOOLS=OFF `
    -DGGML_OPENCL=ON `
    -DLLAMA_CURL=OFF

# Build
Write-Host ""
Write-Host "Building..."
cmake --build $BuildDir --config Release -j

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
