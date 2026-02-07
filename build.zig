const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ztg_dep = b.dependency("zentig_ecs", .{
        .target = target,
        .optimize = optimize,
    });
    const ztg = ztg_dep.module("zentig");

    const ray = setupModule(b, "raylib", ztg, .{
        .root_source_file = b.path("src/raylib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const rl = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    ray.addImport("raylib", rl.module("root"));

    const box2d_fw = setupModule(b, "box2d", ztg, .{
        .root_source_file = b.path("src/box2d.zig"),
        .target = target,
        .optimize = optimize,
    });

    const box2d = b.dependency("box2d", .{
        .target = target,
        .optimize = optimize,
    });
    box2d_fw.addImport("box2d", box2d.module("raw_c"));
}

fn setupModule(b: *std.Build, comptime name: []const u8, ztg_mod: *std.Build.Module, create_options: std.Build.Module.CreateOptions) *std.Build.Module {
    _ = b.addModule(name, create_options);

    const mod = b.createModule(create_options);
    mod.addImport("ztg", ztg_mod);

    const exe_unit_tests = b.addTest(.{ .root_module = mod });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step(name ++ "-test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    return mod;
}

const NamedModule = struct {
    name: []const u8,
    mod: *std.Build.Module,
};

pub fn setupModules(root_module: *std.Build.Module, ztg_fw_dep: *std.Build.Dependency, options: struct {
    zentig: *std.Build.Module,
    raylib: ?NamedModule = null,
    box2d: ?NamedModule = null,
}) void {
    if (options.raylib) |rl| {
        const rl_fw = ztg_fw_dep.module("raylib");
        rl_fw.addImport("raylib", rl.mod);
        rl_fw.addImport("ztg", options.zentig);
        root_module.addImport(rl.name, rl_fw);
    }
    if (options.box2d) |b2d| {
        const b2d_fw = ztg_fw_dep.module("box2d");
        b2d_fw.addImport("box2d", b2d.mod);
        b2d_fw.addImport("ztg", options.zentig);
        root_module.addImport(b2d.name, b2d_fw);
    }
}
