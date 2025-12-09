const Warp = @import("Warp.zig").Warp;
pub const WarpDTO = @import("WarpDTO.zig").WarpDTO;
pub const WarpCreationError = @import("WarpError.zig").WarpCreationError;

pub fn createAndSaveWarp(warp_name: []const u8, warp_path: []const u8) WarpCreationError!WarpDTO {
    if (warp_name.len <= 0) return WarpCreationError.MissingName;
    if (warp_path.len <= 0) return WarpCreationError.MissingPath;

    const dto: WarpDTO = .{
        .name = warp_name,
        .path = warp_path,
    };

    return dto;
}
