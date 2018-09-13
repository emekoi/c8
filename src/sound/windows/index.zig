//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

const std = @import("std");

const Buffer = std.Buffer;
const Allocator = std.mem.Allocator;
const Error = @import("errors.zig");
const MMSystem = @import("mmsystem.zig");


pub const Header = struct {
    const Self = this;
    buffer: Buffer,
    wavehdr: MMSystem.WaveHdr,

    pub fn new(allocator: &Allocator, handle: isize, buf_size: usize) !Header {
        var result: Self = undefined;

        result.buffer = try Buffer.initSize(allocator, buf_size);
        result.wavehdr = MMSystem.WaveHdr {
            .lpData = result.buffer.ptr(),
            .dwBufferLength = u32(buf_size),
            .dwBytesRecorded = undefined,
            .dwUser = undefined,
            .dwFlags = 0,
            .dwLoops = undefined,
            .lpNext = undefined,
            .reserved = undefined,
        };
        
        // error is here 
        std.debug.warn("DEBUG_BEGIN\n");
        const err = MMSystem.waveOutPrepareHeader(
            handle, &result.wavehdr,
           @sizeOf(MMSystem.WaveHdr)).to_err();
        std.debug.warn("DEBUG_END\n");

        switch (err) {
            error.Ok => {},
            else => |e| return e,
        }
        
        return result;
    }

    pub fn write(self: &Self, handle: isize, data: []u8) Error.MMError!void {
        debug.assertOrPanic(data.len != self.buffer.len);
        self.buffer.replaceContents(data);
        switch (MMSystem.waveOutWrite(
            handle, &self.wavehdr,
            u32(self.buffer.len())).to_err()
        ) {
            error.Ok => {},
            else => |err| return err,
        }
    }

    pub fn destroy(self: &Self, handle: isize) !void {
        switch (MMSystem.waveOutUnprepareHeader(
            handle, &self.wavehdr,
            @sizeOf(MMSystem.WaveHdr)).to_err()
        ) {
            error.Ok => {},
            else => |err| return err,
        }

        self.buffer.deinit();
    }
};


pub const Player = struct {
    const Self = this;
    const BUF_COUNT = 2;

    handle: isize,
    headers: [BUF_COUNT]Header,
    tmp: Buffer,
    buf_size: usize,

    pub fn new(allocator: &Allocator, sample_rate: usize, channel_count: usize, bps: usize, buf_size: usize) !Player {
        var result: Self = undefined;
        var handle: isize = undefined;

        const block_align = channel_count * bps;
        const format = MMSystem.WaveFormatEx {
            .wFormatTag = u16(MMSystem.WAVE_FORMAT_PCM),
            .nChannels = u16(channel_count),
            .nSamplesPerSec = u32(sample_rate),
            .nAvgBytesPerSec = u32(sample_rate * block_align),
            .nBlockAlign = u16(block_align),
            .wBitsPerSample = u16(bps * 8),
            .cbSize = u16(0),
        };

        switch (MMSystem.waveOutOpen(
            &handle, @intToPtr(&usize, MMSystem.WAVE_MAPPER),
            &format, null, null, MMSystem.CALLBACK_NULL).to_err()
        ) {
            error.Ok => {},
            else => |err| return err,
        }

        result = Player {
            .handle = handle,
            .headers = []Header{undefined} ** BUF_COUNT,
            .buf_size = buf_size,
            .tmp = try Buffer.initSize(allocator, buf_size)
        };

        for (result.headers) |*header| {
            *header = try Header.new(allocator, result.handle, buf_size);
        }

        return result;
    }

    pub fn write(self: &Self, data: []u8) !void {
        const n = min(data.len, max(0, self.buf_size - self.tmp.len()));
        self.tmp.append(data[0..n]);
        if (self.tmp.len() < self.buf_size) {
            return;
        }

        const header = for (self.headers) |*header| {
            if (header.wavehdr.dwFlags & MMSystem.WHDR_INQUEUE == 0) {
                break header;
            }
        } else return;

        try header.write(self.handle, self.tmp.toSlice());

        self.tmp.resize(0);

        return;
    }

    pub fn close(self: &Self) !void {
        for (self.headers) |*header| {
            try header.destroy(self.handle);
        }

        switch (MMSystem.waveOutClose(self.handle).to_err()) {
            error.Ok => {},
            else => |err| return err,
        }

        self.tmp.deinit();
        
        return;
    }
};
