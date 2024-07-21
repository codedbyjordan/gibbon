const std = @import("std");
const token = @import("token.zig");
const TokenType = token.TokenType;
const Token = token.Token;

fn isLetter(ch: u8) bool {
    return std.ascii.isAlphabetic(ch) or ch == '_';
}

pub const Lexer = struct {
    input: []const u8,
    position: u32,
    readPosition: u32,
    ch: u8,
    pub fn init(in: []const u8) Lexer {
        var lexer = Lexer{ .input = in, .position = 0, .readPosition = 0, .ch = 0 };
        lexer.readChar();
        return lexer;
    }

    pub fn deinit(self: *Lexer) void {
        self.keywords.deinit();
    }

    pub fn readChar(self: *Lexer) void {
        if (self.readPosition >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.readPosition];
        }

        self.position = self.readPosition;
        self.readPosition += 1;
    }

    pub fn skipWhitespace(self: *Lexer) void {
        while (std.ascii.isWhitespace(self.ch)) {
            self.readChar();
        }
    }

    pub fn nextToken(self: *Lexer) Token {
        var tok: Token = undefined;

        self.skipWhitespace();
        switch (self.ch) {
            '=' => {
                const peek = self.peekChar();
                if (peek == '=') {
                    self.readChar();
                    tok = newToken(TokenType.eq, "==");
                } else {
                    tok = newToken(TokenType.assign, "=");
                }
            },
            ';' => tok = newToken(TokenType.semicolon, ";"),
            '(' => tok = newToken(TokenType.lparen, "("),
            ')' => tok = newToken(TokenType.rparen, ")"),
            ',' => tok = newToken(TokenType.comma, ","),
            '+' => tok = newToken(TokenType.plus, "+"),
            '-' => tok = newToken(TokenType.minus, "-"),
            '!' => {
                const peek = self.peekChar();
                if (peek == '=') {
                    self.readChar();
                    tok = newToken(TokenType.not_eq, "!=");
                } else {
                    tok = newToken(TokenType.bang, "!");
                }
            },
            '*' => tok = newToken(TokenType.asterisk, "*"),
            '/' => tok = newToken(TokenType.slash, "/"),
            '<' => tok = newToken(TokenType.lt, "<"),
            '>' => tok = newToken(TokenType.gt, ">"),
            '{' => tok = newToken(TokenType.lbrace, "{"),
            '}' => tok = newToken(TokenType.rbrace, "}"),
            0 => tok = newToken(TokenType.eof, ""),
            else => {
                if (isLetter(self.ch)) {
                    tok.literal = self.readIdentifier();
                    tok.tokenType = token.lookupIdent(tok.literal);
                    return tok;
                } else if (std.ascii.isDigit(self.ch)) {
                    tok.tokenType = .int;
                    tok.literal = self.readNumber();
                    return tok;
                } else {
                    tok = newToken(TokenType.illegal, &[_]u8{self.ch});
                }
            },
        }

        self.readChar();
        return tok;
    }

    fn newToken(tokenType: TokenType, literal: []const u8) Token {
        return Token{ .tokenType = tokenType, .literal = literal };
    }

    fn readIdentifier(self: *Lexer) []const u8 {
        const position = self.position;
        while (isLetter(self.ch)) {
            self.readChar();
        }
        return self.input[position..self.position];
    }

    fn readNumber(self: *Lexer) []const u8 {
        const position = self.position;
        while (std.ascii.isDigit(self.ch)) {
            self.readChar();
        }
        return self.input[position..self.position];
    }

    fn peekChar(self: *Lexer) u8 {
        if (self.readPosition >= self.input.len) {
            return 0;
        } else {
            return self.input[self.readPosition];
        }
    }
};

test "lexer" {
    const input = "=+(){},;";

    const tokenTypes = [_]TokenType{
        .assign,
        .plus,
        .lparen,
        .rparen,
        .lbrace,
        .rbrace,
        .comma,
        .semicolon,
        .eof,
    };

    var lexer = Lexer.init(input);

    for (tokenTypes) |expectedType| {
        const t = lexer.nextToken();
        try std.testing.expectEqual(expectedType, t.tokenType);
        try std.testing.expectEqual(expectedType.asString(), t.literal);
    }
}

