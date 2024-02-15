const std = @import("std");
const c = @import("c.zig");

const stdout = std.io.getStdOut().writer();

var original_termios: c.struct_termios = undefined;

const TerminalError = error{
    TCGETATTR_FAILURE,
    TCSETATTR_FAILURE,
};

pub fn enter_raw_mode() !void {
    // this may error but for now let's pretend it cannot
    if (c.tcgetattr(c.STDIN_FILENO, &original_termios) == -1) {
        return TerminalError.TCSETATTR_FAILURE;
    }

    var raw_termios = original_termios;

    c.cfmakeraw(&raw_termios);

    // Make our application read in a blocking manner:
    // We don't need to do anything except when we get an input command
    // VMIN = 1: read when we have 1 byte in STDIN
    // VTIME = 0: wait until VMIN has been reached for read(2) to return
    raw_termios.c_cc[c.VMIN] = 1;
    raw_termios.c_cc[c.VTIME] = 0;

    if (c.tcsetattr(c.STDIN_FILENO, c.TCSANOW, &raw_termios) == -1) {
        return TerminalError.TCSETATTR_FAILURE;
    }

    // Enter alternative screen buffer
    _ = try stdout.writeAll("\x1b[?1049h");
}

pub fn enter_canonical_mode() !void {
    if (c.tcsetattr(c.STDIN_FILENO, c.TCSANOW, &original_termios) == -1) {
        return TerminalError.TCSETATTR_FAILURE;
    }

    // Enter alternative screen buffer
    _ = try stdout.writeAll("\x1b[?1049l");
}
