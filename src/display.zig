const std = @import("std");

const c = @import("c.zig");
const buffer = @import("buffer.zig");
const terminal = @import("terminal.zig");

const stdout = std.io.getStdOut().writer();

const Dimensions = struct { row_count: usize, col_count: usize };

pub var dimensions: Dimensions = undefined;

pub fn update_display_dimensions() !void {
    var display_dimensions: c.struct_winsize = undefined;
    _ = c.ioctl(c.STDOUT_FILENO, c.TIOCGWINSZ, &display_dimensions);
    dimensions.row_count = display_dimensions.ws_row;
    dimensions.col_count = display_dimensions.ws_col;
}

fn update_status_line() !void {
    terminal.invert_colors();
    terminal.move_cursor(dimensions.row_count, 1);
    try stdout.print(" {[mode]s}{[filename]s: ^[filename_width]}{[ln]d: >3}:{[col]d: <3} ", .{
        .mode = "NORMAL",
        .filename = buffer.file.name,
        .filename_width = dimensions.col_count - 15,
        .ln = buffer.cursor.row,
        .col = buffer.cursor.col,
    });
    terminal.reset_colors();
}

fn update_buffer_display() !void {
    terminal.move_cursor(1, 1);

    var lines = std.mem.splitScalar(u8, buffer.file.content, '\n');
    var line_num: usize = 1;

    while (lines.next()) |line| : (line_num += 1) {
        if (line_num >= dimensions.row_count)
            break;

        try stdout.print("{d: >3} | {s}\r\n", .{ line_num, line });
    }

    while (line_num < dimensions.row_count) : (line_num += 1) {
        try stdout.writeAll("~\r\n");
    }
}

pub fn update_display() !void {
    terminal.hide_cursor();
    defer terminal.show_cursor();

    try update_buffer_display();
    try update_status_line();

    terminal.move_cursor(buffer.cursor.row, buffer.cursor.col);
}

pub fn sigwinch_handler(_: c_int) callconv(.C) void {
    update_display_dimensions() catch {};
    update_display() catch {};
}
