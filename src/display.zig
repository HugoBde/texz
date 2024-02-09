const std = @import("std");

const terminal = @import("terminal.zig");
const editor = @import("editor.zig");
const c = @import("c_imports.zig");

const DisplayState = struct {
    width: usize,
    height: usize,
};

var displayState: DisplayState = undefined;

fn updateDisplayState() !void {
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
    // prepare new status bar
    try updateDisplayState();

    var new_status_bar_buf: [1024]u8 = undefined;

    const new_status_bar = try std.fmt.bufPrint(&new_status_bar_buf, "><><>< {s} ><><><><><>", .{@tagName(editor.state.mode)});

    // mmove to status bar row
    terminal.moveCursor(0, displayState.height);
    _ = try std.io.getStdOut().writer().print("\x1b[{d};0H", .{displayState.height});

    // write new status bar
    terminal.invertColors();
    _ = try std.io.getStdOut().write(new_status_bar);
    terminal.resetColors();
}
