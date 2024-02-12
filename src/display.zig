const std = @import("std");

const buffer = @import("buffer.zig");
const c = @import("c_imports.zig");
const editor = @import("editor.zig");
const terminal = @import("terminal.zig");

const DisplayState = struct {
    width: usize,
    height: usize,
};

var displayState: DisplayState = undefined;

pub fn updateDisplayState() !void {
    var winsz: c.winsize = undefined;

    if (std.os.system.ioctl(c.STDOUT_FILENO, c.TIOCGWINSZ, &winsz) != 0) {
        unreachable;
    }

    displayState = DisplayState{
        .width = winsz.ws_col,
        .height = winsz.ws_row,
    };
}

pub fn updateStatusBar() !void {
    var new_status_bar_buf: [1024]u8 = undefined;

    const new_status_bar = try std.fmt.bufPrint(&new_status_bar_buf, "><><>< {s} ><><><><><>", .{@tagName(editor.state.mode)});

    // clear display
    terminal.printEscapeCode(terminal.EscapeCodeTag.CLEAR_SCREEN, .{});

    // mmove to status bar row
    terminal.moveCursor(1, displayState.height);
    _ = try std.io.getStdOut().writer().print("\x1b[{d};0H", .{displayState.height});

    // write new status bar
    terminal.invertColors();
    _ = try std.io.getStdOut().write(new_status_bar);
    terminal.resetColors();
}

fn updateBufferLine(line_number: usize, line: std.ArrayList(u8)) !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("{d: >3} | {s}\r", .{ line_number, line.items });
}

fn updateBufferSection(file_buffer: buffer.Buffer) !void {
    var line = file_buffer.lines.head;
    var line_number: usize = 1;

    while (line_number < displayState.height and line != null) {
        try updateBufferLine(line_number, line.?.data);
        line = line.?.next;
        line_number += 1;
    }

    // if (line == null) {
    //     for (line_number..displayState.height) |_| {
    //         try std.io.getStdOut().writer().print("~\n\r", .{});
    //     }
    // }
}

pub fn updateDisplay(file_buffer: buffer.Buffer) !void {
    try updateDisplayState();
    terminal.moveCursor(1, 1);
    try updateBufferSection(file_buffer);
    try updateStatusBar();
}

pub fn sigwinchHandler(_: c_int) callconv(.C) void {
    updateDisplayState() catch {};
    updateStatusBar() catch {};
}
