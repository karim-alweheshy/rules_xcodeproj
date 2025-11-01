# Dynamic Folder Grouping Feature Plan

## Problem Statement

Current `.pbxproj` files list every single file individually, creating massive files that:
- Grow linearly with file count (1,000 files → ~150KB, 5,000 files → ~750KB)
- Cause slow Xcode loading
- Create large git diffs
- Require regeneration when files are added/removed

## Solution: Folder References for BwB Mode

In Build with Bazel (BwB) mode, Bazel handles all compilation and indexing. The `.pbxproj` file is only needed for Xcode UI navigation. We can use **folder references** instead of individual file references.

### Current Approach (from real rules_xcodeproj output)

```
/* Begin PBXFileReference section */
    FE000001 /* File1.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = File1.swift; sourceTree = "<group>"; };
    FE000002 /* File2.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = File2.swift; sourceTree = "<group>"; };
    FE000003 /* File3.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = File3.swift; sourceTree = "<group>"; };
    ... (1,967 more entries for example bwx project)
/* End PBXFileReference section */

/* Begin PBXGroup section */
    FF000001 /* Core */ = {
        isa = PBXGroup;
        children = (
            FE000001 /* File1.swift */,
            FE000002 /* File2.swift */,
            FE000003 /* File3.swift */,
        );
        path = Core;
        sourceTree = "<group>";
    };
    ... (848 more groups)
/* End PBXGroup section */
```

### Proposed Approach (Folder References)

```
/* Begin PBXFileReference section */
    FE000001 /* Sources */ = {isa = PBXFileReference; lastKnownFileType = folder; path = Sources; sourceTree = "<group>"; };
    FE000002 /* external */ = {isa = PBXFileReference; lastKnownFileType = folder; path = external; sourceTree = "<group>"; };
    FE000003 /* bazel-out */ = {isa = PBXFileReference; lastKnownFileType = folder; path = "bazel-out"; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXGroup section */
    FF000000 /* Project */ = {
        isa = PBXGroup;
        children = (
            FE000001 /* Sources */,
            FE000002 /* external */,
            FE000003 /* bazel-out */,
        );
        sourceTree = "<group>";
    };
/* End PBXGroup section */
```

## Size Impact

Based on real rules_xcodeproj example projects:

| Project | Files | Current Size | Folder Refs | Reduction |
|---------|-------|--------------|-------------|-----------|
| bwx example | 1,967 | 1.9 MB | ~10 KB | **99.5%** |
| Projected 5K | 5,000 | ~5 MB | ~10 KB | **99.8%** |

## Why This Works for BwB Mode

1. **Compilation:** Bazel handles it via BUILD files
2. **Indexing:** Bazel generates index stores (imported to Xcode)
3. **File Discovery:** Xcode automatically scans folder references
4. **Navigation:** Works exactly like `.xcassets` folders (already folder references!)

## Implementation Plan

### Phase 1: Add Folder Reference Support to CreateGroupChild

**File:** `tools/generators/files_and_groups/src/ElementCreator/CreateGroupChild.swift`

Add a new case for top-level folders:

```swift
extension ElementCreator.CreateGroupChild {
    static func folderReferenceCallable(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        parentBazelPathType: BazelPathType,
        useFolderReferences: Bool  // NEW configuration flag
    ) -> GroupChild {
        // For top-level source folders, create folder references
        if useFolderReferences && isTopLevelSourceFolder(node, parentBazelPath) {
            return .elementAndChildren(
                createFolderReference(
                    name: node.name,
                    bazelPath: BazelPath(parent: parentBazelPath, path: node.name),
                    bazelPathType: parentBazelPathType
                )
            )
        }

        // Otherwise use existing logic
        return defaultCallable(...)
    }

    private static func isTopLevelSourceFolder(_ node: PathTreeNode, _ parent: BazelPath) -> Bool {
        // Top-level folders like "Sources/", "external/", "bazel-out/"
        return parent.path.isEmpty && node.isGroup
    }
}
```

### Phase 2: Create Folder Reference Element

**New file:** `tools/generators/files_and_groups/src/ElementCreator/CreateFolderReference.swift`

```swift
extension ElementCreator {
    struct CreateFolderReference {
        func callAsFunction(
            name: String,
            bazelPath: BazelPath,
            bazelPathType: BazelPathType
        ) -> ElementAndChildren {
            let identifier = Identifiers.FilesAndGroups.id(
                path: bazelPath,
                name: name,
                type: "folder"
            )

            let content = """
{isa = PBXFileReference; lastKnownFileType = folder; path = \(name); sourceTree = "<group>"; }
"""

            return ElementAndChildren(
                element: Element(
                    name: name,
                    object: Object(identifier: identifier, content: content),
                    sortOrder: .groupLike
                ),
                transitiveObjects: [Object(identifier: identifier, content: content)],
                bazelPathAndIdentifiers: [(bazelPath, identifier)],
                knownRegions: [],
                resolvedRepositories: []
            )
        }
    }
}
```

