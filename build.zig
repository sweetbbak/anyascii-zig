const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "anyascii",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
    });
    switch (optimize) {
        .Debug, .ReleaseSafe => lib.bundle_compiler_rt = true,
        .ReleaseFast, .ReleaseSmall => {},
    }
    b.installArtifact(lib);

    const static_lib = b.addStaticLibrary(.{
        .name = "anyascii",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
    });

    static_lib.pie = true;

    // necessary to avoid issues with undefined symbols
    switch (optimize) {
        .Debug, .ReleaseSafe => static_lib.bundle_compiler_rt = true,
        .ReleaseFast, .ReleaseSmall => {},
    }

    b.installArtifact(static_lib);

    _ = b.addModule("anyascii", .{
        .root_source_file = b.path("src/anyascii.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/anyascii.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
