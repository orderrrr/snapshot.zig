const std = @import("std");

/// Print a colored diff between expected and actual
pub fn printColoredDiff(expected: []const u8, actual: []const u8) void {
    var exp_lines = std.mem.splitScalar(u8, expected, '\n');
    var act_lines = std.mem.splitScalar(u8, actual, '\n');

    var line_num: usize = 1;
    var has_diff = false;

    while (true) {
        const exp_line = exp_lines.next();
        const act_line = act_lines.next();

        if (exp_line == null and act_line == null) break;

        const exp = exp_line orelse "";
        const act = act_line orelse "";

        if (std.mem.eql(u8, exp, act)) {
            // Lines match - print in gray if we're showing context
            if (has_diff) {
                std.debug.print("\x1b[90m{d:>4} │\x1b[0m {s}\n", .{ line_num, exp });
            }
        } else {
            has_diff = true;
            // Lines differ - show both with colors
            if (exp_line != null) {
                std.debug.print("\x1b[31m{d:>4} │- {s}\x1b[0m\n", .{ line_num, exp });
            }
            if (act_line != null) {
                std.debug.print("\x1b[32m{d:>4} │+ {s}\x1b[0m\n", .{ line_num, act });
            }

            // Show character-level diff for this line
            printCharDiff(exp, act);
        }

        line_num += 1;
    }

    if (!has_diff) {
        std.debug.print("\x1b[90m(no visible differences - possibly whitespace/encoding)\x1b[0m\n", .{});
    }
}

/// Print character-level diff highlighting
pub fn printCharDiff(expected: []const u8, actual: []const u8) void {
    // Find first differing position
    var diff_pos: usize = 0;
    const min_len = @min(expected.len, actual.len);

    while (diff_pos < min_len and expected[diff_pos] == actual[diff_pos]) {
        diff_pos += 1;
    }

    if (diff_pos > 0 or expected.len != actual.len) {
        // Print position indicator
        std.debug.print("     │  ", .{});
        for (0..diff_pos) |_| {
            std.debug.print(" ", .{});
        }
        std.debug.print("\x1b[33m^\x1b[0m\n", .{});
    }
}
