# snapshot.zig

Tiny snapshot testing for Zig.

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
```

See `example/` for more usage examples.
