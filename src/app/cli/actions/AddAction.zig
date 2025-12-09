const std = @import("std");
const Allocator = std.mem.Allocator;
const warp = @import("warp");

pub const AddActionError = error{
    PathError,
};

pub const AddAction = struct {
    command_name: []const u8 = "add",
    min_arguments: u8 = 2,

    pub fn execute(_: @This(), allocator: Allocator, args: []const []const u8) AddActionError!void {
        const warp_name = args[0];
        const warp_path = args[1];

        const abs_path = try getFullPath(allocator, warp_path);
        defer allocator.free(abs_path);

        const new_warp = warp.createAndSaveWarp(warp_name, abs_path) catch |err| {
            std.debug.print("Err: {}\n", .{err});
            return;
        };
        _ = new_warp;
    }

    pub fn name(self: @This()) []const u8 {
        return self.command_name;
    }

    pub fn min_args(self: @This()) u8 {
        return self.min_arguments;
    }
};

fn getFullPath(allocator: Allocator, relative_path: []const u8) AddActionError![]const u8 {
    const cwd_path = std.fs.cwd().realpathAlloc(allocator, ".") catch |err| {
        std.debug.print("Err: {}\n", .{err});
        return AddActionError.PathError;
    };
    defer allocator.free(cwd_path);

    const abs_path = std.fs.path.resolve(allocator, &.{
        cwd_path,
        relative_path,
    }) catch |err| {
        std.debug.print("Err: {}\n", .{err});
        return AddActionError.PathError;
    };

    return abs_path;
}
