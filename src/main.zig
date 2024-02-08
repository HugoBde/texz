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
var original_termios: c.struct_termios = undefined;

/// Perform Init actions
/// Init Actions:
///     - Enter canonical mode
fn init() void {
    // Get
    _ = c.tcgetattr(c.STDIN_FILENO, &original_termios);

    var raw = original_termios;

    _ = io.getStdOut().writer().print("{b}\n", .{raw.c_iflag}) catch {};
    c.cfmakeraw(&raw);
    _ = io.getStdOut().writer().print("{b}\n", .{raw.c_iflag}) catch {};

    raw.c_cc[c.VMIN] = 1;
    raw.c_cc[c.VTIME] = 0;

    _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &raw);
}

fn clean_up() void {
    _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &original_termios);
}

pub fn main() !void {
    init();
    defer clean_up();

    const stdin = io.getStdIn().reader();
    const stdout = io.getStdOut().writer();

    var buffer: [1]u8 = undefined;
    _ = try stdin.read(&buffer);
    while (buffer[0] != 'q') {
        try stdout.print("user input > 0x{x} {c}\n", .{ buffer[0], buffer[0] });
        _ = try stdin.read(&buffer);
    }

    try stdout.print("EXITING\n", .{});
}
