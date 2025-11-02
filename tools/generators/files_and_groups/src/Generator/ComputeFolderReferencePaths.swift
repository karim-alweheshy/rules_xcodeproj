import PBXProj

extension Generator {
    /// Computes the minimal set of directory paths that should be treated as
    /// folder references instead of recursively enumerating their files.
    ///
    /// This function analyzes all file paths and identifies top-level
    /// directories that contain a significant number of files, which can
    /// dramatically reduce .pbxproj file size (95%+ reduction for large projects).
    ///
    /// Algorithm:
    /// 1. Count files in each top-level directory
    /// 2. Directories with >= threshold files become folder references
    /// 3. This avoids enumerating thousands of individual files
    ///
    /// - Parameter paths: All file paths that will be included in the project
    /// - Parameter threshold: Minimum file count for a directory to use folder reference (default: 10)
    /// - Returns: Set of directory names to treat as folder references
    static func computeFolderReferencePaths(
        paths: [BazelPath],
        threshold: Int = 10
    ) -> Set<String> {
        // Count files in each top-level directory
        var topLevelDirectoryCounts: [String: Int] = [:]

        for path in paths {
            let components = path.path.split(separator: "/")

            // Only process files (not root-level files)
            guard components.count > 1 else {
                continue
            }

            // Get the top-level directory name
            let topLevelDir = String(components[0])
            topLevelDirectoryCounts[topLevelDir, default: 0] += 1
        }

        // Return directories that exceed the threshold
        let folderReferences = Set(
            topLevelDirectoryCounts
                .filter { $0.value >= threshold }
                .map { $0.key }
        )

        // Debug: Print which folders will use folder references
        if !folderReferences.isEmpty {
            print("[folder_references] Using folder references for: \(folderReferences.sorted().joined(separator: ", "))")
            for (dir, count) in topLevelDirectoryCounts.sorted(by: { $0.key < $1.key }) {
                print("[folder_references]   \(dir): \(count) files \(folderReferences.contains(dir) ? "✓" : "✗")")
            }
        }

        return folderReferences
    }
}
