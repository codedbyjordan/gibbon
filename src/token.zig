const std = @import("std");

pub const TokenType = enum {
    eof,
    illegal,
    ident,
    int,
    comma,
    semicolon,
    lparen,
    rparen,
    lbrace,
    rbrace,
    keyword_function,
    keyword_let,
    keyword_if,
    keyword_true,
    keyword_false,
    keyword_else,
    keyword_return,
    assign,
    plus,
    minus,
    bang,
    asterisk,
    slash,
    lt,
    gt,
    eq,
    not_eq,

    pub fn asString(self: TokenType) []const u8 {
        return switch (self) {
            .ident => "ident",
            .int => "int",
            .assign => "=",
            .plus => "+",
            .minus => "-",
            .bang => "!",
            .asterisk => "*",
            .slash => "/",
            .lt => "<",
            .gt => ">",
            .comma => ",",
            .semicolon => ";",
            .lparen => "(",
            .rparen => ")",
            .lbrace => "{",
            .rbrace => "}",
            .eq => "==",
            .not_eq => "!=",
            .keyword_function => "function",
            .keyword_let => "let",
            .keyword_if => "if",
            .keyword_true => "true",
            .keyword_false => "false",
            .keyword_else => "else",
            .keyword_return => "return",
            .illegal => "illegal",
            .eof => "",
        };
    }
};

pub const keywords = std.StaticStringMap(TokenType).initComptime(.{ .{ "let", .keyword_let }, .{ "fn", .keyword_function }, .{ "true", .keyword_true }, .{ "false", .keyword_false }, .{ "if", .keyword_if }, .{ "else", .keyword_else }, .{ "return", .keyword_return } });

pub fn lookupIdent(ident: []const u8) TokenType {
    return keywords.get(ident) orelse .ident;
}

pub const Token = struct {
    tokenType: TokenType,
    literal: []const u8,
};
