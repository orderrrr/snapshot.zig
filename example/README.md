# Snapshot Testing Example

This example demonstrates how to use the `snapshot` module for snapshot testing in Zig.

## Usage

### Create/Update Snapshots

```bash
zig build test -Dsnapshot=true
```

This will create snapshot files in the `snapshots/` directory.

### Verify Snapshots

```bash
zig build test
```

This compares test output against existing snapshots and fails if there's a mismatch.

## Example Output

When a snapshot mismatch occurs, you'll see colored diff output:

```
[SNAPSHOT MISMATCH] lib.zig:120 (lib_snapshot__format_person_as_JSON_0.snapshot)
─────────────────────────────────────────
   1 │- {                    (red - expected)
   1 │+ {                    (green - actual)
     │  ^                    (yellow - diff position)
─────────────────────────────────────────
Run with -Dsnapshot=true to update snapshots
```

## Project Structure

```
example/
├── build.zig           # Build configuration
├── build.zig.zon       # Dependencies
├── src/
│   └── lib.zig         # Library with snapshot tests
├── snapshots/          # Snapshot files (version controlled)
│   ├── lib_snapshot__format_person_as_JSON_0.snapshot
│   ├── lib_snapshot__format_table_0.snapshot
│   └── ...
└── README.md
```

## Writing Snapshot Tests

```zig
const snapshot = @import("snapshot");
const std = @import("std");

test "my feature" {
    var s: snapshot.Snapshot(std.testing.allocator, @src()) = .{};
    defer s.deinit();
    
    const result = myFunction();
    try s.snap(result);
}

test "multiple snapshots" {
    var s: snapshot.Snapshot(std.testing.allocator, @src()) = .{};
    defer s.deinit();
    
    // Each snap() call gets a unique offset (0, 1, 2, ...)
    try s.snap(step1Result);  // :0.snapshot
    try s.snap(step2Result);  // :1.snapshot
    try s.snap(step3Result);  // :2.snapshot
}
```
