const m = @import("std").mem;

pub const SMF = struct {
    fmt: u16,
    trk: u16,
    div: u16,
    s: []const u8,
    pub fn init(s: []const u8) error{ NotMThd, UnexpectedEOF }!SMF {
        if (s.len < 14 or !m.eql(u8, s[0..4], "MThd")) return error.NotMThd;
        const end = m.readInt(u32, s[4..8], .big) + 8;
        return if (end < 14) error.NotMThd else if (s.len < end) error.UnexpectedEOF else .{
            .fmt = m.readInt(u16, s[0x8..0xA], .big),
            .trk = m.readInt(u16, s[0xA..0xC], .big),
            .div = m.readInt(u16, s[0xC..0xE], .big),
            .s = s[end..],
        };
    }
    pub fn next(self: *SMF) error{UnexpectedEOF}!?Trk {
        while (self.s.len > 0) {
            if (self.s.len < 8) return error.UnexpectedEOF;
            const ptr = self.s.ptr;
            const end = m.readInt(u32, ptr[4..8], .big) + 8;
            if (self.s.len < end) return error.UnexpectedEOF;
            self.s = self.s[end..];
            if (m.eql(u8, ptr[0..4], "MTrk")) return .{
                .ptr = ptr + 8,
                .ptr_limit = @intFromPtr(self.s.ptr),
            };
        } else return null;
    }
};

pub const Trk = struct {
    ptr: [*]const u8,
    ptr_limit: usize,
    last_cmd: u8 = 0,
    pub fn left(self: Trk) bool {
        return @intFromPtr(self.ptr) < self.ptr_limit;
    }
    pub fn byte(self: *Trk) u8 {
        defer self.ptr += 1;
        return self.ptr[0];
    }
    pub fn vlq(self: *Trk) u32 {
        var v: u32 = 0;
        inline for (0..4) |i| {
            const b = self.byte();
            v = @shlExact(v, 7) | if (i < 4) @as(u7, @truncate(b)) else b;
            if (i == 3 or b < 0x80) return v;
        }
    }
    pub fn evt(self: *Trk) Evt {
        switch (self.byte()) {
            0x00...0x7f => |arg1| switch (self.last_cmd) {
                0xc0...0xdf => |kind| return .{ .kind = kind, .arg1 = arg1 },
                else => |kind| return .{ .kind = kind, .arg1 = arg1, .arg2 = self.byte() },
            },
            0x80...0xbf, 0xe0...0xef => |kind| {
                self.last_cmd = kind;
                return .{ .kind = kind, .arg1 = self.byte(), .arg2 = self.byte() };
            },
            0xc0...0xdf => |kind| {
                self.last_cmd = kind;
                return .{ .kind = kind, .arg1 = self.byte() };
            },
            0xf0...0xff => |kind| {
                const arg1 = if (kind == 0xff) self.byte() else undefined;
                const size = self.vlq();
                defer self.ptr += size;
                return .{ .kind = kind, .arg1 = arg1, .size = size, .data = self.ptr };
            },
        }
    }
};

pub const Evt = struct {
    kind: u8,
    arg1: u8,
    arg2: u8 = undefined,
    size: u32 = undefined,
    data: [*]const u8 = undefined,
};
