const std = @import("std");
const io = std.io;
const terminal = @import("terminal.zig");
const display = @import("display.zig");
const input = @import("input.zig");
const editor = @import("editor.zig");
const c = @import("c_imports.zig");

/// # Original Termios struct
/// Used to reset terminal on exit
var original_termios: c.struct_termios = undefined;

const stdin = io.getStdIn().reader();
const stdout = io.getStdOut().writer();

/// # Perform Init actions
/// Init Actions:
///     - Enter raw mode
fn init() !void {
    // Get
    _ = c.tcgetattr(c.STDIN_FILENO, &original_termios);

    var raw = original_termios;

    c.cfmakeraw(&raw);

    raw.c_cc[c.VMIN] = 1;
    raw.c_cc[c.VTIME] = 0;

    _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &raw);

    terminal.printEscapeCode(terminal.EscapeCode.CLEAR_SCREEN);
    terminal.printEscapeCode(terminal.EscapeCode.ENABLE_ALTERNATE_BUFFER);

    try display.updateDisplayState();
    try display.updateStatusBar();

    _ = c.signal(c.SIGWINCH, display.sigwinchHandler);
}

/// # Perform Clean up actions
/// Clean up actions:
///     - Return canonical mode
fn cleanUp() void {
    terminal.printEscapeCode(terminal.EscapeCode.DISABLE_ALTERNATE_BUFFER);
    _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &original_termios);
}

pub fn main() !void {
    // const args = std.os.argv;

    // if (args.len != 2) {
    //     std.debug.print("Usage: texz <filename>", .{});
    //     return;
    // }

    editor.state = editor.State{
        .mode = editor.Mode.NORMAL,
        .x_pos = 1,
        .y_pos = 1,
        // .filename = args[1],
        .exiting = false,
    };

    try init();
    defer cleanUp();

    try run();
}

fn run() !void {
    while (!editor.state.exiting) {
        const user_input = try read_keypress();
        try processInput(user_input);
    }
}

fn read_keypress() !input.Key {
    var buffer: [1]u8 = undefined;

    _ = try stdin.read(&buffer);

    return @enumFromInt(buffer[0]);
}

fn processInput(user_input: input.Key) !void {
    switch (editor.state.mode) {
        editor.Mode.NORMAL => try processInputNormalMode(user_input),
        editor.Mode.INSERT => try processInputInsertMode(user_input),
    }
}

fn processInputNormalMode(user_input: input.Key) !void {
    switch (user_input) {
        input.Key.LOWER_I => try setMode(editor.Mode.INSERT),
        input.Key.LOWER_Q => editor.state.exiting = true,
        input.Key.LOWER_H => terminal.printEscapeCode(terminal.EscapeCode.CURSOR_BACK),
        input.Key.LOWER_J => terminal.printEscapeCode(terminal.EscapeCode.CURSOR_DOWN),
        input.Key.LOWER_K => terminal.printEscapeCode(terminal.EscapeCode.CURSOR_UP),
        input.Key.LOWER_L => terminal.printEscapeCode(terminal.EscapeCode.CURSOR_FORWARD),
        else => {},
    }
}

fn processInputInsertMode(user_input: input.Key) !void {
    switch (user_input) {
        input.Key.ESC => try setMode(editor.Mode.NORMAL),
        else => _ = stdout.write(&[_]u8{@intFromEnum(user_input)}) catch {},
    }
}

fn setMode(new_mode: editor.Mode) !void {
    editor.state.mode = new_mode;
    try display.updateStatusBar();
}
