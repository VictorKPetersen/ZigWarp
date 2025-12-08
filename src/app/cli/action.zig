const AddAction = @import("actions/addAction.zig").AddAction;

pub const Action = union(enum) {
    add: AddAction,

    pub fn execute(self: @This(), args: []const []const u8) void {
        switch (self) {
            inline else => |action| action.execute(args),
        }
    }

    pub fn name(self: @This()) []const u8 {
        switch (self) {
            inline else => |action| return action.name(),
        }
    }
};
