const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    setupModule(b, "raylib", .{
        .root_source_file = b.path("src/raylib.zig"),
        .target = target,
        .optimize = optimize,
    });
}

fn setupModule(b: *std.Build, comptime name: []const u8, create_options: std.Build.Module.CreateOptions) void {
    const mod = b.addModule("raylib", create_options);

    const exe_unit_tests = b.addTest(.{ .root_module = mod });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step(name ++ "-test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
