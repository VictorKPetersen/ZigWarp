const std = @import("std");
const File = std.fs.File;
const Dir = std.fs.Dir;
const Allocator = std.mem.Allocator;
const FileOpenError = File.OpenError;
const testing = std.testing;

const CreateError = @import("warp_errors.zig").CreateError;
const Diagnostics = @import("warp_diagnostics.zig").Diagnostics;

/// Gets the file named file_name in data_dir, if the file does not exist, creates it.
/// Requires the user has read permissions and also write if file does not exist.
/// The caller owns the returned file.
pub fn getOrCreateSaveFile(
    data_dir: Dir,
    file_name: []const u8,
    diagnostics: ?*Diagnostics,
) CreateError!File {
    const data_file = data_dir.openFile(file_name, .{ .mode = .read_write }) catch |err| {
        return switch (err) {
            FileOpenError.FileNotFound => try createSaveFile(
                data_dir,
                file_name,
                diagnostics,
            ),
            inline else => {
                if (diagnostics) |d| {
                    try setDiagnosticForError(d, err, file_name);
                }
                return mapFileOpenError(err);
            },
        };
    };

    return data_file;
}

/// Creates a file named file_name in data_dir.
/// Requires that the user has permission to create a file in data_dir.
/// The caller owns the returned file.
fn createSaveFile(
    data_dir: Dir,
    file_name: []const u8,
    diagnostics: ?*Diagnostics,
) CreateError!File {
    return data_dir.createFile(file_name, .{}) catch |err| {
        if (diagnostics) |d| {
            try setDiagnosticForError(d, err, file_name);
        }
        return mapFileOpenError(err);
    };
}

fn setDiagnosticForError(
    diag: *Diagnostics,
    err: FileOpenError,
    file_name: []const u8,
) !void {
    diag.err = switch (err) {
        error.PermissionDenied,
        error.AccessDenied,
        error.AntivirusInterference,
        => .{ .file_permission_denied = .{
            .relative_path = try diag.allocator.dupe(u8, file_name),
            .operation = .write,
        } },

        error.BadPathName,
        error.InvalidUtf8,
        error.InvalidWtf8,
        => .{ .invalid_path = .{
            .reason = try diag.allocator.dupe(u8, @errorName(err)),
        } },

        error.PathAlreadyExists => .{ .file_already_exists = .{
            .relative_path = try diag.allocator.dupe(u8, file_name),
        } },

        inline else => .{ .file_create_failed = .{
            .code = err,
            .relative_path = try diag.allocator.dupe(u8, file_name),
        } },
    };
}

fn mapFileOpenError(err: FileOpenError) CreateError {
    return switch (err) {
        error.PermissionDenied,
        error.AccessDenied,
        error.AntivirusInterference,
        => return CreateError.PermissionDenied,

        error.BadPathName,
        error.InvalidUtf8,
        error.InvalidWtf8,
        error.PathAlreadyExists,
        => return CreateError.BadPath,

        inline else => return CreateError.IoFailure,
    };
}

test "warp_repo.createSaveFile creates file" {
    var test_dir = testing.tmpDir(.{});
    defer test_dir.cleanup();
    const root_dir = test_dir.dir;

    var created_file = try createSaveFile(root_dir, "testfile", null);
    defer created_file.close();

    var opened_file = try root_dir.openFile("testfile", .{});
    defer opened_file.close();

    const created_stat = try created_file.stat();
    const opened_stat = try opened_file.stat();

    try testing.expect(created_stat.kind == std.fs.File.Kind.file);
    try testing.expect(opened_stat.kind == std.fs.File.Kind.file);

    try testing.expectEqual(created_stat.inode, opened_stat.inode);
}

test "warp_repo.getOrCreateSaveFile gets already existing file" {
    var test_dir = testing.tmpDir(.{});
    defer test_dir.cleanup();
    const root_dir = test_dir.dir;

    var created_file = try createSaveFile(root_dir, "testfile", null);
    defer created_file.close();

    var get_file = try getOrCreateSaveFile(root_dir, "testfile", null);
    defer get_file.close();

    const created_stat = try created_file.stat();
    const get_stat = try get_file.stat();

    try testing.expect(created_stat.kind == std.fs.File.Kind.file);
    try testing.expect(get_stat.kind == std.fs.File.Kind.file);

    try testing.expectEqual(created_stat.inode, get_stat.inode);
}

test "warp_repo.getOrCreateDataFile creates non existing file" {
    var test_dir = testing.tmpDir(.{});
    defer test_dir.cleanup();
    const root_dir = test_dir.dir;

    var created_file = try getOrCreateSaveFile(root_dir, "testfile", null);
    defer created_file.close();

    var opened_file = try root_dir.openFile("testfile", .{});
    defer opened_file.close();

    const created_stat = try created_file.stat();
    const opened_stat = try opened_file.stat();

    try testing.expect(created_stat.kind == std.fs.File.Kind.file);
    try testing.expect(opened_stat.kind == std.fs.File.Kind.file);

    try testing.expectEqual(created_stat.inode, opened_stat.inode);
}

