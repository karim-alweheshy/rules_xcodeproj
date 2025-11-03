load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcodeproj")

swift_library(
    name = "TestLib",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "TestLib",
    visibility = ["//visibility:public"],
)

xcodeproj(
    name = "TestProject_Before",
    project_name = "TestProject_Before",
    tags = ["manual"],
    top_level_targets = [":TestLib"],
)

xcodeproj(
    name = "TestProject_After",
    project_name = "TestProject_After",
    tags = ["manual"],
    top_level_targets = [":TestLib"],
)
