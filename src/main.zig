const std = @import("std");
const c = @import("c.zig");

const buffer = @import("buffer.zig");
const commands = @import("commands.zig");
const display = @import("display.zig");
const terminal = @import("terminal.zig");

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    defer _ = gpa.detectLeaks();

    const args = try std.process.argsAlloc(allocator);

    if (args.len != 2) {
        std.debug.print("usage: ./texz <filename>", .{});
        return;
    }

    const filename = args[1];

    buffer.file.content = try std.fs.cwd().readFileAlloc(allocator, filename, 4_000_000_000);
    buffer.file.name = filename;

    try terminal.enter_raw_mode();
    defer terminal.enter_canonical_mode() catch unreachable;

    // Set cursor to blinking block
    terminal.set_cursor_type(terminal.CursorType.BLINKING_BLOCK);

    // Setup signal handler to update display dimensions when window is resized
    _ = c.signal(c.SIGWINCH, display.sigwinch_handler);

    try display.update_display_dimensions();

    var read_buffer: [1]u8 = [1]u8{0};

    try display.update_display();
    while (read_buffer[0] != 'q') {
        // Read
        _ = try stdin.read(&read_buffer);

        // Process
        switch (read_buffer[0]) {
            'h' => try commands.move_cursor_left(),
            'j' => try commands.move_cursor_down(),
            'k' => try commands.move_cursor_up(),
            'l' => try commands.move_cursor_right(),
            'q' => {
                try stdout.writeAll("Exiting...");
                break;
            },
            else => {},
        }

        // Display
        try display.update_display();
    }

    terminal.reset_cursor_type();
}
