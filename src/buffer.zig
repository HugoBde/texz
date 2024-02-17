const Cursor = struct {
    row: usize,
    col: usize,
};

const File = struct { content: []u8, file_line_count: usize };

pub var file: File = undefined;

pub var cursor = Cursor{ .row = 1, .col = 1 };
