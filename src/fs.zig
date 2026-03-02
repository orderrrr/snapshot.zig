const std = @import("std");
const Allocator = std.mem.Allocator;
const Dir = std.Io.Dir;
const Io = std.Io;

pub const Fs = struct {
    dir: Dir,
    io: Io,

    pub fn open(io: Io, dir_path: []const u8) !Fs {
        const cwd = Dir.cwd();
        const snapshot_dir = cwd.openDir(io, dir_path, .{}) catch |err| switch (err) {
            error.FileNotFound => cwd.createDirPathOpen(io, dir_path, .{}) catch |e| {
                std.debug.print("Failed to create snapshot directory '{s}': {}\n", .{ dir_path, e });
                @panic("Cannot initialize snapshot directory");
            },
            else => {
                std.debug.print("Failed to open snapshot directory '{s}': {}\n", .{ dir_path, err });
                @panic("Cannot open snapshot directory");
            },
        };

        return .{
            .dir = snapshot_dir,
            .io = io,
        };
    }

    pub fn close(self: *Fs) void {
        self.dir.close(self.io);
    }

    pub fn writeSnapshot(self: *Fs, comptime src: std.builtin.SourceLocation, offset: u32, actual: []const u8) !void {
        const filename = comptime Fs.snapshotName(src);
        var buf: [256]u8 = undefined;
        const full_filename = std.fmt.bufPrint(&buf, "{s}:{d}.snapshot", .{ filename, offset }) catch unreachable;

        self.dir.writeFile(self.io, .{
            .sub_path = full_filename,
            .data = actual,
        }) catch |e| return e;

        // TODO move to my logging util.
        std.debug.print("\x1b[32m[SNAPSHOT]\x1b[0m Updated: {s}\n", .{filename});
    }

    pub fn loadSnapshot(self: *Fs, allocator: Allocator, offset: u32, comptime src: std.builtin.SourceLocation) Dir.ReadFileAllocError![]u8 {
        const filename = comptime Fs.snapshotName(src);
        var buf: [256]u8 = undefined;
        const full_filename = std.fmt.bufPrint(&buf, "{s}:{d}.snapshot", .{ filename, offset }) catch unreachable;

        return self.dir.readFileAlloc(self.io, full_filename, allocator, .limited(32 * 1024 * 1024));
    }

    pub fn snapshotName(comptime src: std.builtin.SourceLocation) *const [snapshotLen(src)]u8 {
        comptime {
            const stem = fileName(src);
            const test_name = src.fn_name;
            return stem ++ "_" ++ test_name;
        }
    }

    pub fn snapshotLen(comptime src: std.builtin.SourceLocation) usize {
        comptime {
            const stem = fileName(src);
            const test_name = src.fn_name;
            return stem.len + test_name.len + 1;
        }
    }

    pub fn fileName(comptime src: std.builtin.SourceLocation) *const [fileNameLen(src)]u8 {
        comptime {
            const filename = std.fs.path.basename(src.file);
            const ext = std.fs.path.extension(src.file);
            return filename[0 .. filename.len - ext.len];
        }
    }

    pub fn fileNameLen(comptime src: std.builtin.SourceLocation) usize {
        comptime {
            const filename = std.fs.path.basename(src.file);
            const ext = std.fs.path.extension(src.file);
            return filename.len - ext.len;
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

fn mockSrc(comptime file: [:0]const u8, comptime fn_name: [:0]const u8) std.builtin.SourceLocation {
    return .{
        .module = "test",
        .file = file,
        .fn_name = fn_name,
        .line = 0,
        .column = 0,
    };
}

test "fileName extracts basename without extension" {
    {
        const src = comptime mockSrc("src/foo/bar.zig", "test_fn");
        const result = comptime Fs.fileName(src);
        try std.testing.expectEqualStrings("bar", result);
    }
    {
        const src = comptime mockSrc("test.zig", "test_fn");
        const result = comptime Fs.fileName(src);
        try std.testing.expectEqualStrings("test", result);
    }
    {
        const src = comptime mockSrc("path/to/my-file.test.zig", "test_fn");
        const result = comptime Fs.fileName(src);
        try std.testing.expectEqualStrings("my-file.test", result);
    }
}

test "snapshotName combines filename and function name" {
    const src = comptime mockSrc("src/parser.zig", "test.parse tokens");
    const result = comptime Fs.snapshotName(src);
    try std.testing.expectEqualStrings("parser_test.parse tokens", result);
}
