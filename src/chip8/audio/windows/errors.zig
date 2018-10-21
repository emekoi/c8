//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

pub const MMError = error.{
    Error,
    BadDeviceID,
    Allocated,
    InvalidHandle,
    NoDriver,
    NoMem,
    BadFormat,
    StillPlaying,
    Unprepared,
    Sync,
};

pub const MMRESULT = extern enum(u32).{
    MMSYSERR_NOERROR = 0,
    MMSYSERR_ERROR = 1,
    MMSYSERR_BADDEVICEID = 2,
    MMSYSERR_ALLOCATED = 4,
    MMSYSERR_INVALIDHANDLE = 5,
    MMSYSERR_NODRIVER = 6,
    MMSYSERR_NOMEM = 7,
    WAVERR_BADFORMAT = 32,
    WAVERR_STILLPLAYING = 33,
    WAVERR_UNPREPARED = 34,
    WAVERR_SYNC = 35,

    pub fn to_err(self: MMRESULT) MMError!void {
        return switch (self) {
            MMRESULT.MMSYSERR_NOERROR => {},
            MMRESULT.MMSYSERR_ERROR => MMError.Error,
            MMRESULT.MMSYSERR_BADDEVICEID => MMError.BadDeviceID,
            MMRESULT.MMSYSERR_ALLOCATED => MMError.Allocated,
            MMRESULT.MMSYSERR_INVALIDHANDLE => MMError.InvalidHandle,
            MMRESULT.MMSYSERR_NODRIVER => MMError.NoDriver,
            MMRESULT.MMSYSERR_NOMEM => MMError.NoMem,
            MMRESULT.WAVERR_BADFORMAT =>  MMError.BadFormat,
            MMRESULT.WAVERR_STILLPLAYING =>  MMError.StillPlaying,
            MMRESULT.WAVERR_UNPREPARED =>  MMError.Unprepared,
            MMRESULT.WAVERR_SYNC =>  MMError.Sync,
        };
    }
};
