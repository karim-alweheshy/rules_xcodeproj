import XCTest
@testable import files_and_groups
import PBXProj

final class ComputeFolderReferencePathsTests: XCTestCase {
    func test_emptyPaths() {
        // Given
        let paths: [BazelPath] = []

        // When
        let result = Generator.computeFolderReferencePaths(
            paths: paths,
            threshold: 10
        )

        // Then
        XCTAssertEqual(result, [])
    }

    func test_belowThreshold() {
        // Given
        let paths: [BazelPath] = [
            BazelPath("Sources/File1.swift"),
            BazelPath("Sources/File2.swift"),
            BazelPath("Sources/File3.swift"),
        ]

        // When
        let result = Generator.computeFolderReferencePaths(
            paths: paths,
            threshold: 10
        )

        // Then
        XCTAssertEqual(result, [], "Should not use folder reference with only 3 files")
    }

    func test_aboveThreshold() {
        // Given
        let paths: [BazelPath] = (1...15).map {
            BazelPath("Sources/File\($0).swift")
        }

        // When
        let result = Generator.computeFolderReferencePaths(
            paths: paths,
            threshold: 10
        )

        // Then
        XCTAssertEqual(result, ["Sources"], "Should use folder reference with 15 files")
    }

    func test_multipleDirectories() {
        // Given
        var paths: [BazelPath] = []

        // Sources: 50 files (above threshold)
        paths += (1...50).map { BazelPath("Sources/File\($0).swift") }

        // Tests: 20 files (above threshold)
        paths += (1...20).map { BazelPath("Tests/Test\($0).swift") }

        // Resources: 5 files (below threshold)
        paths += (1...5).map { BazelPath("Resources/Asset\($0).png") }

        // When
        let result = Generator.computeFolderReferencePaths(
            paths: paths,
            threshold: 10
        )

        // Then
        XCTAssertEqual(
            result.sorted(),
            ["Sources", "Tests"].sorted(),
            "Should only use folder references for Sources and Tests, not Resources"
        )
    }

    func test_rootLevelFiles() {
        // Given
        let paths: [BazelPath] = [
            BazelPath("README.md"),
            BazelPath("BUILD"),
            BazelPath("WORKSPACE"),
        ]

        // When
        let result = Generator.computeFolderReferencePaths(
            paths: paths,
            threshold: 10
        )

        // Then
        XCTAssertEqual(result, [], "Should not create folder references for root-level files")
    }

    func test_nestedDirectories() {
        // Given
        let paths: [BazelPath] = (1...25).map {
            BazelPath("Sources/App/Views/File\($0).swift")
        }

        // When
        let result = Generator.computeFolderReferencePaths(
            paths: paths,
            threshold: 10
        )

        // Then
        XCTAssertEqual(
            result,
            ["Sources"],
            "Should use top-level directory, not nested subdirectories"
        )
    }

    func test_customThreshold() {
        // Given
        let paths: [BazelPath] = (1...15).map {
            BazelPath("Sources/File\($0).swift")
        }

        // When (threshold = 20)
        let result = Generator.computeFolderReferencePaths(
            paths: paths,
            threshold: 20
        )

        // Then
        XCTAssertEqual(
            result,
            [],
            "Should respect custom threshold of 20"
        )
    }
}
