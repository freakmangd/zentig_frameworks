const std = @import("std");
const ztg = @import("ztg");
const rl = @import("raylib");

pub fn includeWorld(wb: *ztg.WorldBuilder, draw_stage_2d: anytype, draw_stage_3d: anytype) void {
    wb.include(&.{ztg.base});
    wb.addComponents(&.{ DebugRectangle, DebugCube });
    if (@TypeOf(draw_stage_2d) != @TypeOf(null)) {
        wb.addSystemsToStage(draw_stage_2d, .{DebugRectangle.draw});
    }
    if (@TypeOf(draw_stage_3d) != @TypeOf(null)) {
        wb.addSystemsToStage(draw_stage_3d, .{DebugCube.draw});
    }
}

pub fn drawThroughCams2d(gpa: std.mem.Allocator, world: anytype, stage: anytype) !void {
    const query = try world.query(gpa, ztg.Query(.{rl.Camera2D}));
    defer query.deinit(gpa);

    for (query.items(rl.Camera2D)) |cam| {
        rl.BeginMode2D(cam.*);
        defer rl.EndMode2D();

        try world.runStage(stage);
    }
}

pub fn drawThroughCams3d(gpa: std.mem.Allocator, world: anytype, stage: anytype) !void {
    const query = try world.query(gpa, ztg.Query(.{rl.Camera3D}));
    defer query.deinit(gpa);

    for (query.items(rl.Camera3D)) |cam| {
        rl.BeginMode3D(cam.*);
        defer rl.EndMode3D();

        try world.runStage(stage);
    }
}

pub const DebugRectangle = struct {
    offset: ztg.Vec2 = .zero,
    size: ztg.Vec2,
    color: rl.Color = .red,
    filled: bool = false,

    pub fn draw(q: ztg.Query(.{ ztg.base.Transform, DebugRectangle })) void {
        for (q.items(ztg.base.Transform), q.items(DebugRectangle)) |tr, dr| {
            const pos = tr.getPos().flatten().add(dr.offset);

            if (dr.filled)
                rl.DrawRectangleV(pos.into(rl.Vector2), dr.size.into(rl.Vector2), dr.color)
            else
                rl.DrawRectangleLinesEx(.{
                    .x = pos.x,
                    .y = pos.y,
                    .width = dr.size.x,
                    .height = dr.size.y,
                }, 1, dr.color);
        }
    }
};

pub const DebugCube = struct {
    offset: ztg.Vec3 = .zero,
    size: ztg.Vec3,
    color: rl.Color = .red,
    filled: bool = false,

    pub fn draw(q: ztg.Query(.{ ztg.base.Transform, DebugCube })) void {
        for (q.items(ztg.base.Transform), q.items(DebugCube)) |tr, db| {
            if (db.filled)
                rl.DrawCubeV(tr.getPos().add(db.offset).into(rl.Vector3), db.size.into(rl.Vector3), db.color)
            else
                rl.DrawCubeWiresV(tr.getPos().add(db.offset).into(rl.Vector3), db.size.into(rl.Vector3), db.color);
        }
    }
};

