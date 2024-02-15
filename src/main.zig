const std = @import("std");
const c = @import("c.zig");

const terminal = @import("terminal.zig");

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

const test_file_content =
    \\#include <stdio.h>
    \\
    \\int main(int argc, char **argv) {
    \\    printf("Hello, World!\n");
    \\    return 0;
    \\}
;

pub fn main() !void {
    try terminal.enter_raw_mode();
    defer terminal.enter_canonical_mode() catch unreachable;
    try stdout.writeAll("\x1b[1 q");
    _ = c.signal(c.SIGWINCH, sigwinch_handler);

    try update_display_dimensions();
    var read_buffer: [1]u8 = [1]u8{0};

    try update_display();
    while (read_buffer[0] != 'q') {
        // Read
        _ = try stdin.read(&read_buffer);

        // Process
        switch (read_buffer[0]) {
            'h' => try move_cursor_left(),
            'j' => try move_cursor_down(),
            'k' => try move_cursor_up(),
            'l' => try move_cursor_right(),
            'q' => {
                try stdout.print("Exiting...", .{});
                break;
            },
            else => {},
        }

        // Display
        try update_display();
    }

    try stdout.writeAll("\x1b[0 q");
}

var display_dimensions: c.struct_winsize = undefined;

fn update_display_dimensions() !void {
    _ = c.ioctl(c.STDOUT_FILENO, c.TIOCGWINSZ, &display_dimensions);
}

fn update_display() !void {
    try stdout.writeAll("\x1b[H");
    var lines = std.mem.splitScalar(u8, test_file_content, '\n');
    var line_num: usize = 1;
    while (lines.next()) |line| : (line_num += 1) {
        if (line_num >= display_dimensions.ws_row)
            break;

        try stdout.print("{d: >3} | {s}\r\n", .{ line_num, line });
    }

    while (line_num < display_dimensions.ws_row) : (line_num += 1) {
        try stdout.writeAll("~\r\n");
    }

    try stdout.print("\x1b[{d};{d}H", .{ cursor_position.row, cursor_position.col });
}

fn sigwinch_handler(_: c_int) callconv(.C) void {
    update_display_dimensions() catch {};
    update_display() catch {};
}

const CursorPosition = struct {
    row: usize,
    col: usize,
};

var cursor_position = CursorPosition{ .row = 1, .col = 1 };

fn move_cursor_left() !void {
    cursor_position.col = @max(cursor_position.col - 1, 1);
}
fn move_cursor_down() !void {
    cursor_position.row = @min(cursor_position.row + 1, display_dimensions.ws_row);
}
fn move_cursor_up() !void {
    cursor_position.row = @max(cursor_position.row - 1, 1);
}
fn move_cursor_right() !void {
    cursor_position.col = @min(cursor_position.col + 1, display_dimensions.ws_col);
}
