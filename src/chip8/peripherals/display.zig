//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

pub const std = @import("std");

const warn = std.debug.warn;
const mem = std.mem;

pub const Display = struct {
    const Self = this;

    pixels: [0x800]u8,

    pub fn clear(self: *Self) void {
        mem.set(u8, self.pixels[0..], 0);
    }
};
