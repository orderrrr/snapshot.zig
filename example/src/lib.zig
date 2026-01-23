const std = @import("std");
const snapshot = @import("snapshot");

const Person = struct {
    name: []const u8,
    age: u32,
    hobbies: []const []const u8,
};

/// Format a Person as JSON using std.json
pub fn formatPerson(allocator: std.mem.Allocator, name: []const u8, age: u32, hobbies: []const []const u8) ![]u8 {
    const person = Person{ .name = name, .age = age, .hobbies = hobbies };
    const fmt = std.json.fmt(person, .{ .whitespace = .indent_2 });
    var writer = std.io.Writer.Allocating.init(allocator);
    try fmt.format(&writer.writer);
    return writer.toOwnedSlice();
}

// ============================================================================
// Snapshot Tests
// ============================================================================

test "snapshot: format person as JSON" {
    const allocator = std.testing.allocator;

    var s = snapshot.Snapshot(allocator, @src()).init();
    defer s.deinit();

    const hobbies = &[_][]const u8{ "reading", "gaming", "hiking" };
    const result = try formatPerson(allocator, "Alice", 30, hobbies);
    defer allocator.free(result);

    try s.snap(result);
}

test "snapshot: format person with no hobbies" {
    const allocator = std.testing.allocator;

    var s = snapshot.Snapshot(allocator, @src()).init();
    defer s.deinit();

    const hobbies = &[_][]const u8{};
    const result = try formatPerson(allocator, "Bob", 25, hobbies);
    defer allocator.free(result);

    try s.snap(result);
}

test "snapshot: multiple snapshots in one test" {
    const allocator = std.testing.allocator;

    var s = snapshot.Snapshot(allocator, @src()).init();
    defer s.deinit();

    const hobbies = &[_][]const u8{ "coding", "music" };

    const result1 = try formatPerson(allocator, "Alice", 30, hobbies);
    defer allocator.free(result1);
    try s.snap(result1);

    const result2 = try formatPerson(allocator, "Bob", 25, &.{});
    defer allocator.free(result2);
    try s.snap(result2);
}
