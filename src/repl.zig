const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const TokenType = @import("token.zig").TokenType;

const prompt = ">>";

pub fn start() !void {
    while (true) {
        const stdin = std.io.getStdIn().reader();
        std.debug.print(">> ", .{});
        const bare_line = try stdin.readUntilDelimiterAlloc(
            std.heap.page_allocator,
            '\n',
            8192,
        );
        defer std.heap.page_allocator.free(bare_line);

        const line = std.mem.trim(u8, bare_line, "\r");

        var lexer = Lexer.init(line);

        while (true) {
            const token = lexer.nextToken();
            std.debug.print("{}\n", .{token});
            if (token.tokenType == TokenType.eof) break;
        }
        std.debug.print("{s}\n", .{line});
    }
}
