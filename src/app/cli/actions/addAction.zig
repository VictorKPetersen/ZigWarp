const std = @import("std");

pub const AddAction = struct {
    command_name: []const u8 = "add",

    pub fn execute(self: @This(), args: []const []const u8) void {
        std.debug.print("From {s}\n", .{self.name()});
        for (args) |arg| {
            std.debug.print("Arg: {s}\n", .{arg});
        }
    }

    pub fn name(self: @This()) []const u8 {
        return self.command_name;
    }
};
