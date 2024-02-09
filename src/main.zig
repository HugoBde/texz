const std = @import("std");
const io = std.io;
const terminal = @import("terminal.zig");
const Key = @import("input.zig").Key;

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("termios.h");
    @cInclude("unistd.h");
});

const Mode = enum {
    NORMAL,
    INSERT,
};

const State = struct {
    // filename: [*:0]u8,
    x_pos: u32,
    y_pos: u32,
    mode: Mode,
    exiting: bool,
};

var STATE: State = undefined;

/// # Original Termios struct
/// Used to reset terminal on exit
var original_termios: c.struct_termios = undefined;

const stdin = io.getStdIn().reader();
const stdout = io.getStdOut().writer();

/// Perform Init actions
/// Init Actions:
///     - Enter canonical mode
fn init() void {
    // Get
    _ = c.tcgetattr(c.STDIN_FILENO, &original_termios);

    var raw = original_termios;

    _ = stdout.print("{b}\n", .{raw.c_iflag}) catch {};
    c.cfmakeraw(&raw);
    _ = stdout.print("{b}\n", .{raw.c_iflag}) catch {};

    raw.c_cc[c.VMIN] = 1;
    raw.c_cc[c.VTIME] = 0;

    _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &raw);

    terminal.printEscapeCode(terminal.EscapeCode.CLEAR_SCREEN);
    terminal.printEscapeCode(terminal.EscapeCode.ENABLE_ALTERNATE_BUFFER);
}

fn clean_up() void {
    terminal.printEscapeCode(terminal.EscapeCode.DISABLE_ALTERNATE_BUFFER);
    _ = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &original_termios);
}

pub fn main() !void {
    // const args = std.os.argv;

    // if (args.len != 2) {
    //     std.debug.print("Usage: texz <filename>", .{});
    //     return;
    // }

    STATE = State{
        .mode = Mode.NORMAL,
        .x_pos = 1,
        .y_pos = 1,
        // .filename = args[1],
        .exiting = false,
    };

    init();
    defer clean_up();

    try run();
}

fn run() !void {
    while (!STATE.exiting) {
        const input = try read_keypress();
        process_input(input);
    }
}

fn read_keypress() !Key {
    var buffer: [1]u8 = undefined;

    _ = try stdin.read(&buffer);

    return @enumFromInt(buffer[0]);
}

fn process_input(input: Key) void {
    switch (STATE.mode) {
        Mode.NORMAL => process_input_normal_mode(input),
        Mode.INSERT => process_input_insert_mode(input),
    }
}

fn process_input_normal_mode(input: Key) void {
    switch (input) {
        Key.LOWER_I => set_mode(Mode.INSERT),
        Key.LOWER_Q => STATE.exiting = true,
        Key.LOWER_H => terminal.printEscapeCode(terminal.EscapeCode.CURSOR_BACK),
        Key.LOWER_J => terminal.printEscapeCode(terminal.EscapeCode.CURSOR_DOWN),
        Key.LOWER_K => terminal.printEscapeCode(terminal.EscapeCode.CURSOR_UP),
        Key.LOWER_L => terminal.printEscapeCode(terminal.EscapeCode.CURSOR_FORWARD),
        else => {},
    }
}

fn process_input_insert_mode(input: Key) void {
    switch (input) {
        Key.ESC => set_mode(Mode.NORMAL),
        else => _ = stdout.write(&[_]u8{@intFromEnum(input)}) catch {},
    }
}

fn set_mode(new_mode: Mode) void {
    STATE.mode = new_mode;
}
