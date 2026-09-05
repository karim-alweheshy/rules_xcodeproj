import XCTest
@testable import target_build_settings

final class PreviewResourceBuildSettingsTests: XCTestCase {
    func test_resourceBundlePathsAreEscapedAndKeepFollowingArgumentsAligned() async throws {
        let paths = #""$(BAZEL_OUT)/First.bundle" "$(BAZEL_OUT)/Bundle With Spaces.bundle""#

        let settings = try await buildSettings(resourceBundlePaths: paths)

        XCTAssertEqual(
            settings["PREVIEW_RESOURCE_BUNDLE_PATHS"],
            #""\"$(BAZEL_OUT)/First.bundle\" \"$(BAZEL_OUT)/Bundle With Spaces.bundle\"""#
        )
        XCTAssertEqual(
            settings["PREVIEWS_SWIFT_INCLUDE__YES"],
            #""-I$(BAZEL_OUT)/preview-includes""#
        )
    }

    func test_emptyResourceBundlePathsOmitSetting() async throws {
        let settings = try await buildSettings(resourceBundlePaths: "")

        XCTAssertNil(settings["PREVIEW_RESOURCE_BUNDLE_PATHS"])
        XCTAssertNotNil(settings["PREVIEWS_SWIFT_INCLUDE__YES"])
    }

    private func buildSettings(
        resourceBundlePaths: String
    ) async throws -> [String: String] {
        let arguments = [
            "", // device-family
            "false", // extension-safe
            "false", // generates-dsyms
            "", // info-plist
            "", // entitlements
            "", // certificate-name
            "", // provisioning-profile-name
            "", // team-id
            "false", // provisioning-profile-is-xcode-managed
            "", // previews-framework-paths
            resourceBundlePaths,
            "bazel-out/preview-includes",
            "false", // separate-index-build-output-base
            "swift_worker", "swiftc", "-Onone", "---",
            "---", // no C arguments
            "---", // no C++ arguments
        ]
        let result = try await Generator.Environment.default.processArgs(
            rawArguments: arguments[...],
            generateBuildSettings: true,
            includeSelfSwiftDebugSettings: true,
            transitiveSwiftDebugSettingPaths: []
        )
        return Dictionary(uniqueKeysWithValues: result.buildSettings)
    }
}
