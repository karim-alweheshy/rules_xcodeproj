load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load(
    ":dual_aspect_tests.bzl",
    "dual_aspect_resource_bundle_test",
    "multiple_generators_resource_bundle_test",
)

apple_resource_bundle(
    name = "NestedResources",
    resources = ["Nested/value.txt"],
)

apple_resource_bundle(
    name = "RawResources",
    bundle_id = "com.example.rules-xcodeproj.dual-aspect",
    infoplists = ["Info.plist"],
    resources = glob(["Resources/**"]) + [":NestedResources"],
)

dual_aspect_resource_bundle_test(
    name = "dual_aspect_resource_bundle",
    target = ":RawResources",
)

multiple_generators_resource_bundle_test(
    name = "multiple_generators_resource_bundle",
    first_target = ":RawResources",
    second_target = ":RawResources",
)

test_suite(
    name = "preview_resource_bundles",
    tests = [
        ":dual_aspect_resource_bundle",
        ":multiple_generators_resource_bundle",
    ],
)
