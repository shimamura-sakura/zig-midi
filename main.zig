const std = @import("std");
const mid = @import("midi.zig");
const allocator = std.heap.page_allocator;

pub fn main() anyerror!void {
    const data = try std.fs.cwd().readFileAlloc(allocator, "test_midi_file", 128 * 1048576);
    defer allocator.free(data);
    _ = try run(data);
    for (0..100) |_| _ = run(data) catch unreachable;
    const beg = try std.time.Instant.now();
    for (0..100) |_| _ = run(data) catch unreachable;
    const end = try std.time.Instant.now();
    const u, const d = run(data) catch unreachable;
    std.debug.print(
        "time: {d} note: up {d} down {d}\n",
        .{@as(f64, @floatFromInt(end.since(beg))) / 1_000_000_000 / 100, u, d },
    );
}

noinline fn run(data: []const u8) !struct { usize, usize } {
    var smf = try mid.SMF.init(data);
    var dn: usize = 0;
    var up: usize = 0;
    var i: usize = 0;
    while (try smf.next()) |t| : (i += 1) {
        var track = t;
        while (track.left()) {
            _ = track.vlq();
            const evt = track.evt();
            switch (evt.kind) {
                0x80...0x8f => up += 1,
                0x90...0x9f => {
                    if (evt.arg2 > 0) dn += 1 else up += 1;
                },
                else => {},
            }
        }
    }
    return .{ dn, up };
}
