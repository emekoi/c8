//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

const std = @import("std");
const windows = @import("windows/index.zig");
const time = std.os.time;

fn PlayerImpl(comptime T: type) type {
    return struct {
        const Self = this;
        const Second = 1000000000;

        player: T,
        sample_rate: usize,
        channel_count: usize,
        bps: usize,
        buf_size: usize,

        pub fn new(allocator: *std.mem.Allocator, sample_rate: usize, channel_count: usize, bps: usize, buf_size: usize) !Self {
            return Self {
                .player = try T.new(allocator, sample_rate, channel_count, bps, buf_size),
                .sample_rate = sample_rate,
                .channel_count = channel_count,
                .bps = bps,
                .buf_size = buf_size,
            };
        }

        pub fn bytes_per_sec(self: *Self) usize {
            return self.sample_rate * self.channel_count * self.bps;
        }

        pub fn write(self: *Self, data: []u8) !void {
            var written = 0;
            while (data.len > 0) {
                const n = try self.player.write(data);
                written += n;

                data = data[n..];

                if (data.len > 0) {
                    time.sleep(0, Second * self.buf_size / self.bytes_per_sec() / 8);
                }
            }
        }

        pub fn close(self: *Self) !void {
            time.sleep(0, Second * self.buf_size / self.bytes_per_sec());
            try self.player.close();
        }
    };
}

pub const Player = PlayerImpl(windows.Player);
