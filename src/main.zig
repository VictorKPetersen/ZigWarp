const std = @import("std");
const builtin = @import("builtin");
const cli = @import("presentation/cli/cli.zig");
const expect = std.testing.expect;

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

    const allocator, const is_debug = switch (builtin.mode) {
        .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
        .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false},
    };

    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len <= 1) {
        // Currently we ignore this scenario.
        // TODO: Add a friendly message.
        std.log.err("No command line arguments found, expects atleast 1.\n", .{});
    } else {
        cli.run(allocator, args[1..]);
    }
}

// This test should be deleted once testing has been initilized in the rest of the project.
test "always_true" {
    try expect(1 == 1);
}
