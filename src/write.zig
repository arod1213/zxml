const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const c = @import("lib.zig").c;
const types = @import("./types.zig");
const utils = @import("utils.zig");
const Node = types.Node;

const ValueType = union(enum) { field: []const u8, child: Node };
fn getValue(alloc: Allocator, comptime T: type, value: T, field_name: []const u8, parent_node: Node) !ValueType {
    const field_info = @typeInfo(T);
    const value_str = switch (field_info) {
        .null => "",
        .optional => |opt| if (value == null) "" else try getValue(opt.child, alloc, field_name, value),
        .bool => try std.fmt.allocPrint(alloc, "{any}", .{value}),
        .int,
        .comptime_int,
        .float,
        .comptime_float,
        => try std.fmt.allocPrint(alloc, "{d}", .{value}),
        .pointer => |ptr| if (ptr.child == u8) value else unreachable, // only support []const u8
        .@"struct" => {
            const child_node = try structToNode(T, alloc, value);
            child_node.attach(&parent_node);
            return .{ .child = child_node };
        },
        else => unreachable,
    };
    return .{ .field = value_str };
}

pub fn structToNode(comptime T: type, alloc: Allocator, x: T) !Node {
    const info = @typeInfo(T);
    assert(info == .@"struct");

    const struct_name = utils.simpleTypeName(T);
    var parent: Node = try Node.new(struct_name, null);

    inline for (info.@"struct".fields) |field| {
        const value = try getValue(alloc, field.type, @field(x, field.name), field.name, parent);
        switch (value) {
            .field => |f| parent.setProperty(field.name, f),
            .child => {},
        }
    }
    return parent;
}
