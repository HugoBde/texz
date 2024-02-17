const buffer = @import("buffer.zig");
const display = @import("display.zig");

pub fn move_cursor_left() !void {
    buffer.cursor.col = @max(buffer.cursor.col - 1, 1);
}
pub fn move_cursor_down() !void {
    buffer.cursor.row = @min(buffer.cursor.row + 1, display.dimensions.row_count);
}
pub fn move_cursor_up() !void {
    buffer.cursor.row = @max(buffer.cursor.row - 1, 1);
}
pub fn move_cursor_right() !void {
    buffer.cursor.col = @min(buffer.cursor.col + 1, display.dimensions.col_count);
}
