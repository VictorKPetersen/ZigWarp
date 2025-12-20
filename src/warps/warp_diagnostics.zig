const std = @import("std");

/// Diagnostics provides detailed error information for warp operations.
///
/// When operations fail, diagnostics capture context like file paths and error codes
/// All string data is owned by the diagnostics instance and must be freed with deinit().
pub const Diagnostics = struct {
    allocator: std.mem.Allocator,
    /// The diagnostic error, if any occurred
    err: ?Error = null,

    /// Represents specific error conditions with relevant context
    pub const Error = union(enum) {
        /// Failed to create a file due to an unexpected error
        file_create_failed: struct {
            code: anyerror,
            relative_path: []const u8,
        },
        /// Permission was denied for a file operation
        file_permission_denied: struct {
            relative_path: []const u8,
            operation: enum { read, write, execute },
        },
        /// Attempted to create a file which paths already exists.
        file_already_exists: struct {
            relative_path: []const u8,
        },
        /// The provided path was invalid or malformed
        invalid_path: struct {
            reason: []const u8,
        },
    };

    /// Frees all allocated diagnostic data.
    ///
    /// Safe to call multiple times and if err is null.
    pub fn deinit(self: *Diagnostics) void {
        if (self.err) |err| {
            switch (err) {
                .file_create_failed => |e| {
                    self.allocator.free(e.relative_path);
                },
                .file_permission_denied => |e| {
                    self.allocator.free(e.relative_path);
                },
                .file_already_exists => |e| {
                    self.allocator.free(e.relative_path);
                },
                .invalid_path => |e| {
                    self.allocator.free(e.reason);
                },
            }
        }
    }
};

test "Diagnostics.deinit file_create_failed frees memory" {
    const allocator = std.testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    diag.err = .{ .file_create_failed = .{
        .code = error.Unexpected,
        .relative_path = try allocator.dupe(u8, "testfile"),
    } };
    diag.deinit();
}

test "Diagnostics.deinit file_permission_denied frees memory" {
    const allocator = std.testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    diag.err = .{ .file_permission_denied = .{
        .relative_path = try allocator.dupe(u8, "testfile"),
        .operation = .write,
    } };
    diag.deinit();
}

test "Diagnostics.deinit file_already_exists frees memory" {
    const allocator = std.testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    diag.err = .{ .file_already_exists = .{
        .relative_path = try allocator.dupe(u8, "testfile"),
    } };
    diag.deinit();
}

test "Diagnostics.deinit invalid_path frees memory" {
    const allocator = std.testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    diag.err = .{ .invalid_path = .{
        .reason = try allocator.dupe(u8, "test reason"),
    } };
    diag.deinit();
}

test "Diagnostics.deinit handles null case safely" {
    const allocator = std.testing.allocator;
    var diag = Diagnostics{ .allocator = allocator };
    diag.deinit();
}
