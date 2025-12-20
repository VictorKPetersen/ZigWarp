const std = @import("std");
const Warp = @import("Warp.zig").Warp;
const warp_repo = @import("warp_repo.zig");
const Dir = std.fs.Dir;
const WarpDTO = @import("Warp.zig").WarpDTO;
const CreateError = @import("warp_errors.zig").CreateError;
const Diagnostics = @import("warp_diagnostics.zig").Diagnostics;

pub fn createAndSaveWarp(
    data_dir: Dir,
    warp_name: []const u8,
    warp_path: []const u8,
    diagnostics: ?*Diagnostics,
) !WarpDTO {
    if (warp_name.len <= 0) return CreateError.MissingName;
    if (warp_path.len <= 0) return CreateError.MissingPath;

    const file = try warp_repo.getOrCreateSaveFile(
        data_dir,
        "warps.json",
        diagnostics,
    );
    defer file.close();

    const dto: WarpDTO = .{
        .name = warp_name,
        .path = warp_path,
    };

    return dto;
}
