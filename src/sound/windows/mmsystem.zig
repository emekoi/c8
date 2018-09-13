//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

const MMRESULT = @import("errors.zig").MMRESULT;

pub const WAVE_FORMAT_PCM = 0x01;
pub const WHDR_INQUEUE = 0x10;
pub const WAVE_MAPPER = 0xffffffff;
pub const CALLBACK_NULL = 0x0;

pub const WaveHdr = extern struct {
    lpData: &u8,
    dwBufferLength: u32,
    dwBytesRecorded: u32,
    dwUser: ?&usize,
    dwFlags: u32,
    dwLoops: u32,
    lpNext: ?&WaveHdr,
    reserved: ?&usize,
};

pub const WaveFormatEx = extern struct {
    wFormatTag: u16,
    nChannels: u16,
    nSamplesPerSec: u32,
    nAvgBytesPerSec: u32,
    nBlockAlign: u16,
    wBitsPerSample: u16,
    cbSize: u16,
};


pub extern "winmm" stdcallcc fn waveOutOpen(phwo: &isize, uDeviceID: &usize,
    pwfx: &WaveFormatEx, dwCallback: ?&usize,
    dwCallbackInstance: ?&usize, fdwOpen: usize) MMRESULT;

pub extern "winmm" stdcallcc fn waveOutClose(hwo: isize) MMRESULT;

pub extern "winmm" stdcallcc fn waveOutPrepareHeader(hwo: isize, pwh: &WaveHdr, cbwh: u32) MMRESULT;

pub extern "winmm" stdcallcc fn waveOutUnprepareHeader(hwo: isize, pwh: &WaveHdr, cbwh: u32) MMRESULT;

pub extern "winmm" stdcallcc fn waveOutWrite(hwo: isize, pwh: &WaveHdr, cbwh: u32) MMRESULT;