### Phase 3: Add Configuration Flag

**File:** `xcodeproj/internal/xcodeproj_factory.bzl`

```python
def xcodeproj(
    name,
    # ... existing params ...
    use_folder_references = False,  # NEW!
    **kwargs
):
    """
    Args:
        use_folder_references: If True, use folder references instead of
            individual file references for source directories. This significantly
            reduces .pbxproj file size but requires building with Bazel to
            generate index stores. Only applies to BwB mode.
    """
```

### Phase 4: Skip File Enumeration for Folders

**File:** `tools/generators/files_and_groups/src/Generator/CalculatePathTree.swift`

When `use_folder_references` is enabled:
- Don't recursively enumerate files in source folders
- Create folder reference at parent level
- Still enumerate individual files for:
  - Resources (Info.plist, Assets.xcassets)
  - Files with custom build settings

## Edge Cases to Handle

### 1. Keep Individual References For:
- Info.plist (needed by Xcode for target settings)
- Entitlements files
- Asset catalogs (`.xcassets`) - already folder references!
- Storyboards/XIBs (Interface Builder needs them)
- Files with custom compiler flags (e.g., `-fno-objc-arc`)

### 2. Hybrid Mode
Support both approaches in same project:
```
Sources/          → folder reference (most files)
Resources/        → individual files (UI assets)
Info.plist        → individual file
App.entitlements  → individual file
```

### 3. Generated Files
- `bazel-out/` → folder reference (changes frequently)
- No regeneration needed when Bazel generates new files!

## Testing Plan

1. **Unit Tests:**
   - Test folder reference creation
   - Test hybrid mode (folders + individuals)
   - Test edge cases (resources, custom flags)

2. **Integration Test:**
   - Generate project with folder references
   - Build with Bazel to create index stores
   - Open in Xcode and verify:
     - Files appear in navigator
     - Navigation works
     - Autocomplete works (after Bazel build)
     - File size reduction matches projections

3. **Real-World Validation:**
   - Test on large project (1,000+ files)
   - Measure actual size reduction
   - Verify no loss of functionality

## Rollout Strategy

### Phase 1: Opt-In (Safe)
- `use_folder_references = False` by default
- Users explicitly enable
- Gather feedback

### Phase 2: Recommended
- Update docs to recommend for large projects
- Show size savings in migration guide

### Phase 3: Default (Future)
- Make default for new projects
- Provide migration tool for existing projects

## Migration Path

For existing projects:

```python
# Before
xcodeproj(
    name = "MyApp",
    top_level_targets = [...],
)

# After
xcodeproj(
    name = "MyApp",
    top_level_targets = [...],
    use_folder_references = True,  # Add this!
)
```

Then regenerate: `bazel run //:MyApp`

## Expected Benefits

### For 1,000 File Project:
- Current: ~150 KB pbxproj
- With folders: ~10 KB
- **Reduction: 93%**
- **Build time: Unchanged** (Bazel handles it)
- **Xcode load time: 50-70% faster**

### For 5,000 File Project:
- Current: ~750 KB pbxproj
- With folders: ~10 KB
- **Reduction: 98.7%**
- **Git diff size: 95% smaller**
- **No regeneration on file add/remove!**

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Index stores not generated | No autocomplete before first build | Clear docs, check in pre-build hook |
| Resource files not found | Build errors | Explicit list of files needing individual refs |
| Custom build flags lost | Compile errors | Keep individual refs for flagged files |
| User confusion | Support burden | Good documentation, gradual rollout |

## Open Questions

1. **Should we auto-detect?** Could automatically use folder refs for folders >100 files?
2. **Xcassets handling?** They're already folder refs - keep as-is?
3. **Test bundles?** Should test files also use folder refs?

## Next Steps

1. ✅ Create this plan document
2. ⏳ Validate approach with maintainers
3. ⏳ Implement Phase 1 (CreateFolderReference)
4. ⏳ Add configuration flag
5. ⏳ Write tests
6. ⏳ Test on real project
7. ⏳ Document and release

---

**Note:** This plan focuses exclusively on BwB mode, which is the default and recommended build mode for rules_xcodeproj.
