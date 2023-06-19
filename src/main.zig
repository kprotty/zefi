const std = @import("std");
const Fiber = @import("fiber.zig");

fn assertEq(a: anytype, b: @TypeOf(a)) void {
    std.testing.expectEqual(a, b) catch @panic("fail");
}

fn hello(value: *usize, other_fiber: *Fiber) void {
    assertEq(Fiber.current().?.getUserDataPtr().*, 0x1337);
    assertEq(value.*, @as(usize, 5));

    other_fiber.switchTo();
    assertEq(value.*, @as(usize, 10));

    Fiber.yield();
    assertEq(value.*, @as(usize, 17));

    other_fiber.switchTo();
    other_fiber.switchTo();
    other_fiber.switchTo();
}

fn hello2(value: *usize) void {
    assertEq(Fiber.current().?.getUserDataPtr().*, 0x420);

    value.* += 5;
    Fiber.yield();

    Fiber.current().?.getUserDataPtr().* = 0x69;
    Fiber.yield();

    assertEq(Fiber.current().?.getUserDataPtr().*, 0x69);
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

    var fiber_2 = try Fiber.init(f2_stack, 0x420, hello2, .{&val});
    var fiber = try Fiber.init(f1_stack, 0x1337, hello, .{ &val, fiber_2 });

    val = 5;
    fiber.switchTo();
    
    val += 7;
    fiber.switchTo();
}