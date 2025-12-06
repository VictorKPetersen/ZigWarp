const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn run(allocator: Allocator, args: []const []const u8) void {
    _ = allocator;

    if (args.len <= 0) {
        std.log.err("CLI Expects atleast 1 argument {d} was found.\n", .{args.len});
    }

    std.debug.print("Parsed command: {s} args: \n", .{args[0]});
    for (args[1..]) |command_arg| {
        std.debug.print("{s} \n", .{command_arg});
    }
}