pub const input = struct {
    pub const InputSource = union(enum) {
        kb_ms,
        gamepad: usize,
    };

    pub const ButtonType = union(enum) {
        keyboard: rl.KeyboardKey,
        mouse: rl.MouseButton,
        gamepad: rl.GamepadButton,

        fn fromString(str: []const u8, value0: i32) !ButtonType {
            if (str[0] == 'k') {
                return .{ .keyboard = @enumFromInt(value0) };
            } else if (str[0] == 'm') {
                return .{ .mouse = @enumFromInt(value0) };
            } else if (str[0] == 'g') {
                return .{ .gamepad = @enumFromInt(value0) };
            }
            return error.CouldNotConvertFromString;
        }

        pub fn kb(key: rl.KeyboardKey) ButtonType {
            return .{ .keyboard = key };
        }

        pub fn ms(button: rl.MouseButton) ButtonType {
            return .{ .mouse = button };
        }

        pub fn gp(button: rl.GamepadButton) ButtonType {
            return .{ .gamepad = button };
        }
    };

    pub const AxisType = union(enum) {
        keyboard: struct {
            positive: rl.KeyboardKey,
            negative: rl.KeyboardKey,
        },
        mouse_x,
        mouse_y,
        gamepad: rl.GamepadAxis,

        fn fromString(str: []const u8, value0: i32, value1: i32) !AxisType {
            if (str[0] == 'k') {
                return .{ .keyboard = .{
                    .positive = @enumFromInt(value0),
                    .negative = @enumFromInt(value1),
                } };
            } else if (str[0] == 'g') {
                return .{ .gamepad = @enumFromInt(value1) };
            } else {
                if (str[str.len - 1] == 'x') {
                    return .mouse_x;
                } else if (str[str.len - 1] == 'y') {
                    return .mouse_y;
                }
            }
            return error.CouldNotConvertFromString;
        }

        pub fn kb(negative: rl.KeyboardKey, positive: rl.KeyboardKey) AxisType {
            return .{ .keyboard = .{
                .positive = positive,
                .negative = negative,
            } };
        }

        pub fn gp(axis: rl.GamepadAxis) AxisType {
            return .{ .gamepad = axis };
        }
    };

    pub fn isButtonPressed(source: InputSource, button: ButtonType) bool {
        return switch (source) {
            .kb_ms => switch (button) {
                .keyboard => |kb| rl.IsKeyPressed(kb),
                .mouse => |ms| rl.IsMouseButtonPressed(ms),
                else => unreachable,
            },
            .gamepad => |num| rl.IsGamepadButtonPressed(@intCast(num), button.gamepad),
        };
    }

    pub fn isButtonDown(source: InputSource, button: ButtonType) bool {
        return switch (source) {
            .kb_ms => switch (button) {
                .keyboard => |kb| rl.IsKeyDown(kb),
                .mouse => |ms| rl.IsMouseButtonDown(ms),
                else => unreachable,
            },
            .gamepad => |num| rl.IsGamepadButtonDown(@intCast(num), button.gamepad),
        };
    }

    pub fn isButtonReleased(source: InputSource, button: ButtonType) bool {
        return switch (source) {
            .kb_ms => switch (button) {
                .keyboard => |kb| rl.IsKeyReleased(kb),
                .mouse => |ms| rl.IsMouseButtonReleased(ms),
                else => unreachable,
            },
            .gamepad => |num| rl.IsGamepadButtonReleased(@intCast(num), button.gamepad),
        };
    }

    pub fn getAxis(source: InputSource, axis: AxisType) f32 {
        return switch (source) {
            .kb_ms => switch (axis) {
                .keyboard => |kb| blk: {
                    var val: f32 = 0.0;
                    if (rl.IsKeyDown(kb.positive)) val += 1.0;
                    if (rl.IsKeyDown(kb.negative)) val -= 1.0;
                    break :blk val;
                },
                .mouse_x => rl.GetMouseDelta().x,
                .mouse_y => rl.GetMouseDelta().y,
                else => unreachable,
            },
            .gamepad => |num| rl.GetGamepadAxisMovement(@intCast(num), axis.gamepad),
        };
    }

    pub fn exportButtonBinding(writer: anytype, button: ButtonType) !void {
        const button_fmt = switch (button) {
            .keyboard => |kb| @intFromEnum(kb),
            .mouse => |ms| @intFromEnum(ms),
            .gamepad => |gp| @intFromEnum(gp),
        };
        try writer.print("{s},{}", .{ @tagName(button), button_fmt });
    }

    pub fn exportAxisBinding(writer: anytype, axis: AxisType) !void {
        try writer.print("{s}", .{@tagName(axis)});
        switch (axis) {
            .mouse_x, .mouse_y => {},
            .keyboard => |kb| try writer.print(",{},{}", .{ @intFromEnum(kb.positive), @intFromEnum(kb.negative) }),
            .gamepad => |gp| try writer.print(",{}", .{@intFromEnum(gp)}),
        }
    }

    pub fn importButtonBinding(str: []const u8) !ButtonType {
        const tn_and_vals = try getEnumTagNameAndVals(str);
        return ButtonType.fromString(tn_and_vals[0], tn_and_vals[1]);
    }

    pub fn importAxisBinding(str: []const u8) !AxisType {
        const tn_and_vals = try getEnumTagNameAndVals(str);
        return AxisType.fromString(tn_and_vals[0], tn_and_vals[1], tn_and_vals[2]);
    }

    fn getEnumTagNameAndVals(str: []const u8) !struct { []const u8, i32, i32 } {
        const enum_type_end = std.mem.indexOfScalar(u8, str, '|') orelse return error.BadFormat;
        const value_splitter_idx = std.mem.indexOfScalar(u8, str[enum_type_end..], ' ') orelse return error.BadFormat;

        const value0 = try std.fmt.parseInt(i32, str[enum_type_end + 1 ..][0 .. value_splitter_idx - 1], 10);
        const value1 = try std.fmt.parseInt(i32, str[enum_type_end..][value_splitter_idx + 1 .. str.len - enum_type_end - 1], 10);

        return .{ str[0..enum_type_end], value0, value1 };
    }

    /// Binds axes and buttons added in `.setupMouse()`
    pub fn bindMouse(controller: usize, in: anytype) !void {
        try in.addAxisBinding(controller, .mouse_x, .mouse_x);
        try in.addAxisBinding(controller, .mouse_y, .mouse_y);
        try in.addButtonBinding(controller, .mouse_left, .{ .mouse = rl.MOUSE_BUTTON_LEFT });
        try in.addButtonBinding(controller, .mouse_right, .{ .mouse = rl.MOUSE_BUTTON_RIGHT });
        try in.addButtonBinding(controller, .mouse_middle, .{ .mouse = rl.MOUSE_BUTTON_MIDDLE });
        try in.addButtonBinding(controller, .mouse_side, .{ .mouse = rl.MOUSE_BUTTON_SIDE });
        try in.addButtonBinding(controller, .mouse_extra, .{ .mouse = rl.MOUSE_BUTTON_EXTRA });
        try in.addButtonBinding(controller, .mouse_forward, .{ .mouse = rl.MOUSE_BUTTON_FORWARD });
        try in.addButtonBinding(controller, .mouse_back, .{ .mouse = rl.MOUSE_BUTTON_BACK });
    }

    pub const MouseButtons = enum {
        mouse_left,
        mouse_right,
        mouse_middle,
        mouse_side,
        mouse_extra,
        mouse_forward,
        mouse_back,
    };
    pub const MouseAxes = enum {
        mouse_x,
        mouse_y,
    };
};

