const std = @import("std");

const terminal = @import("terminal.zig");
const editor = @import("editor.zig");

const DisplayState = struct {
    width: u32,
    height: u32,
};

var displayState: DisplayState = undefined;

fn updateDisplayState() !void {
    const lines_num_env_var = std.os.getenv("LINES") orelse "80";
    const cols_num_env_var = std.os.getenv("COLUMNS") orelse "80";

    displayState = DisplayState{
        .width = try std.fmt.parseInt(u32, cols_num_env_var, 10),
        .height = try std.fmt.parseInt(u32, lines_num_env_var, 10),
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
