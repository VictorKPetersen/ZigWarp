const std = @import("std");
const Allocator = std.mem.Allocator;
const warp = @import("warp");

pub const AddActionError = error{
    PermissionDenied,
    BadPath,
    SaveFailed,
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

        std.debug.print("Created warp {s} with path {s}\n", .{new_warp.name, new_warp.path});
    }

    pub fn name(self: @This()) []const u8 {
        return self.command_name;
    }

    pub fn min_args(self: @This()) u8 {
        return self.min_arguments;
    }
};

/// Gets the full path from a relative one.
///
/// The Full path is seen as the path to the current cwd and then resolving the user input path.
/// The caller owns the memory and must free it when no longer in use.
fn getFullPath(allocator: Allocator, relative_path: []const u8) AddActionError![]const u8 {
    const cwd_path = std.fs.cwd().realpathAlloc(allocator, ".") catch |err| {
        return switch (err) {
            error.AccessDenied, error.AntivirusInterference => AddActionError.PermissionDenied,
            error.NameTooLong, error.SymLinkLoop, => AddActionError.BadPath,
            inline else => AddActionError.SaveFailed,
        };
    };
    defer allocator.free(cwd_path);

    const abs_path = std.fs.path.resolve(allocator, &.{
        cwd_path,
        relative_path,
    }) catch {
        return AddActionError.SaveFailed;
    };
    errdefer allocator.free(abs_path);

    std.fs.cwd().access(relative_path, .{ .mode = .read_only }) catch |err| {
        return switch (err) {
            error.AccessDenied, error.ReadOnlyFileSystem => AddActionError.PermissionDenied,
            error.BadPathName, error.FileNotFound, error.NameTooLong, error.SymLinkLoop => AddActionError.BadPath,
            inline else => AddActionError.SaveFailed,
        };
    };

    return abs_path;
}