test {
    _ = input;
    _ = DebugCube;
    _ = DebugRectangle;
}

test "input" {
    const Input = ztg.input.Build(input, enum {
        button_a,
        button_b,
    }, enum {
        axis_a,
        axis_b,
    }, .{});

    const World = comptime World: {
        var wb: ztg.WorldBuilder = .init(&.{Input});
        wb.addStage(.draw_3d);
        includeWorld(&wb, .draw, .draw_3d);
        break :World wb.Build();
    };

    var world: World = try .init(std.testing.allocator, .{});
    defer world.deinit();

    const input_ptr = world.getResPtr(Input);
    try input_ptr.addBindings(.{
        .buttons = .{
            .button_a = &.{ .kb(.a), .gp(.right_face_down), .ms(.left) },
            .button_b = &.{ .kb(.b), .gp(.right_face_right), .ms(.right) },
        },
        .axes = .{
            .axis_a = &.{ .kb(.left, .right), .gp(.left_x), .mouse_x },
            .axis_b = &.{ .kb(.up, .down), .gp(.left_y), .mouse_y },
        },
    });

    try world.runStage(.load);
    try world.runUpdateStages();
    try world.runStage(.draw);
    world.cleanForNextFrame();

    var wa: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer wa.deinit();

    try input_ptr.writeBindings(&wa.writer);

    const bindings_str = try wa.toOwnedSlice();
    const expected_str =
        \\buttons:
        \\button_a=keyboard,65
        \\button_a=gamepad,7
        \\button_a=mouse,0
        \\button_b=keyboard,66
        \\button_b=gamepad,6
        \\button_b=mouse,1
        \\axes:
        \\axis_a=keyboard,263,262
        \\axis_a=gamepad,0
        \\axis_a=mouse_x
        \\axis_b=keyboard,265,264
        \\axis_b=gamepad,1
        \\axis_b=mouse_y
        \\
    ;
    wa.clearRetainingCapacity();

    try std.testing.expectEqualStrings(expected_str, bindings_str);

    input_ptr.clearBindings();

    var expected_reader: std.Io.Reader = .fixed(expected_str);
    try std.testing.expect(input_ptr.readBindings(&expected_reader));
    try input_ptr.writeBindings(&wa.writer);

    try std.testing.expectEqualStrings(expected_str, wa.written());
}
