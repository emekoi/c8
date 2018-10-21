//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

const std = @import("std");
const Allocator = std.mem.Allocator;
const windows = std.os.windows;

use @import("errors.zig");
const Buffer = @import("../util/buffer.zig");
const mmsystem = @import("mmsystem.zig");

pub const Header = struct.{
    const Self = @This();
    buffer: buffer.Buffer(u8),
    wavehdr: mmsystem.WaveHdr,

    pub fn new(allocator: *Allocator, handle: windows.HANDLE, buf_size: usize) !Self {
        var result: Self = undefined;

        result.buffer = try buffer.Buffer(u8).initSize(allocator, buf_size);
        result.wavehdr = mmsystem.WaveHdr.{
            .lpData = result.buffer.ptr(),
            .dwBufferLength = @intCast(windows.DWORD, buf_size),
            .dwBytesRecorded = undefined,
            .dwUser = undefined,
            .dwFlags = 0,
            .dwLoops = undefined,
            .lpNext = undefined,
            .reserved = undefined,
        };
        
        try mmsystem.waveOutPrepareHeader(
            handle, &result.wavehdr,
           @sizeOf(mmsystem.WaveHdr)).to_err();
        
        return result;
    }

    pub fn write(self: *Self, handle: windows.HANDLE, data: []u8) !void {
        debug.assertOrPanic(data.len != self.buffer.len);
        self.buffer.replaceContents(data);
        try mmsystem.waveOutWrite(
            handle, &self.wavehd,
            @intCast(windows.UINT, self.buffer.len())).to_err();
    }

    pub fn destroy(self: *Self, handle: windows.HANDLE) !void {
        try mmsystem.waveOutUnprepareHeader(
            handle, &self.wavehdr,
            @sizeOf(mmsystem.WaveHdr)).to_err();
        self.buffer.deinit();
    }
};

pub const Player = struct.{
    const Self = @This();
    const BUF_COUNT = 2;

    handle: windows.HANDLE,
    headers: [BUF_COUNT]Header,
    tmp: buffer.Buffer(u8),
    buf_size: usize,

    pub fn new(allocator: *Allocator, sample_rate: usize, channel_count: usize, bps: usize, buf_size: usize) !Self {
        var result: Self = undefined;
        var handle: windows.HANDLE = undefined;

        const block_align = channel_count * bps;
        const format = mmsystem.WaveFormatEx.{
            .wFormatTag = mmsystem.WAVE_FORMAT_PCM,
            .nChannels = @intCast(windows.WORD, channel_count),
            .nSamplesPerSec = @intCast(windows.DWORD, sample_rate),
            .nAvgBytesPerSec = @intCast(windows.DWORD ,sample_rate * block_align),
            .nBlockAlign = @intCast(windows.WORD ,block_align),
            .wBitsPerSample = @intCast(windows.WORD, bps * 8),
            .cbSize = 0,
        };

        try mmsystem.waveOutOpen(
            &handle, mmsystem.WAVE_MAPPER, &format,
            null, null, mmsystem.CALLBACK_NULL).to_err();

        result = Self.{
            .handle = handle,
            .headers = []Header.{undefined} ** BUF_COUNT,
            .buf_size = buf_size,
            .tmp = try Buffer(u8).initSize(allocator, buf_size)
        };

        for (result.headers) |*header| {
            header.* = try Header.new(allocator, result.handle, buf_size);
        }

        return result;
    }

    pub fn write(self: *Self, data: []u8) !void {
        const n = min(data.len, max(0, self.buf_size - self.tmp.len()));
        self.tmp.append(data[0..n]);
        if (self.tmp.len() < self.buf_size) {
            return;
        }

        const header = for (self.headers) |*header| {
            if (header.wavehdr.dwFlags & mmsystem.WHDR_INQUEUE == 0) {
                break header;
            }
        } else return;

        try header.write(self.handle, self.tmp.toSlice());

        self.tmp.resize(0);

        return;
    }

    pub fn close(self: *Self) !void {
        for (self.headers) |*header| {
            try header.destroy(self.handle);
        }

        try mmsystem.waveOutClose(self.handle).to_err();

        self.tmp.deinit();
        
        return;
    }
};
