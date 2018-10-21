//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

const MMRESULT = @import("errors.zig").MMRESULT;
const windows = @import("std").os.windows;

pub const WAVE_FORMAT_PCM = 0x01;
pub const WHDR_INQUEUE = 0x10;
pub const WAVE_MAPPER = 0xffffffff;
pub const CALLBACK_NULL = 0x0;

pub const UINT_PTR = usize;

pub const WaveHdr = extern struct.{
    lpData: windows.LPSTR,
    dwBufferLength: windows.DWORD,
    dwBytesRecorded: windows.DWORD,
    dwUser: windows.DWORD_PTR,
    dwFlags: windows.DWORD,
    dwLoops: windows.DWORD,
    lpNext: ?*WaveHdr,
    reserved: windows.DWORD_PTR,
};

pub const WaveFormatEx = extern struct.{
    wFormatTag: windows.WORD,
    nChannels: windows.WORD,
    nSamplesPerSec: windows.DWORD,
    nAvgBytesPerSec: windows.DWORD,
    nBlockAlign: windows.WORD,
    wBitsPerSample: windows.WORD,
    cbSize: windows.WORD,
};


pub extern "winmm" stdcallcc fn waveOutOpen(phwo: *windows.HANDLE, uDeviceID: UINT_PTR,
    pwfx: *const WaveFormatEx, dwCallback: ?windows.DWORD_PTR,
    dwCallbackInstance: ?windows.DWORD_PTR, fdwOpen: windows.DWORD) MMRESULT;

pub extern "winmm" stdcallcc fn waveOutClose(hwo: windows.HANDLE) MMRESULT;

pub extern "winmm" stdcallcc fn waveOutPrepareHeader(hwo: windows.HANDLE, pwh: *WaveHdr, cbwh: windows.UINT) MMRESULT;

pub extern "winmm" stdcallcc fn waveOutUnprepareHeader(hwo: windows.HANDLE, pwh: *WaveHdr, cbwh: windows.UINT) MMRESULT;

pub extern "winmm" stdcallcc fn waveOutWrite(hwo: windows.HANDLE, pwh: *WaveHdr, cbwh: windows.UINT) MMRESULT;
