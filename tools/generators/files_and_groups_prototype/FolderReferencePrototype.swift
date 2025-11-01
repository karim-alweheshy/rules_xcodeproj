#!/usr/bin/env swift

import Foundation

// MARK: - Prototype: Folder Reference Generator for rules_xcodeproj

/// This prototype demonstrates the size reduction possible by using folder references
/// instead of individual file references in the generated pbxproj file.
///
/// **Key Concept:** In BwB (Build with Bazel) mode, Bazel handles compilation and
/// generates index stores independently. The pbxproj file is primarily for:
/// 1. Xcode UI navigation
/// 2. Project structure visualization
///
/// Individual file references are NOT needed for:
/// - Compilation (Bazel does this)
/// - Indexing (imported from Bazel's index stores)
/// - Target membership (defined in BUILD files)

// MARK: - Sample Data

let sampleFilePaths = """
Sources/Core/Networking/HTTPClient.swift
Sources/Core/Networking/URLSessionManager.swift
Sources/Core/Networking/RequestBuilder.swift
Sources/Core/Networking/ResponseParser.swift
Sources/Core/Storage/Database.swift
Sources/Core/Storage/Cache.swift
Sources/Core/Storage/Persistence.swift
Sources/Core/Models/User.swift
Sources/Core/Models/Product.swift
Sources/Core/Models/Order.swift
Sources/Features/Authentication/LoginView.swift
Sources/Features/Authentication/SignUpView.swift
Sources/Features/Authentication/AuthViewModel.swift
Sources/Features/Catalog/ProductListView.swift
Sources/Features/Catalog/ProductDetailView.swift
Sources/Features/Catalog/CategoryView.swift
Sources/Features/Cart/CartView.swift
Sources/Features/Cart/CheckoutView.swift
Sources/Utils/Extensions/String+Extensions.swift
Sources/Utils/Extensions/Date+Extensions.swift
Sources/Utils/Helpers/Logger.swift
Sources/Utils/Helpers/Analytics.swift
external/swift_protobuf/Sources/SwiftProtobuf/Message.swift
external/swift_protobuf/Sources/SwiftProtobuf/Decoder.swift
external/swift_protobuf/Sources/SwiftProtobuf/Encoder.swift
bazel-out/darwin-fastbuild/bin/Generated/Protos/user.pb.swift
bazel-out/darwin-fastbuild/bin/Generated/Protos/product.pb.swift
bazel-out/darwin-fastbuild/bin/Generated/Resources/Assets.swift
"""

// MARK: - Current Approach (Individual Files)

func generateCurrentApproach(files: [String]) -> String {
    var output = """
    // !$*UTF8*$!
    {
    \tarchiveVersion = 1;
    \tclasses = {
    \t};
    \tobjectVersion = 55;
    \tobjects = {

    /* Begin PBXFileReference section */

    """

    var fileReferences: [(id: String, path: String, name: String)] = []
    for (index, filePath) in files.enumerated() {
        let identifier = String(format: "%024X", 0xFE000000 + index)
        let fileName = filePath.split(separator: "/").last.map(String.init) ?? filePath
        let fileType = fileName.hasSuffix(".swift") ? "sourcecode.swift" : "file"

        output += "\t\t\(identifier) /* \(fileName) */ = {isa = PBXFileReference; lastKnownFileType = \(fileType); path = \(fileName); sourceTree = \"<group>\"; };\n"
        fileReferences.append((identifier, filePath, fileName))
    }

    output += "/* End PBXFileReference section */\n\n"
    output += "/* Begin PBXGroup section */\n"

    // Create nested groups
    var groups: [String: [String]] = [:]
    for file in fileReferences {
        let components = file.path.split(separator: "/")
        if components.count > 1 {
            let parentPath = components.dropLast().joined(separator: "/")
            groups[parentPath, default: []].append(file.id)
        }
    }

    for (index, (groupPath, childIds)) in groups.sorted(by: { $0.key < $1.key }).enumerated() {
        let groupId = String(format: "%024X", 0xFF000000 + index)
        let groupName = groupPath.split(separator: "/").last.map(String.init) ?? groupPath
        output += "\t\t\(groupId) /* \(groupName) */ = {\n"
        output += "\t\t\tisa = PBXGroup;\n"
        output += "\t\t\tchildren = (\n"
        for childId in childIds {
            output += "\t\t\t\t\(childId),\n"
        }
        output += "\t\t\t);\n"
        output += "\t\t\tpath = \(groupName);\n"
        output += "\t\t\tsourceTree = \"<group>\";\n"
        output += "\t\t};\n"
    }

    output += "/* End PBXGroup section */\n"
    output += "\t};\n}\n"

    return output
}

// MARK: - New Approach (Folder References)

