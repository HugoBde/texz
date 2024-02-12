const std = @import("std");

fn DoublyLinkedList(comptime T: type) type {
    return struct {
        const Node = struct {
            data: T,
            next: ?Node,
            prev: ?Node,

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

        fn init(allocator: std.mem.Allocator) DoublyLinkedList {
            return DoublyLinkedList(T){
                .size = 0,
                .head = null,
                .tail = null,
                .allocator = allocator,
            };
        }

        fn append(self: DoublyLinkedList, data: T) !void {
            const new_node = try Node.new(self.allocator, data);

            // Empty list
            if (self.size == 0) {
                self.head = new_node;
                self.tail = new_node;
                return;
            }

            new_node.prev = self.tail;
            self.tail.?.next = new_node;
            self.tail = new_node;
            self.size += 1;
        }

        fn prepend(self: DoublyLinkedList, data: T) !void {
            const new_node = try Node.new(self.allocator, data);

            // Empty list
            if (self.size == 0) {
                self.head = new_node;
                self.tail = new_node;
                return;
            }

            new_node.next = self.head;
            self.head.?.prev = new_node;
            self.head = new_node;
            self.size += 1;
        }

        fn getByIndex(self: DoublyLinkedList, index: usize) ?*Node {
            if (index >= self.size or index < 0) {
                return null;
            }

            if (index <= self.size / 2) {
                return self.getByIndexFromHead(index);
            } else {
                return self.getByIndexFromTail(index);
            }
        }

        fn getByLineNumber(self: DoublyLinkedList, line_number: usize) ?*Node {
            return self.getByIndex(line_number - 1);
        }

        fn getByIndexFromHead(self: DoublyLinkedList, index: usize) *Node {
            const curr_node = self.head;

            while (index != 0) {
                curr_node = curr_node.?.next;
                index -= 1;
            }

            return curr_node.?;
        }

        fn getByIndexFromTail(self: DoublyLinkedList, index: usize) *Node {
            const curr_node = self.tail;

            while (index < self.size) {
                curr_node = curr_node.?.prev;
                index += 1;
            }

            return curr_node.?;
        }

        fn insertByIndex(self: DoublyLinkedList, line: []u8, index: usize) !void {
            if (index >= self.size or index < 0) {
                unreachable;
            }

            if (index == 0) {
                self.prepend(line);
                return;
            }

            if (index == self.size - 1) {
                self.append(line);
                return;
            }

            const new_node = try Node.new(self.allocator, line);

            const curr_node = self.getByIndex(index);
            const prev_node = curr_node.?.prev;
            prev_node.?.next = new_node;
            new_node.prev = prev_node;
            curr_node.?.prev = new_node;
            new_node.next = curr_node;
            self.size += 1;
        }

        fn insertByLineNumber(self: DoublyLinkedList, line: []u8, line_number: usize) !void {
            self.insertByIndex(line, line_number);
        }
    };
}

test "List append" {
    const allocator = std.heap.HeapAllocator.init().allocator();
    const list = DoublyLinkedList(usize).init(allocator);

    list.append(list);

    std.testing.expect(list.size == 1);
    std.testing.expect(list.getByIndex(0) == "hello");
}

pub const Buffer = struct {
    lines: DoublyLinkedList(std.ArrayList(u8)),
    cursor_x: usize,
    cursor_y: usize,

    pub fn loadFile(filename: []const u8) !Buffer {
        _ = filename;
        return Buffer{
            .lines = DoublyLinkedList.new(),
            .cursor_x = 1,
            .cursor_y = 1,
        };
    }
};
