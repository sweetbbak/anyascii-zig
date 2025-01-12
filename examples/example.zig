const std = @import("std");
const anyascii = @import("anyascii");

pub fn main() !void {
    var buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const writer = fbs.writer().any();

    const len = try anyascii.anyascii_string("🫣", writer);
    std.debug.print("{s}\n", .{buf[0..len]});

    const s = anyascii.anyascii(0xFA);
    std.debug.print("{s}\n", .{s});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    
    const str = try anyascii.anyascii_string_alloc(allocator, "🫣");
    defer allocator.free(str);
    std.debug.print("{s}\n", .{str});
}
