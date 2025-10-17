# Release Workflow Configuration

## Overview

The build workflow has been configured to automatically create GitHub releases when version tags are pushed.

## Trigger Configuration

### Tag-Based Releases

**Workflow triggers on**:
```yaml
on:
  push:
    tags:
      - 'v*.*.*'
```

**Examples of valid tags**:
- `v1.0.0`
- `v2.1.3`
- `v0.5.0-beta`
- `v1.0.0-rc1`

**Also supports**:
```yaml
workflow_dispatch:  # Manual trigger from GitHub Actions UI
```

## Creating a Release

### Method 1: Git Tag (Recommended)

```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0

# Or create with annotation
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### Method 2: GitHub UI

1. Go to repository → Releases → "Create a new release"
2. Click "Choose a tag"
3. Type new tag (e.g., `v1.0.0`)
4. Click "Create new tag: v1.0.0 on publish"
5. Publish release (this pushes the tag and triggers workflow)

### Method 3: Manual Workflow Dispatch

1. Go to Actions → "Build Multi-Backend Release"
2. Click "Run workflow"
3. Select branch
4. Click "Run workflow"

**Note**: Manual dispatch won't extract version from tag

## Build Process

### Workflow Execution

When a tag is pushed:

1. **All 16 build jobs run in parallel**:
   - Linux: 6 builds (x64 CPU/Vulkan/OpenCL/ROCm, ARM64, ARM32)
   - Android: 1 build (ARM64 CPU)
   - iOS: 2 builds (ARM64 CPU/Metal)
   - Windows: 4 builds (x64 CPU/Vulkan/OpenCL/ROCm)
   - macOS: 3 builds (ARM64 CPU/Metal, x64 CPU)

2. **Each job uploads artifacts**:
   - Artifact name: `ggufx-{platform}-{backend}`
   - Retention: 90 days
   - Format: Original shared libraries (.so/.dll/.dylib)

3. **Release job waits for all builds** (`needs:` all 16 jobs)

4. **Release creation**:
   - Downloads all 16 artifacts
   - Creates zip archives for each platform
   - Generates SHA256 checksums
   - Creates GitHub release with all archives

## Release Artifacts

### Archive Structure

Each platform gets a separate archive:

```
ggufx-linux-x64-cpu.zip
├── libllama.so
├── libggml-base.so
└── libggml-cpu.so

ggufx-windows-x64-vulkan.zip
├── llama.dll
├── ggml-base.dll
├── ggml-cpu.dll
└── ggml-vulkan.dll

ggufx-macos-arm64-metal.zip
├── libllama.dylib
├── libggml.dylib
├── libggml-base.dylib
├── libggml-cpu.dylib
├── libggml-metal.dylib
└── ggml-metal.metal
```

### Checksums File

`checksums.txt` contains SHA256 hashes for all archives:
```
a1b2c3d4... ggufx-linux-x64-cpu.zip
e5f6g7h8... ggufx-windows-x64-vulkan.zip
...
```

## Release Content

### Automatic Release Notes

The workflow automatically generates release notes including:

1. **Version number** (from tag)
2. **Platform list** (16 builds)
3. **Library architecture** explanation
4. **File counts** per build type
5. **Verification** instructions (checksums)

### Customizing Release Notes

To customize, edit the `body:` section in the workflow:

```yaml
- name: Create GitHub Release
  uses: softprops/action-gh-release@v1
  with:
    name: Release ${{ steps.version.outputs.version }}
    body: |
      # Your custom release notes here
