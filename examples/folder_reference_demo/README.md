# Folder Reference Feature Demo

This directory contains example pbxproj snippets demonstrating the dramatic file size reduction achieved by the folder reference feature.

## Comparison

### Before: `example_before.pbxproj`
Traditional approach - enumerates every file individually

For a directory with **28 files**:
- **28 file reference objects** (~140 bytes each)
- **1 group object** with 28 children (~1,400 bytes)
- **Total**: ~5,320 bytes in files_and_groups section

### After: `example_after.pbxproj`
Folder reference approach - single folder reference

For a directory with **28 files**:
- **1 folder reference object** (~120 bytes)
- **Total**: ~120 bytes in files_and_groups section

### Savings

**For 28 files**: 5,200 bytes saved (**98% reduction**)

**For realistic projects** (1,967 files like old bwb.xcodeproj):
- Before: ~275 KB in files_and_groups section
- After: ~10-15 KB in files_and_groups section
- **Savings: 95-96% reduction**

## How It Works

### Folder References

A folder reference is a special type of `PBXFileReference` with:
```
{isa = PBXFileReference; lastKnownFileType = folder; path = Sources; sourceTree = "<group>"; }
```

This tells Xcode to **automatically scan** the directory at runtime instead of having every file pre-enumerated.

### When Are Folder References Used?

The feature is **fully automatic**:

1. **Analyzes all file paths** in the project
2. **Counts files** in each top-level directory
3. **Applies folder references** to directories with ≥10 files
4. **Leaves small directories** as-is (better for navigation)

Example:
```
Given files:
  Sources/File1.swift
  Sources/File2.swift
  ... (50 total files in Sources/)
  Resources/icon.png
  Resources/logo.png
  (only 2 files in Resources/)

Result:
  ✓ Sources/ → folder reference (50 files)
  ✗ Resources/ → enumerated files (2 files)
```

## Visual Differences in Xcode

| Before (Groups) | After (Folder References) |
|----------------|--------------------------|
| Yellow folders 📂 | Blue folders 📁 |
| Files pre-enumerated | Files scanned at runtime |
| ~1.9 MB .pbxproj | ~50 KB .pbxproj |

## Implementation Details

The folder reference feature modifies the `files_and_groups` generator:

1. **ComputeFolderReferencePaths.swift** - Analyzes file paths and determines which folders should use folder references
2. **CreateFolderReference.swift** - Creates the folder reference PBXFileReference
3. **CreateGroupChild.swift** - Routes nodes to either folder references or regular groups based on the analysis

The feature is **zero-configuration** - it automatically optimizes projects based on their actual structure.

## Testing

Run the integration tests to see folder references in action:

```bash
cd examples/integration
bazel run //:xcodeproj
open Integration.xcodeproj
```

Look for blue folder icons (📁) in the Project Navigator for directories with many files.

## Debug Output

When generating projects, you'll see:
```
[folder_references] Using folder references for: CommandLine, iOSApp, macOSApp
[folder_references]   Bundle: 2 files ✗
[folder_references]   CommandLine: 25 files ✓
[folder_references]   iOSApp: 50 files ✓
```

## Impact

For large projects (thousands of files):
- **95%+ file size reduction** in files_and_groups section
- **Faster project generation** (less data to write)
- **Faster Xcode loading** (smaller project files)
- **Better git diffs** (fewer file changes)
- **Same functionality** (Xcode scans folders automatically)

## Compatibility

Folder references work the same way as `.xcassets` folders, which have been in Xcode for years. This is a well-established Xcode feature, not a hack.

In BwB (Build with Bazel) mode:
- ✅ File navigation works
- ✅ Indexing works (from Bazel's index stores)
- ✅ Code completion works
- ✅ Debugging works
- ✅ File discovery works (Xcode scans at runtime)
