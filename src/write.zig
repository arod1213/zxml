const std = @import("std");
pub fn header(w: *std.Io.Writer) !void {
    _ = try w.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
    try w.flush();
}
