const std = @import("std");
const Dir = std.fs.Dir;
const FileOpenError = std.fs.File.OpenError;

pub const AppDataError = error{
    DataPermissionDenied,
    BadDataPath,
    Unkown,
};

pub fn openOrCreateDataDir(path: []const u8) AppDataError!Dir {
    const data_dir = std.fs.openDirAbsolute(path, .{}) catch |err| switch (err) {
        FileOpenError.FileNotFound => try createDataDir(path),

        FileOpenError.PermissionDenied,
        FileOpenError.AccessDenied,
        FileOpenError.AntivirusInterference,
        => AppDataError.DataPermissionDenied,

        FileOpenError.InvalidUtf8,
        FileOpenError.InvalidWtf8,
        FileOpenError.BadPathName,
        FileOpenError.PathAlreadyExists,
        => AppDataError.BadDataPath,

        inline else => AppDataError.Unkown,
    };

    return data_dir;
}

fn createDataDir(path: []const u8) AppDataError!Dir {
    std.fs.makeDirAbsolute(path) catch {
        return AppDataError.Unkown;
    };

    return std.fs.openDirAbsolute(path, .{}) catch |err| switch (err) {
        FileOpenError.PermissionDenied,
        FileOpenError.AccessDenied,
        FileOpenError.AntivirusInterference,
        => AppDataError.DataPermissionDenied,

        FileOpenError.InvalidUtf8,
        FileOpenError.InvalidWtf8,
        FileOpenError.BadPathName,
        FileOpenError.PathAlreadyExists,
        => AppDataError.BadDataPath,

        inline else => AppDataError.Unkown,
    };
}
