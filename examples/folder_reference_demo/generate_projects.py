#!/usr/bin/env python3
"""
Generate realistic Xcode project files demonstrating folder reference feature.

This script creates two .xcodeproj files:
1. TestProject_Before - Traditional approach (enumerate all files)
2. TestProject_After - Folder reference approach (single folder reference)
"""

import os
import hashlib
from pathlib import Path

def generate_identifier(path, suffix=""):
    """Generate a unique Xcode identifier."""
    content = f"{path}{suffix}"
    hash_obj = hashlib.md5(content.encode())
    hash_hex = hash_obj.hexdigest()[:22].upper()
    return f"FE{hash_hex}"

def scan_source_files(sources_dir):
    """Scan and return list of source files."""
    files = []
    sources_path = Path(sources_dir)
    if sources_path.exists():
        for file in sorted(sources_path.glob("*.swift")):
            files.append(file.name)
    return files

def generate_before_project(source_files, output_path):
    """Generate project with individual file references (old approach)."""

    # Generate identifiers for each file
    file_refs = []
    for filename in source_files:
        file_id = generate_identifier(f"Sources/{filename}")
        file_refs.append({
            'id': file_id,
            'name': filename,
            'path': filename
        })

    sources_group_id = generate_identifier("Sources", "group")
    test_project_group_id = generate_identifier("test_project", "group")
    main_group_id = "FF0000000000000000000003"
    project_id = "FF0000000000000000000001"
    config_list_id = "FF0000000000000000000002"
    products_group_id = "FF0000000000000000000004"

    # Build file references section
    file_refs_section = "/* Begin PBXFileReference section */\n"
    for ref in file_refs:
        file_refs_section += f"\t\t{ref['id']} /* {ref['name']} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {ref['name']}; sourceTree = \"<group>\"; }};\n"
    file_refs_section += "/* End PBXFileReference section */\n"

    # Build group section with all files listed
    sources_children = ",\n\t\t\t\t".join([f"{ref['id']} /* {ref['name']} */" for ref in file_refs])

    group_section = f"""/* Begin PBXGroup section */
\t\t{main_group_id} /* TestProject */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{test_project_group_id} /* test_project */,
\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tname = TestProject;
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{test_project_group_id} /* test_project */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{sources_group_id} /* Sources */,
\t\t\t);
\t\t\tpath = test_project;
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{sources_group_id} /* Sources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{sources_children}
\t\t\t);
\t\t\tpath = Sources;
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = \"<group>\";
\t\t}};
/* End PBXGroup section */
"""

    project_content = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

{file_refs_section}

{group_section}

/* Begin PBXProject section */
\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t}};
\t\t\tbuildConfigurationList = {config_list_id} /* Build configuration list for PBXProject "TestProject_Before" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\tBase,
\t\t\t\ten,
\t\t\t);
\t\t\tmainGroup = {main_group_id} /* TestProject */;
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = \"\";
\t\t\tprojectRoot = \"\";
\t\t\ttargets = (
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin XCBuildConfiguration section */
\t\t{config_list_id}01 /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{config_list_id}02 /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{config_list_id} /* Build configuration list for PBXProject "TestProject_Before" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{config_list_id}01 /* Debug */,
\t\t\t\t{config_list_id}02 /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {project_id} /* Project object */;
}}
"""

    # Write to file
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(project_content)

    print(f"✓ Generated: {output_path}")
    print(f"  - {len(file_refs)} file references")
    print(f"  - {len(source_files)} files in Sources group")
    print(f"  - Size: {len(project_content)} bytes")

def generate_after_project(source_files, output_path):
    """Generate project with folder reference (new approach)."""

    sources_folder_id = generate_identifier("Sources", "folder")
    test_project_group_id = generate_identifier("test_project", "group")
    main_group_id = "FF0000000000000000000003"
    project_id = "FF0000000000000000000001"
    config_list_id = "FF0000000000000000000002"
    products_group_id = "FF0000000000000000000004"

    # Single folder reference
    file_refs_section = f"""/* Begin PBXFileReference section */
\t\t{sources_folder_id} /* Sources */ = {{isa = PBXFileReference; lastKnownFileType = folder; path = Sources; sourceTree = \"<group>\"; }};
/* End PBXFileReference section */
"""

    # Group section - Sources appears as single child (folder reference)
    group_section = f"""/* Begin PBXGroup section */
\t\t{main_group_id} /* TestProject */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{test_project_group_id} /* test_project */,
\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tname = TestProject;
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{test_project_group_id} /* test_project */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{sources_folder_id} /* Sources */,
\t\t\t);
\t\t\tpath = test_project;
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = \"<group>\";
\t\t}};
/* End PBXGroup section */
"""

    project_content = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

{file_refs_section}

{group_section}

/* Begin PBXProject section */
\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t}};
\t\t\tbuildConfigurationList = {config_list_id} /* Build configuration list for PBXProject "TestProject_After" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\tBase,
\t\t\t\ten,
\t\t\t);
\t\t\tmainGroup = {main_group_id} /* TestProject */;
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = \"\";
\t\t\tprojectRoot = \"\";
\t\t\ttargets = (
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin XCBuildConfiguration section */
\t\t{config_list_id}01 /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{config_list_id}02 /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{config_list_id} /* Build configuration list for PBXProject "TestProject_After" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{config_list_id}01 /* Debug */,
\t\t\t\t{config_list_id}02 /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {project_id} /* Project object */;
}}
"""

    # Write to file
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(project_content)

    print(f"✓ Generated: {output_path}")
    print(f"  - 1 folder reference (replaces {len(source_files)} files)")
    print(f"  - Xcode will scan Sources/ automatically")
    print(f"  - Size: {len(project_content)} bytes")

def main():
    # Get script directory
    script_dir = Path(__file__).parent
    sources_dir = script_dir / "test_project" / "Sources"

    print("=" * 60)
    print("Generating Xcode Projects - Folder Reference Demo")
    print("=" * 60)

    # Scan source files
    source_files = scan_source_files(sources_dir)
    print(f"\nFound {len(source_files)} source files in test_project/Sources/")

    # Generate BEFORE project (traditional approach)
    print("\n" + "-" * 60)
    print("Generating BEFORE project (individual file references)...")
    print("-" * 60)
    before_output = script_dir / "TestProject_Before.xcodeproj" / "project.pbxproj"
    generate_before_project(source_files, before_output)

    # Generate AFTER project (folder reference approach)
    print("\n" + "-" * 60)
    print("Generating AFTER project (folder reference)...")
    print("-" * 60)
    after_output = script_dir / "TestProject_After.xcodeproj" / "project.pbxproj"
    generate_after_project(source_files, after_output)

    # Calculate savings
    before_size = os.path.getsize(before_output)
    after_size = os.path.getsize(after_output)
    savings = ((before_size - after_size) / before_size) * 100

    print("\n" + "=" * 60)
    print("COMPARISON")
    print("=" * 60)
    print(f"Before: {before_size:,} bytes ({len(source_files)} file references)")
    print(f"After:  {after_size:,} bytes (1 folder reference)")
    print(f"Savings: {savings:.1f}% reduction ({before_size - after_size:,} bytes)")
    print("\nYou can now:")
    print("  1. Open both .xcodeproj files in Xcode")
    print("  2. Compare project.pbxproj files")
    print("  3. See blue folder (📁) vs yellow folder (📂)")
    print("=" * 60)

if __name__ == "__main__":
    main()
