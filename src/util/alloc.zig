//  Copyright (c) 2018 emekoi
//
//  This library is free software; you can redistribute it and/or modify it
//  under the terms of the MIT license. See LICENSE for details.
//

const std = @import("std");
const heap = std.heap;
const mem = std.mem;

pub var global: *mem.Allocator = undefined;
var alloc_impl: heap.DirectAllocator = undefined;

pub fn init() void {
    alloc_impl = heap.DirectAllocator.init();
    // var arena_alloc = heap.ArenaAllocator.init(alloc_impl);
    global = &alloc_impl.allocator;
}

pub fn deinit() void {
    alloc_impl.deinit();
}
