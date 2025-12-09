const std = @import("std");
const add_action = @import("actions/AddAction.zig");
const AddAction = add_action.AddAction;
const AddActionError = add_action.AddActionError;
const Allocator = std.mem.Allocator;

pub const ActionError = AddActionError;

pub const Action = union(enum) {
    add: AddAction,

    pub fn execute(self: @This(), allocator: Allocator, args: []const []const u8) ActionError!void {
        try switch (self) {
            inline else => |action| action.execute(allocator, args),
        };
    }

    pub fn name(self: @This()) []const u8 {
        switch (self) {
            inline else => |action| return action.name(),
        }
    }

    pub fn min_args(self: @This()) u8 {
        switch (self) {
            inline else => |action| return action.min_args(),
        }
    }
};
