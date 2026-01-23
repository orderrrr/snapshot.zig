const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build options for snapshot behavior
    const update_snapshots = b.option(
        bool,
        "snapshot",
        "Update snapshots instead of verifying",
    ) orelse false;

    const snapshot_dir = b.option(
        []const u8,
        "snapshot-dir",
        "Directory for snapshot files (relative to project root)",
    ) orelse "snapshots";

    const opts = b.addOptions();
    opts.addOption(bool, "update_snapshots", update_snapshots);
    opts.addOption([]const u8, "snapshot_dir", snapshot_dir);

    // Create the module
    const snapshot_mod = b.createModule(.{
        .root_source_file = b.path("src/snapshot.zig"),
        .target = target,
        .optimize = optimize,
    });
    snapshot_mod.addOptions("snapshot_options", opts);

    // Export the module
    _ = b.addModule("snapshot", .{
        .root_source_file = b.path("src/snapshot.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "snapshot_options", .module = opts.createModule() },
        },
    });

    // Tests for the snapshot module itself
    const tests = b.addTest(.{
        .root_module = snapshot_mod,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run snapshot module tests");
    test_step.dependOn(&run_tests.step);
}