test "warp_repo.mapFileOpenError return correct error" {
    const invalidUtf8 = mapFileOpenError(FileOpenError.InvalidUtf8);
    const invalidWtf8 = mapFileOpenError(FileOpenError.InvalidWtf8);
    const badPathName = mapFileOpenError(FileOpenError.BadPathName);
    const pathAlreadyExists = mapFileOpenError(FileOpenError.PathAlreadyExists);

    try testing.expectEqual(CreateError.BadPath, invalidUtf8);
    try testing.expectEqual(CreateError.BadPath, invalidWtf8);
    try testing.expectEqual(CreateError.BadPath, badPathName);
    try testing.expectEqual(CreateError.BadPath, pathAlreadyExists);

    const permissionDenied = mapFileOpenError(FileOpenError.PermissionDenied);
    const accessDenied = mapFileOpenError(FileOpenError.AccessDenied);
    const antivirus = mapFileOpenError(FileOpenError.AntivirusInterference);

    try testing.expectEqual(CreateError.PermissionDenied, permissionDenied);
    try testing.expectEqual(CreateError.PermissionDenied, accessDenied);
    try testing.expectEqual(CreateError.PermissionDenied, antivirus);

    const unexpected = mapFileOpenError(FileOpenError.Unexpected);

    try testing.expectEqual(CreateError.IoFailure, unexpected);
}

test "warp_repo.setDiagnosticForError sets .file_permission_denied for PermissionDenied" {
    const allocator = testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    defer diag.deinit();

    try setDiagnosticForError(&diag, FileOpenError.PermissionDenied, "testfile");

    try testing.expect(diag.err != null);
    try testing.expectEqual(.file_permission_denied, std.meta.activeTag(diag.err.?));
    try testing.expectEqualStrings("testfile", diag.err.?.file_permission_denied.relative_path);
    try testing.expectEqual(.write, diag.err.?.file_permission_denied.operation);
}

test "warp_repo.setDiagnosticForError sets .file_permission_denied for AccessDenied" {
    const allocator = testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    defer diag.deinit();

    try setDiagnosticForError(&diag, FileOpenError.AccessDenied, "testfile");

    try testing.expect(diag.err != null);
    try testing.expectEqual(.file_permission_denied, std.meta.activeTag(diag.err.?));
    try testing.expectEqualStrings("testfile", diag.err.?.file_permission_denied.relative_path);
    try testing.expectEqual(.write, diag.err.?.file_permission_denied.operation);
}

test "warp_repo.setDiagnosticForError sets .file_permission_denied for AntivirusInterference" {
    const allocator = testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    defer diag.deinit();

    try setDiagnosticForError(&diag, FileOpenError.AntivirusInterference, "testfile");

    try testing.expect(diag.err != null);
    try testing.expectEqual(.file_permission_denied, std.meta.activeTag(diag.err.?));
    try testing.expectEqualStrings("testfile", diag.err.?.file_permission_denied.relative_path);
    try testing.expectEqual(.write, diag.err.?.file_permission_denied.operation);
}

test "setDiagnosticForError sets invalid_path for InvalidUtf8" {
    const allocator = testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    defer diag.deinit();

    try setDiagnosticForError(&diag, error.InvalidUtf8, "testfile");

    try testing.expectEqual(.invalid_path, std.meta.activeTag(diag.err.?));
    try testing.expectEqualStrings("InvalidUtf8", diag.err.?.invalid_path.reason);
}

test "setDiagnosticForError sets invalid_path for InvalidWtf8" {
    const allocator = testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    defer diag.deinit();

    try setDiagnosticForError(&diag, error.InvalidWtf8, "testfile");

    try testing.expectEqual(.invalid_path, std.meta.activeTag(diag.err.?));
    try testing.expectEqualStrings("InvalidWtf8", diag.err.?.invalid_path.reason);
}

test "setDiagnosticForError sets invalid_path for BadPathName" {
    const allocator = testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    defer diag.deinit();

    try setDiagnosticForError(&diag, error.BadPathName, "testfile");

    try testing.expectEqual(.invalid_path, std.meta.activeTag(diag.err.?));
    try testing.expectEqualStrings("BadPathName", diag.err.?.invalid_path.reason);
}

test "setDiagnosticForError sets file_already_exists for PathAlreadyExists" {
    const allocator = testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    defer diag.deinit();

    try setDiagnosticForError(&diag, error.PathAlreadyExists, "testfile");

    try testing.expectEqual(.file_already_exists, std.meta.activeTag(diag.err.?));
    try testing.expectEqualStrings("testfile", diag.err.?.file_already_exists.relative_path);
}

test "setDiagnosticForError sets file_create_failed for unexpected errors" {
    const allocator = testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    defer diag.deinit();

    try setDiagnosticForError(&diag, error.Unexpected, "testfile");

    try testing.expectEqual(.file_create_failed, std.meta.activeTag(diag.err.?));
    try testing.expectEqualStrings("testfile", diag.err.?.file_create_failed.relative_path);
    try testing.expectEqual(error.Unexpected, diag.err.?.file_create_failed.code);
}