func generateFolderReferenceApproach(files: [String]) -> String {
    var output = """
    // !$*UTF8*$!
    {
    \tarchiveVersion = 1;
    \tclasses = {
    \t};
    \tobjectVersion = 55;
    \tobjects = {

    /* Begin PBXFileReference section */

    """

    // Extract top-level folders
    var topLevelFolders = Set<String>()
    for filePath in files {
        if let firstComponent = filePath.split(separator: "/").first {
            topLevelFolders.insert(String(firstComponent))
        }
    }

    // Create folder references (just the top-level folders!)
    for (index, folder) in topLevelFolders.sorted().enumerated() {
        let identifier = String(format: "%024X", 0xFE000000 + index)
        output += "\t\t\(identifier) /* \(folder) */ = {isa = PBXFileReference; lastKnownFileType = folder; path = \(folder); sourceTree = \"<group>\"; };\n"
    }

    output += "/* End PBXFileReference section */\n\n"
    output += "/* Begin PBXGroup section */\n"

    // Create single main group
    let mainGroupId = "FF00000000000000000000FF"
    output += "\t\t\(mainGroupId) /* Project */ = {\n"
    output += "\t\t\tisa = PBXGroup;\n"
    output += "\t\t\tchildren = (\n"
    for (index, folder) in topLevelFolders.sorted().enumerated() {
        let identifier = String(format: "%024X", 0xFE000000 + index)
        output += "\t\t\t\t\(identifier) /* \(folder) */,\n"
    }
    output += "\t\t\t);\n"
    output += "\t\t\tsourceTree = \"<group>\";\n"
    output += "\t\t};\n"

    output += "/* End PBXGroup section */\n"
    output += "\t};\n}\n"

    return output
}

// MARK: - Comparison

print("=" * 80)
print("FOLDER REFERENCE PROTOTYPE FOR rules_xcodeproj")
print("=" * 80)
print()

let files = sampleFilePaths.split(separator: "\n").map(String.init)
print("📁 Sample Project:")
print("   - \(files.count) source files")
print("   - Typical iOS app structure")
print()

print("-" * 80)
print("CURRENT APPROACH: Individual File References")
print("-" * 80)
let currentOutput = generateCurrentApproach(files: files)
print(currentOutput)
print()
print("📊 Statistics:")
print("   - Lines: \(currentOutput.split(separator: "\n").count)")
print("   - Size: \(currentOutput.count) bytes")
print()

print("-" * 80)
print("NEW APPROACH: Folder References")
print("-" * 80)
let folderOutput = generateFolderReferenceApproach(files: files)
print(folderOutput)
print()
print("📊 Statistics:")
print("   - Lines: \(folderOutput.split(separator: "\n").count)")
print("   - Size: \(folderOutput.count) bytes")
print()

print("=" * 80)
print("COMPARISON SUMMARY")
print("=" * 80)
let reduction = Double(currentOutput.count - folderOutput.count) / Double(currentOutput.count) * 100
print("🎯 Size Reduction: \(String(format: "%.1f", reduction))%")
print("📉 From: \(currentOutput.count) bytes → \(folderOutput.count) bytes")
print()

print("💡 KEY INSIGHTS:")
print()
print("1. Individual Files (\(files.count) references):")
print("   - Every file gets a PBXFileReference entry")
print("   - Every directory gets a PBXGroup with explicit children")
print("   - Result: ~\(currentOutput.split(separator: "\n").count) lines")
print()
print("2. Folder References (\(topLevelFolders.count) references):")
print("   - Only top-level folders get references")
print("   - Xcode automatically scans folder contents")
print("   - Result: ~\(folderOutput.split(separator: "\n").count) lines")
print()
print("3. For BwB Mode:")
print("   ✅ Index stores provided by Bazel (has all file-to-target info)")
print("   ✅ Compilation handled by Bazel (doesn't need individual refs)")
print("   ✅ File navigation still works (Xcode scans folder references)")
print("   ⚠️  Must build once with Bazel to generate index stores")
print()

print("📈 SCALING PROJECTION:")
print()
let realWorldFiles = [100, 500, 1000, 2000, 5000]
for fileCount in realWorldFiles {
    let currentSize = fileCount * 150 // ~150 bytes per file reference + group entry
    let folderSize = 5 * 120 // ~5 top-level folders * 120 bytes each
    let savings = Double(currentSize - folderSize) / Double(currentSize) * 100
    print("   \(String(format: "%5d", fileCount)) files: \(String(format: "%6d", currentSize))B → \(String(format: "%5d", folderSize))B (saves \(String(format: "%.1f", savings))%)")
}
print()

print("=" * 80)
print("NEXT STEPS FOR INTEGRATION:")
print("=" * 80)
print()
print("1. Modify CreateGroupChild.swift:")
print("   - Add logic to detect when to use folder references")
print("   - Create PBXFileReference with lastKnownFileType = folder")
print()
print("2. Skip individual file enumeration:")
print("   - Don't iterate through PathTreeNode children")
print("   - Just reference the parent folder")
print()
print("3. Empty PBXSourcesBuildPhase:")
print("   - In BwB mode, build files handled by Bazel")
print("   - Can leave Sources phase empty or minimal")
print()
print("4. Configuration flag:")
print("   - Add use_folder_references = True to xcodeproj rule")
print("   - Default to False for backwards compatibility")
print()
print("=" * 80)

// Helper to calculate top-level folders
var topLevelFolders: Set<String> {
    var folders = Set<String>()
    for filePath in files {
        if let firstComponent = filePath.split(separator: "/").first {
            folders.insert(String(firstComponent))
        }
    }
    return folders
}
