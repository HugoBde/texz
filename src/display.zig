const std = @import("std");

const c = @import("c.zig");
const buffer = @import("buffer.zig");
const terminal = @import("terminal.zig");

const stdout = std.io.getStdOut().writer();

pub var display_dimensions: c.struct_winsize = undefined;

pub fn update_display_dimensions() !void {
    _ = c.ioctl(c.STDOUT_FILENO, c.TIOCGWINSZ, &display_dimensions);
}

pub fn update_display() !void {
    terminal.hide_cursor();
    defer terminal.show_cursor();

    terminal.move_cursor(1, 1);

    var lines = std.mem.splitScalar(u8, buffer.file.content, '\n');
    var line_num: usize = 1;

    while (lines.next()) |line| : (line_num += 1) {
        if (line_num >= display_dimensions.ws_row)
            break;

        try stdout.print("{d: >3} | {s}\r\n", .{ line_num, line });
    }

    while (line_num < display_dimensions.ws_row) : (line_num += 1) {
        try stdout.writeAll("~\r\n");
    }

    terminal.move_cursor(buffer.cursor.row, buffer.cursor.col);
}

pub fn sigwinch_handler(_: c_int) callconv(.C) void {
    update_display_dimensions() catch {};
    update_display() catch {};
}
