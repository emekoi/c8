//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

use @import("peripherals/index.zig");

pub const std = @import("std");

const warn = std.debug.warn;
const time= std.os.time;
const rand = std.rand;
const mem = std.mem;

pub const CPU = struct.{
    const Self = @This();

    pub const Exception = error.{
        InvalidOpcode,
        StackUnderflow,
        StackOverflow,
    };

    const font_set = [80]u8.{
        0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
        0x20, 0x60, 0x20, 0x20, 0x70, // 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
        0x90, 0x90, 0xF0, 0x10, 0x10, // 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
        0xF0, 0x10, 0x20, 0x40, 0x40, // 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, // A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
        0xF0, 0x80, 0x80, 0x80, 0xF0, // C
        0xE0, 0x90, 0x90, 0x90, 0xE0, // D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
        0xF0, 0x80, 0xF0, 0x80, 0x80  // F
    };

    const font_start = 0;
    
    // index register
    i: u16,
    // program counter
    pc: u16,
    // memory
    memory: [0x1000]u8,
    // registers
    v: [0x10]u8,
    // peripherals
    keypad: Keypad,
    display: Display,
    // stack
    stack: [0x10]u16,
    // stack pointer
    sp: u8,
    // delay timers
    delay: u8,
    sound: u8,
    // prng
    prng: rand.DefaultPrng,

    pub fn new() Self {
        return Self.{
            .i = 0x0,
            .pc = 0x200,
            .memory = []u8.{0} ** 0x1000,
            .v = []u8.{0x0} ** 0x10,
            .keypad = Keypad.{
                .keys = []u8.{0x0} ** 0x10,
            },
            .display = Display.{
                .pixels = []u8.{0x0} ** 0x800,
            },
            .stack = []u16.{0x0} ** 0x10,
            .sp = 0x0,
            .delay = 0x0,
            .sound = 0x0,
            .prng = rand.DefaultPrng.init(time.milliTimestamp()),
        };
    }

    pub fn load_rom(self: *Self, rom: []const u8) void {
        mem.copy(u8, self.memory[0x0..], font_set);
        mem.copy(u8, self.memory[0x200..], rom);
    }

    pub fn step(self: *Self) !void {
        const opcode = {
            var tmp = u16(self.memory[self.pc]) << 8;
            tmp | u16(self.memory[self.pc + 1]);
        };
        try self.process(opcode);
        warn("\n");
    }

    pub fn process(self: *Self, opcode: u16) Exception!void {
        const nibbles = []u8.{
            @truncate(u8, (opcode & 0xF000) >> 12),
            @truncate(u8, (opcode & 0x0F00) >> 8),
            @truncate(u8, (opcode & 0x00F0) >> 4),
            @truncate(u8, (opcode & 0x000F) >> 0),
        };

        const bytes = []u8.{
            @truncate(u8, (opcode & 0xFF00) >> 8),
            @truncate(u8, (opcode & 0x00FF) >> 0),
        };

        warn("{X4} ({X}{X2}) ", self.pc, bytes[0], bytes[1]);
        
        switch (nibbles[0]) {
            0x00 => {
                switch (nibbles[1]) {
                    0x00 => {
                        switch (bytes[1]) {
                            // CLS
                            0xE0 => self.display.clear(),
                            // RET
                            0xEE => if (self.sp > 0) self.sp -= 1 else return error.StackUnderflow,
                            // SYS
                            else => {},
                        }
                    },
                    // SYS
                    else => {},
                }
            },
            // JP
            0x01 => {
                self.pc = opcode & 0x0FFF;
                return;
            },
            // CALL
            0x02 => {
                if (self.sp > self.stack.len) {
                    return error.StackOverflow;
                }
                self.stack[self.sp] = self.pc + 2;
                self.sp += 1;
                self.pc = opcode & 0x0FFF;
                return;
            },
            // SE
            0x03 => if (self.v[nibbles[1]] == bytes[1]) self.pc += 2,
            // SNE
            0x04 => if (self.v[nibbles[1]] != bytes[1]) self.pc += 2,
            // SE
            0x05 => if (self.v[nibbles[1]] == self.v[nibbles[1]]) self.pc += 2,
            // LD
            0x06 => self.v[nibbles[1]] = bytes[1],
            // ADD
            0x07 => self.v[nibbles[1]] += bytes[1],
            0x08 => {
                switch (nibbles[3]) {
                    // LD
                    0x00 => self.v[nibbles[1]] = self.v[nibbles[2]],
                    // OR
                    0x01 => self.v[nibbles[1]] |= self.v[nibbles[2]],
                    // AND
                    0x02 => self.v[nibbles[1]] &= self.v[nibbles[2]],
                    // XOR
                    0x03 => self.v[nibbles[1]] ^= self.v[nibbles[2]],
                    // ADD
                    0x04 => {
                        const vX = u16(self.v[nibbles[1]]);
                        const vY = u16(self.v[nibbles[2]]);
                        if (vX + vY > 0xFF) self.v[0x0F] = 1;
                        self.v[nibbles[1]] = @truncate(u8,  vX + vY);
                    },
                    // SUB
                    0x05 => {
                        const vX = u16(self.v[nibbles[1]]);
                        const vY = u16(self.v[nibbles[2]]);
                        if (vX > vY) self.v[0x0F] = 1;
                        self.v[nibbles[1]] = @truncate(u8,  vX - vY);
                    },
                    // SHR
                    0x06 => self.v[nibbles[1]] >>= 1,
                    // SUBN
                    0x07 => {
                        const vX = u16(self.v[nibbles[1]]);
                        const vY = u16(self.v[nibbles[2]]);
                        if (vX < vY) self.v[0x0F] = 1;
                        self.v[nibbles[1]] = @truncate(u8,  vY - vX);
                    },
                    // SHL
                    0x0E => self.v[nibbles[1]] <<= 1,
                    else => return error.InvalidOpcode,
                }
            },
            // SNE
            0x09 => if (self.v[nibbles[1]] != self.v[nibbles[1]]) self.pc += 2,
            // LD
            0x0A => self.i = opcode & 0x0FFF,
            // JP(v0)
            0x0B =>{
                self.pc = (opcode & 0x0FFF) + self.v[0x00];
                return;
            },
            // RND
            0x0C => self.v[nibbles[1]] = self.prng.random.scalar(u8) & bytes[1],
            0x0D => warn("{s10} v{X}, v{X}, ${X} \n", "DRW", nibbles[1], nibbles[2], nibbles[3]),
            0x0E => {
                switch (bytes[1]) {
                    // SKP
                    0x9E => if (self.keypad.is_down(self.v[nibbles[1]])) self.pc += 2,
                    // SKNP
                    0xA1 => if (!self.keypad.is_down(self.v[nibbles[1]])) self.pc += 2,
                    else => return error.InvalidOpcode,
                }
            },
            0x0F => {
                switch (bytes[1]) {
                    // LD
                    0x07 => self.v[nibbles[1]] = self.delay,
                    // LD
                    0x0A => self.v[nibbles[1]] = self.keypad.get_key(),
                    // LD
                    0x15 => self.delay = self.v[nibbles[1]],
                    // LD
                    0x18 => self.sound = self.v[nibbles[1]],
                    // ADD
                    0x1E => self.i += self.v[nibbles[1]],
                    // LD
                    0x29 => self.i = font_start + (self.v[nibbles[1]] * 5),
                    // BCD
                    0x33 => {
                        var decimal = self.v[nibbles[1]];
                        self.memory[self.i + 2] = decimal % 10;
                        decimal /= 10;
                        self.memory[self.i + 1] = decimal % 10;
                        self.memory[self.i + 0] = decimal / 10;
                    },
                    // LD
                    0x55 => {
                        var counter: u8 = 0;
                        while (counter <= self.v[nibbles[1]]) : (counter += 1) {
                            self.memory[self.i + u16(counter)] = self.v[counter];
                        }
                    },
                    // LD
                    0x65 => {
                        var counter: u8 = 0;
                        while (counter <= self.v[nibbles[1]]) : (counter += 1) {
                            self.v[counter] = self.memory[self.i + u16(counter)];
                        }
                    },
                    else => return error.InvalidOpcode,
                }
            },
            else => return error.InvalidOpcode,
        }

        // increment pc
        self.pc += 2;
    }
};
