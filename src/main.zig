const std = @import("std");
const fs = std.fs;
const io = std.io;
const os = std.os;

fn enter_canonical_mode(tty: fs.File, original_termios: os.termios) !void {
    // const stdout = io.getStdOut().writer();
    try os.tcsetattr(tty.handle, .FLUSH, original_termios);
    // try stdout.writeAll("\x1B[?1049l"); // Disable alternative buffer.
    // try stdout.writeAll("\x1B[?47l"); // Restore screen.
    // try stdout.writeAll("\x1B[u"); // Restore cursor position.
}

fn enter_raw_mode(tty: fs.File, original_termios: os.termios) !void {
    // const stdout = io.getStdOut().writer();

    var raw = original_termios;
    raw.cc[os.system.V.TIME] = 0;
    raw.cc[os.system.V.MIN] = 1;

    try os.tcsetattr(tty.handle, .FLUSH, raw);
    // try stdout.writeAll("\x1B[?25l"); // Hide the cursor.
    // try stdout.writeAll("\x1B[s"); // Save cursor position.
    // try stdout.writeAll("\x1B[?47h"); // Save screen.
    // try stdout.writeAll("\x1B[?1049h"); // Enable alternative buffer.
}

pub fn main() !void {
    const tty: fs.File = try fs.cwd().openFile("/dev/tty", .{ .mode = fs.File.OpenMode.read_write });
    defer tty.close();

    const original_termios = try os.tcgetattr(tty.handle);
    try enter_raw_mode(tty, original_termios);
    defer enter_canonical_mode(tty, original_termios) catch {};

    const stdout = io.getStdOut().writer();
    const stdin = io.getStdIn().reader();
    var buffer: [1]u8 = undefined;

    _ = try stdin.read(&buffer);

    while (buffer[0] != 'q') {
        try stdout.print("user input > {c}\n", .{buffer[0]});
        _ = try stdin.read(&buffer);
    }
}
