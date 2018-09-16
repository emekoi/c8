//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

pub const Keypad = struct {
    const Self = this;

    pub keys: [0x10]u8,

    pub fn is_down(self: *Self, key: u8) bool {
        return self.keys[key] != 0;
    }

    pub fn get_key(self: *Self) u8 {
        return 0;
    }
};
