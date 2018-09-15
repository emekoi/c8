//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

const std = @import("std");
const alloc = @import("util/alloc.zig");
const buffer = @import("util/buffer.zig");
const io = std.io;
const os = std.os;

var stdout_file: os.File = undefined;
var stdout_file_out_stream: io.FileOutStream = undefined;
var stdout_stream: ?*io.OutStream(io.FileOutStream.Error) = null;

fn get_stdout_stream() !*std.io.OutStream(std.io.FileOutStream.Error) {
    if (stdout_stream) |st| {
        return st;
    } else {
        stdout_file = try io.getStdOut();
        stdout_file_out_stream = io.FileOutStream.init(stdout_file);
        const st = &stdout_file_out_stream.stream;
        stdout_stream = st;
        return st;
    }
}

fn info(comptime fmt: []const u8, args: ...) void {
    const stdout = get_stdout_stream() catch return;
    stdout.print(fmt, args) catch return;
}

fn invalid() void {
    info("invalid or malformed instruction\n");
}

fn to_addr(bytes: []const u8) u12 {
    var result: u12 = 0;
    result = result | u12(bytes[0]) << 8;
    result = result | u12(bytes[1]) << 4;
    result = result | u12(bytes[2]) << 0;
    return result;
}

fn disassemble(bytes: []const u8, pc: usize) void {
    const nibbles = []u8{
        (bytes[0] & 0xF0) >> 4,
        (bytes[0] & 0x0F) >> 0,
        (bytes[1] & 0xF0) >> 4,
        (bytes[1] & 0x0F) >> 0,
    };

    info("{X4} ({X}{X2}) ", pc + 0x200, bytes[0], bytes[1]);
    
    switch (nibbles[0]) {
        0x00 => {
            switch (nibbles[1]) {
                0x00 => {
                    switch (bytes[1]) {
                        0xE0 => info("{s10}\n", "CLS"),
                        0xEE => info("{s10}\n", "RET"),
                        else => info("{s10} ${X3}\n", "SYS", to_addr(nibbles[1..])),
                    }
                },
                else => info("{s10} ${X3}\n", "SYS", to_addr(nibbles[1..])),
            }
            
        },
        0x01 => info("{s10} ${X3}\n", "JP", to_addr(nibbles[1..])),
        0x02 => info("{s10} ${X3}\n", "CALL", to_addr(nibbles[1..])),
        0x03 => info("{s10} v{X}, ${X2}\n", "SE", nibbles[1], bytes[1]),
        0x04 => info("{s10} v{X}, ${X2}\n", "SNE", nibbles[1], bytes[1]),
        0x05 => info("{s10} ${X}, ${X2}\n", "SE", nibbles[1], nibbles[2]),
        0x06 => info("{s10} v{X}, ${X2}\n", "LD", nibbles[1], bytes[1]),
        0x07 => info("{s10} v{X}, ${X2}\n", "ADD", nibbles[1], bytes[1]),
        0x08 => {
            switch (nibbles[3]) {
                0x00 => info("{s10} v{X}, v{X}\n", "LD", nibbles[1], nibbles[2]),
                0x01 => info("{s10} v{X}, v{X}\n", "OR", nibbles[1], nibbles[2]),
                0x02 => info("{s10} v{X}, v{X}\n", "AND", nibbles[1], nibbles[2]),
                0x03 => info("{s10} v{X}, v{X}\n", "XOR", nibbles[1], nibbles[2]),
                0x04 => info("{s10} v{X}, v{X}\n", "ADD", nibbles[1], nibbles[2]),
                0x05 => info("{s10} v{X}, v{X}\n", "SUB", nibbles[1], nibbles[2]),
                0x06 => info("{s10} v{X}\n", "SHR", nibbles[1]),
                0x07 => info("{s10} v{X}, v{X}\n", "SUBN", nibbles[1], nibbles[2]),
                0x0E => info("{s10} v{X}\n", "SHL", nibbles[1]),
                else => invalid(),
            }
        },
        0x09 => info("{s10} v{X}, v{X}\n", "SNE", nibbles[1], nibbles[2]),
        0x0A => info("{s10} I, ${X3}\n", "LD", to_addr(nibbles[1..])),
        0x0B => info("{s10} ${X3}(v0)\n", "JP", to_addr(nibbles[1..])),
        0x0C => info("{s10} v{X}, ${X2}\n", "RND", nibbles[1], bytes[1]),
        0x0D => info("{s10} v{X}, v{X}, ${X} \n", "DRW", nibbles[1], nibbles[2], nibbles[3]),
        0x0E => {
            switch (bytes[1]) {
                0x9E => info("{s10} v{X}, \n", "SKP", nibbles[1]),
                0xA1 => info("{s10} v{X}, \n", "SKNP", nibbles[1]),
                else => invalid(),
            }
        },
        0x0F => {
            switch (bytes[1]) {
                0x07 => info("{s10} v{X}, DT\n", "LD", nibbles[1]),
                0x0A => info("{s10} v{X}, K\n", "LD", nibbles[1]),
                0x15 => info("{s10} DT, v{X}\n", "LD", nibbles[1]),
                0x18 => info("{s10} ST, v{X}\n", "LD", nibbles[1]),
                0x1E => info("{s10} I, v{X}\n", "ADD", nibbles[1]),
                0x29 => info("{s10} F, v{X}\n", "LD", nibbles[1]),
                0x33 => info("{s10} B, v{X}\n", "LD", nibbles[1]),
                0x55 => info("{s10} [I], v{X}\n", "LD", nibbles[1]),
                0x65 => info("{s10} v{X}, [I]\n", "LD", nibbles[1]),
                else => invalid(),
            }
        },
        else => invalid(),
    }
}

pub fn main() !void {
    alloc.init();
    defer alloc.deinit();

    var args_it = os.args();
    _ = try args_it.next(alloc.global).?;
    
    const filename = args_it.next(alloc.global) orelse return;
    const file = try os.File.openRead(try filename);
    defer file.close();

    const size = try file.getEndPos();
    var tmp = try buffer.Buffer(u8).initSize(alloc.global, size);
    var data = tmp.toOwnedSlice();
    tmp.deinit();
    
    _ = try file.read(data[0..]);
    var pc: usize = 0;

    info("{} - {} bytes\n---------------------------------------\n", filename, size);

    while (pc <= data.len / 2) {
        disassemble(data[pc..], pc);
        pc += 2;
    }    
}
