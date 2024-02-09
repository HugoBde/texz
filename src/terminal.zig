const io = @import("std").io;

const stdout = io.getStdOut().writer();

const Terminal = struct {
    height: u32,
    width: u32,
};

pub const EscapeCode = enum {
    CURSOR_UP,
    CURSOR_DOWN,
    CURSOR_FORWARD,
    CURSOR_BACK,
    CLEAR_SCREEN,
    ENABLE_ALTERNATE_BUFFER,
    DISABLE_ALTERNATE_BUFFER,
};

fn getEscapeCodeSequence(escape_code: EscapeCode) []const u8 {
    return switch (escape_code) {
        .CURSOR_UP => "\x1b[A",
        .CURSOR_DOWN => "\x1b[B",
        .CURSOR_FORWARD => "\x1b[C",
        .CURSOR_BACK => "\x1b[D",
        .CLEAR_SCREEN => "\x1b[3J",
        .ENABLE_ALTERNATE_BUFFER => "\x1b[?1049h",
        .DISABLE_ALTERNATE_BUFFER => "\x1b[?1049l",
    };
}

pub fn printEscapeCode(escape_code: EscapeCode) void {
    _ = stdout.write(getEscapeCodeSequence(escape_code)) catch {};
}
