const std = @import("std");
const Fiber = @import("fiber.zig");

fn hello(value: *usize, other_fiber: *Fiber) void {
    std.testing.expectEqual(value.*, @as(usize, 5)) catch @panic("Fail");

    Fiber.switchTo(other_fiber);
    std.testing.expectEqual(value.*, @as(usize, 10)) catch @panic("Fail");

    Fiber.yield();
    std.testing.expectEqual(value.*, @as(usize, 17)) catch @panic("Fail");

    Fiber.switchTo(other_fiber);
    Fiber.switchTo(other_fiber);
    Fiber.switchTo(other_fiber);
}

fn hello2(value: *usize) void {
    value.* += 5;
    Fiber.yield();
    Fiber.yield();
    Fiber.yield();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var val: usize = 0;

    const f2_stack = try allocator.alloc(u8, 16 * 1024);
    defer allocator.free(f2_stack);

    const f1_stack = try allocator.alloc(u8, 16 * 1024);
    defer allocator.free(f1_stack);

    var fiber_2 = try Fiber.init(f2_stack, hello2, .{&val});
    var fiber = try Fiber.init(f1_stack, hello, .{ &val, fiber_2 });

    val = 5;
    Fiber.switchTo(fiber);
    
    val += 7;
    Fiber.switchTo(fiber);
}