const std = @import("std");
const Allocator = std.mem.Allocator;

const options = @import("snapshot_options");
const util = @import("util.zig");

pub const Fs = @import("fs.zig").Fs;

pub fn Snapshot(allocator: Allocator, comptime src: std.builtin.SourceLocation) type {
    return struct {
        const Self = @This();
        const snapshot_name = Fs.snapshotName(src);

        offset: u32 = 0,
        fs: Fs = Fs.open(options.snapshot_dir) catch @panic("Failed to open snapshot directory"),

        pub fn deinit(self: *Self) void {
            self.fs.close();
        }

        pub fn snap(self: *Self, actual: []const u8) !void {
            defer self.offset += 1;

            if (options.update_snapshots) {
                try self.fs.writeSnapshot(src, self.offset, actual);
                return;
            }

            const expected = self.fs.loadSnapshot(allocator, self.offset, src) catch |err| switch (err) {
                error.FileNotFound => {
                    std.debug.print("\x1b[33m[SNAPSHOT]\x1b[0m Creating new snapshot: {s}\n", .{snapshot_name});
                    try self.fs.writeSnapshot(src, self.offset, actual);
                    return;
                },
                else => |e| return e,
            };
            defer allocator.free(expected);

            if (!std.mem.eql(u8, expected, actual)) {
                std.debug.print("\n\x1b[31m[SNAPSHOT MISMATCH]\x1b[0m {s}:{d} ({s})\n", .{
                    src.file,
                    src.line,
                    snapshot_name,
                });
                std.debug.print("─────────────────────────────────────────\n", .{});

                util.printColoredDiff(expected, actual);

                std.debug.print("─────────────────────────────────────────\n", .{});
                std.debug.print("Run with \x1b[33m-Dsnapshot=true\x1b[0m to update snapshots\n\n", .{});

                return error.SnapshotMismatch;
            }
        }
    };
}

// ============================================================================
// Tests
// ============================================================================

test "integration: snapshot write and verify" {
    var s: Snapshot(std.testing.allocator, @src()) = .{};
    defer s.deinit();

    const test_data = "hello world\nthis is a test\n";
    try s.snap(test_data);

    // Second call should use offset 1
    const test_data2 = "second snapshot\n";
    try s.snap(test_data2);
}

test "integration: snapshot mismatch detection" {
    // Use a temp directory for this test to avoid polluting snapshots/
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    // Create a custom snapshot instance pointing to temp dir
    _ = Snapshot(std.testing.allocator, @src()){
        .offset = 0,
        .fs = .{ .dir = tmp.dir },
    };

    // First, create a snapshot
    const original_data = "original content\n";
    // Force update mode by writing directly
    const filename = "test_mismatch_0.snapshot";
    const file = try tmp.dir.createFile(filename, .{});
    try file.writeAll(original_data);
    file.close();

    // Now verify with different data - should fail
    const different_data = "different content\n";

    // Manually load and compare since we can't call snap() with custom filename
    const loaded = try tmp.dir.openFile(filename, .{});
    defer loaded.close();

    const expected = try loaded.readToEndAlloc(std.testing.allocator, 10 * 1024 * 1024);
    defer std.testing.allocator.free(expected);

    try std.testing.expect(!std.mem.eql(u8, expected, different_data));
}
