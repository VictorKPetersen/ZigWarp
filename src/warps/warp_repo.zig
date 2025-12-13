const std = @import("std");
const File = std.fs.File;
const Dir = std.fs.Dir;
const Allocator = std.mem.Allocator;
const FileOpenError = File.OpenError;
const testing = std.testing;

const SaveFileError = error{
    FailedSave,
    DataDirNotFound,
    PermissionDenied,
};

/// Gets the file named file_name in data_dir, if the file does not exist, creates it.
/// Requires the user has read permissions and also write if file does not exist.
/// The caller owns the returned file.
pub fn getOrCreateSaveFile(data_dir: Dir, file_name: []const u8) SaveFileError!File {
    const data_file = data_dir.openFile(file_name, .{ .mode = .read_write }) catch |err| switch (err) {
        FileOpenError.FileNotFound => try createSaveFile(data_dir, file_name),
        FileOpenError.PermissionDenied, FileOpenError.AccessDenied, FileOpenError.AntivirusInterference => return SaveFileError.PermissionDenied,
        inline else => return SaveFileError.FailedSave,
    };

    return data_file;
}

/// Creates a file named file_name in data_dir.
/// Requires that the user has permission to create a file in data_dir.
/// The caller owns the returned file.
fn createSaveFile(data_dir: Dir, file_name: []const u8) SaveFileError!File {
    return data_dir.createFile(file_name, .{}) catch |err| switch (err) {
        FileOpenError.PermissionDenied, FileOpenError.AccessDenied, FileOpenError.AntivirusInterference => return SaveFileError.PermissionDenied,
        inline else => return SaveFileError.FailedSave,
    };
}

test "createSaveFile creates file" {
    var test_dir = testing.tmpDir(.{});
    defer test_dir.cleanup();
    const root_dir = test_dir.dir;

    var created_file = try createSaveFile(root_dir, "testfile");
    defer created_file.close();

    var opened_file = try root_dir.openFile("testfile", .{});
    defer opened_file.close();

    const created_stat = try created_file.stat();
    const opened_stat = try opened_file.stat();

    try testing.expect(created_stat.kind == std.fs.File.Kind.file);
    try testing.expect(opened_stat.kind == std.fs.File.Kind.file);

    try testing.expectEqual(created_stat.inode, opened_stat.inode);
}

test "getOrCreateSaveFile gets already existing file" {
    var test_dir = testing.tmpDir(.{});
    defer test_dir.cleanup();
    const root_dir = test_dir.dir;

    var created_file = try createSaveFile(root_dir, "testfile");
    defer created_file.close();

    var get_file = try getOrCreateSaveFile(root_dir, "testfile");
    defer get_file.close();

    const created_stat = try created_file.stat();
    const get_stat = try get_file.stat();

    try testing.expect(created_stat.kind == std.fs.File.Kind.file);
    try testing.expect(get_stat.kind == std.fs.File.Kind.file);

    try testing.expectEqual(created_stat.inode, get_stat.inode);
}

test "getOrCreateDataFile creates non existing file" {
    var test_dir = testing.tmpDir(.{});
    defer test_dir.cleanup();
    const root_dir = test_dir.dir;

    var created_file = try getOrCreateSaveFile(root_dir, "testfile");
    defer created_file.close();

    var opened_file = try root_dir.openFile("testfile", .{});
    defer opened_file.close();

    const created_stat = try created_file.stat();
    const opened_stat = try opened_file.stat();

    try testing.expect(created_stat.kind == std.fs.File.Kind.file);
    try testing.expect(opened_stat.kind == std.fs.File.Kind.file);

    try testing.expectEqual(created_stat.inode, opened_stat.inode);
}
