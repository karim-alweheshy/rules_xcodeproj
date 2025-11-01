#!/usr/bin/env python3

"""
Folder Reference Prototype for rules_xcodeproj

This prototype demonstrates the size reduction possible by using folder references
instead of individual file references in the generated pbxproj file.

**Key Concept:** In BwB (Build with Bazel) mode, Bazel handles compilation and
generates index stores independently. The pbxproj file is primarily for:
1. Xcode UI navigation
2. Project structure visualization

Individual file references are NOT needed for:
- Compilation (Bazel does this)
- Indexing (imported from Bazel's index stores)
- Target membership (defined in BUILD files)
"""

# Sample file paths representing a typical iOS app
SAMPLE_FILE_PATHS = """
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
""".strip()


def generate_current_approach(files):
    """Generate pbxproj with individual file references (current approach)"""
    output = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {",
        "\t};",
        "\tobjectVersion = 55;",
        "\tobjects = {",
        "",
        "/* Begin PBXFileReference section */",
    ]

    file_references = []
    for index, file_path in enumerate(files):
        identifier = f"{0xFE000000 + index:024X}"
        file_name = file_path.split("/")[-1]
        file_type = "sourcecode.swift" if file_name.endswith(".swift") else "file"

        output.append(
            f'\t\t{identifier} /* {file_name} */ = '
            f'{{isa = PBXFileReference; lastKnownFileType = {file_type}; '
            f'path = {file_name}; sourceTree = "<group>"; }};'
        )
        file_references.append((identifier, file_path, file_name))

    output.append("/* End PBXFileReference section */")
    output.append("")
    output.append("/* Begin PBXGroup section */")

    # Create nested groups
    groups = {}
    for file_id, file_path, _ in file_references:
        components = file_path.split("/")
        if len(components) > 1:
            parent_path = "/".join(components[:-1])
            if parent_path not in groups:
                groups[parent_path] = []
            groups[parent_path].append(file_id)

    for index, (group_path, child_ids) in enumerate(sorted(groups.items())):
        group_id = f"{0xFF000000 + index:024X}"
        group_name = group_path.split("/")[-1]

        output.append(f"\t\t{group_id} /* {group_name} */ = {{")
        output.append("\t\t\tisa = PBXGroup;")
        output.append("\t\t\tchildren = (")
        for child_id in child_ids:
            output.append(f"\t\t\t\t{child_id},")
        output.append("\t\t\t);")
        output.append(f"\t\t\tpath = {group_name};")
        output.append('\t\t\tsourceTree = "<group>";')
        output.append("\t\t};")

    output.append("/* End PBXGroup section */")
    output.append("\t};")
    output.append("}")

    return "\n".join(output)


def generate_folder_reference_approach(files):
    """Generate pbxproj with folder references (new approach)"""
    output = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {",
        "\t};",
        "\tobjectVersion = 55;",
        "\tobjects = {",
        "",
        "/* Begin PBXFileReference section */",
    ]

    # Extract top-level folders
    top_level_folders = sorted(set(f.split("/")[0] for f in files))

    # Create folder references (just the top-level folders!)
    for index, folder in enumerate(top_level_folders):
        identifier = f"{0xFE000000 + index:024X}"
        output.append(
            f'\t\t{identifier} /* {folder} */ = '
            f'{{isa = PBXFileReference; lastKnownFileType = folder; '
            f'path = {folder}; sourceTree = "<group>"; }};'
        )

    output.append("/* End PBXFileReference section */")
    output.append("")
    output.append("/* Begin PBXGroup section */")

    # Create single main group
    main_group_id = "FF00000000000000000000FF"
    output.append(f"\t\t{main_group_id} /* Project */ = {{")
    output.append("\t\t\tisa = PBXGroup;")
    output.append("\t\t\tchildren = (")
    for index, folder in enumerate(top_level_folders):
        identifier = f"{0xFE000000 + index:024X}"
        output.append(f"\t\t\t\t{identifier} /* {folder} */,")
    output.append("\t\t\t);")
    output.append('\t\t\tsourceTree = "<group>";')
    output.append("\t\t};")

    output.append("/* End PBXGroup section */")
    output.append("\t};")
    output.append("}")

    return "\n".join(output)


def main():
    print("=" * 80)
    print("FOLDER REFERENCE PROTOTYPE FOR rules_xcodeproj")
    print("=" * 80)
    print()

    files = [f for f in SAMPLE_FILE_PATHS.split("\n") if f.strip()]
    print(f"📁 Sample Project:")
    print(f"   - {len(files)} source files")
    print(f"   - Typical iOS app structure")
    print()

    print("-" * 80)
    print("CURRENT APPROACH: Individual File References")
    print("-" * 80)
    current_output = generate_current_approach(files)
    print(current_output)
    print()
    print(f"📊 Statistics:")
    print(f"   - Lines: {len(current_output.splitlines())}")
    print(f"   - Size: {len(current_output)} bytes")
    print()

    print("-" * 80)
    print("NEW APPROACH: Folder References")
    print("-" * 80)
    folder_output = generate_folder_reference_approach(files)
    print(folder_output)
    print()
    print(f"📊 Statistics:")
    print(f"   - Lines: {len(folder_output.splitlines())}")
    print(f"   - Size: {len(folder_output)} bytes")
    print()

    print("=" * 80)
    print("COMPARISON SUMMARY")
    print("=" * 80)
    reduction = (len(current_output) - len(folder_output)) / len(current_output) * 100
    print(f"🎯 Size Reduction: {reduction:.1f}%")
    print(f"📉 From: {len(current_output)} bytes → {len(folder_output)} bytes")
    print()

    top_level_folders = set(f.split("/")[0] for f in files)
    print("💡 KEY INSIGHTS:")
    print()
    print(f"1. Individual Files ({len(files)} references):")
    print(f"   - Every file gets a PBXFileReference entry")
    print(f"   - Every directory gets a PBXGroup with explicit children")
    print(f"   - Result: ~{len(current_output.splitlines())} lines")
    print()
    print(f"2. Folder References ({len(top_level_folders)} references):")
    print(f"   - Only top-level folders get references")
    print(f"   - Xcode automatically scans folder contents")
    print(f"   - Result: ~{len(folder_output.splitlines())} lines")
    print()
    print("3. For BwB Mode:")
    print("   ✅ Index stores provided by Bazel (has all file-to-target info)")
    print("   ✅ Compilation handled by Bazel (doesn't need individual refs)")
    print("   ✅ File navigation still works (Xcode scans folder references)")
    print("   ⚠️  Must build once with Bazel to generate index stores")
    print()

    print("📈 SCALING PROJECTION:")
    print()
    real_world_files = [100, 500, 1000, 2000, 5000]
    for file_count in real_world_files:
        current_size = file_count * 150  # ~150 bytes per file reference + group entry
        folder_size = 5 * 120  # ~5 top-level folders * 120 bytes each
        savings = (current_size - folder_size) / current_size * 100
        print(
            f"   {file_count:5d} files: {current_size:6d}B → {folder_size:5d}B "
            f"(saves {savings:.1f}%)"
        )
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


if __name__ == "__main__":
    main()
