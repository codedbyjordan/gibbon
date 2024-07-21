const std = @import("std");
const repl = @import("repl.zig");

pub fn main() !void {
    std.debug.print("Hello! Welcome to the Gibbon programming language.\n", .{});
    try repl.start();
}
