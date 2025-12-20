const std = @import("std");
const builtin = @import("builtin");
const cli = @import("cli/cli.zig");

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

    const allocator, const is_debug = switch (builtin.mode) {
        .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
        .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
    };

    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len <= 1) {
        // Currently we ignore this scenario.
        // TODO: Add a friendly message.
    } else {
        cli.run(allocator, args[1..]) catch |err| switch (err) {
            cli.CliError.MissingArgument => {
                std.log.err("Missing command-line arguments.", .{});
            },
        };
    }
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
