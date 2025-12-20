const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const warp_mod = b.addModule("warp", .{
        .root_source_file = b.path("src/warps/warps.zig"),
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "zwarp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/app/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "warp", .module = warp_mod },
            },
        }),
    });

    b.installArtifact(exe);

    const exe_check = b.addExecutable(.{
        .name = "zwarp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/app/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "warp", .module = warp_mod },
            },
        }),
    });

    const check = b.step("check", "Check if zwarp compiles");
    check.dependOn(&exe_check.step);

    const docs_step = b.step("docs", "Generate Documentation");
    const exe_docs = b.addInstallDirectory(.{
        .source_dir = exe.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&exe_docs.step);

    const warp_docs_obj = b.addObject(.{
        .name = "warp",
        .root_module = warp_mod,
    });
    const warp_docs = b.addInstallDirectory(.{
        .source_dir = warp_docs_obj.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&warp_docs.step);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const test_step = b.step("test", "Run tests");

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    test_step.dependOn(&run_exe_tests.step);

    // Define warp module test step.
    const warp_tests = b.addTest(.{ .root_module = warp_mod });

    const run_warp_tests = b.addRunArtifact(warp_tests);
    test_step.dependOn(&run_warp_tests.step);
}