```

## Version Management

### Version Extraction

The workflow extracts version from the tag:

```yaml
- name: Extract Version
  id: version
  run: |
    VERSION=${GITHUB_REF#refs/tags/}
    echo "version=${VERSION}" >> $GITHUB_OUTPUT
```

**Example**:
- Tag: `v1.2.3`
- Extracted version: `v1.2.3`
- Release title: "Release v1.2.3"

### Semantic Versioning

Recommended format: `v{MAJOR}.{MINOR}.{PATCH}`

**Examples**:
- `v1.0.0` - Initial release
- `v1.1.0` - New features (backwards compatible)
- `v1.1.1` - Bug fixes
- `v2.0.0` - Breaking changes
- `v1.0.0-beta` - Pre-release
- `v1.0.0-rc1` - Release candidate

## Permissions

### Required GitHub Permissions

The release job requires write access to repository contents:

```yaml
permissions:
  contents: write
```

This allows the workflow to:
- Create releases
- Upload release assets
- Tag releases

### Repository Settings

Ensure in repository settings:
1. Settings → Actions → General
2. "Workflow permissions" → "Read and write permissions" ✅
3. Or use fine-grained token with `contents: write`

## Workflow Dependencies

### Build Job Dependencies

The release job depends on ALL build jobs:

```yaml
create-release:
  needs:
    - linux-x64-cpu
    - linux-x64-vulkan
    - linux-x64-opencl
    # ... all 16 jobs
```

**Important**: If ANY build fails, the release will not be created.

### Partial Release Strategy

To create releases even if some builds fail, modify:

```yaml
create-release:
  needs:
    - linux-x64-cpu
    # ... only critical builds
  if: always()  # Run even if some jobs fail
```

## Troubleshooting

### Release Not Created

**Check**:
1. All 16 builds succeeded ✅
2. Tag format matches `v*.*.*` pattern
3. Workflow has `contents: write` permission
4. No duplicate release for same tag

### Missing Artifacts

**Check**:
1. Build job completed successfully
2. Artifact uploaded (check job logs)
3. Artifact name matches expected pattern
4. Download step includes all artifact names

### Invalid Checksums

**Verify**:
```bash
# Download release archive and checksums.txt
sha256sum -c checksums.txt
```

## Example Release Workflow

### Complete Release Process

```bash
# 1. Ensure all changes committed
git status

# 2. Create release tag
git tag -a v1.0.0 -m "Release v1.0.0 - Initial multi-backend release"

# 3. Push tag to trigger workflow
git push origin v1.0.0

# 4. Monitor workflow
# Go to Actions tab on GitHub

# 5. Wait for all 16 builds to complete (~30-45 minutes)

# 6. Release automatically created with:
#    - 16 platform archives (.zip)
#    - checksums.txt
#    - Auto-generated release notes
```

### Hotfix Release

```bash
# Fix critical bug
git commit -m "Fix critical memory leak"

# Create patch version tag
git tag v1.0.1
git push origin v1.0.1

# Workflow runs automatically
```

## CI/CD Integration

### Automated Version Bumping

Example GitHub Actions workflow for automatic versioning:

```yaml
name: Auto Version

on:
  push:
    branches: [master]

jobs:
  version:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Bump version
        run: |
          # Your version bumping logic
          NEW_VERSION=$(./scripts/bump-version.sh)
          git tag ${NEW_VERSION}
          git push origin ${NEW_VERSION}
```

## Release Artifacts Summary

| Platform | Archive Name | Size (approx) | Files |
|----------|--------------|---------------|-------|
| Linux x64 CPU | ggufx-linux-x64-cpu.zip | 2-3 MB | 3 (.so) |
| Linux x64 Vulkan | ggufx-linux-x64-vulkan.zip | 3-4 MB | 4 (.so) |
| Linux x64 OpenCL | ggufx-linux-x64-opencl.zip | 3-4 MB | 4 (.so) |
| Linux x64 ROCm | ggufx-linux-x64-rocm.zip | 4-5 MB | 4 (.so) |
| Linux ARM64 CPU | ggufx-linux-arm64-cpu.zip | 2-3 MB | 3 (.so) |
| Linux ARM32 CPU | ggufx-linux-arm32-cpu.zip | 2-3 MB | 3 (.so) |
| Android ARM64 CPU | ggufx-android-arm64-cpu.zip | 2-3 MB | 3 (.so) |
| iOS ARM64 CPU | ggufx-ios-arm64-cpu.zip | 3-4 MB | 4 (.dylib) |
| iOS ARM64 Metal | ggufx-ios-arm64-metal.zip | 4-5 MB | 5 (.dylib) |
| Windows x64 CPU | ggufx-windows-x64-cpu.zip | 2-3 MB | 3 (.dll) |
| Windows x64 Vulkan | ggufx-windows-x64-vulkan.zip | 3-4 MB | 4 (.dll) |
| Windows x64 OpenCL | ggufx-windows-x64-opencl.zip | 3-4 MB | 4 (.dll) |
| Windows x64 ROCm | ggufx-windows-x64-rocm.zip | 4-5 MB | 4 (.dll) |
| macOS ARM64 CPU | ggufx-macos-arm64-cpu.zip | 3-4 MB | 4 (.dylib) |
| macOS ARM64 Metal | ggufx-macos-arm64-metal.zip | 4-5 MB | 6 (.dylib + .metal) |
| macOS x64 CPU | ggufx-macos-x64-cpu.zip | 3-4 MB | 4 (.dylib) |

**Total release size**: ~50-60 MB (all platforms)

## Best Practices

### 1. Test Before Release
```bash
# Test builds locally before tagging
./build_multi_backend.sh

# Or trigger workflow_dispatch to test without creating release
```

### 2. Semantic Versioning
- Use `v{major}.{minor}.{patch}` format
- Document breaking changes in major versions
- Keep minor/patch versions backwards compatible

### 3. Changelog
- Maintain CHANGELOG.md
- Include in release notes
- Reference commit hashes for traceability

### 4. Pre-releases
```bash
# For testing before stable release
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

### 5. Verify Releases
- Download archives after release
- Test on target platforms
- Verify checksums match

---

**Status**: ✅ Configured for tag-based releases  
**Trigger**: Push tags matching `v*.*.*`  
**Output**: 16 platform archives + checksums  
**Ready**: ✅ For first release!
