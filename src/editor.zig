pub const Mode = enum {
    NORMAL,
    INSERT,
};

pub const State = struct {
    // filename: [*:0]u8,
    x_pos: u32,
    y_pos: u32,
    mode: Mode,
    exiting: bool,
};

pub var state: State = undefined;
