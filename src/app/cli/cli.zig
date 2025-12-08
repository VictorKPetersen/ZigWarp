const std = @import("std");
const Allocator = std.mem.Allocator;
const Action = @import("action.zig").Action;

const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

pub const CliError = error{
    MissingArgument,
    UnkownCommand,
};

pub fn run(allocator: Allocator, args: []const []const u8) !void {
    _ = allocator;

    if (args.len <= 0) return CliError.MissingArgument;

    const main_command = args[0];
    const arguments = args[1..];

    const potential_action = matchCommand(main_command);

    if (potential_action) |action| {
        action.execute(arguments);
    } else {
        return CliError.UnkownCommand;
    }
}

/// Attemps to find a matching Action based on the input command name.
///
/// Will return first found command where .name() matches command_name.
/// If no matching commands are found returns null.
pub fn matchCommand(command_name: []const u8) ?Action {
    const Info = @typeInfo(Action).@"union";

    inline for (Info.fields) |field| {
        const PayloadType = field.type;
        const tag_name = field.name;

        const temp_action = PayloadType{};

        const defined_name = temp_action.name();

        if (std.mem.eql(u8, command_name, defined_name)) {
            return @unionInit(Action, tag_name, temp_action);
        }
    }

    return null;
}

test "cli.run returns MissingArgument with empty args" {
    const empty_args: []const []const u8 = &[_][]const u8{};
    try expectEqual(0, empty_args.len);

    const allocator = std.testing.allocator;
    const result = run(allocator, empty_args);

    try expectError(CliError.MissingArgument, result);
}

test "cli.matchCommand returns null on unkown command" {
    const input_commad = "this_is_not_a_command_and_never_will_be";
    const potential_action = matchCommand(input_commad);

    try expect(potential_action == null);
}

test "cli.matchCommand returns null on partial match" {
    const input_command = "ad";
    const potential_action = matchCommand(input_command);

    try expect(potential_action == null);
}

test "cli.matchCommand succes on 'add' " {
    const input_command = "add";
    const potential_action = matchCommand(input_command);

    try expect(potential_action != null);

    const action = potential_action.?;

    try expectEqualSlices(u8, input_command, action.name());
}
