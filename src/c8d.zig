//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

const std = @import("std");
const sound = @import("sound/index.zig");

const debug = std.debug;

// fn disassemble(code: []const u8, pc: i32) void {
//     const nibble = @bitCast([]const u4, code[0]);
    
//     warn("{04X} {02X} {02X} ", pc, nibble[0], nibble[1]);
    
//     switch (nibble[0]) {
//         0x06 => warn("{-10s} V{01X},#${02X}", "MVI", nibble[1], code[1]),
//         0x0A => warn("{-10s} I,#${01X}x{02X}x", "MVI", nibble[1], code[1]),
//         else => warn("{x} not handled\n", nibble[0]),
//     }
// }

pub fn main() !void {
    var allocator = debug.global_allocator;
    var player = try sound.Player.new(allocator, 44100 , 2, 2, 512);
    try player.close();
}
