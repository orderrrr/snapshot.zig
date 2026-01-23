const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Snapshot options
    const update_snapshots = b.option(bool, "snapshot", "Update snapshots instead of verifying") orelse false;

    const snapshot_dep = b.dependency("snapshot", .{
        .target = target,
        .optimize = optimize,
        .snapshot = update_snapshots,
        .@"snapshot-dir" = "snapshots",
    });

    // Main library module
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport("snapshot", snapshot_dep.module("snapshot"));

    // Library artifact
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "example",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    // Tests
    const tests = b.addTest(.{
        .root_module = lib_mod,
    });
    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
