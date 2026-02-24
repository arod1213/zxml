const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const c = @import("lib.zig").c;
const types = @import("./types.zig");
const utils = @import("utils.zig");
const Node = types.Node;

pub fn structToNode(comptime T: type, alloc: Allocator, x: T) !Node {
    const info = @typeInfo(T);
    assert(info == .@"struct");

    const struct_name = utils.simpleTypeName(T);
    var parent: Node = try Node.new(struct_name, null);

    inline for (info.@"struct".fields) |field| {
        const field_info = @typeInfo(field.type);
        const val_str = switch (field_info) {
            .bool => try std.fmt.allocPrint(alloc, "{any}", .{@field(x, field.name)}),
            .int, .float => try std.fmt.allocPrint(alloc, "{d}", .{@field(x, field.name)}),
            .pointer => |ptr| if (ptr.child == u8) @field(x, field.name) else unreachable, // only support []const u8
            .@"struct" => {
                const child_node = try structToNode(field.type, alloc, @field(x, field.name));
                child_node.attach(&parent);
                continue;
            },
            else => unreachable,
        };
        parent.setProperty(field.name, val_str);
    }
    return parent;
}
