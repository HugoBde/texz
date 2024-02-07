const std = @import("std");
const io = std.io;
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("termios.h");
    @cInclude("unistd.h");
});

pub fn main() !void {
    var original_termios: c.struct_termios = undefined;
    _ = c.tcgetattr(c.STDIN_FILENO, &original_termios);

    const stdout = io.getStdOut().writer();

    inline for (std.meta.fields(@TypeOf(original_termios))) |f| {
        try stdout.print(f.name ++ " {any}\n", .{@as(f.type, @field(original_termios, f.name))});
    }
}