test "lexer - nextToken" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\let add = fn(x, y) {
        \\x + y;
        \\};
        \\let result = add(five, ten);
        \\ !-/*5;
        \\5 < 10 > 5;
        \\if (5 < 10) {
        \\return true;
        \\} else {
        \\return false;
        \\}
        \\10 == 10;
        \\10 != 9;
    ;

    const expectedTokens = [_]struct { tokenType: TokenType, literal: []const u8 }{
        .{ .tokenType = .keyword_let, .literal = "let" },
        .{ .tokenType = .ident, .literal = "five" },
        .{ .tokenType = .assign, .literal = "=" },
        .{ .tokenType = .int, .literal = "5" },
        .{ .tokenType = .semicolon, .literal = ";" },
        .{ .tokenType = .keyword_let, .literal = "let" },
        .{ .tokenType = .ident, .literal = "ten" },
        .{ .tokenType = .assign, .literal = "=" },
        .{ .tokenType = .int, .literal = "10" },
        .{ .tokenType = .semicolon, .literal = ";" },
        .{ .tokenType = .keyword_let, .literal = "let" },
        .{ .tokenType = .ident, .literal = "add" },
        .{ .tokenType = .assign, .literal = "=" },
        .{ .tokenType = .keyword_function, .literal = "fn" },
        .{ .tokenType = .lparen, .literal = "(" },
        .{ .tokenType = .ident, .literal = "x" },
        .{ .tokenType = .comma, .literal = "," },
        .{ .tokenType = .ident, .literal = "y" },
        .{ .tokenType = .rparen, .literal = ")" },
        .{ .tokenType = .lbrace, .literal = "{" },
        .{ .tokenType = .ident, .literal = "x" },
        .{ .tokenType = .plus, .literal = "+" },
        .{ .tokenType = .ident, .literal = "y" },
        .{ .tokenType = .semicolon, .literal = ";" },
        .{ .tokenType = .rbrace, .literal = "}" },
        .{ .tokenType = .semicolon, .literal = ";" },
        .{ .tokenType = .keyword_let, .literal = "let" },
        .{ .tokenType = .ident, .literal = "result" },
        .{ .tokenType = .assign, .literal = "=" },
        .{ .tokenType = .ident, .literal = "add" },
        .{ .tokenType = .lparen, .literal = "(" },
        .{ .tokenType = .ident, .literal = "five" },
        .{ .tokenType = .comma, .literal = "," },
        .{ .tokenType = .ident, .literal = "ten" },
        .{ .tokenType = .rparen, .literal = ")" },
        .{ .tokenType = .semicolon, .literal = ";" },
        .{ .tokenType = .bang, .literal = "!" },
        .{ .tokenType = .minus, .literal = "-" },
        .{ .tokenType = .slash, .literal = "/" },
        .{ .tokenType = .asterisk, .literal = "*" },
        .{ .tokenType = .int, .literal = "5" },
        .{ .tokenType = .semicolon, .literal = ";" },
        .{ .tokenType = .int, .literal = "5" },
        .{ .tokenType = .lt, .literal = "<" },
        .{ .tokenType = .int, .literal = "10" },
        .{ .tokenType = .gt, .literal = ">" },
        .{ .tokenType = .int, .literal = "5" },
        .{ .tokenType = .semicolon, .literal = ";" },
        .{ .tokenType = .keyword_if, .literal = "if" },
        .{ .tokenType = .lparen, .literal = "(" },
        .{ .tokenType = .int, .literal = "5" },
        .{ .tokenType = .lt, .literal = "<" },
        .{ .tokenType = .int, .literal = "10" },
        .{ .tokenType = .rparen, .literal = ")" },
        .{ .tokenType = .lbrace, .literal = "{" },
        .{ .tokenType = .keyword_return, .literal = "return" },
        .{ .tokenType = .keyword_true, .literal = "true" },
        .{ .tokenType = .semicolon, .literal = ";" },
        .{ .tokenType = .rbrace, .literal = "}" },
        .{ .tokenType = .keyword_else, .literal = "else" },
        .{ .tokenType = .lbrace, .literal = "{" },
        .{ .tokenType = .keyword_return, .literal = "return" },
        .{ .tokenType = .keyword_false, .literal = "false" },
        .{ .tokenType = .semicolon, .literal = ";" },
        .{ .tokenType = .rbrace, .literal = "}" },
        .{ .tokenType = .int, .literal = "10" },
        .{ .tokenType = .eq, .literal = "==" },
        .{ .tokenType = .int, .literal = "10" },
        .{ .tokenType = .semicolon, .literal = ";" },
        .{ .tokenType = .int, .literal = "10" },
        .{ .tokenType = .not_eq, .literal = "!=" },
        .{ .tokenType = .int, .literal = "9" },
        .{ .tokenType = .semicolon, .literal = ";" },
        .{ .tokenType = .eof, .literal = "" },
    };

    var lexer = Lexer.init(input);

    for (expectedTokens) |expected| {
        const t = lexer.nextToken();
        try std.testing.expectEqual(expected.tokenType, t.tokenType);
        try std.testing.expectEqualStrings(expected.literal, t.literal);
    }
}
