const std = @import("std");

pub const DebugRectangle = struct {
    size: 
};

pub fn wrapper(rl: type) type {
    return struct {
        pub const ButtonType = union(enum) {
            keyboard: rl.KeyboardKey,
            mouse: rl.MouseButton,
            gamepad: rl.GamepadButton,

            fn fromString(str: []const u8, value0: i32, value1: i32) !ButtonType {
                _ = value1; // autofix
                if (str[0] == 'k') {
                    return .{ .keyboard = @enumFromInt(value0) };
                } else if (str[0] == 'm') {
                    return .{ .mouse = @enumFromInt(value0) };
                } else if (str[0] == 'g') {
                    return .{ .gamepad = value0 };
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
            gamepad: struct {
                axis: rl.GamepadAxis,
                modifier: f32,
                deadzone: f32,
            },

            fn fromString(str: []const u8, value0: i32, value1: i32) !AxisType {
                if (str[0] == 'k') {
                    return .{ .keyboard = .{
                        .positive = @enumFromInt(value0),
                        .negative = @enumFromInt(value1),
                    } };
                } else if (str[0] == 'g') {
                    return .{ .gamepad = .{
                        .gamepad = value0,
                        .axis = @enumFromInt(value1),
                    } };
                } else {
                    if (str[str.len - 1] == 'x') {
                        return .mouse_x;
                    } else if (str[str.len - 1] == 'y') {
                        return .mouse_y;
                    }
                }
                return error.CouldNotConvertFromString;
            }

            pub fn kb(pos: rl.KeyboardKey, neg: rl.KeyboardKey) AxisType {
                return .{ .keyboard = .{
                    .positive = pos,
                    .negative = neg,
                } };
            }

            pub fn gp(axis: rl.GamepadAxis, modifier: f32, deadzone: f32) AxisType {
                return .{ .gamepad = .{
                    .axis = axis,
                    .modifier = modifier,
                    .deadzone = deadzone,
                } };
            }
        };

        pub fn isButtonPressed(controller_index: usize, button: ButtonType) bool {
            return switch (button) {
                .keyboard => |kb| rl.IsKeyPressed(kb),
                .mouse => |ms| rl.IsMouseButtonPressed(ms),
                .gamepad => |gp| rl.IsGamepadButtonPressed(@intCast(controller_index - 1), gp),
            };
        }

        pub fn isButtonDown(controller_index: usize, button: ButtonType) bool {
            return switch (button) {
                .keyboard => |kb| rl.IsKeyDown(kb),
                .mouse => |ms| rl.IsMouseButtonDown(ms),
                .gamepad => |gp| rl.IsGamepadButtonDown(@intCast(controller_index - 1), gp),
            };
        }

        pub fn isButtonReleased(controller_index: usize, button: ButtonType) bool {
            return switch (button) {
                .keyboard => |kb| rl.IsKeyReleased(kb),
                .mouse => |ms| rl.IsMouseButtonReleased(ms),
                .gamepad => |gp| rl.IsGamepadButtonReleased(@intCast(controller_index - 1), gp),
            };
        }

        pub fn getAxis(controller_index: usize, axis: AxisType) f32 {
            return switch (axis) {
                .keyboard => |kb| blk: {
                    var val: f32 = 0.0;
                    if (rl.IsKeyDown(kb.positive)) val += 1.0;
                    if (rl.IsKeyDown(kb.negative)) val -= 1.0;
                    break :blk val;
                },
                .mouse_x => rl.GetMouseDelta().x,
                .mouse_y => rl.GetMouseDelta().y,
                .gamepad => |gp| gamepad: {
                    const axis_raw = rl.GetGamepadAxisMovement(@intCast(controller_index), gp.axis);
                    break :gamepad if (@abs(axis_raw) > gp.deadzone) axis_raw * gp.modifier else 0;
                },
            };
        }

        pub fn exportButtonBinding(writer: anytype, button: ButtonType) !void {
            const button_fmt: struct { i32, i32 } = switch (button) {
                .keyboard => |kb| .{ @intFromEnum(kb), 0 },
                .mouse => |ms| .{ @intFromEnum(ms), 0 },
                .gamepad => |gp| .{ -1, @intFromEnum(gp) },
            };
            try writer.print("{s}|{} {}|", .{ @tagName(button), button_fmt[0], button_fmt[1] });
        }

        pub fn exportAxisBinding(writer: anytype, axis: AxisType) !void {
            const axis_fmt: struct { i32, i32 } = switch (axis) {
                .keyboard => |kb| .{ @intFromEnum(kb.positive), @intFromEnum(kb.negative) },
                .mouse_x => .{ 0, 0 },
                .mouse_y => .{ 0, 0 },
                .gamepad => |gp| .{ -1, @intFromEnum(gp) },
            };
            try writer.print("{s}|{} {}|", .{ @tagName(axis), axis_fmt[0], axis_fmt[1] });
        }

        pub fn importButtonBinding(str: []const u8) !ButtonType {
            const name, const val0, const val1 = try getEnumTagNameAndVals(str);
            return .fromString(name, val0, val1);
        }

        pub fn importAxisBinding(str: []const u8) !AxisType {
            const name, const val0, const val1 = try getEnumTagNameAndVals(str);
            return .fromString(name, val0, val1);
        }

        fn getEnumTagNameAndVals(str: []const u8) !struct { []const u8, i32, i32 } {
            const enum_type_end = std.mem.indexOfScalar(u8, str, '|') orelse return error.BadFormat;
            const value_splitter_idx = std.mem.indexOfScalar(u8, str[enum_type_end..], ' ') orelse return error.BadFormat;

            const value0 = try std.fmt.parseInt(i32, str[enum_type_end + 1 ..][0 .. value_splitter_idx - 1], 10);
            const value1 = try std.fmt.parseInt(i32, str[enum_type_end..][value_splitter_idx + 1 .. str.len - enum_type_end - 1], 10);

            return .{ str[0..enum_type_end], value0, value1 };
        }

        /// Binds axes and buttons added in `.setupMouse()`
        pub fn bindMouse(controller: usize, input: anytype) !void {
            try input.addAxisBinding(controller, .mouse_x, .mouse_x);
            try input.addAxisBinding(controller, .mouse_y, .mouse_y);
            try input.addButtonBinding(controller, .mouse_left, .{ .mouse = rl.MOUSE_BUTTON_LEFT });
            try input.addButtonBinding(controller, .mouse_right, .{ .mouse = rl.MOUSE_BUTTON_RIGHT });
            try input.addButtonBinding(controller, .mouse_middle, .{ .mouse = rl.MOUSE_BUTTON_MIDDLE });
            try input.addButtonBinding(controller, .mouse_side, .{ .mouse = rl.MOUSE_BUTTON_SIDE });
            try input.addButtonBinding(controller, .mouse_extra, .{ .mouse = rl.MOUSE_BUTTON_EXTRA });
            try input.addButtonBinding(controller, .mouse_forward, .{ .mouse = rl.MOUSE_BUTTON_FORWARD });
            try input.addButtonBinding(controller, .mouse_back, .{ .mouse = rl.MOUSE_BUTTON_BACK });
        }
    };
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
