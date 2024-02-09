const io = @import("std").io;

const stdout = io.getStdOut().writer();

const Color = enum {
    WHITE,
    BLACK,
};

const EscapeCodeTag = enum {
    CURSOR_UP,
    CURSOR_DOWN,
    CURSOR_FORWARD,
    CURSOR_BACK,
    CLEAR_SCREEN,
    ENABLE_ALTERNATE_BUFFER,
    DISABLE_ALTERNATE_BUFFER,
    FG_COLOR,
    BG_COLOR,
    RESET_FG_COLOR,
    RESET_BG_COLOR,
    ABSOLUTE_MOVE,
};

pub const EscapeCode = union(EscapeCodeTag) {
    CURSOR_UP: void,
    CURSOR_DOWN: void,
    CURSOR_FORWARD: void,
    CURSOR_BACK: void,
    CLEAR_SCREEN: void,
    ENABLE_ALTERNATE_BUFFER: void,
    DISABLE_ALTERNATE_BUFFER: void,
    FG_COLOR: Color,
    BG_COLOR: Color,
    RESET_FG_COLOR: void,
    RESET_BG_COLOR: void,
    ABSOLUTE_MOVE: struct { x: usize, y: usize },
};

fn getEscapeCodeSequence(escape_code: EscapeCode) []const u8 {
    return switch (escape_code) {
        EscapeCode.CURSOR_UP => "\x1b[A",
        EscapeCode.CURSOR_DOWN => "\x1b[B",
        EscapeCode.CURSOR_FORWARD => "\x1b[C",
        EscapeCode.CURSOR_BACK => "\x1b[D",
        EscapeCode.CLEAR_SCREEN => "\x1b[3J",
        EscapeCode.ENABLE_ALTERNATE_BUFFER => "\x1b[?1049h",
        EscapeCode.DISABLE_ALTERNATE_BUFFER => "\x1b[?1049l",
        EscapeCode.FG_COLOR => |color| switch (color) {
            .WHITE => "\x1b[37m",
            .BLACK => "\x1b[30m",
        },
        EscapeCode.BG_COLOR => |color| switch (color) {
            .WHITE => "\x1b[107m",
            .BLACK => "\x1b[40m",
        },
        EscapeCode.RESET_FG_COLOR => "\x1b[39m",
        EscapeCode.RESET_BG_COLOR => "\x1b[49m",
        EscapeCode.ABSOLUTE_MOVE => |_| "",
    };
}

pub fn printEscapeCode(escape_code: EscapeCode) void {
    _ = stdout.write(getEscapeCodeSequence(escape_code)) catch {};
}

pub fn invertColors() void {
    printEscapeCode(EscapeCode{ .FG_COLOR = Color.BLACK });
    printEscapeCode(EscapeCode{ .BG_COLOR = Color.WHITE });
}

pub fn resetColors() void {
    printEscapeCode(EscapeCode{ .FG_COLOR = Color.WHITE });
    printEscapeCode(EscapeCode{ .BG_COLOR = Color.BLACK });
}

pub fn moveCursor(x: usize, y: usize) void {
    _ = y;
    _ = x;
}
