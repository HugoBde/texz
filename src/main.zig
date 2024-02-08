const std = @import("std");
const io = std.io;

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("termios.h");
    @cInclude("unistd.h");
});

/// # Original Termios struct
/// Used to reset terminal on exit
const original_termios: c.struct_termios = undefined;

fn print_anything(prefix_msg: []const u8, thing: anytype, postfix_msg: []const u8) void {
    std.log.debug(prefix_msg);
    inline for (std.meta.fields(@TypeOf(thing))) |f| {
        std.log.debug(f.name ++ " {any}\n", .{@as(f.type, @field(thing, f.name))});
    }
    std.log.debug(postfix_msg);
}

/// Perform Init actions
/// Init Actions:
///     - Enter canonical mode
fn init() !void {
    // Get
    _ = c.tcgetattr(c.STDIN_FILENO, &original_termios);

    var raw = original_termios;

    raw.c_cc[c.VMIN] = 1;
    raw.c_cc[c.VTIME] = 0;
    raw.c_iflag = c.ICANON;

    _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &raw);
}

pub fn main() !void {
    try init();
}
