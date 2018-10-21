//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

const std = @import("std");
const alloc = @import("util/alloc.zig");
const Buffer = @import("util/buffer.zig").Buffer;
const CPU = @import("chip8/cpu.zig").CPU;

const io = std.io;
const os = std.os;

pub fn main() !void {
    alloc.init();
    defer alloc.deinit();

    var args_it = os.args();
    _ = try args_it.next(alloc.global).?;
    
    const filename = args_it.next(alloc.global) orelse return;
    const file = try os.File.openRead(try filename);
    defer file.close();

    const size = try file.getEndPos();
    var tmp = try Buffer(u8).initSize(alloc.global, size);
    var data = tmp.toOwnedSlice();
    tmp.deinit();
    
    const len = try file.read(data[0..]);
    var cpu = CPU.new();
    cpu.load_rom(data);

    var i: usize = 0;
    while (i < len / 2) : (i += 1) {
        try cpu.step();
    }
}
