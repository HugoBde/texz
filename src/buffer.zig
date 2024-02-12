const std = @import("std");

fn DoublyLinkedList(comptime T: type) type {
    return struct {
        const Node = struct {
            data: T,
            next: ?*Node,
            prev: ?*Node,

            fn new(allocator: std.mem.Allocator, data: T) !*Node {
                const new_node = try allocator.create(Node);

                new_node.* = Node{
                    .data = data,
                    .next = null,
                    .prev = null,
                };

                return new_node;
            }
        };

        size: usize,
        head: ?*Node,
        tail: ?*Node,

        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator) DoublyLinkedList(T) {
            return DoublyLinkedList(T){
                .size = 0,
                .head = null,
                .tail = null,
                .allocator = allocator,
            };
        }

        fn append(self: *DoublyLinkedList(T), data: T) !void {
            const new_node = try Node.new(self.allocator, data);

            // Empty list
            if (self.size == 0) {
                self.head = new_node;
            } else {
                new_node.prev = self.tail;
                self.tail.?.next = new_node;
            }

            self.tail = new_node;
            self.size += 1;
        }

        fn prepend(self: *DoublyLinkedList(T), data: T) !void {
            const new_node = try Node.new(self.allocator, data);

            // Empty list
            if (self.size == 0) {
                self.tail = new_node;
            } else {
                new_node.next = self.head;
                self.head.?.prev = new_node;
            }

            self.head = new_node;
            self.size += 1;
        }

        fn getByIndex(self: DoublyLinkedList(T), index: usize) ?*Node {
            if (index >= self.size or index < 0) {
                return null;
            }

            if (index <= self.size / 2) {
                return self.getByIndexFromHead(index);
            } else {
                return self.getByIndexFromTail(index);
            }
        }

        fn getByLineNumber(self: DoublyLinkedList(T), line_number: usize) ?*Node {
            return self.getByIndex(line_number - 1);
        }

        fn getByIndexFromHead(self: DoublyLinkedList(T), index: usize) *Node {
            var curr_node = self.head;

            for (0..index) |_| {
                curr_node = curr_node.?.next;
            }

            return curr_node.?;
        }

        fn getByIndexFromTail(self: DoublyLinkedList(T), index: usize) *Node {
            var curr_node = self.tail;

            for (index..self.size - 1) |_| {
                curr_node = curr_node.?.prev;
            }

            return curr_node.?;
        }

        fn insertByIndex(self: *DoublyLinkedList(T), data: T, index: usize) !void {
            if (index > self.size or index < 0) {
                unreachable;
            }

            if (index == 0) {
                try self.prepend(data);
                return;
            }

            if (index == self.size) {
                try self.append(data);
                return;
            }

            const new_node = try Node.new(self.allocator, data);

            var curr_node = self.getByIndex(index);
            var prev_node = curr_node.?.prev;
            prev_node.?.next = new_node;
            new_node.prev = prev_node;
            curr_node.?.prev = new_node;
            new_node.next = curr_node;
            self.size += 1;
        }

        fn insertByLineNumber(self: *DoublyLinkedList(T), data: T, line_number: usize) !void {
            try self.insertByIndex(data, line_number - 1);
        }

        fn print(self: *DoublyLinkedList(T)) void {
            if (self.size == 0) {
                std.debug.print("[EMPTY]\n", .{});
                return;
            }

            var node = self.head;
            while (node != null) {
                std.debug.print("{any} -> ", .{node.?.data});
                node = node.?.next;
            }

            std.debug.print("END\n", .{});
        }
    };
}

test "list_append" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var list = DoublyLinkedList(usize).init(allocator);

    try list.append(5);

    try std.testing.expectEqual(@as(usize, 1), list.size);
    try std.testing.expectEqual(@as(usize, 5), list.getByIndex(0).?.data);

    try list.append(1);

    try std.testing.expectEqual(@as(usize, 2), list.size);
    try std.testing.expectEqual(@as(usize, 5), list.getByIndex(0).?.data);
    try std.testing.expectEqual(@as(usize, 1), list.getByIndex(1).?.data);
}

test "list_prepend" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var list = DoublyLinkedList(usize).init(allocator);

    try list.prepend(5);

    try std.testing.expectEqual(@as(usize, 1), list.size);
    try std.testing.expectEqual(@as(usize, 5), list.getByIndex(0).?.data);

    try list.prepend(1);

    try std.testing.expectEqual(@as(usize, 2), list.size);
    try std.testing.expectEqual(@as(usize, 1), list.getByIndex(0).?.data);
    try std.testing.expectEqual(@as(usize, 5), list.getByIndex(1).?.data);
}

test "list_insert" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var list = DoublyLinkedList(usize).init(allocator);

    try list.insertByIndex(5, 0);
    try std.testing.expectEqual(@as(usize, 1), list.size);
    try std.testing.expectEqual(@as(usize, 5), list.getByIndex(0).?.data);

    try list.insertByIndex(3, 0);
    try std.testing.expectEqual(@as(usize, 2), list.size);
    try std.testing.expectEqual(@as(usize, 3), list.getByIndex(0).?.data);

    try list.insertByIndex(6, 2);
    try std.testing.expectEqual(@as(usize, 3), list.size);
    try std.testing.expectEqual(@as(usize, 6), list.getByIndex(2).?.data);

    try list.insertByLineNumber(1, 1);
    try std.testing.expectEqual(@as(usize, 4), list.size);
    try std.testing.expectEqual(@as(usize, 1), list.getByLineNumber(1).?.data);

    try list.insertByLineNumber(2, 2);
    try std.testing.expectEqual(@as(usize, 5), list.size);
    try std.testing.expectEqual(@as(usize, 2), list.getByLineNumber(2).?.data);

    try list.insertByLineNumber(4, 4);
    try std.testing.expectEqual(@as(usize, 6), list.size);
    try std.testing.expectEqual(@as(usize, 4), list.getByLineNumber(4).?.data);
}

pub const Buffer = struct {
    lines: DoublyLinkedList(std.ArrayList(u8)),
    cursor_x: usize,
    cursor_y: usize,

    pub fn loadFile(allocator: std.mem.Allocator, path: [*:0]const u8) !Buffer {
        const file = try std.fs.openFileAbsoluteZ(path, .{
            .mode = std.fs.File.OpenMode.read_only,
        });
        const file_stat = try file.stat();
        const file_size = file_stat.size;

        const read_buffer = try allocator.alloc(u8, file_size);

        const file_reader = file.reader();

        const file_read_size = try file_reader.readAll(read_buffer);

        if (file_read_size < file_size) {
            unreachable;
        }

        var buffer = Buffer{
            .lines = DoublyLinkedList(std.ArrayList(u8)).init(allocator),
            .cursor_x = 1,
            .cursor_y = 1,
        };

        var line_start: usize = 0;

        for (0..file_size) |i| {
            if (read_buffer[i] == '\n') {
                var line = try std.ArrayList(u8).initCapacity(allocator, i - line_start + 1);
                try line.writer().writeAll(read_buffer[line_start..(i + 1)]);
                try buffer.lines.append(line);
                line_start = i + 1;
            }
        }

        return buffer;
    }
};
